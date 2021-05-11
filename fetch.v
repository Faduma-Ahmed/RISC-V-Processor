module fetch (
  input  clock,
  input wire [31:0] data_in,
  input wire read_write,
  output reg [31:0] address,
  output reg [31:0] data_out
);
	reg [7:0] mem [0:`MEM_DEPTH-1]; 
	reg [31:0] mem_temp [0:(`MEM_DEPTH>>2)-1]; 
	integer  i,j,k;

	initial begin
//		address = 32'h01000000;
		$readmemh(`MEM_PATH, mem_temp);	
		j=0;
		for(i=0; i < `MEM_DEPTH; i=i+4) begin
			for(k=0; k < 32; k=k+8) begin
				mem[i + (k/8)]   = mem_temp[j][k+:8]; 				
//				$display("mem[%d + (%d/8)] = %x ",  i, k, mem_temp[j][k+:8]);
			end 
			j=j+1;
		end
	end

	always @(*) begin  // reads, combinational circuit, use blocking statements
		if (read_write == 0) begin
			data_out[7:0] = mem[address]; 
			data_out[15:8] = mem[address+1]; 
			data_out[23:16] = mem[address+2]; 
			data_out[31:24] = mem[address+3]; 
		end 
		
	end

	always @(posedge clock) begin // writes, sequential circuit, use non-blocking statements
		if (read_write == 1) begin
			mem[address] <= data_in[7:0]; 
			mem[address+1] <= data_in[15:8]; 
			mem[address+2] <= data_in[23:16]; 
			mem[address+3] <= data_in[31:24]; 
		end
		//address <= address + 'd4;
			
	end

endmodule 

