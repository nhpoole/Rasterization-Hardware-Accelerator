/*
 * bbx_sb
 *
 * The bounding box score board:
 *   This scoreboard checks that the output
 *   of the bounding box moudle is correct.
 *   It does this by checking the function against
 *   the golden model, which is imported using DPI.
 *
 */

  /****************************************************************************
 * Change bar:
 * -----------
 * Date           Author    Description
 * Sep 22, 2012   jingpu    ported from John's original code to Genesis
 *
 * ***************************************************************************/

import "DPI" pure function int check_bounding_box(
    int   v0_x,     //triangle
    int   v0_y,     //triangle
    int   v1_x,     //triangle
    int   v1_y,     //triangle
    int   v2_x,     //triangle
    int   v2_y,     //triangle
    int  valid_triangle, // valid
    int   ll_x,     //BBOX
    int   ll_y,     //BBOX
    int   ur_x,     //BBOX
    int   ur_y,     //BBOX
    int   ss_w_lg2, //Subsample
    int   screen_w, //Screen
    int   screen_h, //Screen
    int  valid_bbox,   //BBOX
    int   r_shift,  //Config
    int   r_val     //Congig 
);

module bbx_sb
#(
    parameter SIGFIG = 24, // Bits in color and position.
    parameter RADIX = 10, // Fraction bits in color and position
    parameter VERTS = 3, // Maximum Vertices in triangle
    parameter AXIS = 3, // Number of axis foreach vertex 3 is (x,y,z).
    parameter COLORS = 3, // Number of color channels
    parameter PIPE_DEPTH = 3 // Number of Pipe Stages in bbox module
)
(
input logic signed [SIGFIG-1:0] tri_R10S[VERTS-1:0][AXIS-1:0],
input logic validTri_R10H, // Valid Data for Operation

input logic signed [SIGFIG-1:0] box_R13S[1:0][1:0], // 2 Sets X,Y Fixed Point Values
input logic signed [SIGFIG-1:0] tri_R13S[VERTS-1:0][AXIS-1:0], // 4 Sets X,Y Fixed Point Values
input logic                     validTri_R13H, // Valid Data for Operation
input logic [1:0][1:0]          invalidate_R10H,
input logic clk, // Clock
input logic rst , // Reset

input logic                     halt_RnnnnL, // Halt Signal
input logic signed [SIGFIG-1:0] screen_RnnnnS[1:0], // Screen Dimensions
input logic [3:0]               subSample_RnnnnU // SubSample_Interval
);

    logic signed [SIGFIG-1:0]   tri_RnnS[VERTS-1:0][AXIS-1:0];
    logic                       validTri_RnnH;                      // Valid Data for Operation
    logic [1:0][1:0]            invalidate_RnnH;

    int ss_w_lg2;

    int one;
    assign one = 1 ;

    always_comb begin
        unique case( 1'b1 )
            ( subSample_RnnnnU[0] ): ss_w_lg2 = 3;
            ( subSample_RnnnnU[1] ): ss_w_lg2 = 2;
            ( subSample_RnnnnU[2] ): ss_w_lg2 = 1;
            ( subSample_RnnnnU[3] ): ss_w_lg2 = 0;
        endcase
    end

    //Check that Bounding Box is Correct
    always @(posedge clk) begin
        if( validTri_RnnH ) begin //check only when the triangle is valid
            if(one != check_bounding_box(
                            int'(tri_RnnS[0][0]), //triangle
                            int'(tri_RnnS[0][1]), //triangle
                            int'(tri_RnnS[1][0]), //triangle
                            int'(tri_RnnS[1][1]), //triangle
                            int'(tri_RnnS[2][0]), //triangle
                            int'(tri_RnnS[2][1]), //triangle
                            int'(validTri_RnnH)    , //triangle
                            int'(box_R13S[0][0] ), //BBOX
                            int'(box_R13S[0][1] ), //BBOX
                            int'(box_R13S[1][0] ), //BBOX
                            int'(box_R13S[1][1] ), //BBOX
                            ss_w_lg2,                //Subsample
                            int'(screen_RnnnnS[0] ), //Screen
                            int'(screen_RnnnnS[1] ), //Screen
                            int'(validTri_R13H),  //triangle Valid
                            RADIX,                   //Config
                            int'( 128'd1 << RADIX )  //Congig
                            )) begin
                // Die
                $finish();
            end // if (one != rastBBox_bbox_check(...
        end // if ( validTri_R13H )
    end // always @ (posedge clk)

    dff3 #(
        .WIDTH      (SIGFIG     ),
        .ARRAY_SIZE1(VERTS      ),
        .ARRAY_SIZE2(AXIS       ),
        .PIPE_DEPTH (PIPE_DEPTH )
    )
    d_01
    (
        .clk    (clk        ),
        .reset  (rst        ),
        .en     (halt_RnnnnL),
        .in     (tri_R10S   ),
        .out    (tri_RnnS   )
    );

    dff #(
        .WIDTH          (1          ),
        .PIPE_DEPTH     (PIPE_DEPTH ),
        .RETIME_STATUS  (0          ) // No retime
    )
    d_02
    (
        .clk    (clk            ),
        .reset  (rst            ),
        .en     (halt_RnnnnL    ),
        .in     (validTri_R10H  ),
        .out    (validTri_RnnH  )
    );

    dff #(
        .WIDTH          (4          ),
        .PIPE_DEPTH     (PIPE_DEPTH ),
        .RETIME_STATUS  (0          ) // No retime
    )
    d_03
    (
        .clk    (clk            ),
        .reset  (rst            ),
        .en     (halt_RnnnnL    ),
        .in     (invalidate_R10H),
        .out    (invalidate_RnnH)
    );

    property sig_eq_con( rst, a , b , c );
        @(posedge clk) rst | ((a==b) | !c);
    endproperty

    //Check that signals should match
    assert property( sig_eq_con( rst, tri_RnnS[0][0] , tri_R13S[0][0]  , validTri_RnnH ));
    assert property( sig_eq_con( rst, tri_RnnS[0][1] , tri_R13S[0][1]  , validTri_RnnH ));
    assert property( sig_eq_con( rst, tri_RnnS[1][0] , tri_R13S[1][0]  , validTri_RnnH ));
    assert property( sig_eq_con( rst, tri_RnnS[1][1] , tri_R13S[1][1]  , validTri_RnnH ));
    assert property( sig_eq_con( rst, tri_RnnS[2][0] , tri_R13S[2][0]  , validTri_RnnH ));
    assert property( sig_eq_con( rst, tri_RnnS[2][1] , tri_R13S[2][1]  , validTri_RnnH ));

endmodule
