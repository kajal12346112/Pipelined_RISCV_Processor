# Pipelined_RISCV_Processor
This project is a modular 5-stage pipelined RISC-V processor (RV32I subset), fully written in Verilog HDL. It simulates core CPU functionality following the instruction pipeline:  
Instruction Fetch → Decode → Execute → Memory → Write Back.

 Key Features
- 5-Stage Pipeline: IF, ID, EX, MEM, WB with pipeline registers  
- Control & Datapath Modules: ALU, Register File, Immediate Generator, Control Unit  
- Hazard Handling: Forwarding Unit & Hazard Detection logic  
- Branch Handling: Branch detection, flush, and PC redirection  
- Testbench Included: For waveform simulation in Vivado

