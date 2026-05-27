`include "city_define.vh"

// 中央政府資金庫。接收商業區稅收，並透過註冊後的 valid/ready 通道分配資金。
module government #(
    parameter INIT_FUNDS = `INIT_FUNDS,
    parameter GRANT0 = 16'd2,
    parameter GRANT1 = 16'd2,
    parameter GRANT2 = 16'd0,
    parameter GRANT3 = 16'd0,
    parameter GRANT4 = 16'd0
) (
    input clk,
    input rst_n,

    input [`DATA_WIDTH-1:0] tax_data,
    input tax_valid,
    output tax_ready,

    output reg [`DATA_WIDTH-1:0] fund0_data,
    output reg fund0_valid,
    input fund0_ready,

    output reg [`DATA_WIDTH-1:0] fund1_data,
    output reg fund1_valid,
    input fund1_ready,

    output reg [`DATA_WIDTH-1:0] fund2_data,
    output reg fund2_valid,
    input fund2_ready,

    output reg [`DATA_WIDTH-1:0] fund3_data,
    output reg fund3_valid,
    input fund3_ready,

    output reg [`DATA_WIDTH-1:0] fund4_data,
    output reg fund4_valid,
    input fund4_ready,

    output reg [2:0] state,
    output [`DATA_WIDTH-1:0] debug_funds
);

    reg [`DATA_WIDTH-1:0] funds;
    reg [2:0] rr_ptr;
    reg [`DATA_WIDTH-1:0] next_funds;
    reg [2:0] next_rr_ptr;

    wire fire_tax;
    wire fire0;
    wire fire1;
    wire fire2;
    wire fire3;
    wire fire4;
    wire has_pending_grant;

    // 稅收接收也遵守和其他資源相同的滿載限制。
    assign tax_ready = (funds < `READY_LIMIT);
    assign fire_tax = tax_valid && tax_ready;
    assign fire0 = fund0_valid && fund0_ready;
    assign fire1 = fund1_valid && fund1_ready;
    assign fire2 = fund2_valid && fund2_ready;
    assign fire3 = fund3_valid && fund3_ready;
    assign fire4 = fund4_valid && fund4_ready;
    assign has_pending_grant = fund0_valid || fund1_valid || fund2_valid ||
                               fund3_valid || fund4_valid;
    assign debug_funds = funds;

    // 稅收加總採飽和加法，避免 16-bit 資金計數器回捲。
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
        next_funds = funds;
        next_rr_ptr = rr_ptr;

        // 先在組合邏輯中套用所有握手結果，再於 clock edge 註冊 next_funds。
        if (fire_tax) begin
            next_funds = saturating_add(next_funds, tax_data);
        end
        if (fire0) begin
            next_funds = next_funds - fund0_data;
            next_rr_ptr = 3'd1;
        end
        if (fire1) begin
            next_funds = next_funds - fund1_data;
            next_rr_ptr = 3'd0;
        end
        if (fire2) begin
            next_funds = next_funds - fund2_data;
            next_rr_ptr = 3'd3;
        end
        if (fire3) begin
            next_funds = next_funds - fund3_data;
            next_rr_ptr = 3'd4;
        end
        if (fire4) begin
            next_funds = next_funds - fund4_data;
            next_rr_ptr = 3'd0;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            funds <= INIT_FUNDS;
            rr_ptr <= 3'd0;
            fund0_data <= 16'd0;
            fund1_data <= 16'd0;
            fund2_data <= 16'd0;
            fund3_data <= 16'd0;
            fund4_data <= 16'd0;
            fund0_valid <= 1'b0;
            fund1_valid <= 1'b0;
            fund2_valid <= 1'b0;
            fund3_valid <= 1'b0;
            fund4_valid <= 1'b0;
            state <= `S_IDLE;
        end else begin
            funds <= next_funds;
            rr_ptr <= next_rr_ptr;

            if (fire0) fund0_valid <= 1'b0;
            if (fire1) fund1_valid <= 1'b0;
            if (fire2) fund2_valid <= 1'b0;
            if (fire3) fund3_valid <= 1'b0;
            if (fire4) fund4_valid <= 1'b0;

            if (!has_pending_grant) begin
                // 本設計中只有前兩個資金通道會實際使用，分別供應發電廠與淨水廠。
                if ((rr_ptr == 3'd0) && (next_funds >= GRANT0) &&
                    (GRANT0 != 16'd0)) begin
                    fund0_data <= GRANT0;
                    fund0_valid <= 1'b1;
                end else if ((rr_ptr == 3'd1) && (next_funds >= GRANT1) &&
                             (GRANT1 != 16'd0)) begin
                    fund1_data <= GRANT1;
                    fund1_valid <= 1'b1;
                end else if ((rr_ptr == 3'd2) && (next_funds >= GRANT2) &&
                             (GRANT2 != 16'd0)) begin
                    fund2_data <= GRANT2;
                    fund2_valid <= 1'b1;
                end else if ((rr_ptr == 3'd3) && (next_funds >= GRANT3) &&
                             (GRANT3 != 16'd0)) begin
                    fund3_data <= GRANT3;
                    fund3_valid <= 1'b1;
                end else if ((rr_ptr == 3'd4) && (next_funds >= GRANT4) &&
                             (GRANT4 != 16'd0)) begin
                    fund4_data <= GRANT4;
                    fund4_valid <= 1'b1;
                end else if ((next_funds >= GRANT0) && (GRANT0 != 16'd0)) begin
                    fund0_data <= GRANT0;
                    fund0_valid <= 1'b1;
                    rr_ptr <= 3'd0;
                end else if ((next_funds >= GRANT1) && (GRANT1 != 16'd0)) begin
                    fund1_data <= GRANT1;
                    fund1_valid <= 1'b1;
                    rr_ptr <= 3'd1;
                end
            end

            if (next_funds == 16'd0) begin
                state <= `S_WAIT;
            end else begin
                state <= `S_WORK;
            end
        end
    end

endmodule
