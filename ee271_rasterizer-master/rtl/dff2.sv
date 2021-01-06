/*
 This is a two-dimensional array of DFFs.
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
//; my $array_size      = parameter(Name=>'ArraySize1',
//;                                 Val=>64, Min=>1, Step=>1,
//;                                 Doc=>"The size of array's first dimention");
//; my $pipe_depth      = parameter(Name=>'PipelineDepth',
//;                                 Val=>1, Min=>0, Step=>1,
//;                                 Doc=>"Pipeline depth");
//; my $retime_Status   = parameter(Name=>'Retime' ,
//;                                 Val=>'NO' , List=>[ 'YES' , 'NO' ] ,
//;                                 Doc=>"Pipeline Is Retimeable" ) ;

module dff2
#(
    parameter WIDTH = 64,
    parameter ARRAY_SIZE = 64,
    parameter PIPE_DEPTH = 1,
    parameter RETIME_STATUS = 0
)
(
    input logic [WIDTH-1:0]  in[ARRAY_SIZE-1:0],
    input logic clk,
    input logic reset,
    input logic en,
    output logic [WIDTH-1:0] out[ARRAY_SIZE-1:0]
);

generate
for (genvar i = 0; i < ARRAY_SIZE; i = i + 1) begin : dff2_gen_nest0
    if (RETIME_STATUS) begin : dff2_gen_nest1
        dff_retime #(
            .WIDTH          (WIDTH          ),
            .PIPE_DEPTH     (PIPE_DEPTH     ),
            .RETIME_STATUS  (RETIME_STATUS  )
        )
        dff_pipe
        (
            .clk    (clk        ),
            .reset  (reset      ),
            .en     (en         ),
            .in     (in[i]      ),
            .out    (out[i]     )
        );
    end
    else begin : dff2_gen_nest2
        dff #(
            .WIDTH          (WIDTH          ),
            .PIPE_DEPTH     (PIPE_DEPTH     ),
            .RETIME_STATUS  (RETIME_STATUS  )
        )
        dff_pipe
        (
            .clk    (clk        ),
            .reset  (reset      ),
            .en     (en         ),
            .in     (in[i]      ),
            .out    (out[i]     )
        );
    end
end
endgenerate
   //; }

endmodule
