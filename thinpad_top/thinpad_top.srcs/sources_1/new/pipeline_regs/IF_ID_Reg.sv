module IF_ID_Reg (
    input wire clk,
    input wire rst,
    
    input wire[31:0] in_instr,
    input wire[31:0] in_pc,

    output reg[31:0] out_instr,
    output reg[31:0] out_pc
);
    
    always_ff @(posedge clk or posedge rst) begin : IF_ID
        if (rst) begin
            out_instr <= 0;
            out_pc <= 0;
        end
        else begin
            out_instr <= in_instr;
            out_pc <= in_pc;
        end
    end

endmodule