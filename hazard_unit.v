`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 20.06.2025 
// Design Name: 
// Module Name: hazard_unit
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

module hazard_unit (
    input [4:0] RS1E,RS2E,RdM,RdW,
    input rst,RegwriteM,RegwriteW,
    output [1:0] ForwardAE,ForwardBE
);
    assign ForwardAE =(rst==1'b0)?2'b00:
    ((RS1E==RdM & RegwriteM)& RS1E!=0)?2'b10:
    ((RS1E==RdW & RegwriteW)& RS1E!=0)?2'b01:2'b00;

    assign ForwardBE =(rst==1'b0)?2'b00:
    ((RS2E==RdM & RegwriteM)& RS2E!=0)?2'b10:
    ((RS2E==RdW & RegwriteW)& RS2E!=0)?2'b01:2'b00;
endmodule
