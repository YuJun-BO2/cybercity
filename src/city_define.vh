`ifndef CITY_DEFINE_VH
`define CITY_DEFINE_VH

// Shared simulation and resource width settings.
`define CLK_PERIOD 10
`define DATA_WIDTH 16

// Department FSM states required by the Cyber City specification.
`define S_IDLE   3'd0
`define S_WORK   3'd1
`define S_WAIT   3'd2
`define S_CRISIS 3'd3
`define S_DEAD   3'd4

// A department deasserts ready before the 16-bit counter can overflow.
`define RESOURCE_MAX   16'd65535
`define READY_LIMIT    16'd65000

// Beginner-mode reset resources from the project handout.
`define INIT_FUNDS     16'd10000
`define INIT_WATER     16'd500
`define INIT_LABOR     16'd500
`define INIT_MATERIAL  16'd100

`endif
