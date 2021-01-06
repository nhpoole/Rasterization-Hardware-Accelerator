/*
 *  Hashing Function
 *
 *  Inputs:
 *    triangle and Sample Information
 *
 *  Outputs:
 *    Jittered Sample Position and Buffered triangle
 *
 *  Function:
 *    Calc on offset for the sample.  This is used for
 *    stochastic sampling reasons.  Note that this is
 *    a simplified hashing mechanism.  An in depth
 *    discussion of stochastic sampling in rendering
 *    can be found here:
 *    http://doi.acm.org/10.1145/7529.8927
 *
 *
 * Long Description:
 *    The basic idea is to use a tree of xor
 *    functions to generate a displacement
 *    from the sample center.
 *
 *
 *   Author: John Brunhaver
 *   Created:      Thu 10/01/10
 *   Last Updated: Tue 10/15/10
 *
 *   Copyright 2009 <jbrunhaver@gmail.com>
 *
 */

/* ***************************************************************************
 * Change bar:
 * -----------
 * Date           Author    Description
 * Sep 19, 2012   jingpu    ported from John's original code to Genesis
 *
 * ***************************************************************************/


/* A Note on Signal Names:
 *
 * Most signals have a suffix of the form _RxxN
 * where R indicates that it is a Raster Block signal
 * xx indicates the clock slice that it belongs to
 * and N indicates the type of signal that it is.
 * H indicates logic high, L indicates logic low,
 * U indicates unsigned fixed point, and S indicates
 * signed fixed point.
 *
 */

