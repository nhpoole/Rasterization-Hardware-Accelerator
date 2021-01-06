/*
 *  zbuff.v
 *
 *  Model of a z-buffer
 *
 *  Inputs:
 *   Sample Location
 *   Sample Hit
 *   Sample Depth
 *   Sample Color
 *
 *  Outputs:
 *   None -> Writes an image file at simulation end
 *
 *  Function:
 *   Implement Zbuffer algorithm
 *   Write image at simualtion end
 *
 *
 *   Author: John Brunhaver
 *   Created:      Mon 10/18/10
 *   Last Updated: Mon 10/18/10
 *
 *   Copyright 2010 <jbrunhaver@gmail.com>
 *
 */

  /****************************************************************************
 * Change bar:
 * -----------
 * Date           Author    Description
 * Sep 22, 2012   jingpu    ported from John's original code to Genesis
 *
 * ***************************************************************************/

/* A Note on Signal Names:
 *
 * Most signals have a suffix of the form _RxxxxN
 * where R indicates that it is a Raster Block signal
 * xxxx indicates the clock slice that it belongs to
 * and N indicates the type of signal that it is.
 * H indicates logic high, L indicates logic low,
 * U indicates unsigned fixed point, and S indicates
 * signed fixed point.
 *
 */


import "DPI" pure function
int check_zbuff_init(
    int w,    //Screen Width
    int h,    //Screen Width
    int ss_w  //Subsample Width
);

import "DPI" pure function
int check_zbuff_process_fragment(
    int x ,   //Hit Loc. X
    int y ,   //Hit Loc. Y
    int ss_x ,  //`$ss` Hit loc X
    int ss_y ,  //`$ss` Hit Loc Y
    int d , //actually a uint
    int R , //actually a ushort
    int G , //actually a ushort
    int B   //actually a ushort
);

import "DPI" pure function
int check_zbuff_write_ppm();


