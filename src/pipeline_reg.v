// CMPE 140 Lab 8: Pipeline Register Module
// Generic pipeline register with stall and flush capability

module pipeline_reg #(parameter WIDTH = 32)
                    (input clk, reset, stall,
                     input [WIDTH-1:0] d,
                     output reg [WIDTH-1:0] q);

    always @(posedge clk) begin
        if (reset)
            q <= 0;
        else if (~stall)  // Only update when not stalled
            q <= d;
        // When stall=1, q retains its current value
    end

endmodule