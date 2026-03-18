`timescale 1ns / 1ps

module ArithmeticLogicUnit(
    input [15:0] A,
    input [15:0] B,
    input [3:0] FunSel,
    input WF,
    input Clock,
    output reg [15:0] ALUOut,
    output reg [3:0] FlagsOut // Zero,Carry,Negative,Overflow
);  
    reg [3:0] next_flags;
    reg [16:0] temp_out; // to detect carry
    reg [15:0] B_twos_complement; // for A - B
    always @(*) begin
        next_flags = FlagsOut;
        case (FunSel) 
            4'b0000: begin
                ALUOut = A;
                next_flags[3] = (ALUOut == 0);
                next_flags[1] = ALUOut[15];
            end
            4'b0001: begin
                ALUOut = B;
                next_flags[3] = (ALUOut == 0);
                next_flags[1] = ALUOut[15];
            end
            4'b0010: begin
                ALUOut = ~A;
                next_flags[3] = (ALUOut == 0);
                next_flags[1] = ALUOut[15];
            end
            4'b0011: begin
                ALUOut = ~B;
                next_flags[3] = (ALUOut == 0);
                next_flags[1] = ALUOut[15];
            end
            4'b0100: begin
                ALUOut = A + B;
                temp_out <= A + B;
                next_flags[3] = (ALUOut == 0);
                next_flags[1] = ALUOut[15];
                next_flags[2] = temp_out[16];
                next_flags[0] = (A[15] == B[15] && ALUOut[15] != A[15]);
            end
            4'b0101: begin
                ALUOut = A + B + FlagsOut[2];
                temp_out = A + B + FlagsOut[2];
                next_flags[3] = (ALUOut == 0);
                next_flags[1] = ALUOut[15];
                next_flags[2] = temp_out[16];
                next_flags[0] = (A[15] == (B[15] + FlagsOut[2]) && ALUOut[15] != A[15]);
            end
            4'b0110: begin
                B_twos_complement = ~B + 1;
                ALUOut = A + B_twos_complement;
                temp_out = A + B_twos_complement;
                next_flags[3] = (ALUOut == 0);
                next_flags[1] = ALUOut[15];
                next_flags[2] = temp_out[16];
                next_flags[0] = (A[15] == B_twos_complement[15] && ALUOut[15] != A[15]);
            end
            4'b0111: begin
                ALUOut = A & B;
                next_flags[3] = (ALUOut == 0);
                next_flags[1] = (ALUOut[15]);
            end
            4'b1000: begin
                ALUOut = A | B;
                next_flags[3] = (ALUOut == 0);
                next_flags[1] = (ALUOut[15]);
            end
            4'b1001: begin
                ALUOut = A ^ B;
                next_flags[3] = (ALUOut == 0);
                next_flags[1] = (ALUOut[15]);
            end
            4'b1010: begin
                ALUOut = ~(A & B);
                next_flags[3] = (ALUOut == 0);
                next_flags[1] = (ALUOut[15]);
            end            
            4'b1011: begin
                ALUOut = A << 1;
                next_flags[3] = (ALUOut == 0);
                next_flags[2] = A[15];
                next_flags[1] = (ALUOut[15]);
            end
            4'b1100: begin
                ALUOut = A >> 1;
                next_flags[3] = (ALUOut == 0);
                next_flags[2] = A[0];
                next_flags[1] = (ALUOut[15]);
            end
            4'b1101: begin
                ALUOut = A >>> 1;
                next_flags[3] = (ALUOut == 0);
            end
            4'b1110: begin
                ALUOut = {A[14:0], A[15]};
                next_flags[3] = (ALUOut == 0);
                next_flags[2] = A[15];
                next_flags[1] = (ALUOut[15]);
            end
            4'b1111: begin
                ALUOut = {A[0], A[14:0]};
                next_flags[3] = (ALUOut == 0);
                next_flags[2] = A[0];
                next_flags[1] = (ALUOut[15]);
            end
        endcase
    end

    // Flag Register
    always @(posedge Clock) begin
        if(WF) begin
            FlagsOut <= next_flags;
        end
    end
endmodule