module add_mant 
#(
  parameter WORD_SIZE = 10,
)(
	input  logic [WORD_SIZE:0] a,    
	input  logic 				 mant,
	output logic [WORD_SIZE:0]	 c	 
);
	assign c = a + mant;
endmodule