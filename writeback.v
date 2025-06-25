`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Design Name: 
// Module Name: writeback
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


module writeback (
    input clk,rst,ResultSrcW,
    input [31:0] PCplus4W,ALUresultW,ReadDataW,
    output [31:0] ResultW
);

mux2 #(32) result_mux(.d0(ALUresultW),
                     .d1(ReadDataW),
                     .sel(ResultSrcW),
                     .y(ResultW));

    endmodule
