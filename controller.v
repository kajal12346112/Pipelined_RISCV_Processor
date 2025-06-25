`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.06.2025 16:14:57
// Design Name: 
// Module Name: controller
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


// alu_decoder.v - logic for ALU decoder

module alu_decoder (
    input            opb5,
    input [2:0]      funct3,
    input            funct7b5,
    input [1:0]      ALUOp,
    output reg [3:0] ALUControl
);

always @(*) begin
    case (ALUOp)
        2'b00: ALUControl = 4'b0000;             // addition
        2'b01: ALUControl = 4'b0001;             // subtraction
        default:
            case (funct3) // R-type or I-type ALU
                3'b000: begin
                    // True for R-type subtract
                    if   (funct7b5 & opb5) ALUControl = 4'b0001; //sub
                    else ALUControl = 4'b0000; // add, addi
                end
                3'b001:  ALUControl = 4'b0100; //sll, slli
                3'b010:  ALUControl = 4'b0101; // slt, slti
                3'b011:  ALUControl = 4'b0101; // sltu, sltiu (doubtful)
                3'b100:  ALUControl = 4'b0110; // xor, xori
                3'b101: begin
                    if (funct7b5) ALUControl = 4'b0111; // srl, srli
                    else ALUControl = 4'b1000;          // sra, srai
                end
                3'b110:  ALUControl = 4'b0011; // or, ori
                3'b111:  ALUControl = 4'b0010; // and, andi
                default: ALUControl = 4'bxxxx; // ???
            endcase
    endcase
end

endmodule

// main_decoder.v - logic for main decoder

module main_decoder (
    input  [6:0] op,
    input  [2:0] funct3,
    output [1:0] ResultSrc,
    output       MemWrite, Branch, ALUR31, ALUSrc,
    output       RegWrite, Zero, Jump, Jalr,
    output reg   Take_Branch,
    output [1:0] ImmSrc,
    output [1:0] ALUOp, Store,
    output [2:0] Load
);

reg [16:0] controls;

always @(*) begin
    case (op)
        // RegWrite_ImmSrc_ALUSrc_MemWrite_ResultSrc_Branch_ALUOp_Jump_Store_Load_Jalr
        7'b0000011: begin
                        case (funct3)
                        3'b000: controls = 17'b1_00_1_0_01_0_00_0_00_000_0; // lb
                        3'b001: controls = 17'b1_00_1_0_01_0_00_0_00_001_0; // lh
                        3'b010: controls = 17'b1_00_1_0_01_0_00_0_00_010_0; // lw
                        3'b100: controls = 17'b1_00_1_0_01_0_00_0_00_011_0; // lbu
                        3'b101: controls = 17'b1_00_1_0_01_0_00_0_00_100_0; // lhu
                        endcase
                    end
        7'b0100011: begin
                        case (funct3)
                        3'b000: controls = 17'b0_01_1_1_00_0_00_0_00_000_0; // sw
                        3'b001: controls = 17'b0_01_1_1_00_0_00_0_01_000_0; // sh
                        3'b010: controls = 17'b0_01_1_1_00_0_00_0_10_000_0; // sb
                        endcase
                    end
        7'b0110011: controls = 17'b1_xx_0_0_00_0_10_0_00_010_0; // R-type
        7'b1100011: controls = 17'b0_10_0_0_00_1_01_0_00_010_0; // B-type
        7'b0010011: controls = 17'b1_00_1_0_00_0_10_0_00_010_0; // I-type ALU
        7'b1100111: controls = 17'b1_00_1_0_10_0_00_0_00_010_1; // jalr
        7'b1101111: controls = 17'b1_11_0_0_10_0_00_1_00_010_0; // jal
        7'b0010111: controls = 17'b1_xx_x_0_11_0_00_0_00_010_0; // auipc
        7'b0110111: controls = 17'b1_xx_x_0_11_0_00_0_00_010_0; // auipc
        default:    controls = 17'bx_xx_x_x_xx_x_xx_x_xx_xxx_x; // ???
    endcase

    Take_Branch = 0;
    if (Branch) begin
        case (funct3)
            3'b000:  Take_Branch = Zero;
            3'b001:  Take_Branch = ~Zero;
            3'b100:  Take_Branch = ALUR31;
            3'b101:  Take_Branch = !ALUR31;
            default: Take_Branch = 0;
        endcase
    end

end

assign {RegWrite, ImmSrc, ALUSrc, MemWrite, ResultSrc, Branch, ALUOp, Jump, Store, Load, Jalr} = controls;

endmodule

// controller.v - controller for RISC-V CPU

module controller (
    input [6:0]  op,
    input [2:0]  funct3,
    input        funct7b5,
    input        Zero, ALUR31,
    output [1:0] ResultSrc,
    output       MemWrite,
    output       PCSrc, Jalr, ALUSrc,
    output       RegWrite, Op5,
    output [1:0] ImmSrc, Store,
    output [2:0] Load,
    output [3:0] ALUControl
);

wire [1:0] ALUOp;
wire       Branch, Jump, Take_Branch;

main_decoder    md (op, funct3, ResultSrc, MemWrite, Branch, ALUR31,
                    ALUSrc, RegWrite, Zero, Jump, Jalr, Take_Branch,
                    ImmSrc, ALUOp, Store, Load);

alu_decoder     ad (op[5], funct3, funct7b5, ALUOp, ALUControl);

// for jump and branch
assign PCSrc = (Branch & Take_Branch) | Jump;
assign Op5 = op[5];

endmodule
