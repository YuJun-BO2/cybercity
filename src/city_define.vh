`ifndef CITY_DEFINE_VH
`define CITY_DEFINE_VH

// 共用模擬參數與資源資料寬度。
`define CLK_PERIOD 10
`define DATA_WIDTH 16

// Cyber City 規格要求的部門 FSM 狀態。
`define S_IDLE   3'd0
`define S_WORK   3'd1
`define S_WAIT   3'd2
`define S_CRISIS 3'd3
`define S_DEAD   3'd4

// 在 16-bit 計數器溢位前提前拉低 ready。
`define RESOURCE_MAX   16'd65535
`define READY_LIMIT    16'd65000

// 題目新手模式指定的 reset 初始資源。
`define INIT_FUNDS     16'd10000
`define INIT_WATER     16'd500
`define INIT_LABOR     16'd500
`define INIT_MATERIAL  16'd100

`endif
