// CMPE 140 Lab 8: System-on-Chip Top Module
// Integrates pipelined MIPS with memory-mapped peripherals

module soc_top(
    input clk, reset,
    input [15:0] sw,           // Basys-3 switches
    input [4:0] btn,           // Basys-3 buttons  
    output [15:0] led,         // Basys-3 LEDs
    output [7:0] seg,          // 7-segment display
    output [3:0] an            // 7-segment anodes
);

    // Memory map:
    // 0x00000000-0x0000FFFF: Instruction memory (64KB)
    // 0x00010000-0x0001FFFF: Data memory (64KB) 
    // 0x00020000-0x00020FFF: GPIO controller (4KB)
    // 0x00021000-0x00021FFF: Factorial accelerator (4KB)

    // Processor signals
    wire [31:0] pc, instr;
    wire [31:0] aluout, writedata, readdata;
    wire memwrite;
    
    // Memory interface signals
    wire [31:0] instr_addr, data_addr;
    wire [31:0] instr_data, data_rdata, data_wdata;
    wire data_we;
    
    // Peripheral select signals
    wire sel_imem, sel_dmem, sel_gpio, sel_factorial;
    wire [31:0] gpio_rdata, factorial_rdata;
    
    // GPIO interface
    wire [31:0] gpio_out;
    wire [7:0] seven_seg;
    wire [3:0] seg_select;
    
    // Factorial accelerator interface
    wire factorial_start, factorial_done;
    wire [31:0] factorial_result;

    // ============ PROCESSOR CORE ============
    pipelined_mips cpu(
        .clk(clk),
        .reset(reset),
        .pc(pc),
        .instr(instr),
        .memwrite(memwrite),
        .aluout(aluout),
        .writedata(writedata),
        .readdata(readdata),
        .gpio_out(gpio_out),
        .gpio_in({16'h0, sw}),
        .seven_seg(seven_seg),
        .seg_select(seg_select),
        .factorial_start(factorial_start),
        .factorial_done(factorial_done),
        .factorial_result(factorial_result)
    );

    // ============ MEMORY MAPPING ============
    assign instr_addr = pc;
    assign data_addr = aluout;
    assign data_wdata = writedata;
    assign data_we = memwrite;
    
    // Address decoding
    assign sel_imem = (instr_addr[31:16] == 16'h0000);
    assign sel_dmem = (data_addr[31:16] == 16'h0001);
    assign sel_gpio = (data_addr[31:12] == 20'h00020);
    assign sel_factorial = (data_addr[31:12] == 20'h00021);
    
    // ============ INSTRUCTION MEMORY ============
    imem instruction_memory(
        .clk(clk),
        .addr(instr_addr[15:2]),  // Word-aligned addressing
        .data(instr)
    );
    
    // ============ DATA MEMORY ============
    dmem data_memory(
        .clk(clk),
        .we(data_we & sel_dmem),
        .addr(data_addr[15:2]),   // Word-aligned addressing
        .din(data_wdata),
        .dout(data_rdata)
    );
    
    // ============ GPIO CONTROLLER ============
    gpio gpio_controller(
        .clk(clk),
        .reset(reset),
        .addr(data_addr[7:2]),    // 6-bit address within GPIO space
        .din(data_wdata),
        .dout(gpio_rdata),
        .we(data_we & sel_gpio),
        .switches(sw),
        .buttons(btn),
        .leds(led),
        .seg_data(seg),
        .seg_select(an)
    );
    
    // ============ FACTORIAL ACCELERATOR ============
    factorial_accel factorial_unit(
        .clk(clk),
        .reset(reset),
        .addr(data_addr[3:2]),    // 2-bit address within factorial space
        .din(data_wdata),
        .dout(factorial_rdata),
        .we(data_we & sel_factorial),
        .start(factorial_start),
        .done(factorial_done),
        .result(factorial_result)
    );
    
    // ============ READ DATA MULTIPLEXING ============
    assign readdata = sel_dmem ? data_rdata :
                     sel_gpio ? gpio_rdata :
                     sel_factorial ? factorial_rdata :
                     32'h0;

endmodule