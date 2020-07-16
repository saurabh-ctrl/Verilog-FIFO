////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This Verilog code implement module for updating the Status Signals like "FULL" and "EMPTY" output.
// Consider this as hardware implementation of Circular FIFO with Two Pointer.
// Using the pointer of n-bit wider we able to trace Memory Depth upto "2n".
// This is because the MSB of the pointer is used only to set the "FULL" and "EMPTY" output.
// Following are the conditions to set this signals:
//	1. EMPTY Condition:
//		When the Read Pointer reach the Write Pointer we set the "EMPTY" condition.
//	2. FULL Condition:
//		When the Write Pointer reaches the Readd Ponter we set the "FULL" condition. ( Complete rotation of Memory)
////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

module status_signal #(parameter ADDR_WIDTH = 3)
	(fifo_full,fifo_empty,wptr,rptr);
	
	// Declaration of Ports
	input [ADDR_WIDTH : 0] 	wptr,rptr;
	output reg 				fifo_full,fifo_empty;
	
	wire fbit_comp;		// This mainly checks the condition. XOR of the MSB of wptr and rptr.
	wire pointer_equal;

	assign fbit_comp = wptr[ADDR_WIDTH] ^ rptr[ADDR_WIDTH];
	assign pointer_equal = (wptr[ADDR_WIDTH-1 : 0] - rptr[ADDR_WIDTH-1 : 0]) ? 1'b0: 1'b1;
		
	always@(*)
	begin
		fifo_full 	<= fbit_comp & pointer_equal;
		fifo_empty 	<= (~fbit_comp) & pointer_equal;
	end
endmodule