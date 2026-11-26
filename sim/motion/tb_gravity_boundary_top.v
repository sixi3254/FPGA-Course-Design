
`timescale 1ns/1ps

module tb_gravity_boundary_top;

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


    //==================================================
    // 2. 输出信号
    //==================================================

    wire signed [31:0] position_x;
    wire signed [31:0] position_y;

    wire signed [31:0] velocity_x;
    wire signed [31:0] velocity_y;

    wire correction_valid;

    wire hit_left;
    wire hit_right;
    wire hit_top;
    wire hit_bottom;


    //==================================================
    // 3. 实例化运动子系统
    //==================================================

    gravity_boundary_top uut(

        .clk(clk),
        .rst(rst),

        .angle_valid(angle_valid),

        .angle_x(angle_x),
        .angle_y(angle_y),

        .position_load(position_load),

        .init_x(init_x),
        .init_y(init_y),

        .position_x(position_x),
        .position_y(position_y),

        .velocity_x(velocity_x),
        .velocity_y(velocity_y),

        .correction_valid(correction_valid),

        .hit_left(hit_left),
        .hit_right(hit_right),
        .hit_top(hit_top),
        .hit_bottom(hit_bottom)

    );


    //==================================================
    // 4. 100MHz时钟
    //==================================================

    initial clk = 1'b0;

    always #5 clk = ~clk;


    //==================================================
    // 5. 调试任务
    //==================================================

    task debug_dump;

        begin

            $display("");
            $display("========== MOTION DEBUG ==========");

            // 第一层：gravity_motion内部寄存器
            $display("gravity.velocity_x_reg = %h",
                uut.u_gravity_motion.velocity_x_reg);

            $display("gravity.velocity_y_reg = %h",
                uut.u_gravity_motion.velocity_y_reg);

            // 第二层：gravity_motion输出
            $display("raw_position_x = %h", uut.raw_position_x);
            $display("raw_position_y = %h", uut.raw_position_y);

            $display("raw_velocity_x = %h", uut.raw_velocity_x);
            $display("raw_velocity_y = %h", uut.raw_velocity_y);

            // 第三层：boundary_detect输入
            $display("boundary.velocity_x = %h",
                uut.u_boundary_detect.velocity_x);

            $display("boundary.velocity_y = %h",
                uut.u_boundary_detect.velocity_y);

            // 第四层：boundary_detect输出
            $display("corrected_position_x = %h",
                uut.corrected_position_x);

            $display("corrected_position_y = %h",
                uut.corrected_position_y);

            $display("corrected_velocity_x = %h",
                uut.corrected_velocity_x);

            $display("corrected_velocity_y = %h",
                uut.corrected_velocity_y);

            // 第五层：最终输出
            $display("final.position_x = %h", position_x);
            $display("final.position_y = %h", position_y);

            $display("final.velocity_x = %h", velocity_x);
            $display("final.velocity_y = %h", velocity_y);

            $display("correction_valid = %b", correction_valid);

            $display("hit_left   = %b", hit_left);
            $display("hit_right  = %b", hit_right);
            $display("hit_top    = %b", hit_top);
            $display("hit_bottom = %b", hit_bottom);

            $display("==================================");
            $display("");

        end

    endtask


    //==================================================
    // 6. 复位任务
    //==================================================

    task apply_reset;

        begin

            @(negedge clk);

            rst = 1'b1;

            angle_valid = 1'b0;
            position_load = 1'b0;

            angle_x = 32'sd0;
            angle_y = 32'sd0;

            repeat(2)
                @(negedge clk);

            rst = 1'b0;

            #1;

        end

    endtask


    //==================================================
    // 7. 装载初始位置
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
    // 8. 输入一次姿态数据
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
    // 9. 主测试程序
    //==================================================

    initial begin

        rst = 1'b0;

        angle_valid = 1'b0;

        angle_x = 32'sd0;
        angle_y = 32'sd0;

        position_load = 1'b0;

        init_x = 32'sd0;
        init_y = 32'sd0;


        $display("");
        $display("====================================");
        $display("GRAVITY + BOUNDARY INTEGRATION TEST");
        $display("====================================");


        //==============================================
        // TEST 1：正常运动第一次更新
        //==============================================

        apply_reset();

        send_angle(32'sd0, 32'sd1048576);

        $display("TEST 1: First normal update");

        debug_dump();

        if (uut.raw_velocity_x !== 32'sd1024 ||
            position_x !== 32'sd20972544) begin

            $display("ERROR: Normal first update failed");

            $fatal(1, "TEST 1 FAILED");

        end

        $display("PASS: Normal first update");


        //==============================================
        // TEST 2：正常运动第二次更新
        //==============================================

        send_angle(32'sd0, 32'sd1048576);

        $display("TEST 2: Second normal update");

        debug_dump();

        if (uut.raw_velocity_x !== 32'sd2032 ||
            position_x !== 32'sd20974576) begin

            $display("ERROR: Normal second update failed");

            $fatal(1, "TEST 2 FAILED");

        end

        $display("PASS: Normal second update");


        //==============================================
        // TEST 3：右边界碰撞
        //==============================================

        apply_reset();

        // 初始位置约为623.988
        load_position(
            32'sd40893700,
            32'sd15728640
        );

        send_angle(
            32'sd0,
            32'sd1048576
        );

        $display("TEST 3: Right boundary collision");

        debug_dump();

        if (position_x !== 32'sd40894464 ||
            velocity_x !== -32'sd512 ||
            correction_valid !== 1'b1 ||
            hit_right !== 1'b1) begin

            $display("ERROR: Right collision failed");

            $fatal(1, "TEST 3 FAILED");

        end

        $display("PASS: Right boundary collision");


        //==============================================
        // TEST 4：状态反馈
        //==============================================

        @(posedge clk);

        #1;

        $display("TEST 4: Collision state feedback");

        debug_dump();

        if (uut.raw_position_x !== 32'sd40894464 ||
            uut.raw_velocity_x !== -32'sd512 ||
            correction_valid !== 1'b0 ||
            position_x !== 32'sd40894464 ||
            velocity_x !== -32'sd512) begin

            $display("ERROR: State feedback failed");

            $fatal(1, "TEST 4 FAILED");

        end

        $display("PASS: Collision state feedback");


        //==============================================
        // TEST 5：恢复水平后向内运动
        //==============================================

        send_angle(
            32'sd0,
            32'sd0
        );

        $display("TEST 5: Inward movement after collision");

        debug_dump();

        if (position_x !== 32'sd40893960 ||
            velocity_x !== -32'sd504 ||
            correction_valid !== 1'b0 ||
            hit_right !== 1'b0) begin

            $display("ERROR: Inward movement failed");

            $fatal(1, "TEST 5 FAILED");

        end

        $display("PASS: Inward movement after collision");


        //==============================================
        // 测试全部结束
        //==============================================

        $display("");
        $display("====================================");
        $display("ALL INTEGRATION TESTS PASSED!");
        $display("====================================");

        $finish;

    end

endmodule
