// Simulation module for generating a clock
// by Ofer Shacham shacham@stanford.edu

/* ***************************************************************************
 * Change bar:
 * -----------
 * Date           Author    Description
 * Sep 22, 2012   jingpu    ported from Ofer's original code to Genesis
 *
 * ***************************************************************************/

module clocker
#(
    parameter PERIOD = 1000 // Period of the generated clock signal
)
(
    output logic clk
);

    localparam HALF_PERIOD1 = PERIOD / 2;
    localparam HALF_PERIOD2 = PERIOD - HALF_PERIOD1;

    initial begin
        while(1) begin
            #HALF_PERIOD1 clk = 1'b0;
            #HALF_PERIOD2 clk = 1'b1;
        end
    end

endmodule // clocker
