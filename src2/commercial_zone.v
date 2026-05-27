`define CLK_PERIOD 10
`define DATA_WIDTH 16 // 資源數值寬度 (最大值 65535)
`define S_IDLE 3'd0 // 待機 / 內部資源已滿載
`define S_WORK 3'd1 // 正常運作與生產中
`define S_WAIT 3'd2 // 等待上游資源 (Ready = 0)
`define S_CRISIS 3'd3 // 資源枯竭 / 啟動保護機制
`define S_DEAD 3'd4 // 系統完全停擺


module commercial_zone (
    input clk,
    input rst_n,

    // 中央政府 / 上游資源輸入
    input  [`DATA_WIDTH-1:0] material_data,
    input                    material_valid,
    output reg               material_ready,

    input  [`DATA_WIDTH-1:0] power_data,
    input                    power_valid,
    output reg               power_ready,

    input  [`DATA_WIDTH-1:0] labor_data,
    input                    labor_valid,
    output reg               labor_ready,

    // 輸出資金給中央政府
    output reg [`DATA_WIDTH-1:0] money_data,
    output reg                   money_valid,
    input                        gov_ready,

    // 觀察狀態
    output reg [2:0] state
);

    reg [2:0] next_state;

    reg [`DATA_WIDTH-1:0] internal_material;
    reg [`DATA_WIDTH-1:0] internal_power;
    reg [`DATA_WIDTH-1:0] internal_labor;
    reg [`DATA_WIDTH-1:0] internal_money;

    reg [3:0] crisis_count;

    wire enough_resource;
    wire money_taken;

    assign enough_resource = (internal_material >= 16'd2) &&
                             (internal_power    >= 16'd2) &&
                             (internal_labor    >= 16'd2);

    assign money_taken = money_valid && gov_ready;

    // =========================
    // FSM state register
    // =========================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= `S_IDLE;
        else
            state <= next_state;
    end

    // =========================
    // FSM next state logic
    // =========================
    always @(*) begin
        next_state = state;

        case (state)

            `S_IDLE: begin
                if (enough_resource)
                    next_state = `S_WORK;
                else
                    next_state = `S_CRISIS;
            end

            `S_WORK: begin
                if (!enough_resource)
                    next_state = `S_CRISIS;
                else if (!gov_ready)
                    next_state = `S_WAIT;
                else
                    next_state = `S_IDLE;
            end

            `S_WAIT: begin
                if (!enough_resource)
                    next_state = `S_CRISIS;
                else if (gov_ready)
                    next_state = `S_IDLE;
                else
                    next_state = `S_WAIT;
            end

            `S_CRISIS: begin
                if (enough_resource)
                    next_state = `S_WORK;
                else if (crisis_count >= 4'd10)
                    next_state = `S_DEAD;
                else
                    next_state = `S_CRISIS;
            end

            `S_DEAD: begin
                next_state = `S_DEAD;
            end

            default: begin
                next_state = `S_IDLE;
            end

        endcase
    end

    // =========================
    // Resource Bank
    // =========================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            internal_material <= 16'd0;
            internal_power    <= 16'd0;
            internal_labor    <= 16'd0;
            internal_money    <= 16'd0;
            crisis_count      <= 4'd0;
        end
        else begin
            // 接收中央政府 / 上游發放資源
            if (material_valid && material_ready)
                internal_material <= internal_material + material_data;

            if (power_valid && power_ready)
                internal_power <= internal_power + power_data;

            if (labor_valid && labor_ready)
                internal_labor <= internal_labor + labor_data;

            // S_WORK：生產資金
            if (state == `S_WORK && enough_resource) begin
                internal_material <= internal_material - 16'd2;
                internal_power    <= internal_power    - 16'd2;
                internal_labor    <= internal_labor    - 16'd2;
                internal_money    <= internal_money    + 16'd10;
            end

            // 中央政府成功收走資金
            if (money_taken && internal_money >= 16'd10)
                internal_money <= internal_money - 16'd10;

            // crisis 計時，太久沒恢復就進 S_DEAD
            if (state == `S_CRISIS && !enough_resource)
                crisis_count <= crisis_count + 4'd1;
            else
                crisis_count <= 4'd0;
        end
    end

    // =========================
    // Ready / Valid Register Output
    // =========================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            material_ready <= 1'b0;
            power_ready    <= 1'b0;
            labor_ready    <= 1'b0;

            money_valid    <= 1'b0;
            money_data     <= 16'd0;
        end
        else begin
            // 滿載拒收
            material_ready <= (internal_material < 16'd65000);
            power_ready    <= (internal_power    < 16'd65000);
            labor_ready    <= (internal_labor    < 16'd65000);

            // 有錢就送給中央政府
            if (internal_money >= 16'd10) begin
                money_valid <= 1'b1;
                money_data  <= 16'd10;
            end

            // gov_ready = 1，中央政府收走資金
            if (money_taken) begin
                money_valid <= 1'b0;
                money_data  <= 16'd0;
            end

            // DEAD 狀態完全停止
            if (state == `S_DEAD) begin
                material_ready <= 1'b0;
                power_ready    <= 1'b0;
                labor_ready    <= 1'b0;
                money_valid    <= 1'b0;
                money_data     <= 16'd0;
            end
        end
    end

endmodule