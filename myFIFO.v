///////////////////////////////////////////////////////////////////////////////////////////////
// This is the FIFO (First in First out) Verilog code:
// The design is build using of Dual Port SRAM.
// Consider this as hardware implementation of Circular FIFO with Two Pointer.
// Two pointers can named as "write pointer(wptr)" and "read pointer(rptr)".
// Using the pointer of n-bit wider we able to trace Memory Depth upto "2n".
// This is because the MSB of the pointer is used only to set the "FULL" and "EMPTY" output.
// The code will divide into the 5 modules as follows:
//		1. Module for "Memory Block (Dual Port SRAM)".
//		2. Module for updating the "Read Pointer (rptr)".
//		3. Module for updating the "Write Pointer (wptr)".
//		4. Module for updating the Status Signals like "FULL" and "EMPTY" output.
//		5. TOP Module in which all above modules are connected together.
//////////////////////////////////////////////////////////////////////////////////////////////

module fifo_top #(parameter DATA_WIDTH = 8, parameter ADDR_WIDTH = 3, parameter FIFO_DEPTH = (1 << ADDR_WIDTH))
	(o_data,fifo_full,fifo_empty,clk,rstn,i_we,i_rd,i_data);
	
	// Port define:
	input  clk,rstn,i_we,i_rd;
	input  [DATA_WIDTH-1 : 0] i_data;
	output [DATA_WIDTH-1 : 0] o_data;
	output fifo_empty,fifo_full;
	
	// Internal variables:
	wire [ADDR_WIDTH :0] wptr,rptr;
	wire fifo_we,fifo_rd;
		
	// Module instantiated:
	// 1. Memory Block (Dual Port SRAM)
	memory_array #(DATA_WIDTH,ADDR_WIDTH,FIFO_DEPTH) mod_mem
	(
		.o_data(o_data),
		.i_data(i_data),
		.clk(clk),
		.fifo_we(fifo_we),
		.fifo_rd(fifo_rd),
		.rstn(rstn),
		.wptr(wptr),
		.rptr(rptr)
	);
	
	// 2. Reap Pointer Module 	
	read_pointer #(ADDR_WIDTH) mod_rptr
	(
		.rptr(rptr),
		.fifo_rd(fifo_rd),
		.clk(clk),
		.rstn(rstn),
		.i_rd(i_rd),
		.fifo_empty(fifo_empty)
	);
	
	// 3. Write Pointer Module
	write_pointer #(ADDR_WIDTH) mod_wptr
	(
		.wptr(wptr),
		.fifo_we(fifo_we),
		.clk(clk),
		.rstn(rstn),
		.i_we(i_we),
		.fifo_full(fifo_full)
	);
	
	// 4. Status Signals Module
	status_signal #(ADDR_WIDTH) mod_status 
	(
		.fifo_full(fifo_full),
		.fifo_empty(fifo_empty),
		.wptr(wptr),
		.rptr(rptr)
	);
	
endmodule