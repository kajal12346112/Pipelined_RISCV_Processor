`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.06.2025 16:17:18
// Design Name: 
// Module Name: data_path
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


// store_extend.v - logic for extending the data and addr for storing word, half and byte

module store_extend (
    input   [31:0] y,
    input   [1:0] sel,
    output reg [31:0] data
);

always @(*) begin
    case(sel)
        2'b00: data = y;
        2'b01: data = {24'b0, y[7:0]};
        2'b10: data = {16'b0, y[15:0]};
        default: data = y;
    endcase
end

endmodule

// reg_file.v - register file for single-cycle RISC-V CPU
//              (with 32 registers, each of 32 bits)
//              having two read ports, one write port
//              write port is synchronous, read ports are combinational
//              register 0 is hardwired to 0

module reg_file #(parameter DATA_WIDTH = 32) (
    input       clk,
    input       wr_en,
    input       [4:0] rd_addr1, rd_addr2, wr_addr,
    input       [DATA_WIDTH-1:0] wr_data,
    output      [DATA_WIDTH-1:0] rd_data1, rd_data2
);

reg [DATA_WIDTH-1:0] reg_file_arr [0:31];

integer i;
initial begin
    for (i = 0; i < 32; i = i + 1) begin
        reg_file_arr[i] = 0;
    end
end

// register file write logic (synchronous)
always @(posedge clk) begin
    if (wr_en) reg_file_arr[wr_addr] <= wr_data;
end

// register file read logic (combinational)
assign rd_data1 = ( rd_addr1 != 0 ) ? reg_file_arr[rd_addr1] : 0;
assign rd_data2 = ( rd_addr2 != 0 ) ? reg_file_arr[rd_addr2] : 0;

endmodule

// mux4.v - logic for 4-to-1 multiplexer

module mux4 #(parameter WIDTH = 8) (
    input       [WIDTH-1:0] d0, d1, d2, d3,
    input       [1:0] sel,
    output      [WIDTH-1:0] y
);

assign y = sel[1] ? (sel[0] ? d3 : d2) : (sel[0] ? d1 : d0);

endmodule

// reset_ff.v - 8-bit resettable D flip-flop

module reset_ff #(parameter WIDTH = 8) (
    input       clk, rst,
    input       [WIDTH-1:0] d,
    output reg  [WIDTH-1:0] q
);

always @(posedge clk or posedge rst) begin
    if (rst) q <= 0;
    else     q <= d;
end

endmodule

// mux2.v - logic for 2-to-1 multiplexer

module mux2 #(parameter WIDTH = 8) (
    input       [WIDTH-1:0] d0, d1,
    input       sel,
    output      [WIDTH-1:0] y
);

assign y = sel ? d1 : d0;

endmodule

// load_extend.v - logic for extending the data and addr for loading word, half and byte


module load_extend (
    input [31:0] y,
    input [ 2:0] sel,
    output reg [31:0] data
);

always @(*) begin
    case (sel)
    3'b000: data = {{24{y[7]}}, y[7:0]};
    3'b001: data = {{16{y[15]}}, y[15:0]};
    3'b010: data = y;
    3'b011: data = {24'b0, y[7:0]};
    3'b100: data = {16'b0, y[15:0]};
    default: data = y;
    endcase
end

endmodule

// imm_ext.v - logic for immediate extension

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
        // B-type (branches)
        2'b10:   immext = {{20{instr[31]}}, instr[7], instr[30:25], instr[11:8], 1'b0};
        // J-type (jal)
        2'b11:   immext = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21], 1'b0};
        default: immext = 32'bx; // undefined
    endcase
end

endmodule

// adder.v - logic for adder

module adder #(parameter WIDTH = 32) (
    input       [WIDTH-1:0] a, b,
    output      [WIDTH-1:0] sum
);

assign sum = a + b;

endmodule

// alu.v - ALU module

module alu #(parameter WIDTH = 32) (
    input       [WIDTH-1:0] a, b,       // operands
    input       [3:0] alu_ctrl,         // ALU control //was 2-bit
    output reg  [WIDTH-1:0] alu_out,    // ALU output
    output      zero                    // zero flag
);

always @(a, b, alu_ctrl) begin
    case (alu_ctrl)
        4'b0000: alu_out <= a + b;       // add
        4'b0001: alu_out <= a + ~b + 1;  // sub
        4'b0010: alu_out <= a & b;       // and
        4'b0011: alu_out <= a | b;       // or
        4'b0100: alu_out <= a << b[4:0]; // sll
        4'b0101: begin                   // slt
                    if (a[31] != b[31]) alu_out <= a[31] ? 0 : 1;
                    else alu_out <= a < b ? 1 : 0;
                end
        4'b0110: alu_out <= a ^ b;         // xor
        4'b0111: alu_out <= a >> b[4:0];   // srl
        4'b1000: alu_out <= a >>> b[4:0];  // sra
        default: alu_out = 0;
    endcase
end

assign zero = (alu_out == 0) ? 1'b1 : 1'b0;

endmodule

// datapath.v - datapath for single-cycle RISC-V CPU

module datapath (
    input         clk, reset,
    input   [1:0] ResultSrc,
    input         PCSrc, Jalr, ALUSrc,
    input         RegWrite, Op5,
    input   [1:0] ImmSrc, Store,
    input   [2:0] Load,
    input   [3:0] ALUControl,
    output        Zero, ALUR31,
    output [31:0] PC,
    input  [31:0] Instr,
    output [31:0] Mem_WrAddr, Mem_WrData,
    input  [31:0] ReadData
);

wire [31:0] PCNext, PCNextJalr, PCPlus4, PCTarget;
wire [31:0] ImmExt, SrcA, SrcB, Result, WriteData, ALUResult;
wire [31:0] ReadDataMem, AUIPc, URd;

// next PC logic
// Confused with JAlR
reset_ff #(32)  pcreg (clk, reset, PCNextJalr, PC);
adder           pcadd4 (PC, 32'd4, PCPlus4);
adder           pcaddbranch (PC, ImmExt, PCTarget);
mux2 #(32)      pcjalrmux(PCNext, ALUResult, Jalr, PCNextJalr);
mux2 #(32)      pcmux (PCPlus4, PCTarget, PCSrc, PCNext);

// Without JALR
// reset_ff #(32) pcreg(clk, reset, PCNext, PC);
// adder          pcadd4(PC, 32'd4, PCPlus4);
// adder          pcaddbranch(PC, ImmExt, PCTarget);
// mux2 #(32)     pcmux(PCPlus4, PCTarget, PCSrc, PCNext);


// register file logic
reg_file       rf (clk, RegWrite, Instr[19:15], Instr[24:20], Instr[11:7], Result, SrcA, WriteData);
imm_extend    ext (Instr[31:7], ImmSrc, ImmExt);

// ALU logic
mux2 #(32)     srcbmux (WriteData, ImmExt, ALUSrc, SrcB);
alu            alu (SrcA, SrcB, ALUControl, ALUResult, Zero);

// load data
load_extend     ldextd (ReadData, Load, ReadDataMem);

// lui and auipc
adder       auipcadd  (PC, {Instr[31:12], 12'b0}, AUIPc);
mux2 #(32)  luipcmux  (AUIPc, {Instr[31:12], 12'b0}, Op5, URd);
mux4 #(32)  resultmux (ALUResult, ReadDataMem, PCPlus4, URd, ResultSrc, Result);

// store data
store_extend strextd (WriteData, Store, Mem_WrData);

// assign Mem_WrData = WriteData;
assign Mem_WrAddr = ALUResult;
assign ALUR31 = ALUResult[31];

endmodule