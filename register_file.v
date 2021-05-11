module register_file(
  input  clock,
  input wire [4:0]  addr_rs1,
  input wire [4:0]  addr_rs2,
  input wire [4:0]  addr_rd,
  input wire [31:0] data_rd,
  input wire        write_enable,
  output reg [31:0] data_rs1,
  output reg [31:0] data_rs2
);
 initial begin
   register_file[0] = 32'h0;
   register_file[2] = 32'h01000000 + `MEM_DEPTH;
 end
 //create a register file 
reg   [31:0] register_file[0:31];

assign data_rs1 = register_file[addr_rs1];
assign data_rs2 = register_file[addr_rs2];

always@(posedge clock) begin
    if (write_enable && (addr_rd != 5'b00000)) begin 
		    register_file[addr_rd] <= data_rd;
		end 
end 

endmodule