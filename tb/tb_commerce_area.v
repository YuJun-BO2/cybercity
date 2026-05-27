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
                $display("ERROR: %0s; sim_time=%0t", message, $time);
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
            check(material_ready, "commerce_area should accept material input");
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
            check(power_ready, "commerce_area should accept power input");
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
            check(labor_ready, "commerce_area should accept labor input");
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
            check(tax_valid, "commerce_area should assert tax_valid");
            check(tax_data == 16'd10, "commerce_area tax_data should be 10");
        end
    endtask

    initial begin
        clear_inputs();
        tax_ready = 1'b1;
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        check(!tax_valid, "tax_valid should be low after reset");
        check(material_ready && power_ready && labor_ready,
               "all input ready signals should be high after reset");

        // 只送物資與電力，缺少勞動力時應等待，不可提前產生稅收。
        send_material(16'd2);
        send_power(16'd2);
        repeat (2) @(posedge clk);
        check(!tax_valid, "tax should not be produced without labor");
        check(state == `S_WAIT, "state should enter S_WAIT when required resources are missing");

        // 補上勞動力後，三種資源剛好完成一次商業區轉換。
        send_labor(16'd2);
        wait_for_tax_valid();
        check(debug_funds == 16'd10, "debug_funds should be 10 before tax is accepted");
        @(posedge clk);
        check(!tax_valid, "tax_valid should clear after handshake when tax_ready is high");

        // 測試下游反壓：稅收接收端不可接收時，稅收輸出必須保持。
        tax_ready = 1'b0;
        send_material(16'd2);
        send_power(16'd2);
        send_labor(16'd2);
        wait_for_tax_valid();
        repeat (3) begin
            @(posedge clk);
            check(tax_valid, "tax_valid should hold while tax_ready is low");
            check(tax_data == 16'd10, "tax_data should hold 10 while tax_ready is low");
        end
        tax_ready = 1'b1;
        @(posedge clk);
        @(posedge clk);
        check(!tax_valid, "tax_valid should clear after tax_ready returns high");

        // 大量物資入庫後，物資 ready 應依滿載規則拉低。
        send_material(16'd65000);
        @(posedge clk);
        check(!material_ready, "material_ready should go low after material storage reaches 65000");

        $display("PASS: commerce_area unit test completed.");
        $finish;
    end

endmodule
