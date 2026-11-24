`timescale 1ns/1ps
`include "project_defs.vh"

// DEVELOPMENT PLACEHOLDER: interface complete, functional implementation pending.
module video_top(
    // 全局信号
    input  wire               clk,
    input  wire               rst,
    input  wire               pix_ce,

    // 运动模式
    input  wire [1:0]         mode,
    input  wire               game_enable,

    // 运动数据
    input  wire [9:0]         ball_x,
    input  wire [9:0]         ball_y,

    input  wire signed [31:0] angle_x,
    input  wire signed [31:0] angle_y,

    input  wire signed [31:0] velocity_x,
    input  wire signed [31:0] velocity_y,

    // 传感器信息
    input  wire [7:0]         light_level,
    input  wire               gyro_ready,
    input  wire               gyro_fault,
    input  wire               light_ready,

    // 顶层选择后的亮度增益
    input  wire [4:0]         display_gain,

    // 游戏信息
    input  wire [2:0]         game_state,
    input  wire [15:0]        score,
    input  wire [6:0]         time_left,

    // VGA物理输出
    output wire               vga_hsync,
    output wire               vga_vsync,
    output wire [3:0]         vga_r,
    output wire [3:0]         vga_g,
    output wire [3:0]         vga_b,

    // 帧同步信号
    output wire               frame_tick
);

    // TODO(B): Replace with VGA timing, rendering, frame latch and RGB adjustment.
    // This placeholder does not generate a VGA signal or a frame_tick.
    assign vga_hsync = 1'b1;
    assign vga_vsync = 1'b1;
    assign vga_r = 4'd0;
    assign vga_g = 4'd0;
    assign vga_b = 4'd0;
    assign frame_tick = 1'b0;

endmodule
