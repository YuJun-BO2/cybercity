//`include "city_define.vh"

module city(
    input  wire         clk,
    input  wire         rst_n,
    
    // =========================================================================
    // 介面對齊：來自中央政府的資源輸入介面 (由政府統一分發)
    // =========================================================================
    input  wire         resource_valid,
    output wire         resource_ready,    // 遵照老師 Hint：改為 wire，後面用 assign
    input  wire [47:0]  resource_data,     // [47:32] material, [31:16] power, [15:0] labor
    
    // 輸出給中央市政府的稅收資金介面 (Money Output Interface)
    output reg [15:0]   out_money,
    output reg          out_valid,
    input  wire         gov_ready,         
    
    // 監視輸出
    output reg [2:0]    current_state
);

    // 內部資源記帳本 (Internal Resource Bank)
    reg [15:0] internal_material;
    reg [15:0] internal_power;
    reg [15:0] internal_labor;
    reg [15:0] internal_money;

    // 狀態機與計數器
    reg [2:0] next_state;
    reg [3:0] crisis_counter; 
    
    // 助教提示的 X 週期緩衝期 (長時間無法恢復)
    localparam X_CYCLES = 4'd10;

    // 解開中央政府送來的 48-bit resource_data 總線
    wire [15:0] gov_material    = resource_data[47:32];
    wire [15:0] gov_power       = resource_data[31:16];
    wire [15:0] gov_labor       = resource_data[15:0];

    // 生產致能邏輯：材料都要 >= 2 才能開工
    wire production_enable = (internal_material >= 16'd2) && 
                             (internal_power    >= 16'd2) && 
                             (internal_labor    >= 16'd2);

    // =========================================================================
    // 遵照老師 Hint：用 assign 即時判斷倉庫有沒有滿載 (滿載拒收原則)
    // =========================================================================
    // 商業區主要是生產資金（money）。當資金大於等於 65000，或處於 S_IDLE (3'd0) 時拒收資源。
    assign resource_ready = (internal_money < 16'd65000 && current_state != 3'd0) ? 1'b1 : 1'b0;

    // -------------------------------------------------------------------------
    // 1. 同步時序邏輯： FSM 狀態跳轉與計數器
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_state  <= 3'd0; // S_IDLE
            crisis_counter <= 4'd0;
        end else begin
            current_state <= next_state;
            
            if (current_state == 3'd3) begin // S_CRISIS (3'd3)
                crisis_counter <= crisis_counter + 1'b1;
            end else begin
                crisis_counter <= 4'd0;
            end
        end
    end

    // -------------------------------------------------------------------------
    // 2. 組合邏輯：下一狀態判斷 (對齊 FSM Bubble Diagram)
    // -------------------------------------------------------------------------
    always @(*) begin
        next_state = current_state; // 預設值，完全消滅 Quartus 的 Latch 錯誤
        
        case (current_state)
            // S_IDLE (3'd0)
            3'd0: begin
                if (resource_valid && resource_ready && production_enable) begin
                    next_state = 3'd1; // 轉去 S_WORK
                end
            end
            
            // S_WORK (3'd1)
            3'd1: begin
                if (!production_enable) begin
                    next_state = 3'd3; // 資源不足，轉去 S_CRISIS
                end else if (gov_ready == 1'b0) begin
                    next_state = 3'd2; // 中央政府不收款，轉去 S_WAIT
                end
            end
            
            // S_WAIT (3'd2)
            3'd2: begin
                if (gov_ready == 1'b1) begin
                    next_state = 3'd1; // 政府可以收款了，回到 S_WORK
                end
            end
            
            // S_CRISIS (3'd3)
            3'd3: begin
                if (production_enable) begin
                    next_state = 3'd1; // 資源補齊了，回到 S_WORK
                end else if (crisis_counter >= X_CYCLES) begin
                    next_state = 3'd4; // 長時間無法恢復 -> S_DEAD
                end
            end
            
            // S_DEAD (3'd4)
            3'd4: begin
                next_state = 3'd4; // 死結
            end
            
            default: begin
                next_state = 3'd0;
            end
        endcase
    end

    // -------------------------------------------------------------------------
    // 3. 同步時序邏輯：Datapath 運算 (嚴格執行老師的 Handshake 成功收貨邏輯)
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            internal_material    <= 16'd0;
            internal_power       <= 16'd0;
            internal_labor       <= 16'd0;
            internal_money       <= 16'd0;
        end else begin
            
            // ✨ 融入老師的 Hint 核心：只有在 Valid 和 Ready 同時為 High 的瞬間才收貨！
            if (resource_valid && resource_ready) begin
                internal_material    <= internal_material + gov_material;
                internal_power       <= internal_power + gov_power;
                internal_labor       <= internal_labor + gov_labor;
            end
            
            // FSM 消耗與生產邏輯 (S_WORK)
            if (current_state == 3'd1 && production_enable) begin
                internal_material    <= internal_material - 16'd2;
                internal_power       <= internal_power - 16'd2;
                internal_labor       <= internal_labor - 16'd2;
                
                if (internal_money <= 16'd65525) begin
                    internal_money   <= internal_money + 16'd10; // 產出 10 資金
                end else begin
                    internal_money   <= 16'd65535;
                end
            end
            
            // 上交稅收/資金給中央政府 (Out Handshake 成功)
            if (out_valid && gov_ready) begin
                if (internal_money >= 16'd10) begin
                    internal_money <= internal_money - 16'd10;
                end
            end
        end
    end

    // -------------------------------------------------------------------------
    // 4. 同步時序邏輯：控制輸出 Valid 與 Money (過暫存器，防訊號抖動)
    // -------------------------------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_valid      <= 1'b0;
            out_money      <= 16'd0;
        end else begin
            // 只有在 S_WORK 且內部有足夠資金（>=10）時，才對中央政府發送有效訊號
            if (current_state == 3'd1 && internal_money >= 16'd10) begin
                out_valid <= 1'b1;
                out_money <= 16'd10;
            end else begin
                out_valid <= 1'b0;
                out_money <= 16'd0;
            end
        end
    end

endmodule