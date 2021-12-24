module DFFR #(
    parameter WIDTH = 32,
    parameter INIT_VALUE = 0
) (
    input wire clk,
    input wire rst,
    input wire e,
    input  wire[WIDTH-1 : 0] nxt,
    output wire[WIDTH-1 : 0] cur
);
reg[WIDTH-1 : 0] cur_reg;
assign cur = cur_reg;
always_ff @(posedge clk or posedge rst) begin
    if (rst)
        cur_reg <= INIT_VALUE;
    else if (e)
        cur_reg <= nxt;
end
    
endmodule