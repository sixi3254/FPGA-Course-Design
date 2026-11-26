`timescale 1ns/1ps
module gravity_motion (
    //时钟
    input wire clk,
    input wire rst,

    //姿态输入
    input wire angle_valid,

    input wire signed [31:0] angle_x,
    input wire signed [31:0] angle_y,

    //初始位置装载
    input wire position_load,
    input wire signed [31:0] init_x,
    input wire signed [31:0] init_y,

    //边界碰撞状态恢复接口
    input wire state_restore,
    input wire signed [31:0] restore_position_x,
    input wire signed [31:0] restore_position_y,
    input wire signed [31:0] restore_velocity_x,
    input wire signed [31:0] restore_velocity_y,

 
    //输出位置和速度
    output wire signed [31:0] position_x,
    output wire signed [31:0] position_y,

    output wire signed [31:0] velocity_x,
    output wire signed [31:0] velocity_y

);

    //参数定义 Q16.16定点数
    //死区0.5°
    localparam signed [31:0] ANGLE_DEADZONE = 32'sd32768;
    // 1/256 pixel/tick 对应的定点数
    localparam signed [31:0] STOP_THRESHOLD = 32'sd256;
    // 最大速度：3 pixel/tick
    localparam signed [31:0] VELOCITY_MAX = 32'sd196608;
    // 34位扩展常量，供中间运算比较
    localparam signed [33:0] VELOCITY_MAX_EXT = 34'sd196608;

    localparam signed [33:0] VELOCITY_MIN_EXT = -34'sd196608;

    // 普通模式初始位置 (320,240)
    localparam signed [31:0] DEFAULT_X = 32'sd20971520;

    localparam signed [31:0] DEFAULT_Y = 32'sd15728640;



    reg signed [31:0] position_x_reg;
    reg signed [31:0] position_y_reg;

    reg signed [31:0] velocity_x_reg;
    reg signed [31:0] velocity_y_reg;
    //输出连接
    assign position_x = position_x_reg;
    assign position_y = position_y_reg;

    assign velocity_x = velocity_x_reg;
    assign velocity_y = velocity_y_reg;

    // 判断倾角是否超出死区
    // X方向运动由 angle_y 控制
    wire tilt_x_active;

    assign tilt_x_active =
        (angle_y > ANGLE_DEADZONE) ||
        (angle_y < -ANGLE_DEADZONE);


    // Y方向运动由 angle_x 控制
    wire tilt_y_active;

    assign tilt_y_active =
        (angle_x > ANGLE_DEADZONE) ||
        (angle_x < -ANGLE_DEADZONE);


    //计算加速度映射值
    wire signed [31:0] accel_x;
    wire signed [31:0] accel_y;

    assign accel_x = tilt_x_active ? (angle_y / 32'sd1024) : 32'sd0;
    assign accel_y = tilt_y_active ? (angle_x / 32'sd1024) : 32'sd0;

    //计算阻尼值
    wire signed [31:0] drag_x;
    wire signed [31:0] drag_y;

    assign drag_x = velocity_x_reg / 32'sd64;
    assign drag_y = velocity_y_reg / 32'sd64;


    //扩展位宽，计算下一时刻速度
    wire signed [33:0] velocity_x_sum;
    wire signed [33:0] velocity_y_sum;

    //u[k+1]=63/64u[k]+angle/1024
    assign velocity_x_sum =
          {{2{velocity_x_reg[31]}}, velocity_x_reg}
        - {{2{drag_x[31]}}, drag_x}
        + {{2{accel_x[31]}}, accel_x};

    assign velocity_y_sum =
          {{2{velocity_y_reg[31]}}, velocity_y_reg}
        - {{2{drag_y[31]}}, drag_y}
        + {{2{accel_y[31]}}, accel_y};


    //速度死区，限幅和下一状态计算
    reg signed [31:0] velocity_x_next;
    reg signed [31:0] velocity_y_next;
    
    always @(*) begin
        
        //x方向
        //无效，在死区内
        if((!tilt_x_active) &&
            (velocity_x_reg < STOP_THRESHOLD) &&
            (velocity_x_reg > -STOP_THRESHOLD))
        begin
            velocity_x_next = 32'sd0;
        end
        //限幅
        else if(velocity_x_sum > VELOCITY_MAX_EXT)begin
            velocity_x_next = VELOCITY_MAX;
        end
        else if(velocity_x_sum < VELOCITY_MIN_EXT)begin
            velocity_x_next = -VELOCITY_MAX;
        end
        else begin
            velocity_x_next = velocity_x_sum[31:0];
        end


        // Y方向
        if ((!tilt_y_active) &&
            (velocity_y_reg < STOP_THRESHOLD) &&
            (velocity_y_reg > -STOP_THRESHOLD)) begin

            velocity_y_next = 32'sd0;

        end
        else if (velocity_y_sum > VELOCITY_MAX_EXT) begin

            velocity_y_next = VELOCITY_MAX;

        end
        else if (velocity_y_sum < VELOCITY_MIN_EXT) begin

            velocity_y_next = -VELOCITY_MAX;

        end
        else begin

            velocity_y_next = velocity_y_sum[31:0];

        end
    end


    //时序逻辑，更新位置和速度
    always @(posedge clk) begin
        
        if(rst)begin
            // 全局复位：普通模式中心位置
            position_x_reg <= DEFAULT_X;
            position_y_reg <= DEFAULT_Y;

            velocity_x_reg <= 32'sd0;
            velocity_y_reg <= 32'sd0;
        end

        else if(position_load)begin
            // 装载新的初始位置
            position_x_reg <= init_x;
            position_y_reg <= init_y;

            // 重新开始时速度归零
            velocity_x_reg <= 32'sd0;
            velocity_y_reg <= 32'sd0;
        end

        else if(state_restore)begin
            //碰撞后恢复修正状态
            position_x_reg <= restore_position_x;
            position_y_reg <= restore_position_y;

            velocity_x_reg <= restore_velocity_x;
            velocity_y_reg <= restore_velocity_y;

        end
        else if(angle_valid)begin
            
            //更新速度
            velocity_x_reg <= velocity_x_next;
            velocity_y_reg <= velocity_y_next;
            
            // 使用本次计算出的新速度更新位置
            //x[k+1]=x[k]+u[k+1]
            position_x_reg <= position_x_reg + velocity_x_next;
            position_y_reg <= position_y_reg + velocity_y_next;
            
        end
    end

endmodule