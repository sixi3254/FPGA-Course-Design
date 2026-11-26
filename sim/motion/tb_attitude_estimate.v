`timescale 1ns/1ps

module tb_attitude_estimate;
//==================================================
// 1. 仿真信号定义
//==================================================
reg clk;
reg rst;
reg signed [17:0] gyro_x;
reg signed [17:0] gyro_y;
reg gyro_valid;
reg gyro_ready;
reg angle_reset;
wire signed [31:0] angle_x;
wire signed [31:0] angle_y;
wire angle_valid;
//==================================================
// 2. 实例化被测试模块
//==================================================
attitude_estimate uut(
.clk(clk),
.rst(rst),
.gyro_x(gyro_x),
.gyro_y(gyro_y),
.gyro_valid(gyro_valid),
.gyro_ready(gyro_ready),
.angle_reset(angle_reset),
.angle_x(angle_x),
.angle_y(angle_y),
.angle_valid(angle_valid)
);
//==================================================
// 3. 产生100MHz时钟
//==================================================
initial begin
clk = 1'b0;
end
always #5 clk = ~clk;
//==================================================
// 4. 产生一个陀螺仪有效样本
//==================================================
task send_sample;
input signed [17:0] gx;
input signed [17:0] gy;
begin
@(negedge clk);
gyro_x = gx;
gyro_y = gy;
gyro_valid = 1'b1;
// 等待模块接收数据
@(negedge clk);
gyro_valid = 1'b0;
end
endtask
//==================================================
// 5. 主测试程序
//==================================================
initial begin
// 初始化
rst = 1'b1;
gyro_x = 18'sd0;
gyro_y = 18'sd0;
gyro_valid = 1'b0;
gyro_ready = 1'b1;
angle_reset = 1'b0;
// 等待复位
repeat(3) @(posedge clk);
@(negedge clk);
rst = 1'b0;
//==============================================
// 测试1：无效数据不能积分
//==============================================
gyro_x = 18'sd1000;
gyro_y = 18'sd1000;
gyro_valid = 1'b0;
repeat(5) @(posedge clk);
#1;
if (angle_x !== 32'sd0 ||
angle_y !== 32'sd0) begin
$display("ERROR: Invalid sample test failed");
$stop;
end
$display("PASS: Invalid sample test");
//==============================================
// 测试2：正角速度积分
//==============================================
// 连续输入100个样本
// X轴：+1000 LSB
// Y轴：-500 LSB
repeat(100)
send_sample(18'sd1000, -18'sd500);
#1;
$display("Test 2:");
$display("angle_x = %0d", angle_x);
$display("angle_y = %0d", angle_y);
if (angle_x !== 32'sd573400 ||
angle_y !== -32'sd286700) begin
$display("ERROR: Positive integration failed");
$stop;
end
$display("PASS: Positive integration");
//==============================================
// 测试3：姿态归零
//==============================================
@(negedge clk);
angle_reset = 1'b1;
@(negedge clk);
angle_reset = 1'b0;
#1;
if (angle_x !== 32'sd0 ||
angle_y !== 32'sd0) begin
$display("ERROR: Angle reset failed");
$stop;
end
$display("PASS: Angle reset");
//==============================================
// 测试4：传感器未就绪不能积分
//==============================================
gyro_ready = 1'b0;
repeat(10)
send_sample(18'sd1000, 18'sd1000);
#1;
if (angle_x !== 32'sd0 ||
angle_y !== 32'sd0) begin
$display("ERROR: Gyro ready test failed");
$stop;
end
$display("PASS: Gyro ready test");
//==============================================
// 测试5：负角速度积分
//==============================================
gyro_ready = 1'b1;
repeat(100)
send_sample(-18'sd1000, 18'sd500);
#1;
$display("Test 5:");
$display("angle_x = %0d", angle_x);
$display("angle_y = %0d", angle_y);
if (angle_x !== -32'sd573400 ||
angle_y !== 32'sd286700) begin
$display("ERROR: Negative integration failed");
$stop;
end
$display("PASS: Negative integration");
//==============================================
// 测试完成
//==============================================
$display("--------------------------------");
$display("ALL ATTITUDE TESTS PASSED!");
$display("--------------------------------");
$finish;
end
endmodule