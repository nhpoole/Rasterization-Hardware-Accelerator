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

//Environment Constants
//; #`define T_CLK 1000

//; #`timescale 1ps/1ps
//Environment Constants

module testbench_magma
#(
    parameter SIGFIG = 24, // Bits in color and position.
    parameter RADIX = 10, // Fraction bits in color and position
    parameter VERTS = 3, // Maximum Vertices in triangle
    parameter AXIS = 3, // Number of axis foreach vertex 3 is (x,y,z).
    parameter COLORS = 3, // Number of color channels
    parameter PIPES_BOX = 3, // Number of Pipe Stages in bbox module
    parameter PIPES_ITER = 1, // Number of Pipe Stages in iter module
    parameter PIPES_HASH = 2, // Number of pipe stages in hash module
    parameter PIPES_SAMP = 4 // Number of Pipe Stages in sample module
)
(
    // Output Signals (to DUT inputs)
    output logic signed   [SIGFIG-1:0]  tri_R10S[VERTS-1:0][AXIS-1:0] , // triangle Position
    output logic unsigned [SIGFIG-1:0]  color_R10U[COLORS-1:0] ,         // Color of triangle
    output logic                        validTri_R10H ,                 // Valid Data for Operation

    // Output Control Signals (to DUT inputs)
    output logic signed [SIGFIG-1:0]    screen_RnnnnS[1:0] , // Screen Dimensions
    output logic        [3:0]           subSample_RnnnnU ,   // SubSample_Interval

    // Global Signals
    input logic     clk,                 // Clock
    output logic    rst,                 // Reset

    // Input Control Signals (from DUT outputs)
    input logic                         halt_RnnnnL,

    // Input Signals (from DUT outputs)
    input logic signed   [SIGFIG-1:0]   hit_R18S[AXIS-1:0],       // Hit Location
    input logic unsigned [SIGFIG-1:0]   color_R18U[COLORS-1:0] ,  // Color of triangle
    input logic                         hit_valid_R18H            // Is this a hit?
);

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
        .halt_RnnnnL        (top_rast_magma.rast.halt_RnnnnL  ), // Input:  Indicates No Work Should Be Done

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
        .FILENAME   ("f_image.ppm"  )
    )
    zbuff
    (
        .clk                (clk                ), // Clock
        .rst                (rst                ), // Reset

        .screen_RnnnnS      (screen_RnnnnS      ) , // Output: Screen Dimensions
        .subSample_RnnnnU   (subSample_RnnnnU   ), // Output: SubSample_Interval
        .ss_w_lg2_RnnnnS    (ss_w_lg2_RnnnnS    ),

        .hit_R18S           (hit_R18S           ), //Sample Location and depth
        .color_R18U         (color_R18U         ), //Color of Sample Hit
        .hit_valid_R18H     (hit_valid_R18H     ) //Is sample hit valid
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

        $display("time=%10t ************** Runnning Test *****************", $time);
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
            $toggle_report("af_extraction.saif",1.0e-9,top_rast_magma.rast);
        end

        $display("time=%10t ********************FINISH***********************", $time);

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
            /*
            $vcdpluson(0,top_rast_magma.rast); //
                $vcdpluson(0,rast_driver); //
                $vcdpluson(0,bbox_scoreboard); //
                $vcdpluson(0,sampletest_scoreboard); //
                $vcdpluson(0,sampletest_count_scoreboard); //

            $vcdplusmemon(0,top_rast_magma.rast);
            $vcdplusmemon(0,rast_driver); //
                $vcdplusmemon(0,bbox_scoreboard); //
                $vcdplusmemon(0,sampletest_scoreboard); //
                $vcdplusmemon(0,sampletest_count_scoreboard); //

            $vcdplusmemon(0,zbuff.hit_R18S); //
            $vcdplusmemon(0,zbuff.color_R18U); //
            $vcdplusmemon(0,zbuff.color); //
            $vcdpluson(0,zbuff); //
                */
            $vcdplusmemon(0);
            $vcdpluson(0);

        end // if ( $test$plusargs("wave") )
        if ( $test$plusargs("af") ) begin
            $set_gate_level_monitoring("rtl_on");
            $set_toggle_region(top_rast_magma.rast); //select scope for aqctivity factor extraction
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
