`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.06.2025 
// Design Name: 
// Module Name: fetch_cycle
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


/* instructions i will be adding to the fetch cycle
lw s2,40(s0)
add s3,s9,s10
sub s4,t1,s8
and s5,s11,t0
sw s6,20(t4)
or s3,t2,t3 */

module mux2 #(parameter WIDTH = 8) (
    input       [WIDTH-1:0] d0, d1,
    input       sel,
    output      [WIDTH-1:0] y
);

assign y = (~sel) ? d0 : d1;

endmodule

module Mux_3_by_1 (a,b,c,s,d);
    input [31:0] a,b,c;
    input [1:0] s;
    output [31:0] d;

    assign d = (s == 2'b00) ? a : (s == 2'b01) ? b : (s == 2'b10) ? c : 32'h00000000;
    
endmodule

module adder #(parameter WIDTH = 32) (
    input       [WIDTH-1:0] a, b,
    output      [WIDTH-1:0] sum
);

assign sum = a + b;

endmodule

module reset_ff #(parameter WIDTH = 8) (
    input       clk, rst,
    input       [WIDTH-1:0] d,
    output reg  [WIDTH-1:0] q
);

always @(posedge clk) begin
    if (rst==1'b0) q <= 0;
    else     q <= d;
end

endmodule



module instr_mem #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 32, MEM_SIZE = 1024) (
    input rst,Flush,
    input       [ADDR_WIDTH-1:0] instr_addr,
    output      [DATA_WIDTH-1:0] instr

);

// array of 1023 32-bit words or instructions
reg [DATA_WIDTH-1:0] instr_ram [MEM_SIZE-1:0];

initial begin
    $readmemh("memfile.hex",instr_ram);
end

// word-aligned memory access
// combinational read logic
assign instr = (rst==1'b0||Flush==1'b0)?{32{1'b0}}:instr_ram[instr_addr];

endmodule

module fetch_cycle (
    input clk,
    input rst,
    input PCsrcE,
    input [31:0] PCtargetE,
    input Flush,
    output [31:0] instrD,//instruction coming out of the fetch cycle
    output [31:0] PCD,//program counter coming out of fetch cycle
    output [31:0] PCplus4D //next instrucction address
    );
wire [31:0] PCF,PCplus4f,PCF_flop;
wire [31:0] instrF;

reg [31:0] PCf_reg,PCplus4_reg;
reg [31:0] instrf_reg;

mux2 #(32) PCmux(PCplus4f,PCtargetE,PCsrcE,PCF);
reset_ff #(32) pcflop(clk,rst,PCF,PCF_flop);
instr_mem instrucn_memory(rst,Flush,PCF_flop,instrF);
adder pcadd4 (PCF_flop,32'h00000001,PCplus4f);

always @(posedge clk or negedge rst) begin
    if (rst==1'b0 || Flush==1'b0) begin
        PCf_reg<=32'h00000000;
        PCplus4_reg<=32'h00000000;
        instrf_reg<=32'h00000000;
    end

    else begin
        PCf_reg<=PCF_flop;
        PCplus4_reg<=PCplus4f;
        instrf_reg<=instrF;
    end
    
end

assign instrD=instrf_reg;
assign PCD=PCf_reg;
assign PCplus4D=PCplus4_reg;

endmodule
