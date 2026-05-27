`timescale 1ns/1ps

module tb_city;

    reg clk;
    reg rst_n;

    reg resource_valid;
    wire resource_ready;
    reg [47:0] resource_data;

    wire [15:0] out_money;
    wire out_valid;
    reg gov_ready;

    wire [2:0] current_state;

    city dut (
        .clk(clk),
        .rst_n(rst_n),
        .resource_valid(resource_valid),
        .resource_ready(resource_ready),
        .resource_data(resource_data),
        .out_money(out_money),
        .out_valid(out_valid),
        .gov_ready(gov_ready),
        .current_state(current_state)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task check;
        input condition;
        input [8*128-1:0] message;
        begin
            if (!condition) begin
                $display("ERROR: %0s; sim_time=%0t state=%0d ready=%0b valid=%0b out_valid=%0b out_money=%0d",
                         message, $time, current_state, resource_ready,
                         resource_valid, out_valid, out_money);
                $fatal(1);
            end
        end
    endtask

    task clear_inputs;
        begin
            resource_valid = 1'b0;
            resource_data = 48'd0;
        end
    endtask

    task send_resource_packet;
        input [15:0] material_amount;
        input [15:0] power_amount;
        input [15:0] labor_amount;
        integer i;
        begin
            resource_data = {material_amount, power_amount, labor_amount};
            resource_valid = 1'b1;

            for (i = 0; i < 12 && !resource_ready; i = i + 1) begin
                @(posedge clk);
            end

            check(resource_ready,
                  "resource_ready stayed low while a valid resource packet was waiting");

            @(posedge clk);
            clear_inputs();
        end
    endtask

    task wait_for_money;
        integer i;
        begin
            for (i = 0; i < 20 && !out_valid; i = i + 1) begin
                @(posedge clk);
            end

            check(out_valid, "city should assert out_valid after receiving enough resources");
            check(out_money == 16'd10, "city should output 10 money per production");
        end
    endtask

    initial begin
        clear_inputs();
        gov_ready = 1'b0;
        rst_n = 1'b0;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        @(posedge clk);

        check(current_state == 3'd0, "city should start in S_IDLE after reset");
        check(!out_valid, "out_valid should be low after reset");
        check(out_money == 16'd0, "out_money should be zero after reset");

        send_resource_packet(16'd2, 16'd2, 16'd2);
        wait_for_money();

        repeat (3) begin
            @(posedge clk);
            check(out_valid, "out_valid should hold while gov_ready is low");
            check(out_money == 16'd10, "out_money should hold 10 while gov_ready is low");
        end

        gov_ready = 1'b1;
        @(posedge clk);
        @(posedge clk);
        check(!out_valid, "out_valid should clear after government accepts money");

        $display("PASS: src3 city tb3 completed.");
        $finish;
    end

endmodule
