`include "city_define.vh"

// 單輸入、四輸出的註冊式路由器。每次保留一筆待送資源，
// 並在啟用的輸出端之間 round-robin 輪流分配，避免任一下游長期拿不到資源。
module resource_router4 #(
    parameter ENABLE0 = 1'b1,
    parameter ENABLE1 = 1'b1,
    parameter ENABLE2 = 1'b1,
    parameter ENABLE3 = 1'b1
) (
    input clk,
    input rst_n,

    input [`DATA_WIDTH-1:0] in_data,
    input in_valid,
    output reg in_ready,

    output reg [`DATA_WIDTH-1:0] out0_data,
    output reg out0_valid,
    input out0_ready,

    output reg [`DATA_WIDTH-1:0] out1_data,
    output reg out1_valid,
    input out1_ready,

    output reg [`DATA_WIDTH-1:0] out2_data,
    output reg out2_valid,
    input out2_ready,

    output reg [`DATA_WIDTH-1:0] out3_data,
    output reg out3_valid,
    input out3_ready
);

    reg [1:0] rr_ptr;
    wire busy;
    wire fire0;
    wire fire1;
    wire fire2;
    wire fire3;

    assign busy = out0_valid || out1_valid || out2_valid || out3_valid;
    assign fire0 = out0_valid && out0_ready;
    assign fire1 = out1_valid && out1_ready;
    assign fire2 = out2_valid && out2_ready;
    assign fire3 = out3_valid && out3_ready;

    // 選擇目前 round-robin 目標；若指標落在停用輸出，則退回第一個啟用輸出。
    function [1:0] pick_target;
        input [1:0] start;
        begin
            if ((start == 2'd0) && ENABLE0) begin
                pick_target = 2'd0;
            end else if ((start == 2'd1) && ENABLE1) begin
                pick_target = 2'd1;
            end else if ((start == 2'd2) && ENABLE2) begin
                pick_target = 2'd2;
            end else if ((start == 2'd3) && ENABLE3) begin
                pick_target = 2'd3;
            end else if (ENABLE0) begin
                pick_target = 2'd0;
            end else if (ENABLE1) begin
                pick_target = 2'd1;
            end else if (ENABLE2) begin
                pick_target = 2'd2;
            end else begin
                pick_target = 2'd3;
            end
        end
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rr_ptr <= 2'd0;
            in_ready <= 1'b1;
            out0_data <= 16'd0;
            out1_data <= 16'd0;
            out2_data <= 16'd0;
            out3_data <= 16'd0;
            out0_valid <= 1'b0;
            out1_valid <= 1'b0;
            out2_valid <= 1'b0;
            out3_valid <= 1'b0;
        end else begin
            if (fire0) out0_valid <= 1'b0;
            if (fire1) out1_valid <= 1'b0;
            if (fire2) out2_valid <= 1'b0;
            if (fire3) out3_valid <= 1'b0;

            // data 與 valid 同步鎖住，直到下游 ready 後才釋放，確保封包穩定。
            if (in_valid && in_ready) begin
                case (pick_target(rr_ptr))
                    2'd0: begin
                        out0_data <= in_data;
                        out0_valid <= 1'b1;
                        rr_ptr <= 2'd1;
                    end
                    2'd1: begin
                        out1_data <= in_data;
                        out1_valid <= 1'b1;
                        rr_ptr <= 2'd2;
                    end
                    2'd2: begin
                        out2_data <= in_data;
                        out2_valid <= 1'b1;
                        rr_ptr <= 2'd3;
                    end
                    default: begin
                        out3_data <= in_data;
                        out3_valid <= 1'b1;
                        rr_ptr <= 2'd0;
                    end
                endcase
            end

            // 沒有待送輸出，或本 cycle 有輸出完成握手時，才接受新的輸入。
            in_ready <= !busy || fire0 || fire1 || fire2 || fire3;
        end
    end

endmodule
