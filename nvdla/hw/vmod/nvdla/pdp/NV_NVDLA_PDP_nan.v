// ================================================================
// NVDLA Open Source Project
// 
// Copyright(c) 2016 - 2017 NVIDIA Corporation.  Licensed under the
// NVDLA Open Hardware License; Check "LICENSE" which comes with 
// this distribution for more information.
// ================================================================

// File Name: NV_NVDLA_PDP_nan.v

module NV_NVDLA_PDP_nan (
   nvdla_core_clk
  ,nvdla_core_rstn
  ,dp2reg_done
  ,nan_preproc_prdy
  ,pdp_rdma2dp_pd
  ,pdp_rdma2dp_valid
  ,reg2dp_flying_mode
  ,reg2dp_input_data
  ,reg2dp_nan_to_zero
  ,reg2dp_op_en
  ,dp2reg_inf_input_num
  ,dp2reg_nan_input_num
  ,nan_preproc_pd
  ,nan_preproc_pvld
  ,pdp_rdma2dp_ready
  );
input         nvdla_core_clk;
input         nvdla_core_rstn;
input         dp2reg_done;
input         nan_preproc_prdy;
input  [75:0] pdp_rdma2dp_pd;
input         pdp_rdma2dp_valid;
input         reg2dp_flying_mode;
input   [1:0] reg2dp_input_data;
input         reg2dp_nan_to_zero;
input         reg2dp_op_en;
output [31:0] dp2reg_inf_input_num;
output [31:0] dp2reg_nan_input_num;
output [75:0] nan_preproc_pd;
output        nan_preproc_pvld;
output        pdp_rdma2dp_ready;
reg           cube_end_d1;
reg    [11:0] datin_info_d;
reg           din_pvld_d1;
reg    [31:0] dp2reg_inf_input_num;
reg    [31:0] dp2reg_nan_input_num;
reg    [31:0] inf_in_count;
reg    [31:0] inf_in_num0;
reg    [31:0] inf_in_num1;
reg     [2:0] inf_num_in_8byte_d1;
reg           layer_flag;
reg           mon_inf_in_count;
reg           mon_nan_in_count;
reg    [31:0] nan_in_count;
reg    [31:0] nan_in_num0;
reg    [31:0] nan_in_num1;
reg     [2:0] nan_num_in_8byte_d1;
reg    [15:0] nan_preproc_pd0;
reg    [15:0] nan_preproc_pd1;
reg    [15:0] nan_preproc_pd2;
reg    [15:0] nan_preproc_pd3;
reg           op_en_d1;
reg           waiting_for_op_en;
reg           wdma_layer_flag;
wire          cube_end;
wire    [3:0] dat_is_inf;
wire    [3:0] dat_is_nan;
wire          din_prdy_d1;
wire          fp16_en;
wire   [15:0] fp16_in_pd_0;
wire   [15:0] fp16_in_pd_1;
wire   [15:0] fp16_in_pd_2;
wire   [15:0] fp16_in_pd_3;
wire    [2:0] inf_num_in_8byte;
wire    [1:0] inf_num_in_8byte_0;
wire    [1:0] inf_num_in_8byte_1;
wire          layer_end;
wire          load_din;
wire          load_din_d1;
wire    [2:0] nan_num_in_8byte;
wire    [1:0] nan_num_in_8byte_0;
wire    [1:0] nan_num_in_8byte_1;
wire          onfly_en;
wire          op_en_load;
wire          pdp_rdma2dp_ready_f;
wire          tozero_en;
wire          wdma_done;
// synoff nets

// monitor nets

// debug nets

// tie high nets

// tie low nets

// no connect nets

// not all bits used nets

