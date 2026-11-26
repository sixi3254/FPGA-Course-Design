`timescale 1ns/1ps

module boundary_detect (
    
    //当前候选位置
    input wire signed [31:0] position_x,
    input wire signed [31:0] position_y,

    //当前候选速度
    input wire signed [31:0] velocity_x,
    input wire signed [31:0] velocity_y,

    //修正后的位置
    output reg signed [31:0] corrected_position_x,
    output reg signed [31:0] corrected_position_y,

    //修正后速度
    output reg signed [31:0] corrected_velocity_x,
    output reg signed [31:0] corrected_velocity_y,

    //状态修正标志
    output reg correction_valid,

    //边界反弹标志
    output reg hit_left,
    output reg hit_right,
    output reg hit_top,
    output reg hit_bottom
);


    //边界参数
    localparam signed [31:0] X_MIN = 32'sd983040;
    localparam signed [31:0] X_MAX = 32'sd40894464;
    localparam signed [31:0] Y_MIN = 32'sd983040;
    localparam signed [31:0] Y_MAX = 32'sd30408704;

    //组合逻辑：边界判断和速度反弹
    always @(*) begin

        //默认保存原始状态
        //未碰撞
        corrected_position_x = position_x;
        corrected_position_y = position_y;
        corrected_velocity_x = velocity_x;
        corrected_velocity_y = velocity_y;
        //设置标志位
        correction_valid = 1'b0;

        hit_left = 1'b0;
        hit_right = 1'b0;
        hit_top = 1'b0;
        hit_bottom = 1'b0;


        //右边界碰撞
        if(position_x > X_MAX)begin
            corrected_position_x = X_MAX;
            correction_valid = 1'b1;

            //只有向外运行才反弹
            if(velocity_x > 0)begin
                //恢复系数e=0.5，衰减为原来一半
                corrected_velocity_x = -(velocity_x / 32'sd2);
                hit_right = 1'b1;
            end
        end
        //左边界碰撞
        if (position_x < X_MIN) begin

            corrected_position_x = X_MIN;
            correction_valid = 1'b1;

            if (velocity_x < 0) begin

                corrected_velocity_x =
                    -(velocity_x / 32'sd2);

                hit_left = 1'b1;

            end

        end
        //下边界碰撞
        if (position_y > Y_MAX) begin

            corrected_position_y = Y_MAX;
            correction_valid = 1'b1;

            if (velocity_y > 0) begin

                corrected_velocity_y =
                    -(velocity_y / 32'sd2);

                hit_bottom = 1'b1;

            end

        end
        //上边界碰撞
        if (position_y < Y_MIN) begin

            corrected_position_y = Y_MIN;
            correction_valid = 1'b1;

            if (velocity_y < 0) begin

                corrected_velocity_y =
                    -(velocity_y / 32'sd2);

                hit_top = 1'b1;

            end
        end
    end
    
endmodule