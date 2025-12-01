module auxdec (
        input  wire [1:0] alu_op,
        input  wire [5:0] funct,
        output wire [2:0] alu_ctrl,
        output wire       we_hi,
        output wire       we_lo,
        output wire       hilo_to_reg,
        output wire       jr
    );

    reg [2:0] ctrl;
    reg       hi_we, lo_we, hilo_sel, jump_reg;

    assign alu_ctrl = ctrl;
    assign we_hi = hi_we;
    assign we_lo = lo_we;
    assign hilo_to_reg = hilo_sel;
    assign jr = jump_reg;

    always @ (alu_op, funct) begin
        // Default values
        ctrl = 3'b010;       // Default to ADD
        hi_we = 1'b0;
        lo_we = 1'b0;
        hilo_sel = 1'b0;
        jump_reg = 1'b0;
        
        case (alu_op)
            2'b00: ctrl = 3'b010;          // ADD for I-type
            2'b01: ctrl = 3'b110;          // SUB for BEQ
            2'b11: ctrl = 3'b111;          // SLT for SLTI
            default: case (funct)
                6'b00_0000: begin          // SLL
                    ctrl = 3'b011;
                end
                6'b00_0010: begin          // SRL
                    ctrl = 3'b100;
                end
                6'b00_1000: begin          // JR
                    ctrl = 3'b010;         // Don't care for ALU
                    jump_reg = 1'b1;
                end
                6'b01_0000: begin          // MFHI
                    ctrl = 3'b010;         // Don't care for ALU
                    hilo_sel = 1'b1;
                end
                6'b01_0010: begin          // MFLO
                    ctrl = 3'b010;         // Don't care for ALU
                    hilo_sel = 1'b1;
                end
                6'b01_1001: begin          // MULTU
                    ctrl = 3'b010;         // Don't care for ALU
                    hi_we = 1'b1;
                    lo_we = 1'b1;
                end
                6'b10_0000: ctrl = 3'b010; // ADD
                6'b10_0010: ctrl = 3'b110; // SUB
                6'b10_0100: ctrl = 3'b000; // AND
                6'b10_0101: ctrl = 3'b001; // OR
                6'b10_1010: ctrl = 3'b111; // SLT
                default:    ctrl = 3'bxxx;
            endcase
        endcase
    end

endmodule