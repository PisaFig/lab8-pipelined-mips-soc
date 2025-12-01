// CMPE 140 Lab 8: Forwarding Unit
// Handles data forwarding to resolve pipeline hazards

module forwarding_unit(
    input [4:0] rsE, rtE,          // Source registers in execute stage
    input [4:0] writeregM,         // Destination register in memory stage
    input regwriteM,               // Write enable in memory stage
    input [4:0] writeregW,         // Destination register in writeback stage
    input regwriteW,               // Write enable in writeback stage
    output reg [1:0] forwardaE, forwardbE  // Forwarding control signals
);

    always @(*) begin
        // Forward for first ALU operand (rsE)
        if ((rsE != 0) && (rsE == writeregM) && regwriteM)
            forwardaE = 2'b10;  // Forward from MEM stage
        else if ((rsE != 0) && (rsE == writeregW) && regwriteW)
            forwardaE = 2'b01;  // Forward from WB stage
        else
            forwardaE = 2'b00;  // No forwarding
            
        // Forward for second ALU operand (rtE)
        if ((rtE != 0) && (rtE == writeregM) && regwriteM)
            forwardbE = 2'b10;  // Forward from MEM stage
        else if ((rtE != 0) && (rtE == writeregW) && regwriteW)
            forwardbE = 2'b01;  // Forward from WB stage
        else
            forwardbE = 2'b00;  // No forwarding
    end

endmodule