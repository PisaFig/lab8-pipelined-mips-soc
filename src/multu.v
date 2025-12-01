module multu (
        input  wire [31:0] a,
        input  wire [31:0] b,
        output wire [31:0] hi,
        output wire [31:0] lo
    );

    wire [63:0] product;

    assign product = a * b;
    assign hi = product[63:32];
    assign lo = product[31:0];

endmodule