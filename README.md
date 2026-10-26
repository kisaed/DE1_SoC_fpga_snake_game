<div align="center">

# Snake — FPGA

A classic snake game in SystemVerilog, running on the 16×16 RGB LED matrix of a Terasic DE1-SoC board.

**SystemVerilog · Intel Quartus Prime · ModelSim · Terasic DE1-SoC (Cyclone V SoC)**

[Features](#features) · [How to Play](#how-to-play) · [Requirements](#requirements) · [Architecture](#architecture) · [Getting Started](#getting-started) · [Project Structure](#project-structure) · [Documentation](#documentation)

</div>

The game is fully implemented in combinational/sequential SystemVerilog — no soft CPU, no operating system. An 8-bit LFSR seeds apple placement, keys are debounced at the register level, and the whole design compiles to a single Cyclone V configuration.

## Features

- **16×16 RGB LED matrix display** — green snake, red apple, driven row-by-row through the board's GPIO header
- **Pseudo-random apple placement** — an 8-bit LFSR proposes positions; cells occupied by the snake are rejected until a free spot is found
- **Debounced controls** — each key press is captured as a clean single-cycle pulse; 180° reversals are ignored
- **Collision detection** — walls and the snake's own body (tracked via a per-cell direction memory, so the tail follows without storing the full body)
- **Reset & game-over** — a hardware switch resets the game; `LEDR[0]` lights on game over
- **Sim/board clock switching** — the top module detects `ALTERA_RESERVED_QIS` to pick the hardware clock-divider chain on the board or the fast testbench clock in simulation
- **Testbenches throughout** — the top-level testbench scripts a full game (movement, rejected reversals, simultaneous key presses); `apple`, `snake`, `LFSR`, and `userInput` each ship with their own

## How to Play

Move the green snake to eat the red apple. Each apple grows the snake by one. Hitting a wall or your own body ends the game.

| Board element | Function |
|---------------|----------|
| `KEY[0]` | Move right |
| `KEY[1]` | Move left |
| `KEY[2]` | Move down |
| `KEY[3]` | Move up |
| `SW[9]` | Reset game |
| `LEDR[0]` | Game-over indicator |

On hardware the snake moves roughly every 330 ms (≈3 moves/second).

## Requirements

### Hardware

| Item | Notes |
|------|-------|
| Terasic DE1-SoC board (Cyclone V) | Uses `KEY[0..3]` (movement), `SW[9]` (reset), `LEDR[0]` (game over), and the 50 MHz board clock |
| 16×16 RGB LED matrix expansion board | Connects to the board's 36-pin `GPIO1` header (e.g. Terasic's LED matrix add-on for the DE1-SoC) |

Simulation requires no special hardware — any computer with ModelSim is enough.

### Software

| Tool | Version used | Needed for |
|------|--------------|------------|
| Intel Quartus Prime | 17.0.0 Lite Edition | Building and programming the FPGA (any recent Quartus with Cyclone V support works) |
| ModelSim (SE is fine) | 17.0 SE, bundled with Quartus | Running the testbenches (any ModelSim with SystemVerilog support works) |
| SystemVerilog (IEEE 1800) | — | The design and testbenches are written in SystemVerilog |

## Architecture

![System layout — modules and signal flow](docs/layout-diagram.svg)

The three signals between `snake` and `apple` form the game loop: the snake's body tells the apple module which cells are occupied, `ateApple` triggers a respawn, and the new `AplPos` feeds back into collision checks. For the full original block diagram, see [docs/Block Diagram Updated.pdf](docs/Block%20Diagram%20Updated.pdf).

| Module | File | Responsibility |
|--------|------|----------------|
| `DE1_SoC` | `DE1_SoC.sv` | Top level — clock tree, movement direction lock-out, game-tick generation, module wiring |
| `snake` | `snake.sv` | Game core — head/tail movement, wall & self collision, growth |
| `apple` | `apple.sv` | Apple placement — samples the LFSR and rejects snake-occupied cells |
| `LFSR` | `LFSR.sv` | 8-bit LFSR pseudo-random number generator (taps 8, 6, 5, 4) |
| `userInput` | `userInput.sv` | Debounces a key press into a one-cycle pulse |
| `clock_divider` | `clock_divider.sv` | 32-bit free-running counter whose bits are divided clocks |
| `LEDDriver` | `LEDDriver.sv` | Row-scan driver for the 16×16×2 LED matrix expansion board |

Clocking on the board: the 50 MHz clock feeds a counter whose bit 9 (~48.8 kHz) is the base game clock; a second divider chain produces the ~3 Hz game tick (`GT`). In simulation the base clock is the 10 MHz testbench clock and the tick divider is sped up with a `defparam`.

> [!NOTE]
> `LEDDriver.sv` is the provided driver for the LED matrix expansion board. It maps two 16×16 pixel arrays (`RedPixels`, `GrnPixels`) to the GPIO header and handles the row scanning.

## Getting Started

### Simulation (ModelSim)

Any ModelSim version works (developed with v17.0 SE):

```bash
# from the repository root
do runlab.do
```

`runlab.do` compiles every `.sv` file in the folder, runs the `DE1_SoC_testbench`, opens the signal/waveform/structure windows, and runs the simulation to completion. `Launch_ModelSim.bat` simply opens ModelSim.

Per-module waveform setups live in the `*_wave.do` files.

> [!TIP]
> `runlab.do` takes an optional argument — `do runlab.do apple` runs the `apple` module's testbench with its waveform view.

### Hardware (Quartus Prime)

1. Open `DE1_SoC.qsf` in Quartus Prime (developed with v17.0).
2. Compile and program the DE1-SoC board (Cyclone V).
3. Play: `KEY[0..3]` to steer, `SW[9]` to reset, watch `LEDR[0]` for game over.

The SDC constraints are in `DE1_SoC_golden_top.sdc`.

## Project Structure

```
.
├── DE1_SoC.sv              # Top module + full-game testbench
├── snake.sv                # Game core
├── apple.sv                # Apple placement
├── LFSR.sv                 # Pseudo-random number generator
├── userInput.sv            # Debounced key input
├── clock_divider.sv        # Clock division tree
├── LEDDriver.sv            # LED matrix driver (provided)
├── DE1_SoC.qpf / .qsf      # Quartus project files
├── DE1_SoC_golden_top.sdc  # Timing constraints
├── runlab.do               # ModelSim run script
├── *_wave.do               # Per-module waveform setups
├── Launch_ModelSim.bat
└── docs/                   # Design description, FSM, block diagrams, product docs
```

## Documentation

- [Layout diagram (SVG)](docs/layout-diagram.svg)
- [Design description](docs/Description.pdf)
- [FSM design](docs/FSM.pdf)
- [Block diagram](docs/Block%20Diagram%20Updated.pdf)
- [Product explanation](docs/product%20explanation.docx)
- [Market & usability analysis](docs/market%26usability.docx)

## Author

Built as the final project for **ECE 271 — Digital Design**, University of Washington, by **Kevin Xu** (2026).
