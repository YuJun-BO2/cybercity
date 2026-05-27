`include "city_define.vh"

// 住宅區：消耗 1 水 + 1 電力，產生 3 勞動力。
module residential_area #(
    parameter INIT_LABOR_STORE = `INIT_LABOR
) (
    input clk,
    input rst_n,

    input [`DATA_WIDTH-1:0] water_data,
    input water_valid,
    output water_ready,

    input [`DATA_WIDTH-1:0] power_data,
    input power_valid,
    output power_ready,

    output [`DATA_WIDTH-1:0] labor_data,
    output labor_valid,
    input labor_ready,

    output [2:0] state,
    output [`DATA_WIDTH-1:0] debug_labor
);

    department_core #(
        .COST0(16'd1),
        .COST1(16'd1),
        .PRODUCT_AMOUNT(16'd3),
        .INIT_PRODUCT(INIT_LABOR_STORE)
    ) u_core (
        .clk(clk),
        .rst_n(rst_n),
        .in0_data(water_data),
        .in0_valid(water_valid),
        .in0_ready(water_ready),
        .in1_data(power_data),
        .in1_valid(power_valid),
        .in1_ready(power_ready),
        .in2_data(16'd0),
        .in2_valid(1'b0),
        .in2_ready(),
        .out_data(labor_data),
        .out_valid(labor_valid),
        .out_ready(labor_ready),
        .state(state),
        .debug_store0(),
        .debug_store1(),
        .debug_store2(),
        .debug_product(debug_labor)
    );

endmodule
