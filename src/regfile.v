module regfile (
    input  wire        clk,
    input  wire        we3,
    input  wire [4:0]  ra1,
    input  wire [4:0]  ra2,
    input  wire [4:0]  wa3,
    input  wire [31:0] wd3,
    output wire [31:0] rd1,
    output wire [31:0] rd2
);

    reg [31:0] rf [0:31];
    integer n;
    
    initial begin
        for (n = 0; n < 32; n = n + 1) 
            rf[n] = 32'h0;
        rf[29] = 32'h00000100;  // Initialize stack pointer
    end
    
    always @(posedge clk) begin
        if (we3 && (wa3 != 5'b00000))
            rf[wa3] <= wd3;
    end

    assign rd1 = (ra1 == 5'b00000) ? 32'h00000000 : rf[ra1];
    assign rd2 = (ra2 == 5'b00000) ? 32'h00000000 : rf[ra2];

endmodule