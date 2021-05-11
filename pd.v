module pd(
  input clock,
  input reset
);
  reg [31:0] pc;
  always @(posedge clock) begin
    if(reset) pc <= 0;
    else pc <= pc + 1;
  end

  //to fetch
wire [31:0]  probe_data_in;
wire         probe_read_write;
reg  [31:0]  probe_addr;
reg  [31:0]  probe_pc;
reg  [31:0]  probe_data_out;

// to decode
reg [6:0]  probe_opcode;
reg [4:0]  probe_rd;
reg [4:0]  probe_rs1;
reg [4:0]  probe_rs2;
reg [2:0]  probe_func3;
reg [6:0]  probe_func7;
reg [31:0] probe_imm;
reg [4:0]  probe_shamt;
reg        probe_write_enable;

//to register file
reg [31:0] probe_data_rd;
reg [31:0] probe_data_rs1;
reg [31:0] probe_data_rs2;

// to ALU
reg        probe_a_sel;
reg        probe_b_sel;
reg [4:0]  probe_alu_sel;
reg [31:0] probe_alu_result;
reg        probe_pc_sel;

reg       probe_branch;

 //to Memory
wire [31:0]  probe_mem_data_in;
wire         probe_mem_read_write;
wire  [1:0]  probe_access_size;
reg  [31:0]  probe_mem_addr;
reg  [31:0]  probe_mem_data_out;
reg  [1:0]   probe_wb_sel;


fetch fetch_0(
	.clock(clock),
	.address(probe_addr),
	.data_in(probe_data_in),
	.read_write(probe_read_write),
	.data_out(probe_data_out)
);

decode decode_0(
  .clock(clock),
  .instruction(probe_data_out),
  .opcode(probe_opcode),
  .rd(probe_rd),
  .rs1(probe_rs1),
  .rs2(probe_rs2),
  .func3(probe_func3),
  .func7(probe_func7),
  .imm(probe_imm),
  .shamt(probe_shamt),
  .write_enable(probe_write_enable),
  .a_sel(probe_a_sel),
  .b_sel(probe_b_sel),
  .alu_sel(probe_alu_sel),
  .branch(probe_branch),
  .wb_sel(probe_wb_sel),
  .access_size(probe_access_size),
  .mem_read_write(probe_mem_read_write)
);

register_file register_file_0(
  .clock(clock),
  .addr_rs1(probe_rs1),
  .addr_rs2(probe_rs2),
  .addr_rd(probe_rd),
  .data_rd(probe_data_rd),
  .write_enable(probe_write_enable),
  .data_rs1(probe_data_rs1),
  .data_rs2(probe_data_rs2)
);

alu alu_0(
     .clock(clock),
     .a_sel(probe_a_sel),
     .b_sel(probe_b_sel),
     .branch(probe_branch),
     .alu_sel(probe_alu_sel),
     .data_rs1(probe_data_rs1),
     .data_rs2(probe_data_rs2),
     .pc(probe_addr),
     .imm(probe_imm),
     .alu_result(probe_alu_result),
     .pc_sel(probe_pc_sel)
);
dmemory dmemory_0(
	.clock(clock),
	.address(probe_alu_result),
	.data_in(probe_data_rs2),
	.read_write(probe_mem_read_write),
  .access_size(probe_access_size),
	.data_out(probe_mem_data_out)
);

initial begin
		probe_addr = 32'h01000000;
    probe_pc = probe_addr ;
end 

// probe_pc_sel is being used 
always @(posedge clock) begin
   //  $display("pc_sel = %d", probe_pc_sel);
    // jump branching 
    if(probe_pc_sel) begin
      probe_addr <= probe_alu_result;
    end else begin
      probe_addr <= probe_addr + 'd4; 
    end
    probe_pc <= probe_addr;
end 

always @(*) begin
  //write-back 
    if(probe_wb_sel == 2'b00) begin // for loads
       probe_data_rd = (probe_func3 == 3'b000) ?  {{24{probe_mem_data_out[7]}}, probe_mem_data_out[7:0]}  :                //LB
                        (probe_func3 == 3'b001) ?  {{16{probe_mem_data_out[15]}}, probe_mem_data_out[15:0]} :               //LH
                        (probe_func3 == 3'b010) ?  probe_mem_data_out :                                                     //LW
                        (probe_func3 == 3'b100) ?  {24'b000000000000000000000000, probe_mem_data_out[7:0]} :               //LBU
                        (probe_func3 == 3'b101) ?  {16'b0000000000000000, probe_mem_data_out[15:0]}  :                     //LHU
                        32'b000000000000000000000000000000;
     
    end else if(probe_wb_sel == 2'b01) begin
      probe_data_rd = probe_alu_result;
    end else if(probe_wb_sel == 2'b10) begin
      probe_data_rd = probe_addr + 'd4;
    end 

end 
endmodule
