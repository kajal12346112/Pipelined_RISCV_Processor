`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Design Name: 
// Module Name: branch_detection
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



//detect a successfull branch reset the fetch and decode for two cycles then continue the pipeline 

module D_ff #(parameter N=32)(D,clk,rst,Q);
input [ N:0] D; // Data input 
input clk; // clock input 
input rst; // asynchronous reset high level
output reg  [N:0]Q; // output Q 
always @(posedge clk or negedge rst) 
begin
 if(rst==1'b0)
  Q <=0; 
 else 
  Q <= D; 
end 
endmodule 
module branch_detection(
    input clk,rst,PCsrcE,
    input [31:0]PCtargetE,
    output [31:0] stalled_PC,
    output stalled_PCsrcE,sel,
    output Flush
);


wire [32:0]delay_line1,delay_line2;
D_ff flop1({PCsrcE,PCtargetE},clk,rst,delay_line1);
D_ff flop2(delay_line1,clk,rst,delay_line2);
    


assign Flush=~(PCsrcE|delay_line1[32]|delay_line2[32]);
assign stalled_PC=delay_line2[31:0];
assign stalled_PCsrcE=delay_line2[32];
assign sel=(PCsrcE|delay_line1[32]|delay_line2[32]);
    
endmodule
