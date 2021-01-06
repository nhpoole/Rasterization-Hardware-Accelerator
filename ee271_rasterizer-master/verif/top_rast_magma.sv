 import rast_params::*;
 
 module top_rast_magma;

    localparam SIGFIG = rast_params::SIGFIG; // Bits in color and position.
    localparam RADIX = rast_params::RADIX; // Fraction bits in color and position
    localparam VERTS = rast_params::VERTS; // Maximum Vertices in triangle
    localparam AXIS = rast_params::AXIS; // Number of axis foreach vertex 3 is (x,y,z).
    localparam COLORS = rast_params::COLORS; // Number of color channels
    localparam PIPES_BOX = rast_params::PIPES_BOX; // Number of Pipe Stages in bbox module
    localparam PIPES_ITER = rast_params::PIPES_ITER; // Number of Pipe Stages in iter module
    localparam PIPES_HASH = rast_params::PIPES_HASH; // Number of pipe stages in hash module
    localparam PIPES_SAMP = rast_params::PIPES_SAMP; // Number of Pipe Stages in sample module

   /*****************************************
    * wires to connect design and environment
    *****************************************/

    //DUT INPUTS
    logic signed   [SIGFIG-1:0] tri_R10S[VERTS-1:0][AXIS-1:0] ;   // 4 Sets X,Y Fixed Point Values
    logic unsigned [SIGFIG-1:0] color_R10U[COLORS-1:0] ;   // 4 Sets X,Y Fixed Point Values
    logic                           validTri_R10H ;        // Valid Data for Operation
    //DUT INPUTS

    //DUT CONFIG
    logic signed   [SIGFIG-1:0] screen_RnnnnS[1:0];       // Screen Dimensions
    logic          [3:0]            subSample_RnnnnU ;        // SubSample_Interval
    //DUT CONFIG

    //DUT GLOBAL
    logic clk ;                     // Clock
    logic rst ;                     // Reset
    //DUT GLOBAL

    //DUT OUTPUTS
    logic                           halt_RnnnnL;
    logic signed   [SIGFIG-1:0] hit_R18S[AXIS-1:0]; //Sample hit Location
    logic unsigned [SIGFIG-1:0] color_R18U[COLORS-1:0]; //Sample hit Location
    logic                           hit_valid_R18H ;  //Did Sample Hit?
    //DUT OUTPUTS

    // instantiate the DUT
    rast_magma #(
        .SIGFIG     (SIGFIG     ),
        .RADIX      (RADIX      ),
        .VERTS      (VERTS      ),
        .AXIS       (AXIS       ),
        .COLORS     (COLORS     ),
        .PIPES_BOX  (PIPES_BOX  ),
        .PIPES_ITER (PIPES_ITER ),
        .PIPES_HASH (PIPES_HASH ),
        .PIPES_SAMP (PIPES_SAMP )
    )
    rast
    (
        .tri_R10S           (tri_R10S           ), // Input: 4 Sets X,Y Fixed Point Values
        .color_R10U         (color_R10U         ), // Input: 4 Sets X,Y Fixed Point Values
        .validTri_R10H      (validTri_R10H      ), // Input: Valid Data for Operation

        .screen_RnnnnS      (screen_RnnnnS      ), // Input: Screen Dimensions
        .subSample_RnnnnU   (subSample_RnnnnU   ), // Input: SubSample_Interval

        .clk                (clk                ), // Input: Clock
        .rst                (rst                ), // Input: Reset

        .halt_RnnnnL        (halt_RnnnnL        ),

        .hit_R18S           (hit_R18S           ), // Output: Sample Location Tested
        .color_R18U         (color_R18U         ), // Input: 4 Sets X,Y Fixed Point Values
        .hit_valid_R18H     (hit_valid_R18H     )  // Output: Does Sample lie in triangle
    );

    clocker #(
        .PERIOD(1000)
    )
    clocker
    (
        .clk(clk)
    );

    testbench_magma #(
        .SIGFIG     (SIGFIG     ),
        .RADIX      (RADIX      ),
        .VERTS      (VERTS      ),
        .AXIS       (AXIS       ),
        .COLORS     (COLORS     ),
        .PIPES_BOX  (PIPES_BOX  ),
        .PIPES_ITER (PIPES_ITER ),
        .PIPES_HASH (PIPES_HASH ),
        .PIPES_SAMP (PIPES_SAMP )
    )
    testbench
    (
        // Output Signals (to DUT inputs)
        .tri_R10S           (tri_R10S           ),
        .color_R10U         (color_R10U         ),
        .validTri_R10H      (validTri_R10H      ),
        // Output Control Signals (to DUT inputs)
        .screen_RnnnnS      (screen_RnnnnS      ),
        .subSample_RnnnnU   (subSample_RnnnnU   ),
        // Global Signals
        .clk                (clk                ),
        .rst                (rst                ),
        // Input Control Signals (from DUT outputs)
        .halt_RnnnnL        (halt_RnnnnL        ),
        // Input Signals (from DUT outputs)
        .hit_R18S           (hit_R18S           ),
        .color_R18U         (color_R18U         ),
        .hit_valid_R18H     (hit_valid_R18H     )
    );

endmodule //
