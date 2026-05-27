`include "city_define.vh"

// Cyber City 閉環經濟系統整合層。
//
// 資源流向：
//   中央政府資金 -> 發電廠 / 淨水廠
//   電力 -> 淨水廠 / 住宅區 / 重工業區 / 商業區
//   水 -> 發電廠 / 住宅區
//   住宅區勞動力 -> 重工業區 / 商業區
//   重工業區物資 -> 商業區
//   商業區稅收 -> 中央政府
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

    // 停用的政府資金通道固定 ready，避免意外 valid 脈波卡住仲裁器。
    assign unused_fund2_ready = 1'b1;
    assign unused_fund3_ready = 1'b1;
    assign unused_fund4_ready = 1'b1;

    // 中央政府負責供應直接消耗資金的兩個部門：發電廠與淨水廠。
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

    power_plant #(
        .INIT_WATER_STORE(INIT_POWER_WATER)
    ) u_power_plant (
        .clk(clk),
        .rst_n(rst_n),
        .fund_data(fund_power_data),
        .fund_valid(fund_power_valid),
        .fund_ready(fund_power_ready),
        .water_data(water_to_power_data),
        .water_valid(water_to_power_valid),
        .water_ready(water_to_power_ready),
        .power_data(power_out_data),
        .power_valid(power_out_valid),
        .power_ready(power_out_ready),
        .state(state_power),
        .debug_energy(debug_power_energy)
    );

    water_plant u_water_plant (
        .clk(clk),
        .rst_n(rst_n),
        .fund_data(fund_water_data),
        .fund_valid(fund_water_valid),
        .fund_ready(fund_water_ready),
        .power_data(power_to_water_data),
        .power_valid(power_to_water_valid),
        .power_ready(power_to_water_ready),
        .water_data(water_out_data),
        .water_valid(water_out_valid),
        .water_ready(water_out_ready),
        .state(state_water),
        .debug_water(debug_water_resource)
    );

    residential_area #(
        .INIT_LABOR_STORE(INIT_RES_LABOR)
    ) u_residential (
        .clk(clk),
        .rst_n(rst_n),
        .water_data(water_to_res_data),
        .water_valid(water_to_res_valid),
        .water_ready(water_to_res_ready),
        .power_data(power_to_res_data),
        .power_valid(power_to_res_valid),
        .power_ready(power_to_res_ready),
        .labor_data(labor_out_data),
        .labor_valid(labor_out_valid),
        .labor_ready(labor_out_ready),
        .state(state_residential),
        .debug_labor(debug_labor_resource)
    );

    industry_area #(
        .INIT_MATERIAL_STORE(INIT_IND_MATERIAL)
    ) u_industry (
        .clk(clk),
        .rst_n(rst_n),
        .power_data(power_to_ind_data),
        .power_valid(power_to_ind_valid),
        .power_ready(power_to_ind_ready),
        .labor_data(labor_to_ind_data),
        .labor_valid(labor_to_ind_valid),
        .labor_ready(labor_to_ind_ready),
        .material_data(material_out_data),
        .material_valid(material_out_valid),
        .material_ready(material_out_ready),
        .state(state_industry),
        .debug_material(debug_material_resource)
    );

    commerce_area u_commerce (
        .clk(clk),
        .rst_n(rst_n),
        .material_data(material_to_com_data),
        .material_valid(material_to_com_valid),
        .material_ready(material_to_com_ready),
        .power_data(power_to_com_data),
        .power_valid(power_to_com_valid),
        .power_ready(power_to_com_ready),
        .labor_data(labor_to_com_data),
        .labor_valid(labor_to_com_valid),
        .labor_ready(labor_to_com_ready),
        .tax_data(tax_data),
        .tax_valid(tax_valid),
        .tax_ready(tax_ready),
        .state(state_commerce),
        .debug_funds(debug_commerce_funds)
    );

    // 電力有四個下游消費者。
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

    // 水供應給發電廠與住宅區。
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

    // 勞動力供應給重工業區與商業區。
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

    // 題目公式中，工業物資只供應給商業區。
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
