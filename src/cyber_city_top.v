`include "city_define.vh"

module cyber_city_top #(
    parameter INIT_GOV_FUNDS = `INIT_FUNDS,
    parameter INIT_POWER_WATER = `INIT_WATER,
    parameter INIT_RES_LABOR = `INIT_LABOR,
    parameter INIT_IND_MATERIAL = `INIT_MATERIAL
) (
    input clk,
    input rst_n,

    output [2:0] state_power,
    output [2:0] state_water,
    output [2:0] state_residential,
    output [2:0] state_industry,
    output [2:0] state_commerce,
    output [2:0] state_government,

    output [`DATA_WIDTH-1:0] debug_funds,
    output [`DATA_WIDTH-1:0] debug_power_energy,
    output [`DATA_WIDTH-1:0] debug_water_resource,
    output [`DATA_WIDTH-1:0] debug_labor_resource,
    output [`DATA_WIDTH-1:0] debug_material_resource,
    output [`DATA_WIDTH-1:0] debug_commerce_funds
);

    wire [`DATA_WIDTH-1:0] fund_power_data;
    wire fund_power_valid;
    wire fund_power_ready;
    wire [`DATA_WIDTH-1:0] fund_water_data;
    wire fund_water_valid;
    wire fund_water_ready;
    wire [`DATA_WIDTH-1:0] unused_fund2_data;
    wire unused_fund2_valid;
    wire unused_fund2_ready;
    wire [`DATA_WIDTH-1:0] unused_fund3_data;
    wire unused_fund3_valid;
    wire unused_fund3_ready;
    wire [`DATA_WIDTH-1:0] unused_fund4_data;
    wire unused_fund4_valid;
    wire unused_fund4_ready;

    wire [`DATA_WIDTH-1:0] power_out_data;
    wire power_out_valid;
    wire power_out_ready;
    wire [`DATA_WIDTH-1:0] water_out_data;
    wire water_out_valid;
    wire water_out_ready;
    wire [`DATA_WIDTH-1:0] labor_out_data;
    wire labor_out_valid;
    wire labor_out_ready;
    wire [`DATA_WIDTH-1:0] material_out_data;
    wire material_out_valid;
    wire material_out_ready;
    wire [`DATA_WIDTH-1:0] tax_data;
    wire tax_valid;
    wire tax_ready;

    wire [`DATA_WIDTH-1:0] water_to_power_data;
    wire water_to_power_valid;
    wire water_to_power_ready;
    wire [`DATA_WIDTH-1:0] water_to_res_data;
    wire water_to_res_valid;
    wire water_to_res_ready;

    wire [`DATA_WIDTH-1:0] power_to_water_data;
    wire power_to_water_valid;
    wire power_to_water_ready;
    wire [`DATA_WIDTH-1:0] power_to_res_data;
    wire power_to_res_valid;
    wire power_to_res_ready;
    wire [`DATA_WIDTH-1:0] power_to_ind_data;
    wire power_to_ind_valid;
    wire power_to_ind_ready;
    wire [`DATA_WIDTH-1:0] power_to_com_data;
    wire power_to_com_valid;
    wire power_to_com_ready;

    wire [`DATA_WIDTH-1:0] labor_to_ind_data;
    wire labor_to_ind_valid;
    wire labor_to_ind_ready;
    wire [`DATA_WIDTH-1:0] labor_to_com_data;
    wire labor_to_com_valid;
    wire labor_to_com_ready;

    wire [`DATA_WIDTH-1:0] material_to_com_data;
    wire material_to_com_valid;
    wire material_to_com_ready;

    wire [`DATA_WIDTH-1:0] unused_store0;
    wire [`DATA_WIDTH-1:0] unused_store1;
    wire [`DATA_WIDTH-1:0] unused_store2;
    wire [`DATA_WIDTH-1:0] unused_product;

    assign unused_fund2_ready = 1'b1;
    assign unused_fund3_ready = 1'b1;
    assign unused_fund4_ready = 1'b1;

    government #(
        .INIT_FUNDS(INIT_GOV_FUNDS),
        .GRANT0(16'd2),
        .GRANT1(16'd2),
        .GRANT2(16'd0),
        .GRANT3(16'd0),
        .GRANT4(16'd0)
    ) u_government (
        .clk(clk),
        .rst_n(rst_n),
        .tax_data(tax_data),
        .tax_valid(tax_valid),
        .tax_ready(tax_ready),
        .fund0_data(fund_power_data),
        .fund0_valid(fund_power_valid),
        .fund0_ready(fund_power_ready),
        .fund1_data(fund_water_data),
        .fund1_valid(fund_water_valid),
        .fund1_ready(fund_water_ready),
        .fund2_data(unused_fund2_data),
        .fund2_valid(unused_fund2_valid),
        .fund2_ready(unused_fund2_ready),
        .fund3_data(unused_fund3_data),
        .fund3_valid(unused_fund3_valid),
        .fund3_ready(unused_fund3_ready),
        .fund4_data(unused_fund4_data),
        .fund4_valid(unused_fund4_valid),
        .fund4_ready(unused_fund4_ready),
        .state(state_government),
        .debug_funds(debug_funds)
    );

    department #(
        .COST0(16'd2),
        .COST1(16'd1),
        .PRODUCT_AMOUNT(16'd5),
        .INIT_STORE1(INIT_POWER_WATER)
    ) u_power_plant (
        .clk(clk),
        .rst_n(rst_n),
        .in0_data(fund_power_data),
        .in0_valid(fund_power_valid),
        .in0_ready(fund_power_ready),
        .in1_data(water_to_power_data),
        .in1_valid(water_to_power_valid),
        .in1_ready(water_to_power_ready),
        .in2_data(16'd0),
        .in2_valid(1'b0),
        .in2_ready(),
        .out_data(power_out_data),
        .out_valid(power_out_valid),
        .out_ready(power_out_ready),
        .state(state_power),
        .debug_store0(unused_store0),
        .debug_store1(unused_store1),
        .debug_store2(unused_store2),
        .debug_product(debug_power_energy)
    );

    department #(
        .COST0(16'd2),
        .COST1(16'd2),
        .PRODUCT_AMOUNT(16'd5)
    ) u_water_plant (
        .clk(clk),
        .rst_n(rst_n),
        .in0_data(fund_water_data),
        .in0_valid(fund_water_valid),
        .in0_ready(fund_water_ready),
        .in1_data(power_to_water_data),
        .in1_valid(power_to_water_valid),
        .in1_ready(power_to_water_ready),
        .in2_data(16'd0),
        .in2_valid(1'b0),
        .in2_ready(),
        .out_data(water_out_data),
        .out_valid(water_out_valid),
        .out_ready(water_out_ready),
        .state(state_water),
        .debug_store0(),
        .debug_store1(),
        .debug_store2(),
        .debug_product(debug_water_resource)
    );

    department #(
        .COST0(16'd1),
        .COST1(16'd1),
        .PRODUCT_AMOUNT(16'd3),
        .INIT_PRODUCT(INIT_RES_LABOR)
    ) u_residential (
        .clk(clk),
        .rst_n(rst_n),
        .in0_data(water_to_res_data),
        .in0_valid(water_to_res_valid),
        .in0_ready(water_to_res_ready),
        .in1_data(power_to_res_data),
        .in1_valid(power_to_res_valid),
        .in1_ready(power_to_res_ready),
        .in2_data(16'd0),
        .in2_valid(1'b0),
        .in2_ready(),
        .out_data(labor_out_data),
        .out_valid(labor_out_valid),
        .out_ready(labor_out_ready),
        .state(state_residential),
        .debug_store0(),
        .debug_store1(),
        .debug_store2(),
        .debug_product(debug_labor_resource)
    );

    department #(
        .COST0(16'd3),
        .COST1(16'd1),
        .PRODUCT_AMOUNT(16'd4),
        .INIT_PRODUCT(INIT_IND_MATERIAL)
    ) u_industry (
        .clk(clk),
        .rst_n(rst_n),
        .in0_data(power_to_ind_data),
        .in0_valid(power_to_ind_valid),
        .in0_ready(power_to_ind_ready),
        .in1_data(labor_to_ind_data),
        .in1_valid(labor_to_ind_valid),
        .in1_ready(labor_to_ind_ready),
        .in2_data(16'd0),
        .in2_valid(1'b0),
        .in2_ready(),
        .out_data(material_out_data),
        .out_valid(material_out_valid),
        .out_ready(material_out_ready),
        .state(state_industry),
        .debug_store0(),
        .debug_store1(),
        .debug_store2(),
        .debug_product(debug_material_resource)
    );

    department #(
        .COST0(16'd2),
        .COST1(16'd2),
        .COST2(16'd2),
        .PRODUCT_AMOUNT(16'd10)
    ) u_commerce (
        .clk(clk),
        .rst_n(rst_n),
        .in0_data(material_to_com_data),
        .in0_valid(material_to_com_valid),
        .in0_ready(material_to_com_ready),
        .in1_data(power_to_com_data),
        .in1_valid(power_to_com_valid),
        .in1_ready(power_to_com_ready),
        .in2_data(labor_to_com_data),
        .in2_valid(labor_to_com_valid),
        .in2_ready(labor_to_com_ready),
        .out_data(tax_data),
        .out_valid(tax_valid),
        .out_ready(tax_ready),
        .state(state_commerce),
        .debug_store0(),
        .debug_store1(),
        .debug_store2(),
        .debug_product(debug_commerce_funds)
    );

    resource_router4 #(
        .ENABLE0(1'b1),
        .ENABLE1(1'b1),
        .ENABLE2(1'b1),
        .ENABLE3(1'b1)
    ) u_power_router (
        .clk(clk),
        .rst_n(rst_n),
        .in_data(power_out_data),
        .in_valid(power_out_valid),
        .in_ready(power_out_ready),
        .out0_data(power_to_water_data),
        .out0_valid(power_to_water_valid),
        .out0_ready(power_to_water_ready),
        .out1_data(power_to_res_data),
        .out1_valid(power_to_res_valid),
        .out1_ready(power_to_res_ready),
        .out2_data(power_to_ind_data),
        .out2_valid(power_to_ind_valid),
        .out2_ready(power_to_ind_ready),
        .out3_data(power_to_com_data),
        .out3_valid(power_to_com_valid),
        .out3_ready(power_to_com_ready)
    );

    resource_router4 #(
        .ENABLE0(1'b1),
        .ENABLE1(1'b1),
        .ENABLE2(1'b0),
        .ENABLE3(1'b0)
    ) u_water_router (
        .clk(clk),
        .rst_n(rst_n),
        .in_data(water_out_data),
        .in_valid(water_out_valid),
        .in_ready(water_out_ready),
        .out0_data(water_to_power_data),
        .out0_valid(water_to_power_valid),
        .out0_ready(water_to_power_ready),
        .out1_data(water_to_res_data),
        .out1_valid(water_to_res_valid),
        .out1_ready(water_to_res_ready),
        .out2_data(),
        .out2_valid(),
        .out2_ready(1'b1),
        .out3_data(),
        .out3_valid(),
        .out3_ready(1'b1)
    );

    resource_router4 #(
        .ENABLE0(1'b1),
        .ENABLE1(1'b1),
        .ENABLE2(1'b0),
        .ENABLE3(1'b0)
    ) u_labor_router (
        .clk(clk),
        .rst_n(rst_n),
        .in_data(labor_out_data),
        .in_valid(labor_out_valid),
        .in_ready(labor_out_ready),
        .out0_data(labor_to_ind_data),
        .out0_valid(labor_to_ind_valid),
        .out0_ready(labor_to_ind_ready),
        .out1_data(labor_to_com_data),
        .out1_valid(labor_to_com_valid),
        .out1_ready(labor_to_com_ready),
        .out2_data(),
        .out2_valid(),
        .out2_ready(1'b1),
        .out3_data(),
        .out3_valid(),
        .out3_ready(1'b1)
    );

    resource_router4 #(
        .ENABLE0(1'b1),
        .ENABLE1(1'b0),
        .ENABLE2(1'b0),
        .ENABLE3(1'b0)
    ) u_material_router (
        .clk(clk),
        .rst_n(rst_n),
        .in_data(material_out_data),
        .in_valid(material_out_valid),
        .in_ready(material_out_ready),
        .out0_data(material_to_com_data),
        .out0_valid(material_to_com_valid),
        .out0_ready(material_to_com_ready),
        .out1_data(),
        .out1_valid(),
        .out1_ready(1'b1),
        .out2_data(),
        .out2_valid(),
        .out2_ready(1'b1),
        .out3_data(),
        .out3_valid(),
        .out3_ready(1'b1)
    );

endmodule
