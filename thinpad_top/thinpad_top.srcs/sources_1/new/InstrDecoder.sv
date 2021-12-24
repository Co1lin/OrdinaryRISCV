/*
 * by Colin
 * Ref: https://msyksphinz-self.github.io/riscv-isadoc/html/rvi.html
 *      https://github.com/riscv-non-isa/riscv-asm-manual/blob/master/riscv-asm.md
 */
 
`default_nettype none
`timescale 1ns / 1ps
`include "headers/common.vh"
`include "headers/ops.vh"

module InstrDecoder (
    input wire[31:0]        instr,
    output wire[4:0]        rs1,
    output wire[4:0]        rs2,
    output wire[4:0]        rd,
    output `op_id_reg_t     op_id,
    output reg[31:0]        imm,
    output reg              imm_select,
    output reg              wb_e
);
    wire sign;
    wire[19:0] sign_ext_20;
    assign sign         = instr[31];
    assign sign_ext_20  = {20{sign}};   // cat 20 copies of sign
    assign rd           = instr[11:7];
    assign rs1          = instr[19:15];
    assign rs2          = instr[24:20];

    wire[6:0] opcode;
    assign opcode   = instr[6:0];
    wire[2:0] funct3;
    assign funct3   = instr[14:12];
    wire[6:0] funct7;
    assign funct7   = instr[31:25];

    always_comb begin
        unique case (opcode)
            7'b0110011: begin
                // ADD   0000000SSSSSsssss000ddddd0110011
                // AND   0000000SSSSSsssss111ddddd0110011
                // OR    0000000SSSSSsssss110ddddd0110011
                // XOR   0000000SSSSSsssss100ddddd0110011
                unique case (funct3)
                    3'b000: begin op_id = `OP_ID_ADD; wb_e = 1; end
                    3'b111: begin op_id = `OP_ID_AND; wb_e = 1; end
                    3'b110: begin op_id = `OP_ID_OR; wb_e = 1; end
                    3'b100: begin op_id = `OP_ID_XOR; wb_e = 1; end
                    default: begin op_id = `OP_ID_INVALID; wb_e = 0; end
                endcase
                imm = 32'h0; imm_select  = 0;
            end
            7'b0010011: begin
                // ADDI  iiiiiiiiiiiisssss000ddddd0010011
                // ANDI  iiiiiiiiiiiisssss111ddddd0010011
                // ORI   iiiiiiiiiiiisssss110ddddd0010011
                // SLLI  0000000iiiiisssss001ddddd0010011
                // SRLI  0000000iiiiisssss101ddddd0010011
                unique case (funct3)
                    3'b000: begin op_id = `OP_ID_ADDI; imm = {sign_ext_20, instr[31:20]}; imm_select = 1'b1; wb_e = 1; end
                    3'b111: begin op_id = `OP_ID_ANDI; imm = {sign_ext_20, instr[31:20]}; imm_select = 1'b1; wb_e = 1; end
                    3'b110: begin op_id = `OP_ID_ORI; imm = {sign_ext_20, instr[31:20]}; imm_select = 1'b1; wb_e = 1; end
                    3'b001: begin op_id = `OP_ID_SLLI; imm = {sign_ext_20, instr[31:20]}; imm_select = 1'b1; wb_e = 1; end
                    3'b101: begin op_id = `OP_ID_SRLI; imm = {sign_ext_20, instr[31:20]}; imm_select = 1'b1; wb_e = 1; end
                    default: begin op_id = `OP_ID_INVALID; imm = 32'h0; imm_select  = 1'b0; wb_e = 0; end
                endcase
            end
            7'b0000011: begin
                // LB    iiiiiiiiiiiisssss000ddddd0000011
                // LW    iiiiiiiiiiiisssss010ddddd0000011
                unique case (funct3)
                    3'b000: begin op_id = `OP_ID_LB; imm = {sign_ext_20, instr[31:20]}; imm_select = 1'b1; wb_e = 1; end
                    3'b010: begin op_id = `OP_ID_LW; imm = {sign_ext_20, instr[31:20]}; imm_select = 1'b1; wb_e = 1; end
                    default: begin op_id = `OP_ID_INVALID; imm = 32'h0; imm_select  = 1'b0; wb_e = 0; end
                endcase
            end
            7'b1100111: begin
                // JALR  iiiiiiiiiiiisssss000ddddd1100111
                if (funct3 == 3'b000) begin
                    op_id = `OP_ID_JALR; imm = {sign_ext_20, instr[31:20]}; imm_select = 1'b1; wb_e = 1;
                end
                else begin
                    op_id = `OP_ID_INVALID; imm = 32'h0; imm_select  = 1'b0; wb_e = 0;
                end
            end
            7'b0100011: begin
                // SB    iiiiiiiSSSSSsssss000iiiii0100011
                // SW    iiiiiiiSSSSSsssss010iiiii0100011
                unique case (funct3)
                    3'b000: begin op_id = `OP_ID_SB; imm = {sign_ext_20, instr[31:25], instr[11:7]}; imm_select = 1'b1; end
                    3'b010: begin op_id = `OP_ID_SW; imm = {sign_ext_20, instr[31:25], instr[11:7]}; imm_select = 1'b1; end
                    default: begin op_id = `OP_ID_INVALID; imm = 32'h0; imm_select  = 1'b0; end
                endcase
                wb_e = 0;
            end
            7'b1100011: begin
                // BEQ   iiiiiiiSSSSSsssss000iiiii1100011
                // BNE   iiiiiiiSSSSSsssss001iiiii1100011
                //     12| 10:5 |           |4:1|11|
                unique case (funct3)
                    3'b000: begin op_id = `OP_ID_BEQ; imm = {sign_ext_20[18:0], instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}; imm_select = 1'b1; end
                    3'b001: begin op_id = `OP_ID_BNE; imm = {sign_ext_20[18:0], instr[31], instr[7], instr[30:25], instr[11:8], 1'b0}; imm_select = 1'b1; end
                    default: begin op_id = `OP_ID_INVALID; imm = 32'h0; imm_select  = 1'b0; end
                endcase
                wb_e = 0;
            end
            7'b0010111: begin
                // AUIPC iiiiiiiiiiiiiiiiiiiiddddd0010111
                op_id = `OP_ID_AUIPC;
                imm = {instr[31:12], 12'b0};
                imm_select = 1'b1;
                wb_e = 1;
            end
            7'b0110111: begin
                // LUI   iiiiiiiiiiiiiiiiiiiiddddd0110111
                op_id = `OP_ID_LUI;
                imm = {instr[31:12], 12'b0};
                imm_select = 1'b1;
                wb_e = 1;
            end
            7'b1101111: begin
                // JAL   iiiiiiiiiiiiiiiiiiiiddddd1101111
                op_id = `OP_ID_JAL;
                imm = {sign_ext_20[10:0], instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
                imm_select = 1'b1;
                wb_e = 1;
            end
            default: begin op_id = `OP_ID_INVALID; imm = 32'h0; imm_select  = 1'b0; wb_e = 0; end
        endcase
    end
endmodule
