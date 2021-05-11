module decode(
  //inputs from fetch
  input  clock,
  input wire [31:0] instruction,

//outputs to display instruction
  output reg [6:0]  opcode,
  output reg [4:0]  rd,
  output reg [4:0]  rs1,
  output reg [4:0]  rs2,
  output reg [2:0]  func3,
  output reg [6:0]  func7,
  output reg [31:0] imm,
  output reg [4:0]  shamt,

// Outputs to Reg File
  output reg  write_enable,

// Outputs to ALU
  output reg       a_sel,
  output reg       b_sel,
  output reg [4:0] alu_sel,
  output reg       branch,

// Output to Memory
output reg [1:0] wb_sel,
output reg [1:0] access_size,
output reg  mem_read_write

);
// temp wires to calculate immediates 
wire[11:0] imm_i;
wire[11:0] imm_s;
wire[12:0] imm_sb;
wire[19:0] imm_u;
wire[20:0] imm_jal;

assign imm_i  = instruction[31:20];
assign imm_s  = {instruction[31:25], instruction[11:7]};
assign imm_sb = {instruction[31], instruction[7], instruction[30:25], instruction[11:8], 1'b0}; //branches are scaled by 2 bytes
assign imm_u  = instruction[31:12];
assign imm_jal = {instruction[31], instruction[19:12], instruction[20], instruction[30:21], 1'b0};


localparam [4:0]ADD                         = 5'b00000,
                SUBTRACT                    = 5'b00001,
                AND                         = 5'b00010,
                OR                          = 5'b00011,
                XOR                         = 5'b00100,
                LOGICAL_SHIFT_LEFT          = 5'b00101,
                LOGICAL_SHIFT_RIGHT         = 5'b00110,
                ARITHMETIC_SHIFT_RIGHT      = 5'b00111,
                UNSIGNED_LESS_THAN          = 5'b01000,
                UNSIGNED_GREATER_THAN       = 5'b01001,
                SIGNED_LESS_THAN            = 5'b01010,
                SIGNED_GREATER_THAN         = 5'b01011,
                BRANCH_EQUAL                = 5'b01100,
                BRANCH_NOT_EQUAL            = 5'b01101,
                JAL                         = 5'b01110,
                JALR                        = 5'b01111,
                LUI                         = 5'b10000;

//assign instruction 
always @(*) begin: instruction_decoding
    opcode = instruction[6:0];
    rd     = instruction[11:7];
    rs1    = instruction[19:15];
    rs2    = instruction[24:20];
    func3  = instruction[14:12];
    func7  = instruction[31:25];
    shamt  = instruction[24:20];
end 


always @(*) begin : generate_alu_signals
    case(opcode)
        7'b0110011 : begin  // R-type instructions
          imm    = 32'h00000000;
          write_enable = 1; 

          a_sel= 0;
          b_sel= 0; 
          branch=0; 

          alu_sel = (func3 == 3'b001) ? LOGICAL_SHIFT_LEFT: //slli
                    (func3 == 3'b010) ? SIGNED_LESS_THAN:   //slti
                    (func3 == 3'b011) ? UNSIGNED_LESS_THAN: //sltiu
                    (func3 == 3'b100) ? XOR:                //xori
                    (func3 == 3'b110) ? OR:                 //ori
                    (func3 == 3'b111)? AND:                 //ori
                    (func3 == 3'b000) && (func7 == 7'b0000000)  ? ADD:      //add
                    (func3 == 3'b000) && (func7 == 7'b0100000)  ? SUBTRACT: //sub
                    (func3 == 3'b101) && (func7 == 7'b0000000)  ? LOGICAL_SHIFT_RIGHT: //srl
                    (func3 == 3'b101) && (func7 == 7'b0100000)  ? ARITHMETIC_SHIFT_RIGHT: //sra
                     5'b00000;
          mem_read_write = 1'bx;
          wb_sel = 2'b01;

        end
        7'b0010011 : begin  // I-type instructions  
           if( (func3 == 3'b001) || (func3 == 3'b101) ) begin
            imm = {27'b000000000000000000000000000, shamt }; //SLLI or SRLI
           end else begin
            imm = { {20{imm_i[11]}}, imm_i};   // other I types
           end

          write_enable = 1;  
          a_sel= 0;
          b_sel= 1; 
          branch=0; 

          alu_sel = (func3 == 3'b000) ? ADD:                //addi 
                    (func3 == 3'b001) ? LOGICAL_SHIFT_LEFT: //slli
                    (func3 == 3'b010) ? SIGNED_LESS_THAN:   //slti
                    (func3 == 3'b011) ? UNSIGNED_LESS_THAN: //sltiu
                    (func3 == 3'b100) ? XOR:                //xori
                    (func3 == 3'b110) ? OR:                 //ori
                    (func3 == 3'b111)? AND:                 //ori
                    (func3 == 3'b101) && (func7 == 7'b0000000)  ? LOGICAL_SHIFT_RIGHT:    //srli
                    (func3 == 3'b101) && (func7 == 7'b0100000)  ? ARITHMETIC_SHIFT_RIGHT: //srai
                                        5'b00000;
          wb_sel = 2'b01;
          mem_read_write = 1'bx;

        end
       7'b0000011: begin  // Load Instructions (Load lb,lh,lw,lbu,lhu)  
          imm = { {20{imm_i[11]}}, imm_i};  // imm extended
          write_enable = 1; 
          a_sel= 0;
          b_sel= 1; 
          branch=0; 
          alu_sel= ADD;
          wb_sel = 2'b00;
          mem_read_write = 0;
          access_size = func3[1:0];
        end
       7'b0100011 : begin  //S-type Instructions 
          imm = { {20{imm_s[11]}}, imm_s}; 
          write_enable = 0;
          a_sel= 0;
          b_sel= 1; 
          branch=0;
          alu_sel= ADD; 
          mem_read_write = 1; 
          wb_sel = 2'bx;

          access_size = func3[1:0];
        end
        7'b1100011 : begin  //Branch-Type Instructions
          imm = {{19{imm_sb[12]}}, imm_sb};
          write_enable = 0;
          a_sel= 0;
          b_sel= 0; 
          branch=1; 


          alu_sel = (func3 == 3'b000) ? BRANCH_EQUAL:           //beq
                    (func3 == 3'b110) ? UNSIGNED_LESS_THAN:     //bltu
                    (func3 == 3'b100) ? SIGNED_LESS_THAN:       //blt
                    (func3 == 3'b111) ? UNSIGNED_GREATER_THAN: //bgeu
                    (func3 == 3'b101) ? SIGNED_GREATER_THAN:    //bge
                    (func3 == 3'b001) ? BRANCH_NOT_EQUAL:      //bne
                     5'b00000;
          
          wb_sel = 2'bx;
          mem_read_write = 1'bx;

        end
        7'b1100111 : begin   //JALR Instruction
           imm = { {20{imm_i[11]}}, imm_i};  // imm extended
           write_enable = 1;
           a_sel= 0;
           b_sel= 0; 
           branch=0; 
           alu_sel = JALR;
            //save pc+4 in rd
           wb_sel = 2'b10;
           mem_read_write = 1'bx;
        end
        7'b1101111 : begin  //JAL Instruction 
           imm = { {11{imm_jal[20]}}, imm_jal};  // Jal imm
           write_enable = 1;
           a_sel= 0;
           b_sel= 0; 
           branch=0; 
           alu_sel = JAL;
           //save pc+4 in rd
           wb_sel = 2'b10;
           mem_read_write = 1'bx;
        end
        7'b0010111 : begin // AUIPC Instruction 
        //adds upper imm to PC and places result in rd
          imm = {imm_u, 12'b000000000000}; //load  upper 
           write_enable = 1;
           a_sel= 1;
           b_sel= 1; 
           branch=0; 
           alu_sel = ADD;
           wb_sel = 2'b01;
           mem_read_write = 1'bx;
        end
        7'b0110111 : begin //LUI Instruction
          imm = {imm_u, 12'b000000000000}; //load  upper 
           write_enable = 1;
           a_sel= 0;
           b_sel= 0; 
           branch=0; 
           alu_sel = LUI;
           wb_sel = 2'b01;
           mem_read_write = 1'bx;
        end
        default: begin
             $finish("Invalid Instruction");
       end


    endcase
end 

endmodule 
