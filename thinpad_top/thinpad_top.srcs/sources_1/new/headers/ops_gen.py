'''
Generates ops.svh
'''

instrs = {
	'Invalid': 'invalid',
	'R Type': 'add, sub, and, or, xor, sltu, xnor, sbset, min',
	'I Type': 'addi, andi, jalr, lb, lw, lbu, ori, slli, srli',
	'S Type': 'sb, sw',
	'B Type': 'beq, bne, bgeu',
	'U Type': 'auipc, lui',
	'J Type': 'jal',
	'Privileged Instructions': 'csrrc, csrrs, csrrw, ebreak, ecall, mret, sfence_vm'
}

# total count and diff
instr_list = []
for i in instrs.values():
	instr_list.extend( i.split(', ') )
if len(instr_list) != len(set(instr_list)):
	raise Exception('Duplicate instructions!')
print(f'total instr count: {len(instr_list)}')

# numbering instrs
max_length = max([len(i) for i in instr_list])
instr_defs = []
instr_index = 0
for k, v in instrs.items():
	instr_defs.append(f'// {k}')
	for i in v.split(', '):
		instr_defs.append(f'`define OP_ID_{i.upper()}  {" "*(max_length-len(i))}  `OP_ID_WIDTH\'d{instr_index}')
		instr_index += 1
	instr_defs.append('')

import math
width = int(math.log2(instr_index) + 1)

with open('ops.svh', 'w') as f:

	lines = [
		'// Generated file. DO NOT EDIT!',
		'',
		'`ifndef OPS_H',
		'`define OPS_H',
		'',
		f'`define OP_ID_WIDTH  {width}',
		'`define op_id_reg_t  reg[`OP_ID_WIDTH-1 : 0]',
		'`define op_id_wire_t wire[`OP_ID_WIDTH-1 : 0]',
		''
	] + instr_defs + [
		'`endif'
	]

	f.writelines([l+'\n' for l in lines])
