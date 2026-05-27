`include "city_define.vh"

// 重工業區：消耗 3 電力 + 1 勞動力，產生 4 工業物資。
module industry_area #(
    parameter INIT_MATERIAL_STORE = `INIT_MATERIAL
) (
    input clk,
    input rst_n,

    input [`DATA_WIDTH-1:0] power_data,
    input power_valid,
    output power_ready,

    input [`DATA_WIDTH-1:0] labor_data,
    input labor_valid,
    output labor_ready,

    output [`DATA_WIDTH-1:0] material_data,
    output material_valid,
    input material_ready,

    output [2:0] state,
    output [`DATA_WIDTH-1:0] debug_material
);

    department_core #(
        .COST0(16'd3),
        .COST1(16'd1),
        .PRODUCT_AMOUNT(16'd4),
        .INIT_PRODUCT(INIT_MATERIAL_STORE)
    ) u_core (
        .clk(clk),
        .rst_n(rst_n),
        .in0_data(power_data),
        .in0_valid(power_valid),
        .in0_ready(power_ready),
        .in1_data(labor_data),
        .in1_valid(labor_valid),
        .in1_ready(labor_ready),
        .in2_data(16'd0),
        .in2_valid(1'b0),
        .in2_ready(),
        .out_data(material_data),
        .out_valid(material_valid),
        .out_ready(material_ready),
        .state(state),
        .debug_store0(),
        .debug_store1(),
        .debug_store2(),
        .debug_product(debug_material)
    );

endmodule
