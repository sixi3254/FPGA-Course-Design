
`timescale 1ns/1ps

module gravity_boundary_top(

    input wire clk,
    input wire rst,

    // 姿态输入
    input wire angle_valid,
    input wire signed [31:0] angle_x,
    input wire signed [31:0] angle_y,

    // 初始位置装载
    input wire position_load,
    input wire signed [31:0] init_x,
    input wire signed [31:0] init_y,

    // 最终运动状态
    output wire signed [31:0] position_x,
    output wire signed [31:0] position_y,

    output wire signed [31:0] velocity_x,
    output wire signed [31:0] velocity_y,

    // 碰撞状态
    output wire correction_valid,

    output wire hit_left,
    output wire hit_right,
    output wire hit_top,
    output wire hit_bottom

);

    // 重力运动模块原始输出

    wire signed [31:0] raw_position_x;
    wire signed [31:0] raw_position_y;

    wire signed [31:0] raw_velocity_x;
    wire signed [31:0] raw_velocity_y;


    //边界模块修正输出

    wire signed [31:0] corrected_position_x;
    wire signed [31:0] corrected_position_y;

    wire signed [31:0] corrected_velocity_x;
    wire signed [31:0] corrected_velocity_y;


    //内部状态恢复信号

    wire restore_req;

    assign correction_valid = restore_req;

    //重力滚球

    gravity_motion u_gravity_motion(

        .clk(clk),
        .rst(rst),

        .angle_valid(angle_valid),

        .angle_x(angle_x),
        .angle_y(angle_y),

        .position_load(position_load),

        .init_x(init_x),
        .init_y(init_y),

        .state_restore(restore_req),

        .restore_position_x(corrected_position_x),
        .restore_position_y(corrected_position_y),

        .restore_velocity_x(corrected_velocity_x),
        .restore_velocity_y(corrected_velocity_y),

        .position_x(raw_position_x),
        .position_y(raw_position_y),

        .velocity_x(raw_velocity_x),
        .velocity_y(raw_velocity_y)

    );

    //边界检测


    boundary_detect u_boundary_detect(

        .position_x(raw_position_x),
        .position_y(raw_position_y),

        .velocity_x(raw_velocity_x),
        .velocity_y(raw_velocity_y),

        .corrected_position_x(corrected_position_x),
        .corrected_position_y(corrected_position_y),

        .corrected_velocity_x(corrected_velocity_x),
        .corrected_velocity_y(corrected_velocity_y),

        .correction_valid(restore_req),

        .hit_left(hit_left),
        .hit_right(hit_right),
        .hit_top(hit_top),
        .hit_bottom(hit_bottom)

    );

    //最终输出

    assign position_x = corrected_position_x;
    assign position_y = corrected_position_y;

    assign velocity_x = corrected_velocity_x;
    assign velocity_y = corrected_velocity_y;


endmodule
