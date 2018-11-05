module posit_mult
#(
  parameter WORD_SIZE = 32,
  parameter RS        = 5, //$clog2(WORD_SIZE)
  parameter ES 		  = 2	
)(
	input logic [WORD_SIZE-1:0]  in1,    
	input logic [WORD_SIZE-1:0]  in2,

	input logic 				 ready,

	output logic [WORD_SIZE-1:0] out,

	output logic 				 inf,
	output logic				 zero,
	output logic				 valid	 
);


	logic ready0= start;
	logic s1 = in1[WORD_SIZE-1];
	logic s2 = in2[WORD_SIZE-1];
	logic zero_tmp1 = |in1[WORD_SIZE-2:0];
	logic zero_tmp2 = |in2[WORD_SIZE-2:0];
	logic inf1 = in1[WORD_SIZE-1] & (~zero_tmp1),
		inf2 = in2[WORD_SIZE-1] & (~zero_tmp2);
	logic zero1 = ~(in1[WORD_SIZE-1] | zero_tmp1),
		zero2 = ~(in2[WORD_SIZE-1] | zero_tmp2);
	assign inf = inf1 | inf2,
		zero = zero1 & zero2;

	//Data Extraction
	logic rc1, rc2;
	logic [RS-1:0] regime1, regime2, Lshift1, Lshift2;
	logic [ES-1:0] e1, e2;
	logic [WORD_SIZE-ES-1:0] mant1, mant2;
	logic [WORD_SIZE-1:0] xin1 = s1 ? -in1 : in1;
	logic [WORD_SIZE-1:0] xin2 = s2 ? -in2 : in2;
	data_extract #(.WORD_SIZE(WORD_SIZE), .RS(RS), .ES(ES)) uut_de1(.in(xin1), .rc(rc1), .regime(regime1), .exp(e1), .mantissa(mant1), .Lshift(Lshift1));
	data_extract #(.WORD_SIZE(WORD_SIZE), .RS(RS), .ES(ES)) uut_de2(.in(xin2), .rc(rc2), .regime(regime2), .exp(e2), .mantissa(mant2), .Lshift(Lshift2));

	logic [WORD_SIZE-ES:0] m1 = {zero_tmp1,mant1}, 
		m2 = {zero_tmp2,mant2};

	//Sign, Exponent and Mantissa Computation
	logic mult_s = s1 ^ s2;

	logic [2*(WORD_SIZE-ES)+1:0] mult_m = m1*m2;
	logic mult_m_ovf = mult_m[2*(WORD_SIZE-ES)+1];
	logic [2*(WORD_SIZE-ES)+1:0] mult_mN = ~mult_m_ovf ? mult_m << 1'b1 : mult_m;

	logic [RS+1:0] r1 = rc1 ? {2'b0,regime1} : -regime1;
	logic [RS+1:0] r2 = rc2 ? {2'b0,regime2} : -regime2;
	logic [RS+ES+1:0] mult_e  =  {r1, e1} + {r2, e2} + mult_m_ovf;

	//Exponent and Regime Computation
	logic [ES+RS:0] mult_eN = mult_e[ES+RS+1] ? -mult_e : mult_e;
	logic [ES-1:0] e_o = (mult_e[ES+RS+1] & |mult_eN[ES-1:0]) ? mult_e[ES-1:0] : mult_eN[ES-1:0];
	logic [RS:0] r_o = (~mult_e[ES+RS+1] || (mult_e[ES+RS+1] & |mult_eN[ES-1:0])) ? mult_eN[ES+RS:ES] + 1'b1 : mult_eN[ES+RS:ES];

	//Exponent and Mantissa Packing
	logic [2*WORD_SIZE-1:0]tmp_o = {{WORD_SIZE{~mult_e[ES+RS+1]}},mult_e[ES+RS+1],e_o,mult_mN[2*(WORD_SIZE-ES):WORD_SIZE-ES+2]};


	//Including Regime bits in Exponent-Mantissa Packing
	logic [2*WORD_SIZE-1:0] tmp1_o;
	DRS #(.WORD_SIZE(2*WORD_SIZE), .RS(RS+1)) dsr2 (.a(tmp_o), .b(r_o[RS] ? {RS{1'b1}} : r_o), .c(tmp1_o));


	//Final Output
	logic [2*WORD_SIZE-1:0] tmp1_oN = mult_s ? -tmp1_o : tmp1_o;
	assign out = inf|zero|(~mult_mN[2*(WORD_SIZE-ES)+1]) ? {inf,{WORD_SIZE-1{1'b0}}} : {mult_s, tmp1_oN[WORD_SIZE-1:1]},
		valid = ready0;

endmodule

