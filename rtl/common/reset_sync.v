`timescale 1ns/1ps

// Nexys CPU_RESETN: async assertion, two-clock synchronous release.
// Artix-7 INIT keeps reset asserted at configuration before the first clocks.
module reset_sync (
    input wire clk,
    input wire rst_n,
    output wire rst
);
    (* ASYNC_REG = "TRUE" *) reg [1:0] reset_pipe = 2'b11;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            reset_pipe <= 2'b11;
        else
            reset_pipe <= {reset_pipe[0], 1'b0};
    end
    assign rst = reset_pipe[1];
endmodule
