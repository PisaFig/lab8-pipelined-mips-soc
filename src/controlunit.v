// CMPE 140 Lab 8: Control Unit (adapted for pipeline)
module controlunit (
    input  wire [5:0]  op,
    input  wire [5:0]  funct,
    output wire        regwrite,
    output wire        memtoreg,
    output wire        memwrite,
    output wire        branch,
    output wire        alusrc,
    output wire        regdst,
    output wire        jump,
    output wire        jal,
    output wire        jumpreg,
    output wire [2:0]  alucontrol
);
    
    // Internal signals
    wire [1:0] aluop;
    wire we_hi, we_lo, hilo_to_reg;
    
    // Main decoder
    maindec md (
        .opcode(op),
        .branch(branch),
        .jump(jump),
        .reg_dst(regdst),
        .we_reg(regwrite),
        .alu_src(alusrc),
        .we_dm(memwrite),
        .dm2reg(memtoreg),
        .jal(jal),
        .alu_op(aluop)
    );

    // ALU decoder
    auxdec ad (
        .alu_op(aluop),
        .funct(funct),
        .alu_ctrl(alucontrol),
        .we_hi(we_hi),
        .we_lo(we_lo),
        .hilo_to_reg(hilo_to_reg),
        .jr(jumpreg)
    );

endmodule