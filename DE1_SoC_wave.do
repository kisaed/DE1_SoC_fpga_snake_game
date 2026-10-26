onerror {resume}
quietly WaveActivateNextPane {} 0
add wave -noupdate {/DE1_SoC_testbench/KEY[3]}
add wave -noupdate {/DE1_SoC_testbench/KEY[2]}
add wave -noupdate {/DE1_SoC_testbench/KEY[1]}
add wave -noupdate {/DE1_SoC_testbench/KEY[0]}
add wave -noupdate {/DE1_SoC_testbench/SW[9]}
add wave -noupdate /DE1_SoC_testbench/dut/disp/RedPixels
add wave -noupdate /DE1_SoC_testbench/dut/disp/GrnPixels
add wave -noupdate /DE1_SoC_testbench/dut/snk/SnPos
add wave -noupdate /DE1_SoC_testbench/dut/snk/clk
add wave -noupdate /DE1_SoC_testbench/dut/snk/mov
add wave -noupdate /DE1_SoC_testbench/dut/snk/AplPos
add wave -noupdate {/DE1_SoC_testbench/dut/snk/AplPos[9]}
add wave -noupdate /DE1_SoC_testbench/dut/snk/grow
add wave -noupdate /DE1_SoC_testbench/dut/snk/tailX
add wave -noupdate /DE1_SoC_testbench/dut/snk/tailY
add wave -noupdate /DE1_SoC_testbench/dut/snk/nextTailX
add wave -noupdate /DE1_SoC_testbench/dut/snk/nextTailY
add wave -noupdate /DE1_SoC_testbench/dut/snk/dir
add wave -noupdate /DE1_SoC_testbench/dut/snk/GT
TreeUpdate [SetDefaultTree]
WaveRestoreCursors {{Cursor 1} {14548 ps} 0}
quietly wave cursor active 1
configure wave -namecolwidth 262
configure wave -valuecolwidth 325
configure wave -justifyvalue left
configure wave -signalnamewidth 1
configure wave -snapdistance 10
configure wave -datasetprefix 0
configure wave -rowmargin 4
configure wave -childrowmargin 2
configure wave -gridoffset 0
configure wave -gridperiod 1
configure wave -griddelta 40
configure wave -timeline 0
configure wave -timelineunits ps
update
WaveRestoreZoom {31956 ps} {43003 ps}
