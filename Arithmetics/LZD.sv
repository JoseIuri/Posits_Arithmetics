module LZD
#(
  parameter WORD_SIZE = 32,
  parameter RS        = 5 //$clog2(WORD_SIZE)
)(
  input logic  [WORD_SIZE-1:0]  in,
  output logic [RS-1:0]  		out,
  output logic 					vld
);

	generate
		if(WORD_SIZE == 2) begin
			assign vld = ~&in;
			assign out = (~in[0]) & in[1];
		end
		else if (WORD_SIZE & (WORD_SIZE-1)) 
		begin
			LOD #(.WORD_SIZE(1<<RS), .RS($clog2(1<<RS))) LOD ({1<<RS {1'b0}} | in,out,vld);
		end
		else begin

			logic [RS-2:0] out_l;
			logic [RS-2:0] out_h;
			logic 		   out_vl;
			logic		   out_vh;

			LOD #(.WORD_SIZE(WORD_SIZE>>1), .RS($clog2(WORD_SIZE>>1))) l (in[(WORD_SIZE>>1)-1:0],out_l,out_vl);
			LOD #(.WORD_SIZE(WORD_SIZE>>1), .RS($clog2(WORD_SIZE>>1))) h (in[WORD_SIZE-1:WORD_SIZE>>1],out_h,out_vh);
			assign vld = out_vl | out_vh;
			assign out = out_vh ? {1'b0,out_h} : {out_vl,out_l};

		end // else
	endgenerate
endmodule