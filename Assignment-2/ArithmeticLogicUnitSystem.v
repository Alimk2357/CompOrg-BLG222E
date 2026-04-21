`timescale 1ns / 1ps

module ArithmeticLogicUnitSystem(
    input [2:0] RF_OutASel,
    input [2:0] RF_OutBSel,
    input [1:0] RF_FunSel,
    input [3:0] RF_RegSel,
    input [3:0] RF_ScrSel,
    input [3:0] ALU_FunSel,
    input ALU_WF,
    input [1:0] ARF_OutCSel,
    input [1:0] ARF_FunSel,
    input [2:0] ARF_RegSel,
    input ARF_OutDSel,
    input IMU_CS,
    input IMU_LH,
    input DMU_WR,
    input DMU_CS,
    input DMU_FunSel,
    input [1:0] MuxASel,
    input [1:0] MuxBSel,
    input MuxCSel,
    input Clock,
    output [15:0] IROut, // IROut, opcode için gerekli
    output [3:0] FlagsOut // If condition içeren microoperation'lar için
);
    wire [15:0] OutA, OutB;
    reg [15:0] MuxAOut;
    reg [15:0] MuxBOut;
    reg [7:0] MuxCOut;
    wire [15:0] ALUOut;
    wire [15:0] OutC, OutD, OutE;
    wire [15:0] DMUOut;
    wire [15:0] IMUOut;

    always @(*) begin
        case (MuxASel) 
            2'b00: MuxAOut = ALUOut;
            2'b01: MuxAOut = OutC;
            2'b10: MuxAOut = DMUOut;
            2'b11: MuxAOut = IMUOut;
        endcase
    end
    
    always @(*) begin
        case (MuxCSel)
            1'b0: MuxCOut = ALUOut[7:0];
            1'b1: MuxCOut = ALUOut[15:8];
        endcase
    end
    
    always @(*) begin
        case (MuxBSel)
            2'b00: MuxBOut = ALUOut;
            2'b01: MuxBOut = OutC;
            2'b10: MuxBOut = DMUOut;
            2'b11: MuxBOut = IMUOut;
        endcase
    end
    
    RegisterFile RF(.Clock(Clock), .I(MuxAOut), 
                    .OutASel(RF_OutASel), .OutBSel(RF_OutBSel), 
                    .FunSel(RF_FunSel), .RegSel(RF_RegSel), 
                    .ScrSel(RF_ScrSel), .OutA(OutA), .OutB(OutB));

    ArithmeticLogicUnit ALU(.A(OutA), .B(OutB), .FunSel(ALU_FunSel),
                            .WF(ALU_WF), .Clock(Clock), .FlagsOut(FlagsOut),
                            .ALUOut(ALUOut));

    AddressRegisterFile ARF(.Clock(Clock), .I(MuxBOut), .RegSel(ARF_RegSel),
                            .FunSel(ARF_FunSel), .OutCSel(ARF_OutCSel),
                            .OutDSel(ARF_OutDSel), .OutC(OutC), .OutD(OutD),
                            .OutE(OutE));

    DataMemoryUnit DMU(.I(MuxCOut), .Address(OutD), .WR(DMU_WR), .CS(DMU_CS),
                        .FunSel(DMU_FunSel), .Clock(Clock), .DMUOut(DMUOut));

    InstructionMemoryUnit IMU(.Address(OutE), .CS(IMU_CS), .LH(IMU_LH),
                              .Clock(Clock), .IMUOut(IMUOut), .IROut(IROut));
endmodule