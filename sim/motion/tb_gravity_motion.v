`timescale 1ns/1ps

module tb_gravity_motion;
//==================================================
// 1. 仿真信号
//==================================================
reg clk;
reg rst;
reg angle_valid;
reg signed [31:0] angle_x;
reg signed [31:0] angle_y;
reg position_load;
reg signed [31:0] init_x;
reg signed [31:0] init_y;
wire signed [31:0] position_x;
wire signed [31:0] position_y;
wire signed [31:0] velocity_x;
wire signed [31:0] velocity_y;
//==================================================
// 2. 实例化被测模块
//==================================================
gravity_motion uut(
.clk(clk),
.rst(rst),
.angle_valid(angle_valid),
.angle_x(angle_x),
.angle_y(angle_y),
.position_load(position_load),
.init_x(init_x),
.init_y(init_y),
.state_restore(1'b0),
.restore_position_x(32'sd0),
.restore_position_y(32'sd0),
.restore_velocity_x(32'sd0),
.restore_velocity_y(32'sd0),
.position_x(position_x),
.position_y(position_y),
.velocity_x(velocity_x),
.velocity_y(velocity_y)
);
//==================================================
// 3. 产生100MHz时钟
//==================================================
initial clk = 1'b0;
always #5 clk = ~clk;
//==================================================
// 4. 系统复位任务
//==================================================
task apply_reset;
begin
@(negedge clk);
rst = 1'b1;
angle_valid = 1'b0;
position_load = 1'b0;
repeat(2)
@(negedge clk);
rst = 1'b0;
#1;
end
endtask
//==================================================
// 5. 输入一组姿态数据
//==================================================
task send_angle;
input signed [31:0] ax;
input signed [31:0] ay;
begin
@(negedge clk);
angle_x = ax;
angle_y = ay;
angle_valid = 1'b1;
@(negedge clk);
angle_valid = 1'b0;
#1;
end
endtask
//==================================================
// 6. 装载初始位置
//==================================================
task load_position;
input signed [31:0] ix;
input signed [31:0] iy;
begin
@(negedge clk);
init_x = ix;
init_y = iy;
position_load = 1'b1;
@(negedge clk);
position_load = 1'b0;
#1;
end
endtask
//==================================================
// 7. 主测试程序
//==================================================
initial begin
// 初始信号
rst = 1'b0;
angle_valid = 1'b0;
angle_x = 32'sd0;
angle_y = 32'sd0;
position_load = 1'b0;
init_x = 32'sd0;
init_y = 32'sd0;
//==============================================
// 测试1：复位及初始位置
//==============================================
apply_reset();
if (position_x !== 32'sd20971520 ||
position_y !== 32'sd15728640 ||
velocity_x !== 32'sd0 ||
velocity_y !== 32'sd0) begin
$display("ERROR: Initial position test failed");
$stop;
end
$display("PASS: Initial position test");
//==============================================
// 测试2：16度倾斜，第一次更新
//==============================================
// angle_y = 16度
// angle_x = 0度
send_angle(32'sd0, 32'sd1048576);
$display("Test 2 - First update:");
$display("velocity_x = %0d", velocity_x);
$display("position_x = %0d", position_x);
if (velocity_x !== 32'sd1024 ||
position_x !== 32'sd20972544) begin
$display("ERROR: First update failed");
$stop;
end
$display("PASS: First update");
//==============================================
// 测试3：16度倾斜，第二次更新
//==============================================
send_angle(32'sd0, 32'sd1048576);
$display("Test 3 - Second update:");
$display("velocity_x = %0d", velocity_x);
$display("position_x = %0d", position_x);
if (velocity_x !== 32'sd2032 ||
position_x !== 32'sd20974576) begin
$display("ERROR: Second update failed");
$stop;
end
$display("PASS: Second update");
//==============================================
// 测试4：angle_valid无效时保持状态
//==============================================
repeat(5)
@(posedge clk);
#1;
if (velocity_x !== 32'sd2032 ||
position_x !== 32'sd20974576) begin
$display("ERROR: Invalid update test failed");
$stop;
end
$display("PASS: Invalid update hold");
//==============================================
// 测试5：倾角死区
//==============================================
apply_reset();
// 0.25度，小于0.5度死区
send_angle(32'sd0, 32'sd16384);
if (velocity_x !== 32'sd0 ||
position_x !== 32'sd20971520) begin
$display("ERROR: Deadzone test failed");
$stop;
end
$display("PASS: Angle deadzone");
//==============================================
// 测试6：负角度运动
//==============================================
apply_reset();
send_angle(32'sd0, -32'sd1048576);
if (velocity_x !== -32'sd1024 ||
position_x !== 32'sd20970496) begin
$display("ERROR: Negative first update failed");
$stop;
end
send_angle(32'sd0, -32'sd1048576);
if (velocity_x !== -32'sd2032 ||
position_x !== 32'sd20968464) begin
$display("ERROR: Negative second update failed");
$stop;
end
$display("PASS: Negative angle movement");
//==============================================
// 测试7：Y轴运动
//==============================================
apply_reset();
// angle_x控制Y方向
send_angle(32'sd1048576, 32'sd0);
if (velocity_y !== 32'sd1024 ||
position_y !== 32'sd15729664) begin
$display("ERROR: Y axis test failed");
$stop;
end
$display("PASS: Y axis movement");
//==============================================
// 测试8：自定义初始位置
//==============================================
apply_reset();
// 游戏模式起点：(70,70)
load_position(32'sd4587520, 32'sd4587520);
if (position_x !== 32'sd4587520 ||
position_y !== 32'sd4587520 ||
velocity_x !== 32'sd0 ||
velocity_y !== 32'sd0) begin
$display("ERROR: Position load test failed");
$stop;
end
$display("PASS: Position load");
//==============================================
// 测试9：速度限幅
//==============================================
apply_reset();
// 180度持续输入40次
repeat(40)
send_angle(32'sd0, 32'sd11796480);
$display("Test 9:");
$display("velocity_x = %0d", velocity_x);
if (velocity_x !== 32'sd196608) begin
$display("ERROR: Velocity limit test failed");
$stop;
end
$display("PASS: Velocity limit");
//==============================================
// 测试10：恢复水平，阻尼使速度逐渐归零
//==============================================
// 继续输入0度，模拟开发板恢复水平
repeat(500)
send_angle(32'sd0, 32'sd0);
if (velocity_x !== 32'sd0) begin
$display("ERROR: Damping stop test failed");
$stop;
end
$display("PASS: Damping stop");
//==============================================
// 测试结束
//==============================================
$display("-----------------------------------");
$display("ALL GRAVITY MOTION TESTS PASSED!");
$display("-----------------------------------");
$finish;
end
endmodule