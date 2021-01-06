/*
 This is a three-dimensional array of DFFs.
 */

/* ***************************************************************************
 * Change bar:
 * -----------
 * Date           Author    Description
 * Sep 20, 2012   jingpu    init version
 *
 * ***************************************************************************/

/******************************************************************************
 * PARAMETERIZATION
 * ***************************************************************************/
//; # module parameters
//; my $bitwidth        = parameter(Name=>'BitWidth',
//;                                 Val=>64, Min=>1, Step=>1,
//;                                 Doc=>"Signal bit widths");
//; my $array_size1     = parameter(Name=>'ArraySize1',
//;                                 Val=>64, Min=>1, Step=>1,
//;                                 Doc=>"The size of array's first dimention");
//; my $array_size2     = parameter(Name=>'ArraySize2',
//;                                 Val=>64, Min=>1, Step=>1,
//;                                 Doc=>"The size of array's second dimention");
//; my $pipe_depth      = parameter(Name=>'PipelineDepth',
//;                                 Val=>1, Min=>0, Step=>1,
//;                                 Doc=>"Pipeline depth");
//; my $retime_Status   = parameter(Name=>'Retime' ,
//;                                 Val=>'NO' , List=>[ 'YES' , 'NO' ] ,
//;                                 Doc=>"Pipeline Is Retimeable" ) ;

module dff3
#(
    parameter WIDTH = 64,
    parameter ARRAY_SIZE1 = 64,
    parameter ARRAY_SIZE2 = 64,
    parameter PIPE_DEPTH = 1,
    parameter RETIME_STATUS = 0
)
(
    input logic [WIDTH-1:0]  in[ARRAY_SIZE1-1:0][ARRAY_SIZE2-1:0],
    input logic clk,
    input logic reset,
    input logic en,
    output logic [WIDTH-1:0] out[ARRAY_SIZE1-1:0][ARRAY_SIZE2-1:0]
);

generate
for (genvar i = 0; i < ARRAY_SIZE1; i = i + 1) begin : dff3_gen
    dff2 #(
        .WIDTH(WIDTH),
        .ARRAY_SIZE(ARRAY_SIZE2),
        .PIPE_DEPTH(PIPE_DEPTH),
        .RETIME_STATUS(RETIME_STATUS)
    )
    dff_arr
    (
        .clk    (clk        ),
        .reset  (reset      ),
        .en     (en         ),
        .in     (in[i]      ),
        .out    (out[i]     )
    );
end
endgenerate

endmodule
