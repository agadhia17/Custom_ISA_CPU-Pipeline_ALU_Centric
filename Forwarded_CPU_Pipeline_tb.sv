// Code your testbench here
// or browse Examples
`timescale 1ns/1ns // Simulation time unit / precision in nanoseconds

module tb_CPU_Pipeline;
  reg CLK = 0;
  reg RST;
  
  always #5 CLK = ~CLK; // 10 ns clock period
  
  localparam memDepth = 18;
  localparam instrCodeLength = 16;
  localparam instrFile = "instr_mem.txt";
  
  CPU_Pipeline #(.ROMDepth(memDepth), .ROMFile(instrFile)) 
  DUT		(.CLK(CLK), .RST(RST)); // Instantiate the top-level DUT
  
  // Individual register probes for waveform dumping (Icarus/EPWave convenience)
  wire [15:0] rp00 = DUT.stage2.MEM.RAM[0];
  wire [15:0] rp01 = DUT.stage2.MEM.RAM[1];
  wire [15:0] rp02 = DUT.stage2.MEM.RAM[2];
  wire [15:0] rp03 = DUT.stage2.MEM.RAM[3];
  wire [15:0] rp04 = DUT.stage2.MEM.RAM[4];
  wire [15:0] rp05 = DUT.stage2.MEM.RAM[5];
  wire [15:0] rp06 = DUT.stage2.MEM.RAM[6];
  wire [15:0] rp07 = DUT.stage2.MEM.RAM[7];
  wire [15:0] rp08 = DUT.stage2.MEM.RAM[8];
  wire [15:0] rp09 = DUT.stage2.MEM.RAM[9];
  wire [15:0] rp10 = DUT.stage2.MEM.RAM[10];
  wire [15:0] rp11 = DUT.stage2.MEM.RAM[11];
  wire [15:0] rp12 = DUT.stage2.MEM.RAM[12];
  wire [15:0] rp13 = DUT.stage2.MEM.RAM[13];
  wire [15:0] rp14 = DUT.stage2.MEM.RAM[14];
  wire [15:0] rp15 = DUT.stage2.MEM.RAM[15];
  wire fwd_rs = DUT.fwd_rs;
  wire fwd_rt = DUT.fwd_rt;
  
  initial begin // EDA Playground waveform dump setup
    $dumpfile("waves.vcd"); // Not needed in Vivado
    $dumpvars(0, tb_CPU_Pipeline);
  end
  
  
  task automatic wait_cycles(input integer n); // Wait for n clock cycles
    integer i;
    begin
      for(i=0; i<n; i=i+1) begin
        @(posedge CLK);
      end
    end
  endtask
  
  
  // Check the register-file value at address r against the expected value.
  // On mismatch, print a failure message and terminate simulation.
  // On success, print a pass message and continue.
  task automatic check_reg(input integer r, input [15:0] exp); 
    reg [15:0] rec;
    begin
      rec = DUT.stage2.MEM.RAM[r]; // Read register-file contents through DUT hierarchy
      
      if(rec != exp) begin
        $display("FAIL; at r%0d, expected: 0x%04h, recieved: 0x%04h @ t = 				   					 %0t", r, exp, rec, $time); // Failure message
        $fatal; // Stop immediately on first mismatch for easier debugging
      end else begin
        $display("PASS; r%0d is 0x%04h at time = %0t",
                 r, rec, $time);
      end
    end
  endtask
  
  
  
  initial begin
    #0; RST =1'b1; // Assert reset
    wait_cycles(2); // Hold reset active for a couple of cycles
    RST = 1'b0; // Deassert reset and begin normal execution
    
    wait_cycles(memDepth + 8); // Allow program execution plus extra cycles for pipeline drain
    
    
    // Check final register-file contents after the full program completes
    check_reg(0, 16'h0000); // Expected r0 after all instructions complete
    check_reg(1, 16'h0005); 
    check_reg(2, 16'h000A); 
    check_reg(3, 16'h000D); 
    check_reg(4, 16'h000C); 
    check_reg(5, 16'h000F); 
    check_reg(6, 16'h0007); 
    check_reg(7, 16'h0008); 
    check_reg(8, 16'h0007); 
    check_reg(9, 16'h0003); 
    check_reg(10, 16'h0034); 
    check_reg(11, 16'h0006); 
    check_reg(12, 16'h000F); 
    check_reg(13, 16'h0005); 
    check_reg(14, 16'h0005); 
    check_reg(15, 16'h000D); 
    
    
    $finish;
  end
endmodule
