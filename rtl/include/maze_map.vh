`ifndef MAZE_MAP_VH
`define MAZE_MAP_VH
// Shared level-0 data only. Render/collision implementations remain TODO.
// All rectangles use half-open intervals [x0,x1) and [y0,y1).
`define MAZE_WALL_COUNT 4
`define WALL0_X0 140
`define WALL0_Y0 20
`define WALL0_X1 160
`define WALL0_Y1 200
`define WALL1_X0 300
`define WALL1_Y0 140
`define WALL1_X1 320
`define WALL1_Y1 380
`define WALL2_X0 440
`define WALL2_Y0 20
`define WALL2_X1 460
`define WALL2_Y1 300
`define WALL3_X0 140
`define WALL3_Y0 400
`define WALL3_X1 460
`define WALL3_Y1 420
`define GOAL_X0 550
`define GOAL_Y0 390
`define GOAL_X1 606
`define GOAL_Y1 446
`endif
