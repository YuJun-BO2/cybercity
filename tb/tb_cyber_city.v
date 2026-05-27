`timescale 1ns/1ps
`include "../src/city_define.vh"

// 使用題目定義的三組初始條件測試同一個城市整合模組，
// 並確認 1000 個 clock 內沒有任何部門進入 S_DEAD。
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

    // 新手模式：題目指定的寬鬆初始庫存。
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

    // 專家模式：低資金與低水量，勞動力與物資皆為 0。
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

    // 6-2 挑戰：最低可啟動資源。
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

    // 共用測試時脈。
    initial begin
        clk = 1'b0;
        forever #(`CLK_PERIOD / 2) clk = ~clk;
    end

    // RTL 以 S_WAIT 表示正常資源等待；若進入 S_DEAD，代表出現不可恢復的狀態錯誤。
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
                $display("錯誤：有模組在時間 %0t 進入 S_DEAD", $time);
                $finish;
            end
        end
    endtask

    task print_city;
        input [1:0] mode_id;
        input [`DATA_WIDTH-1:0] funds;
        input [`DATA_WIDTH-1:0] power;
        input [`DATA_WIDTH-1:0] water;
        input [`DATA_WIDTH-1:0] labor;
        input [`DATA_WIDTH-1:0] material;
        input [`DATA_WIDTH-1:0] commerce;
        begin
            case (mode_id)
                2'd0: $display("新手模式 資金=%0d 電力=%0d 水=%0d 勞動力=%0d 物資=%0d 商業資金=%0d",
                                funds, power, water, labor, material, commerce);
                2'd1: $display("專家模式 資金=%0d 電力=%0d 水=%0d 勞動力=%0d 物資=%0d 商業資金=%0d",
                                funds, power, water, labor, material, commerce);
                default: $display("6-2挑戰 資金=%0d 電力=%0d 水=%0d 勞動力=%0d 物資=%0d 商業資金=%0d",
                                  funds, power, water, labor, material, commerce);
            endcase
        end
    endtask

    integer cycle;

    initial begin
        // reset 維持數個時脈，讓三個城市實例都從穩定的註冊值開始。
        rst_n = 1'b0;
        repeat (3) @(posedge clk);
        rst_n = 1'b1;

        // 題目新手模式的驗收目標是 1000 個 clock；較困難模式也跑相同長度以便比較。
        for (cycle = 0; cycle < 1000; cycle = cycle + 1) begin
            @(posedge clk);
            fail_if_dead(b_state_power, b_state_water, b_state_residential,
                         b_state_industry, b_state_commerce, b_state_government);
            fail_if_dead(e_state_power, e_state_water, e_state_residential,
                         e_state_industry, e_state_commerce, e_state_government);
            fail_if_dead(c_state_power, c_state_water, c_state_residential,
                         c_state_industry, c_state_commerce, c_state_government);
        end

        print_city(2'd0, b_funds, b_power, b_water, b_labor,
                   b_material, b_commerce);
        print_city(2'd1, e_funds, e_power, e_water, e_labor,
                   e_material, e_commerce);
        print_city(2'd2, c_funds, c_power, c_water, c_labor,
                   c_material, c_commerce);
        $display("通過：Cyber City 在所有模式下都存活 1000 個 clock。");
        $finish;
    end

endmodule
