`timescale 1ns/1ps

module tb_boundary_detect;
reg signed [31:0] position_x;
reg signed [31:0] position_y;
reg signed [31:0] velocity_x;
reg signed [31:0] velocity_y;
wire signed [31:0] corrected_position_x;
wire signed [31:0] corrected_position_y;
wire signed [31:0] corrected_velocity_x;
wire signed [31:0] corrected_velocity_y;
wire correction_valid;
wire hit_left;
wire hit_right;
wire hit_top;
wire hit_bottom;
//==================================================
// 实例化边界检测模块
//==================================================
boundary_detect uut(
.position_x(position_x),
.position_y(position_y),
.velocity_x(velocity_x),
.velocity_y(velocity_y),
.corrected_position_x(corrected_position_x),
.corrected_position_y(corrected_position_y),
.corrected_velocity_x(corrected_velocity_x),
.corrected_velocity_y(corrected_velocity_y),
.correction_valid(correction_valid),
.hit_left(hit_left),
.hit_right(hit_right),
.hit_top(hit_top),
.hit_bottom(hit_bottom)
);
initial begin
// 初始值
position_x = 0;
position_y = 0;
velocity_x = 0;
velocity_y = 0;
//==============================================
// 测试1：正常运动
//==============================================
position_x = 32'sd20971520;  // 320
position_y = 32'sd15728640;  // 240
velocity_x = 32'sd65536;
velocity_y = -32'sd65536;
#10;
if (correction_valid !== 1'b0 ||
corrected_position_x !== position_x ||
corrected_position_y !== position_y) begin
$display("ERROR: Normal movement failed");
$stop;
end
$display("PASS: Normal movement");
//==============================================
// 测试2：右边界反弹
//==============================================
// X = 624.5
position_x = 32'sd40927232;
velocity_x = 32'sd131072;
#10;
if (corrected_position_x !== 32'sd40894464 ||
corrected_velocity_x !== -32'sd65536 ||
hit_right !== 1'b1) begin
$display("ERROR: Right boundary failed");
$stop;
end
$display("PASS: Right boundary");
//==============================================
// 测试3：左边界反弹
//==============================================
// X = 14.5
position_x = 32'sd950272;
velocity_x = -32'sd131072;
#10;
if (corrected_position_x !== 32'sd983040 ||
corrected_velocity_x !== 32'sd65536 ||
hit_left !== 1'b1) begin
$display("ERROR: Left boundary failed");
$stop;
end
$display("PASS: Left boundary");
//==============================================
// 测试4：上边界反弹
//==============================================
// Y = 14.5
position_y = 32'sd950272;
velocity_y = -32'sd98304;
#10;
if (corrected_position_y !== 32'sd983040 ||
corrected_velocity_y !== 32'sd49152 ||
hit_top !== 1'b1) begin
$display("ERROR: Top boundary failed");
$stop;
end
$display("PASS: Top boundary");
//==============================================
// 测试5：下边界反弹
//==============================================
// Y = 464.5
position_y = 32'sd30441472;
velocity_y = 32'sd131072;
#10;
if (corrected_position_y !== 32'sd30408704 ||
corrected_velocity_y !== -32'sd65536 ||
hit_bottom !== 1'b1) begin
$display("ERROR: Bottom boundary failed");
$stop;
end
$display("PASS: Bottom boundary");
//==============================================
// 测试6：右下角同时碰撞
//==============================================
position_x = 32'sd40927232;
position_y = 32'sd30441472;
velocity_x = 32'sd131072;
velocity_y = 32'sd98304;
#10;
if (corrected_position_x !== 32'sd40894464 ||
corrected_position_y !== 32'sd30408704 ||
corrected_velocity_x !== -32'sd65536 ||
corrected_velocity_y !== -32'sd49152 ||
hit_right !== 1'b1 ||
hit_bottom !== 1'b1) begin
$display("ERROR: Corner collision failed");
$stop;
end
$display("PASS: Corner collision");
//==============================================
// 测试7：越界但已经向内部运动
//==============================================
position_x = 32'sd40960000;
// 速度已经向左
velocity_x = -32'sd65536;
#10;
if (corrected_position_x !== 32'sd40894464 ||
corrected_velocity_x !== -32'sd65536 ||
correction_valid !== 1'b1 ||
hit_right !== 1'b0) begin
$display("ERROR: Inward movement test failed");
$stop;
end
$display("PASS: Inward movement");
//==============================================
// 测试结束
//==============================================
$display("--------------------------------");
$display("ALL BOUNDARY TESTS PASSED!");
$display("--------------------------------");
$finish;
end
endmodule