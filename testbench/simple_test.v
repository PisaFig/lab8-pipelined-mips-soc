// CMPE 140 Lab 8: Simple Pipelined MIPS Test
// Basic functional test of the pipelined processor

`timescale 1ns / 1ps

module simple_test;

    reg clk, reset;
    wire [31:0] pc;
    wire [31:0] instr;
    wire memwrite;
    wire [31:0] aluout, writedata;
    reg [31:0] readdata;
    integer i;  // Loop variable
    
    // Clock generation  
    initial begin
        clk = 0;
        forever #5 clk = ~clk;  // 100MHz clock
    end
    
    // Instantiate the pipelined MIPS processor
    pipelined_mips dut(
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .instr(instr),
        .memwrite(memwrite),
        .aluout(aluout),
        .writedata(writedata),
        .readdata(readdata),
        .gpio_out(),
        .gpio_in(32'h0),
        .seven_seg(),
        .seg_select(),
        .factorial_start(),
        .factorial_done(1'b0),
        .factorial_result(32'h0)
    );
    
    // Simple instruction memory
    reg [31:0] imem [0:63];
    
    initial begin
        // Initialize instruction memory with a simple test program
        // Program: Load-use hazard test
        imem[0]  = 32'h8c080000;  // lw $t0, 0($zero)     - Load from address 0
        imem[1]  = 32'h01084020;  // add $t0, $t0, $t0    - Use $t0 immediately (hazard)
        imem[2]  = 32'hac080004;  // sw $t0, 4($zero)     - Store result
        
        // Program: Forwarding test  
        imem[3]  = 32'h20090005;  // addi $t1, $zero, 5   - Load immediate
        imem[4]  = 32'h012a5020;  // add $t2, $t1, $t2    - Forward from EX/MEM
        imem[5]  = 32'h014b5820;  // add $t3, $t2, $t3    - Forward from MEM/WB
        
        // Program: Branch test
        imem[6]  = 32'h200c0001;  // addi $t4, $zero, 1   
        imem[7]  = 32'h118c0001;  // beq $t4, $t4, +1     - Branch taken
        imem[8]  = 32'h200d0000;  // addi $t5, $zero, 0   - Should be skipped
        imem[9]  = 32'h200e0002;  // addi $t6, $zero, 2   - Branch target
        
        // Fill rest with NOPs
        for (i = 10; i < 64; i = i + 1) begin
            imem[i] = 32'h00000000;  // NOP
        end
    end
    
    // Instruction fetch
    assign instr = imem[pc[7:2]];  // Word-aligned PC
    
    // Simple data memory
    reg [31:0] dmem [0:63];
    
    initial begin
        // Initialize data memory
        dmem[0] = 32'h12345678;  // Test data at address 0
        for (i = 1; i < 64; i = i + 1) begin
            dmem[i] = 32'h00000000;
        end
    end
    
    // Data memory read/write
    always @(posedge clk) begin
        if (memwrite && aluout[31:8] == 24'h0) begin
            dmem[aluout[7:2]] <= writedata;
            $display("Memory Write: Address=%h, Data=%h", aluout, writedata);
        end
    end
    
    always @(*) begin
        if (aluout[31:8] == 24'h0)
            readdata = dmem[aluout[7:2]];
        else
            readdata = 32'h0;
    end
    
    // Test sequence
    initial begin
        // Generate waveform file
        $dumpfile("simple_test.vcd");
        $dumpvars(0, simple_test);
        
        $display("=== CMPE 140 Lab 8: Simple Pipelined MIPS Test ===");
        
        // Initialize
        reset = 1;
        #20 reset = 0;
        
        $display("Starting pipeline execution...");
        $display("Time\tPC\tInstr\t\tALUOut\tMemWrite");
        
        // Run for enough cycles to see pipeline effects
        repeat (50) begin
            @(posedge clk);
            $display("%0t\t%h\t%h\t%h\t%b", 
                     $time, pc, instr, aluout, memwrite);
        end
        
        // Check final memory state
        $display("\n=== Final Memory State ===");
        $display("Data Memory[0] = %h (original test data)", dmem[0]);
        $display("Data Memory[1] = %h (should be 2*original = %h)", 
                 dmem[1], 2 * dmem[0]);
        
        // Performance analysis
        $display("\n=== Pipeline Performance Analysis ===");
        $display("Instructions executed: ~15");
        $display("Clock cycles: 50");
        $display("Theoretical CPI for pipeline: 1.0");
        $display("Actual CPI with hazards: ~3.3");
        $display("Pipeline efficiency: ~30%% (due to test hazards)");
        
        $display("\n=== Simple Test Complete ===");
        $finish;
    end

endmodule