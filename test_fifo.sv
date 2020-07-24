// Combine all in one:

////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Defining the macro SV_RAND_CHECK to check wheather the randomization done or failed:
// We used this macro when we want to randomize the "transcation" object in the generator class.
////////////////////////////////////////////////////////////////////////////////////////////////////////////////
`define SV_RAND_CHECK(r) \
	do begin \
      if(!r) begin \
        $display("%0s:%0d: Randomization failed \"%s\"",\
                 `__FILE__,`__LINE__,`"r`");\
        $finish; \
      end \
    end while(0)

	
//////////////////////////////////////////////////////////////////////////////////////
// This file contain the Interface for the FIFO Verification:
// In the Interface there will be two modport and two clocking block for:
//		1. Driver Class
//		2. Monitor Class
/////////////////////////////////////////////////////////////////////////////////////

interface fifo_if( input bit clk );

	// Defining the port list for the FIFO DUT:
	logic [7 : 0] i_data;
	logic [7 : 0] o_data;
	logic i_we,i_rd;
	logic fifo_full,fifo_empty;
	logic rstn;
	endinterface

/////////////////////////////////////////////////////////////////////////////////////////////////
// This file consist of the "Transcation class" for FIFO Verificatio.
// We set the variable which are input to the DUT by the random value using "rand" declaration.
// This class also content copy function so that the object copy can be done at anytime.
/////////////////////////////////////////////////////////////////////////////////////////////////

class transcation;

	// Variable to be randmoize:
	rand bit  rstn;
	rand bit  i_we,i_rd;
	rand bit  [7:0] i_data;
	
	// Normal variable:
	bit [7:0] o_data;
	bit		  fifo_full;
	bit		  fifo_empty;
	
	// Set the constraint for randomize such that their will be either write or read:
	constraint we_or_rd { i_rd != i_we; }
	
	
	// Only copy the inputs so that same input can applied to the "reference DUT" and output can check:
	function void copy(transcation temp);
		this.rstn 	= temp.rstn;
		this.i_we 	= temp.i_we;
		this.i_rd 	= temp.i_rd;
		this.i_data = temp.i_data;
	endfunction
endclass

///////////////////////////////////////////////////////////////////////////////////////////////////
// This file consist of the generator class for the FIFO verification:
// This class use to generate the randmoize set of value of transcation object.
// Using the mailbocx the generated value are passed to the driver class.
// Once a set of values transfer to the driver the generator wait for driver class to driver the 
// set of values using a event.
///////////////////////////////////////////////////////////////////////////////////////////////////