module zbuff
#(
    parameter SIGFIG = 24, // Bits in color and position.
    parameter RADIX = 10, // Fraction bits in color and position
    parameter VERTS = 3, // Maximum Vertices in triangle
    parameter AXIS = 3, // Number of axis foreach vertex 3 is (x,y,z).
    parameter COLORS = 3, // Number of color channels
    parameter FILENAME = "f_image.ppm", // Output image file name
    parameter FB_L2 = 11, // Log_2 of Greatest Pixel Width
    parameter FB = 2048, // Greatest Pixel Width or Pixel Height for simulation
    parameter SS_L2 = 2, // Number of bits needed for maximum subsampling index
    parameter SS = 4, // Greatest number of x ind needed for subsampling 4-> 16x MSAA
    parameter SAMPLES = 2, // number of samples to test at a time
    parameter COLORP = 12 // Bits of Precision in Color
)
(
    input logic clk,
    input logic rst,

    input logic signed [SIGFIG-1:0] screen_RnnnnS[1:0],              // Input: Screen Dimensions
    input logic        [3:0]            subSample_RnnnnU,                // Input: SubSample_Interval
    input int                           ss_w_lg2_RnnnnS,

    //input logic signed   [SIGFIG-1:0] hit_R18S[AXIS-1:0],
    input logic signed   [SIGFIG-1:0] hit_R18S[SAMPLES-1:0][AXIS-1:0],
    input logic unsigned [SIGFIG-1:0] color_R18U[COLORS-1:0],
    //input logic                           hit_valid_R18H
    input logic                           hit_valid_R18H[SAMPLES-1:0]
);

    /*logic unsigned [FB_L2-1:0]  x_ind;
    logic unsigned [FB_L2-1:0]  y_ind;
    logic unsigned [SS_L2-1:0]  x_ss_ind;
    logic unsigned [SS_L2-1:0]  y_ss_ind;
    logic unsigned [SIGFIG-1:0] depth;*/
    logic unsigned [FB_L2-1:0]  x_ind[SAMPLES-1:0];
    logic unsigned [FB_L2-1:0]  y_ind[SAMPLES-1:0];
    logic unsigned [SS_L2-1:0]  x_ss_ind[SAMPLES-1:0];
    logic unsigned [SS_L2-1:0]  y_ss_ind[SAMPLES-1:0];
    logic unsigned [SIGFIG-1:0] depth[SAMPLES-1:0];

    logic unsigned [SIGFIG-1:0] color[COLORS-1:0];

    int unsigned     x_max;
    int unsigned     y_max;
    int unsigned     ss_max;
    int unsigned     ss_rate;

    logic [SIGFIG-1:0]   zero; //fudge signal to hold zero as a reset value
    logic [127:0]            big_zero; //fudge signal to hold zero as a reset value

    assign big_zero = 128'd0;
    assign zero = big_zero[SIGFIG-1:0];

    generate
        for (genvar i = 0; i < SAMPLES; i = i + 1) begin : hit_gen
            assign  depth[i] = unsigned'(hit_R18S[i][2]);
            assign  x_ind[i] = hit_R18S[i][0][(RADIX+FB_L2-1):RADIX];
            assign  y_ind[i] = hit_R18S[i][1][(RADIX+FB_L2-1):RADIX];
        end
    endgenerate

    /*assign  depth = unsigned'(hit_R18S[2]);
    assign  x_ind = hit_R18S[0][(RADIX+FB_L2-1):RADIX];
    assign  y_ind = hit_R18S[1][(RADIX+FB_L2-1):RADIX];*/

    //Brittle Only works for COLORS=3
    assign color[0] = color_R18U[0];
    assign color[1] = color_R18U[1];
    assign color[2] = color_R18U[2];

    assign x_max = screen_RnnnnS[0][SIGFIG-1:RADIX];
    assign y_max = screen_RnnnnS[1][SIGFIG-1:RADIX];

    generate
        for (genvar i = 0; i < SAMPLES; i = i + 1) begin : hit_gen2
            always_comb begin
                unique case ( subSample_RnnnnU )
                    (4'b1000 ): x_ss_ind[i][SS_L2-1:0] =   zero[SS_L2-1:0];
                    (4'b0100 ): x_ss_ind[i][SS_L2-1:0] = { zero[SS_L2-1:1] , hit_R18S[i][0][RADIX-1] };
                    (4'b0010 ): x_ss_ind[i][SS_L2-1:0] = { zero[SS_L2-1:1] , hit_R18S[i][0][RADIX-1:RADIX-2] };
                    (4'b0001 ): x_ss_ind[i][SS_L2-1:0] = {                   hit_R18S[i][0][RADIX-1:RADIX-3] };
                endcase // case ( subSample_RnnnnU )

                unique case ( subSample_RnnnnU )
                    (4'b1000 ): y_ss_ind[i][SS_L2-1:0] =   zero[SS_L2-1:0] ;
                    (4'b0100 ): y_ss_ind[i][SS_L2-1:0] = { zero[SS_L2-1:1] , hit_R18S[i][1][RADIX-1] }  ;
                    (4'b0010 ): y_ss_ind[i][SS_L2-1:0] = { zero[SS_L2-1:1] , hit_R18S[i][1][RADIX-1:RADIX-2] }  ;
                    (4'b0001 ): y_ss_ind[i][SS_L2-1:0] = {                   hit_R18S[i][1][RADIX-1:RADIX-3] }  ;
                endcase // case ( subSample_RnnnnU )
            end
        end
    endgenerate

    always_comb begin

        /*unique case ( subSample_RnnnnU )
            (4'b1000 ): x_ss_ind[SS_L2-1:0] =   zero[SS_L2-1:0];
            (4'b0100 ): x_ss_ind[SS_L2-1:0] = { zero[SS_L2-1:1] , hit_R18S[0][RADIX-1] };
            (4'b0010 ): x_ss_ind[SS_L2-1:0] = { zero[SS_L2-1:1] , hit_R18S[0][RADIX-1:RADIX-2] };
            (4'b0001 ): x_ss_ind[SS_L2-1:0] = {                   hit_R18S[0][RADIX-1:RADIX-3] };
        endcase // case ( subSample_RnnnnU )

        unique case ( subSample_RnnnnU )
            (4'b1000 ): y_ss_ind[SS_L2-1:0] =   zero[SS_L2-1:0] ;
            (4'b0100 ): y_ss_ind[SS_L2-1:0] = { zero[SS_L2-1:1] , hit_R18S[1][RADIX-1] }  ;
            (4'b0010 ): y_ss_ind[SS_L2-1:0] = { zero[SS_L2-1:1] , hit_R18S[1][RADIX-1:RADIX-2] }  ;
            (4'b0001 ): y_ss_ind[SS_L2-1:0] = {                   hit_R18S[1][RADIX-1:RADIX-3] }  ;
        endcase // case ( subSample_RnnnnU )*/

        unique case ( subSample_RnnnnU )
            (4'b1000 ): ss_max = 1  ;
            (4'b0100 ): ss_max = 2  ;
            (4'b0010 ): ss_max = 4  ;
            (4'b0001 ): ss_max = 8  ;
        endcase // case ( subSample_RnnnnU )

        unique case ( subSample_RnnnnU )
            (4'b1000 ): ss_rate = 1  ;
            (4'b0100 ): ss_rate = 4  ;
            (4'b0010 ): ss_rate = 16 ;
            (4'b0001 ): ss_rate = 64 ;
        endcase // case ( subSample_RnnnnU )

    end

    always @(posedge clk) begin
        #25;
        /*if( hit_valid_R18H && ~rst ) begin
            check_zbuff_process_fragment(  x_ind ,   //Hit Loc. X
                y_ind ,   //Hit Loc. Y
                x_ss_ind ,  //SS Hit loc X
                y_ss_ind ,  //SS Hit Loc Y
                depth , //actually a uint
                color[0] , //actually a ushort
                color[1] , //actually a ushort
                color[2]  //actually a ushort
            ) ;
        end*/
        for (integer i = 0; i < SAMPLES; i = i + 1) begin : zbuff_loop
            if( hit_valid_R18H[i] && ~rst ) begin
                check_zbuff_process_fragment(  x_ind[i] ,   //Hit Loc. X
                    y_ind[i] ,   //Hit Loc. Y
                    x_ss_ind[i] ,  //SS Hit loc X
                    y_ss_ind[i] ,  //SS Hit Loc Y
                    depth[i] , //actually a uint
                    color[0] , //actually a ushort
                    color[1] , //actually a ushort
                    color[2]  //actually a ushort
                ) ;
            end
        end
    end

    task init_buffers;
    begin
        $display("time=%10t ************** Initializing FB and ZB *****************", $time);
        #10;

        check_zbuff_init( x_max,    //Screen Width
                y_max,    //Screen Width
                ss_max  //Subsample Width
                );

        $display("time=%10t ************** Finished Init FB and ZB *****************", $time);
    end
    endtask

    task write_image;
    begin
        #10;

        $display("time=%10t ************** Writing Final Image to File *****************", $time);
        #10;

       check_zbuff_write_ppm( );
        #10;

        $display("time=%10t ************** Finished Final Image to File *****************", $time);
        #10;
    end
    endtask //write_image

endmodule
