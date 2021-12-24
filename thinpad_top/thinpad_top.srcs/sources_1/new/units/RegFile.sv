`default_nettype none
`timescale 1ns / 1ps

module RegFile (
    input wire          clk,
    input wire          rst,
    input wire          w_e,
    input wire[4:0]     w_id,
    input wire[31:0]    w_data,
    
    input wire[4:0]     r_id1,
    output reg[31:0]    r_data1,
    input wire[4:0]     r_id2,
    output reg[31:0]    r_data2
);
    
    reg[31:0] registers[0:31];
    
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            registers[0] <= 32'h00000000;
            registers[1] <= 32'h00000000;
            registers[2] <= 32'h00000000;
            registers[3] <= 32'h00000000;
            registers[4] <= 32'h00000000;
            registers[5] <= 32'h00000000;
            registers[6] <= 32'h00000000;
            registers[7] <= 32'h00000000;
            registers[8] <= 32'h00000000;
            registers[9] <= 32'h00000000;
            registers[10] <= 32'h00000000;
            registers[11] <= 32'h00000000;
            registers[12] <= 32'h00000000;
            registers[13] <= 32'h00000000;
            registers[14] <= 32'h00000000;
            registers[15] <= 32'h00000000;
            registers[16] <= 32'h00000000;
            registers[17] <= 32'h00000000;
            registers[18] <= 32'h00000000;
            registers[19] <= 32'h00000000;
            registers[20] <= 32'h00000000;
            registers[21] <= 32'h00000000;
            registers[22] <= 32'h00000000;
            registers[23] <= 32'h00000000;
            registers[24] <= 32'h00000000;
            registers[25] <= 32'h00000000;
            registers[26] <= 32'h00000000;
            registers[27] <= 32'h00000000;
            registers[28] <= 32'h00000000;
            registers[29] <= 32'h00000000;
            registers[30] <= 32'h00000000;
            registers[31] <= 32'h00000000;
        end
        else if (w_e) begin
            registers[w_id] <= w_data;
        end
    end
    
    /* CAUTION:
     * if r_id1 is zero (register), then the data must be zero
     * some instruction may write non-zero value to zero register, 
     * when we CANNOT use w_data as the result if bypassing happens (r_id1 == w_id)
     */
    always_comb begin
        if (r_id1 == 0) r_data1 = 0;
        else if (r_id1 == w_id) r_data1 = w_data; // bypassing
        else r_data1 = registers[r_id1];
    end
    
    always_comb begin
        if (r_id2 == 0) r_data2 = 0;
        else if (r_id2 == w_id) r_data2 = w_data; // bypassing
        else r_data2 = registers[r_id2];
    end

endmodule
