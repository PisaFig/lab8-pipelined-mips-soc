// CMPE 140 Lab 8: Validation Wrapper Testbench
// Tests the mips_fpga module with validation wrapper

`timescale 1ns / 1ps

module validation_wrapper_test;

    reg clk, rst, button;
    reg [8:0] switches;
    wire we_dm;
    wire [3:0] LEDSEL;
    wire [7:0] LEDOUT;
    
    // Clock generation (100MHz)
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Instantiate validation wrapper
    mips_fpga dut(
        .clk(clk),
        .rst(rst),
        .button(button),
        .switches(switches),
        .we_dm(we_dm),
        .LEDSEL(LEDSEL),
        .LEDOUT(LEDOUT)
    );
    
    // Test sequence
    initial begin
        // Generate waveform file
        $dumpfile("validation_wrapper_test.vcd");
        $dumpvars(0, validation_wrapper_test);
        
        $display("=== CMPE 140 Lab 8: Validation Wrapper Test ===");
        
        // Initialize
        rst = 1;
        button = 0;
        switches = 9'b0;
        #50;
        
        // Release reset
        rst = 0;
        $display("Reset released at time %0t", $time);
        
        // Test register read (switches[4:0] = register address)
        switches[4:0] = 5'd0;  // Read register 0 ($zero)
        switches[8:5] = 4'b0000;  // Display lower half word
        #100;
        $display("Reading register %0d (should be 0)", switches[4:0]);
        
        switches[4:0] = 5'd1;  // Read register 1 ($at)
        #100;
        $display("Reading register %0d", switches[4:0]);
        
        // Test instruction display
        switches[8:5] = 4'b0010;  // Display lower half word of instruction
        #100;
        $display("Displaying instruction (lower half)");
        
        // Test PC display
        switches[8:5] = 4'b1000;  // Display lower half word of PC
        #100;
        $display("Displaying PC (lower half)");
        
        // Run for several clock cycles to see pipeline operation
        $display("\nRunning pipeline for 200 cycles...");
        repeat (200) begin
            @(posedge clk);
        end
        
        $display("\n=== Validation Wrapper Test Complete ===");
        $display("Check waveform file: validation_wrapper_test.vcd");
        $finish;
    end

endmodule

