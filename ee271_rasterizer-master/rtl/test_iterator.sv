/*
 *  Bounding Box Sample Test Iteration
 *
 *  Inputs:
 *    BBox and triangle Information
 *
 *  Outputs:
 *    Subsample location and triangle Information
 *
 *  Function:
 *    Iterate from left to right bottom to top
 *    across the bounding box.
 *
 *    While iterating set the halt signal in
 *    order to hold the bounding box pipeline in
 *    place.
 *
 *
 * Long Description:
 *    The iterator starts in the waiting state,
 *    when a valid triangle bounding box
 *    appears at the input. It will enter the
 *    testing state the next cycle with a
 *    sample equivelant to the lower left
 *    cooridinate of the bounding box.
 *
 *    While in the testing state, the next sample
 *    for each cycle should be one sample interval
 *    to the right, except when the current sample
 *    is at the right edge.  If the current sample
 *    is at the right edge, the next sample should
 *    be one row up.  Additionally, if the current
 *    sample is on the top row and the right edge,
 *    next cycles sample should be invalid and
 *    equivelant to the lower left vertice and
 *    next cycles state should be waiting.
 *
 *
 *   Author: John Brunhaver
 *   Created:      Thu 07/23/09
 *   Last Updated: Tue 10/01/10
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
 * For all the signed fixed point signals (logic signed [`$sig_fig`-1:0]),
 * their highest `$sig_fig-$radix` bits, namely [`$sig_fig-1`:`$radix`]
 * represent the integer part of the fixed point number,
 * while the lowest `$radix` bits, namely [`$radix-1`:0]
 * represent the fractional part of the fixed point number.
 *
 *
 *
 * For signal subSample_RnnnnU (logic [3:0])
 * 1000 for  1x MSAA eq to 1 sample per pixel
 * 0100 for  4x MSAA eq to 4 samples per pixel,
 *              a sample is half a pixel on a side
 * 0010 for 16x MSAA eq to 16 sample per pixel,
 *              a sample is a quarter pixel on a side.
 * 0001 for 64x MSAA eq to 64 samples per pixel,
 *              a sample is an eighth of a pixel on a side.
 *
 */

