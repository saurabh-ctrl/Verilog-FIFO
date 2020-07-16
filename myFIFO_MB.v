////////////////////////////////////////////////////////////////////////////////////////
// This Verilog code implement the Memory Block (Dual port SRAM) for the FIFO.
////////////////////////////////////////////////////////////////////////////////////////

module memory_block #(parameter DATA_WIDTH = 8, parameter ADDR_WIDTH = 3, parameter FIFO_DEPTH = (1 << ADDR_WIDTH))
	(o_data,i_data,clk,fifo_we,fifo_rd,rstn,wptr,rptr);
	
	// Declaration of Ports:
	input 						clk,fifo_we,fifo_rd,rstn;
	input  [DATA_WIDTH-1 : 0] 	i_data;
	input  [ADDR_WIDTH : 0] 	wptr,rptr;
	output [DATA_WIDTH-1 : 0] 	o_data;
	
	// Internal Variables:
	reg [DATA_WIDTH-1 : 0] 		fifo_mem [0 : FIFO_DEPTH-1];	//Memory Block Define.
	reg [DATA_WIDTH-1 : 0] 		r_data;
	integer i;				// To trace the location of Memory Block during the "Reset Condition".
	
	always@(posedge clk or posedge rstn)
	begin
	
		// When the Positive edge of Reset comes make all the input signal at logic 0 and Data at alla memory be 8'hFF(All at logic 1)
		if(rstn)
		begin
			for(i = 0; i < FIFO_DEPTH; i = i+1)
				fifo_mem[i]	<= 8'hFF;
		end
		
		else
		begin
			if(fifo_we)
				fifo_mem[wptr[ADDR_WIDTH-1 : 0]] <= i_data;
			else if(fifo_rd)
				r_data <= fifo_mem[rptr[ADDR_WIDTH-1 : 0]];
			else
				r_data <= 0;
		end
	end
	
	assign o_data = r_data;
endmodule