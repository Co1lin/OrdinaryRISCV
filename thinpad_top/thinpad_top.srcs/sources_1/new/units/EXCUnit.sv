`include "../headers/exc.svh"
`include "../headers/ops.svh"

module EXCUnit (
    input wire clk,
    input wire rst,
    input `op_id_wire_t op_id,
    input wire csr_e,
    input `csr_addr_wire_t csr_addr,
    input `word_wire_t rs1_data,
    input wire mem_out_timeout,
    input `pc_wire_t id_exe_out_pc, // for recovering async interrupt
    input `pc_wire_t if_id_out_pc, // for recovering sync exception (ecall, ebreak)
    input `pri_level_reg_t pri_level_in,
    output `mxlen_reg_t csr_r_data,
    output reg intrpt_e,
    output reg exc_ret_e,   // intrpt, ecall, ebreak, mret
    output `word_reg_t target_addr,
    output `sxlen_wire_t satp,
    output `pri_level_reg_t pri_level_next
);

mip_t csr_mip;
mie_t csr_mie;
mstatus_t csr_mstatus;
mtvec_t csr_mtvec;
mcause_t csr_mcause;
mscratch_t csr_mscratch;
mepc_t csr_mepc;

satp_t csr_satp;
assign satp = csr_satp;

wire exc_ret_flag;
assign exc_ret_flag = op_id == `OP_ID_MRET; // todo should add more if supervisor mode is supported

// global mie
wire real_global_mie;
assign real_global_mie = pri_level_in ==`LEVEL_MACHINE ? csr_mstatus.mie : 1; // mie is always enabled in lower levels
// todo supervisor global interrupt enable

// timeout interrupt
always_comb begin
    csr_mip = {24'b0, mem_out_timeout, 7'b0};
end
wire interrupt_timeout;
assign interrupt_timeout = csr_mip.mtip & csr_mie.mtie & real_global_mie;

