# Lab 8: Pipelined MIPS Processor with SoC Integration

Complete implementation of a 5-stage pipelined MIPS processor with System-on-Chip (SoC) integration for Basys3 FPGA board.

## Repository Structure

```
├── src/              # All Verilog source files (19 modules)
├── testbench/        # Testbenches for validation
├── memory/           # Instruction and data memory modules
└── constraints/      # Basys3 FPGA constraints file
```

## Key Components

### Processor Core
- **5-stage pipeline**: IF, ID, EX, MEM, WB
- **Hazard detection and forwarding**: Handles data and control hazards
- **19 MIPS instructions**: ADD, SUB, AND, OR, SLT, SLL, SRL, ADDI, SLTI, LW, SW, BEQ, J, JAL, JR, MULTU, MFHI, MFLO

### SoC Integration
- **Instruction Memory**: 64KB (0x00000000-0x0000FFFF)
- **Data Memory**: 64KB (0x00010000-0x0001FFFF)
- **GPIO Controller**: Memory-mapped I/O (0x00020000-0x00020FFF)
- **Factorial Accelerator**: Hardware accelerator (0x00021000-0x00021FFF)

### Top Module
- **`soc_top.v`**: Complete SoC integration with Basys3 interface

## Quick Start

### Simulation (Icarus Verilog)

```bash
# Compile and run comprehensive SoC test
iverilog -g2012 -o soc_test.vvp -s comprehensive_soc_testbench \
    src/*.v memory/*.v testbench/comprehensive_soc_testbench.v

vvp soc_test.vvp
gtkwave comprehensive_soc_testbench.vcd  # View waveforms
```

### Vivado Synthesis (Basys3)

1. Create new Vivado project
2. Add all files from `src/` and `memory/`
3. Set top module: `soc_top`
4. Add constraint file: `constraints/soc_basys3.xdc`
5. Run synthesis → implementation → generate bitstream

## Testbenches

- **`comprehensive_soc_testbench.v`**: Complete SoC validation with performance metrics
- **`soc_testbench.v`**: Basic SoC integration test
- **`simple_test.v`**: Simple pipeline functionality test

## Target Hardware

- **FPGA**: Basys3 (Artix-7, xc7a35tcpg236-1)
- **Clock**: 100 MHz
- **I/O**: Switches, buttons, LEDs, 7-segment display

## Files Included

### Source Files (19 modules)
- Core: `pipelined_mips.v`, `datapath.v`, `controlunit.v`
- Pipeline: `pipeline_reg.v`, `hazard_unit.v`, `forwarding_unit.v`
- Execution: `alu.v`, `multu.v`, `hilo.v`, `regfile.v`
- SoC: `soc_top.v`, `gpio.v`, `factorial_accel.v`
- Supporting: `adder.v`, `signext.v`, `mux2.v`, `dreg.v`, `maindec.v`, `auxdec.v`

### Memory
- `imem.v`: Instruction memory
- `dmem.v`: Data memory
- `memfile.dat`: Program memory contents
- `program.hex`: Additional programs

### Constraints
- `soc_basys3.xdc`: Basys3 pin assignments and timing constraints

## Testing

Run the comprehensive testbench to validate:
- Pipeline operation
- Hazard handling
- Memory-mapped I/O
- Hardware accelerator functionality
- SoC integration

## License

Academic project for CMPE 140 - Computer Architecture

