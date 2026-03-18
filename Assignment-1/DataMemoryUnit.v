`timescale 1ns / 1ps

module DataMemoryUnit(
    input [7:0] I,
    input [15:0] Address,
    input WR, //Read = 0, Write = 1
    input CS, // Unit is enable when cs = 1 
    input FunSel,
    input Clock,
    output [15:0] DMUOut
);
    wire [7:0] memOut; // Also DR input
    DataMemory DM (.Address(Address), .Data(I), .WR(WR), .CS(~CS), .Clock(Clock), .MemOut(memOut));
    DataRegister DR (.Clock(Clock), .I(memOut), .E(~WR && CS), .FunSel(FunSel), .DROut(DMUOut));
endmodule