// exceptions (in a broad way)
reg exc_flag;
mcause_t exception_to_throw;
always_comb begin
    exc_flag = 0;
    exception_to_throw = 0;
    intrpt_e = 0;
    // Interrupt priority: MEI, MSI, MTI, SEI, SSI, STI, UEI, USI, UTI
    if (interrupt_timeout) begin
        exc_flag = 1;
        intrpt_e = 1;
        exception_to_throw.intrpt = 1;
        exception_to_throw.exception_code = `EXC_CODE_INTERRUPT_MACHINE_TIMER;
    end
    // Synchronous exceptions are of lower priority than all interrupts
    else if (op_id == `OP_ID_ECALL) begin
        if (pri_level_in == `LEVEL_USER) begin
            exc_flag = 1;
            exception_to_throw.intrpt = 0;
            exception_to_throw.exception_code = `EXC_CODE_EXCEPTION_ECALL_FROM_U;
        end // ecall from supervisor and user not implemented
    end
    else if (op_id == `OP_ID_EBREAK) begin
        exc_flag = 1;
        exception_to_throw.intrpt = 0;
        exception_to_throw.exception_code = `EXC_CODE_EXCEPTION_BREAK;
    end
end
// generate jumping signal and target PC for ecall, ebreak, mret only
always_comb begin
    if (exc_flag) begin
        // intrpt or ecall or ebreak
        exc_ret_e = 1;
        target_addr = csr_mtvec;
    end
    else if (exc_ret_flag) begin
        // mret
        exc_ret_e = 1;
        target_addr = csr_mepc;
    end
    else begin
        exc_ret_e = 0;
        target_addr = 0;
    end
end

always_comb begin
    if (exc_flag)
        pri_level_next = `LEVEL_MACHINE;
    else if (exc_ret_flag)
        pri_level_next = csr_mstatus.mpp;
    else
        pri_level_next = `LEVEL_ILLEGAL;
end

// csr read & write
wire csr_w_e;
`csr_addr_wire_t csr_w_addr;
`csr_addr_wire_t csr_r_addr;
assign csr_w_e    = csr_e;
assign csr_w_addr = csr_addr;
assign csr_r_addr = csr_addr;
`mxlen_reg_t  csr_w_data;
always_comb begin
    case (op_id)
        `OP_ID_CSRRW: csr_w_data = rs1_data;
        `OP_ID_CSRRS: csr_w_data = csr_r_data | rs1_data;
        `OP_ID_CSRRC: csr_w_data = csr_r_data & (~rs1_data);
        default: csr_w_data = 0;
    endcase
end

always @(posedge clk or posedge rst) begin
    if (rst) begin
        /* mstatus init:
         *   mie = 0 (ensure kernel doesn't interrupt)
         *   mpie = 1 (ensure user program can interrupt)
         *   mpp = 00 (ensure switch to user level)
         *   tvm = 0 (1: r/w satp, SFENCE.VMA are illegal; 0: legal in S-mode)
         */
        csr_mstatus <= 32'b0000_0000_0000_0000_0000_0000_1000_0000;
        csr_mie <= 0;
        csr_mtvec <= 0;
        csr_mcause <= 0;
        csr_mscratch <= 0;
        csr_mepc <= 0;   
        csr_satp <= 0;
    end
    else begin
        if (exc_flag) begin
            // TODO currently will only jump to M mode, otherwise medeleg should be taken account
            csr_mstatus.mpie <= csr_mstatus.mie;
            csr_mstatus.mie <= 1'b0;
            csr_mstatus.mpp <= pri_level_in;
            // pri_level <= `LEVEL_MACHINE;
            csr_mcause <= exception_to_throw;
            /* CAUTION:
             * for interruption, return addr is where to resume;
             * for exception, return addr is where the exception happened!
             * (software will add 4 to mepc for exception)
             */
            csr_mepc <= exception_to_throw.intrpt ? id_exe_out_pc : if_id_out_pc;
        end
        else if (exc_ret_flag) begin
            // pri_level <= csr_mstatus.mpp;
            csr_mstatus.mie <= csr_mstatus.mpie;
            csr_mstatus.mpie <= 1'b1;
            csr_mstatus.mpp <= `LEVEL_USER;
        end
        else if (csr_w_e) begin
            // CSR Registers Wrting
            case (csr_w_addr)
                `CSR_MSTATUS: begin // mpp is WARL, leave unchanged if illegal
                    if (csr_w_data[12:11] == 2'b10) // if mpp field is 2'b10, which is undefined privilege level
                        csr_mstatus <= {csr_w_data[`MXLEN-1 : 13], csr_mstatus.mpp, csr_w_data[10:0]};
                    else
                        csr_mstatus <= csr_w_data;
                end
                `CSR_MIE:           csr_mie <= csr_w_data;
                `CSR_MTVEC:         csr_mtvec <= {csr_w_data[`MXLEN-1 : 2], 2'b0}; // hardwire mode to 0, i.e. direct mode
                `CSR_MSCRATCH:      csr_mscratch <= csr_w_data;
                `CSR_MEPC:          csr_mepc <= {csr_w_data[`MXLEN-1 : 1], 1'b0}; // always 0 for last bit
                `CSR_MCAUSE:        csr_mcause <= csr_w_data;
                `CSR_MIP: begin
                    // mtip is read only (already set in always_comb upward), stip & utip may be written in M mdoe
                    // msip is memory mapped for remote harts, ssip & usip can be written by higher level
                    // meip is read only, seip & ueip (N extension) may be written in M mdoe
                end
                `CSR_SATP:          csr_satp <= csr_w_data;
                default: ;
            endcase
        end
    end
end

// CSR Registers Reading
always_comb begin
    case (csr_r_addr)
        `CSR_MSTATUS:       csr_r_data = csr_mstatus;
        `CSR_MIE:           csr_r_data = csr_mie;
        `CSR_MTVEC:         csr_r_data = csr_mtvec;
        `CSR_MSCRATCH:      csr_r_data = csr_mscratch;
        `CSR_MEPC:          csr_r_data = csr_mepc; // the last bit *would* always be 0
        `CSR_MCAUSE:        csr_r_data = csr_mcause;
        `CSR_MIP:           csr_r_data = csr_mip;
        `CSR_SATP:          csr_r_data = csr_satp;
        default: csr_r_data = 0;
    endcase
end


endmodule