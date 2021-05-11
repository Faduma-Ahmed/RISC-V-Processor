module alu(
     input  clock,
     input wire        a_sel,
     input wire        b_sel,
     input wire        branch,
     input wire [4:0]  alu_sel,
     input wire [31:0] data_rs1,
     input wire [31:0] data_rs2,
     input wire [31:0] pc,
     input wire [31:0] imm,
     output reg [31:0] alu_result,
     output reg pc_sel
);

wire [31:0] op_a;
wire [31:0] op_b;

assign op_a = (a_sel ==1) ? pc : data_rs1; 
assign op_b = (b_sel ==1) ? imm : data_rs2; 

// ALU Control Input
// 00000 = add
// 00001 = subtract
// 00010 = and
// 00011 = or 
// 00100 = xor
// 00101 = logical shift left (LSL)
// 00110 = logical shift right
// 00111 = arithmetic shift right 
// 01000 = unsigned less than
// 01001 = unsigned greater than or equal to
// 01010 = signed less than
// 01011 = signed greater than or equal to
// 01100 = branch equal
// 01101 = branch not equal
// 01110 = jal
// 01111 = jalr
// 10000 = LUI (alu result is imm)

assign alu_result = (branch == 1'b1) && (alu_sel == 5'b01100) && (op_a == op_b) ? (pc + imm):                          // BEQ
                    (branch == 1'b1) && (alu_sel == 5'b0101) && (op_a != op_b) ? (pc + imm):                          // BNE
                    (branch == 1'b1) && (alu_sel == 5'b01000) && (op_a < op_b)  ? (pc + imm):                          // BLTU
                    (branch == 1'b1) && (alu_sel == 5'b01001) && (op_a >= op_b) ? (pc + imm):                          // BGEU
                    (branch == 1'b1) && (alu_sel == 5'b01010) && ($signed(op_a) < $signed(op_b))  ? (pc + imm):        // BLT
                    (branch == 1'b1) && (alu_sel == 5'b01011) && ($signed(op_a) >= $signed(op_b)) ? (pc + imm):        // BGE
                    (alu_sel == 5'b00000) ? (op_a + op_b):                                                             // add (LUI,AUIPC,LW,SW,ADDI,ADD)
                    (alu_sel == 5'b00001) ? (op_a - op_b):                                                             // subtract (SUB)
                    (alu_sel == 5'b00010) ? (op_a & op_b):                                                             // AND  (ANDI,AND)
                    (alu_sel == 5'b00011) ? (op_a | op_b):                                                             // OR  (OR,ORI)
                    (alu_sel == 5'b00100) ? (op_a ^ op_b):                                                             // XOR (XORI,XOR)
                    (alu_sel == 5'b00101) ? (op_a << op_b):                                                            // logical shift left      (SLLI,SLL)
                    (alu_sel == 5'b00110) ? (op_a >> op_b):                                                            // logical shift right     (SRLI,SRL)
                    (alu_sel == 5'b00111) ? (op_a >>> op_b):                                                           // arithmetic shift right (SRAI,SRA)
                    (alu_sel == 5'b01000) && (op_a < op_b) ?  32'h00000001:                                            // unsigned less than (BLTU,SLTIU,SLTU)
                    (alu_sel == 5'b01010) && ($signed(op_a) < $signed(op_b)) ?  32'h00000001:                          // signed less than (SLTI,SLT,BLT)
                    (alu_sel == 5'b01110) ? (pc + imm):                                                                // JAL (PC = PC + Offset)
                    (alu_sel == 5'b01111) ? ((op_a + imm) & 32'hfffffffe) :                                            // JALR (PC = (Reg[rs1] + imm) & 0xfffffffe)
                    (alu_sel == 5'b10000) ?  imm:                                                                      // LUI 
                    32'h00000000;


 
assign pc_sel = (branch == 1'b1) && (alu_sel == 5'b01100) && (op_a == op_b)                   ? 1'b1: // BEQ
                (branch == 1'b1) && (alu_sel == 5'b01101) && (op_a != op_b)                   ? 1'b1: // BNE
                (branch == 1'b1) && (alu_sel == 5'b01000) && (op_a < op_b)                    ? 1'b1: // BLTU
                (branch == 1'b1) && (alu_sel == 5'b01001) && (op_a >= op_b)                   ? 1'b1: // BGEU
                (branch == 1'b1) && (alu_sel == 5'b01010) && ($signed(op_a) < $signed(op_b))  ? 1'b1: // BLT
                (branch == 1'b1) && (alu_sel == 5'b01011) && ($signed(op_a) >= $signed(op_b)) ? 1'b1: // BGE
                (alu_sel == 5'b01110) ?  1'b1:                                                        // JAL
                (alu_sel == 5'b01111) ?  1'b1:                                                        // JALR
                1'b0;
endmodule