`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.06.2025 
// Design Name: 
// Module Name: decode_cycle
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module Main_Decoder(Op,RegWrite,ImmSrc,ALUSrc,MemWrite,ResultSrc,Branch,ALUOp);
    input [6:0]Op;
    output RegWrite,ALUSrc,MemWrite,ResultSrc,Branch;
    output [1:0]ImmSrc,ALUOp;

    assign RegWrite = (Op == 7'b0000011 | Op == 7'b0110011 | Op == 7'b0010011 ) ? 1'b1 :
                                                              1'b0 ;
    assign ImmSrc = (Op == 7'b0100011) ? 2'b01 : 
                    (Op == 7'b1100011) ? 2'b10 :    
                                         2'b00 ;
    assign ALUSrc = (Op == 7'b0000011 | Op == 7'b0100011 | Op == 7'b0010011) ? 1'b1 :
                                                            1'b0 ;
    assign MemWrite = (Op == 7'b0100011) ? 1'b1 :
                                           1'b0 ;
    assign ResultSrc = (Op == 7'b0000011 ) ? 1'b1 :
                                            1'b0 ;
    assign Branch = (Op == 7'b1100011) ? 1'b1 :
                                         1'b0 ;
    assign ALUOp = (Op == 7'b0110011) ? 2'b10 :
                   (Op == 7'b1100011) ? 2'b01 :
                   (Op == 7'b0010011) ? 2'b11 :
                                        2'b00 ;
endmodule

module ALU_Decoder(ALUOp,funct3,funct7,op,ALUControl);

    input [1:0]ALUOp;
    input [2:0]funct3;
    input [6:0]funct7,op;
    output reg [2:0]ALUControl;

    // Method 1 
    // assign ALUControl = (ALUOp == 2'b00) ? 3'b000 :
    //                     (ALUOp == 2'b01) ? 3'b001 :
    //                     (ALUOp == 2'b10) ? ((funct3 == 3'b000) ? ((({op[5],funct7[5]} == 2'b00) | ({op[5],funct7[5]} == 2'b01) | ({op[5],funct7[5]} == 2'b10)) ? 3'b000 : 3'b001) : 
    //                                         (funct3 == 3'b010) ? 3'b101 : 
    //                                         (funct3 == 3'b110) ? 3'b011 : 
    //                                         (funct3 == 3'b111) ? 3'b010 : 3'b000) :
    //                                        3'b000;

    // Method 2
    // assign ALUControl = (ALUOp == 2'b00) ? 3'b000 :
    //                     (ALUOp == 2'b01) ? 3'b001 :
    //                     ((ALUOp == 2'b10) & (funct3 == 3'b000) & ({op[5],funct7[5]} == 2'b11)) ? 3'b001 : 
    //                     ((ALUOp == 2'b10) & (funct3 == 3'b000) & ({op[5],funct7[5]} != 2'b11)) ? 3'b000 : 
    //                     ((ALUOp == 2'b10) & (funct3 == 3'b010)) ? 3'b101 :
    //                     ((ALUOp == 2'b10) & (funct3 == 3'b100)) ? 3'b110 :  
    //                     ((ALUOp == 2'b10) & (funct3 == 3'b110)) ? 3'b011 : 
    //                     ((ALUOp == 2'b10) & (funct3 == 3'b111)) ? 3'b010 :
    //                                                               3'b000 ;

    always @(*) begin
    case (ALUOp)
        2'b00: ALUControl = 3'b000;             // addition
        2'b01: ALUControl = 3'b001;             // subtraction
        default:
            case (funct3) // R-type or I-type ALU
                3'b000: begin
                    // True for R-type subtract
                    if   (funct7[5] & op[5]) ALUControl = 3'b001; //sub
                    else ALUControl = 3'b000; // add, addi
                end
                3'b001:  ALUControl = 3'b100; //sll, slli
                3'b010:  ALUControl = 3'b101; // slt, slti
                // 3'b011:  ALUControl = 4'b0101; // sltu, sltiu (doubtful)
                3'b100:  ALUControl = 3'b110; // xor, xori
                // 3'b101: begin
                //     if (funct7b5) ALUControl = 4'b0111; // srl, srli
                //     else ALUControl = 4'b1000;          // sra, srai
                // end
                3'b110:  ALUControl = 3'b011; // or, ori
                3'b111:  ALUControl = 3'b010; // and, andi
                default: ALUControl = 3'bxxx; // ???
            endcase
    endcase
end

endmodule

module Control_Unit_Top(Op,RegWrite,ImmSrc,ALUSrc,MemWrite,ResultSrc,Branch,funct3,funct7,ALUControl);

    input [6:0]Op,funct7;
    input [2:0]funct3;
    output RegWrite,ALUSrc,MemWrite,ResultSrc,Branch;
    output [1:0]ImmSrc;
    output [2:0]ALUControl;

    wire [1:0]ALUOp;

    Main_Decoder Main_Decoder(
                .Op(Op),
                .RegWrite(RegWrite),
                .ImmSrc(ImmSrc),
                .MemWrite(MemWrite),
                .ResultSrc(ResultSrc),
                .Branch(Branch),
                .ALUSrc(ALUSrc),
                .ALUOp(ALUOp)
    );

    ALU_Decoder ALU_Decoder(
                            .ALUOp(ALUOp),
                            .funct3(funct3),
                            .funct7(funct7),
                            .op(Op),
                            .ALUControl(ALUControl)
    );
endmodule

module imm_extend (
    input  [31:7]     instr,
    input  [ 1:0]     immsrc,
    output reg [31:0] immext
);
always @(*) begin
    case(immsrc)
        // I-type
        2'b00:   immext = {{20{instr[31]}}, instr[31:20]};
        // S-type (stores)
        2'b01:   immext = {{20{instr[31]}}, instr[31:25], instr[11:7]};
        //B-type (branches)
         2'b10:   immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
        // J-type (jal)
        // 2'b11:   immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
        default: immext = 32'h00000000; // undefined
    endcase
end

endmodule

module Register_File(clk,rst,WE3,WD3,A1,A2,A3,RD1,RD2);

    input clk,rst,WE3;
    input [4:0]A1,A2,A3;
    input [31:0]WD3;
    output [31:0]RD1,RD2;

    reg [31:0] Register [31:0];
    wire [31:0]reg5;

    always @ (posedge clk)
    begin
        if(WE3 & (A3 != 5'h00))
            Register[A3] <= WD3;
    end

    assign RD1 = (rst==1'b0) ? 32'd0 : Register[A1];
    assign RD2 = (rst==1'b0) ? 32'd0 : Register[A2];

    initial begin
        Register[0] = 32'h00000000;
    end

    

endmodule



module decode_cycle (
    input clk,
    input rst,
    input RegwriteW, 
    input [31:0]instrD,PCD,PCplus4D,ResultW,
    input [4:0]RDW,
    output RegwriteE,ALUsrcE,MemwriteE,BranchE,ResultsrcE,
    output [2:0] ALUcontrolE,
    output [31:0] RD1E,RD2E,PCE,PCplus4E,ImmextE,
    output [4:0] RdE,RS1E,RS2E
);
//declaring wires
wire RegwriteD,ALUsrcD,MemwriteD,BranchD,ResultsrcD;
wire [1:0] ImmsrcD;
wire [2:0] ALUcontrolD;
wire [31:0] RD1_D,RD2_D,ImmextD;

//declaring intermediate registers
reg RegwriteD_r,ALUsrcD_r,MemwriteD_r,BranchD_r,ResultsrcD_r;
reg [2:0] ALUcontrolD_r;
reg [31:0] RS1D_r,RS2D_r,RD1D_r,RD2D_r,PCD_r,PCplus4D_r,ImmextD_r;
reg [4:0] RdD_r;
Control_Unit_Top control_unit(
                        .Op(instrD[6:0]),
                        .RegWrite(RegwriteD),
                        .ImmSrc(ImmsrcD),
                        .ALUSrc(ALUsrcD),
                        .MemWrite(MemwriteD),
                        .ResultSrc(ResultSrcD),
                        .Branch(BranchD),
                        .funct3(instrD[14:12]),
                        .funct7(instrD[31:25]),
                        .ALUControl(ALUcontrolD)
                        );

Register_File reg_file(.clk(clk),
                  .rst(rst),
                  .WE3(RegwriteW),
                  .WD3(ResultW),
                  .A1(instrD[19:15]),
                  .A2(instrD[24:20]),
                  .A3(RDW),
                  .RD1(RD1_D),
                  .RD2(RD2_D)
                  );

imm_extend sign_extender(.instr(instrD[31:7]),
                         .immsrc(ImmsrcD),
                         .immext(ImmextD));

always @(posedge clk or negedge rst) begin
    if(rst==1'b0)begin
            RegwriteD_r <= 1'b0;
            ALUsrcD_r <= 1'b0;
            MemwriteD_r <= 1'b0;
            ResultsrcD_r <= 1'b0;
            BranchD_r <= 1'b0;
            ALUcontrolD_r <= 3'b000;
            RD1D_r <= 32'h00000000; 
            RD2D_r <= 32'h00000000; 
            ImmextD_r <= 32'h00000000;
            RdD_r <= 5'b00000;
            PCD_r <= 32'h00000000; 
            PCplus4D_r <= 32'h00000000;
            RS1D_r<=5'b00000;
            RS2D_r<=5'b00000;
    end
    
    else begin
            RegwriteD_r <=RegwriteD;
            ALUsrcD_r <= ALUsrcD;
            MemwriteD_r <= MemwriteD;
            ResultsrcD_r <= ResultSrcD;
            BranchD_r <= BranchD;
            ALUcontrolD_r <=ALUcontrolD;
            RD1D_r <=RD1_D; 
            RD2D_r <=RD2_D; 
            ImmextD_r <=ImmextD;
            RdD_r <=instrD[11:7];
            PCD_r <=PCD; 
            PCplus4D_r <=PCplus4D;
            RS1D_r<=instrD[19:15];
            RS2D_r<=instrD[24:20];
    end
end

    assign RegwriteE = RegwriteD_r;
    assign ALUsrcE = ALUsrcD_r;
    assign MemwriteE = MemwriteD_r;
    assign ResultsrcE = ResultsrcD_r;
    assign BranchE = BranchD_r;
    assign ALUcontrolE = ALUcontrolD_r;
    assign RD1E = RD1D_r;
    assign RD2E = RD2D_r;
    assign ImmextE = ImmextD_r;
    assign RdE = RdD_r;
    assign PCE = PCD_r;
    assign PCplus4E = PCplus4D_r;
    assign RS1E=RS1D_r;
    assign RS2E=RS2D_r;
    

  
endmodule
