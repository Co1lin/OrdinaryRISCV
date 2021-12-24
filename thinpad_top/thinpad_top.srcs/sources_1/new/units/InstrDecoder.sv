/*
 * by Colin
 * Ref: https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html
 *      https://github.com/riscv-non-isa/riscv-asm-manual/blob/master/riscv-asm.md
 */
 
`default_nettype none
`timescale 1ns / 1ps
`include "../headers/common.svh"
`include "../headers/ops.svh"

module InstrDecoder (
    input wire[31:0]        instr,
    output reg[4:0]         rs1,
    output reg[4:0]         rs2,
    output reg[4:0]         rd,
    output `op_id_reg_t     op_id,
    output reg[31:0]        imm,
    output reg              imm_select,
    output reg              wb_e,

    output reg              csr_e, // csr read and write
    output reg[11:0]        csr_addr
);

wire sign;
wire[19:0] sign_ext_20;
assign sign         = instr[31];
assign sign_ext_20  = {20{sign}};   // cat 20 copies of sign

wire[6:0] opcode;
assign opcode   = instr[6:0];
wire[2:0] funct3;
assign funct3   = instr[14:12];
wire[6:0] funct7;
assign funct7   = instr[31:25];

`define INVALID_OP_SETTING  op_id = `OP_ID_INVALID; \
                            rs2 = 0; rs1 = 0; rd = 0; \
                            wb_e = 0; imm_select = 0; imm = 0; \
                            csr_e = 0; csr_addr = 0;

`define NO_OP_SETTING   op_id = `OP_ID_ADD; \
                        rs2 = 0; rs1 = 0; rd = 0; \
                        wb_e = 0; imm_select = 0; imm = 0; \
                        csr_e = 0; csr_addr = 0;

always_comb begin
    `INVALID_OP_SETTING
    unique case (opcode)
        7'b0110011: begin
            // ADD   0000000SSSSSsssss000ddddd0110011
            // AND   0000000SSSSSsssss111ddddd0110011
            // OR    0000000SSSSSsssss110ddddd0110011
            // XOR   0000000SSSSSsssss100ddddd0110011
            // SLTU  0000000SSSSSsssss011ddddd0110011
            // SUB   0100000SSSSSsssss000ddddd0110011
            // XNOR
            // MIN
            // SBSET
            rs2 = instr[24:20];
            rs1 = instr[19:15];
            rd  = instr[11:7];
            wb_e = 1;
            imm = 32'h0; imm_select  = 0;
            unique case (funct3)
                3'b000: begin 
                    case (funct7)
                        7'b0000000: begin op_id = `OP_ID_ADD; end
                        7'b0100000: begin op_id = `OP_ID_SUB; end
                    endcase
                end
                3'b111: begin op_id = `OP_ID_AND; end
                3'b110: begin op_id = `OP_ID_OR; end
                3'b100: begin
                    case (funct7)
                        7'b0000000: begin op_id = `OP_ID_XOR; end
                        7'b0100000: begin op_id = `OP_ID_XNOR; end
                        7'b0000101: begin op_id = `OP_ID_MIN; end
                    endcase
                end
                3'b011: begin op_id = `OP_ID_SLTU; end
                3'b001: begin op_id = `OP_ID_SBSET; end
                default: begin `INVALID_OP_SETTING end
            endcase
        end
        7'b0010011: begin
            // ADDI  iiiiiiiiiiiisssss000ddddd0010011
            // ANDI  iiiiiiiiiiiisssss111ddddd0010011
            // ORI   iiiiiiiiiiiisssss110ddddd0010011
            // SLLI  0000000iiiiisssss001ddddd0010011
            // SRLI  0000000iiiiisssss101ddddd0010011
            rs2 = 0;
            rs1 = instr[19:15];
            rd  = instr[11:7];
            wb_e = 1;
            imm_select = 1'b1;
            imm = {sign_ext_20, instr[31:20]};
            unique case (funct3)
                3'b000: begin op_id = `OP_ID_ADDI; end
                3'b111: begin op_id = `OP_ID_ANDI; end
                3'b110: begin op_id = `OP_ID_ORI;  end
                3'b001: begin op_id = `OP_ID_SLLI; end
                3'b101: begin op_id = `OP_ID_SRLI; end
                default: begin `INVALID_OP_SETTING end
            endcase
        end
        7'b0000011: begin
            // LB    iiiiiiiiiiiisssss000ddddd0000011
            // LW    iiiiiiiiiiiisssss010ddddd0000011
            // LBU
            rs1 = instr[19:15];
            rd  = instr[11:7];
            wb_e = 1;
            imm_select = 1'b1;
            imm = {sign_ext_20, instr[31:20]};  
            unique case (funct3)
                3'b000: begin op_id = `OP_ID_LB; end
                3'b010: begin op_id = `OP_ID_LW; end
                3'b100: begin op_id = `OP_ID_LBU; end
                default: begin `INVALID_OP_SETTING end
            endcase
        end
        7'b1100111: begin
            // JALR  iiiiiiiiiiiisssss000ddddd1100111
            if (funct3 == 3'b000) begin
                rs1 = instr[19:15];
                rd  = instr[11:7];
                wb_e = 1;
                op_id = `OP_ID_JALR;
                imm = {sign_ext_20, instr[31:20]}; imm_select = 1'b1;
            end
            else begin
                `INVALID_OP_SETTING
            end
        end
        7'b0100011: begin
            // SB    iiiiiiiSSSSSsssss000iiiii0100011
            // SW    iiiiiiiSSSSSsssss010iiiii0100011
            rs2 = instr[24:20];
            rs1 = instr[19:15];
            rd = 0;
            wb_e = 0;
            imm_select = 1'b1;
            imm = {sign_ext_20, instr[31:25], instr[11:7]};
            unique case (funct3)
                3'b000: begin op_id = `OP_ID_SB; end
                3'b010: begin op_id = `OP_ID_SW; end
                default: begin `INVALID_OP_SETTING end
            endcase
        end
        7'b1100011: begin
            // BEQ   iiiiiiiSSSSSsssss000iiiii1100011
            // BNE   iiiiiiiSSSSSsssss001iiiii1100011
            // BGEU  iiiiiiiSSSSSsssss111iiiii1100011   
            //     12| 10:5 |           |4:1|11|
            rs2 = instr[24:20];
            rs1 = instr[19:15];
            rd = 0;
            wb_e = 0;
            imm_select = 1'b1;
            imm = {sign_ext_20[18:0], instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            unique case (funct3)
                3'b000: begin op_id = `OP_ID_BEQ;  end
                3'b001: begin op_id = `OP_ID_BNE;  end
                3'b111: begin op_id = `OP_ID_BGEU; end
                default: begin `INVALID_OP_SETTING end
            endcase
        end
        7'b0010111: begin
            // AUIPC iiiiiiiiiiiiiiiiiiiiddddd0010111
            op_id = `OP_ID_AUIPC;
            rs2 = 0;
            rs1 = 0;
            rd  = instr[11:7];
            wb_e = 1;
            imm_select = 1'b1;
            imm = {instr[31:12], 12'b0};
        end
        7'b0110111: begin
            // LUI   iiiiiiiiiiiiiiiiiiiiddddd0110111
            op_id = `OP_ID_LUI;
            rs2 = 0;
            rs1 = 0;
            rd  = instr[11:7];
            wb_e = 1;
            imm_select = 1'b1;
            imm = {instr[31:12], 12'b0};
        end
        7'b1101111: begin
            // JAL   iiiiiiiiiiiiiiiiiiiiddddd1101111
            op_id = `OP_ID_JAL;
            rs2 = 0;
            rs1 = 0;
            rd  = instr[11:7];
            wb_e = 1;
            imm_select = 1'b1;
            imm = {sign_ext_20[10:0], instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
        end
        7'b1110011: begin
            // CSRRC        ccccccccccccsssss011ddddd1110011
            // CSRRS        ccccccccccccsssss010ddddd1110011
            // CSRRW        ccccccccccccsssss001ddddd1110011
            // EBREAK       00000000000100000000000001110011
            // ECALL        00000000000000000000000001110011
            // MRET         00110000001000000000000001110011
            // SFENCE.VMA   0001001SSSSSsssss000000001110011
            rs1 = instr[19:15];
            rs2 = 0;
            rd  = instr[11:7];
            wb_e = 1;
            imm = 32'h0; imm_select  = 0;
            csr_e = 1;
            csr_addr = instr[31:20];
            unique case (funct3)
                3'b001: begin
                    op_id = `OP_ID_CSRRW; 
                end
                3'b010: begin
                    op_id = `OP_ID_CSRRS;
                end
                3'b011: begin
                    op_id = `OP_ID_CSRRC;
                end
                3'b000: begin
                    rs1 = 0; rs2 = 0;
                    rd = 0; wb_e = 0;
                    csr_e = 0;
                    csr_addr = 0;
                    case (instr[31:20])
                        12'b0000_0000_0000: begin op_id = `OP_ID_ECALL; end
                        12'b0000_0000_0001: begin op_id = `OP_ID_EBREAK; end
                        12'b0011_0000_0010: begin op_id = `OP_ID_MRET; end
                        12'b0001_0000_0100: begin
                            // replace no-op setting when implementing TLB
                            // op_id = `OP_ID_SFENCE_VM;
                            `NO_OP_SETTING
                        end
                        default: begin `INVALID_OP_SETTING end
                    endcase
                end
                default: begin `INVALID_OP_SETTING end
            endcase
        end
        default: begin `INVALID_OP_SETTING end
    endcase
end

endmodule
