`timescale 1ns/1ps
`include "project_defs.vh"

// DEVELOPMENT PLACEHOLDER: interface complete, functional implementation pending.
module motion_top(
    // 全局信号
    input  wire               clk,
    input  wire               rst,

    // 游戏计时使能
    input  wire               tick_100hz,

    // 传感器数据
    input  wire signed [17:0] gyro_x,
    input  wire signed [17:0] gyro_y,
    input  wire signed [17:0] gyro_z,
    input  wire               gyro_valid,
    input  wire               gyro_ready,

    // 系统控制
    input  wire [1:0]         mode,
    input  wire               game_enable,

    input  wire               cal_req,
    input  wire               recenter_req,
    input  wire               start_req,
    input  wire               game_reset_req,

    // 输出姿态
    output wire signed [31:0] angle_x,
    output wire signed [31:0] angle_y,

    // 输出速度
    output wire signed [31:0] velocity_x,
    output wire signed [31:0] velocity_y,

    // 输出显示坐标
    output wire [9:0]         ball_x,
    output wire [9:0]         ball_y,

    // 输出游戏信息
    output wire [2:0]         game_state,
    output wire [15:0]        score,
    output wire [6:0]         time_left
);

    // TODO(C): Replace with attitude, movement, collision and game logic.
    // Fixed initial scene only; no sensor sample is consumed or integrated.
    assign angle_x = 32'sd0;
    assign angle_y = 32'sd0;
    assign velocity_x = 32'sd0;
    assign velocity_y = 32'sd0;
    assign ball_x = game_enable ? `GAME_START_X : `CENTER_X;
    assign ball_y = game_enable ? `GAME_START_Y : `CENTER_Y;
    assign game_state = game_enable ? `GAME_READY : `GAME_DEMO;
    assign score = 16'd0;
    assign time_left = `GAME_TIME;

endmodule
