`timescale 1ns/1ps

// Focused RTL regressions; these do not validate physical board behavior.
module regression_testbench;
    bit passed = 0;
    wire snake_done, apple_done, input_done, lfsr_done, integration_done;
    snake_regression s(snake_done);
    apple_regression a(apple_done);
    input_regression u(input_done);
    lfsr_regression l(lfsr_done);
    integration_regression i(integration_done);
    initial begin
        wait (snake_done && apple_done && input_done && lfsr_done && integration_done);
        passed = 1;
        $display("PASS: all focused RTL regressions completed");
    end
    initial begin #20000; if (!passed) $fatal(1, "Regression timed out"); end
endmodule

module integration_regression(output bit done);
    bit CLOCK_50 = 0;
    always #5 CLOCK_50 = ~CLOCK_50;
    logic [35:0] GPIO_1;
    logic [6:0] HEX0, HEX1, HEX2, HEX3, HEX4, HEX5;
    logic [9:0] LEDR, SW;
    logic [3:0] KEY;
    DE1_SoC #(.whichClock2(3)) dut(.*);
    task automatic press_keys(input logic [3:0] keys);
        @(negedge CLOCK_50); KEY = keys;
        repeat (5) @(negedge CLOCK_50);
        KEY = 4'b1111;
        repeat (5) @(negedge CLOCK_50);
    endtask
    initial begin
        done = 0; KEY = 4'b1111; SW = 10'b1000000000;
        repeat (3) @(negedge CLOCK_50);
        if (dut.pmov !== 2'b00 || LEDR[0] !== 0)
            $fatal(1, "integration: simulation reset initializes direction/game flag");
        SW = 0;
        press_keys(4'b1101); // opposite (left) while moving right
        if (dut.pmov !== 2'b00) $fatal(1, "integration: direct reversal rejected");
        press_keys(4'b1011); // down
        if (dut.pmov !== 2'b11) $fatal(1, "integration: perpendicular turn accepted");
        press_keys(4'b1010); // right and down: right has priority
        if (dut.pmov !== 2'b00) $fatal(1, "integration: simultaneous input priority");
        if (HEX0 !== 7'b1111111 || HEX5 !== 7'b1111111)
            $fatal(1, "integration: unused seven-segment displays blanked");
        $display("PASS: simulation top-level reset, direction filtering, input priority");
        done = 1;
    end
endmodule

module snake_regression(output bit done);
    bit clk = 0;
    always #5 clk = ~clk;
    logic GT, reset, ateApple, gameOver;
    logic [1:0] mov;
    logic [15:0][15:0] SnPos, AplPos, expected;
    snake dut(.*);
    task automatic check(input bit condition, input string description);
        if (!condition) $fatal(1, "snake: %s", description);
    endtask
    task automatic reset_game;
        @(negedge clk); reset = 1; GT = 0; mov = 0; AplPos = '0;
        repeat (2) @(posedge clk);
        #1; expected = '0; expected[0][0] = 1;
        check(SnPos === expected && gameOver === 0 && ateApple === 0,
              "reset initializes one live cell and clears flags");
        check(dut.length === 9'd1, "reset initializes length");
        @(negedge clk); reset = 0;
    endtask
    task automatic move_once(input logic [1:0] direction);
        @(negedge clk); mov = direction; GT = 1;
        @(posedge clk); #1; GT = 0;
    endtask
    initial begin
        done = 0; reset_game();
        repeat (3) @(posedge clk);
        #1; check(SnPos === expected, "no game tick leaves the snake stationary");
        move_once(2'b00);
        expected = '0; expected[0][1] = 1;
        check(SnPos === expected && dut.length === 9'd1,
              "ordinary movement vacates the old tail");
        AplPos = '0; AplPos[0][2] = 1;
        move_once(2'b00);
        check(ateApple === 1 && dut.length === 9'd2, "eating grows once");
        expected[0][2] = 1;
        check(SnPos === expected, "growth retains the tail");
        @(posedge clk); #1;
        check(ateApple === 0 && dut.length === 9'd2, "ateApple is a one-clock pulse");
        AplPos = '0; AplPos[1][2] = 1; move_once(2'b11);
        AplPos = '0; AplPos[1][1] = 1; move_once(2'b01);
        expected[1][2] = 1; expected[1][1] = 1;
        check(SnPos === expected && dut.length === 9'd4, "turning growth builds body");
        AplPos = '0; move_once(2'b10); // enter the departing tail at (1,0)
        check(gameOver === 0, "entering the departing tail cell is legal");
        check(SnPos === expected && dut.length === 9'd4,
              "departing-tail move preserves the new head occupancy");
        check(dut.headX === 4'd1 && dut.headY === 4'd0 &&
              dut.tailX === 4'd2 && dut.tailY === 4'd0, "body coordinates advance");
        move_once(2'b11); // occupied non-tail cell (1,1)
        check(gameOver === 1 && SnPos === expected, "non-tail self collision");
        move_once(2'b00);
        check(SnPos === expected, "game over freezes movement");
        reset_game(); move_once(2'b01);
        check(gameOver === 1, "left wall collision");
        reset_game(); move_once(2'b10);
        check(gameOver === 1, "top wall collision");
        reset_game(); repeat (15) move_once(2'b00);
        check(gameOver === 0 && dut.headX === 4'd15, "right edge is in bounds");
        move_once(2'b00); check(gameOver === 1, "right wall collision");
        reset_game(); repeat (15) move_once(2'b11);
        check(gameOver === 0 && dut.headY === 4'd15, "bottom edge is in bounds");
        move_once(2'b11); check(gameOver === 1, "bottom wall collision");
        $display("PASS: snake movement, growth, tail reuse, collisions, reset");
        done = 1;
    end
endmodule

module apple_regression(output bit done);
    bit clk = 0;
    always #5 clk = ~clk;
    logic update, reset;
    logic [7:0] randNum;
    logic [15:0][15:0] SnPos, AplPos, expected;
    apple dut(.*);
    task automatic check(input bit condition, input string description);
        if (!condition) $fatal(1, "apple: %s", description);
    endtask
    initial begin
        done = 0; reset = 1; update = 0; randNum = 0; SnPos = '0;
        repeat (2) @(posedge clk);
        #1; expected = '0; expected[15][15] = 1;
        check(AplPos === expected, "reset gives known one-hot location");
        @(negedge clk); reset = 0; SnPos[2][3] = 1; randNum = 8'h23; update = 1;
        @(posedge clk); #1;
        @(negedge clk); update = 0;
        repeat (2) @(posedge clk);
        #1; check(AplPos === expected, "occupied candidates are rejected");
        @(negedge clk); randNum = 8'h45;
        @(posedge clk); #1; expected = '0; expected[4][5] = 1;
        check(AplPos === expected, "first free candidate is selected");
        @(negedge clk); update = 1; randNum = 8'h67;
        repeat (2) @(posedge clk);
        #1; expected = '0; expected[6][7] = 1;
        check(AplPos === expected, "rising edge starts new placement");
        @(negedge clk); randNum = 8'h89;
        repeat (3) @(posedge clk);
        #1; check(AplPos === expected, "held update does not repeatedly respawn");
        @(negedge clk); reset = 1;
        @(posedge clk); #1; expected = '0; expected[15][15] = 1;
        check(AplPos === expected, "reset restarts placement state");
        $display("PASS: apple reset, occupied rejection, placement, update edge");
        done = 1;
    end
endmodule

module input_regression(output bit done);
    bit Clock = 0;
    always #5 Clock = ~Clock;
    logic Reset, In, Out;
    integer pulses;
    userInput dut(.*);
    always @(posedge Clock) begin #1; if (!Reset && Out) pulses = pulses + 1; end
    initial begin
        done = 0; Reset = 1; In = 0; pulses = 0;
        repeat (2) @(negedge Clock);
        Reset = 0; In = 1;
        repeat (8) @(negedge Clock);
        if (pulses != 1) $fatal(1, "input: held input must produce one pulse");
        In = 0; repeat (5) @(negedge Clock);
        In = 1; repeat (6) @(negedge Clock);
        if (pulses != 2) $fatal(1, "input: second rising edge must produce another pulse");
        $display("PASS: synchronized input edge pulses (not bounce filtering)");
        done = 1;
    end
endmodule

module lfsr_regression(output bit done);
    bit clk = 0;
    always #5 clk = ~clk;
    logic reset;
    logic [7:0] out;
    bit [255:0] seen;
    LFSR dut(.*);
    initial begin
        done = 0; reset = 1; seen = '0;
        repeat (2) @(posedge clk);
        #1; if (out !== 8'h00) $fatal(1, "LFSR: reset state");
        @(negedge clk); reset = 0;
        // XNOR feedback excludes the all-ones state from its 255-state cycle.
        repeat (255) begin
            @(posedge clk); #1;
            if ((^out) === 1'bx || out === 8'hff || seen[out])
                $fatal(1, "LFSR: unknown, excluded, or repeated state");
            seen[out] = 1;
        end
        if (out !== 8'h00) $fatal(1, "LFSR: period must return to reset state");
        $display("PASS: LFSR reset and 255-state period");
        done = 1;
    end
endmodule
