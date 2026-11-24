`timescale 1ns/1ps
`include "project_defs.vh"

// Board shell. Business logic remains in the three placeholder subsystems.
module top #(
    parameter CLK_FREQ = `SYS_CLK_FREQ,
    parameter INPUT_STABLE_CYCLES = 1_000_000
)(
    input wire sys_clk,
    input wire rst_n,
    input wire [3:0] sw,
    input wire btn_center,
    input wire btn_up,
    input wire btn_right,
    input wire btn_down,
    output wire gyro_cs_n,
    output wire gyro_sclk,
    output wire gyro_mosi,
    input wire gyro_miso,
    output wire als_cs_n,
    output wire als_sclk,
    input wire als_miso,
    output wire vga_hsync,
    output wire vga_vsync,
    output wire [3:0] vga_r,
    output wire [3:0] vga_g,
    output wire [3:0] vga_b
);
    wire rst;
    wire pix_ce, tick_100hz, tick_20hz;
    wire [7:0] control_level, control_tick;
    wire [1:0] mode;
    wire game_enable, auto_light_en;
    wire cal_req, recenter_req, start_req, game_reset_req;
    wire signed [17:0] gyro_x, gyro_y, gyro_z;
    wire gyro_valid, gyro_ready, gyro_fault;
    wire [7:0] als_data, light_level;
    wire als_valid, light_ready;
    wire [4:0] brightness_gain, display_gain;
    wire signed [31:0] angle_x, angle_y, velocity_x, velocity_y;
    wire [9:0] ball_x, ball_y;
    wire [2:0] game_state;
    wire [15:0] score;
    wire [6:0] time_left;
    wire frame_tick;

    reset_sync u_reset (.clk(sys_clk), .rst_n(rst_n), .rst(rst));
    tick_gen #(.CLK_FREQ(CLK_FREQ)) u_tick (
        .clk(sys_clk), .rst(rst), .pix_ce(pix_ce),
        .tick_100hz(tick_100hz), .tick_20hz(tick_20hz)
    );
    key_debounce #(.WIDTH(8), .STABLE_CYCLES(INPUT_STABLE_CYCLES)) u_controls (
        .clk(sys_clk), .rst(rst),
        .key_in({btn_down, btn_right, btn_up, btn_center, sw}),
        .key_level(control_level), .key_tick(control_tick)
    );
    assign mode = control_level[1:0];
    assign game_enable = control_level[2] && (mode == `MODE_GRAVITY);
    assign auto_light_en = control_level[3];
    assign recenter_req = control_tick[4];
    assign cal_req = control_tick[5];
    assign start_req = control_tick[6];
    assign game_reset_req = control_tick[7];
    assign display_gain = (auto_light_en && light_ready)
                        ? brightness_gain : `GAIN_DEFAULT;

    sensor_top u_sensor (
        .clk(sys_clk),
        .rst(rst),
        .tick_100hz(tick_100hz),
        .tick_20hz(tick_20hz),
        .cal_req(cal_req),
        .gyro_cs_n(gyro_cs_n),
        .gyro_sclk(gyro_sclk),
        .gyro_mosi(gyro_mosi),
        .gyro_miso(gyro_miso),
        .als_cs_n(als_cs_n),
        .als_sclk(als_sclk),
        .als_miso(als_miso),
        .gyro_x(gyro_x),
        .gyro_y(gyro_y),
        .gyro_z(gyro_z),
        .gyro_valid(gyro_valid),
        .gyro_ready(gyro_ready),
        .gyro_fault(gyro_fault),
        .als_data(als_data),
        .light_level(light_level),
        .als_valid(als_valid),
        .light_ready(light_ready),
        .brightness_gain(brightness_gain)
    );

    motion_top u_motion (
        .clk(sys_clk),
        .rst(rst),
        .tick_100hz(tick_100hz),
        .gyro_x(gyro_x),
        .gyro_y(gyro_y),
        .gyro_z(gyro_z),
        .gyro_valid(gyro_valid),
        .gyro_ready(gyro_ready),
        .mode(mode),
        .game_enable(game_enable),
        .cal_req(cal_req),
        .recenter_req(recenter_req),
        .start_req(start_req),
        .game_reset_req(game_reset_req),
        .angle_x(angle_x),
        .angle_y(angle_y),
        .velocity_x(velocity_x),
        .velocity_y(velocity_y),
        .ball_x(ball_x),
        .ball_y(ball_y),
        .game_state(game_state),
        .score(score),
        .time_left(time_left)
    );

    video_top u_video (
        .clk(sys_clk),
        .rst(rst),
        .pix_ce(pix_ce),
        .mode(mode),
        .game_enable(game_enable),
        .ball_x(ball_x),
        .ball_y(ball_y),
        .angle_x(angle_x),
        .angle_y(angle_y),
        .velocity_x(velocity_x),
        .velocity_y(velocity_y),
        .light_level(light_level),
        .gyro_ready(gyro_ready),
        .gyro_fault(gyro_fault),
        .light_ready(light_ready),
        .display_gain(display_gain),
        .game_state(game_state),
        .score(score),
        .time_left(time_left),
        .vga_hsync(vga_hsync),
        .vga_vsync(vga_vsync),
        .vga_r(vga_r),
        .vga_g(vga_g),
        .vga_b(vga_b),
        .frame_tick(frame_tick)
    );

endmodule
