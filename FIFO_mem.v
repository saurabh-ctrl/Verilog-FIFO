//FIFO example:

module memory_array (data_out,data_in,clk,fifo_we,fifo_rd,wptr,rptr);
	input [7 : 0] data_in;
	input clk,fifo_we,fifo_rd;
	input [3 : 0] wptr,rptr;
	output [7 : 0] data_out;
	
	reg [7 : 0] fifo_mem [0 : 7];
	reg [7 : 0] data_out_reg;
	
	always@(posedge clk)
	begin
		if(fifo_we)
			fifo_mem[wptr[2:0]] <= data_in;
		else if(fifo_rd)
			data_out_reg <= fifo_mem[rptr[2:0]];
		else
			data_out_reg <= 0;
	end
	
	assign data_out = data_out_reg;
endmodule

//Read_pointer: 
module read_pointer (rptr,fifo_rd,fifo_empty,rd,clk,rst);
	input fifo_empty,rd,clk,rst;
	output reg [3 : 0] rptr;
	output fifo_rd;
	
	assign fifo_rd = (!fifo_empty) && rd;
	
	always@(posedge clk or posedge rst)
	begin
		if(rst)
			rptr <= 0;
		else if(fifo_rd)
			rptr <= (rptr +1);
		else 
			rptr <= rptr;
	end
endmodule

//write Poiinter:
module write_pointer  (wptr,fifo_we,wr,fifo_full,clk,rst);
	input clk,rst,wr,fifo_full;
	output fifo_we;
	output reg [3 : 0] wptr;
	
	assign fifo_we = (!fifo_full) & wr;
	
	always@(posedge clk or posedge rst)
	begin	
		if(rst)
			wptr <= 0;
		else if(fifo_we)
			wptr <= (wptr + 1);
		else
			wptr <= wptr;
	end
endmodule

//Status Counter:
module status_signal (fifo_full,fifo_empty,wptr,rptr);
	input [2: 0] wptr,rptr;
	output reg fifo_full,fifo_empty;
	
	wire fbit_comp;
	wire pointer_equal;

	assign fbit_comp = wptr[3] ^rptr[3];
	assign pointer_equal = (wptr[2 : 0] - rptr[2 : 0]) ? 1'b0: 1'b1;
		
	always@(*)
	begin
		fifo_full <= fbit_comp & pointer_equal;
		fifo_empty <= (~fbit_comp) & pointer_equal;
	end
endmodule

//TOP Module:
module fifo_top (data_out,fifo_full,fifo_empty,clk,rst,wr,rd,data_in);

	//Port define:
	input [7 : 0] data_in;
	input clk,rst,wr,rd;
	output [7 : 0] data_out;
	output fifo_empty,fifo_full;
	
	//Internal variables:
	wire [3 :0] wptr,rptr;
	wire fifo_we,fifo_rd;
	
	write_pointer  top1(wptr,fifo_we,wr,fifo_full,clk,rst);
	read_pointer  top2(rptr,fifo_rd,fifo_empty,rd,clk,rst);
	memory_array  top3(data_out,data_in,clk,fifo_we,fifo_rd,wptr,rptr);
	status_signal top4 (fifo_full,fifo_empty,wptr,rptr);
	
endmodule
