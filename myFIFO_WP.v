////////////////////////////////////////////////////////////////////////////////////////////////////
// This Verilog code implement module to update the "Write Pointer(wptr)" for the FIFO.
// The Corresponding "Write Pointer" will increament when we received the HIGH of Input
// "we" signal providing the condition that FIFO should not be FULL i.e (FULL = LOW).
// So, the signal for this modules will be:
// 	Inputs:	
//			1. FIFO FULL signal,
//			2. Clock and Reset,
//			3. FIFO Read Enable signal (we) from the top module.
//	Output:
//			1. FIFO Write Pointer(wptr)
//			2. FIFO Write Enable to the Memory Block (It will work as enable signal to Memory).
///////////////////////////////////////////////////////////////////////////////////////////////////

module write_pointer #(parameter ADDR_WIDTH = 3)
	(wptr,fifo_we,clk,rstn,i_we,fifo_full);
	
	// Declaration of Ports:
	input 	clk;
	input 	rstn,i_we,fifo_full;
	output 	fifo_we;
	output reg [ADDR_WIDTH : 0] wptr;
	
	// Assigning the fifo_we:
	assign fifo_we = (!fifo_full) & i_we;
	
	// Purpose : To modify the write Pointer:
	always@(posedge clk or posedge rstn)
	begin
		if(rstn)
		begin
			wptr <= 0;
		end
		
		else if(fifo_we)
			wptr <= wptr + 1;
		else
			wptr <= wptr;
	end
	
endmodule
	
	

