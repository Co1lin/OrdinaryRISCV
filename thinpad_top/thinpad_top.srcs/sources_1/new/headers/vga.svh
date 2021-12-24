`ifndef VGA_H
`define VGA_H

`define VGA_PIXEL_WIDTH 	8
`define vga_pixel_wire 		wire[`VGA_PIXEL_WIDTH-1 : 0]
`define vga_pixel_reg 		reg[`VGA_PIXEL_WIDTH-1 : 0]

`define VGA_ADDR_WIDTH 		19
`define vga_addr_wire 		wire[`VGA_ADDR_WIDTH-1 : 0]
`define vga_addr_reg 		reg[`VGA_ADDR_WIDTH-1 : 0]

`endif
