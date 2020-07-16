/////////////////////////////////////////////////////////////////////////////////////////////////
// This contain the testbench for the FIFO RTL Design.
// From the waveform we will look at the following things:
//	1. Check wheather the "RESET" condition works properly.
//	2. Write all the memory locations with the random value till FIFO set "FULL" signal.
//	3. Once the FULL set then sequencely read the location using the read pointer 
//	   thus check wheather the FIFO functionality implmented successfully or not.
//	4. Check the simulatenous "READ & WRITE" operation by the FIFO.
//		To do so randomly assign the "WRITE ENABLE" and "READ ENABLE".
////////////////////////////////////////////////////////////////////////////////////////////////

module test_fifo;
	
	// Parameter Defining:
	parameter DATA_WIDTH = 8;
	parameter ADDR_WIDTH = 3;
	parameter FIFO_DEPTH = (1 << ADDR_WIDTH);
	
	// Port Defining:
	// 1. Input of DUT
	reg  clk,rstn,i_we,i_rd;
	reg  [DATA_WIDTH-1 : 0] i_data;
	
	// 2. Output of DUT
	wire [DATA_WIDTH-1 : 0] o_data;
	wire fifo_empty,fifo_full;
	
	//Definig the event triggered when simulation done:
	event done_sim,full_done,empty_done;
	
	// Instantiate the DUT:
	fifo_top #(.DATA_WIDTH(DATA_WIDTH),.ADDR_WIDTH(ADDR_WIDTH),.FIFO_DEPTH(FIFO_DEPTH)) uut
	(
		.o_data(o_data),
		.fifo_full(fifo_full),
		.fifo_empty(fifo_empty),
		.clk(clk),
		.rstn(rstn),
		.i_we(i_we),
		.i_rd(i_rd),
		.i_data(i_data)
	);
	
	// Clock Design Block:
	initial
	begin
		clk <= 0;
		forever #5 clk <= ~(clk);
	end
	
	// Initial all the reg value tho the default:
	initial 
	begin
		rstn 	<= 0;
		i_we 	<= 0;
		i_rd 	<= 0;
		i_data	<= 0;
		
		// 1. RESET Check.
		$display("------------[%t] RESET CHECK-----------------",$time);
		@(negedge clk);
		rstn 	<= 1;
		#4;
		rstn 	<= 0;
		@(negedge clk);
		$display("------------[%t] RESET CHECK END-----------------",$time);
		
		// 2. Performing only write operation:
		$display("------------[%t] WRITE CHECK-----------------",$time);
		i_we	<= 1;
		repeat(10)
		begin
			i_data	<= $random;
			if(fifo_full)
			begin
				$display("FIFO is Full");
				->full_done;
			end
			@(negedge clk);
		end
		
		@(full_done);
		i_we	<= 0;
		$display("------------[%t] WRITE CHECK END-----------------",$time);
		
		// 3. Performing the Read from the FIFO:
		$display("------------[%t] READ CHECK-----------------",$time);
		@(negedge clk);
		i_rd	<= 1;
		if(fifo_empty)
		begin
			$display("FIFO is EMPTY");
			->empty_done;
		end
		@(empty_done);
		i_rd	<= 0;
		$display("------------[%t] READ CHECK END-----------------",$time);
		
		// 4. Simulatenous READ & WRITE
		@(negedge clk);
		$display("------------[%t] SIMUL CHECK-----------------",$time);
		repeat(20)
		begin
			rstn 	<= $random;
			i_we 	<= $random;
			i_rd 	<= $random;
			i_data 	<= $random;
			
			if(rstn)
			begin
				$display("Reset HIGH");
				$display(" Check other signals : fifo_empty = %b, fifo_full = %b, o_data = %h, uut.wptr = %h, uut.rptr = %h",fifo_empty,fifo_full,o_data,uut.wptr,uut.rptr);
			end
			
			else
			begin
				if(i_we)
				begin
					$display("Write operation HIGH");
					$display(" DATA Input = %h -> MEM[%h]",i_data,uut.wptr);
				end
				if(i_rd)
				begin
					$display("READ operation HIGH");
					$display(" DATA out = %h <- MEM[%h]",o_data,uut.rptr);
				end
			end
			@(negedge clk);
		end
		
		@(posedge clk);
		$display("------------[%t] SIMUL CHECK END-----------------",$time);
		->done_sim;
	end
	
	// Initial block to finish the simulation:
	initial
	begin
		@(done_sim);
		$finish;
	end
	
endmodule