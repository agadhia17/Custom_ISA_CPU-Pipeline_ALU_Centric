# Custom-ISA-4-Stage-ALU-Centric-CPU-Pipeline-in-SystemVerilog
A custom 16-bit, 4-stage pipelined CPU (Fetch, Decode, Execute, Writeback) implemented in SystemVerilog. 
Instructions are loaded from a text-based ROM. Verified with a self-checking testbench using tasks and directed tests, 
including RAW hazard-aware instruction scheduling.


OVERVIEW:
  * Custom 16-bit pipelined CPU implemented in SystemVerilog
  * Implements a simple opcode-driven ISA with immediate, register-type, and shift instructions
  * Designed to explore CPU microarchitecture, pipelining, and verification
  * Verified using a self-checking testbench and waveform analysis
  * Focused on correctness and clarity rather than feature completeness


ARCHITECTURE SUMMARY:
  * See CPU_Pipeline_Diagram.png for visual block diagram
  * 4-stage in-order pipeline:
      - Instruction Fetch (IF)
      - Instruction Decode / Register Read (ID)
      - Execute (EX)
      - Writeback (WB)
  * Single-issue, one instruction fetched per cycle
  * No data memory or control flow instructions (ALU-only core)
  * Pipeline registers separate each stage
  * Register file:
      - 16 registers × 16 bits
      - 2 read ports, 1 write port
      - Register r0 hardwired to zero


INSTRUCTION SET ARCHITECTURE (ISA):
  * Fixed 16-bit instruction format:
      - [15:12] opcode
      - [11:8] destination register (rd)
      - [7:4] source register (rs)
      - [3:0] immediate / shift amount(immediate function only) / second register (rt)
  * Opcode fully determines operation (no funct field)
  * Supported instruction classes:
      - Immediate arithmetic/logical (ADDI, SUBI, ANDI, ORI, XORI)
      - Register-register arithmetic/logical (ADD, SUB, AND, OR, XOR)
      - Shift-immediate (SLLI, SRLI)
  * Immediate values are 4-bit and extended to 16 bits before ALU use


PIPELINE OPERATION:
  * Instruction fetch uses a text-initialized ROM ($readmemh)
  * Decode stage:
     - Generates ALU control signals combinationally
     - Reads register operands from the register file
  * Execute stage:
     -  Performs ALU operations (add, subtract, logic, shifts)
  * Writeback stage:
      - Commits ALU results to the register file on the clock edge
      - One instruction completes per cycle in steady state (after pipeline fill)


HAZARD HANDLING:
  * No hardware-based forwarding or pipeline stall mechanisms are implemented.
  * The processor is susceptible to Read-After-Write (RAW) data hazards due to in-order execution.
  * Correct execution is ensured through instruction scheduling at the program level.
  * Dependent instructions are separated by independent operations, allowing register writes to complete before subsequent reads.
  * Avoids pipeline bubbles while maintaining correctness, mirroring early compiler-scheduled pipelines.


VERIFICATION METHODOLOGY:
  * Instruction programs loaded from a text-based ROM file
  * Testbench features:
      - Clock and synchronous reset generation
      - Self-checking tasks to validate final register file contents
      - Immediate simulation termination on failure ($fatal)
  * Directed test programs:
      - Exercise every opcode
      - Validate pipeline timing
      - Demonstrate RAW hazard behavior
  * Internal state verified via:
      - Hierarchical register file access
      - Waveform inspection (EPWave)


HOW TO RUN:
  * Simulated using EDA Playground (SystemVerilog + Icarus Verilog)
  * Required files:
      - design.sv (CPU RTL)
      - testbench.sv
      - instr_mem.txt (instruction ROM contents)
  * Steps:
      - Upload all files to the Design/Testbench windows
      - Run simulation
      - Observe PASS/FAIL output and waveforms


LIMITATIONS FOR FUTURE WORK:
  * No forwarding or pipeline stalls
  * No branch or jump instructions
  * No data memory (load/store)
  * Potential extensions:
      - Forwarding and hazard detection
      - Branch handling and PC redirection
      - Data memory stage
      - Larger immediates or expanded ISA


KEY TAKEAWAYS:
  * Designed as a learning and verification project
  * Developed understanding of:
      - CPU pipeline timing
      - ISA design tradeoffs
      - RAW hazards and scheduling
      - RTL verification techniques
  * Serves as a foundation for more advanced CPU designs

