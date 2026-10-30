# Verification notes

## Focused RTL run: October 29, 2026

- Tool: Model Technology ModelSim ALTERA STARTER EDITION **10.5b**, Intel FPGA 17.0 distribution.
- Command from repository root: `vsim -c -do run_regressions.do`.
- Compiles all seven root design sources and `tests/regression_testbench.sv`.
- Result after maintenance: **exit status 0; compilation 0 errors / 0 warnings; simulation 0 errors / 0 warnings**.
- This is a behavioral RTL simulation. No new synthesis, fitting, physical timing, or board validation was performed.

Observed check-group results:

```text
PASS: apple reset, occupied rejection, placement, update edge
PASS: synchronized input edge pulses (not bounce filtering)
PASS: simulation top-level reset, direction filtering, input priority
PASS: snake movement, growth, tail reuse, collisions, reset
PASS: LFSR reset and 255-state period
PASS: all focused RTL regressions completed
Regression completion flag: 1
```

The suite finishes its checks by 2.566 microseconds and the runner samples completion after a bounded 10-microsecond run. A check failure uses `$fatal`; the runner returns nonzero on a simulator break/error or if completion is absent.

## Reproduced occupancy defect

The regression grows a four-cell body in a 2 x 2 loop and then moves the head into the cell vacated by the tail on the same tick. That move is legal when not growing.

Before the fix, simulation failed at 116 ns:

```text
Fatal: snake: departing-tail move preserves the new head occupancy
```

The original sequential block scheduled `SnPos[nextHead] <= 1` and later `SnPos[oldTail] <= 0`. When those indexes matched, the later assignment cleared the new head. The updated block clears the tail first and sets the head last. The regression then passed without changing the intended collision rule.

## Other maintenance changes

- Connected and initialized `reset` in the original apple waveform testbench.
- Corrected the LFSR waveform testbench signal width from 10 bits to the module's 8 bits.
- Removed Quartus source-list references to twelve nonexistent earlier-lab modules; retained the board pin assignments and original notices.
- Corrected README and SVG statements about red/green display output and input edge detection.

## Limits of the evidence

The directed checks cover a useful set of RTL behaviors, not all game states or physical effects. They do not test switch bounce, metastability, LED electrical wiring/scan quality, board-clock reset behavior, timing closure, full-board completion, or rapid multiple turns between movement ticks. The README records those known limitations. Original waveform benches remain available but are not described as self-checking coverage.
