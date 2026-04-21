`timescale 1ns / 1ps

module InstructionRegister(
    input [7:0] I,
    input Write,
    input LH,
    input Clock,
    output reg [15:0] IROut
);
    always @(posedge Clock) begin
        if(Write) begin
            case(LH)
                1'b0: IROut[7:0] <= I;
                1'b1: IROut[15:8] <= I;
                default: IROut <= IROut;
            endcase
        end
    end
endmodule