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

    // =========================
    // 上游資源輸入
    // =========================

    // 工業物資輸入
    input  [`DATA_WIDTH-1:0] material_data,
    input                    material_valid,
    output reg               material_ready,

    // 電力輸入
    input  [`DATA_WIDTH-1:0] power_data,
    input                    power_valid,
    output reg               power_ready,

    // 勞動力輸入
    input  [`DATA_WIDTH-1:0] labor_data,
    input                    labor_valid,
    output reg               labor_ready,

    // =========================
    // 輸出資金給中央政府
    // =========================
    output reg [`DATA_WIDTH-1:0] money_data,
    output reg                   money_valid,

    // 中央政府是否準備接收
    input                        gov_ready,

    // FSM 狀態輸出（方便看波形）
    output reg [2:0] state
);

    // =========================
    // FSM next state
    // =========================
    reg [2:0] next_state;

    // =========================
    // Internal Resource Bank
    // 內部資源儲存區
    // =========================
    reg [`DATA_WIDTH-1:0] internal_material;
    reg [`DATA_WIDTH-1:0] internal_power;
    reg [`DATA_WIDTH-1:0] internal_labor;
    reg [`DATA_WIDTH-1:0] internal_money;

    // =========================
    // 危機狀態計時器
    // 長時間缺資源 -> S_DEAD
    // =========================
    reg [3:0] crisis_count;

    // =========================
    // 資源是否足夠生產
    // 商業區需求：
    // 2 material
    // 2 power
    // 2 labor
    // =========================
    wire enough_resource;

    assign enough_resource =
            (internal_material >= 16'd2) &&
            (internal_power    >= 16'd2) &&
            (internal_labor    >= 16'd2);

    // =========================
    // 資金成功傳送條件
    // valid && ready
    // =========================
    wire money_taken;

    assign money_taken = money_valid && gov_ready;

    // ============================================================
    // FSM State Register
    // 在 clock 上升沿更新 state
    // ============================================================
    always @(posedge clk or negedge rst_n) begin

        // Reset
        if (!rst_n)
            state <= `S_IDLE;

        // 正常更新狀態
        else
            state <= next_state;
    end

    // ============================================================
    // FSM Next State Logic
    // 決定下一個狀態
    // ============================================================
    always @(*) begin

        // 預設保持原狀態
        next_state = state;

        case (state)

            // ====================================================
            // S_IDLE
            // 初始化 / 待機
            // ====================================================
            `S_IDLE: begin

                // 資源足夠 -> 開始生產
                if (enough_resource)
                    next_state = `S_WORK;

                // 資源不足 -> 危機狀態
                else
                    next_state = `S_CRISIS;
            end

            // ====================================================
            // S_WORK
            // 生產資金
            // ====================================================
            `S_WORK: begin

                // 生產途中資源不足
                if (!enough_resource)
                    next_state = `S_CRISIS;

                // 中央政府不收款
                else if (!gov_ready)
                    next_state = `S_WAIT;

                // 正常完成
                else
                    next_state = `S_IDLE;
            end

            // ====================================================
            // S_WAIT
            // 等待中央政府接收資金
            // ====================================================
            `S_WAIT: begin

                // 缺資源
                if (!enough_resource)
                    next_state = `S_CRISIS;

                // 中央政府恢復接收
                else if (gov_ready)
                    next_state = `S_IDLE;

                // 繼續等待
                else
                    next_state = `S_WAIT;
            end

            // ====================================================
            // S_CRISIS
            // 資源危機
            // ====================================================
            `S_CRISIS: begin

                // 資源恢復
                if (enough_resource)
                    next_state = `S_WORK;

                // 太久沒恢復 -> DEAD
                else if (crisis_count >= 4'd10)
                    next_state = `S_DEAD;

                // 持續危機
                else
                    next_state = `S_CRISIS;
            end

            // ====================================================
            // S_DEAD
            // 系統完全停擺
            // ====================================================
            `S_DEAD: begin
                next_state = `S_DEAD;
            end

            // ====================================================
            // Default
            // ====================================================
            default: begin
                next_state = `S_IDLE;
            end

        endcase
    end

    // ============================================================
    // Internal Resource Bank
    // 管理內部資源
    // ============================================================
    always @(posedge clk or negedge rst_n) begin

        // Reset
        if (!rst_n) begin

            internal_material <= 16'd0;
            internal_power    <= 16'd0;
            internal_labor    <= 16'd0;
            internal_money    <= 16'd0;

            crisis_count      <= 4'd0;

        end
        else begin

            // ====================================================
            // 接收工業物資
            // ====================================================
            if (material_valid && material_ready)
                internal_material <= internal_material + material_data;

            // ====================================================
            // 接收電力
            // ====================================================
            if (power_valid && power_ready)
                internal_power <= internal_power + power_data;

            // ====================================================
            // 接收勞動力
            // ====================================================
            if (labor_valid && labor_ready)
                internal_labor <= internal_labor + labor_data;

            // ====================================================
            // S_WORK 生產資金
            //
            // 消耗：
            // -2 material
            // -2 power
            // -2 labor
            //
            // 產出：
            // +10 money
            // ====================================================
            if (state == `S_WORK && enough_resource) begin

                internal_material <= internal_material - 16'd2;

                internal_power <= internal_power - 16'd2;

                internal_labor <= internal_labor - 16'd2;

                internal_money <= internal_money + 16'd10;
            end

            // ====================================================
            // 中央政府成功收走資金
            // ====================================================
            if (money_taken && internal_money >= 16'd10)

                internal_money <= internal_money - 16'd10;

            // ====================================================
            // 危機計時器
            // ====================================================
            if (state == `S_CRISIS && !enough_resource)

                crisis_count <= crisis_count + 4'd1;

            else

                crisis_count <= 4'd0;
        end
    end

    // ============================================================
    // Ready / Valid Output Logic
    // ============================================================
    always @(posedge clk or negedge rst_n) begin

        // Reset
        if (!rst_n) begin

            material_ready <= 1'b0;
            power_ready    <= 1'b0;
            labor_ready    <= 1'b0;

            money_valid    <= 1'b0;
            money_data     <= 16'd0;

        end
        else begin

            // ====================================================
            // 滿載拒收原則
            // 超過 65000 不再接收資源
            // ====================================================
            material_ready <= (internal_material < 16'd65000);

            power_ready <= (internal_power < 16'd65000);

            labor_ready <= (internal_labor < 16'd65000);

            // ====================================================
            // 有資金時送給中央政府
            // ====================================================
            if (internal_money >= 16'd10) begin

                money_valid <= 1'b1;

                money_data <= 16'd10;
            end

            // ====================================================
            // 中央政府成功收款
            // ====================================================
            if (money_taken) begin

                money_valid <= 1'b0;

                money_data <= 16'd0;
            end

            // ====================================================
            // DEAD 狀態
            // 完全停止運作
            // ====================================================
            if (state == `S_DEAD) begin

                material_ready <= 1'b0;

                power_ready <= 1'b0;

                labor_ready <= 1'b0;

                money_valid <= 1'b0;

                money_data <= 16'd0;
            end
        end
    end

endmodule