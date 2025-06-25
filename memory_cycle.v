`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// Design Name: 
// Module Name: memory_cycle
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



module data_mem #(parameter DATA_WIDTH = 32, ADDR_WIDTH = 32, MEM_SIZE = 1024) (
    input       clk,wr_en,rst,
    input       [ADDR_WIDTH-1:0] wr_addr, wr_data,
    output      [DATA_WIDTH-1:0] rd_data_mem
);

// array of 64 32-bit words or data
reg [DATA_WIDTH-1:0] data_ram [MEM_SIZE-1:0];

// combinational read logic
// word-aligned memory access
assign rd_data_mem = (rst==1'b0)? 32'h00000000:data_ram[(wr_addr)];

// synchronous write logic
always @(posedge clk) begin
    if (wr_en) data_ram[(wr_addr)]<=wr_data;
end
initial begin
    data_ram[0]=32'h00000000;
end

endmodule

module Memory_cycle (
    input clk,rst,
    input [31:0] ALUresultM,WriteDataM,PCplus4M,
    input [4:0] RdM,
    input RegWriteM,ResultSrcM,MemwriteM,
    output RegWriteW,ResultSrcW,
    output [31:0] ReadDataW,ALUresultW,PCplus4W,
    output [4:0] RdW
);

wire [31:0] rd_data;
reg RegWriteM_r,ResultSrcM_r;
reg [31:0] ReadDataM_r,ALUresultM_r,PCplus4M_r;
reg [4:0] RdM_r;

data_mem data_memory(.clk(clk),
                     .wr_en(MemwriteM),
                     .rst(rst),
                     .wr_addr(ALUresultM),
                     .wr_data(WriteDataM),
                     .rd_data_mem(rd_data));

always @(posedge clk or negedge rst) begin
    if(rst==1'b0)begin
                RegWriteM_r<=1'b0;
                ResultSrcM_r<=1'b0;
                ReadDataM_r<=32'h00000000;
                ALUresultM_r<=32'h00000000;
                PCplus4M_r<=32'h00000000;
                RdM_r<=5'b00000;
                end
    
    else begin 
       
       RegWriteM_r<=RegWriteM;
       ResultSrcM_r<=ResultSrcM;
       ReadDataM_r<=rd_data;
       ALUresultM_r<=ALUresultM;
       PCplus4M_r<=PCplus4M;
       RdM_r<=RdM;
       end
end
assign RegWriteW=RegWriteM_r;
assign ResultSrcW=ResultSrcM_r;
assign ReadDataW=ReadDataM_r;
assign ALUresultW=ALUresultM_r;
assign PCplus4W=PCplus4M_r;
assign RdW=RdM_r;




endmodule
