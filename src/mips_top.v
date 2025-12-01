// CMPE 140 Lab 8: MIPS Top Module for Validation Wrapper
// Adapts pipelined MIPS processor to validation wrapper interface

module mips_top(
    input  wire        clk,
    input  wire        rst,
    input  wire [4:0]  ra3,        // Register read address for display
    output wire        we_dm,      // Data memory write enable
    output wire [31:0] pc_current, // Current PC
    output wire [31:0] instr,      // Current instruction
    output wire [31:0] alu_out,    // ALU output
    output wire [31:0] wd_dm,      // Write data to data memory
    output wire [31:0] rd_dm,      // Read data from data memory
    output wire [31:0] rd3         // Register file 3rd read port output
);

    // Processor signals
    wire [31:0] pc;
    wire [31:0] instruction;
    wire memwrite;
    wire [31:0] aluout, writedata, readdata;
    
    // Instruction memory
    wire [31:0] instr_data;
    
    // Data memory
    wire [31:0] data_rdata;
    
    // Instantiate pipelined MIPS processor
    pipelined_mips cpu(
        .clk(clk),
        .reset(rst),
        .pc(pc),
        .instr(instruction),
        .memwrite(memwrite),
        .aluout(aluout),
        .writedata(writedata),
        .readdata(readdata),
        .ra3(ra3),
        .rd3(rd3),
        // SoC interface - not used in validation wrapper
        .gpio_out(),
        .gpio_in(32'h0),
        .seven_seg(),
        .seg_select(),
        .factorial_start(),
        .factorial_done(1'b0),
        .factorial_result(32'h0)
    );
    
    // Instruction memory
    imem instruction_memory(
        .clk(clk),
        .addr(pc[15:2]),  // Word-aligned addressing
        .data(instr_data)
    );
    
    // Data memory
    dmem data_memory(
        .clk(clk),
        .we(memwrite),
        .addr(aluout[15:2]),  // Word-aligned addressing
        .din(writedata),
        .dout(data_rdata)
    );
    
    // Connect instruction memory
    assign instruction = instr_data;
    
    // Connect data memory
    assign readdata = data_rdata;
    
    // Map to validation wrapper interface
    assign pc_current = pc;
    assign instr = instruction;
    assign alu_out = aluout;
    assign wd_dm = writedata;
    assign rd_dm = data_rdata;
    assign we_dm = memwrite;

endmodule

