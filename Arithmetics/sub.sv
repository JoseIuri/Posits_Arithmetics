module sub 
#(
  parameter WORD_SIZE = 10,
)(
	input  logic [WORD_SIZE-1:0] a,    
	input  logic [WORD_SIZE-1:0] b,
	output logic [WORD_SIZE:0]	 c
);
	assign c = {1'b0,a} - {1'b0,b};
endmodule