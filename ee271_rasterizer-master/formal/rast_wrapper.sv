/*
Wrapper for rast to constrain signals
*/
module rast_wrapper
(
    input logic signed [24-1:0]     tri_R10S[3-1:0][3-1:0], // Poly Position
    input logic unsigned [24-1:0]   color_R10U[3-1:0],
    input logic [1:0]               subSample,

    //Global Signals
    input logic clk, // Clock
    input logic rst, // Reset

    //Control Signals
    output logic halt_RnnnnL,

    //Outout Signals
    output logic signed [24-1:0]    hit_R18S[3-1:0], // Output: Sample Location Tested
    output logic unsigned [24-1:0]  color_R18U[3-1:0], // Input: 4 Sets X,Y Fixed Point Values
    output logic                    hit_valid_R18H  // Output: Does Sample lie in uPoly
);

    logic signed [24-1:0]    screen_RnnnnS[1:0]; // Screen Dimensions
    logic                    validTri_R10H;  // Valid Data for Operation
    logic                    cmp_validR10H [2:0] [1:0] [1:0];
    logic                    validTri_R10H_input[1:0][1:0];
    logic [1:0]              subSample_RnnU;
    logic [3:0]              subSample_RnnnnU;

    assign screen_RnnnnS[0] = {1'b1,19'd0};
    assign screen_RnnnnS[1] = {1'b1,19'd0};

    //Constrain subSample to change only at rst
    always @(posedge clk)
    begin
        if(rst) subSample_RnnU <= subSample;
    end

    always_comb begin
        //Convert subSample to one hot
        unique case (subSample_RnnU) // synopsys full_case
            2'b00 : subSample_RnnnnU = 4'b0001;
            2'b01 : subSample_RnnnnU = 4'b0010;
            2'b10 : subSample_RnnnnU = 4'b0100;
            2'b11 : subSample_RnnnnU = 4'b1000;
        endcase // case (subSample)

        // Generate validTri_R10H if all coordinates are in screen limits
        cmp_validR10H [2][0][0] = (tri_R10S[2][0] >= 0);
        cmp_validR10H [2][1][0] = (tri_R10S[2][0] <= screen_RnnnnS[0]);
        cmp_validR10H [1][0][0] = (tri_R10S[1][0] >= 0);
        cmp_validR10H [1][1][0] = (tri_R10S[1][0] <= screen_RnnnnS[0]);
        cmp_validR10H [0][0][0] = (tri_R10S[0][0] >= 0);
        cmp_validR10H [0][1][0] = (tri_R10S[0][0] <= screen_RnnnnS[0]);
        cmp_validR10H [2][0][1] = (tri_R10S[2][1] >= 0);
        cmp_validR10H [2][1][1] = (tri_R10S[2][1] >= screen_RnnnnS[1]);
        cmp_validR10H [1][0][1] = (tri_R10S[1][1] >= 0);
        cmp_validR10H [1][1][1] = (tri_R10S[1][1] >= screen_RnnnnS[1]);
        cmp_validR10H [0][0][1] = (tri_R10S[0][1] >= 0);
        cmp_validR10H [0][1][1] = (tri_R10S[0][1] <= screen_RnnnnS[1]);

        validTri_R10H_input[0][0] = (cmp_validR10H [2][0][0] & (cmp_validR10H [1][0][0] & cmp_validR10H [0][0][0]));
        validTri_R10H_input[0][1] = (cmp_validR10H [2][0][1] & (cmp_validR10H [1][0][1] & cmp_validR10H [0][0][1]));
        validTri_R10H_input[1][0] = (cmp_validR10H [2][1][0] & (cmp_validR10H [1][1][0] & cmp_validR10H [0][1][0]));
        validTri_R10H_input[1][1] = (cmp_validR10H [2][1][1] & (cmp_validR10H [1][1][1] & cmp_validR10H [0][1][1]));

        validTri_R10H = validTri_R10H_input[0][0] & (validTri_R10H_input[0][1] & (validTri_R10H_input[1][0] & validTri_R10H_input[1][1]));
    end // always_comb

    rast dut
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
        .hit_valid_R18H     (hit_valid_R18H     )  // Output: Does Sample lie in uPoly
    );
endmodule
