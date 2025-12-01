// CMPE 140 Lab 8: 5-Stage Pipelined MIPS Processor
// Main processor module integrating all pipeline stages

module pipelined_mips(
    input clk, reset,
    output [31:0] pc,
    input [31:0] instr,
    output memwrite,
    output [31:0] aluout, writedata,
    input [31:0] readdata,
    
    // Validation wrapper interface (3rd register read port)
    input [4:0] ra3,
    output [31:0] rd3,
    
    // SoC interface signals
    output [31:0] gpio_out,
    input [31:0] gpio_in,
    output [7:0] seven_seg,
    output [3:0] seg_select,
    output factorial_start,
    input factorial_done,
    input [31:0] factorial_result
);

    // Pipeline register control signals
    wire stallF, stallD, flushD, flushE;
    
    // IF stage signals
    wire [31:0] pcnextF, pcplus4F, pcnextbrF;
    wire [31:0] instrF;
    
    // ID stage signals  
    wire [31:0] pcF, pcD, pcplus4D, instrD;
    wire [5:0] opD, functD;
    wire [4:0] rsD, rtD, rdD;
    wire [15:0] immD;
    wire [31:0] signimmD, signimmshD;
    wire [31:0] srcaD, srcbD;
    wire regwriteD, memtoregD, memwriteD, branchD, alusrcD, regdstD, jumpD, jalD;
    wire [2:0] alucontrolD;
    wire equalD, jumpregD;
    wire [31:0] pcbranchD, pcjumpD;
    wire [31:0] pcplus8D;  // Return address for JAL
    
    // EX stage signals
    wire [31:0] srcaE, srcbE, signimmE;
    wire [4:0] rsE, rtE, rdE;
    wire [4:0] writeregE, writereg2E;
    wire regwriteE, memtoregE, memwriteE, alusrcE, regdstE, jalE;
    wire [2:0] alucontrolE;
    wire [31:0] srca2E, srcb2E, srcb3E;
    wire [31:0] aluoutE;
    wire [1:0] forwardaE, forwardbE;
    wire [31:0] pcplus8E;  // Propagate return address through pipeline
    
    // MEM stage signals
    wire [31:0] aluoutM, writedataM;
    wire [4:0] writeregM;
    wire regwriteM, memtoregM, memwriteM, jalM;
    wire [31:0] readdataM;
    wire [31:0] pcplus8M;  // Propagate return address
    
    // WB stage signals
    wire [31:0] aluoutW, readdataW;
    wire [4:0] writeregW;
    wire regwriteW, memtoregW, jalW;
    wire [31:0] resultW, result2W;
    wire [31:0] pcplus8W;  // Return address for JAL
    
    // Hazard detection
    hazard_unit hu(
        .rsD(rsD), .rtD(rtD),
        .rsE(rsE), .rtE(rtE),
        .writeregE(writeregE),
        .regwriteE(regwriteE),
        .memtoregE(memtoregE),
        .writeregM(writeregM),
        .regwriteM(regwriteM),
        .memtoregM(memtoregM),
        .writeregW(writeregW),
        .regwriteW(regwriteW),
        .branchD(branchD),
        .jumpD(jumpD),
        .jumpregD(jumpregD),
        .stallF(stallF),
        .stallD(stallD),
        .flushD(flushD),
        .flushE(flushE)
    );
    
    // Forwarding unit
    forwarding_unit fu(
        .rsE(rsE), .rtE(rtE),
        .writeregM(writeregM),
        .regwriteM(regwriteM),
        .writeregW(writeregW),
        .regwriteW(regwriteW),
        .forwardaE(forwardaE),
        .forwardbE(forwardbE)
    );

    // ============ IF STAGE ============
    // PC logic
    wire [31:0] pcjumptargetD;  // Jump target (either immediate or register)
    
    // Select jump target: register for JR, immediate for J/JAL
    mux2 #(32) jrtargetmux(pcjumpD, srcaD, jumpregD, pcjumptargetD);
    
    // Select next PC: branch or not
    mux2 #(32) pcmux(pcplus4F, pcbranchD, branchD & equalD, pcnextbrF);
    
    // Select next PC: jump or not
    mux2 #(32) pcjumpmux(pcnextbrF, pcjumptargetD, jumpD | jumpregD, pcnextF);
    
    // PC register with stall support
    pipeline_reg #(32) pcreg(clk, reset, stallF, pcnextF, pcF);
    adder pcadd1(pcF, 32'h4, pcplus4F);
    
    assign pc = pcF;
    assign instrF = instr;

    // ============ IF/ID PIPELINE REGISTER ============
    pipeline_reg #(64) ifid(
        .clk(clk),
        .reset(reset | flushD),
        .stall(stallD),
        .d({instrF, pcplus4F}),
        .q({instrD, pcplus4D})
    );

    // ============ ID STAGE ============
    // Instruction decode
    assign opD = instrD[31:26];
    assign functD = instrD[5:0];
    assign rsD = instrD[25:21];
    assign rtD = instrD[20:16];
    assign rdD = instrD[15:11];
    assign immD = instrD[15:0];

    // Control unit
    controlunit cu(
        .op(opD), 
        .funct(functD),
        .regwrite(regwriteD), 
        .memtoreg(memtoregD), 
        .memwrite(memwriteD),
        .branch(branchD), 
        .alusrc(alusrcD), 
        .regdst(regdstD), 
        .jump(jumpD),
        .jal(jalD),
        .alucontrol(alucontrolD),
        .jumpreg(jumpregD)
    );

    // Register file
    regfile rf(
        .clk(clk), 
        .we3(regwriteW), 
        .ra1(rsD), 
        .ra2(rtD), 
        .ra3(ra3),  // Third read port for validation wrapper
        .wa3(writeregW),
        .wd3(resultW), 
        .rd1(srcaD), 
        .rd2(srcbD),
        .rd3(rd3)   // Third read port output
    );

    // Sign extend
    signext se(immD, signimmD);
    
    // Branch logic
    assign equalD = (srcaD == srcbD);
    assign signimmshD = signimmD << 2;
    adder pcadd2(pcplus4D, signimmshD, pcbranchD);
    assign pcjumpD = {pcplus4D[31:28], instrD[25:0], 2'b00};
    
    // JAL return address (PC+4 in delay slot architecture)
    // Note: In MIPS with delay slots, JAL saves PC+4, and the delay slot executes
    // So we return to the instruction right after JAL (which will be fetched after delay slot)
    assign pcplus8D = pcplus4D;  // Return address is just PC+4

    // ============ ID/EX PIPELINE REGISTER ============
    pipeline_reg #(211) idex(
        .clk(clk),
        .reset(reset | flushE),
        .stall(1'b0),
        .d({regwriteD, memtoregD, memwriteD, alucontrolD, alusrcD, regdstD, jalD,
            srcaD, srcbD, rsD, rtD, rdD, signimmD, pcplus8D}),
        .q({regwriteE, memtoregE, memwriteE, alucontrolE, alusrcE, regdstE, jalE,
            srcaE, srcbE, rsE, rtE, rdE, signimmE, pcplus8E})
    );

    // ============ EX STAGE ============
    // Forwarding muxes
    mux3 #(32) forwardamux(srcaE, resultW, aluoutM, forwardaE, srca2E);
    mux3 #(32) forwardbmux(srcbE, resultW, aluoutM, forwardbE, srcb2E);
    
    // ALU source mux
    mux2 #(32) srcbmux(srcb2E, signimmE, alusrcE, srcb3E);
    
    // ALU
    alu alu_inst(
        .a(srca2E), 
        .b(srcb3E), 
        .alucontrol(alucontrolE), 
        .aluout(aluoutE)
    );
    
    // Write register mux
    mux2 #(5) wrmux(rtE, rdE, regdstE, writeregE);
    
    // JAL writes to register 31 ($ra)
    mux2 #(5) jalmux(writeregE, 5'd31, jalE, writereg2E);

    // ============ EX/MEM PIPELINE REGISTER ============
    pipeline_reg #(136) exmem(
        .clk(clk),
        .reset(reset),
        .stall(1'b0),
        .d({regwriteE, memtoregE, memwriteE, jalE, aluoutE, srcb2E, writereg2E, pcplus8E}),
        .q({regwriteM, memtoregM, memwriteM, jalM, aluoutM, writedataM, writeregM, pcplus8M})
    );

    // ============ MEM STAGE ============
    assign memwrite = memwriteM;
    assign aluout = aluoutM;
    assign writedata = writedataM;
    assign readdataM = readdata;

    // ============ MEM/WB PIPELINE REGISTER ============
    pipeline_reg #(104) memwb(
        .clk(clk),
        .reset(reset),
        .stall(1'b0),
        .d({regwriteM, memtoregM, jalM, aluoutM, readdataM, writeregM, pcplus8M}),
        .q({regwriteW, memtoregW, jalW, aluoutW, readdataW, writeregW, pcplus8W})
    );

    // ============ WB STAGE ============
    mux2 #(32) resmux(aluoutW, readdataW, memtoregW, result2W);
    
    // JAL writes PC+8 (return address) instead of ALU/memory result
    mux2 #(32) jalresmux(result2W, pcplus8W, jalW, resultW);

    // Connect SoC interface outputs (placeholders for integration)
    assign gpio_out = 32'h0;
    assign seven_seg = 8'h0;
    assign seg_select = 4'h0;
    assign factorial_start = 1'b0;

endmodule

// 3-input mux for forwarding
module mux3 #(parameter WIDTH = 32)
             (input [WIDTH-1:0] d0, d1, d2,
              input [1:0] s,
              output [WIDTH-1:0] y);
    
    assign y = s[1] ? d2 : (s[0] ? d1 : d0);
endmodule