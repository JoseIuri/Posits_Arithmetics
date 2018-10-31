module data_extract 
#(
  parameter WORD_SIZE = 32,
  parameter RS        = 5, //$clog2(WORD_SIZE)
  parameter ES		  = 2
)(
	input  logic [WORD_SIZE-1:0] in,    
	output logic 				 rc,
	output logic [BS-1:0] 		 regime,
	output logic [BS-1:0] 		 Lshift,	
	output logic [ES-1:0]		 exp,
	output logic [WORD_SIZE-ES-1:0]		 mantissa	 
);

	logic [WORD_SIZE-1:0] xin = in;
	
	assign rc = xin[WORD_SIZE-2];
	
	logic [Bs-1:0] k0, k1;
	
	LOD #(.WORD_SIZE(WORD_SIZE), .RS(RS)) xinst0(.in({xin[WORD_SIZE-2:0],1'b0}), .out(k0), .vld());
	LZD #(.WORD_SIZE(WORD_SIZE), .RS(RS)) xinst1(.in({xin[WORD_SIZE-3:0],2'b0}), .out(k1), .vld());

	assign regime = xin[WORD_SIZE-2] ? k1 : k0;
	assign Lshift = xin[WORD_SIZE-2] ? k1+1 : k0;

	logic [WORD_SIZE-1:0] xin_tmp;

	DLS #(.WORD_SIZE(WORD_SIZE), .RS(RS)) ls (.a({xin[WORD_SIZE-3:0],2'b0}),.b(Lshift),.c(xin_tmp));

	assign exp= xin_tmp[WORD_SIZE-1:WORD_SIZE-es];
	assign mant= xin_tmp[WORD_SIZE-es-1:0];


endmodule