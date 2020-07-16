// FIFO only full and empty output test
// Testbench no : 01:

module full_empty_test;
	
	// Input Ports of top module:
	reg [7 : 0] data_in;
	reg clk,rst,wr,rd;
	
	// Output Ports of top module:
	wire [7 : 0] data_out;
	wire fifo_empty,fifo_full;
	
	fifo_top uut 
	(
		.data_out(data_out),
		.fifo_full(fifo_full),
		.fifo_empty(fifo_empty),
		.clk(clk),
		.rst(rst),
		.wr(wr),.rd(rd),
		.data_in(data_in)
	);
	
	initial
	begin
		clk <= 0;
		forever #5 clk <= ~clk;
	end
	
	initial
	begin
		// Reset Condition:
		rstn 	<= 0;
		wr 		<= 0;
		rd		<= 0;
		data_in <= 0;
		
		#5;
		rstn 	<= 1;
		#10;
		wr 		<= 1;
		repeat(10)
		begin
			data_in <= $random;
			$display("[%t] Writing Data %h -> fifo_mem[%h]",$time,data_in,uut.wptr);
			if(fifo_empty)
				$display("FIFO is Empty at address %h",uut.rptr);
			else if(fifo_full)
				$display("FIFO is Full at address %h",uut.wptr);
			else
				$display("FIFO neither full nor empty wptr = %h rptr = %h",uut.wptr,uut.rptr);
			@(negedge clk);
		end
		
		
		@(posedge clk);
		$finish;
		
	end
endmodule