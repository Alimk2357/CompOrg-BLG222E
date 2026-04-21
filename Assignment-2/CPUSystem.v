`timescale 1ns / 1ps

module CPUSystem(
    input Clock,
    input Reset,
    output reg [11:0] T
);
    reg [2:0] RF_OutASel;
    reg [2:0] RF_OutBSel;
    reg [1:0] RF_FunSel;
    reg [3:0] RF_RegSel;
    reg [3:0] RF_ScrSel;
    reg [3:0] ALU_FunSel;
    reg ALU_WF;
    reg [1:0] ARF_OutCSel;
    reg [1:0] ARF_FunSel;
    reg [2:0] ARF_RegSel;
    reg ARF_OutDSel;
    reg IMU_CS;
    reg IMU_LH;
    reg DMU_WR;
    reg DMU_CS;
    reg DMU_FunSel;
    reg [1:0] MuxASel, MuxBSel;
    reg MuxCSel;
    reg T_Reset; // to reset counter

    wire [15:0] IROut;
    wire [3:0] FlagsOut;

    ArithmeticLogicUnitSystem ALUSys(.RF_OutASel(RF_OutASel), .RF_OutBSel(RF_OutBSel),
        .RF_FunSel(RF_FunSel), .RF_RegSel(RF_RegSel), .RF_ScrSel(RF_ScrSel),
        .ALU_FunSel(ALU_FunSel), .ALU_WF(ALU_WF), .ARF_OutCSel(ARF_OutCSel),
        .ARF_FunSel(ARF_FunSel), .ARF_RegSel(ARF_RegSel), .ARF_OutDSel(ARF_OutDSel),
        .IMU_CS(IMU_CS), .IMU_LH(IMU_LH), .DMU_WR(DMU_WR), .DMU_CS(DMU_CS),
        .DMU_FunSel(DMU_FunSel), .MuxASel(MuxASel), .MuxBSel(MuxBSel),
        .MuxCSel(MuxCSel), .Clock(Clock), .IROut(IROut), .FlagsOut(FlagsOut));

    wire [5:0] Opcode;
    wire [1:0] RegSel;
    wire [2:0] DestReg;
    wire [2:0] SrcReg1, SrcReg2;
    wire [7:0] Address = IROut[7:0];
    
    assign Opcode = IROut[15:10];
    assign RegSel = IROut[9:8];
    assign DestReg = IROut[9:7];
    assign SrcReg1 = IROut[6:4];
    assign SrcReg2 = IROut[3:1];
    
    // T'nin güncellendiği blok
    always @(posedge Clock) begin
        if (T_Reset || !Reset) begin
            T <= 12'b000000000001;
        end else begin
            T <= T << 1; // next state
        end
    end

    wire is_sreg1_rf = SrcReg1[2];
    wire is_sreg2_rf = SrcReg2[2];
    wire is_dstreg_rf = DestReg[2];
    
    // Src1 ve/veya Src2 RF'de ise kullanılacak
    wire [2:0] src1_OutASel = {1'b0, SrcReg1[1:0]};
    wire [2:0] src2_OutBSel = {1'b0, SrcReg2[1:0]};

    // Src1 ve/veya Src2 ARF'de ise kullanılacak
    wire [1:0] src1_OutCSel = SrcReg1[1:0];
    wire [1:0] src2_OutCSel = SrcReg2[1:0];


    wire [2:0] alu_A_sel = is_sreg1_rf ? src1_OutASel : 3'b100; // 100=S1
    wire [2:0] alu_B_sel = is_sreg2_rf ? src2_OutBSel : 3'b101; // 101=S2

    // Dst RF'de ise kullanılacak
    reg [3:0] dst_RF_RegSel;
    always @(*) begin
        case(DestReg[1:0])
            2'b00: dst_RF_RegSel = 4'b0111;
            2'b01: dst_RF_RegSel = 4'b1011;
            2'b10: dst_RF_RegSel = 4'b1101;
            2'b11: dst_RF_RegSel = 4'b1110;
        endcase
    end

    // Dst ARF'de ise kullanılacak
    reg [2:0] dst_ARF_RegSel;
    always @(*) begin
        case(DestReg[1:0])
            2'b00: dst_ARF_RegSel = 3'b011;
            2'b01: dst_ARF_RegSel = 3'b011;
            2'b10: dst_ARF_RegSel = 3'b110;
            2'b11: dst_ARF_RegSel = 3'b101;
        endcase
    end
    
    reg [3:0] alu_funsel;
    always @(*) begin
        case(Opcode) 
            6'h07, 6'h08: alu_funsel = 4'b0000;
            6'h09: alu_funsel = 4'b1011;
            6'h0A: alu_funsel = 4'b1100;
            6'h0B: alu_funsel = 4'b1101;
            6'h0C: alu_funsel = 4'b1110;
            6'h0D: alu_funsel = 4'b1111;
            6'h0E: alu_funsel = 4'b0010; 
            6'h0F: alu_funsel = 4'b0111; // and
            6'h10: alu_funsel = 4'b1000; // or
            6'h11: alu_funsel = 4'b1001; // xor
            6'h12: alu_funsel = 4'b1010; // nand
            6'h13: alu_funsel = 4'b0100; // add
            6'h14: alu_funsel = 4'b0101; // adc
            6'h15: alu_funsel = 4'b0110; // sub
            6'h16: alu_funsel = 4'b0000; 
            default: alu_funsel = 4'b0000;
        endcase
    end

    // ana blok
    always @(*) begin
        RF_OutASel = src1_OutASel;   
        RF_FunSel = 2'b01;    
        RF_ScrSel = 4'b1111; 
        ALU_FunSel = alu_funsel;  
        ARF_OutCSel = 2'b00;    
        ARF_RegSel = 3'b111;   
        IMU_CS = 0;        
        DMU_WR = 0;        
        DMU_FunSel = 0;        
        MuxBSel = 2'b00;    
        T_Reset = 0;  
        RF_OutBSel = src2_OutBSel;
        RF_RegSel = 4'b1111;
        ALU_WF = 0;
        ARF_FunSel = 2'b01;
        ARF_OutDSel = 0;
        IMU_LH = 0;
        DMU_CS = 0;
        MuxASel = 2'b00;
        MuxCSel = 0;

        if (!Reset) begin
            // ARF ve RF içindeki tüm registerlar 0 (Clear) yapılır
            ARF_FunSel <= 2'b00;
            ARF_RegSel <= 3'b000;
            RF_FunSel <= 2'b00;
            RF_RegSel <= 4'b0000;
            RF_ScrSel <= 4'b0000;
            // reset, low-active'dir
        end else begin
            if(T[0]) begin
                // IR [7:0] <- ROM[PC], PC++
                IMU_LH = 0;
                IMU_CS = 1;
                ARF_RegSel = 3'b011; // only pc is enabled
                ARF_FunSel = 2'b10; // increment pc
            end

            if(T[1]) begin
                // IR [15:8] <- ROM[PC], PC++
                IMU_LH = 1;
                IMU_CS = 1;
                ARF_RegSel = 3'b011;
                ARF_FunSel = 2'b10;
            end

            if(T[2]) begin
                case(Opcode)
                    6'h00: begin
                        // PC <- VALUE
                        ARF_FunSel = 2'b01;
                        ARF_RegSel = 3'b011;
                        MuxBSel = 2'b11;
                        T_Reset = 1;
                    end
                    6'h01: begin
                        if(!FlagsOut[3]) begin
                            ARF_FunSel = 2'b01;
                            ARF_RegSel = 3'b011;
                            MuxBSel = 2'b11;
                        end
                        T_Reset = 1;
                    end
                    6'h02: begin
                        if(FlagsOut[3]) begin
                            ARF_FunSel = 2'b01;
                            ARF_RegSel = 3'b011;
                            MuxBSel = 2'b11;
                        end
                        T_Reset = 1;
                    end
                    6'h03: begin
                        if(FlagsOut[1] != FlagsOut[0]) begin
                            ARF_FunSel = 2'b01;
                            ARF_RegSel = 3'b011;
                            MuxBSel = 2'b11;
                        end
                        T_Reset = 1;
                    end
                    6'h04: begin
                        if(FlagsOut[1] == FlagsOut[0] && !FlagsOut[3]) begin
                            ARF_FunSel = 2'b01;
                            ARF_RegSel = 3'b011;
                            MuxBSel = 2'b11;
                        end
                        T_Reset = 1;
                    end
                    6'h05: begin
                        if(FlagsOut[1] != FlagsOut[0] || FlagsOut[3]) begin
                            ARF_FunSel = 2'b01;
                            ARF_RegSel = 3'b011;
                            MuxBSel = 2'b11;
                        end
                        T_Reset = 1;
                    end
                    6'h06: begin
                        if(FlagsOut[1] == FlagsOut[0]) begin
                            ARF_FunSel = 2'b01;
                            ARF_RegSel = 3'b011;
                            MuxBSel = 2'b11;
                        end
                        T_Reset = 1;
                    end
                    6'h07, 6'h08: begin
                        // SREG1 -> S1
                        if(is_sreg1_rf) begin
                            RF_OutASel = src1_OutASel;
                            ALU_FunSel = 4'b0000;
                            MuxASel = 2'b00;
                        end
                        else begin
                            ARF_OutCSel = src1_OutCSel;
                            MuxASel = 2'b01;
                        end
                        RF_ScrSel = 4'b0111;
                        RF_FunSel = 2'b01;
                    end
                    6'h09, 6'h0A, 6'h0B, 6'h0C, 6'h0D, 6'h0E : begin
                        if(is_sreg1_rf) begin
                            // scratch registera gerek yok
                            RF_OutASel = alu_A_sel;
                            ALU_FunSel = alu_funsel;
                            ALU_WF = 1;
                            MuxASel = 2'b00;
                            MuxBSel = 2'b00;
                            RF_FunSel = 2'b01;
                            ARF_FunSel = 2'b01;
                            RF_RegSel = is_dstreg_rf ? dst_RF_RegSel : 4'b1111;
                            ARF_RegSel = is_dstreg_rf ? 3'b111 : dst_ARF_RegSel;
                            T_Reset = 1;
                        end else begin
                            // Srcreg1 ARF'tedir ve önce S1'e yüklenmelidir
                            ARF_OutCSel = src1_OutCSel;
                            MuxASel = 2'b01;
                            RF_ScrSel = 4'b0111;
                            RF_FunSel = 2'b01;
                        end
                    end
                    6'h0F, 6'h10, 6'h11, 6'h12, 6'h13, 6'h14, 6'h15: begin
                        if(is_sreg1_rf && is_sreg2_rf) begin
                            ALU_FunSel = alu_funsel;
                            ALU_WF = 1;
                            RF_OutASel = alu_A_sel;
                            RF_OutBSel = alu_B_sel;

                            ARF_RegSel = is_dstreg_rf ? 3'b111 : dst_ARF_RegSel;
                            RF_RegSel = is_dstreg_rf ? dst_RF_RegSel : 4'b1111;
                            ARF_FunSel = 2'b01;
                            RF_FunSel = 2'b01;

                            MuxASel = 2'b00;
                            MuxBSel = 2'b00;
                            T_Reset = 1;
                        end
                        else if(is_sreg1_rf && !is_sreg2_rf) begin
                            // bu cycle'da sreg2, s2'ye yüklenir
                            ARF_OutCSel = src2_OutCSel;
                            MuxASel = 2'b01;
                            RF_ScrSel = 4'b1011; // sadece s2 aktifleşir
                            RF_FunSel = 2'b01;
                        end
                        else begin
                            // bu cycle'da sreg1, s1'e yüklenir
                            // bu cycle, hem SrcReg1'in ve SrcReg2'nin beraber
                            // ARF'de bulunduğu durum için hem de sadece SrcReg1'in
                            // ARF'de bulunduğu durum için ortaktır
                            ARF_OutCSel = src1_OutCSel;
                            MuxASel = 2'b01;
                            RF_ScrSel = 4'b0111; // sadece s1 aktifleşir
                            RF_FunSel = 2'b01;
                        end
                    end
                    6'h16: begin
                        // copy SREG1 to DSTREG
                        RF_OutASel = src1_OutASel;
                        ALU_FunSel = alu_funsel;
                        ARF_OutCSel = src1_OutCSel;

                        ARF_FunSel = 2'b01;
                        RF_FunSel = 2'b01;
                        ARF_RegSel = is_dstreg_rf ? 3'b111 : dst_ARF_RegSel;
                        RF_RegSel = is_dstreg_rf ? dst_RF_RegSel : 4'b1111;

                        // Route to DSTREG
                        // DSTREG in RF: MuxA path
                        // DSTREG in ARF: MuxB path
                        MuxASel = is_sreg1_rf ? 2'b00 : 2'b01;
                        MuxBSel = is_sreg1_rf ? 2'b00 : 2'b01;

                        T_Reset = 1;
                    end
                    6'h17: begin
                        // Load IMUOut into Rx (RF) which is selected by RSEL
                        // in the 1st type of instruction
                        RF_FunSel = 2'b01;
                        MuxASel = 2'b11;
                        case(RegSel)
                            2'b00: RF_RegSel = 4'b0111;
                            2'b01: RF_RegSel = 4'b1011;
                            2'b10: RF_RegSel = 4'b1101;
                            2'b11: RF_RegSel = 4'b1110;
                        endcase
                        T_Reset = 1;
                    end
                endcase
            end

            if(T[3]) begin
                case(Opcode)
                    6'h07, 6'h08: begin
                        // clear S2 to perform A + 1 on ALU
                        RF_ScrSel = 4'b1011;
                        RF_FunSel = 2'b00;
                    end
                    6'h09, 6'h0A, 6'h0B, 6'h0C, 6'h0D, 6'h0E: begin
                        // scratch registerdan ALU'ya
                        RF_OutASel = alu_A_sel;
                        ALU_FunSel = alu_funsel;
                        ALU_WF = 1;
                        ARF_RegSel = is_dstreg_rf ? 3'b111 : dst_ARF_RegSel;
                        RF_RegSel = is_dstreg_rf ? dst_RF_RegSel : 4'b1111;
                        ARF_FunSel = 2'b01;
                        RF_FunSel = 2'b01;
                        T_Reset = 1;
                        MuxASel = 2'b00;
                        MuxBSel = 2'b00;
                    end
                    6'h0f, 6'h10, 6'h11, 6'h12, 6'h13, 6'h14, 6'h15: begin
                        if(is_sreg1_rf || is_sreg2_rf) begin
                            // bu statement SrcReg1 ve SrcReg2'ten birinin ARF'de
                            // olduğu durum içindir
                            // bu cycleda ALU işlemi yapılıp sonuc DestReg'e yüklenir
                            ALU_FunSel = alu_funsel;
                            ALU_WF = 1;
                            RF_OutASel = alu_A_sel;
                            RF_OutBSel = alu_B_sel;

                            ARF_RegSel = is_dstreg_rf ? 3'b111 : dst_ARF_RegSel;
                            RF_RegSel = is_dstreg_rf ? dst_RF_RegSel : 4'b1111;
                            ARF_FunSel = 2'b01;
                            RF_FunSel = 2'b01;

                            MuxASel = 2'b00;
                            MuxBSel = 2'b00;
                            T_Reset = 1;
                        end 
                        else begin
                            // Hem SrcReg1 hem de SrcReg2 ARF'de olduğu durum
                            // bu cycleda SrcReg2, S2'ye yüklenir
                            ARF_OutCSel = src2_OutCSel;
                            MuxASel = 2'b01;
                            RF_ScrSel = 4'b1011; // sadece s2 aktifleşir
                            RF_FunSel = 2'b01;
                        end
                    end
                endcase
            end

            if(T[4]) begin
                case (Opcode)
                    6'h07, 6'h08: begin
                        // increment s2 from 0 to 1
                        RF_ScrSel = 4'b1011;
                        RF_FunSel = 2'b10; 
                    end 
                    6'h0f, 6'h10, 6'h11, 6'h12, 6'h13, 6'h14, 6'h15: begin
                            // bu statement hem SrcReg1 hem de SrcReg2'in ARF'de
                            // olduğu durum içindir
                            // bu cycleda ALU işlemi yapılıp sonuc DestReg'e yüklenir
                            ALU_FunSel = alu_funsel;
                            ALU_WF = 1;
                            RF_OutASel = alu_A_sel;
                            RF_OutBSel = alu_B_sel;

                            ARF_RegSel = is_dstreg_rf ? 3'b111 : dst_ARF_RegSel;
                            RF_RegSel = is_dstreg_rf ? dst_RF_RegSel : 4'b1111;
                            ARF_FunSel = 2'b01;
                            RF_FunSel = 2'b01;

                            MuxASel = 2'b00;
                            MuxBSel = 2'b00;
                            T_Reset = 1;
                    end
                endcase
            end

            if(T[5]) begin
                case(Opcode)
                    6'h07: begin
                        RF_OutASel = 3'b100;
                        RF_OutBSel = 3'b101;
                        ALU_FunSel = 4'b0100;
                        ALU_WF = 1;
                        MuxASel = 2'b00;
                        MuxBSel = 2'b00;
                        RF_FunSel = 2'b01;
                        ARF_FunSel = 2'b01;
                        RF_RegSel = is_dstreg_rf ? dst_RF_RegSel  : 4'b1111;
                        ARF_RegSel = is_dstreg_rf ? 3'b111 : dst_ARF_RegSel;
                        T_Reset = 1;
                    end
                    6'h08: begin  // DEC: SUB(S1, S2=1)
                        RF_OutASel = 3'b100;
                        RF_OutBSel = 3'b101;
                        ALU_FunSel = 4'b0110;
                        ALU_WF = 1;
                        MuxASel = 2'b00;
                        MuxBSel = 2'b00;
                        RF_FunSel = 2'b01;
                        ARF_FunSel = 2'b01;
                        RF_RegSel = is_dstreg_rf ? dst_RF_RegSel  : 4'b1111;
                        ARF_RegSel = is_dstreg_rf ? 3'b111 : dst_ARF_RegSel;
                        T_Reset = 1;
                    end
                endcase
            end
        end
    end
endmodule