module hash_jtree
#(
    parameter SIGFIG = 24,
    parameter RADIX = 10,
    parameter VERTS = 3,
    parameter AXIS = 3,
    parameter COLORS = 3,
    parameter SAMPLES = 2,
    parameter PIPE_DEPTH = 3
)
(
    //Input Signals
    input logic signed    [SIGFIG-1:0]  tri_R14S[VERTS-1:0][AXIS-1:0],  //triangle to Sample Test
    input logic unsigned  [SIGFIG-1:0]  color_R14U[COLORS-1:0],         //Color of Tri
    /*input logic signed    [SIGFIG-1:0]  sample_R14S[1:0],                //Sample Location to Be Tested
    input logic                         validSamp_R14H,                 //Sample and triangle are Valid*/
    input logic signed [SIGFIG-1:0] sample_R14S[SAMPLES-1:0][1:0],      //Sample Location to Be Tested
    input logic validSamp_R14H[SAMPLES-1:0],                            //Sample and triangle are Valid

    //Global Signals
    input logic clk, // Clock
    input logic rst, // Reset

    //Control Signals
    input logic [3:0] subSample_RnnnnU ,   //Subsample width

    //Outputs
    output logic signed   [SIGFIG-1:0]  tri_R16S[VERTS-1:0][AXIS-1:0], // triangle to Iterate Over
    output logic unsigned [SIGFIG-1:0]  color_R16U[COLORS-1:0],        // Color of Tri
    /*output logic signed   [SIGFIG-1:0]  sample_R16S[1:0],              // Sample Location
    output logic                        validSamp_R16H                  // A valid sample location*/
    output logic signed [SIGFIG-1:0] sample_R16S[SAMPLES-1:0][1:0],     // Sample Location
    output logic validSamp_R16H[SAMPLES-1:0]                            // A valid sample location
);

    localparam HASH_IN_WIDTH = (SIGFIG - 4) * 2;
    localparam HASH_OUT_WIDTH = RADIX - 2;

    // output for retiming registers
    logic signed [SIGFIG-1:0]   tri_R16S_retime[VERTS-1:0][AXIS-1:0]; // triangle to Iterate Over
    logic unsigned [SIGFIG-1:0] color_R16U_retime[COLORS-1:0];      // Color of Tri
    /*logic signed [SIGFIG-1:0]   sample_R16S_retime[1:0];    // Sample Location
    logic                       validSamp_R16H_retime;              // A valid sample location*/
    logic signed [SIGFIG-1:0] sample_R16S_retime[SAMPLES-1:0][1:0]; // Sample Location
    logic validSamp_R16H_retime[SAMPLES-1:0];                       // A valid sample location
    // output for retiming registers

    logic [HASH_OUT_WIDTH-1:0]  hash_mask_R14H ;
    /*logic [HASH_OUT_WIDTH-1:0]  jitt_val_R14H[1:0] ;
    logic [SIGFIG-1:0]          sample_jitted_R14S[1:0] ;*/
    logic [HASH_OUT_WIDTH-1:0]  jitt_val_R14H[SAMPLES-1:0][1:0] ;
    logic [SIGFIG-1:0]          sample_jitted_R14S[SAMPLES-1:0][1:0] ;

    always_comb begin
        assert( $onehot(subSample_RnnnnU) ) ;
        unique case ( 1'b1 )
            (subSample_RnnnnU[3]): hash_mask_R14H = 8'b11111111 ; //MSAA = 1
            (subSample_RnnnnU[2]): hash_mask_R14H = 8'b01111111 ; //MSAA = 4
            (subSample_RnnnnU[1]): hash_mask_R14H = 8'b00111111 ; //MSAA = 16
            (subSample_RnnnnU[0]): hash_mask_R14H = 8'b00011111 ; //MSAA = 64
        endcase // case ( 1'b1 )
    end

    generate
        for (genvar i = 0; i < SAMPLES; i = i + 1) begin : hash_gen
            tree_hash #(
                .IN_WIDTH(HASH_IN_WIDTH),
                .OUT_WIDTH(HASH_OUT_WIDTH)
            )
            xjit_hash
            (
                .in_RnnH    ({sample_R14S[i][1][SIGFIG-1:4],
                            sample_R14S[i][0][SIGFIG-1:4]}   ),
                .clk(clk),
                .rst(rst),
                .mask_RnnH  (hash_mask_R14H                 ),
                .out_RnnH   (jitt_val_R14H[i][0]               )
            );

            tree_hash #(
                .IN_WIDTH(HASH_IN_WIDTH),
                .OUT_WIDTH(HASH_OUT_WIDTH)
            )
            yjit_hash
            (
                .in_RnnH    ({sample_R14S[i][0][SIGFIG-1:4],
                            sample_R14S[i][1][SIGFIG-1:4]}   ),
                .clk(clk),
                .rst(rst),
                .mask_RnnH  (hash_mask_R14H                     ),
                .out_RnnH   (jitt_val_R14H[i][1]                   )
            );

            //Jitter the sample coordinates
            assign sample_jitted_R14S[i][0] =   { sample_R14S[i][0][SIGFIG-1:0] }
                                            | { {(SIGFIG - RADIX){1'b0}},                 //23:10 = 14 bits
                                                jitt_val_R14H[i][0][HASH_OUT_WIDTH-1:0], //7:0 = 8 bits
                                                {(RADIX - HASH_OUT_WIDTH){1'b0}} };     //1:0 = 2 bits  ==> 24 bits total

            //Jitter the sample coordinates
            assign sample_jitted_R14S[i][1] =   { sample_R14S[i][1][SIGFIG-1:0] }
                                            | { {(SIGFIG - RADIX){1'b0}},                 //23:10 = 14 bits
                                                jitt_val_R14H[i][1][HASH_OUT_WIDTH-1:0], //7:0 = 8 bits
                                                {(RADIX - HASH_OUT_WIDTH){1'b0}} };     //1:0 = 2 bits  ==> 24 bits total
        end
    endgenerate


    /*tree_hash #(
        .IN_WIDTH(HASH_IN_WIDTH),
        .OUT_WIDTH(HASH_OUT_WIDTH)
    )
    xjit_hash
    (
        .in_RnnH    ({sample_R14S[1][SIGFIG-1:4],
                      sample_R14S[0][SIGFIG-1:4]}   ),
        .clk(clk),
        .rst(rst),
         .mask_RnnH  (hash_mask_R14H                 ),
        .out_RnnH   (jitt_val_R14H[0]               )
    );

    tree_hash #(
        .IN_WIDTH(HASH_IN_WIDTH),
        .OUT_WIDTH(HASH_OUT_WIDTH)
    )
    yjit_hash
    (
        .in_RnnH    ({sample_R14S[0][SIGFIG-1:4],
                      sample_R14S[1][SIGFIG-1:4]}   ),
        .clk(clk),
        .rst(rst),
         .mask_RnnH  (hash_mask_R14H                     ),
        .out_RnnH   (jitt_val_R14H[1]                   )
    );

    //Jitter the sample coordinates
    assign sample_jitted_R14S[0] =   { sample_R14S[0][SIGFIG-1:0] }
                                    | { {(SIGFIG - RADIX){1'b0}},                 //23:10 = 14 bits
                                        jitt_val_R14H[0][HASH_OUT_WIDTH-1:0], //7:0 = 8 bits
                                        {(RADIX - HASH_OUT_WIDTH){1'b0}} };     //1:0 = 2 bits  ==> 24 bits total

    //Jitter the sample coordinates
    assign sample_jitted_R14S[1] =   { sample_R14S[1][SIGFIG-1:0] }
                                    | { {(SIGFIG - RADIX){1'b0}},                 //23:10 = 14 bits
                                        jitt_val_R14H[1][HASH_OUT_WIDTH-1:0], //7:0 = 8 bits
                                        {(RADIX - HASH_OUT_WIDTH){1'b0}} };     //1:0 = 2 bits  ==> 24 bits total
    */

    dff3 #(
        .WIDTH(SIGFIG),
        .ARRAY_SIZE1(VERTS),
        .ARRAY_SIZE2(AXIS),
        .PIPE_DEPTH(PIPE_DEPTH - 1),
        .RETIME_STATUS(1)
    )
    d_hash_r1
    (
        .clk    (clk                ),
        .reset  (rst                ),
        .en     (1'b1               ),
        .in     (tri_R14S           ),
        .out    (tri_R16S_retime    )
    );

    dff2 #(
        .WIDTH(SIGFIG),
        .ARRAY_SIZE(COLORS),
        .PIPE_DEPTH(PIPE_DEPTH - 1),
        .RETIME_STATUS(1)
    )
    d_hash_r2
    (
        .clk    (clk                ),
        .reset  (rst                ),
        .en     (1'b1               ),
        .in     (color_R14U         ),
        .out    (color_R16U_retime  )
    );

    /*dff2 #(
        .WIDTH(SIGFIG),
        .ARRAY_SIZE(2),
        .PIPE_DEPTH(PIPE_DEPTH - 1),
        .RETIME_STATUS(1)
    )*/
    dff3 #(
        .WIDTH(SIGFIG),
        .ARRAY_SIZE1(SAMPLES),
        .ARRAY_SIZE2(2),
        .PIPE_DEPTH(PIPE_DEPTH - 1),
        .RETIME_STATUS(1)
    )
    d_hash_r3
    (
        .clk    (clk                ),
        .reset  (rst                ),
        .en     (1'b1               ),
        .in     (sample_jitted_R14S ),
        .out    (sample_R16S_retime )
    );

    /*dff_retime #(
        .WIDTH(1),
        .PIPE_DEPTH(PIPE_DEPTH - 1),
        .RETIME_STATUS(1) // Retime
    )*/
    dff2 #(
        .WIDTH(1),
        .ARRAY_SIZE(SAMPLES),
        .PIPE_DEPTH(PIPE_DEPTH - 1),
        .RETIME_STATUS(1) // Retime
    )
    d_hash_r4
    (
        .clk    (clk                    ),
        .reset  (rst                    ),
        .en     (1'b1                   ),
        .in     (validSamp_R14H         ),
        .out    (validSamp_R16H_retime  )
    );
    //Flop R14 to R16_retime with retiming registers

    //Flop R16_retime to R16 with fixed registers
    dff3 #(
        .WIDTH(SIGFIG),
        .ARRAY_SIZE1(VERTS),
        .ARRAY_SIZE2(AXIS),
        .PIPE_DEPTH(1),
        .RETIME_STATUS(0)
    )
    d_hash_f1
    (
        .clk    (clk                ),
        .reset  (rst                ),
        .en     (1'b1               ),
        .in     (tri_R16S_retime    ),
        .out    (tri_R16S           )
    );

    dff2 #(
        .WIDTH(SIGFIG),
        .ARRAY_SIZE(COLORS),
        .PIPE_DEPTH(1),
        .RETIME_STATUS(0)
    )
    d_hash_f2
    (
        .clk    (clk                ),
        .reset  (rst                ),
        .en     (1'b1               ),
        .in     (color_R16U_retime  ),
        .out    (color_R16U         )
    );

    /*dff2 #(
        .WIDTH(SIGFIG),
        .ARRAY_SIZE(2),
        .PIPE_DEPTH(1),
        .RETIME_STATUS(0)
    )*/
    dff3 #(
        .WIDTH(SIGFIG),
        .ARRAY_SIZE1(SAMPLES),
        .ARRAY_SIZE2(2),
        .PIPE_DEPTH(1),
        .RETIME_STATUS(0)
    )
    d_hash_f3
    (
        .clk    (clk                         ),
        .reset  (rst                         ),
        .en     (!(!gate_RnnH & Gate_RnnH)   ),
        .in     (sample_R16S_retime          ),
        .out    (sample_R16S                 )
    );

    /*dff #(
        .WIDTH(1),
        .PIPE_DEPTH(1),
        .RETIME_STATUS(0) // No retime
    )*/
    dff2 #(
        .WIDTH(1),
        .ARRAY_SIZE(SAMPLES),
        .PIPE_DEPTH(1),
        .RETIME_STATUS(0) // No retime
    )
    d_hash_f4
    (
        .clk    (clk                       ),
        .reset  (rst                       ),
        .en     (!(!gate_RnnH & Gate_RnnH) ),
        .in     (validSamp_R16H_retime     ),
        .out    (validSamp_R16H            )
    );
    //Flop R16_retime to R16 with fixed registers


   dff #(
        .WIDTH(1),
        .PIPE_DEPTH(1),
        .RETIME_STATUS(0) // No retime
    )
    bit0
    (
        .clk    (clk                     ),
        .reset  (rst                     ),
        .en     (!(|tri_R14S[0][0])      ),
        .in     (!Gate_RnnH              ),
        .out    (Gate_RnnH               )
    );

    dff #(
        .WIDTH(1),
        .PIPE_DEPTH(1),
        .RETIME_STATUS(0) // No retime
    )
    bit1
    (
        .clk    (Gate_RnnH               ),
        .reset  (rst                     ),
        .en     (!(|tri_R14S[1][0])      ),
        .in     (!gate_RnnH              ),
        .out    (gate_RnnH               )
    );



endmodule
