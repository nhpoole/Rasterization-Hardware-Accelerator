/*
 * Performance monitor
 *
 * This module monitors the number of sample hits and the cycle counts
 *
 *
 *   Author: John Brunhaver, Ofer Shacham
 *   Created:          09/21/09
 *   Last Updated:     10/06/10
 *
 *   Copyright 2009 <jbrunhaver@gmail.com>  <shacham@stanford.edu>
 */

 /****************************************************************************
 * Change bar:
 * -----------
 * Date           Author    Description
 * Sep 22, 2012   jingpu    ported from John's original code to Genesis
 *
 * ***************************************************************************/

module perf_monitor
#(
    parameter SIGFIG = 24, // Bits in color and position.
    parameter RADIX = 10, // Fraction bits in color and position
    parameter VERTS = 3, // Maximum Vertices in triangle
    parameter AXIS = 3, // Number of axis foreach vertex 3 is (x,y,z).
    parameter COLORS = 3, // Number of color channels
    parameter SAMPLES = 2, // Number of samples to test at once
    parameter PIPE_DEPTH = 3 // Number of Pipe Stages in bbox module
)
(
    input logic signed   [SIGFIG-1:0]     tri_R10S[VERTS-1:0][AXIS-1:0],  // 4 Sets X,Y Fixed Point Values
    input logic unsigned [SIGFIG-1:0]     color_R10U[COLORS-1:0],          // 4 Sets X,Y Fixed Point Values
    input logic                           validSamp_R16H[SAMPLES-1:0],
    input logic signed   [SIGFIG-1:0]     sample_R16S[SAMPLES-1:0][1:0],

    input logic clk,                // Clock
    input logic rst,                // Reset

    input logic signed [SIGFIG-1:0]   hit_R18S[SAMPLES-1:0][AXIS-1:0],
    input logic signed [SIGFIG-1:0]   color_R18U[COLORS-1:0],
    input                             hit_valid_R18H[SAMPLES-1:0]
);

    //Pipe Signals for Later Evaluation
    logic signed   [SIGFIG-1:0]  tri_RnnS[VERTS-1:0][AXIS-1:0];    // 4 Sets X,Y Fixed Point Values
    logic signed   [SIGFIG-1:0]  tri_Rn1S[VERTS-1:0][AXIS-1:0];    // 4 Sets X,Y Fixed Point Values
    logic                        validSamp_RnnH[SAMPLES-1:0];
    //Pipe Signals for Later Evaluation

    dff3 #(
        .WIDTH          (SIGFIG     ),
        .ARRAY_SIZE1    (VERTS      ),
        .ARRAY_SIZE2    (AXIS       ),
        .PIPE_DEPTH     (PIPE_DEPTH ),
        .RETIME_STATUS  (0          )
    )
    d_01
    (
        .clk    (clk        ),
        .reset  (rst        ),
        .en     (1'b1       ),
        .in     (tri_R10S   ),
        .out    (tri_RnnS   )
    );

    dff3 #(
        .WIDTH          (SIGFIG         ),
        .ARRAY_SIZE1    (VERTS          ),
        .ARRAY_SIZE2    (AXIS           ),
        .PIPE_DEPTH     (PIPE_DEPTH-1   ),
        .RETIME_STATUS  (0              )
    )
    d_011
    (
        .clk    (clk        ),
        .reset  (rst        ),
        .en     (1'b1       ),
        .in     (tri_R10S   ),
        .out    (tri_Rn1S   )
    );

    /*dff #(
        .WIDTH          (1          ),
        .PIPE_DEPTH     (PIPE_DEPTH ),
        .RETIME_STATUS  (0          ) // No retime
    )*/
    dff2 #(
        .WIDTH          (1          ),
        .ARRAY_SIZE     (SAMPLES    ),
        .PIPE_DEPTH     (PIPE_DEPTH ),
        .RETIME_STATUS  (0          ) // No retime
    )
    d_04
    (
        .clk    (clk            ),
        .reset  (rst            ),
        .en     (1'b1           ),
        .in     (validSamp_R16H ),
        .out    (validSamp_RnnH )
    );

    int sample_count;
    int sample_hit_count;
    int triangle_count;
    int cycle_count;

    //Count the total Number of Valid Samples
    initial begin

        sample_count = 0;
        sample_hit_count = 0;
        triangle_count = 0;
        cycle_count = 0 ;

        @(negedge rst);
        @(posedge clk);
        @(posedge clk);
        @(posedge clk);

        while(1) begin
            @(posedge clk);
            for (integer i = 0; i < SAMPLES; i = i + 1) begin : monitor_loop
                sample_count = validSamp_RnnH[i] ? (sample_count + 1) : sample_count;

                sample_hit_count = ( validSamp_RnnH[i] && hit_valid_R18H[i] ) ?
                            ( sample_hit_count + 1 ) : sample_hit_count;

                triangle_count = ( tri_Rn1S != tri_RnnS ) ?
                            ( triangle_count + 1 ) : triangle_count;

                cycle_count++ ;

                if (sample_count % 100000 == 0) begin
                    $display("time=%10t \t%10d samples processed, %10d of them hit", $time, sample_count, sample_hit_count);
                end
            end
        end
    end
    //Count the total Number of Valid Samples

endmodule
