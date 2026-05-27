`include "city_define.vh"

// 淨水廠：消耗 2 資金 + 2 電力，產生 5 水。
module water_plant (
    input clk,
    input rst_n,

    input [`DATA_WIDTH-1:0] fund_data,
    input fund_valid,
    output fund_ready,

    input [`DATA_WIDTH-1:0] power_data,
    input power_valid,
    output power_ready,

    output [`DATA_WIDTH-1:0] water_data,
    output water_valid,
    input water_ready,

    output [2:0] state,
    output [`DATA_WIDTH-1:0] debug_water
);

    department_core #(
        .COST0(16'd2),
        .COST1(16'd2),
        .PRODUCT_AMOUNT(16'd5)
    ) u_core (
        .clk(clk),
        .rst_n(rst_n),
        .in0_data(fund_data),
        .in0_valid(fund_valid),
        .in0_ready(fund_ready),
        .in1_data(power_data),
        .in1_valid(power_valid),
        .in1_ready(power_ready),
        .in2_data(16'd0),
        .in2_valid(1'b0),
        .in2_ready(),
        .out_data(water_data),
        .out_valid(water_valid),
        .out_ready(water_ready),
        .state(state),
        .debug_store0(),
        .debug_store1(),
        .debug_store2(),
        .debug_product(debug_water)
    );

endmodule
