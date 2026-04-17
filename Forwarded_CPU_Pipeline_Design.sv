// Code your design here
`timescale 1ns/1ns

`define OPC_ADDI   4'h0        // I-type: add immediate
`define OPC_SUBI   4'h1        // I-type: subtract immediate
`define OPC_ANDI   4'h2        // I-type: bitwise AND immediate
`define OPC_ORI    4'h3        // I-type: bitwise OR immediate
`define OPC_XORI   4'h4        // I-type: bitwise XOR immediate
`define OPC_SLLI   4'h5        // I-type: logical shift left immediate
`define OPC_SRLI   4'h6        // I-type: logical shift right immediate
`define OPC_ADD    4'h7        // R-type: add
`define OPC_SUB    4'h8        // R-type: subtract
`define OPC_AND    4'h9        // R-type: bitwise AND
`define OPC_OR     4'hA        // R-type: bitwise OR
`define OPC_XOR    4'hB        // R-type: bitwise XOR


`define ALU_ADD    3'd0        // ALU control: add
`define ALU_SUB    3'd1        // ALU control: subtract
`define ALU_AND    3'd2        // ALU control: bitwise AND
`define ALU_OR     3'd3        // ALU control: bitwise OR
`define ALU_XOR    3'd4        // ALU control: bitwise XOR
`define ALU_SLL    3'd5        // ALU control: logical shift left
`define ALU_SRL    3'd6        // ALU control: logical shift right


// Instruction Fetch stage:
// Reads 16-bit instructions from ROM and outputs one instruction per cycle.
module IF_STAGE #(parameter iMemDepth = 18, // Number of instruction words in ROM
            parameter iMemAWL = $clog2(iMemDepth), // Address width derived from ROM depth
            parameter InstrMem = "instr_mem.txt", // Instruction memory initialization file
            parameter instrDWL = 16 // Instruction word length
           ) 
  
 (input CLK, RST, 
  output reg [iMemAWL-1:0] pc_out,
  output wire [instrDWL-1:0] instr_out);
  
  reg [instrDWL-1:0] iROM [0:iMemDepth-1]; // Instruction ROM storage
  
  initial begin
    integer i;
    for (i = 0; i < iMemDepth; i=i+1) begin
      iROM[i] = 16'h0000; // Initialize ROM contents to 0 before loading program
    end
    $readmemh(InstrMem, iROM); // Load instruction file into ROM
  end
    
  always @(posedge CLK) begin // Program counter update
    if(RST) pc_out <= '0; // Synchronous reset clears PC
    else pc_out <= pc_out + 1'b1; // Increment PC each cycle
  end
    
  assign instr_out = iROM[pc_out]; // Combinational instruction read from ROM