class generator;

	// Creating the transcation handle to handle the objects:
	transcation trans;
	// Mailbox to communicated with the driver class.
	mailbox mb_gen;
	// event shared between the driver class.
	event drv_done;
	
	// new constructor:
	function new(mailbox mb_gen , event drv_done);
		this.mb_gen 	= mb_gen;
		this.drv_done 	= drv_done;
	endfunction
	
	// Task to generate the randomize values uding transcation object:
	task run();
		$display("---------------------[%0t] GENERATOR STARTS --------------------",$time);
		repeat(10)
		begin
			trans = new();
			`SV_RAND_CHECK(trans.randomize());
			mb_gen.put(trans);
			$display("Waiting for Driver to done");
			@(drv_done);
		end
	endtask
		
endclass 

/////////////////////////////////////////////////////////////////////////////////////////////////
// This file consist of the driver class for FIFO verification.
// Driver class used to get signals send by the Generator class through the mailbox.
// This signals are then used to drives the inputs of DUT through virtual interface.
// Virtual Interface: It is merely a handle or pointer to a physical interface.
////////////////////////////////////////////////////////////////////////////////////////////////

class driver;
	
	// Creating the transcation handle to handle the objects:
	transcation trans;
	// Mailbox to communicated with the generator class.
	mailbox mb_drv;
	// event shared between the Generator class.
	event drv_done;
	// Creating virtual interface handle:
	virtual fifo_if inth;

	// new constructor:
	function new(virtual fifo_if inth, mailbox mb_drv, event drv_done);
		this.inth 		= inth;
		this.mb_drv 	= mb_drv;
		this.drv_done 	= drv_done;
	endfunction
	
	// Following defines tasks to drive the signals through interface:
	// 1. Task to achieve the reset condition:
	task RESET();
		$display(" DRIVER : Entered the RESET MODE ");
		inth.rstn	<= 0;
		@(negedge inth.clk);
		inth.rstn 	<= 1;
		
		repeat(2) @(posedge inth.clk);
		inth.rstn	<= 0;
		$display(" DRIVER : Leaving the RESET MODE ");
	endtask
	
	// 2. Drive the remaining signals through interface:
	task run();
		$display("----------------------[%0t] DRIVER STARTS -------------------",$time);
		forever
		begin
			trans = new();
			mb_drv.get(trans); 	
			@(posedge inth.clk);
			inth.i_we	<= trans.i_we;
			inth.i_rd	<= trans.i_rd;
			inth.i_data	<= trans.i_data;
			->drv_done;
		end
	endtask
	
endclass

//////////////////////////////////////////////////////////////////////////////////////////////
// This file consist of the Monitor class for FIFO verification.
// Monitor class will get the signal values from the DUT through the Interface.
// Monitor then put those set of values into mailbox to transferit to the scoreboard.
//////////////////////////////////////////////////////////////////////////////////////////////

class monitor;

	// Creating the transcation handle to handle the objects:
	transcation trans;
	// Mailbox to communicated with the scoreboard class.
	mailbox mb_mon;
	// Creating virtual interface handle:
	virtual fifo_if inth;
	
	// new constructor:
	function new(virtual fifo_if inth,mailbox mb_mon);
		this.inth 	= inth;
		this.mb_mon = mb_mon;
	endfunction
	
	// Task to get the set of values from the interface and send through mailbox:
	task run();
		$display("----------------[%0t] MONITOR STARTS ---------------",$time);
		forever
		begin
			trans = new();
			@(posedge inth.clk);
			trans.i_data	<= inth.i_data;
			trans.rstn		<= inth.rstn;
			trans.i_we		<= inth.i_we;
			trans.i_rd		<= inth.i_rd;
			trans.o_data	<= inth.o_data;
			trans.fifo_full	<= inth.fifo_full;
			trans.fifo_empty <= inth.fifo_empty;
			mb_mon.put(trans);
		end
	endtask
endclass

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This file is consist of the scoreboard class for the FIFO verification.
// Scoreboard will get the set of values from the mailbox sent by the monitor class.
// Scoreboard also includes the reference DUT type codes.
// We compare the set of output values received through mailbox by the monitor with output of ref. DUT
// We will build the refernce DUT using the SystemVerilogs datasets i.e. queues structure.
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class scoreboard;

	// Creating the transcation handle to handle the object:
	transcation trans;
	// Creating the transcation handle to handle the object:
	transcation ref_trans;
	// Mailbox to communicated with the monitor class.
	mailbox mb_scr;
	
	// Defining the queue structure which will acts as refernce DUT:
	bit [7:0] ref_queue [$:8];
	
	// new constructor:
	function new(mailbox mb_scr);
		this.mb_scr = mb_scr;
	endfunction
	
	// Task to get the values from monitor and compare the output values with ref. DUT output:
	task run();
		$display("----------------[%0t] SCOREBOARD STARTS ---------------",$time);
		forever
		begin
			trans 		= new();		// Creating the object "trans".
			ref_trans 	= new();		// Creating the object "ref_trans".
			mb_scr.get(trans);
			ref_trans.copy(trans);		// Deep copy of trans object into ref_trans object.
			
			// Creating reference DUT type module using queue and its property:
			if(ref_trans.rstn)
			begin
				ref_trans.o_data	<= 0;
			end
			
			else
			begin
				if(ref_trans.i_we)
				begin
					ref_queue.push_front(ref_trans.i_data);
				end
				
				if(ref_trans.i_rd)
				begin
					ref_trans.o_data <= ref_queue.pop_front();
				end
			end
			
			// This if block for setting the fifo_full signal
			if(ref_queue.size() == 8)
				ref_trans.fifo_full <= 1;
			else
				ref_trans.fifo_full <= 0;
			
			// This if block is for setting the fifo_empty signal:
			if(ref_queue.size() == 0)
				ref_trans.fifo_empty <= 1;
			else
				ref_trans.fifo_empty <= 0;
			
			// Printing all the input variable to compare:
			$display("Input Data : i_data = %h ref_i_data = %h",trans.i_data,ref_trans.i_data);
			$display("Write Enable : i_we = %b ref_i_we = %b",trans.i_we,ref_trans.i_we);
			$display("Read Enable : i_rd = %b ref_i_rd = %b",trans.i_rd,ref_trans.i_rd);
			
			// Comparing the Output by DUT and REF_DUT:
			// 1. Output Data:
			$display("Output Data : o_data = %h ref_o_data = %h",trans.o_data,ref_trans.o_data);
			if(trans.o_data == ref_trans.o_data)
				$display("Output Data Test PASSED");
			else
				$display("Output Data Test FAILED");
			
			// 2. FIFO_FULL signal:
			$display("FIFO_FULL : fifo_full = %b ref_fifo_full = %b",trans.fifo_full,ref_trans.fifo_full); 
			if(trans.fifo_full == ref_trans.fifo_full)
				$display("OUTPUT FULL Test PASSED");
			else
				$display("OUTPUT FULL Test FAILED");
			
			// 3. FIFO_EMPTY signal:
			$display("FIFO_EMPTY : fifo_empty = %b ref_fifo_empty = %b",trans.fifo_empty,ref_trans.fifo_empty); 
			if(trans.fifo_empty == ref_trans.fifo_empty)
				$display("OUTPUT EMPTY Test PASSED");
			else
				$display("OUTPUT EMPTY Test FAILED");
				
			// 4. IF all above true then FIFO Test is PASSED
			if(trans.fifo_full == ref_trans.fifo_full && trans.fifo_empty == ref_trans.fifo_empty && trans.o_data == ref_trans.o_data)
				$display("FIFO Test PASSED");
			else
				$display("FIFO Test FAILED");
		end
	endtask
endclass

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This file consist of the Environment class for the FIFO verification.
// In the Environment class we create the instance of all pervious classes 
// i.e. Generator class, Driver class, Monitor class and Scoreboard class
// In this we join respective classes with the mailbox and also invokes all the task run of this classes.
//////////////////////////////////////////////////////////////////////////////////////////////////////////////////

class environment;

	// Creating handle of all pervious classes:
	generator gen;
	driver drv;
	monitor mon;
	scoreboard scr;
	
	// Creating handle of two mailbox for communication:
	mailbox mb_gen_drv;
	mailbox mb_mon_scr;
	
	// Creating virtual interface handle:
	virtual fifo_if inth;
	
	// Event shared between Generator and Driver class:
	event drv_done;
	
	// new Constructor:
	function new(virtual fifo_if inth);
		this.inth = inth;
		mb_gen_drv = new();
		mb_mon_scr = new();
		gen = new(mb_gen_drv,drv_done);
		drv = new(inth,mb_gen_drv,drv_done);
		mon = new(inth,mb_mon_scr);
		scr = new(mb_mon_scr);
	endfunction
	
	// Call all the run task from the pervious defined classes in the task called main:
	task run();
		$display("--------------------[%0t] Environment STARTS ----------------------------",$time);
		fork
			gen.run();
			drv.run();
			mon.run();
			scr.run();
		join
	endtask
endclass

///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// This file consists of the Program test for the FIFO verification:
// In the System Verilog the test is written in the program block:
// There is no need for the "$finish" statement so the simulation terminated when the 
// program block finish the execution.
///////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

program test(fifo_if inth);
	environment env;
	
	initial
	begin
		env = new(inth);
		env.run();
	end
endprogram

// FIFO DUT Here:

// Top Module BLock:
module top;

	// Declare the bit for clk generation:
	bit clk;
	
	// Parameter to define the DATA WIDTH, ADDRESS WIDTH and FIFO DEPTH:
	parameter DATA_WIDTH = 8;
	parameter ADDR_WIDTH = 3;
	parameter FIFO_DEPTH = (1 << (ADDR_WIDTH-1));
	
	initial 
	begin
		clk = 0;
		forever #5 clk = ~clk;
	end
	
	fifo_if inth (.clk(clk));
	test fifo_test(inth);
	
	fifo_top #(.DATA_WIDTH(DATA_WIDTH),.ADDR_WIDTH(ADDR_WIDTH),.FIFO_DEPTH(FIFO_DEPTH)) uut
	(
		.o_data(inth.o_data),
		.fifo_full(inth.fifo_full),
		.fifo_empty(inth.fifo_empty),
		.clk(inth.clk),
		.rstn(inth.rstn),
		.i_we(inth.i_we),
		.i_rd(inth.i_rd),
		.i_data(inth.i_data)
	);
	
endmodule
