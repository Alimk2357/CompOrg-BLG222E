`timescale 1ns / 1ps

module InstructionMemoryUnit(
    input [15:0] Address,
    input CS, // unit is enable when cs = 1
    input LH,
    input Clock,
    output [15:0] IMUOut,
    output [15:0] IROut
);
    wire [7:0] memOut; // also input of IR
    InstructionMemory IM (.Address(Address), .CS(~CS), .Clock(Clock), .MemOut(memOut));
    InstructionRegister IR (.I(memOut), .Write(CS), .LH(LH), .Clock(Clock), .IROut(IROut));
    assign IMUOut[15:8] = 8'b0;
    assign IMUOut[7:0] = IROut[7:0];
endmodule