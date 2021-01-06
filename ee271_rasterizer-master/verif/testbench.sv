 /*   Simulation bench for Hider
  *
  *   Author: John Brunhaver, Ofer Shacham
  *   Created:          09/21/09
  *   Last Updated:     10/06/10
  *
  *   Copyright 2009 <jbrunhaver@gmail.com>  <shacham@stanford.edu>
  */

/* ***************************************************************************
 * Change bar:
 * -----------
 * Date           Author    Description
 * Sep 20, 2012   jingpu    ported from John's original code to Genesis
 *
 * ***************************************************************************/

//; # local variables
//; my $delay_r2z_mon = $pipes_samp;
//; my $delay_r2z_sb = $pipes_samp;

//Environment Constants
//; #`define T_CLK 1000

//; #`timescale 1ps/1ps
//Environment Constants

module testbench
#(
    parameter SIGFIG = 24, // Bits in color and position.
    parameter RADIX = 10, // Fraction bits in color and position
    parameter VERTS = 3, // Maximum Vertices in triangle
    parameter AXIS = 3, // Number of axis foreach vertex 3 is (x,y,z).
    parameter COLORS = 3, // Number of color channels
    parameter SAMPLES = 2, // Number of samples to test at once
    parameter PIPES_BOX = 3, // Number of Pipe Stages in bbox module
    parameter PIPES_ITER = 1, // Number of Pipe Stages in iter module
    parameter PIPES_HASH = 2, // Number of pipe stages in hash module
    parameter PIPES_SAMP = 4 // Number of Pipe Stages in sample module
)
(
    // Output Signals (to DUT inputs)
    output logic signed   [SIGFIG-1:0]  tri_R10S[VERTS-1:0][AXIS-1:0], // triangle Position
    output logic unsigned [SIGFIG-1:0]  color_R10U[COLORS-1:0],         // Color of triangle
    output logic                        validTri_R10H,                 // Valid Data for Operation

    // Output Control Signals (to DUT inputs)
    output logic signed [SIGFIG-1:0]    screen_RnnnnS[1:0], // Screen Dimensions
    output logic        [3:0]           subSample_RnnnnU,   // SubSample_Interval

    // Global Signals
    input logic                         clk,                 // Clock
    output logic                        rst,                 // Reset

    // Input Control Signals (from DUT outputs)
    input logic                         halt_RnnnnL,

    // Input Signals (from DUT outputs)
    //input logic signed   [SIGFIG-1:0]   hit_R18S[AXIS-1:0],       // Hit Location
    input logic signed   [SIGFIG-1:0]   hit_R18S[SAMPLES-1:0][AXIS-1:0],       // Hit Location
    input logic unsigned [SIGFIG-1:0]   color_R18U[COLORS-1:0],  // Color of triangle
    //input logic                         hit_valid_R18H            // Is this a hit?
    input logic                         hit_valid_R18H[SAMPLES-1:0]            // Is this a hit?
);

    localparam DETAILED_LOGGING = 0; // Turn this to 1 for detailed logging

    // Some simulation variables
    int seed;
    int timeout;
    int dummy; // for random number generator initialization
    string  testname;

    int ss_w_lg2_RnnnnS;

    //BENCH Logical Signals
    logic test_finish;

   /*****************************************
   *
   * Instance Driver
   *
   *****************************************/

    rast_driver #(
        .SIGFIG (SIGFIG ),
        .RADIX  (RADIX  ),
        .VERTS  (VERTS  ),
        .AXIS   (AXIS   ),
        .COLORS (COLORS )
    )
    rast_driver
    (
        .halt_RnnnnL        (top_rast.rast.halt_RnnnnL  ), // Input:  Indicates No Work Should Be Done

        .tri_R10S           (tri_R10S                   ), // Output: 4 Sets X,Y Fixed Point Values
        .color_R10U         (color_R10U                 ), // Output: Color of triangle
        .validTri_R10H      (validTri_R10H              ), // Output: Valid Data for Operation
        .screen_RnnnnS      (screen_RnnnnS              ), // Output: Screen Dimensions
        .subSample_RnnnnU   (subSample_RnnnnU           ), // Output: SubSample_Interval
        .ss_w_lg2_RnnnnS    (ss_w_lg2_RnnnnS            ), // Output: SubSample_Interval

        .clk                (clk                        ), // Input:  Clock
        .rst                (rst                        ) // Input:  Reset
    );

    /******************************************
    *
    * ZBuff Model
    *
    ******************************************/

    zbuff #(
        .SIGFIG     (SIGFIG         ),
        .RADIX      (RADIX          ),
        .VERTS      (VERTS          ),
        .AXIS       (AXIS           ),
        .COLORS     (COLORS         ),
        .SAMPLES    (SAMPLES        ),
        .FILENAME   ("f_image.ppm"  )
    )
    zbuff
    (
        .clk                (clk                ), // Clock
        .rst                (rst                ), // Reset

        .screen_RnnnnS      (screen_RnnnnS      ), // Output: Screen Dimensions
        .subSample_RnnnnU   (subSample_RnnnnU   ), // Output: SubSample_Interval
        .ss_w_lg2_RnnnnS    (ss_w_lg2_RnnnnS    ),

        .hit_R18S           (hit_R18S           ), // Sample Location and depth
        .color_R18U         (color_R18U         ), // Color of Sample Hit
        .hit_valid_R18H     (hit_valid_R18H     )  // Is sample hit valid
    );

    /*****************************************
    *
    * Instance Scoreboards
    *
    *****************************************/

    bbx_sb #(
        .SIGFIG     (SIGFIG     ),
        .RADIX      (RADIX      ),
        .VERTS      (VERTS      ),
        .AXIS       (AXIS       ),
        .COLORS     (COLORS     ),
        .PIPE_DEPTH (PIPES_BOX  )
    )
    bbx_sb
    (
        .tri_R10S           (tri_R10S                           ), // Input: 4 Sets X,Y Fixed Point Values
        .validTri_R10H      (validTri_R10H                      ), // Input: Valid triangle

        .tri_R13S           (top_rast.rast.tri_R13S             ), // Input: 4 Sets X,Y Fixed Point Values
        .box_R13S           (top_rast.rast.box_R13S             ), // Input: Bound Box
        .validTri_R13H      (top_rast.rast.validTri_R13H        ), // Input: Valid Data for Operation
        //.invalidate_R10H    (top_rast.rast.bbox.invalidate_R10H ),

        .clk                (clk                                ), // Input: Clock
        .rst                (rst                                ), // Input: Reset

        .halt_RnnnnL        (top_rast.rast.halt_RnnnnL          ), // Input: Halt Signal
        .screen_RnnnnS      (screen_RnnnnS                      ), // Screen Size
        .subSample_RnnnnU   (subSample_RnnnnU                   )  // Flag for subsample
    );

    smpl_sb #(
        .SIGFIG     (SIGFIG     ),
        .RADIX      (RADIX      ),
        .VERTS      (VERTS      ),
        .AXIS       (AXIS       ),
        .COLORS     (COLORS     ),
        .SAMPLES    (SAMPLES    ),
        .PIPE_DEPTH (PIPES_SAMP )
    )
    smpl_sb
    (
        .tri_R16S       (top_rast.rast.tri_R16S         ), // 4 Sets X,Y Fixed Point Values
        .color_R16U     (top_rast.rast.color_R16U       ), // triangle Color
        .validSamp_R16H (top_rast.rast.validSamp_R16H   ),
        .sample_R16S    (top_rast.rast.sample_R16S      ), // Will change for JIT -todo

        .clk            (clk                            ), // Clock
        .rst            (rst                            ), // Reset

        .hit_R18S       (hit_R18S                       ),
        .color_R18U     (color_R18U                     ), // triangle Color
        .hit_valid_R18H (hit_valid_R18H                 )
    );

    logic signed [SIGFIG-1:0] sample_R14S_tempx[SAMPLES-1:0];
    logic signed [SIGFIG-1:0] sample_R14S_tempy[SAMPLES-1:0];
    logic signed [7:0] jitval_R14S_tempx[SAMPLES-1:0];
    logic signed [7:0] jitval_R14S_tempy[SAMPLES-1:0];
    logic signed [SIGFIG-1:0] sample_jit_R14S_tempx[SAMPLES-1:0];
    logic signed [SIGFIG-1:0] sample_jit_R14S_tempy[SAMPLES-1:0];

    generate
        for (genvar i = 0; i < SAMPLES; i = i + 1) begin : temp_sample_gen
            assign sample_R14S_tempx[i] = top_rast.rast.hash_jtree.sample_R14S[i][0];
            assign sample_R14S_tempy[i] = top_rast.rast.hash_jtree.sample_R14S[i][1];
            assign jitval_R14S_tempx[i] = top_rast.rast.hash_jtree.jitt_val_R14H[i][0];
            assign jitval_R14S_tempy[i] = top_rast.rast.hash_jtree.jitt_val_R14H[i][1];
            assign sample_jit_R14S_tempx[i] = top_rast.rast.hash_jtree.sample_jitted_R14S[i][0];
            assign sample_jit_R14S_tempy[i] = top_rast.rast.hash_jtree.sample_jitted_R14S[i][1];
        end
    endgenerate

    smpl_cnt_sb #(
        .SIGFIG     (SIGFIG         ),
        .RADIX      (RADIX          ),
        .VERTS      (VERTS          ),
        .AXIS       (AXIS           ),
        .COLORS     (COLORS         ),
        .SAMPLES    (SAMPLES        ),
        .PIPE_DEPTH (PIPES_SAMP + 1 )
    )
    smpl_cnt_sb
    (
        .tri_R16S           (top_rast.rast.tri_R16S         ), // 4 Sets X,Y Fixed Point Values
        .color_R16U         (top_rast.rast.color_R16U       ), // triangle Color
        .validSamp_R16H     (top_rast.rast.validSamp_R16H   ),
        .sample_R16S        (top_rast.rast.sample_R16S      ), // Will change for JIT -todo

        .clk                (clk                            ), // Clock
        .rst                (rst                            ), // Reset

        .hit_R18S           (hit_R18S                       ),
        .color_R18U         (color_R18U                     ), // triangle Color
        .hit_valid_R18H     (hit_valid_R18H                 ),

        .screen_RnnnnS      (screen_RnnnnS                  ), // Screen Size
        .subSample_RnnnnU   (subSample_RnnnnU               ), // Flag for subsample

        .s_x_RnnS           (sample_R14S_tempx        ),
        .s_y_RnnS           (sample_R14S_tempy        ),
        .jitter_x_RnnS      (jitval_R14S_tempx        ),
        .jitter_y_RnnS      (jitval_R14S_tempy        ),
        .s_j_x_RnnS         (sample_jit_R14S_tempx    ),
        .s_j_y_RnnS         (sample_jit_R14S_tempy    )
    );


    /*****************************************
    *
    * Instance Monitors
    *
    *****************************************/

    perf_monitor #(
        .SIGFIG     (SIGFIG     ),
        .RADIX      (RADIX      ),
        .VERTS      (VERTS      ),
        .AXIS       (AXIS       ),
        .COLORS     (COLORS     ),
        .SAMPLES    (SAMPLES    ),
        .PIPE_DEPTH (PIPES_SAMP )
    )
    perf_mon
    (
        .tri_R10S       (top_rast.rast.tri_R10S       ), // 4 Sets X,Y Fixed Point Values
        .color_R10U     (top_rast.rast.color_R10U     ), // triangle Color
        .validSamp_R16H (top_rast.rast.validSamp_R16H ),
        .sample_R16S    (top_rast.rast.sample_R16S    ), // Will change for JIT -todo

        .clk            (clk                          ), // Clock
        .rst            (rst                          ), // Reset

        .hit_R18S       (hit_R18S                     ),
        .color_R18U     (top_rast.rast.color_R18U     ), // triangle Color
        .hit_valid_R18H (hit_valid_R18H               )
    );

   /*****************************************
    * Main simulation task
    *****************************************/
    initial begin
        rst = 1'b1;
        rast_driver.InitLines();

        $display("time=%10t ************** Loading Arguments *****************", $time);
        ProcessArgs();
        $display("Seed=%d ", seed);
        dummy = $random(seed); // initial the random number generator
        repeat (15) @(posedge clk);

        rast_driver.testname = testname; // tell the driver what to drive
        rast_driver.InitTest();
        repeat (15) @(posedge clk);

        zbuff.init_buffers();
        repeat (15) @(posedge clk);

        $display("time=%10t ************** Running Test *****************", $time);
        rst = 1'b0;

        if ($test$plusargs("af")) begin
            $toggle_start(); //start activity factor extraction
        end

        rast_driver.testname = testname; // tell the driver what to drive
        rast_driver.RunTest(); // Tell the driver to start

        while (!rast_driver.TestFinish) // wait for driver to finish
            @(posedge clk);
        repeat (15) @(posedge clk);

        if ($test$plusargs("af")) begin
            $toggle_stop(); //activity factor extraction end
        end

        zbuff.write_image();

        if ($test$plusargs("af")) begin
            $display("time=%10t ******* Printing AF Extraction *********\n",$time);
            $toggle_report("af_extraction.saif",1.0e-9,top_rast.rast);
        end

        $display("time=%10t ********************FINISH***********************", $time);
        $display("Cycles: %d triangle: %d sampleTests: %d sampleHits: %d \n" ,
            perf_mon.cycle_count  , perf_mon.triangle_count ,
            perf_mon.sample_count , perf_mon.sample_hit_count );
        $display("JJ: triangle / cycle : %f " , (1.0*perf_mon.triangle_count)/
            (1.0* perf_mon.cycle_count));
        $display("JJ: cycle / triangle : %f " ,
            (1.0* perf_mon.cycle_count)/
            (1.0* perf_mon.triangle_count) );

        //Call Function for Zbuff write out.
        $finish(2);
    end // initial begin

    // Timeout mechanism
    initial begin
        repeat(timeout) @(posedge clk);
        $display("time=%10t ***************** ERROR: TIMEOUT  *******************", $time);
        $finish(2);
    end

   /****************************************************************************
    * Auxiliary Tasks:
    * *************************************************************************/
    task ProcessArgs;
    begin
        // if this is a "+wave" run, it must record all signals
        if ( $test$plusargs("wave") ) begin
            //         levels  instance
            $display("time=%10t Starting Wave Capture", $time);
            $vcdplusfile("wave.vpd");
			$vcdpluson(0); 
            $vcdplusmemon(0);

        end // if ( $test$plusargs("wave") )
        if ( $test$plusargs("af") ) begin
            $set_gate_level_monitoring("rtl_on");
            $set_toggle_region( top_rast.rast ); //select scope for aqctivity factor extraction
        end
        // look for +seed+12345 runtime args
        if ($test$plusargs("seed")) begin
            $value$plusargs("seed=%d", seed);
            $display("Simulation will run with random seed=%0d", seed);
        end
        else begin
            seed=12345;
            $display("Simulation run with default random seed=%0d", seed);
        end

        // look for +timout+1000 runtime args
        if ($test$plusargs("timeout")) begin
            $value$plusargs("timeout=%d", timeout);
            $display("Simulation will timout after %0d cycles", timeout);
        end
        else begin
            timeout=50000000 ;
            $display("Simulation will timout after %0d cycles", timeout);
        end

        // look for +testname=sample_test.dat type of argument
        if ($test$plusargs("testname")) begin
            $value$plusargs("testname=%s", testname);
            $display("Simulation will use test file %s", testname);
        end
        else begin
            testname="tests/sample_test.dat";
            $display("Simulation will use test file %s", testname);
        end

    end
   endtask // ProcessArgs
   /****************************************************************************
    * Auxiliary Tasks:
    * *************************************************************************/

endmodule
