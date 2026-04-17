# Custom-ISA-4-Stage-ALU-Centric-CPU-Pipeline-in-SystemVerilog
A custom 16-bit, 4-stage pipelined CPU (Fetch, Decode, Execute, Writeback) implemented in SystemVerilog. 
Instructions are loaded from a text-based ROM. Verified with a self-checking testbench using tasks and directed tests, 
including hardware-based RAW hazard resolution via EX/WB forwarding.


OVERVIEW:
  * Custom 16-bit pipelined CPU implemented in SystemVerilog
  * Implements a simple opcode-driven ISA with immediate, register-type, and shift instructions
  * Designed to explore CPU microarchitecture, pipelining, and verification
  * Verified using a self-checking testbench and waveform analysis
  * Implements EX/WB → EX data forwarding to resolve RAW hazards without pipeline stalls
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
     - Performs ALU operations (add, subtract, logic, shifts)
     - Receives forwarded operands when RAW hazards are detected
  * Writeback stage:
      - Commits ALU results to the register file on the clock edge
      - One instruction completes per cycle in steady state (after pipeline fill)


HAZARD HANDLING:
  * Implements EX/WB → EX data forwarding to resolve Read-After-Write (RAW) hazards.
  * Forwarding logic:
      - Compares EX-stage source register addresses with EX/WB destination register
      - Forwards ALU results directly to EX-stage operands when dependencies are detected
      - Uses operand muxing in the top-level datapath to select between forwarded and pipeline values
  * Supported hazard cases:
      - Back-to-back RAW dependencies on source A (rs)
      - Back-to-back RAW dependencies on source B (rt) for R-type instructions
  * Correctness safeguards:
      - Immediate instructions do not falsely forward into operand B
      - Register r0 remains hardwired to zero and is excluded from forwarding
  * Limitations:
      - No stall or hazard detection unit (forwarding-only solution)
      - Load-use hazards not applicable (ALU-only pipeline)


VERIFICATION METHODOLOGY:
  * Instruction programs loaded from a text-based ROM file 
  * Testbench features:
      - Clock and synchronous reset generation
      - Self-checking tasks to validate final register file contents
      - Immediate simulation termination on failure ($fatal)    
  * Directed test programs:
      - Exercise every opcode
      - Validate pipeline timing    
  * Additional directed tests for forwarding:
      - Source-A (rs) forwarding
      - Source-B (rt) forwarding for R-type instructions
      - Immediate false-forward protection
      - Zero-register (r0) forwarding suppression  
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
  * No pipeline stalls or hazard detection unit (forwarding-only hazard resolution)
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
  * Data hazard resolution using forwarding (bypass logic)
  * Serves as a foundation for more advanced CPU designs

