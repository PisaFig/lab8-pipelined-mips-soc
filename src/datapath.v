module datapath (
        input  wire        clk,
        input  wire        rst,
        input  wire        branch,
        input  wire        jump,
        input  wire        reg_dst,
        input  wire        we_reg,
        input  wire        alu_src,
        input  wire        dm2reg,
        input  wire        we_hi,
        input  wire        we_lo,
        input  wire        hilo_to_reg,
        input  wire        jal,
        input  wire        jr,
        input  wire [2:0]  alu_ctrl,
        input  wire [4:0]  ra3,
        input  wire [31:0] instr,
        input  wire [31:0] rd_dm,
        output wire [31:0] pc_current,
        output wire [31:0] alu_out,
        output wire [31:0] wd_dm,
        output wire [31:0] rd3
    );

    wire [4:0]  rf_wa;
    wire        pc_src;
    wire [31:0] pc_plus4;
    wire [31:0] pc_pre;
    wire [31:0] pc_next;
    wire [31:0] pc_jr;
    wire [31:0] sext_imm;
    wire [31:0] ba;
    wire [31:0] bta;
    wire [31:0] jta;
    wire [31:0] alu_pa;
    wire [31:0] alu_pb;
    wire [31:0] wd_rf;
    wire [31:0] wd_rf_pre;
    wire [31:0] hi_out, lo_out;
    wire [31:0] mult_hi, mult_lo;
    wire [31:0] hilo_data;
    wire        zero;
    
    assign pc_src = branch & zero;
    assign ba = {sext_imm[29:0], 2'b00};
    assign jta = {pc_current[31:28], instr[25:0], 2'b00};
    
    // --- PC Logic --- //
    dreg pc_reg (
            .clk            (clk),
            .rst            (rst),
            .d              (pc_next),
            .q              (pc_current)
        );

    adder pc_plus_4 (
            .a              (pc_current),
            .b              (32'd4),
            .y              (pc_plus4)
        );

    adder pc_plus_br (
            .a              (pc_plus4),
            .b              (ba),
            .y              (bta)
        );

    mux2 #(32) pc_src_mux (
            .sel            (pc_src),
            .a              (pc_plus4),
            .b              (bta),
            .y              (pc_pre)
        );

    mux2 #(32) pc_jmp_mux (
            .sel            (jump),
            .a              (pc_pre),
            .b              (jta),
            .y              (pc_jr)
        );

    mux2 #(32) pc_jr_mux (
            .sel            (jr),
            .a              (pc_jr),
            .b              (alu_pa),
            .y              (pc_next)
        );

    // --- RF Logic --- //
    mux2 #(5) rf_wa_mux (
            .sel            (reg_dst),
            .a              (instr[20:16]),
            .b              (instr[15:11]),
            .y              (rf_wa)
        );

    // JAL uses register 31 ($ra)
    wire [4:0] rf_wa_final;
    mux2 #(5) jal_wa_mux (
            .sel            (jal),
            .a              (rf_wa),
            .b              (5'd31),
            .y              (rf_wa_final)
        );

    regfile rf (
            .clk            (clk),
            .we             (we_reg),
            .ra1            (instr[25:21]),
            .ra2            (instr[20:16]),
            .ra3            (ra3),
            .wa             (rf_wa_final),
            .wd             (wd_rf),
            .rd1            (alu_pa),
            .rd2            (wd_dm),
            .rd3            (rd3),
            .rst            (rst)
        );

    signext se (
            .a              (instr[15:0]),
            .y              (sext_imm)
        );

    // --- ALU Logic --- //
    mux2 #(32) alu_pb_mux (
            .sel            (alu_src),
            .a              (wd_dm),
            .b              (sext_imm),
            .y              (alu_pb)
        );

    alu alu (
            .op             (alu_ctrl),
            .a              (alu_pa),
            .b              (alu_pb),
            .shamt          (instr[10:6]),
            .zero           (zero),
            .y              (alu_out)
        );

    // --- HILO Logic --- //
    multu mult_unit (
            .a              (alu_pa),
            .b              (wd_dm),
            .hi             (mult_hi),
            .lo             (mult_lo)
        );

    hilo hilo_regs (
            .clk            (clk),
            .rst            (rst),
            .we_hi          (we_hi),
            .we_lo          (we_lo),
            .d_hi           (mult_hi),
            .d_lo           (mult_lo),
            .q_hi           (hi_out),
            .q_lo           (lo_out)
        );

    // Select between HI and LO for MFHI/MFLO
    mux2 #(32) hilo_sel_mux (
            .sel            (instr[1]),  // MFHI has funct[1]=0, MFLO has funct[1]=1
            .a              (hi_out),
            .b              (lo_out),
            .y              (hilo_data)
        );

    // --- MEM Logic --- //
    mux2 #(32) rf_wd_mux1 (
            .sel            (dm2reg),
            .a              (alu_out),
            .b              (rd_dm),
            .y              (wd_rf_pre)
        );

    mux2 #(32) rf_wd_mux2 (
            .sel            (hilo_to_reg),
            .a              (wd_rf_pre),
            .b              (hilo_data),
            .y              (wd_rf_pre2)
        );

    // JAL stores PC+4 in $ra
    wire [31:0] wd_rf_pre2;
    mux2 #(32) jal_wd_mux (
            .sel            (jal),
            .a              (wd_rf_pre2),
            .b              (pc_plus4),
            .y              (wd_rf)
        );

endmodule