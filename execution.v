`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 18.06.2025 
// Design Name: 
// Module Name: execution
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


module alu #(parameter WIDTH = 32) (
    input       [WIDTH-1:0] a, b,       // operands
    input       [2:0] alu_ctrl,         // ALU control //was 2-bit
    output reg  [WIDTH-1:0] alu_out,    // ALU output
    output      zero                    // zero flag
);

always @(a, b, alu_ctrl) begin
    case (alu_ctrl)
        3'b000: alu_out <= a + b;       // add
        3'b001: alu_out <= a + ~b + 1;  // sub
        3'b010: alu_out <= a & b;       // and
        3'b011: alu_out <= a | b;       // or
        // 4'b0100: alu_out <= a << b[4:0]; // sll
        3'b101: begin                   // slt
                    if (a[31] != b[31]) alu_out <= a[31] ? 0 : 1;
                    else alu_out <= a < b ? 1 : 0;
                end
        3'b110: alu_out <= a ^ b;         // xor
        // 4'b0111: alu_out <= a >> b[4:0];   // srl
        // 4'b1000: alu_out <= a >>> b[4:0];  // sra
        default: alu_out = 0;
    endcase
end


assign zero = (alu_out == 0) ? 1'b1 : 1'b0;

endmodule



module execution (
    input clk,rst,regWriteE,ALUsrcE,MemwriteE,BranchE,ResultSrcE,
    input [2:0] ALUcontrolE,
    input [31:0] RD1E,RD2E,PCE,PCplus4E,ImmextE,
    input [4:0] Rde,
    input [1:0] ForwardAE,ForwardBE,
    input [31:0] ResultW,
    output [31:0] PCtargetE,ALUresultM,WriteDataM,PCplus4M,
    output [4:0] RdM,
    output PCsrcE,
    output RegWriteM,ResultSrcM,MemwriteM
);
wire zeroE;
wire [31:0] ALUresultE,SrcBE;

wire [31:0] Frwrd_A,Frwrd_B;


reg  regwriteE_r,ResultSrcE_r,MemwriteE_r;
reg [31:0] ALUresultE_r,WriteDataE_r,PCplus4E_r;
reg [4:0] RD_E_r;

Mux_3_by_1 MuxA(.a(RD1E),
                .b(ResultW),
                .c(ALUresultE_r),
                .s(ForwardAE),
                .d(Frwrd_A));


Mux_3_by_1 MuxB(.a(RD2E),
                .b(ResultW),
                .c(ALUresultE_r),
                .s(ForwardBE),
                .d(Frwrd_B));

alu ALU(.a(Frwrd_A),
        .b(SrcBE),
        .alu_ctrl(ALUcontrolE),
        .alu_out(ALUresultE),
        .zero(zeroE));

mux2 #(32) oprand_mux(.d0(Frwrd_B),
                .d1(ImmextE),
                .sel(ALUsrcE),
                .y(SrcBE));

adder PCadder(.a(PCE),
              .b(ImmextE),
              .sum(PCtargetE)
);

assign PCsrcE=(zeroE & BranchE);

always @(posedge clk or negedge rst) begin
    if(rst==1'b0)begin
        regwriteE_r<=1'b0;
        ResultSrcE_r<=1'b0;
        MemwriteE_r<=1'b0;
        ALUresultE_r<=32'h00000000;
        WriteDataE_r<=32'h00000000;
        PCplus4E_r<=32'h00000000;
        RD_E_r<=5'b00000;
end

else begin
        regwriteE_r<=regWriteE;
        ResultSrcE_r<=ResultSrcE;
        MemwriteE_r<=MemwriteE;
        ALUresultE_r<=ALUresultE;
        WriteDataE_r<=Frwrd_B;
        PCplus4E_r<=PCplus4E;
        RD_E_r<=Rde;
    end
end

assign RegWriteM=regwriteE_r;
assign ResultSrcM=ResultSrcE_r;
assign MemwriteM=MemwriteE_r;
assign ALUresultM=ALUresultE_r;
assign WriteDataM=WriteDataE_r;
assign PCplus4M=PCplus4E_r;
assign RdM=RD_E_r;
endmodule

