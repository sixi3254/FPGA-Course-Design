`timescale 1ns/1ps

// Two-stage input synchronizer and whole-vector stability filter.
// After STABLE_CYCLES identical synchronized samples, publish all bits together.
// Rising changes produce one-cycle key_tick; falling changes only update level.
module key_debounce #(
    parameter WIDTH = 1,
    parameter STABLE_CYCLES = 1_000_000
)(
    input wire clk,
    input wire rst,
    input wire [WIDTH-1:0] key_in,
    output reg [WIDTH-1:0] key_level,
    output reg [WIDTH-1:0] key_tick
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
    (* ASYNC_REG = "TRUE" *) reg [WIDTH-1:0] input_meta, input_sync;
    reg [WIDTH-1:0] candidate;
    reg [count_width(STABLE_CYCLES)-1:0] stable_count;

    always @(posedge clk) begin
        if (rst) begin
            input_meta <= 0;
            input_sync <= 0;
        end else begin
            input_meta <= key_in;
            input_sync <= input_meta;
        end
    end
    always @(posedge clk) begin
        if (rst) begin
            candidate <= 0;
            stable_count <= 0;
            key_level <= 0;
            key_tick <= 0;
        end else begin
            key_tick <= 0;
            if (STABLE_CYCLES <= 1) begin
                key_level <= input_sync;
                key_tick <= input_sync & ~key_level;
            end else if (input_sync != candidate) begin
                candidate <= input_sync;
                stable_count <= 1;
            end else if (candidate != key_level) begin
                if (stable_count == STABLE_CYCLES - 1) begin
                    key_level <= candidate;
                    key_tick <= candidate & ~key_level;
                    stable_count <= 0;
                end else begin
                    stable_count <= stable_count + 1'b1;
                end
            end else begin
                stable_count <= 0;
            end
        end
    end
endmodule
