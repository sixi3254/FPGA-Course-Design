`timescale 1ns/1ps

// All outputs are one-cycle enables in the clk domain, never new clocks.
// CLK_FREQ must be a positive multiple of 100, >= 100. Default: 100 MHz.
module tick_gen #(
    parameter CLK_FREQ = 100_000_000
)(
    input wire clk,
    input wire rst,
    output reg pix_ce,
    output reg tick_100hz,
    output reg tick_20hz
);
    function integer count_width;
        input integer period;
        integer value;
        begin
            value = period - 1;
            count_width = 0;
            while (value > 0) begin
                count_width = count_width + 1;
                value = value >> 1;
            end
            if (count_width < 1) count_width = 1;
        end
    endfunction
    localparam DIV_100 = CLK_FREQ / 100;
    localparam DIV_20 = CLK_FREQ / 20;
    reg [1:0] pix_count;
    reg [count_width(DIV_100)-1:0] count_100;
    reg [count_width(DIV_20)-1:0] count_20;

    always @(posedge clk) begin
        if (rst) begin
            pix_count <= 2'd0;
            count_100 <= 0;
            count_20 <= 0;
            pix_ce <= 1'b0;
            tick_100hz <= 1'b0;
            tick_20hz <= 1'b0;
        end else begin
            pix_ce <= (pix_count == 2'd3);
            pix_count <= pix_count + 1'b1;
            tick_100hz <= (count_100 == DIV_100 - 1);
            if (count_100 == DIV_100 - 1) count_100 <= 0;
            else count_100 <= count_100 + 1'b1;
            tick_20hz <= (count_20 == DIV_20 - 1);
            if (count_20 == DIV_20 - 1) count_20 <= 0;
            else count_20 <= count_20 + 1'b1;
        end
    end
endmodule
