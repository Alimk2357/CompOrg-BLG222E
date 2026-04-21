`timescale 1ns / 1ps

module DataRegister(
    input Clock,
    input [7:0] I,
    input E,
    input FunSel,
    output reg [15:0] DROut
);
    always @(posedge Clock) begin
        if (E) begin
            case(FunSel) 
                1'b0: DROut[7:0] <= I;
                1'b1: DROut[15:8] <= I;
                default: DROut <= DROut;
            endcase
        end
    end

endmodule