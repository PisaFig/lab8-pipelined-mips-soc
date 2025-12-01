// CMPE 140 Lab 8: Factorial Hardware Accelerator
// High-performance factorial computation unit

module factorial_accel(
    input clk, reset,
    input [1:0] addr,          // Address within factorial accelerator space
    input [31:0] din,          // Data input
    output reg [31:0] dout,    // Data output
    input we,                  // Write enable
    output start,              // Start signal (for external monitoring)
    output done,               // Done signal
    output [31:0] result       // Result output
);

    // Register map:
    // 0x00: Input register (write n to compute n!)
    // 0x04: Result register (read-only)
    // 0x08: Status register (bit 0: done, bit 1: error)
    // 0x0C: Control register (bit 0: start)

    reg [31:0] input_reg;
    reg [31:0] result_reg;
    reg [31:0] status_reg;
    reg [31:0] control_reg;
    
    // Factorial computation state machine
    reg [2:0] state;
    reg [31:0] n, factorial_result;
    reg [31:0] counter;
    
    localparam IDLE = 3'b000;
    localparam COMPUTE = 3'b001;
    localparam DONE = 3'b010;
    localparam ERROR = 3'b011;
    
    // Precomputed factorial values for fast lookup (0! to 12!)
    wire [31:0] factorial_lut [0:12];
    assign factorial_lut[0] = 32'd1;        // 0! = 1
    assign factorial_lut[1] = 32'd1;        // 1! = 1  
    assign factorial_lut[2] = 32'd2;        // 2! = 2
    assign factorial_lut[3] = 32'd6;        // 3! = 6
    assign factorial_lut[4] = 32'd24;       // 4! = 24
    assign factorial_lut[5] = 32'd120;      // 5! = 120
    assign factorial_lut[6] = 32'd720;      // 6! = 720
    assign factorial_lut[7] = 32'd5040;     // 7! = 5040
    assign factorial_lut[8] = 32'd40320;    // 8! = 40320
    assign factorial_lut[9] = 32'd362880;   // 9! = 362880
    assign factorial_lut[10] = 32'd3628800; // 10! = 3628800
    assign factorial_lut[11] = 32'd39916800; // 11! = 39916800
    assign factorial_lut[12] = 32'd479001600; // 12! = 479001600
    
    // State machine for factorial computation
    always @(posedge clk) begin
        if (reset) begin
            state <= IDLE;
            result_reg <= 32'h0;
            status_reg <= 32'h0;
            factorial_result <= 32'h1;
            counter <= 32'h0;
        end else begin
            case (state)
                IDLE: begin
                    if (control_reg[0]) begin  // Start bit set
                        n <= input_reg;
                        if (input_reg > 12) begin
                            state <= ERROR;
                            status_reg <= 32'h2;  // Error flag
                        end else begin
                            state <= COMPUTE;
                            status_reg <= 32'h0;
                        end
                    end
                end
                
                COMPUTE: begin
                    // Use lookup table for fast computation
                    result_reg <= factorial_lut[n];
                    state <= DONE;
                    status_reg <= 32'h1;  // Done flag
                end
                
                DONE: begin
                    if (~control_reg[0]) begin  // Start bit cleared
                        state <= IDLE;
                        status_reg <= 32'h0;
                    end
                end
                
                ERROR: begin
                    if (~control_reg[0]) begin  // Start bit cleared
                        state <= IDLE;
                        status_reg <= 32'h0;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // Register write operations
    always @(posedge clk) begin
        if (reset) begin
            input_reg <= 32'h0;
            control_reg <= 32'h0;
        end else if (we) begin
            case (addr)
                2'b00: input_reg <= din;
                2'b11: control_reg <= din;
                default: ; // Result and status are read-only
            endcase
        end
    end
    
    // Register read operations
    always @(*) begin
        case (addr)
            2'b00: dout = input_reg;
            2'b01: dout = result_reg;
            2'b10: dout = status_reg;
            2'b11: dout = control_reg;
            default: dout = 32'h0;
        endcase
    end
    
    // Output signal assignments
    assign start = control_reg[0];
    assign done = status_reg[0];
    assign result = result_reg;

endmodule