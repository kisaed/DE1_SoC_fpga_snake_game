# Run from the repository root with: vsim -c -do src/run_regressions.do
onerror {quit -f -code 1}
onbreak {quit -f -code 1}
if {![file exists ./src/DE1_SoC.sv]} {error "Run from the repository root: vsim -c -do src/run_regressions.do"}
if {![file isdirectory work]} {vlib work}
vlog -sv ./src/*.sv ./src/tests/regression_testbench.sv
vsim -voptargs=+acc -onfinish stop -t 1ps work.regression_testbench
run 10 us
set completion [examine -radix binary /regression_testbench/passed]
puts "Regression completion flag: $completion"
if {$completion != 1} {quit -f -code 1}
quit -f -code 0
