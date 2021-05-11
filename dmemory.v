module dmemory (
  input  clock,
  input wire [31:0] address,
  input wire [31:0] data_in,
  input wire [1:0] access_size, // 2 bit acess size port
  input wire read_write,
  output reg [31:0] data_out
);

	reg [7:0] d_mem [0:`MEM_DEPTH-1]; 
	reg [31:0] d_mem_temp [0:(`MEM_DEPTH>>2)-1]; 
	integer  i,j,k;

	initial begin
		$readmemh(`MEM_PATH, d_mem_temp);	
		j=0;
		for(i=0; i < `MEM_DEPTH; i=i+4) begin
			for(k=0; k < 32; k=k+8) begin
				d_mem[i + (k/8)]   = d_mem_temp[j][k+:8]; 				
			end 
			j=j+1;
		end
	end


    always @(*) begin  // reads, combinational circuit, use blocking statements
		if (read_write == 0) begin
            data_out[7:0] = d_mem[address]; 
			data_out[15:8] = d_mem[address+1]; 
            data_out[23:16] = d_mem[address+2]; 
			data_out[31:24] = d_mem[address+3]; 
		end
	end

    always @(posedge clock) begin // writes, sequential circuit, use non-blocking statements
		if (read_write == 1) begin
			if (access_size == 2'b00) begin // sb instruction
				d_mem[address]   <= data_in[7:0]; 
				d_mem[address+1] <= 8'b00000000; 
				d_mem[address+2] <= 8'b00000000; 
				d_mem[address+3] <= 8'b00000000; 
			end else if (access_size == 2'b01) begin //sh instruction
				d_mem[address]   <= data_in[7:0]; 
				d_mem[address+1] <= data_in[15:8]; 
				d_mem[address+2] <= 8'b00000000; 
				d_mem[address+3] <= 8'b00000000;

			end else if (access_size == 2'b10) begin //sw instruction
				d_mem[address]   <= data_in[7:0]; 
				d_mem[address+1] <= data_in[15:8]; 
				d_mem[address+2] <= data_in[23:16]; 
				d_mem[address+3] <= data_in[31:24]; 
			end 
		end
        
	end

endmodule