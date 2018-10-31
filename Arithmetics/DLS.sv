module DLS 
#(
  parameter WORD_SIZE = 32,
  parameter RS        = 5 //$clog2(WORD_SIZE)
)(
	input  logic [WORD_SIZE-1:0] a,    
	input  logic [RS-1:0]        b, 
	output logic [WORD_SIZE-1:0] c  
);

	logic [WORD_SIZE-1:0] tmp [RS-1:0];
	assign tmp[0]  = b[0] ? a << 7'd1  : a; 
	genvar i;
	generate
		for (i=1; i<RS; i=i+1)begin : loop_blk
			assign tmp[i] = b[i] ? tmp[i-1] << 2**i : tmp[i-1];
		end
	endgenerate
	assign c = tmp[RS-1];

endmodule