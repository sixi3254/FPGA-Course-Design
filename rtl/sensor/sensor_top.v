`timescale 1ns/1ps
`include "project_defs.vh"

// DEVELOPMENT PLACEHOLDER: interface complete, functional implementation pending.
module sensor_top(
    // 全局信号
    input  wire               clk,
    input  wire               rst,

    // 采样调度
    input  wire               tick_100hz,
    input  wire               tick_20hz,

    // 校准请求
    input  wire               cal_req,

    // 陀螺仪物理接口
    output wire               gyro_cs_n,
    output wire               gyro_sclk,
    output wire               gyro_mosi,
    input  wire               gyro_miso,

    // 环境光物理接口
    output wire               als_cs_n,
    output wire               als_sclk,
    input  wire               als_miso,

    // 输出给成员C
    output wire signed [17:0] gyro_x,
    output wire signed [17:0] gyro_y,
    output wire signed [17:0] gyro_z,
    output wire               gyro_valid,
    output wire               gyro_ready,
    output wire               gyro_fault,

    // 输出给成员B及顶层
    output wire [7:0]         als_data,
    output wire [7:0]         light_level,
    output wire               als_valid,
    output wire               light_ready,
    output wire [4:0]         brightness_gain
);

    // TODO(A): Replace these inactive outputs with sensor acquisition logic.
    // Gyro SPI idle: Mode 3. ALS SPI idle: Mode 0. No transaction starts.
    assign gyro_cs_n = 1'b1;
    assign gyro_sclk = 1'b1;
    assign gyro_mosi = 1'b0;
    assign als_cs_n = 1'b1;
    assign als_sclk = 1'b0;
    assign gyro_x = 18'sd0;
    assign gyro_y = 18'sd0;
    assign gyro_z = 18'sd0;
    assign gyro_valid = 1'b0;
    assign gyro_ready = 1'b0;
    assign gyro_fault = 1'b0;
    assign als_data = 8'd0;
    assign light_level = 8'd0;
    assign als_valid = 1'b0;
    assign light_ready = 1'b0;
    assign brightness_gain = `GAIN_DEFAULT;

endmodule
