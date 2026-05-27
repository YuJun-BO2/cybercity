`include "city_define.vh"

// 部門共用核心。各實際部門只負責定義成本、產出與初始庫存，
// 握手入庫、資源扣除、產出暫存與防溢位邏輯都集中在這裡。
module department_core #(
    parameter COST0 = 16'd0,
    parameter COST1 = 16'd0,
    parameter COST2 = 16'd0,
    parameter PRODUCT_AMOUNT = 16'd0,
    parameter INIT_STORE0 = 16'd0,
    parameter INIT_STORE1 = 16'd0,
    parameter INIT_STORE2 = 16'd0,
    parameter INIT_PRODUCT = 16'd0
) (
    input clk,
    input rst_n,

    input [`DATA_WIDTH-1:0] in0_data,
    input in0_valid,
    output in0_ready,

    input [`DATA_WIDTH-1:0] in1_data,
    input in1_valid,
    output in1_ready,

    input [`DATA_WIDTH-1:0] in2_data,
    input in2_valid,
    output in2_ready,

    output reg [`DATA_WIDTH-1:0] out_data,
    output reg out_valid,
    input out_ready,

    output reg [2:0] state,
    output [`DATA_WIDTH-1:0] debug_store0,
    output [`DATA_WIDTH-1:0] debug_store1,
    output [`DATA_WIDTH-1:0] debug_store2,
    output [`DATA_WIDTH-1:0] debug_product
);

    reg [`DATA_WIDTH-1:0] store0;
    reg [`DATA_WIDTH-1:0] store1;
    reg [`DATA_WIDTH-1:0] store2;
    reg [`DATA_WIDTH-1:0] product_store;

    reg [`DATA_WIDTH-1:0] next_store0;
    reg [`DATA_WIDTH-1:0] next_store1;
    reg [`DATA_WIDTH-1:0] next_store2;
    reg [`DATA_WIDTH-1:0] next_product_store;
    reg [2:0] next_state;

    wire can_accept0;
    wire can_accept1;
    wire can_accept2;
    wire can_produce;
    wire output_fire;
    wire missing_resource;
    wire product_room;

    // ready 由暫存後的庫存決定，讓上游看到穩定且同步的 back-pressure。
    assign can_accept0 = (store0 < `READY_LIMIT);
    assign can_accept1 = (store1 < `READY_LIMIT);
    assign can_accept2 = (store2 < `READY_LIMIT);

    assign in0_ready = can_accept0;
    assign in1_ready = can_accept1;
    assign in2_ready = can_accept2;

    assign product_room = (product_store <= (`RESOURCE_MAX - PRODUCT_AMOUNT));
    assign can_produce = (store0 >= COST0) &&
                         (store1 >= COST1) &&
                         (store2 >= COST2) &&
                         product_room &&
                         (PRODUCT_AMOUNT != 16'd0);
    assign output_fire = out_valid && out_ready;
    assign missing_resource = ((COST0 != 16'd0) && (store0 < COST0)) ||
                              ((COST1 != 16'd0) && (store1 < COST1)) ||
                              ((COST2 != 16'd0) && (store2 < COST2));

    assign debug_store0 = store0;
    assign debug_store1 = store1;
    assign debug_store2 = store2;
    assign debug_product = product_store;

    // 多個資源在同一個 cycle 進來時，避免 16-bit 加法回捲。
    function [`DATA_WIDTH-1:0] saturating_add;
        input [`DATA_WIDTH-1:0] lhs;
        input [`DATA_WIDTH-1:0] rhs;
        reg [`DATA_WIDTH:0] sum;
        begin
            sum = {1'b0, lhs} + {1'b0, rhs};
            if (sum[`DATA_WIDTH]) begin
                saturating_add = `RESOURCE_MAX;
            end else begin
                saturating_add = sum[`DATA_WIDTH-1:0];
            end
        end
    endfunction

    always @(*) begin
        next_store0 = store0;
        next_store1 = store1;
        next_store2 = store2;
        next_product_store = product_store;

        // 只有完成握手的輸入資源才會被計入庫存。
        if (in0_valid && in0_ready) begin
            next_store0 = saturating_add(next_store0, in0_data);
        end
        if (in1_valid && in1_ready) begin
            next_store1 = saturating_add(next_store1, in1_data);
        end
        if (in2_valid && in2_ready) begin
            next_store2 = saturating_add(next_store2, in2_data);
        end

        // 只有下游接受後，產品才會離開本部門庫存。
        if (output_fire) begin
            if (next_product_store > out_data) begin
                next_product_store = next_product_store - out_data;
            end else begin
                next_product_store = 16'd0;
            end
        end

        // can_produce 已確認資源足夠，因此這裡扣庫存不會低於 0。
        // 若資源不足，狀態會轉為 S_WAIT，而不是錯誤扣成負值。
        if (can_produce) begin
            next_store0 = next_store0 - COST0;
            next_store1 = next_store1 - COST1;
            next_store2 = next_store2 - COST2;
            next_product_store = saturating_add(next_product_store, PRODUCT_AMOUNT);
        end

        // S_WAIT 表示正常的資源等待；S_IDLE 也包含產品庫存滿載時暫停生產。
        if (next_product_store >= `READY_LIMIT) begin
            next_state = `S_IDLE;
        end else if (can_produce) begin
            next_state = `S_WORK;
        end else if (missing_resource) begin
            next_state = `S_WAIT;
        end else begin
            next_state = `S_IDLE;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            store0 <= INIT_STORE0;
            store1 <= INIT_STORE1;
            store2 <= INIT_STORE2;
            product_store <= INIT_PRODUCT;
            out_data <= 16'd0;
            out_valid <= 1'b0;
            state <= `S_IDLE;
        end else begin
            store0 <= next_store0;
            store1 <= next_store1;
            store2 <= next_store2;
            product_store <= next_product_store;
            state <= next_state;

            // out_valid 維持為暫存器輸出。若剩餘產品不足一個標準封包，
            // 仍允許送出較小的最後一包。
            if (next_product_store == 16'd0) begin
                out_data <= 16'd0;
                out_valid <= 1'b0;
            end else if (next_product_store >= PRODUCT_AMOUNT) begin
                out_data <= PRODUCT_AMOUNT;
                out_valid <= 1'b1;
            end else begin
                out_data <= next_product_store;
                out_valid <= 1'b1;
            end
        end
    end

endmodule