module test_iterator
#(
    parameter SIGFIG = 24,      // Bits in color and position.
    parameter RADIX = 10,       // Fraction bits in color and position
    parameter VERTS = 3,        // Maximum Vertices in triangle
    parameter AXIS = 3,         // Number of axis for each vertex 3 is (x,y,z).
    parameter COLORS = 3,       // Number of color channels
    parameter PIPE_DEPTH = 1,   // How many pipe stages are in this block
    parameter SAMPLES = 2,      // number of samples to test at a time
    parameter MOD_FSM = 0       // Use Modified FSM to eliminate a wait state
)
(
    //Input Signals
    input logic signed [SIGFIG-1:0] tri_R13S[VERTS-1:0][AXIS-1:0],  //triangle to Iterate Over
    input logic unsigned [SIGFIG-1:0] color_R13U[COLORS-1:0] ,      //Color of triangle
    input logic signed [SIGFIG-1:0] box_R13S[1:0][1:0],             //Box to iterate for subsamples
    input logic validTri_R13H,                                      //triangle is valid
    input logic validTri_R13H_retime,                               //triange is valid - one cycle prior

    //Control Signals
    input logic [3:0] subSample_RnnnnU, //Subsample width
    output logic halt_RnnnnL,           //Halt -> hold current microtriangle
    //Note that this block generates
    //Global Signals
    input logic clk,                    // Clock
    input logic rst,                    // Reset

    //Outputs
    output logic signed [SIGFIG-1:0] tri_R14S[VERTS-1:0][AXIS-1:0], //triangle to Sample Test
    output logic unsigned [SIGFIG-1:0] color_R14U[COLORS-1:0],      //Color of triangle
    /*output logic signed [SIGFIG-1:0] sample_R14S[1:0],              //Sample Location to Be Tested
    output logic validSamp_R14H                                     //Sample and triangle are Valid*/
    output logic signed [SIGFIG-1:0] sample_R14S[SAMPLES-1:0][1:0], //Sample Location to Be Tested
    output logic validSamp_R14H[SAMPLES-1:0]                        //Sample and triangle are Valid
);

    // This module implement a Moore machine to iterarte sample points in bbox
    // Recall: a Moore machine is an FSM whose output values are determined
    // solely by its current state.
    // A simple way to build a Moore machine is to make states for every output
    // and the values of the current states are the outputs themselves

    // Now we create the signals for the next states of each outputs and
    // then instantiate registers for storing these states
    logic signed [SIGFIG-1:0] next_tri_R14S[VERTS-1:0][AXIS-1:0];
    logic unsigned  [SIGFIG-1:0] next_color_R14U[COLORS-1:0];
    /*logic signed [SIGFIG-1:0] next_sample_R14S[1:0];
    logic next_validSamp_R14H;*/
    logic signed [SIGFIG-1:0] next_sample_R14S[SAMPLES-1:0][1:0];
    logic next_validSamp_R14H[SAMPLES-1:0];
    logic next_halt_RnnnnL;

    // Subsample interval, computed from the subsample width.
    /*logic unsigned [SIGFIG-1:0] subSample_int;
    assign subSample_int = {{(SIGFIG-RADIX){1'b0}}, (subSample_RnnnnU << 1), {(RADIX-4){1'b0}}};*/
    logic unsigned [SIGFIG-1:0] subSample_int[SAMPLES-1:0];
    assign subSample_int[0] = {{(SIGFIG-RADIX){1'b0}}, (subSample_RnnnnU << 1), {(RADIX-4){1'b0}}};
    assign subSample_int[1] = {{(SIGFIG-RADIX){1'b0}}, (subSample_RnnnnU << 1), {(RADIX-4){1'b0}}} << 1;
    assign subSample_int[2] = subSample_int[0] | subSample_int[1];


    // Instantiate registers for storing these states
    dff3 #(
        .WIDTH(SIGFIG),
        .ARRAY_SIZE1(VERTS),
        .ARRAY_SIZE2(AXIS),
        .PIPE_DEPTH(1),
        .RETIME_STATUS(0)
    )
    d301
    (
        .clk    (clk          ),
        .reset  (rst          ),
        .en     (1'b1         ),
        .in     (next_tri_R14S),
        .out    (tri_R14S     )
    );

    dff2 #(
        .WIDTH(SIGFIG),
        .ARRAY_SIZE(COLORS),
        .PIPE_DEPTH(1),
        .RETIME_STATUS(0)
    )
    d302
    (
        .clk    (clk            ),
        .reset  (rst            ),
        .en     (1'b1           ),
        .in     (next_color_R14U),
        .out    (color_R14U     )
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
    d303
    (
        .clk    (clk             ),
        .reset  (rst             ),
        .en     (1'b1            ),
        .in     (next_sample_R14S),
        .out    (sample_R14S     )
    );

    /*dff #(
        .WIDTH(1),
        .PIPE_DEPTH(1),
        .RETIME_STATUS(0) // No retime
    )
    d304
    (
        .clk    (clk                                    ),
        .reset  (rst                                    ),
        .en     (1'b1                                   ),
        .in     (next_halt_RnnnnL                       ),
        .out    (halt_RnnnnL                            )
    );*/

    /*dff #(
        .WIDTH(1),
        .PIPE_DEPTH(1),
        .RETIME_STATUS(0) // No retime
    )*/
    dff2 #(
        .WIDTH(1),
        .ARRAY_SIZE(SAMPLES),
        .PIPE_DEPTH(1),
        .RETIME_STATUS(0)
    )
    d305
    (
        .clk    (clk                                    ),
        .reset  (rst                                    ),
        .en     (1'b1                                   ),
        .in     (next_validSamp_R14H                    ),
        .out    (validSamp_R14H                         )
    );

    // Instantiate registers for storing these states

    typedef enum logic {
        WAIT_STATE,
        TEST_STATE
    } state_t;

    generate
        if (MOD_FSM == 0) begin : fsm1_gen // Using baseline FSM
            //////
            //////  RTL code for original FSM Goes Here
            //////

            // To build this FSM we want to have two more state: one is the working
            // status of this FSM, and the other is the current bounding box where
            // we iterate sample points

            // define two more states, box_R14S and state_R14H
            logic signed [SIGFIG-1:0] box_R14S[1:0][1:0];       // state for current bounding box
            logic signed [SIGFIG-1:0] next_box_R14S[1:0][1:0];

            state_t state_R14H;             //State Designation (Waiting or Testing)
            state_t next_state_R14H;        //Next Cycles State

            dff3 #(
                .WIDTH(SIGFIG),
                .ARRAY_SIZE1(2),
                .ARRAY_SIZE2(2),
                .PIPE_DEPTH(1),
                .RETIME_STATUS(0)
            )
            d305
            (
                .clk    (clk          ),
                .reset  (rst          ),
                .en     (1'b1         ),
                .in     (next_box_R14S),
                .out    (box_R14S     )
            );

            always_ff @(posedge clk, posedge rst) begin
                if (rst) begin
                    state_R14H <= WAIT_STATE;
                end
                else begin
                    state_R14H <= next_state_R14H;
                end
            end

            // define some helper signals
            logic signed [SIGFIG-1:0] next_up_samp_R14S[SAMPLES-1:0][1:0]; //If jump up, next sample
            logic signed [SIGFIG-1:0] next_rt_samp_R14S[SAMPLES-1:0][1:0]; //If jump right, next sample set
            logic at_right_edge_R14H;                         //Current sample at right edge of bbox?
            logic at_top_edge_R14H;                           //Current sample at top edge of bbox?
            logic at_end_box_R14H;                            //Current sample at end of bbox?

            //////
            ////// First calculate the values of the helper signals using CURRENT STATES
            //////

            // 4 SAMPLES AT A TIME
            // check the comments 'A Note on Signal Names'
            // at the begining of the module for the help on
            // understanding the signals here
            /*always_comb begin
                next_up_samp_R14S[0][0] = box_R14S[0][0];
                next_up_samp_R14S[0][1] = sample_R14S[SAMPLES-1][1] + subSample_int[0];
                next_up_samp_R14S[1][0] = box_R14S[0][0] + subSample_int[0];
                next_up_samp_R14S[1][1] = sample_R14S[SAMPLES-1][1] + subSample_int[0];
                next_up_samp_R14S[2][0] = box_R14S[0][0];
                next_up_samp_R14S[2][1] = sample_R14S[SAMPLES-1][1] + subSample_int[1];
                next_up_samp_R14S[3][0] = box_R14S[0][0] + subSample_int[0];
                next_up_samp_R14S[3][1] = sample_R14S[SAMPLES-1][1] + subSample_int[1];

                next_rt_samp_R14S[0][0] = sample_R14S[SAMPLES-1][0] + subSample_int[0];
                next_rt_samp_R14S[0][1] = sample_R14S[0][1];
                next_rt_samp_R14S[1][0] = sample_R14S[SAMPLES-1][0] + subSample_int[1];
                next_rt_samp_R14S[1][1] = sample_R14S[1][1];
                next_rt_samp_R14S[2][0] = sample_R14S[SAMPLES-1][0] + subSample_int[0];
                next_rt_samp_R14S[2][1] = sample_R14S[2][1];
                next_rt_samp_R14S[3][0] = sample_R14S[SAMPLES-1][0] + subSample_int[1];
                next_rt_samp_R14S[3][1] = sample_R14S[3][1];

                at_right_edge_R14H = (sample_R14S[SAMPLES-1][0] >= box_R14S[1][0]);
                at_top_edge_R14H = (sample_R14S[SAMPLES-1][1] >= box_R14S[1][1]);
                at_end_box_R14H = at_right_edge_R14H & at_top_edge_R14H;
            end*/

            // 3 SAMPLES AT A TIME
            always_comb begin
                next_up_samp_R14S[0][0] = box_R14S[0][0];
                next_up_samp_R14S[1][0] = box_R14S[0][0] + subSample_int[0];
                next_up_samp_R14S[2][0] = box_R14S[0][0] + subSample_int[1];
                at_right_edge_R14H = (sample_R14S[SAMPLES-1][0] >= box_R14S[1][0]);
                at_top_edge_R14H = (sample_R14S[SAMPLES-1][1] == box_R14S[1][1]);
                at_end_box_R14H = at_right_edge_R14H & at_top_edge_R14H;
            end
            for (genvar i = 0; i < SAMPLES; i = i + 1) begin : get_samples_gen
                always_comb begin
                    next_up_samp_R14S[i][1] = sample_R14S[SAMPLES-1][1] + subSample_int[0];
                    next_rt_samp_R14S[i][0] = sample_R14S[SAMPLES-1][0] + subSample_int[i];
                    next_rt_samp_R14S[i][1] = sample_R14S[SAMPLES-1][1];
                end
            end

            // 2 SAMPLES AT A TIME
            /*always_comb begin
                next_up_samp_R14S[0][0] = box_R14S[0][0];
                next_up_samp_R14S[1][0] = box_R14S[0][0] + subSample_int[0];
                at_right_edge_R14H = (sample_R14S[SAMPLES-1][0] >= box_R14S[1][0]);
                at_top_edge_R14H = (sample_R14S[SAMPLES-1][1] == box_R14S[1][1]);
                at_end_box_R14H = at_right_edge_R14H & at_top_edge_R14H;
            end
            for (genvar i = 0; i < SAMPLES; i = i + 1) begin : get_samples_gen
                always_comb begin
                    next_up_samp_R14S[i][1] = sample_R14S[SAMPLES-1][1] + subSample_int[0];
                    next_rt_samp_R14S[i][0] = sample_R14S[SAMPLES-1][0] + subSample_int[i];
                    next_rt_samp_R14S[i][1] = sample_R14S[SAMPLES-1][1];
                end
            end*/

            //////
            ////// Then complete the following combinational logic defining the
            ////// next states
            //////

            // 4 SAMPLES AT A TIME
            /*always_comb begin
                unique case (state_R14H)
                    WAIT_STATE : begin
                        next_state_R14H = validTri_R13H ? TEST_STATE : WAIT_STATE;
                        next_sample_R14S[0] = box_R13S[0];
                        next_sample_R14S[1][0] = box_R13S[0][0] + subSample_int[0];
                        next_sample_R14S[1][1] = box_R13S[0][1];
                        next_sample_R14S[2][0] = box_R13S[0][0];
                        next_sample_R14S[2][1] = box_R13S[0][1] + subSample_int[0];
                        next_sample_R14S[3][0] = box_R13S[0][0] + subSample_int[0];
                        next_sample_R14S[3][1] = box_R13S[0][1] + subSample_int[0];

                        next_box_R14S = box_R13S;
                        next_validSamp_R14H[0] = validTri_R13H;
                        next_validSamp_R14H[1] = validTri_R13H &
                                                 (box_R13S[0][0] + subSample_int[0] <= box_R13S[1][0]);
                        next_validSamp_R14H[2] = validTri_R13H &
                                                 (box_R13S[0][1] + subSample_int[0] <= box_R13S[1][1]);
                        next_validSamp_R14H[3] = validTri_R13H &
                                                 (box_R13S[0][0] + subSample_int[0] <= box_R13S[1][0]) &
                                                 (box_R13S[0][1] + subSample_int[0] <= box_R13S[1][1]);
                        next_halt_RnnnnL = !validTri_R13H;
                        //halt_RnnnnL = !rst;
                        next_tri_R14S = tri_R13S;
                        next_color_R14U = color_R13U;
                    end
                    TEST_STATE : begin
                        next_state_R14H = at_end_box_R14H ? WAIT_STATE : TEST_STATE;
                        next_sample_R14S[0] = at_right_edge_R14H ? next_up_samp_R14S[0] : next_rt_samp_R14S[0];
                        next_sample_R14S[1] = at_right_edge_R14H ? next_up_samp_R14S[1] : next_rt_samp_R14S[1];
                        next_sample_R14S[2] = at_right_edge_R14H ? next_up_samp_R14S[2] : next_rt_samp_R14S[2];
                        next_sample_R14S[3] = at_right_edge_R14H ? next_up_samp_R14S[3] : next_rt_samp_R14S[3];

                        next_box_R14S = box_R14S;
                        next_validSamp_R14H[0] = !at_end_box_R14H;
                        next_validSamp_R14H[1] = !at_end_box_R14H & (next_sample_R14S[1][0] <= box_R14S[1][0]);
                        next_validSamp_R14H[2] = !at_end_box_R14H & (next_sample_R14S[2][1] <= box_R14S[1][1]);
                        next_validSamp_R14H[3] = !at_end_box_R14H & (next_sample_R14S[3][0] <= box_R14S[1][0]) &
                                                 (next_sample_R14S[3][1] <= box_R14S[1][1]);

                        next_halt_RnnnnL = at_end_box_R14H;
                        //halt_RnnnnL = !validTri_R13H;
                        next_tri_R14S = tri_R14S;
                        next_color_R14U = color_R14U;
                    end
                endcase
            end // always_comb*/

            // 3 SAMPLES AT A TIME
            always_comb begin
                unique case (state_R14H)
                    WAIT_STATE : begin
                        next_state_R14H = validTri_R13H ? TEST_STATE : WAIT_STATE;
                        next_sample_R14S[0] = box_R13S[0];
                        next_sample_R14S[1][0] = box_R13S[0][0] + subSample_int[0];
                        next_sample_R14S[1][1] = box_R13S[0][1];
                        next_sample_R14S[2][0] = box_R13S[0][0] + subSample_int[1];
                        next_sample_R14S[2][1] = box_R13S[0][1];
                        next_box_R14S = box_R13S;
                        next_validSamp_R14H[0] = validTri_R13H;
                        next_validSamp_R14H[1] = validTri_R13H &
                                                 (box_R13S[0][0] + subSample_int[0] <= box_R13S[1][0]);
                        next_validSamp_R14H[2] = validTri_R13H &
                                                 (box_R13S[0][0] + subSample_int[1] <= box_R13S[1][0]);
                        //next_halt_RnnnnL = !validTri_R13H;
                        halt_RnnnnL = !rst;
                        next_tri_R14S = tri_R13S;
                        next_color_R14U = color_R13U;
                    end
                    TEST_STATE : begin
                        next_state_R14H = at_end_box_R14H ? WAIT_STATE : TEST_STATE;
                        next_sample_R14S[0] = at_right_edge_R14H ? next_up_samp_R14S[0] : next_rt_samp_R14S[0];
                        next_sample_R14S[1] = at_right_edge_R14H ? next_up_samp_R14S[1] : next_rt_samp_R14S[1];
                        next_sample_R14S[2] = at_right_edge_R14H ? next_up_samp_R14S[2] : next_rt_samp_R14S[2];
                        next_box_R14S = box_R14S;
                        next_validSamp_R14H[0] = !at_end_box_R14H;
                        next_validSamp_R14H[1] = !at_end_box_R14H & (next_sample_R14S[1][0] <= box_R14S[1][0]);
                        next_validSamp_R14H[2] = !at_end_box_R14H & (next_sample_R14S[2][0] <= box_R14S[1][0]);
                        //next_halt_RnnnnL = at_end_box_R14H;
                        halt_RnnnnL = !validTri_R13H;
                        next_tri_R14S = tri_R14S;
                        next_color_R14U = color_R14U;
                    end
                endcase
            end // always_comb

            // 2 SAMPLES AT A TIME
            /*always_comb begin
                unique case (state_R14H)
                    WAIT_STATE : begin
                        next_state_R14H = validTri_R13H ? TEST_STATE : WAIT_STATE;
                        next_sample_R14S[0] = box_R13S[0];
                        next_sample_R14S[1][0] = box_R13S[0][0] + subSample_int[0];
                        next_sample_R14S[1][1] = box_R13S[0][1];
                        next_box_R14S = box_R13S;
                        next_validSamp_R14H[0] = validTri_R13H;
                        next_validSamp_R14H[1] = validTri_R13H &
                                                 (box_R13S[0][0] + subSample_int[0] <= box_R13S[1][0]);
                        //next_halt_RnnnnL = !validTri_R13H;
                        halt_RnnnnL = !rst;
                        next_tri_R14S = tri_R13S;
                        next_color_R14U = color_R13U;
                    end
                    TEST_STATE : begin
                        next_state_R14H = at_end_box_R14H ? WAIT_STATE : TEST_STATE;
                        next_sample_R14S[0] = at_right_edge_R14H ? next_up_samp_R14S[0] : next_rt_samp_R14S[0];
                        next_sample_R14S[1] = at_right_edge_R14H ? next_up_samp_R14S[1] : next_rt_samp_R14S[1];
                        next_box_R14S = box_R14S;
                        next_validSamp_R14H[0] = !at_end_box_R14H;
                        next_validSamp_R14H[1] = !at_end_box_R14H & (next_sample_R14S[1][0] <= box_R14S[1][0]);
                        //next_halt_RnnnnL = at_end_box_R14H;
                        halt_RnnnnL = !validTri_R13H;
                        next_tri_R14S = tri_R14S;
                        next_color_R14U = color_R14U;
                    end
                endcase
            end // always_comb*/


            //Assertions for testing FSM logic.

            // Assertions to verify the FSM transition sequence.
            // Verify that:
            // 1) A validTri_R13H signal causes a transition from WAIT state to TEST state
            assert property(@(posedge clk) (validTri_R13H && (state_R14H == WAIT_STATE)) |=>
                            (state_R14H == TEST_STATE));


            // 2) An at_end_box_R14H signal causes a transition from TEST state to WAIT state
            assert property(@(posedge clk) (at_end_box_R14H && (state_R14H == TEST_STATE)) |=>
                            (state_R14H == WAIT_STATE));

            // 3) An at_end_box_R14H signal in the TESTING state causes halt_RnnnnL to be high
            //    at the next cycle. Once we reach the end of the box, we need to clock in
            //    a new box/triangle, so we need to stop halting.
            assert property(@(posedge clk) (at_end_box_R14H && (state_R14H == TEST_STATE)) |=>
                            halt_RnnnnL);

            // Assertions end

            //////
            //////  RTL code for original FSM Finishes
            //////


            //Some Error Checking Assertions

            //Define a Less Than Property
            //
            //  a should be less than b
            property rb_lt( rst, a , b , c );
                @(posedge clk) rst | ((a<=b) | !c);
            endproperty

            // Check that Proposed Samples are in BBox.
            for (genvar i = 0; i < SAMPLES; i = i + 1) begin : assert_loop1
                for (genvar j = 0; j < 2; j = j + 1) begin : assert_loop2
                    assert property(rb_lt(rst, box_R14S[0][j], sample_R14S[i][j], validSamp_R14H[i]));
                    assert property(rb_lt(rst, sample_R14S[i][j], box_R14S[1][j], validSamp_R14H[i]));
                end
            end

            //End of Error Checking Assertions
        end 
        else begin // Use modified FSM

            //////
            //////  RTL code for modified FSM Goes Here
            //////

            // To build this FSM we want to have two more state: one is the working
            // status of this FSM, and the other is the current bounding box where
            // we iterate sample points

            // define two more states, box_R14S and state_R14H
            logic signed [SIGFIG-1:0] box_R14S[1:0][1:0];       // state for current bounding box
            logic signed [SIGFIG-1:0] next_box_R14S[1:0][1:0];

            state_t state_R14H;             //State Designation (Waiting or Testing)
            state_t next_state_R14H;        //Next Cycles State

            dff3 #(
                .WIDTH(SIGFIG),
                .ARRAY_SIZE1(2),
                .ARRAY_SIZE2(2),
                .PIPE_DEPTH(1),
                .RETIME_STATUS(0)
            )
            d305
            (
                .clk    (clk          ),
                .reset  (rst          ),
                .en     (1'b1         ),
                .in     (next_box_R14S),
                .out    (box_R14S     )
            );

            always_ff @(posedge clk, posedge rst) begin
                if (rst) begin
                    state_R14H <= WAIT_STATE;
                end
                else begin
                    state_R14H <= next_state_R14H;
                end
            end

            // define some helper signals
            logic signed [SIGFIG-1:0] next_up_samp_R14S[SAMPLES-1:0][1:0]; //If jump up, next sample
            logic signed [SIGFIG-1:0] next_rt_samp_R14S[SAMPLES-1:0][1:0]; //If jump right, next sample set
            logic at_right_edge_R14H;                         //Current sample at right edge of bbox?
            logic at_top_edge_R14H;                           //Current sample at top edge of bbox?
            logic at_end_box_R14H;                            //Current sample at end of bbox?

            //////
            ////// First calculate the values of the helper signals using CURRENT STATES
            //////

            // check the comments 'A Note on Signal Names'
            // at the begining of the module for the help on
            // understanding the signals here

            // 2 SAMPLES AT A TIME
            always_comb begin
                next_up_samp_R14S[0][0] = box_R14S[0][0];
                next_up_samp_R14S[1][0] = box_R14S[0][0] + subSample_int[0];
                at_right_edge_R14H = (sample_R14S[SAMPLES-1][0] >= box_R14S[1][0]);
                at_top_edge_R14H = (sample_R14S[SAMPLES-1][1] == box_R14S[1][1]);
                at_end_box_R14H = at_right_edge_R14H & at_top_edge_R14H;
            end
            for (genvar i = 0; i < SAMPLES; i = i + 1) begin : get_samples_gen
                always_comb begin
                    next_up_samp_R14S[i][1] = sample_R14S[SAMPLES-1][1] + subSample_int[0];
                    next_rt_samp_R14S[i][0] = sample_R14S[SAMPLES-1][0] + subSample_int[i];
                    next_rt_samp_R14S[i][1] = sample_R14S[SAMPLES-1][1];
                end
            end

            //////
            ////// Then complete the following combinational logic defining the
            ////// next states
            //////

            // 2 SAMPLES AT A TIME
            always_comb begin
                unique case (state_R14H)
                    WAIT_STATE : begin
                        next_state_R14H = validTri_R13H ? TEST_STATE : WAIT_STATE;
                        next_sample_R14S[0] = box_R13S[0];
                        next_sample_R14S[1][0] = box_R13S[0][0] + subSample_int[0];
                        next_sample_R14S[1][1] = box_R13S[0][1];
                        next_box_R14S = box_R13S;
                        next_validSamp_R14H[0] = validTri_R13H;
                        next_validSamp_R14H[1] = validTri_R13H &
                                                 (box_R13S[0][0] + subSample_int[0] <= box_R13S[1][0]);
                        halt_RnnnnL = !rst;
                        next_tri_R14S = tri_R13S;
                        next_color_R14U = color_R13U;
                    end
                    TEST_STATE : begin
                        next_state_R14H = (at_end_box_R14H & !validTri_R13H) ? WAIT_STATE : TEST_STATE;
                        unique case(1'b1)
                             at_end_box_R14H & !validTri_R13H      :begin
                                                                        next_sample_R14S[0] = box_R14S[0];
                                                                        next_sample_R14S[1][0] = box_R14S[0][0] + subSample_int[0];
                                                                        next_sample_R14S[1][1] = box_R14S[0][1];
                                                                    end
                             at_end_box_R14H &  validTri_R13H      :begin
                                                                        next_sample_R14S[0] = box_R13S[0];
                                                                        next_sample_R14S[1][0] = box_R13S[0][0] + subSample_int[0];
                                                                        next_sample_R14S[1][1] = box_R13S[0][1];
                                                                    end
                            !at_end_box_R14H &  at_right_edge_R14H :begin
                                                                        next_sample_R14S[0] = next_up_samp_R14S[0];
                                                                        next_sample_R14S[1] = next_up_samp_R14S[1];
                                                                    end
                            !at_end_box_R14H & !at_right_edge_R14H :begin
                                                                        next_sample_R14S[0] = next_rt_samp_R14S[0];
                                                                        next_sample_R14S[1] = next_rt_samp_R14S[1];
                                                                    end
                        endcase
                        next_box_R14S = (at_end_box_R14H & validTri_R13H) ? box_R13S : box_R14S;
                        next_validSamp_R14H[0] = !at_end_box_R14H | validTri_R13H;
                        next_validSamp_R14H[1] = (!at_end_box_R14H & (next_sample_R14S[1][0] <= box_R14S[1][0])) |
                                                 (at_end_box_R14H & validTri_R13H);
                        halt_RnnnnL = at_end_box_R14H | !validTri_R13H;
                        next_tri_R14S = (at_end_box_R14H & validTri_R13H) ? tri_R13S : tri_R14S;
                        next_color_R14U = (at_end_box_R14H & validTri_R13H) ? color_R13U : color_R14U;
                    end
                endcase
            end // always_comb


            //Assertions for testing FSM logic.

            // Assertions to verify the FSM transition sequence.
            // Verify that:
            // 1) A validTri_R13H signal causes a transition from WAIT state to TEST state
            assert property(@(posedge clk) (validTri_R13H && (state_R14H == WAIT_STATE)) |=>
                            (state_R14H == TEST_STATE));


            // 2) An at_end_box_R14H signal causes a transition from TEST state to WAIT state
            //    when there is no new valid triangle available.
            assert property(@(posedge clk) (at_end_box_R14H && !validTri_R13H && 
                            (state_R14H == TEST_STATE)) |=> (state_R14H == WAIT_STATE));

            // 3) An at_end_box_R14H signal in the TESTING state causes halt_RnnnnL to be high
            //    in the same cycle. Once we reach the end of the box, we need to clock in
            //    a new box/triangle, so we need to stop halting.
            assert property(@(posedge clk) (at_end_box_R14H && (state_R14H == TEST_STATE)) |->
                            halt_RnnnnL);

            // Assertions end

            //////
            //////  RTL code for modified FSM Finishes
            //////

        end
    endgenerate
endmodule



