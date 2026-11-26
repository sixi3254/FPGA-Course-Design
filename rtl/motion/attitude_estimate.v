`timescale 1ns/1ps
module attitude_estimate (
    input wire clk,
    input wire rst,
    //原始数据
    input wire signed [17:0] gyro_x,
    input wire signed [17:0] gyro_y,
    input wire gyro_valid,
    input wire gyro_ready,
    //姿态归零请求
    input wire angle_reset,
    //姿态角输出
    output wire signed [31:0] angle_x,
    output wire signed [31:0] angle_y,
    output wire angle_valid
);
    //Q16.16定义参数
    localparam signed [31:0] ANGLE_MAX = 32'sd11796480;
    localparam signed [31:0] ANGLE_MIN = -32'sd11796480;
    // 用于33位加法比较，防止累加时溢出
    localparam signed [32:0] ANGLE_MAX_EXT = 33'sd11796480;
    localparam signed [32:0] ANGLE_MIN_EXT = -33'sd11796480;

    //输出是wire类型，所以要先用reg计算保存，再赋值给wire
    reg signed [31:0] angle_x_reg;
    reg signed [31:0] angle_y_reg;

    reg angle_valid_reg;

    assign angle_x = angle_x_reg;
    assign angle_y = angle_y_reg;
    assign angle_valid = angle_valid_reg;


    // 将一个18位有符号陀螺仪数据转换为角度增量
    // 公式：
    // delta = trunc(1468 * gyro_lsb / 256)
    function signed [31:0] gyro_to_delta;

        input signed [17:0] gyro_lsb;

        reg signed [29:0] product;
        reg signed [29:0] magnitude;
        reg signed [31:0] scaled_magnitude;
        
        begin
            //18位有符号数扩展为30位
            //再乘以1468
            product = $signed({{12{gyro_lsb[17]}}, gyro_lsb}) * 30'sd1468 ;
            //{12{gyro_lsb[17]}}将符号位复制12份拼接到gyro_lsb前，扩展成30位

            if(product<0) begin
                magnitude = -product;
                //取绝对值，向右移8位，即除以256
                scaled_magnitude = {10'd0, magnitude[29:8]};

                //恢复负号
                gyro_to_delta = -scaled_magnitude;
            end
            else begin
                magnitude =product;
                scaled_magnitude = {10'd0, magnitude[29:8]};
                gyro_to_delta = scaled_magnitude;
            end
        end

    endfunction

    //X、Y轴角度增量
    wire signed [31:0] delta_x;
    wire signed [31:0] delta_y;

    assign delta_x =gyro_to_delta(gyro_x);
    assign delta_y =gyro_to_delta(gyro_y);


    //扩展位宽，安全累加
    wire signed [32:0] angle_x_ext;
    wire signed [32:0] angle_y_ext;

    wire signed [32:0] delta_x_ext;
    wire signed [32:0] delta_y_ext;

    wire signed [32:0] angle_x_sum;
    wire signed [32:0] angle_y_sum;

    assign angle_x_ext = {angle_x_reg[31], angle_x_reg};//扩展位宽
    assign angle_y_ext = {angle_y_reg[31], angle_y_reg};

    assign delta_x_ext = {delta_x[31], delta_x};
    assign delta_y_ext = {delta_y[31], delta_y};

    // angle[k+1] = angle[k] +delta
    assign angle_x_sum = angle_x_ext + delta_x_ext;
    assign angle_y_sum = angle_y_ext + delta_y_ext;


    //姿态积分与饱和保护
    always @(posedge clk) begin
        if(rst) begin
            //全局复位
            angle_x_reg <= 32'sd0;
            angle_y_reg <= 32'sd0;
            angle_valid_reg <= 1'b0;
        end
        else begin
            //默认不产生有效脉冲
            angle_valid_reg<=1'd0;

            //姿态归零优先级高于正常积分
            if(angle_reset) begin
                angle_x_reg <= 32'sd0;
                angle_y_reg <= 32'sd0;
            end
            //只有有数据且传感器就绪才积分
            else if(gyro_valid && gyro_ready) begin
                //x轴积分以及保护保护(限幅)
                if(angle_x_sum > ANGLE_MAX_EXT)
                    angle_x_reg <= ANGLE_MAX;
                else if(angle_x_sum < ANGLE_MIN_EXT)
                    angle_x_reg <= ANGLE_MIN;
                else
                    angle_x_reg<=angle_x_sum[31:0];

                // Y轴积分及饱和保护
                if (angle_y_sum > ANGLE_MAX_EXT)
                    angle_y_reg <= ANGLE_MAX;

                else if (angle_y_sum < ANGLE_MIN_EXT)
                    angle_y_reg <= ANGLE_MIN;

                else
                    angle_y_reg <= angle_y_sum[31:0];


                // 表示本次姿态更新完成
                angle_valid_reg <= 1'b1;
            end

        end
    end
endmodule