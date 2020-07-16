# Verilog-FIFO
   This is the FIFO (First in First out) Verilog code:
   The design is build using of Dual Port SRAM.
   Consider this as hardware implementation of Circular FIFO with Two Pointer.
   Two pointers can named as "write pointer(wptr)" and "read pointer(rptr)".
   Using the pointer of n-bit wider we able to trace Memory Depth upto "2n".
   This is because the MSB of the pointer is used only to set the "FULL" and "EMPTY" output.
   The code will divide into the 5 modules as follows:
		  1. Module for "Memory Block (Dual Port SRAM)". [Saved as myFIFO_MB.v]
		  2. Module for updating the "Read Pointer (rptr)". [Saved as myFIFO_RP.v]
		  3. Module for updating the "Write Pointer (wptr)".  [Saved as myFIFO_WP.v]
		  4. Module for updating the Status Signals like "FULL" and "EMPTY" output. [Saved as myFIFO_SS.v]
		  5. TOP Module in which all above modules are connected together.  [Saved as myFIFO.v]

   Also the simulation result check following things: [Saved as myFIFO_test.v]
    1. Check wheather the "RESET" condition works properly.
	  2. Write all the memory locations with the random value till FIFO set "FULL" signal.
	  3. Once the FULL set then sequencely read the location using the read pointer 
	     thus check wheather the FIFO functionality implmented successfully or not.
	  4. Check the simulatenous "READ & WRITE" operation by the FIFO.
		  To do so randomly assign the "WRITE ENABLE" and "READ ENABLE".

  Also their is separate testbench created to check the FIFO "FULL" and "EMPTY" output status signals:
    [Saved as Full_Empty_test.v]
