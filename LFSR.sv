// LFSR module for a 8-bit random number generation
// input
//		clk - clock for the generator
//		reset - resets the LFSR to all 0s
// output
//		out - 10-bit output that changes per clk cycle
module LFSR (clk, reset, out);
	input logic clk, reset; 
	output logic [7:0] out;
	
	logic in, o1, o2, o3, o4, o5, o6, o7, o8; 
	
	always_comb begin
		in = ~(o8 ^ o6 ^ o5 ^ o4);
		out = {o1, o2, o3, o4, o5, o6, o7, o8};
	end
	
	always_ff @(posedge clk) begin
		if (reset) begin
			o1 <= 0;
			o2 <= 0; 
			o3 <= 0;
			o4 <= 0;
			o5 <= 0; 
			o6 <= 0;
			o7 <= 0;
			o8 <= 0;
		end else begin
			o1 <= in;
			o2 <= o1;
			o3 <= o2; 
			o4 <= o3; 
			o5 <= o4;
			o6 <= o5; 
			o7 <= o6;
			o8 <= o7;
		end
	end
	
endmodule

// testbench for the above LFSR module
module LFSR_testbench ();
	logic clk, reset;
	logic [9:0] out;
	
	LFSR dut (.clk, .reset, .out);
	
	parameter CLOCK_PERIOD=100;
		initial begin
			clk <= 0;
			forever #(CLOCK_PERIOD/2) clk <= ~clk;	// Forever toggle the clock
		end	
		
	initial begin 
	
		reset <= 1; @(posedge clk);
						@(posedge clk);
						@(posedge clk);
		reset <= 0; @(posedge clk);
		
		for(int i = 0; i < 1024; i++) begin
			@(posedge clk);
		end
		
		reset <= 1; @(posedge clk);
						@(posedge clk);
		$stop;
	end
	
endmodule
	
		