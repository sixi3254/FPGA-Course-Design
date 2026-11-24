`ifndef PROJECT_DEFS_VH
`define PROJECT_DEFS_VH

// ======================================
// 全局硬件参数
// ======================================
`define SYS_CLK_FREQ   100_000_000
`define SPI_CLK_FREQ   2_000_000

`define SCREEN_WIDTH   640
`define SCREEN_HEIGHT  480
`define BALL_RADIUS    15

`define CENTER_X       320
`define CENTER_Y       240

`define BALL_X_MIN     15
`define BALL_X_MAX     624
`define BALL_Y_MIN     15
`define BALL_Y_MAX     464

// ======================================
// 定点数参数
// ======================================
`define FIXED_FRAC     16
`define FIXED_ONE      32'sd65536

`define ANGLE_COEFF    32'sd1468
`define ANGLE_SHIFT    8

`define ANGLE_MAX      32'sd1966080
`define VELOCITY_MAX   32'sd196608

`define DAMPING_SHIFT  6
`define GRAVITY_SHIFT  10

// ======================================
// 运动模式
// ======================================
`define MODE_RATE      2'b00
`define MODE_ANGLE     2'b01
`define MODE_TILT_VEL  2'b10
`define MODE_GRAVITY   2'b11

// ======================================
// 游戏状态
// ======================================
`define GAME_DEMO      3'b000
`define GAME_READY     3'b001
`define GAME_RUNNING   3'b010
`define GAME_PAUSED    3'b011
`define GAME_WIN       3'b100
`define GAME_LOSE      3'b101

`define GAME_START_X   70
`define GAME_START_Y   70
`define GAME_TIME      60

// ======================================
// 默认显示颜色与亮度
// ======================================
`define COLOR_BALL     12'h0FF
`define COLOR_BG       12'h112

`define GAIN_DEFAULT   5'd16

`endif
