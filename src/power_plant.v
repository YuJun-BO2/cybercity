`include "city_define.vh"

// 發電廠：消耗 2 資金 + 1 水，產生 5 電力。
module power_plant #(
    parameter INIT_WATER_STORE = `INIT_WATER
) (
    input clk,
    input rst_n,

    input [`DATA_WIDTH-1:0] fund_data,
    input fund_valid,
    output fund_ready,

    input [`DATA_WIDTH-1:0] water_data,
    input water_valid,
    output water_ready,

    output [`DATA_WIDTH-1:0] power_data,
    output power_valid,
    input power_ready,

    output [2:0] state,
    output [`DATA_WIDTH-1:0] debug_energy
);

    department_core #(
        .COST0(16'd2),
        .COST1(16'd1),
        .PRODUCT_AMOUNT(16'd5),
        .INIT_STORE1(INIT_WATER_STORE)
    ) u_core (
        .clk(clk),
        .rst_n(rst_n),
        .in0_data(fund_data),
        .in0_valid(fund_valid),
        .in0_ready(fund_ready),
        .in1_data(water_data),
        .in1_valid(water_valid),
        .in1_ready(water_ready),
        .in2_data(16'd0),
        .in2_valid(1'b0),
        .in2_ready(),
        .out_data(power_data),
        .out_valid(power_valid),
        .out_ready(power_ready),
        .state(state),
        .debug_store0(),
        .debug_store1(),
        .debug_store2(),
        .debug_product(debug_energy)
    );

endmodule
