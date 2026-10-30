// Two-flop input synchronizer followed by rising-edge pulse detection.
// A held input produces one pulse; this does not filter mechanical switch bounce.
// input
//		Clock - clock to sync the input to
//		reset - resets the input to all 0s
// 	In - user input
// output
//		out - 1 clock cycle true per time user input is true
module userInput (Clock, Reset, In, Out);
	input logic Clock, In, Reset;
	
	output logic Out;
	
	logic f1, f2, ps;
	
	always_ff @(posedge Clock) begin
		if (Reset) begin
			f1 <= 0;
			f2 <= 0;
			ps <= 0;
			Out <= 0;
		end else begin
			f1 <= In;
			f2 <= f1;
			ps <= f2;
			Out <= f2 && ~ps;
		end
	end

endmodule

// Test bench for the user input module
module userInput_testbench;
	
	logic Clock, Reset, In, Out;
	
	userInput dut (.Clock, .Reset, .In, .Out);
	
	parameter CLOCK_PERIOD=100;
		initial begin
			Clock <= 0;
			forever #(CLOCK_PERIOD/2) Clock <= ~Clock;	// Forever toggle the clock
		end	
	
	initial begin
	
	In = 0;
	
	Reset <= 1;	@(posedge Clock);
		@(posedge Clock);
		
	Reset <= 0; @(posedge Clock);
	
	#3  In = 1; # 573
	#11 In = 0; #603
	#4  In = 1; #560
	#9  In = 0; #432
	
	$stop;
	end

endmodule
