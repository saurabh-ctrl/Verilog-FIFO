////////////////////////////////////////////////////////////////////////////////////////
// This Verilog code implement module to update the "Read Pointer(rptr)" for the FIFO.
// The Corresponding "Read Pointer" will increament when we received the HIGH of Input
// "rd" signal providing the condition that FIFO should not be Empty i.e (EMPTY = LOW).
// So, the signal for this modules will be:
// 	Inputs:	
//			1. FIFO EMPTY signal,
//			2. Clock and Reset,
//			3. FIFO Read Enable signal (rd) from the top module.
//	Output:
//			1. FIFO Read Pointer(rptr)
////////////////////////////////////////////////////////////////////////////////////////

module read_pointer #(parameter ADDR_WIDTH = 3)
	(rptr,fifo_rd,clk,rstn,i_rd,fifo_empty);
	
	// Declaration of Ports:
	input 	clk;
	input 	rstn,i_rd,fifo_empty;
	output 	fifo_rd;
	output reg [ADDR_WIDTH : 0] rptr;
	
	// Assigning the fifo_rd:
	assign fifo_rd = (!fifo_empty) & i_rd;
	
	// Purpose : To modify the Read Pointer:
	always@(posedge clk or posedge rstn)
	begin
		if(rstn)
		begin
			rptr <= 0;
		end
		
		else if(fifo_rd)
			rptr <= rptr + 1;
		else
			rptr <= rptr;
	end
	
endmodule
	
	

