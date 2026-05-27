`include "city_define.vh"

// 商業區：消耗 2 物資 + 2 電力 + 2 勞動力，產生 10 資金稅收。
module commerce_area (
    input clk,
    input rst_n,

    input [`DATA_WIDTH-1:0] material_data,
    input material_valid,
    output material_ready,

    input [`DATA_WIDTH-1:0] power_data,
    input power_valid,
    output power_ready,

    input [`DATA_WIDTH-1:0] labor_data,
    input labor_valid,
    output labor_ready,

    output [`DATA_WIDTH-1:0] tax_data,
    output tax_valid,
    input tax_ready,

    output [2:0] state,
    output [`DATA_WIDTH-1:0] debug_funds
);

    department_core #(
        .COST0(16'd2),
        .COST1(16'd2),
        .COST2(16'd2),
        .PRODUCT_AMOUNT(16'd10)
    ) u_core (
        .clk(clk),
        .rst_n(rst_n),
        .in0_data(material_data),
        .in0_valid(material_valid),
        .in0_ready(material_ready),
        .in1_data(power_data),
        .in1_valid(power_valid),
        .in1_ready(power_ready),
        .in2_data(labor_data),
        .in2_valid(labor_valid),
        .in2_ready(labor_ready),
        .out_data(tax_data),
        .out_valid(tax_valid),
        .out_ready(tax_ready),
        .state(state),
        .debug_store0(),
        .debug_store1(),
        .debug_store2(),
        .debug_product(debug_funds)
    );

endmodule
