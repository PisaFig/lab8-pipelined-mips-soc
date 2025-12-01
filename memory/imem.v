module imem (
        input  wire        clk,
        input  wire [13:0] addr,
        output wire [31:0] data
    );

    reg [31:0] rom [0:16383];  // 64KB / 4 bytes = 16K words
    integer i;

    initial begin
        // Initialize all memory to NOPs first
        for (i = 0; i < 16384; i = i + 1) begin
            rom[i] = 32'h00000000;  // NOP instruction
        end
        
        // Try to read memfile.dat
        $readmemh("memfile.dat", rom);
    end

    assign data = rom[addr];
    
endmodule