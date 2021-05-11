module branch_comparator(
  input clock,
  input wire [31:0] data_rs1,
  input wire [31:0] data_rs2
  input wire BrUn,
  output reg BrEq,
  output reg BrLT
);
// signed values 
assign s_data_rs1 = data_rs1;
assign s_data_rs2 = data_rs2;

assign BrEq = (!BrUn) && (data_rs1 >= data_rs2)     ?  1'b1 :
              (BrUn)  && (s_data_rs1 >= s_data_rs2) ?  1'b1 : 1'b0; 

assign BrLT = (!BrUn) && (data_rs1 < data_rs2)     ?  1'b1 :
              (BrUn)  && (s_data_rs1 <s_data_rs2)  ?  1'b1 : 1'b0; 


endmodule