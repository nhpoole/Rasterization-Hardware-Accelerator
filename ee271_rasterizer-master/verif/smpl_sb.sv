/*
 * sampl_sb monitor
 *
 *   Sample Test Function Score Board
 *
 *   This module calls a DPI function
 *   to see if the sample test is correct.
 *
 *   Output error to file and stdout
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

import "DPI" pure function int check_sample_test(
    int   v0_x,      //triangle
    int   v0_y,      //triangle
    int   v1_x,      //triangle
    int   v1_y,      //triangle
    int   v2_x,      //triangle
    int   v2_y,      //triangle
    int   s_x,       //SAMPLE 
    int   s_y,       //SAMPLE
    int   hit        //HIT
);

module smpl_sb
#(
    parameter SIGFIG = 24, // Bits in color and position.
    parameter RADIX = 10, // Fraction bits in color and position
    parameter VERTS = 3, // Maximum Vertices in triangle
    parameter AXIS = 3, // Number of axis foreach vertex 3 is (x,y,z).
    parameter COLORS = 3, // Number of color channels
    parameter PIPE_DEPTH = 3, // Number of Pipe Stages in bbox module
    parameter SAMPLES = 2,  // Number of samples to test at once.
    parameter FILENAME = "sb_log/smpl_sb.log" // Log file name
)
(
    input logic signed   [SIGFIG-1:0]   tri_R16S[VERTS-1:0][AXIS-1:0],  // 4 Sets X,Y Fixed Point Values
    input logic unsigned [SIGFIG-1:0]   color_R16U[COLORS-1:0],          // 4 Sets X,Y Fixed Point Values
    input logic                         validSamp_R16H[SAMPLES-1:0],
    input logic signed   [SIGFIG-1:0]   sample_R16S[SAMPLES-1:0][1:0],

    input logic                         clk,                // Clock
    input logic                         rst,                // Reset

    input logic signed [SIGFIG-1:0]     hit_R18S[SAMPLES-1:0][AXIS-1:0],
    input logic signed [SIGFIG-1:0]     color_R18U[COLORS-1:0],
    input                               hit_valid_R18H[SAMPLES-1:0]
);

    //Pipe Signals for Later Evaluation
    logic signed   [SIGFIG-1:0] tri_RnnS[VERTS-1:0][AXIS-1:0];    // 4 Sets X,Y Fixed Point Values
    logic unsigned [SIGFIG-1:0] color_RnnU[COLORS-1:0];
    logic                       validSamp_RnnH[SAMPLES-1:0];
    logic signed   [SIGFIG-1:0] sample_RnnS[SAMPLES-1:0][1:0];             //
    //Pipe Signals for Later Evaluation

    //Helper Signals
    int one;
    int file;

    assign one = 1 ;
    //Helper Signals

    initial begin
        file = $fopen(FILENAME,"w");
    end

    //Check if Sample in triangle test is correct
    always @(posedge clk) begin
        #100;
        for (integer i = 0; i < SAMPLES; i = i + 1) begin : sample_loop
            if(validSamp_RnnH[i]
                &&
                one !=  check_sample_test( int'(tri_RnnS[0][0]), //triangle
                        int'(tri_RnnS[0][1]), //triangle
                        int'(tri_RnnS[1][0]), //triangle
                        int'(tri_RnnS[1][1]), //triangle
                        int'(tri_RnnS[2][0]), //triangle
                        int'(tri_RnnS[2][1]), //triangle
                        int'(sample_RnnS[i][0]) , //SAMPLE
                        int'(sample_RnnS[i][1]) , //SAMPLE
                        int'(hit_valid_R18H[i])   //IS HIT
                        )) begin

                $fwrite( file , "@%0t: Sample Test ERROR!!!!\n\t\t" , $time );
                $fwrite( file , "uP.v_0.x: %f\t" , (1.0 * tri_RnnS[0][0]) / (1 << RADIX));
                $fwrite( file , "uP.v_0.y: %f\t" , (1.0 * tri_RnnS[0][1]) / (1 << RADIX));
                $fwrite( file , "uP.v_1.x: %f\t" , (1.0 * tri_RnnS[1][0]) / (1 << RADIX));
                $fwrite( file , "uP.v_1.y: %f\t" , (1.0 * tri_RnnS[1][1]) / (1 << RADIX));

                $fwrite( file , "\n\t\t" );
                $fwrite( file , "uP.v_2.x: %f\t" , (1.0 * tri_RnnS[2][0]) / (1 << RADIX));
                $fwrite( file , "uP.v_2.y: %f\t" , (1.0 * tri_RnnS[2][1]) / (1 << RADIX));

                $fwrite( file , "\n\t\t" );

                $fwrite( file , "sample.x:%f\t",  (1.0 * sample_RnnS[i][0]) / (1 << RADIX));
                $fwrite( file , "sample.y:%f\t",  (1.0 * sample_RnnS[i][1]) / (1 << RADIX));
                $fwrite( file , "hit:%b\n" , hit_valid_R18H[i] );

                assert( 0 ) else $error( "time=%10t ERROR: Sample Test Check Failed", $time );
            end
        end
    end

/* Pipe Required Signals */
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
        .in     (tri_R16S  ),
        .out    (tri_RnnS  )
    );

    dff2 #(
        .WIDTH          (SIGFIG     ),
        .ARRAY_SIZE     (COLORS     ),
        .PIPE_DEPTH     (PIPE_DEPTH ),
        .RETIME_STATUS  (0          )
    )
    d_02
    (
        .clk    (clk        ),
        .reset  (rst        ),
        .en     (1'b1       ),
        .in     (color_R16U ),
        .out    (color_RnnU )
    );

    /*dff2 #(
        .WIDTH          (SIGFIG     ),
        .ARRAY_SIZE     (2          ),
        .PIPE_DEPTH     (PIPE_DEPTH ),
        .RETIME_STATUS  (0          )
    )*/
    dff3 #(
        .WIDTH          (SIGFIG     ),
        .ARRAY_SIZE1    (SAMPLES    ),
        .ARRAY_SIZE2    (2          ),
        .PIPE_DEPTH     (PIPE_DEPTH ),
        .RETIME_STATUS  (0          )
    )
    d_03
    (
        .clk    (clk        ),
        .reset  (rst        ),
        .en     (1'b1       ),
        .in     (sample_R16S),
        .out    (sample_RnnS)
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

/* Pipe Required Signals */

endmodule
