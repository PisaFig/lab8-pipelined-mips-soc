module alu (
        input  wire [31:0] a,
        input  wire [31:0] b,
        input  wire [2:0]  alucontrol,
        output reg  [31:0] aluout
    );

    always @(*) begin
        case (alucontrol)
            3'b000: aluout = a & b;           // AND
            3'b001: aluout = a | b;           // OR  
            3'b010: aluout = a + b;           // ADD
            3'b011: aluout = b << a[4:0];     // SLL (shift left logical)
            3'b100: aluout = b >> a[4:0];     // SRL (shift right logical)
            3'b110: aluout = a - b;           // SUB
            3'b111: aluout = (a < b) ? 1 : 0; // SLT (set less than)
            default: aluout = 32'h0;
        endcase
    end

endmodule