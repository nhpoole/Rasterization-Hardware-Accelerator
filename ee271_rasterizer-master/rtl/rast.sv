/*
 * Reyes Style Hider:
 *
 *  This module accepts a stream of triangles
 *  and produces a stream of fragments
 *
 *  This module contains three submodules:
 *    -bounding box module which generates the bounding box
 *     for a triangle
 *    -test iterator module which iterates over the bounding
 *    -sample test function which tests to see if the sample
 *     location from the bounding box lay inside the triangle
 *
 *
 *   Author: John Brunhaver
 *   Created:          09/21/09
 *   Last Updated: TUE 10/20/09
 *
 *   Copyright 2009 <jbrunhaver@gmail.com>
 */


/* ***************************************************************************
 * Change bar:
 * -----------
 * Date           Author    Description
 * Sep 19, 2012   jingpu    ported from John's original code to Genesis
 *
 * ***************************************************************************/
//`include "rast_params.sv"
import rast_params::*;

module rast
#(
    parameter SIGFIG = rast_params::SIGFIG, // Bits in color and position.
    parameter RADIX = rast_params::RADIX, // Fraction bits in color and position
    parameter VERTS = rast_params::VERTS, // Maximum Vertices in triangle
    parameter AXIS = rast_params::AXIS, // Number of axis foreach vertex 3 is (x,y,z).
    parameter COLORS = rast_params::COLORS, // Number of color channels
    parameter SAMPLES = rast_params::SAMPLES, // Number of samples to test at once
    parameter PIPES_BOX = rast_params::PIPES_BOX, // Number of Pipe Stages in bbox module
    parameter PIPES_ITER = rast_params::PIPES_ITER, // Number of Pipe Stages in iter module
    parameter PIPES_HASH = rast_params::PIPES_HASH, // Number of pipe stages in hash module
    parameter PIPES_SAMP = rast_params::PIPES_SAMP // Number of Pipe Stages in sample module
)
(
    // Input Signals
    input logic signed [SIGFIG-1:0]     tri_R10S[VERTS-1:0][AXIS-1:0], // Tri Position
    input logic unsigned [SIGFIG-1:0]   color_R10U[COLORS-1:0], // Color of Tri
    input logic                             validTri_R10H, // Valid Data for Operation

    // Input Control Signals ( ala CSR )
    input logic signed [SIGFIG-1:0] screen_RnnnnS[1:0], // Screen Dimensions
    input logic [3:0]                   subSample_RnnnnU, // SubSample_Interval

    // Global Signals
    input logic clk, // Clock
    input logic rst, // Reset

    // Output Control Signals
    output logic halt_RnnnnL,

    // Output Signals
    //output logic signed [SIGFIG-1:0]    hit_R18S[AXIS-1:0], // Hit Location
    output logic signed [SIGFIG-1:0]    hit_R18S[SAMPLES-1:0][AXIS-1:0], // Hit Location
    output logic unsigned [SIGFIG-1:0]  color_R18U[COLORS-1:0], // Color of Tri
    //output logic                            hit_valid_R18H            // Is this a hit?
    output logic                            hit_valid_R18H[SAMPLES-1:0]            // Is this a hit?
);
    `ifdef GENERATE_JSON
    integer bbox_file;
    integer sample_file;
    integer hash_file;
    integer iterator_file;
    integer rast_file;

    initial begin
        bbox_file = $fopen("ComputeBoundingBox_vector.json", "w");
        $fdisplay(bbox_file, "[");

        sample_file = $fopen("SampleTest_vector.json", "w");
        $fdisplay(sample_file, "[");

        hash_file = $fopen("HashJTree_vector.json", "w");
        $fdisplay(hash_file, "[");

        iterator_file = $fopen("Iterator_vector.json", "w");
        $fdisplay(iterator_file, "[");

        rast_file = $fopen("Rasterizer_vector.json", "w");
        $fdisplay(rast_file, "[");
    end

    always @(posedge clk) begin
        $fdisplay(rast_file, "{\"RESET\": \"%b\",", rst);

        $fdisplay(rast_file, "\"valid_in\": \"%b\",", validTri_R10H);

        $fdisplay(rast_file, "\"tri\": [[\"%b\", \"%b\", \"%b\"], [\"%b\", \"%b\", \"%b\"], [\"%b\", \"%b\", \"%b\"]]",
        tri_R10S[0][0],
        tri_R10S[0][1],
        tri_R10S[0][2],
        tri_R10S[1][0],
        tri_R10S[1][1],
        tri_R10S[1][2],
        tri_R10S[2][0],
        tri_R10S[2][1],
        tri_R10S[2][2], 
        ",");

        $fdisplay(rast_file, "\"color_in\": [\"%b\", \"%b\", \"%b\"]",
        color_R10U[0],
        color_R10U[1],
        color_R10U[2], 
        ",");

        $fdisplay(rast_file, "\"screen_max\": [\"%b\", \"%b\"],", screen_RnnnnS[0], screen_RnnnnS[1]);
        $fdisplay(rast_file, "\"sample_size\": \"%b\",", subSample_RnnnnU);
        $fdisplay(rast_file, "\"halt\": \"%b\",", halt_RnnnnL);
        $fdisplay(rast_file, "\"valid_hit\": \"%b\",", hit_valid_R18H);

        $fdisplay(rast_file, "\"hit\": [\"%b\", \"%b\", \"%b\"]",
        hit_R18S[0],
        hit_R18S[1],
        hit_R18S[2],
        ",");

        $fdisplay(rast_file, "\"color_out\": [\"%b\", \"%b\", \"%b\"]},",
        color_R18U[0],
        color_R18U[1],
        color_R18U[2]);
     //   ",");

       // $fdisplay(rast_file, "},");
    end
    `endif

    //Intermediate Signals
    logic signed [SIGFIG-1:0]   tri_R10S[VERTS-1:0][AXIS-1:0];  //input triangle
    logic unsigned [SIGFIG-1:0] color_R10U[COLORS-1:0] ;        //Color of input triangle

    logic signed [SIGFIG-1:0]   box_R13S[1:0][1:0];             // 2 Sets X,Y Fixed Point Values
    logic signed [SIGFIG-1:0]   tri_R13S[VERTS-1:0][AXIS-1:0];  // 4 Sets X,Y Fixed Point Values
    logic unsigned [SIGFIG-1:0] color_R13U[COLORS-1:0]  ;       // Color of Tri
    logic                       validTri_R13H;                  // Valid Data for Operation
    logic                       validTri_R13H_retime;           // Valid Data for Operation - retime

    logic signed [SIGFIG-1:0]   tri_R14S[VERTS-1:0][AXIS-1:0];  //triangle to Sample Test
    logic unsigned [SIGFIG-1:0] color_R14U[COLORS-1:0] ;        // Color of Tri
    /*logic signed [SIGFIG-1:0]   sample_R14S[1:0];               //Sample Location to Be Tested
    logic                       validSamp_R14H;                 //Sample and triangle are Valid*/
    logic signed [SIGFIG-1:0]   sample_R14S[SAMPLES-1:0][1:0];               //Sample Location to Be Tested
    logic                       validSamp_R14H[SAMPLES-1:0];                 //Sample and triangle are Valid

    logic signed [SIGFIG-1:0]   tri_R16S[VERTS-1:0][AXIS-1:0];  //triangle to Sample Test
    logic unsigned [SIGFIG-1:0] color_R16U[COLORS-1:0] ;        //Color of Tri
    /*logic signed [SIGFIG-1:0]   sample_R16S[1:0];               //Sample Location to Be Tested
    logic                       validSamp_R16H;                 //Sample and triangle are Valid*/
    logic signed [SIGFIG-1:0]   sample_R16S[SAMPLES-1:0][1:0];               //Sample Location to Be Tested
    logic                       validSamp_R16H[SAMPLES-1:0];                 //Sample and triangle are Valid

    logic [SIGFIG-1:0]  zero;                                   //fudge signal to hold zero as a reset value
    logic [127:0]       big_zero;                               //fudge signal to hold zero as a reset value
    //Intermediate Signals

    assign big_zero = 128'd0;
    assign zero = big_zero[SIGFIG-1:0];

    //TODO: Missing triangle color

    //TODO: Make param pipedepth work

    bbox #(
        .SIGFIG     (SIGFIG     ),
        .RADIX      (RADIX      ),
        .VERTS      (VERTS      ),
        .AXIS       (AXIS       ),
        .COLORS     (COLORS     ),
        .PIPE_DEPTH (PIPES_BOX  )
    )
    bbox
    (
        .tri_R10S           (tri_R10S           ),
        .color_R10U         (color_R10U         ),
        .validTri_R10H      (validTri_R10H      ),

        .halt_RnnnnL        (halt_RnnnnL        ),
        .screen_RnnnnS      (screen_RnnnnS      ),
        .subSample_RnnnnU   (subSample_RnnnnU   ),

        .clk                (clk                ),
        .rst                (rst                ),

        .tri_R13S           (tri_R13S           ),
        .color_R13U         (color_R13U         ),
        .box_R13S           (box_R13S           ),
        .validTri_R13H      (validTri_R13H      ),
        .validTri_R13H_retime (validTri_R13H_retime)
    );

    // Generating vectors for bbox
    // 'RESET': Reset, 'valid_in': Bits(1), 'tri_in':
    // Array(3,Array(3,Out(SInt(24)))), 'color_in': Array(3,Out(UInt(24))),
    // 'screen_max': Array(2,Out(SInt(24))), 'sample_size': Bits(4), 'halt':
    // Bits(1), 'valid_out': Bits(1), 'tri_out':
    // Array(3,Array(3,In(SInt(24)))), 'color_out': Array(3,In(UInt(24))),
    // 'box': Array(2,Array(2,In(SInt(24)))), 'is_quad_in': Bits(1),
    // 'is_quad_out': Bits(1)}
    `ifdef GENERATE_JSON
    always @(posedge clk) begin
        $fdisplay(bbox_file, "{\"RESET\": \"%b\",", rst);

        $fdisplay(bbox_file, "\"valid_in\": \"%b\",", validTri_R10H);

        $fdisplay(bbox_file, "\"tri_in\": [[\"%b\", \"%b\", \"%b\"], [\"%b\", \"%b\", \"%b\"], [\"%b\", \"%b\", \"%b\"]]",
        tri_R10S[0][0],
        tri_R10S[0][1],
        tri_R10S[0][2],
        tri_R10S[1][0],
        tri_R10S[1][1],
        tri_R10S[1][2],
        tri_R10S[2][0],
        tri_R10S[2][1],
        tri_R10S[2][2], 
        ",");

        $fdisplay(bbox_file, "\"color_in\": [\"%b\", \"%b\", \"%b\"]",
        color_R10U[0],
        color_R10U[1],
        color_R10U[2], 
        ",");

        $fdisplay(bbox_file, "\"screen_max\": [\"%b\", \"%b\"],", screen_RnnnnS[0], screen_RnnnnS[1]);

        $fdisplay(bbox_file, "\"sample_size\": \"%b\",", subSample_RnnnnU);

        $fdisplay(bbox_file, "\"halt\": \"%b\",", halt_RnnnnL);

        $fdisplay(bbox_file, "\"valid_out\": \"%b\",", validTri_R13H);

        $fdisplay(bbox_file, "\"tri_out\": [[\"%b\", \"%b\", \"%b\"], [\"%b\", \"%b\", \"%b\"], [\"%b\", \"%b\", \"%b\"]]",
        tri_R13S[0][0],
        tri_R13S[0][1],
        tri_R13S[0][2],
        tri_R13S[1][0],
        tri_R13S[1][1],
        tri_R13S[1][2],
        tri_R13S[2][0],
        tri_R13S[2][1],
        tri_R13S[2][2], 
        ",");

        $fdisplay(bbox_file, "\"color_out\": [\"%b\", \"%b\", \"%b\"]",
        color_R13U[0],
        color_R13U[1],
        color_R13U[2],
        ",");

        $fdisplay(bbox_file, "\"box\": [[\"%b\", \"%b\"], [\"%b\", \"%b\"]]",
        box_R13S[0][0],
        box_R13S[0][1],
        box_R13S[1][0],
        box_R13S[1][1]);
        //
        //",");

        $fdisplay(bbox_file, "},");
    end
    `endif 

    test_iterator #(
        .SIGFIG     (SIGFIG     ),
        .RADIX      (RADIX      ),
        .VERTS      (VERTS      ),
        .AXIS       (AXIS       ),
        .COLORS     (COLORS     ),
        .SAMPLES    (SAMPLES    ),
        .PIPE_DEPTH (PIPES_ITER )
    )
    test_iterator
    (
        .tri_R13S           (tri_R13S           ),
        .color_R13U         (color_R13U         ),
        .box_R13S           (box_R13S           ),
        .validTri_R13H      (validTri_R13H      ),
        .validTri_R13H_retime (validTri_R13H_retime),

        .subSample_RnnnnU   (subSample_RnnnnU   ),
        .halt_RnnnnL        (halt_RnnnnL        ),

        .clk                (clk                ),
        .rst                (rst                ),

        .tri_R14S           (tri_R14S           ),
        .color_R14U         (color_R14U         ),
        .sample_R14S        (sample_R14S        ),
        .validSamp_R14H     (validSamp_R14H     )
    );

    `ifdef GENERATE_JSON
    always @(posedge clk) begin
        $fdisplay(iterator_file, "{\"RESET\": \"%b\",", rst);

        $fdisplay(iterator_file, "\"tri_in\": [[\"%b\", \"%b\", \"%b\"], [\"%b\", \"%b\", \"%b\"], [\"%b\", \"%b\", \"%b\"]]",
        tri_R13S[0][0],
        tri_R13S[0][1],
        tri_R13S[0][2],
        tri_R13S[1][0],
        tri_R13S[1][1],
        tri_R13S[1][2],
        tri_R13S[2][0],
        tri_R13S[2][1],
        tri_R13S[2][2], 
        ",");

        $fdisplay(iterator_file, "\"color_in\": [\"%b\", \"%b\", \"%b\"]",
        color_R13U[0],
        color_R13U[1],
        color_R13U[2],
        ",");

        $fdisplay(iterator_file, "\"valid_in\": \"%b\",", validTri_R13H);

        $fdisplay(iterator_file, "\"box\": [[\"%b\", \"%b\"], [\"%b\", \"%b\"]]",
        box_R13S[0][0],
        box_R13S[0][1],
        box_R13S[1][0],
        box_R13S[1][1],
        ",");

        $fdisplay(iterator_file, "\"sample_size\": \"%b\",", subSample_RnnnnU);
        $fdisplay(iterator_file, "\"halt\": \"%b\",", halt_RnnnnL);

        $fdisplay(iterator_file, "\"tri_out\": [[\"%b\", \"%b\", \"%b\"], [\"%b\", \"%b\", \"%b\"], [\"%b\", \"%b\", \"%b\"]]",
        tri_R14S[0][0],
        tri_R14S[0][1],
        tri_R14S[0][2],
        tri_R14S[1][0],
        tri_R14S[1][1],
        tri_R14S[1][2],
        tri_R14S[2][0],
        tri_R14S[2][1],
        tri_R14S[2][2], 
        ",");

        $fdisplay(iterator_file, "\"color_out\": [\"%b\", \"%b\", \"%b\"]",
        color_R14U[0],
        color_R14U[1],
        color_R14U[2],
        ",");

        $fdisplay(iterator_file, "\"sample\": [\"%b\", \"%b\"]",
        sample_R14S[0],
        sample_R14S[1],
        ",");

        $fdisplay(iterator_file, "\"valid_sample\": \"%b\"},", validSamp_R14H);

        //$fdisplay(iterator_file, ",");
    end 
    `endif

    hash_jtree #(
        .SIGFIG     (SIGFIG     ),
        .RADIX      (RADIX      ),
        .VERTS      (VERTS      ),
        .AXIS       (AXIS       ),
        .COLORS     (COLORS     ),
        .SAMPLES    (SAMPLES    ),
        .PIPE_DEPTH (PIPES_HASH )
    )
    hash_jtree
    (
        .tri_R14S           (tri_R14S           ),
        .color_R14U         (color_R14U         ),
        .sample_R14S        (sample_R14S        ),
        .validSamp_R14H     (validSamp_R14H     ),

        .subSample_RnnnnU   (subSample_RnnnnU   ),

        .clk                (clk                ),
        .rst                (rst                ),

        .tri_R16S           (tri_R16S           ),
        .color_R16U         (color_R16U         ),
        .sample_R16S        (sample_R16S        ),
        .validSamp_R16H     (validSamp_R16H     )
    );

    `ifdef GENERATE_JSON
    always @(posedge clk) begin
        $fdisplay(hash_file, "{\"RESET\": \"%b\",", rst);

        $fdisplay(hash_file, "\"tri_in\": [[\"%b\", \"%b\", \"%b\"], [\"%b\", \"%b\", \"%b\"], [\"%b\", \"%b\", \"%b\"]]",
        tri_R14S[0][0],
        tri_R14S[0][1],
        tri_R14S[0][2],
        tri_R14S[1][0],
        tri_R14S[1][1],
        tri_R14S[1][2],
        tri_R14S[2][0],
        tri_R14S[2][1],
        tri_R14S[2][2], 
        ",");

        $fdisplay(hash_file, "\"color_in\": [\"%b\", \"%b\", \"%b\"]",
        color_R14U[0],
        color_R14U[1],
        color_R14U[2],
        ",");

        $fdisplay(hash_file, "\"sample_in\": [\"%b\", \"%b\"]",
        sample_R14S[0],
        sample_R14S[1],
        ",");

        $fdisplay(hash_file, "\"valid_sample_in\": \"%b\",", validSamp_R14H);

        $fdisplay(hash_file, "\"sample_size\": \"%b\",", subSample_RnnnnU);

        $fdisplay(hash_file, "\"tri_out\": [[\"%b\", \"%b\", \"%b\"], [\"%b\", \"%b\", \"%b\"], [\"%b\", \"%b\", \"%b\"]]",
        tri_R16S[0][0],
        tri_R16S[0][1],
        tri_R16S[0][2],
        tri_R16S[1][0],
        tri_R16S[1][1],
        tri_R16S[1][2],
        tri_R16S[2][0],
        tri_R16S[2][1],
        tri_R16S[2][2], 
        ",");

        $fdisplay(hash_file, "\"color_out\": [\"%b\", \"%b\", \"%b\"]",
        color_R16U[0],
        color_R16U[1],
        color_R16U[2],
        ",");

        $fdisplay(hash_file, "\"sample_out\": [\"%b\", \"%b\"]",
        sample_R16S[0],
        sample_R16S[1],
        ",");

        $fdisplay(hash_file, "\"valid_sample_out\": \"%b\"},", validSamp_R16H);

       // $fdisplay(hash_file, ",");
    end 
    `endif

    sampletest #(
        .SIGFIG     (SIGFIG     ),
        .RADIX      (RADIX      ),
        .VERTS      (VERTS      ),
        .AXIS       (AXIS       ),
        .COLORS     (COLORS     ),
        .SAMPLES    (SAMPLES    ),
        .PIPE_DEPTH (PIPES_SAMP )
    )
    sampletest
    (
        .tri_R16S       (tri_R16S       ),
        .color_R16U     (color_R16U     ),
        .sample_R16S    (sample_R16S    ),
        .validSamp_R16H (validSamp_R16H ),

        .clk            (clk            ),
        .rst            (rst            ),

        .hit_R18S       (hit_R18S       ),
        .color_R18U     (color_R18U     ),
        .hit_valid_R18H (hit_valid_R18H )
    );

    // Generating vectors for sampletest, printed in the same order as the
    // signals in the magma module
    `ifdef GENERATE_JSON
    always @(posedge clk) begin
        $fdisplay(sample_file, "{\"RESET\": \"%b\",", rst);

        $fdisplay(sample_file, "\"tri\": [[\"%h\", \"%h\", \"%h\"], [\"%h\", \"%h\", \"%h\"], [\"%h\", \"%h\", \"%h\"]]",
        tri_R16S[0][0],
        tri_R16S[0][1],
        tri_R16S[0][2],
        tri_R16S[1][0],
        tri_R16S[1][1],
        tri_R16S[1][2],
        tri_R16S[2][0],
        tri_R16S[2][1],
        tri_R16S[2][2], 
        ",");

        $fdisplay(sample_file, "\"color_in\": [\"%h\", \"%h\", \"%h\"]",
        color_R16U[0],
        color_R16U[1],
        color_R16U[2],
        ",");

        $fdisplay(sample_file, "\"sample\": [\"%b\", \"%b\"]",
        sample_R16S[0],
        sample_R16S[1],
        ",");

        $fdisplay(sample_file, "\"valid_sample\": \"%b\",", validSamp_R16H);

        $fdisplay(sample_file, "\"hit\": [\"%h\", \"%h\", \"%h\"]",
        hit_R18S[0],
        hit_R18S[1],
        hit_R18S[2],
        ",");

        $fdisplay(sample_file, "\"valid_hit\": \"%b\",", hit_valid_R18H);

        $fdisplay(sample_file, "\"color_out\": [\"%h\", \"%h\", \"%h\"]",
        color_R18U[0],
        color_R18U[1],
        color_R18U[2]
        );

        $fdisplay(sample_file, "},");
    end

    final begin
        $fdisplay(bbox_file, "]");
        $fdisplay(sample_file, "]");
        $fdisplay(hash_file, "]");
        $fdisplay(iterator_file, "]");
        $fdisplay(rast_file, "]");
    end 
    `endif

endmodule
