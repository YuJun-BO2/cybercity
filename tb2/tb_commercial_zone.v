`timescale 1ns/1ps

module tb_commercial_zone;

    reg clk;
    reg rst_n;

    reg [15:0] material_data;
    reg material_valid;
    wire material_ready;

    reg [15:0] power_data;
    reg power_valid;
    wire power_ready;

    reg [15:0] labor_data;
    reg labor_valid;
    wire labor_ready;

    wire [15:0] money_data;
    wire money_valid;
    reg gov_ready;

    wire [2:0] state;

    commercial_zone dut (
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
        .money_data(money_data),
        .money_valid(money_valid),
        .gov_ready(gov_ready),
        .state(state)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task check;
        input condition;
        input [8*96-1:0] message;
        begin
            if (!condition) begin
                $display("ERROR: %0s; sim_time=%0t", message, $time);
                $finish;
            end
        end
    endtask

    task clear_inputs;
        begin
            material_data = 16'd0;
            material_valid = 1'b0;
            power_data = 16'd0;
            power_valid = 1'b0;
            labor_data = 16'd0;
            labor_valid = 1'b0;
        end
    endtask

    task send_resources;
        input [15:0] material_amount;
        input [15:0] power_amount;
        input [15:0] labor_amount;
        begin
            material_data = material_amount;
            power_data = power_amount;
            labor_data = labor_amount;
            material_valid = 1'b1;
            power_valid = 1'b1;
            labor_valid = 1'b1;
            @(posedge clk);
            check(material_ready && power_ready && labor_ready,
                  "commercial_zone should accept all three resource inputs");
            clear_inputs();
        end
    endtask

    task wait_for_money_valid;
        integer i;
        begin
            for (i = 0; i < 12 && !money_valid; i = i + 1) begin
                @(posedge clk);
            end
            check(money_valid, "commercial_zone should assert money_valid");
            check(money_data == 16'd10, "commercial_zone money_data should be 10");
        end
    endtask

    initial begin
        clear_inputs();
        gov_ready = 1'b0;
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        check(!money_valid, "money_valid should be low after reset");
        check(material_ready && power_ready && labor_ready,
              "ready signals should become high after reset");

        send_resources(16'd2, 16'd2, 16'd2);
        wait_for_money_valid();

        repeat (3) begin
            @(posedge clk);
            check(money_valid, "money_valid should hold while gov_ready is low");
            check(money_data == 16'd10, "money_data should hold 10 while gov_ready is low");
        end

        gov_ready = 1'b1;
        @(posedge clk);
        @(posedge clk);
        check(!money_valid, "money_valid should clear after government accepts money");

        gov_ready = 1'b0;
        send_resources(16'd4, 16'd4, 16'd4);
        wait_for_money_valid();
        check(money_data == 16'd10, "first produced money packet should be 10");

        gov_ready = 1'b1;
        @(posedge clk);
        gov_ready = 1'b0;
        wait_for_money_valid();
        check(money_data == 16'd10, "second produced money packet should be 10");

        $display("PASS: commercial_zone tb2 completed.");
        $finish;
    end

endmodule
