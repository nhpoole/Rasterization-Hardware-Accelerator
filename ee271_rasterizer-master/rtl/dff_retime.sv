/*
 This is a Genesis wrapper of DW pipeline regs with en singal
 */

/* ***************************************************************************
 * Change bar:
 * -----------
 * Date           Author    Description
 * Sep 20, 2012   jingpu    init version
 *
 * ***************************************************************************/

module dff_retime
#(
    parameter WIDTH = 64, // Signal bit widths
    parameter PIPE_DEPTH = 1, // Pipeline depth
    parameter RETIME_STATUS = 0 // Pipeline Is Retimeable
)
(
    input logic [WIDTH - 1:0]  in,
    input logic clk,
    input logic reset,
    input logic en,
    output logic [WIDTH - 1:0] out
);

// Compiler pragmas for retiming

   /* synopsys dc_tcl_script_begin
       set_ungroup [current_design] true
       set_flatten true -effort high -phase true -design [current_design]
       set_dont_retime [current_design] false
       set_optimize_registers true -design [current_design]
    */


generate
if (PIPE_DEPTH > 0) begin : dff_retime_gen

    DW_pl_reg
    #(
        .stages     (PIPE_DEPTH + 1 ),
        .in_reg     (0              ),
        .out_reg    (0              ),
        .width      (WIDTH          ),
        .rst_mode   (0              )
    )
    dff_pipe
    (
        .clk        (clk                ),
        .rst_n      (!reset             ),
        .data_in    (in                 ),
        .data_out   (out                ),
        .enable     ({PIPE_DEPTH{en}})
    );

end 
else begin
    assign out = in & (~{WIDTH{reset}});
end
endgenerate

endmodule
