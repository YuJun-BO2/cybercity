`timescale 1ns/1ps
`include "../src/city_define.vh"

// 商業區單元測試：
// 1. 資源不足時不產生稅收。
// 2. 物資、電力、勞動力各 2 單位齊全後，產生 10 單位稅收。
// 3. tax_ready 拉低時，tax_valid 與 tax_data 必須維持到下游接受。
module tb_commerce_area;

    reg clk;
    reg rst_n;

    reg [`DATA_WIDTH-1:0] material_data;
    reg material_valid;
    wire material_ready;

    reg [`DATA_WIDTH-1:0] power_data;
    reg power_valid;
    wire power_ready;

    reg [`DATA_WIDTH-1:0] labor_data;
    reg labor_valid;
    wire labor_ready;

    wire [`DATA_WIDTH-1:0] tax_data;
    wire tax_valid;
    reg tax_ready;

    wire [2:0] state;
    wire [`DATA_WIDTH-1:0] debug_funds;

    commerce_area dut (
        .clk(clk),
        .rst_n(rst_n),
        .material_data(material_data),
        .material_valid(material_valid),
        .material_ready(material_ready),
        .power_data(power_data),
        .power_valid(power_valid),
        .power_ready(power_ready),
        .labor_data(labor_data),
        .labor_valid(labor_valid),
        .labor_ready(labor_ready),
        .tax_data(tax_data),
        .tax_valid(tax_valid),
        .tax_ready(tax_ready),
        .state(state),
        .debug_funds(debug_funds)
    );

    initial begin
        clk = 1'b0;
        forever #(`CLK_PERIOD / 2) clk = ~clk;
    end

    task check;
        input condition;
        input [8*80-1:0] message;
        begin
            if (!condition) begin
                $display("錯誤：%0s，時間=%0t", message, $time);
                $finish;
            end
        end
    endtask

    task clear_inputs;
        begin
            material_valid = 1'b0;
            power_valid = 1'b0;
            labor_valid = 1'b0;
            material_data = 16'd0;
            power_data = 16'd0;
            labor_data = 16'd0;
        end
    endtask

    task send_material;
        input [`DATA_WIDTH-1:0] amount;
        begin
            material_data = amount;
            material_valid = 1'b1;
            @(posedge clk);
            check(material_ready, "商業區應接受物資輸入");
            material_valid = 1'b0;
            material_data = 16'd0;
        end
    endtask

    task send_power;
        input [`DATA_WIDTH-1:0] amount;
        begin
            power_data = amount;
            power_valid = 1'b1;
            @(posedge clk);
            check(power_ready, "商業區應接受電力輸入");
            power_valid = 1'b0;
            power_data = 16'd0;
        end
    endtask

    task send_labor;
        input [`DATA_WIDTH-1:0] amount;
        begin
            labor_data = amount;
            labor_valid = 1'b1;
            @(posedge clk);
            check(labor_ready, "商業區應接受勞動力輸入");
            labor_valid = 1'b0;
            labor_data = 16'd0;
        end
    endtask

    task wait_for_tax_valid;
        integer i;
        begin
            for (i = 0; i < 8 && !tax_valid; i = i + 1) begin
                @(posedge clk);
            end
            check(tax_valid, "商業區應產生稅收 valid");
            check(tax_data == 16'd10, "商業區稅收應為 10");
        end
    endtask

    initial begin
        clear_inputs();
        tax_ready = 1'b1;
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        check(!tax_valid, "reset 後不應立即輸出稅收");
        check(material_ready && power_ready && labor_ready,
               "reset 後三個輸入 ready 應為高");

        // 只送物資與電力，缺少勞動力時應等待，不可提前產生稅收。
        send_material(16'd2);
        send_power(16'd2);
        repeat (2) @(posedge clk);
        check(!tax_valid, "缺少勞動力時不應產生稅收");
        check(state == `S_WAIT, "缺少必要資源時應進入 S_WAIT");

        // 補上勞動力後，三種資源剛好完成一次商業區轉換。
        send_labor(16'd2);
        wait_for_tax_valid();
        check(debug_funds == 16'd10, "稅收尚未被接收前，debug_funds 應為 10");
        @(posedge clk);
        check(!tax_valid, "tax_ready 為高時，稅收應在握手後清除");

        // 測試下游 back-pressure：tax_ready 拉低時，稅收輸出必須保持。
        tax_ready = 1'b0;
        send_material(16'd2);
        send_power(16'd2);
        send_labor(16'd2);
        wait_for_tax_valid();
        repeat (3) begin
            @(posedge clk);
            check(tax_valid, "tax_ready 為低時，tax_valid 必須保持");
            check(tax_data == 16'd10, "tax_ready 為低時，tax_data 必須保持 10");
        end
        tax_ready = 1'b1;
        @(posedge clk);
        @(posedge clk);
        check(!tax_valid, "tax_ready 恢復後，稅收應完成握手並清除");

        // 大量物資入庫後，物資 ready 應依滿載規則拉低。
        send_material(16'd65000);
        @(posedge clk);
        check(!material_ready, "物資庫存達 65000 後 material_ready 應拉低");

        $display("通過：commerce_area 單元測試完成。");
        $finish;
    end

endmodule