// todo nets

    
//&Force internal /pdp_nanin_intr/;
//==========================================
//DP input side
//==========================================
//----------------------------------------
//pdp_rdma2dp_pd[78:0]
//pdp_rdma2dp_valid
//pdp_rdma2dp_ready
assign pdp_rdma2dp_ready = pdp_rdma2dp_ready_f;
assign pdp_rdma2dp_ready_f = (~din_pvld_d1 | din_prdy_d1) & (~waiting_for_op_en);
assign load_din = pdp_rdma2dp_valid & pdp_rdma2dp_ready_f;
//----------------------------------------
//assign propagate_en = reg2dp_nan_to_zero == NVDLA_PDP_D_NAN_FLUSH_TO_ZERO_0_NAN_TO_ZERO_DISABLE;
assign tozero_en = reg2dp_nan_to_zero == 1'h1 ;
assign fp16_en = (reg2dp_input_data[1:0]== 2'h2 );
assign onfly_en = (reg2dp_flying_mode == 1'h0 );
//----------------------------------------
assign fp16_in_pd_0 = pdp_rdma2dp_pd[15:0]  ;
assign fp16_in_pd_1 = pdp_rdma2dp_pd[31:16] ;
assign fp16_in_pd_2 = pdp_rdma2dp_pd[47:32] ;
assign fp16_in_pd_3 = pdp_rdma2dp_pd[63:48] ;

assign dat_is_nan[0] = fp16_en & (&fp16_in_pd_0[14:10]) & (|fp16_in_pd_0[9:0]);
assign dat_is_nan[1] = fp16_en & (&fp16_in_pd_1[14:10]) & (|fp16_in_pd_1[9:0]);
assign dat_is_nan[2] = fp16_en & (&fp16_in_pd_2[14:10]) & (|fp16_in_pd_2[9:0]);
assign dat_is_nan[3] = fp16_en & (&fp16_in_pd_3[14:10]) & (|fp16_in_pd_3[9:0]);

assign dat_is_inf[0] = fp16_en & (&fp16_in_pd_0[14:10]) & (~(|fp16_in_pd_0[9:0]));
assign dat_is_inf[1] = fp16_en & (&fp16_in_pd_1[14:10]) & (~(|fp16_in_pd_1[9:0]));
assign dat_is_inf[2] = fp16_en & (&fp16_in_pd_2[14:10]) & (~(|fp16_in_pd_2[9:0]));
assign dat_is_inf[3] = fp16_en & (&fp16_in_pd_3[14:10]) & (~(|fp16_in_pd_3[9:0]));

//////////////////////////////////////////////////////////////////////
//waiting for op_en
//////////////////////////////////////////////////////////////////////
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    op_en_d1 <= 1'b0;
  end else begin
  op_en_d1 <= reg2dp_op_en;
  end
end
assign op_en_load = reg2dp_op_en & (~op_en_d1);
assign layer_end = &{pdp_rdma2dp_pd[75],pdp_rdma2dp_pd[71]} & load_din;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    waiting_for_op_en <= 1'b1;
  end else begin
    if(layer_end & (~onfly_en))
        waiting_for_op_en <= 1'b1;
    else if(op_en_load) begin
        if(onfly_en)
            waiting_for_op_en <= 1'b1;
        else if(~onfly_en)
            waiting_for_op_en <= 1'b0;
    end
  end
end

//VCS coverage off
`ifndef DISABLE_FUNCPOINT
  `ifdef ENABLE_FUNCPOINT

    reg funcpoint_cover_off;
    initial begin
        if ( $test$plusargs( "cover_off" ) ) begin
            funcpoint_cover_off = 1'b1;
        end else begin
            funcpoint_cover_off = 1'b0;
        end
    end

    property RDMA_NewLayer_out_req_And_core_CurLayer_not_finish__0_cov;
        disable iff((nvdla_core_rstn !== 1) || funcpoint_cover_off)
        @(posedge nvdla_core_clk)
        waiting_for_op_en & (~pdp_rdma2dp_ready_f) & pdp_rdma2dp_valid;
    endproperty
    // Cover 0 : "waiting_for_op_en & (~pdp_rdma2dp_ready_f) & pdp_rdma2dp_valid"
    FUNCPOINT_RDMA_NewLayer_out_req_And_core_CurLayer_not_finish__0_COV : cover property (RDMA_NewLayer_out_req_And_core_CurLayer_not_finish__0_cov);

  `endif
`endif
//VCS coverage on

/////////////////////////////////////
//NaN process mode control
/////////////////////////////////////
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    nan_preproc_pd0 <= {16{1'b0}};
    nan_preproc_pd1 <= {16{1'b0}};
    nan_preproc_pd2 <= {16{1'b0}};
    nan_preproc_pd3 <= {16{1'b0}};
    datin_info_d <= {12{1'b0}};
  end else begin
    if(load_din) begin
        nan_preproc_pd0 <= (dat_is_nan[0] & tozero_en) ? 16'd0 : fp16_in_pd_0;
        nan_preproc_pd1 <= (dat_is_nan[1] & tozero_en) ? 16'd0 : fp16_in_pd_1;
        nan_preproc_pd2 <= (dat_is_nan[2] & tozero_en) ? 16'd0 : fp16_in_pd_2;
        nan_preproc_pd3 <= (dat_is_nan[3] & tozero_en) ? 16'd0 : fp16_in_pd_3;
        datin_info_d    <= pdp_rdma2dp_pd[75:64];
    end
  end
end

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    din_pvld_d1 <= 1'b0;
  end else begin
    if(pdp_rdma2dp_valid & (~waiting_for_op_en))
        din_pvld_d1 <= 1'b1;
    else if(din_prdy_d1)
        din_pvld_d1 <= 1'b0;
  end
end
assign din_prdy_d1 = nan_preproc_prdy;
//-------------output data -----------------
assign nan_preproc_pd = {datin_info_d,nan_preproc_pd3,nan_preproc_pd2,nan_preproc_pd1,nan_preproc_pd0};
assign nan_preproc_pvld = din_pvld_d1;

/////////////////////////////////////
//input NaN element count
/////////////////////////////////////
assign cube_end = pdp_rdma2dp_pd[75];

assign nan_num_in_8byte_0[1:0] = dat_is_nan[0] + dat_is_nan[1];
assign nan_num_in_8byte_1[1:0] = dat_is_nan[2] + dat_is_nan[3];
assign nan_num_in_8byte[2:0]   = nan_num_in_8byte_0 + nan_num_in_8byte_1;

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    cube_end_d1 <= 1'b0;
  end else begin
  if ((load_din) == 1'b1) begin
    cube_end_d1 <= cube_end;
  // VCS coverage off
  end else if ((load_din) == 1'b0) begin
  end else begin
    cube_end_d1 <= 'bx;  // spyglass disable STARC-2.10.1.6 W443 NoWidthInBasedNum-ML -- (Constant containing x or z used, Based number `bx contains an X, Width specification missing for based number)
  // VCS coverage on
  end
  end
end
`ifdef SPYGLASS_ASSERT_ON
`else
// spyglass disable_block NoWidthInBasedNum-ML 
// spyglass disable_block STARC-2.10.3.2a 
// spyglass disable_block STARC05-2.1.3.1 
// spyglass disable_block STARC-2.1.4.6 
// spyglass disable_block W116 
// spyglass disable_block W154 
// spyglass disable_block W239 
// spyglass disable_block W362 
// spyglass disable_block WRN_58 
// spyglass disable_block WRN_61 
`endif // SPYGLASS_ASSERT_ON
`ifdef ASSERT_ON
`ifdef FV_ASSERT_ON
`define ASSERT_RESET nvdla_core_rstn
`else
`ifdef SYNTHESIS
`define ASSERT_RESET nvdla_core_rstn
`else
`ifdef ASSERT_OFF_RESET_IS_X
`define ASSERT_RESET ((1'bx === nvdla_core_rstn) ? 1'b0 : nvdla_core_rstn)
`else
`define ASSERT_RESET ((1'bx === nvdla_core_rstn) ? 1'b1 : nvdla_core_rstn)
`endif // ASSERT_OFF_RESET_IS_X
`endif // SYNTHESIS
`endif // FV_ASSERT_ON
`ifndef SYNTHESIS
  // VCS coverage off 
  nv_assert_no_x #(0,1,0,"No X's allowed on control signals")      zzz_assert_no_x_1x (nvdla_core_clk, `ASSERT_RESET, 1'd1,  (^(load_din))); // spyglass disable W504 SelfDeterminedExpr-ML 
  // VCS coverage on
`endif
`undef ASSERT_RESET
`endif // ASSERT_ON
`ifdef SPYGLASS_ASSERT_ON
`else
// spyglass enable_block NoWidthInBasedNum-ML 
// spyglass enable_block STARC-2.10.3.2a 
// spyglass enable_block STARC05-2.1.3.1 
// spyglass enable_block STARC-2.1.4.6 
// spyglass enable_block W116 
// spyglass enable_block W154 
// spyglass enable_block W239 
// spyglass enable_block W362 
// spyglass enable_block WRN_58 
// spyglass enable_block WRN_61 
`endif // SPYGLASS_ASSERT_ON
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    nan_num_in_8byte_d1 <= {3{1'b0}};
  end else begin
  if ((load_din) == 1'b1) begin
    nan_num_in_8byte_d1 <= nan_num_in_8byte[2:0];
  // VCS coverage off
  end else if ((load_din) == 1'b0) begin
  end else begin
    nan_num_in_8byte_d1 <= 'bx;  // spyglass disable STARC-2.10.1.6 W443 NoWidthInBasedNum-ML -- (Constant containing x or z used, Based number `bx contains an X, Width specification missing for based number)
  // VCS coverage on
  end
  end
end
`ifdef SPYGLASS_ASSERT_ON
`else
// spyglass disable_block NoWidthInBasedNum-ML 
// spyglass disable_block STARC-2.10.3.2a 
// spyglass disable_block STARC05-2.1.3.1 
// spyglass disable_block STARC-2.1.4.6 
// spyglass disable_block W116 
// spyglass disable_block W154 
// spyglass disable_block W239 
// spyglass disable_block W362 
// spyglass disable_block WRN_58 
// spyglass disable_block WRN_61 
`endif // SPYGLASS_ASSERT_ON
`ifdef ASSERT_ON
`ifdef FV_ASSERT_ON
`define ASSERT_RESET nvdla_core_rstn
`else
`ifdef SYNTHESIS
`define ASSERT_RESET nvdla_core_rstn
`else
`ifdef ASSERT_OFF_RESET_IS_X
`define ASSERT_RESET ((1'bx === nvdla_core_rstn) ? 1'b0 : nvdla_core_rstn)
`else
`define ASSERT_RESET ((1'bx === nvdla_core_rstn) ? 1'b1 : nvdla_core_rstn)
`endif // ASSERT_OFF_RESET_IS_X
`endif // SYNTHESIS
`endif // FV_ASSERT_ON
`ifndef SYNTHESIS
  // VCS coverage off 
  nv_assert_no_x #(0,1,0,"No X's allowed on control signals")      zzz_assert_no_x_2x (nvdla_core_clk, `ASSERT_RESET, 1'd1,  (^(load_din))); // spyglass disable W504 SelfDeterminedExpr-ML 
  // VCS coverage on
`endif
`undef ASSERT_RESET
`endif // ASSERT_ON
`ifdef SPYGLASS_ASSERT_ON
`else
// spyglass enable_block NoWidthInBasedNum-ML 
// spyglass enable_block STARC-2.10.3.2a 
// spyglass enable_block STARC05-2.1.3.1 
// spyglass enable_block STARC-2.1.4.6 
// spyglass enable_block W116 
// spyglass enable_block W154 
// spyglass enable_block W239 
// spyglass enable_block W362 
// spyglass enable_block WRN_58 
// spyglass enable_block WRN_61 
`endif // SPYGLASS_ASSERT_ON
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    inf_num_in_8byte_d1 <= {3{1'b0}};
  end else begin
  if ((load_din) == 1'b1) begin
    inf_num_in_8byte_d1 <= inf_num_in_8byte[2:0];
  // VCS coverage off
  end else if ((load_din) == 1'b0) begin
  end else begin
    inf_num_in_8byte_d1 <= 'bx;  // spyglass disable STARC-2.10.1.6 W443 NoWidthInBasedNum-ML -- (Constant containing x or z used, Based number `bx contains an X, Width specification missing for based number)
  // VCS coverage on
  end
  end
end
`ifdef SPYGLASS_ASSERT_ON
`else
// spyglass disable_block NoWidthInBasedNum-ML 
// spyglass disable_block STARC-2.10.3.2a 
// spyglass disable_block STARC05-2.1.3.1 
// spyglass disable_block STARC-2.1.4.6 
// spyglass disable_block W116 
// spyglass disable_block W154 
// spyglass disable_block W239 
// spyglass disable_block W362 
// spyglass disable_block WRN_58 
// spyglass disable_block WRN_61 
`endif // SPYGLASS_ASSERT_ON
`ifdef ASSERT_ON
`ifdef FV_ASSERT_ON
`define ASSERT_RESET nvdla_core_rstn
`else
`ifdef SYNTHESIS
`define ASSERT_RESET nvdla_core_rstn
`else
`ifdef ASSERT_OFF_RESET_IS_X
`define ASSERT_RESET ((1'bx === nvdla_core_rstn) ? 1'b0 : nvdla_core_rstn)
`else
`define ASSERT_RESET ((1'bx === nvdla_core_rstn) ? 1'b1 : nvdla_core_rstn)
`endif // ASSERT_OFF_RESET_IS_X
`endif // SYNTHESIS
`endif // FV_ASSERT_ON
`ifndef SYNTHESIS
  // VCS coverage off 
  nv_assert_no_x #(0,1,0,"No X's allowed on control signals")      zzz_assert_no_x_3x (nvdla_core_clk, `ASSERT_RESET, 1'd1,  (^(load_din))); // spyglass disable W504 SelfDeterminedExpr-ML 
  // VCS coverage on
`endif
`undef ASSERT_RESET
`endif // ASSERT_ON
`ifdef SPYGLASS_ASSERT_ON
`else
// spyglass enable_block NoWidthInBasedNum-ML 
// spyglass enable_block STARC-2.10.3.2a 
// spyglass enable_block STARC05-2.1.3.1 
// spyglass enable_block STARC-2.1.4.6 
// spyglass enable_block W116 
// spyglass enable_block W154 
// spyglass enable_block W239 
// spyglass enable_block W362 
// spyglass enable_block WRN_58 
// spyglass enable_block WRN_61 
`endif // SPYGLASS_ASSERT_ON

assign load_din_d1 = din_pvld_d1 & din_prdy_d1;
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    {mon_nan_in_count,nan_in_count[31:0]} <= {33{1'b0}};
  end else begin
    if(load_din_d1) begin
        if(cube_end_d1)
            {mon_nan_in_count,nan_in_count[31:0]} <= 33'd0;
        else
            {mon_nan_in_count,nan_in_count[31:0]} <= nan_in_count + nan_num_in_8byte_d1;
    end
  end
end

assign inf_num_in_8byte_0[1:0] = dat_is_inf[0] + dat_is_inf[1];
assign inf_num_in_8byte_1[1:0] = dat_is_inf[2] + dat_is_inf[3];
assign inf_num_in_8byte[2:0]   = inf_num_in_8byte_0 + inf_num_in_8byte_1;
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    {mon_inf_in_count,inf_in_count[31:0]} <= {33{1'b0}};
  end else begin
    if(load_din_d1) begin
        if(cube_end_d1)
            {mon_inf_in_count,inf_in_count[31:0]} <= 33'd0;
        else
            {mon_inf_in_count,inf_in_count[31:0]} <= inf_in_count + inf_num_in_8byte_d1;
    end
  end
end
`ifdef SPYGLASS_ASSERT_ON
`else
// spyglass disable_block NoWidthInBasedNum-ML 
// spyglass disable_block STARC-2.10.3.2a 
// spyglass disable_block STARC05-2.1.3.1 
// spyglass disable_block STARC-2.1.4.6 
// spyglass disable_block W116 
// spyglass disable_block W154 
// spyglass disable_block W239 
// spyglass disable_block W362 
// spyglass disable_block WRN_58 
// spyglass disable_block WRN_61 
`endif // SPYGLASS_ASSERT_ON
`ifdef ASSERT_ON
`ifdef FV_ASSERT_ON
`define ASSERT_RESET nvdla_core_rstn
`else
`ifdef SYNTHESIS
`define ASSERT_RESET nvdla_core_rstn
`else
`ifdef ASSERT_OFF_RESET_IS_X
`define ASSERT_RESET ((1'bx === nvdla_core_rstn) ? 1'b0 : nvdla_core_rstn)
`else
`define ASSERT_RESET ((1'bx === nvdla_core_rstn) ? 1'b1 : nvdla_core_rstn)
`endif // ASSERT_OFF_RESET_IS_X
`endif // SYNTHESIS
`endif // FV_ASSERT_ON
  // VCS coverage off 
  nv_assert_never #(0,0,"PDP nan: nan counter no overflow is allowed")      zzz_assert_never_4x (nvdla_core_clk, `ASSERT_RESET, mon_nan_in_count | mon_inf_in_count); // spyglass disable W504 SelfDeterminedExpr-ML 
  // VCS coverage on
`undef ASSERT_RESET
`endif // ASSERT_ON
`ifdef SPYGLASS_ASSERT_ON
`else
// spyglass enable_block NoWidthInBasedNum-ML 
// spyglass enable_block STARC-2.10.3.2a 
// spyglass enable_block STARC05-2.1.3.1 
// spyglass enable_block STARC-2.1.4.6 
// spyglass enable_block W116 
// spyglass enable_block W154 
// spyglass enable_block W239 
// spyglass enable_block W362 
// spyglass enable_block WRN_58 
// spyglass enable_block WRN_61 
`endif // SPYGLASS_ASSERT_ON

always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    layer_flag <= 1'b0;
    nan_in_num1 <= {32{1'b0}};
    inf_in_num1 <= {32{1'b0}};
    nan_in_num0 <= {32{1'b0}};
    inf_in_num0 <= {32{1'b0}};
  end else begin
    if(load_din_d1 & cube_end_d1) begin
        layer_flag <= ~layer_flag;
        if(layer_flag) begin
            nan_in_num1 <= nan_in_count;
            inf_in_num1 <= inf_in_count;
        end else begin
            nan_in_num0 <= nan_in_count;
            inf_in_num0 <= inf_in_count;
        end
    end
  end
end

//adding dp2reg_done to latch the num and output a sigle one for each
assign wdma_done = dp2reg_done;
always @(posedge nvdla_core_clk or negedge nvdla_core_rstn) begin
  if (!nvdla_core_rstn) begin
    wdma_layer_flag <= 1'b0;
    dp2reg_nan_input_num <= {32{1'b0}};
    dp2reg_inf_input_num <= {32{1'b0}};
  end else begin
    if(wdma_done) begin
        wdma_layer_flag <= ~wdma_layer_flag;
        if(wdma_layer_flag) begin
            dp2reg_nan_input_num <= nan_in_num1;
            dp2reg_inf_input_num <= inf_in_num1;
        end else begin
            dp2reg_nan_input_num <= nan_in_num0;
            dp2reg_inf_input_num <= inf_in_num0;
        end
    end
  end
end

/////////////////////////////////////
////input NaN element interrupt
/////////////////////////////////////
//&Always posedge;
//    if(load_din) begin
//        if(|dat_is_nan) begin
//            if(cube_end)
//                nan_in_flag <0= 1'b0;
//            else
//                nan_in_flag <0= 1'b1;
//        end
//    end
//&End;
//assign flag_1st_nan = load_din & (|dat_is_nan) & (~nan_in_flag) & (~cube_end);
//&Always posedge;
//    if(load_din & cube_end & (|dat_is_nan) & (~nan_in_flag))
//        cubend_is_1st_nan <0= 1'b1;
//    else
//        cubend_is_1st_nan <0= 1'b0;
//&End;


//==============
//function points
//==============
//VCS coverage off
`ifndef DISABLE_FUNCPOINT
  `ifdef ENABLE_FUNCPOINT

    property PDP_RDMA2CORE__rdma_layerDone_stall__1_cov;
        disable iff((nvdla_core_rstn !== 1) || funcpoint_cover_off)
        @(posedge nvdla_core_clk)
        waiting_for_op_en & (~pdp_rdma2dp_ready_f);
    endproperty
    // Cover 1 : "waiting_for_op_en & (~pdp_rdma2dp_ready_f)"
    FUNCPOINT_PDP_RDMA2CORE__rdma_layerDone_stall__1_COV : cover property (PDP_RDMA2CORE__rdma_layerDone_stall__1_cov);

  `endif
`endif
//VCS coverage on


//////////////////////////////////////////////////////////////////////
endmodule // NV_NVDLA_PDP_nan


