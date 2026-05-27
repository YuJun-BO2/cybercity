`timescale 1ns/1ps
`include "../src/city_define.vh"

// Runs the same integrated city under the three handout-defined initial
// conditions and checks that no module reaches S_DEAD during 1000 clocks.
module tb_cyber_city;

    reg clk;
    reg rst_n;

    wire [2:0] b_state_power;
    wire [2:0] b_state_water;
    wire [2:0] b_state_residential;
    wire [2:0] b_state_industry;
    wire [2:0] b_state_commerce;
    wire [2:0] b_state_government;
    wire [`DATA_WIDTH-1:0] b_funds;
    wire [`DATA_WIDTH-1:0] b_power;
    wire [`DATA_WIDTH-1:0] b_water;
    wire [`DATA_WIDTH-1:0] b_labor;
    wire [`DATA_WIDTH-1:0] b_material;
    wire [`DATA_WIDTH-1:0] b_commerce;

    wire [2:0] e_state_power;
    wire [2:0] e_state_water;
    wire [2:0] e_state_residential;
    wire [2:0] e_state_industry;
    wire [2:0] e_state_commerce;
    wire [2:0] e_state_government;
    wire [`DATA_WIDTH-1:0] e_funds;
    wire [`DATA_WIDTH-1:0] e_power;
    wire [`DATA_WIDTH-1:0] e_water;
    wire [`DATA_WIDTH-1:0] e_labor;
    wire [`DATA_WIDTH-1:0] e_material;
    wire [`DATA_WIDTH-1:0] e_commerce;

    wire [2:0] c_state_power;
    wire [2:0] c_state_water;
    wire [2:0] c_state_residential;
    wire [2:0] c_state_industry;
    wire [2:0] c_state_commerce;
    wire [2:0] c_state_government;
    wire [`DATA_WIDTH-1:0] c_funds;
    wire [`DATA_WIDTH-1:0] c_power;
    wire [`DATA_WIDTH-1:0] c_water;
    wire [`DATA_WIDTH-1:0] c_labor;
    wire [`DATA_WIDTH-1:0] c_material;
    wire [`DATA_WIDTH-1:0] c_commerce;

    // Beginner Mode: official generous starting inventory.
    cyber_city_top #(
        .INIT_GOV_FUNDS(16'd10000),
        .INIT_POWER_WATER(16'd500),
        .INIT_RES_LABOR(16'd500),
        .INIT_IND_MATERIAL(16'd100)
    ) u_beginner (
        .clk(clk),
        .rst_n(rst_n),
        .state_power(b_state_power),
        .state_water(b_state_water),
        .state_residential(b_state_residential),
        .state_industry(b_state_industry),
        .state_commerce(b_state_commerce),
        .state_government(b_state_government),
        .debug_funds(b_funds),
        .debug_power_energy(b_power),
        .debug_water_resource(b_water),
        .debug_labor_resource(b_labor),
        .debug_material_resource(b_material),
        .debug_commerce_funds(b_commerce)
    );

    // Expert Mode: low funds and water, no initial labor or materials.
    cyber_city_top #(
        .INIT_GOV_FUNDS(16'd100),
        .INIT_POWER_WATER(16'd20),
        .INIT_RES_LABOR(16'd0),
        .INIT_IND_MATERIAL(16'd0)
    ) u_expert (
        .clk(clk),
        .rst_n(rst_n),
        .state_power(e_state_power),
        .state_water(e_state_water),
        .state_residential(e_state_residential),
        .state_industry(e_state_industry),
        .state_commerce(e_state_commerce),
        .state_government(e_state_government),
        .debug_funds(e_funds),
        .debug_power_energy(e_power),
        .debug_water_resource(e_water),
        .debug_labor_resource(e_labor),
        .debug_material_resource(e_material),
        .debug_commerce_funds(e_commerce)
    );

    // 6-2 Challenge: minimum viable startup case.
    cyber_city_top #(
        .INIT_GOV_FUNDS(16'd6),
        .INIT_POWER_WATER(16'd2),
        .INIT_RES_LABOR(16'd0),
        .INIT_IND_MATERIAL(16'd0)
    ) u_challenge (
        .clk(clk),
        .rst_n(rst_n),
        .state_power(c_state_power),
        .state_water(c_state_water),
        .state_residential(c_state_residential),
        .state_industry(c_state_industry),
        .state_commerce(c_state_commerce),
        .state_government(c_state_government),
        .debug_funds(c_funds),
        .debug_power_energy(c_power),
        .debug_water_resource(c_water),
        .debug_labor_resource(c_labor),
        .debug_material_resource(c_material),
        .debug_commerce_funds(c_commerce)
    );

    // Shared test clock.
    initial begin
        clk = 1'b0;
        forever #(`CLK_PERIOD / 2) clk = ~clk;
    end

    // The RTL currently uses S_WAIT for resource starvation. Reaching S_DEAD
    // would indicate an unrecoverable state transition bug.
    task fail_if_dead;
        input [2:0] power_state;
        input [2:0] water_state;
        input [2:0] residential_state;
        input [2:0] industry_state;
        input [2:0] commerce_state;
        input [2:0] government_state;
        begin
            if ((power_state == `S_DEAD) ||
                (water_state == `S_DEAD) ||
                (residential_state == `S_DEAD) ||
                (industry_state == `S_DEAD) ||
                (commerce_state == `S_DEAD) ||
                (government_state == `S_DEAD)) begin
                $display("ERROR: a module entered S_DEAD at time %0t", $time);
                $finish;
            end
        end
    endtask

    task print_city;
        input [8*16-1:0] label_text;
        input [`DATA_WIDTH-1:0] funds;
        input [`DATA_WIDTH-1:0] power;
        input [`DATA_WIDTH-1:0] water;
        input [`DATA_WIDTH-1:0] labor;
        input [`DATA_WIDTH-1:0] material;
        input [`DATA_WIDTH-1:0] commerce;
        begin
            $display("%0s funds=%0d power=%0d water=%0d labor=%0d material=%0d commerce=%0d",
                     label_text, funds, power, water, labor, material, commerce);
        end
    endtask

    integer cycle;

    initial begin
        // Hold reset for a few edges so all three city instances start from
        // stable registered values.
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        rst_n = 1'b1;

        // The handout's beginner acceptance target is 1000 clocks; the tighter
        // modes run through the same duration for comparison.
        for (cycle = 0; cycle < 1000; cycle = cycle + 1) begin
            @(posedge clk);
            fail_if_dead(b_state_power, b_state_water, b_state_residential,
                         b_state_industry, b_state_commerce, b_state_government);
            fail_if_dead(e_state_power, e_state_water, e_state_residential,
                         e_state_industry, e_state_commerce, e_state_government);
            fail_if_dead(c_state_power, c_state_water, c_state_residential,
                         c_state_industry, c_state_commerce, c_state_government);
        end

        print_city("BEGINNER", b_funds, b_power, b_water, b_labor,
                   b_material, b_commerce);
        print_city("EXPERT", e_funds, e_power, e_water, e_labor,
                   e_material, e_commerce);
        print_city("CHALLENGE", c_funds, c_power, c_water, c_labor,
                   c_material, c_commerce);
        $display("PASS: Cyber City survived 1000 clocks in all modes.");
        $finish;
    end

endmodule
