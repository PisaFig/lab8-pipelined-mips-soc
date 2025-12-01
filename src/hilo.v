module hilo (
        input  wire        clk,
        input  wire        rst,
        input  wire        we_hi,
        input  wire        we_lo,
        input  wire [31:0] d_hi,
        input  wire [31:0] d_lo,
        output wire [31:0] q_hi,
        output wire [31:0] q_lo
    );

    reg [31:0] hi_reg;
    reg [31:0] lo_reg;

    always @ (posedge clk, posedge rst) begin
        if (rst) begin
            hi_reg <= 32'h0;
            lo_reg <= 32'h0;
        end
        else begin
            if (we_hi) hi_reg <= d_hi;
            if (we_lo) lo_reg <= d_lo;
        end
    end

    assign q_hi = hi_reg;
    assign q_lo = lo_reg;

endmodule