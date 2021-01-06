/*
 * smpl_cnt_sb
 *
 *  This is a sample count scoreboard.  It checks
 *  to make sure that each triangle generates
 *  the correct number of fragments.
 *
 *  Combined with the correct sample test scoreboard
 *  both scoreboards should detect if a triangle
 *  generates any incorrect fragments
 *
 *
 */

  /****************************************************************************
 * Change bar:
 * -----------
 * Date           Author    Description
 * Sep 22, 2012   jingpu    ported from John's original code to Genesis
 *
 * ***************************************************************************/

import "DPI" pure function int check_hit_count(
    int   v0_x,         //triangle
    int   v0_y,         //triangle
    int   v1_x,         //triangle
    int   v1_y,         //triangle
    int   v2_x,         //triangle
    int   v2_y,         //triangle
    int   hits,         //Number of Samples in triangle
    int   ss_w_lg2,     //Subsample
    int   screen_w,     //Screen
    int   screen_h,     //Screen
    int   r_shift,      //Config
    int   r_val         //Config
);

// Import the DPI function for checking the hash module.
import "DPI" pure function int check_hash(
    int s_x,
    int s_y,
    int ss_w_lg2,
    int jitter_x,
    int jitter_y,
    int s_j_x,
    int s_j_y
);

module smpl_cnt_sb
#(
    parameter SIGFIG = 24,                          // Bits in color and position.
    parameter RADIX = 10,                           // Fraction bits in color and position
    parameter VERTS = 3,                            // Maximum Vertices in triangle
    parameter AXIS = 3,                             // Number of axis foreach vertex 3 is (x,y,z).
    parameter COLORS = 3,                           // Number of color channels
    parameter PIPE_DEPTH = 3,                       // Number of Pipe Stages in bbox module
    parameter SAMPLES = 2,                          // Number of samples to test at once
    parameter FILENAME = "sb_log/smpl_cnt_sb.log"   // Log file name
)
(
    input logic signed [SIGFIG-1:0] tri_R16S[VERTS-1:0][AXIS-1:0],  // 4 Sets X,Y Fixed Point Values
    input logic unsigned [SIGFIG-1:0] color_R16U[COLORS-1:0],       // 4 Sets X,Y Fixed Point Values
    input logic validSamp_R16H[SAMPLES-1:0],
    input logic signed [SIGFIG-1:0] sample_R16S[SAMPLES-1:0][1:0],

    input logic clk,                                // Clock
    input logic rst,                                // Reset

    input logic signed [SIGFIG-1:0] hit_R18S[SAMPLES-1:0][AXIS-1:0],
    input logic signed [SIGFIG-1:0] color_R18U[COLORS-1:0],
    input logic hit_valid_R18H[SAMPLES-1:0],

    input logic [SIGFIG-1:0] screen_RnnnnS[1:0],    // Screen Size
    input logic [3:0] subSample_RnnnnU,             // Flag for subsample

    input logic signed [SIGFIG-1:0] s_x_RnnS[SAMPLES-1:0],
    input logic signed [SIGFIG-1:0] s_y_RnnS[SAMPLES-1:0],
    input logic signed [7:0] jitter_x_RnnS[SAMPLES-1:0],
    input logic signed [7:0] jitter_y_RnnS[SAMPLES-1:0],
    input logic signed [SIGFIG-1:0] s_j_x_RnnS[SAMPLES-1:0],
    input logic signed [SIGFIG-1:0] s_j_y_RnnS[SAMPLES-1:0]
 );


    //Pipe Signals for Later Evaluation
    logic signed [SIGFIG-1:0] tri_RnnS[VERTS-1:0][AXIS-1:0];    // 4 Sets X,Y Fixed Point Values
    logic signed [SIGFIG-1:0] tri_Rn1S[VERTS-1:0][AXIS-1:0];    // 4 Sets X,Y Fixed Point Values
    logic unsigned [SIGFIG-1:0] color_RnnU[COLORS-1:0];
    logic validSamp_RnnH[SAMPLES-1:0];
    logic signed [SIGFIG-1:0] sample_RnnS[SAMPLES-1:0][1:0];
    //Pipe Signals for Later Evaluation

    //Helper Signals
    int file;
    int one;
    int ss_w_lg2;
    assign one = 1 ;
    //Helper Signals

    //Bench Logic
    int hit_count;
    int hit_count_next;
    logic incr;
    logic incr2;
    logic incr3;
    logic incr4;
    logic keep;
    logic reset_to_zero;
    logic reset_to_one;
    logic reset_to_two;
    logic reset_to_three;
    logic reset_to_four;
    //Bench Logic

    initial begin
        file = $fopen(FILENAME,"w");
    end

    always_comb begin
        unique case( 1'b1 )
            ( subSample_RnnnnU[0] ): ss_w_lg2 = 3;
            ( subSample_RnnnnU[1] ): ss_w_lg2 = 2;
            ( subSample_RnnnnU[2] ): ss_w_lg2 = 1;
            ( subSample_RnnnnU[3] ): ss_w_lg2 = 0;
        endcase
    end

    // Call the DPI function that checks that the hash produces the correct jittered samples
    // Should only be called if reset is not asserted
    always @(posedge clk) begin
        #10;
        if (~rst) begin
            for (integer i = 0; i < SAMPLES; i = i + 1) begin : hash_loop
                if (one != check_hash(
                                s_x_RnnS[i],
                                s_y_RnnS[i],
                                ss_w_lg2,
                                int'({ 24'h000000, jitter_x_RnnS[i]}),
                                int'({ 24'h000000, jitter_y_RnnS[i]}),
                                s_j_x_RnnS[i],
                                s_j_y_RnnS[i])) begin
                    $finish();
                end
            end
        end
    end

    //Check that the Number of Hits is Correct
    always @( posedge clk ) begin
        #10;
        if( reset_to_zero && (validSamp_RnnH[0] | validSamp_RnnH[1]) ) begin
            if(one != check_hit_count(
                    int'(tri_RnnS[0][0]),       //triangle
                    int'(tri_RnnS[0][1]),       //triangle
                    int'(tri_RnnS[1][0]),       //triangle
                    int'(tri_RnnS[1][1]),       //triangle
                    int'(tri_RnnS[2][0]),       //triangle
                    int'(tri_RnnS[2][1]),       //triangle
                    hit_count,                  //Number of Samples in triangle
                    ss_w_lg2,                   //Subsample
                    int'(screen_RnnnnS[0] ),    //Screen
                    int'(screen_RnnnnS[1] ),    //Screen
                    RADIX,                      //Config
                    int'( 128'd1 << RADIX )     //Config
                    )) begin

                $finish();
            end
        end
    end

    //Sample hit Counter for

    //hit_count_next holds the number of hits in triangle 106 so far
    dff #(
        .WIDTH          (32 ),
        .PIPE_DEPTH     (1  ),
        .RETIME_STATUS  (0  ) // No retime
    )
    dc
    (
        .clk    (clk            ),
        .reset  (rst            ),
        .en     (1'b1           ),
        .in     (hit_count_next ),
        .out    (hit_count      )
    );

    always_comb begin

        reset_to_zero = (tri_Rn1S != tri_RnnS) ; //New triangle

        /*reset_to_one = reset_to_zero && (hit_valid_R18H[0] ^ hit_valid_R18H[1]); //New triangle with hit
        reset_to_two = reset_to_zero && (hit_valid_R18H[0] & hit_valid_R18H[1]); //New triangle with hit
        incr = (hit_valid_R18H[0] ^ hit_valid_R18H[1]);
        incr2 = (hit_valid_R18H[0] & hit_valid_R18H[1]);
        keep = ~(hit_valid_R18H[0] | hit_valid_R18H[1]);*/

        keep = ~(hit_valid_R18H[0] | hit_valid_R18H[1] | hit_valid_R18H[2]);
        incr2 = ~keep & ~(hit_valid_R18H[0] ^ hit_valid_R18H[1] ^ hit_valid_R18H[2]);
        incr = (hit_valid_R18H[0] & ~hit_valid_R18H[1] & ~hit_valid_R18H[2]) |
               (~hit_valid_R18H[0] & hit_valid_R18H[1] & ~hit_valid_R18H[2]) |
               (~hit_valid_R18H[0] & ~hit_valid_R18H[1] & hit_valid_R18H[2]);
        incr3 = hit_valid_R18H[0] & hit_valid_R18H[1] & hit_valid_R18H[2];

        reset_to_one = reset_to_zero && incr; //New triangle with hit
        reset_to_two = reset_to_zero && incr2; //New triangle with 2 hits
        reset_to_three = reset_to_zero && incr3; //New triangle with 3 hits

        /*keep = ~(hit_valid_R18H[0] | hit_valid_R18H[1] | hit_valid_R18H[2] | hit_valid_R18H[3]);
        incr4 = hit_valid_R18H[0] & hit_valid_R18H[1] & hit_valid_R18H[2] & hit_valid_R18H[3];
        incr2 = ~keep & ~(hit_valid_R18H[0] ^ hit_valid_R18H[1] ^ hit_valid_R18H[2] ^ hit_valid_R18H[3]) &
                ~incr4;
        incr = (hit_valid_R18H[0] & ~hit_valid_R18H[1] & ~hit_valid_R18H[2] & ~hit_valid_R18H[3]) |
               (~hit_valid_R18H[0] & hit_valid_R18H[1] & ~hit_valid_R18H[2] & ~hit_valid_R18H[3]) |
               (~hit_valid_R18H[0] & ~hit_valid_R18H[1] & hit_valid_R18H[2] & ~hit_valid_R18H[3]) |
               (~hit_valid_R18H[0] & ~hit_valid_R18H[1] & ~hit_valid_R18H[2] & hit_valid_R18H[3]);
        incr3 = (hit_valid_R18H[0] ^ hit_valid_R18H[1] ^ hit_valid_R18H[2] ^ hit_valid_R18H[3]) & ~incr;

        reset_to_one = reset_to_zero && incr; //New triangle with hit
        reset_to_two = reset_to_zero && incr2; //New triangle with 2 hits
        reset_to_three = reset_to_zero && incr3; //New triangle with 3 hits
        reset_to_four = reset_to_zero && incr4; //New triangle with 4 hits*/

        priority case( 1'b1 )
            //(reset_to_four) : hit_count_next = 4;
            (reset_to_three) : hit_count_next = 3;
            (reset_to_two): hit_count_next = 2;
            (reset_to_one): hit_count_next = 1;
            (reset_to_zero): hit_count_next = 0;
            (incr): hit_count_next = hit_count + 1;
            (incr2): hit_count_next = hit_count + 2;
            (incr3): hit_count_next = hit_count + 3;
            //(incr4): hit_count_next = hit_count + 4;
            (keep): hit_count_next = hit_count;
            default: hit_count_next = 0;
        endcase // case ( 1'b1 )
    end
    //Sample Hit Counter

    //Pipe triangle Along
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
        .in     (tri_R16S   ),
        .out    (tri_RnnS   )
    );

    dff3 #(
        .WIDTH          (SIGFIG         ),
        .ARRAY_SIZE1    (VERTS          ),
        .ARRAY_SIZE2    (AXIS           ),
        .PIPE_DEPTH     (PIPE_DEPTH - 1 ),
        .RETIME_STATUS  (0              )
    )
    d_011
    (
        .clk    (clk        ),
        .reset  (rst        ),
        .en     (1'b1       ),
        .in     (tri_R16S   ),
        .out    (tri_Rn1S   )
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

endmodule
