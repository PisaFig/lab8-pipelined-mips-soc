// CMPE 140 Lab 8: GPIO Controller
// Memory-mapped I/O controller for Basys-3 board

module gpio(
    input clk, reset,
    input [5:0] addr,          // Address within GPIO space
    input [31:0] din,          // Data input
    output reg [31:0] dout,    // Data output
    input we,                  // Write enable
    
    // Basys-3 I/O
    input [15:0] switches,
    input [4:0] buttons,
    output [15:0] leds,
    output [7:0] seg_data,
    output [3:0] seg_select
);

    // GPIO register map:
    // 0x00: LED control register
    // 0x04: Switch input register (read-only)
    // 0x08: Button input register (read-only) 
    // 0x0C: 7-segment display data register
    // 0x10: 7-segment display select register

    reg [31:0] led_reg;
    reg [31:0] seg_data_reg;
    reg [3:0] seg_select_reg;
    
    // 7-segment display multiplexing
    reg [1:0] seg_counter;
    reg [15:0] clk_div;
    
    always @(posedge clk) begin
        if (reset) begin
            clk_div <= 0;
            seg_counter <= 0;
        end else begin
            clk_div <= clk_div + 1;
            if (clk_div == 0)  // Divide clock for display refresh
                seg_counter <= seg_counter + 1;
        end
    end
    
    // Register write operations
    always @(posedge clk) begin
        if (reset) begin
            led_reg <= 32'h0;
            seg_data_reg <= 32'h0;
            seg_select_reg <= 4'h0;
        end else if (we) begin
            case (addr)
                6'h00: led_reg <= din;
                6'h03: seg_data_reg <= din;
                6'h04: seg_select_reg <= din[3:0];
                default: ; // Do nothing for read-only or undefined addresses
            endcase
        end
    end
    
    // Register read operations
    always @(*) begin
        case (addr)
            6'h00: dout = led_reg;
            6'h01: dout = {16'h0, switches};
            6'h02: dout = {27'h0, buttons};
            6'h03: dout = seg_data_reg;
            6'h04: dout = {28'h0, seg_select_reg};
            default: dout = 32'h0;
        endcase
    end
    
    // Output assignments
    assign leds = led_reg[15:0];
    assign seg_data = seg_data_reg[7:0];
    assign seg_select = ~seg_select_reg;  // Active low for Basys-3

endmodule