endmodule

    
// Register file:
// 16 x 16-bit storage with 2 read ports and 1 write port.
// Writeback results are committed here.
module registerFile(input CLK, RST,
                    input [3:0] RA1, RA2, // Two read addresses
                    output wire [15:0] RD1, RD2,
                    input WE,
                    input [3:0] WA,
                    input [15:0] WD);
  
  reg [15:0] RAM [0:15]; // Register file storage
  integer i;
  
  assign RD1 = RAM[RA1]; // Combinational read port 1
  assign RD2 = RAM[RA2]; // Combinational read port 2
  
  always @(posedge CLK) begin // Synchronous reset / write behavior
    if (RST) begin
      for(i=0; i<16; i=i+1) begin // Clear all registers on reset
        RAM[i] <= 16'h0000;
      end
    end else if (WE && (WA != 4'd0)) begin // Preserve r0 as constant zero
      RAM[WA] <= WD;
    end
  end
endmodule


// Instruction Decode stage:
// Splits the instruction into opcode and register fields, generates ALU control,
// reads source operands from the register file, and selects between rt data and immediate.
module ID_STAGE (input CLK, RST,
           input wire [15:0] instr_in,
           input wire [15:0] wb_rf_wd,
           input wire [3:0] wb_rf_wa,
           input wire wb_rf_we,
           output wire [2:0] alu_sel_out,
           output wire [3:0] shamt_out,
           output wire [15:0] rs_data_out,
           output wire rd_we_out, 
           output wire [3:0] rd_addr_out,
           output wire [15:0] roi_data_out,
           output wire use_imm_out,
           output wire [3:0] rs_out, 
           output wire [3:0] rt_out);
  
  wire [3:0] opcode = instr_in[15:12];
  wire [3:0] rd_addr = instr_in[11:8];
  wire [3:0] rs_addr = instr_in[7:4];
  wire [3:0] lo4 = instr_in[3:0];
  
  
  reg [2:0] alu_sel;
  reg rd_we;
  reg use_imm;
  reg [3:0] shamt;
  
  always @(*) begin
    alu_sel = `ALU_ADD;
    rd_we = 0;
    use_imm = 0;
    shamt = lo4;
    case(opcode)
      `OPC_ADDI: begin
        alu_sel = `ALU_ADD; // Redundant due to default assignment
        rd_we = 1; // Enable destination register write
        use_imm = 1; // Use immediate operand
      end
      `OPC_SUBI: begin
        alu_sel = `ALU_SUB;
        rd_we = 1;
        use_imm = 1;
      end
      `OPC_ANDI: begin
        alu_sel = `ALU_AND;
        rd_we = 1;
        use_imm = 1;
      end
      `OPC_ORI: begin
        alu_sel = `ALU_OR;
        rd_we = 1;
        use_imm = 1;
      end
      `OPC_XORI: begin
        alu_sel = `ALU_XOR;
        rd_we = 1;
        use_imm = 1;
      end
      `OPC_SLLI: begin
        alu_sel = `ALU_SLL;
        rd_we = 1;
        use_imm = 1;
      end
      `OPC_SRLI: begin
        alu_sel = `ALU_SRL;
        rd_we = 1;
        use_imm = 1;
      end
      `OPC_ADD: begin
        alu_sel = `ALU_ADD; // Redundant due to default assignment
        rd_we = 1; // use_imm remains 0 by default
      end
      `OPC_SUB: begin
        alu_sel = `ALU_SUB;
        rd_we = 1;
      end
      `OPC_AND: begin
        alu_sel = `ALU_AND;
        rd_we = 1;
      end
      `OPC_OR: begin
        alu_sel = `ALU_OR;
        rd_we = 1;
      end
      `OPC_XOR: begin
        alu_sel = `ALU_XOR;
        rd_we = 1;
      end
      default: begin
        alu_sel = `ALU_ADD;
        use_imm = 0;
        rd_we = 0;
      end
    endcase
  end  
  
  // True when opcode selects an R-type register-register instruction
  wire is_regtype = ((opcode >= `OPC_ADD) && (opcode <= `OPC_XOR));
  
  // For R-type instructions, lo4 is the rt address.
  // For immediate instructions, read port 2 is forced to r0.
  wire [3:0] ra2 = is_regtype ? lo4:4'b0000; 
 
  
  wire [15:0] rt_data; // Third register operand for R-type operations
  wire [15:0] rs_data; // Source register data from rs_addr
  
  registerFile MEM(.CLK(CLK), .RST(RST), .RA1(rs_addr), .RA2(ra2), .RD1(rs_data), 
                   .RD2(rt_data), .WD(wb_rf_wd), .WE(wb_rf_we), .WA(wb_rf_wa));
  
  
  wire [15:0] imm_ext = {12'h000, lo4}; // Zero-extend 4-bit immediate to 16 bits
  
  // Drive decoded control/data outputs
  assign alu_sel_out = alu_sel;
  assign roi_data_out = use_imm ? imm_ext: rt_data;
  assign use_imm_out = use_imm; // Exposed for pipeline control / forwarding logic
  assign rs_data_out = rs_data;
  assign rd_we_out = rd_we;
  assign rd_addr_out = rd_addr;
  assign shamt_out = shamt;
  assign rs_out = rs_addr;
  assign rt_out = use_imm ? 4'd0:lo4;
  
endmodule

// Forwarding unit:
// Generates select signals for EX-stage operand muxes using EX/WB → EX bypass logic.
module FWD_UNIT(input [3:0] rs_addr,
                      input [3:0] rt_addr,
                      input use_imm,
                      input [3:0] EXWB_rd,
                      input EXWB_rd_we,
                      output reg fwd_rs,
                      output reg fwd_rt);
  wire prefix = (EXWB_rd != 4'b0) && EXWB_rd_we;
  wire rs_match = (rs_addr == EXWB_rd);
  wire rt_match = (rt_addr == EXWB_rd);
  always@(*) begin
    fwd_rs = (prefix && rs_match) ? 1'b1: 1'b0;
    fwd_rt = (prefix && rt_match && (!use_imm)) ? 1'b1: 1'b0;
  end
endmodule
       
      
    


// Execute stage:
// Applies the selected ALU operation to the two EX-stage operands.
// Also generates a zero flag when the ALU result is zero.
module EX_STAGE(input wire [2:0] IDEX_sel,
                input wire [3:0] IDEX_shamt,
                input wire [15:0] IDEX_rsdata,
                input wire [15:0] IDEX_roi,
                output reg [15:0] ex_result,
                output wire ex_zero);
  
  always @(*) begin
    case(IDEX_sel)
      `ALU_ADD: ex_result = IDEX_rsdata + IDEX_roi;
      `ALU_SUB: ex_result = IDEX_rsdata - IDEX_roi;
      `ALU_AND: ex_result = IDEX_rsdata & IDEX_roi;
      `ALU_OR: ex_result = IDEX_rsdata | IDEX_roi;
      `ALU_XOR: ex_result = IDEX_rsdata ^ IDEX_roi;
      `ALU_SLL: ex_result = IDEX_rsdata << IDEX_shamt;
      `ALU_SRL: ex_result = IDEX_rsdata >> IDEX_shamt;
      default: ex_result = 16'h0000;
    endcase
  end
  
  assign ex_zero = (ex_result == 16'h0000);
  
endmodule


// Writeback stage:
// Passes the EX/WB pipeline register contents back to the register file write port.
module WB_STAGE(input wire [15:0] EXWB_result,
                input wire EXWB_rdwe,
                input wire [3:0] EXWB_rd_addr,
                output wire [15:0] wb_rf_wd,
                output wire wb_rf_we,
                output wire [3:0] wb_rf_wa);
  assign wb_rf_wd = EXWB_result;
  assign wb_rf_we = EXWB_rdwe;
  assign wb_rf_wa = EXWB_rd_addr;
  
endmodule


// Top-level CPU pipeline:
// Parameterized 4-stage pipelined CPU connecting IF, ID, EX, and WB stages
// with explicit pipeline registers and EX/WB → EX forwarding.
module CPU_Pipeline #(parameter ROMDepth = 8,
                      parameter ROMFile = "instr_mem.txt",
                      parameter DWL = 16)
  (input CLK, RST);
  
  // IF-stage outputs
  wire [$clog2(ROMDepth)-1:0] pc_out; 
  wire [DWL-1:0] instr_out;
  
  // IF stage instantiation
  IF_STAGE #(.iMemDepth(ROMDepth), .InstrMem(ROMFile), .instrDWL(DWL))
  stage1(.CLK(CLK), .RST(RST), .pc_out(pc_out), .instr_out(instr_out));
  
  // IF/ID pipeline registers
  reg [$clog2(ROMDepth)-1:0] PC_OUT; 
  reg [DWL-1:0] IFID_instr;
  
  always@(posedge CLK) begin // Update IF/ID pipeline registers each cycle
    if(RST) begin
      PC_OUT <= '0;
      IFID_instr <= '0;
    end else begin
      PC_OUT <= pc_out;
      IFID_instr <= instr_out;
    end
  end
  
  
  wire [15:0] wb_rf_wd; // Writeback data to register file
  wire [3:0] wb_rf_wa;  // Writeback address to register file
  wire wb_rf_we;        // Writeback enable to register file
  
  // ID-stage outputs
  wire [2:0] alu_sel_out;
  wire rd_we_out;
  wire [3:0] rd_addr_out;
  wire [3:0] shamt_out;
  wire use_imm_out;
  wire [15:0] rs_data_out;
  wire [15:0] roi_out;
  wire [3:0] rs_out;
  wire [3:0] rt_out;
   
  // ID stage instantiation
  ID_STAGE stage2 (.CLK(CLK), .RST(RST), .instr_in(IFID_instr), .wb_rf_wd(wb_rf_wd),
                   .wb_rf_wa(wb_rf_wa), .wb_rf_we(wb_rf_we), .alu_sel_out(alu_sel_out),
                   .rd_we_out(rd_we_out), 
                   .rd_addr_out(rd_addr_out), .shamt_out(shamt_out), .use_imm_out(use_imm_out),
                   .rs_data_out(rs_data_out), .roi_data_out(roi_out), .rs_out(rs_out), .rt_out(rt_out));
  
  // ID/EX pipeline registers
  reg [2:0] IDEX_sel;
  reg IDEX_rdwe;
  reg [3:0] IDEX_rd;
  reg [3:0] IDEX_shamt;
  reg [15:0] IDEX_rsdata;
  reg [15:0] IDEX_roi;
  reg [3:0] IDEX_rs;
  reg [3:0] IDEX_rt;
  reg IDEX_use_imm;
  
  always @(posedge CLK) begin // Update ID/EX pipeline registers each cycle
    if(RST) begin
      IDEX_sel <= 3'b000;
      IDEX_rdwe <= 1'b0;
      IDEX_rd <= 4'b0000;
      IDEX_shamt <= 4'h0;
      IDEX_rsdata <= 16'h0000;
      IDEX_roi <= 16'h0000;
      IDEX_rs <= 4'b0000;
      IDEX_rt <= 4'b0000;
      IDEX_use_imm <= 1'b0;
    end else begin
      IDEX_sel <= alu_sel_out;
      IDEX_rdwe <= rd_we_out;
      IDEX_rd <= rd_addr_out;
      IDEX_shamt <= shamt_out;
      IDEX_rsdata <= rs_data_out;
      IDEX_roi <= roi_out;
      IDEX_rs <= rs_out;
      IDEX_rt <= rt_out;
      IDEX_use_imm <= use_imm_out;
    end
  end
  
  wire fwd_rs; // Forwarding select for operand A
  wire fwd_rt; // Forwarding select for operand B
  reg [15:0] EXWB_result; // EX/WB pipeline register for ALU result
  
  reg [3:0] EXWB_rd_addr; // Delayed destination register address for WB timing alignment
  reg EXWB_rdwe; // Delayed write-enable for WB timing alignment
  
  // Forwarding unit instantiation
 FWD_UNIT fwdUnit(.rs_addr(IDEX_rs), .rt_addr(IDEX_rt), .use_imm(IDEX_use_imm), .EXWB_rd(EXWB_rd_addr), .EXWB_rd_we(EXWB_rdwe), .fwd_rs(fwd_rs), .fwd_rt(fwd_rt));
            
  // EX-stage outputs and forwarded ALU operands
  wire [15:0] ex_result;
  wire ex_zero;
  wire [15:0] op1;
  wire [15:0] op2;
  
  assign op1 = fwd_rs ? EXWB_result : IDEX_rsdata;
  assign op2 = fwd_rt ? EXWB_result : IDEX_roi;
                   
                   
  // EX stage instantiation
  EX_STAGE stage3(.IDEX_sel(IDEX_sel), .IDEX_shamt(IDEX_shamt), .IDEX_rsdata(op1),
                  .IDEX_roi(op2), .ex_result(ex_result), .ex_zero(ex_zero));
  
  
  always @(posedge CLK) begin
    if(RST) begin
      EXWB_result <= 16'h0000;
      EXWB_rd_addr <= 4'h0;
      EXWB_rdwe <= 1'b0;
    end else begin
      EXWB_result <= ex_result;
      EXWB_rd_addr <= IDEX_rd; // Pipeline rd / rdwe into EX/WB for correct writeback timing
      EXWB_rdwe <= IDEX_rdwe;
    end
  end
  
  // WB stage instantiation
  WB_STAGE stage4(.EXWB_result(EXWB_result), .EXWB_rd_addr(EXWB_rd_addr),
                  .EXWB_rdwe(EXWB_rdwe), .wb_rf_wd(wb_rf_wd), .wb_rf_wa(wb_rf_wa),
                  .wb_rf_we(wb_rf_we));
  
      
endmodule
