// CMPE 140 Lab 8: Hazard Detection Unit
// Detects and handles pipeline hazards

module hazard_unit(
    input [4:0] rsD, rtD,          // Source registers in decode stage
    input [4:0] rsE, rtE,          // Source registers in execute stage
    input [4:0] writeregE,         // Destination register in execute stage
    input regwriteE, memtoregE,    // Control signals in execute stage
    input [4:0] writeregM,         // Destination register in memory stage
    input regwriteM, memtoregM,    // Write enable and memtoreg in memory stage
    input [4:0] writeregW,         // Destination register in writeback stage
    input regwriteW,               // Write enable in writeback stage
    input branchD, jumpD, jumpregD, // Control flow instructions
    output stallF, stallD, flushD, flushE
);

    wire lwstall;
    wire branchstall;
    
    // Load-use hazard detection
    assign lwstall = ((rsD == writeregE) | (rtD == writeregE)) & 
                     memtoregE & (writeregE != 0);
    
    // Branch hazard detection (need to stall for data dependencies)
    assign branchstall = (branchD | jumpregD) & 
                        (regwriteE & ((writeregE == rsD) | (writeregE == rtD)) |
                         memtoregM & ((writeregM == rsD) | (writeregM == rtD)));
    
    // Stall fetch and decode stages for load-use or branch hazards
    assign stallF = lwstall | branchstall;
    assign stallD = lwstall | branchstall;
    
    // Flush decode stage on taken branches or jumps
    assign flushD = (branchD | jumpD | jumpregD);
    
    // Flush execute stage on stalls (insert bubble)
    assign flushE = lwstall | branchstall;

endmodule