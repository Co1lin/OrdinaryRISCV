module DFF #(
    parameter WIDTH = 32
) (
    input wire clk,
    input wire e,
    input  wire[WIDTH-1 : 0] nxt,
    output wire[WIDTH-1 : 0] cur
);
reg[WIDTH-1 : 0] cur_reg;
assign cur = cur_reg;
always_ff @(posedge clk) begin
    if (e)
        cur_reg <= nxt;
end
    
endmodule