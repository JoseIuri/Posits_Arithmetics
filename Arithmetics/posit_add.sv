module posit_add 
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



	logic ready0= ready;
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
	data_extract #(.WORD_SIZE(WORD_SIZE),.ES(ES)) uut_de1(.in(xin1), .rc(rc1), .regime(regime1), .exp(e1), .mantissa(mant1), .Lshift(Lshift1));
	data_extract #(.WORD_SIZE(WORD_SIZE),.ES(ES)) uut_de2(.in(xin2), .rc(rc2), .regime(regime2), .exp(e2), .mantissa(mant2), .Lshift(Lshift2));

	logic [WORD_SIZE-ES:0] m1 = {zero_tmp1,mant1}, 
		m2 = {zero_tmp2,mant2};

	//Large Checking and Assignment
	logic in1_gt_in2 = xin1[WORD_SIZE-2:0] >= xin2[WORD_SIZE-2:0] ? 1'b1 : 1'b0;

	logic ls = in1_gt_in2 ? s1 : s2;
	logic op = s1 ~^ s2;

	logic lrc = in1_gt_in2 ? rc1 : rc2;
	logic src = in1_gt_in2 ? rc2 : rc1;

	logic [RS-1:0] lr = in1_gt_in2 ? regime1 : regime2;
	logic [RS-1:0] sr = in1_gt_in2 ? regime2 : regime1;

	logic [ES-1:0] le = in1_gt_in2 ? e1 : e2;
	logic [ES-1:0] se = in1_gt_in2 ? e2 : e1;

	logic [WORD_SIZE-ES:0] lm = in1_gt_in2 ? m1 : m2;
	logic [WORD_SIZE-ES:0] sm = in1_gt_in2 ? m2 : m1;

	//Exponent Difference: Lower Mantissa Right Shift Amount
	logic [RS:0] r_diff11, r_diff12, r_diff2;
	sub #(.WORD_SIZE(RS)) uut_sub1 (lr, sr, r_diff11); 
	add #(.WORD_SIZE(RS)) uut_add1 (lr, sr, r_diff12); 
	sub #(.WORD_SIZE(RS)) uut_sub2 (sr, lr, r_diff2);  
	logic [RS:0] r_diff =  lrc ? (src ? r_diff11 : r_diff12) : r_diff2;

	logic [ES+RS+1:0] diff;
	sub #(.WORD_SIZE(ES+RS+1)) uut_sub_diff ({r_diff,le}, {{RS+1{1'b0}},se}, diff);
	logic [RS-1:0] exp_diff = (|diff[ES+RS:RS]) ? {RS{1'b1}} : diff[RS-1:0];

	//DSR Right Shifting of Small Mantissa
	logic [WORD_SIZE-1:0] drs_in;
	generate
		if (ES >= 2) 
		assign drs_in = {sm,{ES-1{1'b0}}};
		else 
		assign drs_in = sm;
	endgenerate

	logic [WORD_SIZE-1:0] DRS_out;
	logic [RS-1:0] DSR_e_diff  = exp_diff;
	DRS #(.WORD_SIZE(WORD_SIZE), .RS(RS))  dsr1(.a(drs_in), .b(DSR_e_diff), .c(DRS_out)); 

	//Mantissa Addition
	logic [WORD_SIZE-1:0] add_m_in1;
	generate
		if (ES >= 2) 
		assign add_m_in1 = {lm,{ES-1{1'b0}}};
		else 
		assign add_m_in1 = lm;
	endgenerate

	logic [WORD_SIZE:0] add_m1, add_m2;
	add #(.WORD_SIZE(WORD_SIZE)) uut_add_m1 (add_m_in1, DRS_out, add_m1);
	sub #(.WORD_SIZE(WORD_SIZE)) uut_sub_m2 (add_m_in1, DRS_out, add_m2);
	logic [WORD_SIZE:0] add_m = op ? add_m1 : add_m2;
	logic [1:0] mant_ovf = add_m[WORD_SIZE:WORD_SIZE-1];

	//LOD of mantissa addition result
	logic [WORD_SIZE-1:0] LOD_in = {(add_m[WORD_SIZE] | add_m[WORD_SIZE-1]), add_m[WORD_SIZE-2:0]};
	logic [RS-1:0] left_shift;
	LOD #(.WORD_SIZE(WORD_SIZE), .RS($clog2(WORD_SIZE))) l2(.in(LOD_in), .out(left_shift));

	//DSR Left Shifting of mantissa result
	logic [WORD_SIZE-1:0] DLS_left_out_t;
	DLS #(.WORD_SIZE(WORD_SIZE), .RS(RS)) dsl1(.a(add_m[WORD_SIZE:1]), .b(left_shift), .c(DLS_left_out_t));
	logic [WORD_SIZE-1:0] DLS_left_out = DLS_left_out_t[WORD_SIZE-1] ? DLS_left_out_t[WORD_SIZE-1:0] : {DLS_left_out_t[WORD_SIZE-2:0],1'b0}; 


	//Exponent and Regime Computation
	logic [RS:0] lr_N = lrc ? {1'b0,lr} : -{1'b0,lr};
	logic [ES+RS+1:0] le_o_tmp, le_o;
	sub #(.WORD_SIZE(ES+RS+1)) sub3 ({lr_N,le}, {{ES+1{1'b0}},left_shift}, le_o_tmp);
	add_mant #(ES+RS+1) uut_add_mantovf (le_o_tmp, mant_ovf[1], le_o);

	logic [ES+RS:0] le_oN = le_o[ES+RS] ? -le_o : le_o;
	logic [ES-1:0] e_o = (le_o[ES+RS] & |le_oN[ES-1:0]) ? le_o[ES-1:0] : le_oN[ES-1:0];
	logic [RS-1:0] r_o = (~le_o[ES+RS] || (le_o[ES+RS] & |le_oN[ES-1:0])) ? le_oN[ES+RS-1:ES] + 1'b1 : le_oN[ES+RS-1:ES];

	//Exponent and Mantissa Packing
	logic [2*WORD_SIZE-1:0]tmp_o = { {WORD_SIZE{~le_o[ES+RS]}}, le_o[ES+RS], e_o, DLS_left_out[WORD_SIZE-2:ES]};
	logic [2*WORD_SIZE-1:0] tmp1_o;
	DRS #(.WORD_SIZE(2*WORD_SIZE), .RS(RS)) dsr2 (.a(tmp_o), .b(r_o), .c(tmp1_o));

	//Final Output
	logic [2*WORD_SIZE-1:0] tmp1_oN = ls ? -tmp1_o : tmp1_o;
	assign out = inf|zero|(~DLS_left_out[WORD_SIZE-1]) ? {inf,{WORD_SIZE-1{1'b0}}} : {ls, tmp1_oN[WORD_SIZE-1:1]},
		valid = ready0;

endmodule