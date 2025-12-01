module dmem (
        input  wire        clk,
        input  wire        we,
        input  wire [13:0] addr,
        input  wire [31:0] din,
        output wire [31:0] dout
    );

    reg [31:0] ram [0:16383];  // 64KB / 4 bytes = 16K words

    integer n;

    initial begin
        for (n = 0; n < 16384; n = n + 1) ram[n] = 32'h00000000;
    end

    always @ (posedge clk) begin
        if (we) ram[addr] <= din;
    end

    assign dout = ram[addr];
    
endmodule