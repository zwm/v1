//////////////////////////////////////////////////////////////////////////////
// Module Name          : vdec_hs_fwd                                       //
//                                                                          //
// Type                 : Module                                            //
//                                                                          //
// Module Description   : Forward metric calc, features:                    //
//                        Code rate         : only 1/3                      //
//                        Codeblk_size      : 8, 29, 22                     //
//                        Tail bits         : 8                             //
//                                                                          //
// Timing Constraints   : Module is designed to work with a clock frequency //
//                        of 307.2 MHz                                      //
//                                                                          //
// Revision History     : 20170926    V0.1    File created                  //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
module vdec_hs_fwd (
    clk,
    rst,
    start,
    busy,
    done,
    codeblk_size_p7,    // ???
    hs_mode,
    ue_mask,
    base_sys,
    mp_sel_AB,
    mp_sel_CD,
    diram_rd_req,
    diram_rd_ack,
    diram_raddr,
    diram_rdata,
    sm0_rd,
    sm0_wr,
    sm0_addr,
    sm0_din,
    sm0_dout,
    sm1_rd,
    sm1_wr,
    sm1_addr,
    sm1_din,
    sm1_dout,
    pt_wr,
    pt_addr,
    pt_din
);

//---------------------------------------------------------------------------
// port
//---------------------------------------------------------------------------
input                       clk;
input                       rst;
input                       start;
output                      busy;
output                      done;
input   [5:0]               codeblk_size_p7;    // part1: 8+7, part2: 29+7, agch: 22+7
input   [1:0]               hs_mode;            // 00: part1, 01: part2, 10: agch
input   [15:0]              ue_mask;
input   [ 8:0]              base_sys;
input                       mp_sel_AB;
input                       mp_sel_CD;
output                      diram_rd_req;
input                       diram_rd_ack;
output  [ 8:0]              diram_raddr;        // 608x24b
input   [23:0]              diram_rdata;
output                      sm0_rd;
output                      sm0_wr;
output  [5:0]               sm0_addr;
output  [31:0]              sm0_din;
input   [31:0]              sm0_dout;
output                      sm1_rd;
output                      sm1_wr;
output  [5:0]               sm1_addr;
output  [31:0]              sm1_din;
input   [31:0]              sm1_dout;
output                      pt_wr;
output  [8:0]               pt_addr;            // ptram: 37*8*32b=296*32b
output  [31:0]              pt_din;
reg                         busy;
reg                         diram_rd_req;
reg     [ 8:0]              diram_raddr;
reg     [31:0]              sm0_din;
reg     [31:0]              sm1_din;
reg                         pt_wr;
reg     [8:0]               pt_addr;            // ptram: 37*8*32b=296*32b
reg     [31:0]              pt_din;

// internal wires
reg                         c_ini;
reg                         pre_load;
reg     [ 1:0]              pre_load_cnt;
reg                         diram_rd_pend;
reg     [41:0]              diram_cache;
reg     [ 2:0]              diram_cache_cnt;
wire                        diram_cache_low;
reg                         c_stat;             // debug only!!!
reg     [ 5:0]              c0_next;
reg     [ 5:0]              c1_next;
reg     [ 5:0]              c2_next;
reg     [ 5:0]              c0;
reg     [ 5:0]              c1;
reg     [ 5:0]              c2;
reg     [ 5:0]              stage;      // 0~44
reg     [ 6:0]              code_index; // coded symbol index, 0~111
reg                         fwd_start;
reg                         cyc_en;
reg     [ 6:0]              cyc;
wire                        smram_sel;
wire                        smram_rd;
wire                        smram_wr;
wire    [ 5:0]              sm_rd_addr;
wire    [ 5:0]              sm_wr_addr;
reg     [ 6:0]              cyc_d1;
reg     [ 6:0]              cyc_d2;
reg     [ 6:0]              cyc_d3;
reg     [ 6:0]              cyc_d4;
reg     [ 6:0]              cyc_d5;
reg     [ 6:0]              cyc_d6;
reg                         smram_sel_d1;
reg                         smram_sel_d2;
reg                         smram_sel_d3;
reg                         smram_sel_d4;
reg                         smram_sel_d5;
reg                         smram_sel_d6;
reg                         smram_rd_d1;
reg                         smram_rd_d2;
reg                         smram_rd_d3;
reg                         smram_rd_d4;
reg                         smram_rd_d5;
reg                         smram_rd_d6;
wire    [23:0]              smram_dout;
reg     [31:0]              a_states_reg;
reg     [31:0]              b_states_reg;
wire                        e0;
wire                        e1;
wire                        e2;
wire    [ 5:0]              abs_c0;
wire    [ 5:0]              abs_c1;
wire    [ 5:0]              abs_c2;
wire    [ 5:0]              abs_c01;
wire    [ 5:0]              abs_c12;
wire    [ 5:0]              abs_c02;
wire    [ 6:0]              abs_c012;
reg     [ 6:0]              branch_ac;
reg     [ 6:0]              branch_bc;
reg     [ 6:0]              branch_ac_d1;
reg     [ 6:0]              branch_bc_d1;
wire    [ 2:0]              match;
reg     [ 7:0]              path_a;
reg     [ 7:0]              path_b;
wire    [ 8:0]              path_ac;
wire    [ 8:0]              path_bc;
wire    [ 8:0]              path_ad;
wire    [ 8:0]              path_bd;
wire    [ 9:0]              diff_c;
wire    [ 9:0]              diff_d;
wire                        sel_ac_bc;
wire                        sel_ad_bd;
wire    [ 8:0]              state_c_win;
wire    [ 8:0]              state_d_win;
wire                        state_c_src;
wire                        state_d_src;
wire    [ 8:0]              norm_c;
wire    [ 8:0]              norm_d;
wire    [ 7:0]              state_c;
wire    [ 7:0]              state_d;
wire    [ 9:0]              diff_cd;
wire                        sel_cd;
wire    [ 7:0]              state_min_cd;
wire    [ 8:0]              diff_min_sofar;
reg     [ 7:0]              min_sofar;
reg     [ 7:0]              min_state;
reg     [31:0]              next_a_states;
reg     [31:0]              next_b_states;
reg     [29:0]              pt_cache;
reg                         done_tmp1;
reg                         done_tmp2;
reg                         done_tmp3;
reg                         done_tmp4;
reg     [ 7:0]              cc_reg;
reg                         cc_in;
wire                        cc_g0;
wire                        cc_g1;
//---------------------------------------------------------------------------
//                              SUMMARY
// This module include two parts:
//      1. diram read, deratematching
//      2. forward metric calc
//---------------------------------------------------------------------------

//---------------------------------------------------------------------------
//                      PART 1 : DIRAM Read & De-ratematching
//---------------------------------------------------------------------------
// C0/1/2 are used during cyc_d2 = 0~255, so new C0/1/2 should be loaded at 
// cyc_d2==255, that is cyc==1. To keep continuous of forward pipeline, C0/1/2 
// shall be prepared before cyc==1. At first stage, we prepare C0/1/2 in
// advanc, but in the following stages, we prepare C0/1/2 when caculating
// the 256 state metrics, start at time cyc==2.
//---------------------------------------------------------------------------
// initial c_next fill_up
// After first c_next fill_up, forward process will be started actually!
always @(posedge clk or posedge rst) begin
    if (rst) begin
        c_ini <= 0;
    end
    else begin
        if (start) begin
            c_ini <= 1;
        end
        else if (fwd_start) begin
            c_ini <= 0;
        end
    end
end
// fwd_start
always @(posedge clk or posedge rst) begin
    if (rst) begin
        fwd_start <= 0;
    end
    else begin
        if (c_ini & pre_load & pre_load_cnt == 2'd2 & (~diram_cache_low)) begin
            fwd_start <= 1;
        end
        else begin
            fwd_start <= 0;
        end
    end
end
// pre_load
// cyc==1 load new c_data, cyc==2 start load c_next
always @(posedge clk or posedge rst) begin
    if (rst) begin
        pre_load <= 0;
    end
    else begin
        if (start) begin
            pre_load <= 1;
        end
        else if (cyc == 7'd2) begin
            pre_load <= 1;
        end
        else if (pre_load_cnt == 2'd2 && diram_cache_low == 1'b0) begin
            pre_load <= 0;
        end
    end
end
// pre_load_cnt
always @(posedge clk or posedge rst) begin
    if (rst) begin
        pre_load_cnt <= 2'd0;
    end
    else begin
        if (pre_load) begin
            if (~diram_cache_low) begin
                pre_load_cnt <= pre_load_cnt + 1;
            end
        end
        else begin
            pre_load_cnt <= 2'd0;
        end
    end
end
// HS-SCCH Part1 UE specific masking
// cc_in
always (*) begin
    if (hs_mode == 2'b00) begin
        case (code_index[6:1])
            6'd0    : cc_in = ue_mask[0];
            6'd1    : cc_in = ue_mask[1];
            6'd2    : cc_in = ue_mask[2];
            6'd3    : cc_in = ue_mask[3];
            6'd4    : cc_in = ue_mask[4];
            6'd5    : cc_in = ue_mask[5];
            6'd6    : cc_in = ue_mask[6];
            6'd7    : cc_in = ue_mask[7];
            6'd8    : cc_in = ue_mask[8];
            6'd9    : cc_in = ue_mask[9];
            6'd10   : cc_in = ue_mask[10];
            6'd11   : cc_in = ue_mask[11];
            6'd12   : cc_in = ue_mask[12];
            6'd13   : cc_in = ue_mask[13];
            6'd14   : cc_in = ue_mask[14];
            6'd15   : cc_in = ue_mask[15];
            default : cc_in = 1'd0;
        endcase
    end
    else begin
        cc_in = 1'd0;
    end
end
// cc_reg
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cc_reg <= 8'd0;
    end
    else begin
        if (start) begin
            cc_reg <= 8'd0;
        end
        else if (hs_mode == 2'b00)       // part1
            if (pre_load == 1 && diram_cache_low == 0 && code_index[0] == 1) begin
                cc_reg <= {cc_in, cc_reg[7:1]};
            end
        end
    end
end
// UEID CC output
assign cc_g0 = cc_reg[7] ^ cc_reg[3] ^ cc_reg[2] ^ cc_reg[1] ^ cc_in;
assign cc_g1 = cc_reg[7] ^ cc_reg[6] ^ cc_reg[4] ^ cc_reg[2] ^ cc_reg[1] ^ cc_reg[0] ^ cc_in;
// pre_load c0/1/2 next
always @(posedge clk or posedge rst) begin
    if (rst) begin
        code_index <= 7'd0;
        c0_next <= 6'd0;
        c1_next <= 6'd0;
        c2_next <= 6'd0;
    end
    else begin
        if (start) begin
            code_index <= 7'd0;
            c0_next <= 6'd0;
            c1_next <= 6'd0;
            c2_next <= 6'd0;
        end
        else if (pre_load) begin
            if (~diram_cache_low) begin
                code_index <= code_index + 1;
                // c0
                if (pre_load_cnt == 2'd0) begin
                    if (punc) begin
                        c0_next <= 6'd0;
                    end
                    else begin
                        if (code_index[0]) begin
                            c0_next <= ({6{cc_g0}} ^ diram_cache[41:36]) + cc_reg0;
                        end
                        else begin
                            c0_next <= ({6{cc_g1}} ^ diram_cache[41:36]) + cc_reg1;
                        end
                    end
                end
                // c1
                if (pre_load_cnt == 2'd1) begin
                    if (punc) begin
                        c1_next <= 6'd0;
                    end
                    else begin
                        if (code_index[0]) begin
                            c1_next <= ({6{cc_g0}} ^ diram_cache[41:36]) + cc_reg0;
                        end
                        else begin
                            c1_next <= ({6{cc_g1}} ^ diram_cache[41:36]) + cc_reg1;
                        end
                    end
                end
                // c2
                if (pre_load_cnt == 2'd2) begin
                    if (punc) begin
                        c2_next <= 6'd0;
                    end
                    else begin
                        if (code_index[0]) begin
                            c2_next <= ({6{cc_g0}} ^ diram_cache[41:36]) + cc_reg0;
                        end
                        else begin
                            c2_next <= ({6{cc_g1}} ^ diram_cache[41:36]) + cc_reg1;
                        end
                    end
                end
            end
        end
    end
end
// pre_load_cnt
always @(posedge clk or posedge rst) begin
    if (rst) begin
        pre_load_cnt <= 2'd0;
    end
    else begin
        if (pre_load) begin
            if (~diram_cache_low) begin
                pre_load_cnt <= pre_load_cnt + 1;
            end
        end
        else begin
            pre_load_cnt <= 2'd0;
        end
    end
end
// diram_rd_req
always @(posedge clk or posedge rst) begin
    if (rst) begin
        diram_rd_req <= 0;
    end
    else begin
        if (busy) begin
            if ((~diram_rd_req) & (~diram_rd_pend) & diram_cache_low) begin
                diram_rd_req <= 1;
            end
            else begin
                diram_rd_req <= 0;
            end
        end
        else begin
            diram_rd_req <= 0;
        end
    end
end
// diram_rd_pend
always @(posedge clk or posedge rst) begin
    if (rst) begin
        diram_rd_pend <= 0;
    end
    else begin
        if (busy) begin
            if ((~diram_rd_req) & (~diram_rd_pend) & diram_cache_low) begin
                diram_rd_pend <= 1;
            end
            else if (diram_rd_ack) begin
                diram_rd_pend <= 0;
            end
        end
        else begin
            diram_rd_pend <= 0;
        end
    end
end
// diram_raddr
always @(posedge clk or posedge rst) begin
    if (rst) begin
        diram_raddr <= 0;
    end
    else begin
        if (start) begin
            diram_raddr <= base_sys;
        end
        else if (busy & diram_rd_ack) begin
            diram_raddr <= diram_raddr + 1;
        end
    end
end
// diram_cache proc
// TTRAM FORMAT: {D0, D1, D2, D3}, so diram_cache must left shift out
always @(posedge clk or posedge rst) begin
    if (rst) begin
        diram_cache <= 0;
        diram_cache_cnt <= 0;
    end
    else begin
        if (start) begin
            diram_cache <= 0;
            diram_cache_cnt <= 0;
        end
        else if (diram_rd_ack) begin
            diram_cache_cnt <= diram_cache_cnt + 3'b100;
            case (diram_cache_cnt)
                3'b000  : diram_cache <= {                    diram_rdata, diram_cache[17:0]};      // empty
                3'b001  : diram_cache <= {diram_cache[41:36], diram_rdata, diram_cache[11:0]};      // 1 left
                3'b010  : diram_cache <= {diram_cache[41:30], diram_rdata, diram_cache[ 5:0]};      // 2 left
                default : diram_cache <= {diram_cache[41:24], diram_rdata                   };      // 3 left
            endcase
        end
        else if (pre_load & (~punc)) begin
            diram_cache_cnt <= diram_cache_cnt - 1;
            diram_cache <= {diram_cache[35:0], 8'd0};
        end
    end
end
// if diram access busy, when cyc==127, pre-load will not be complete, error occurs
always @(posedge clk or posedge rst) begin
    if (rst) begin
        c_stat <= 1'd0;
    end
    else begin
        if (pre_load==1 && cyc==7'd127) begin
            c_stat <= 1'd1;
        end
    end
end
// diram_cahce_low
assign diram_cache_low = ~diram_cache_cnt[2];
// de-ratematching
vdec_hs_derm uderm (
    .hs_mode                ( hs_mode               ),
    .index                  ( code_index            ),
    .punc                   ( punc                  )
);

//---------------------------------------------------------------------------
//                      PART 2 : Metric Calc
//---------------------------------------------------------------------------
// pipeline
//  cyc(0)      rd SM0 state 0~3
//  cyc(1)      rd SM0 state 128~131
//  cyc(2)      no access
//  cyc(3)      no access
//  cyc(4)      rd SM0 state 4~7
//  cyc(5)      rd SM0 state 132~135
//  cyc(6)      wr SM1 state 0~3
//  cyc(7)      wr SM1 state 128~131
//  cyc(8)      rd SM0 state 8~11
//  cyc(9)      rd SM0 state 136~139
//  cyc(10)     wr SM1 state 4~7
//  cyc(11)     wr SM1 state 132~135
//  ...
//---------------------------------------------------------------------------
// cyc_en
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cyc_en <= 1'd0;
    end
    else begin
        if (start) begin
            cyc_en <= 1'd0;
        end
        else if (fwd_start) begin
            cyc_en <= 1'd1;
        end
        else if (stage == codeblk_size_p7 && cyc == 8'd255) begin
            cyc_en <= 1'd0;
        end
    end
end
// cyc
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cyc <= 7'd0;
    end
    else begin
        if (start) begin
            cyc <= 7'd0;
        end
        else if (cyc_en) begin
            cyc <= cyc + 1;
        end
    end
end
// stage
always @(posedge clk or posedge rst) begin
    if (rst) begin
        stage <= 6'd0;
    end
    else begin
        if (start) begin
            stage <= 6'd0;
        end
        else if (cyc == 7'd127) begin
            stage <= stage + 1;
        end
    end
end
// delay
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cyc_d1 <= 6'd0;
        cyc_d2 <= 6'd0;
        cyc_d3 <= 6'd0;
        cyc_d4 <= 6'd0;
        cyc_d5 <= 6'd0;
        cyc_d6 <= 6'd0;
        smram_sel_d1 <= 1'd0;
        smram_sel_d2 <= 1'd0;
        smram_sel_d3 <= 1'd0;
        smram_sel_d4 <= 1'd0;
        smram_sel_d5 <= 1'd0;
        smram_sel_d6 <= 1'd0;
        smram_rd_d1 <= 1'd0;
        smram_rd_d2 <= 1'd0;
        smram_rd_d3 <= 1'd0;
        smram_rd_d4 <= 1'd0;
        smram_rd_d5 <= 1'd0;
        smram_rd_d6 <= 1'd0;
    end
    else begin
        cyc_d1 <= cyc;
        cyc_d2 <= cyc_d1;
        cyc_d3 <= cyc_d2;
        cyc_d4 <= cyc_d3;
        cyc_d5 <= cyc_d4;
        cyc_d6 <= cyc_d5;
        smram_sel_d1 <= smram_sel;
        smram_sel_d2 <= smram_sel_d1;
        smram_sel_d3 <= smram_sel_d2;
        smram_sel_d4 <= smram_sel_d3;
        smram_sel_d5 <= smram_sel_d4;
        smram_sel_d6 <= smram_sel_d5;
        smram_rd_d1 <= smram_rd;
        smram_rd_d2 <= smram_rd_d1;
        smram_rd_d3 <= smram_rd_d2;
        smram_rd_d4 <= smram_rd_d3;
        smram_rd_d5 <= smram_rd_d4;
        smram_rd_d6 <= smram_rd_d5;
    end
end
// smram0/1 rw
assign smram_sel    = stage[0];
assign smram_rd     = cyc_en & (~cyc[1]);       // cyc == 0/1 read
assign sm0_rd       = smram_rd & (~smram_sel) & (stage != 6'd0);     // only sm0 should check is stage0
assign sm1_rd       = smram_rd & ( smram_sel);
assign sm_rd_addr   = {cyc[0], cyc[6:2]};
assign smram_wr     = smram_rd_d6;
assign sm0_wr       = smram_wr & ( smram_sel_d6);
assign sm1_wr       = smram_wr & (~smram_sel_d6);
assign sm_wr_addr   = {cyc_d6[0], cyc_d6[6:2]};
assign sm0_addr     = sm0_rd ? sm_rd_addr : sm_wr_addr;
assign sm1_addr     = sm1_rd ? sm_rd_addr : sm_wr_addr;
// sm0_din
always @(*) begin
    if (smram_sel_d6) begin
        if (cyc_d6[1:0] == 2'b00) begin
            sm0_din <= next_a_states;
        end
        else begin
            sm0_din <= next_b_states;
        end
    end
    else begin
        sm0_din <= 32'd0;
    end
end
// sm1_din
always @(*) begin
    if (smram_sel_d6) begin
        sm1_din <= 32'd0;
    end
    else begin
        if (cyc_d6[1:0] == 2'b00) begin
            sm1_din <= next_a_states;
        end
        else begin
            sm1_din <= next_b_states;
        end
    end
end
// When is stage0, previous state_metric has init value
// state0 = 0, other_state = 8'd255
assign smram_dout = smram_sel_d1 ? sm0_dout : sm1_dout;
// update A&B reg
always @(posedge clk or posedge rst) begin
    if (rst) begin
        a_states_reg <= 32'd0;
        b_states_reg <= 32'd0;
    end
    else begin
        if (cyc_en) begin
            if (stage == 6'd0) begin
                if (cyc[6:2] == 4'd0) begin // first 4 cyc special, else {32{1'b1}}
                    a_states_reg <= {8'd0, {24{1'b1}}}; // state0 init to 0
                end
                else begin
                    a_states_reg <= {32{1'b1}};
                end
                b_states_reg <= {32{1'b1}};
            end
            else begin
                if (smram_rd_d1 & (~cyc_d1[0])) begin
                    a_states_reg <= smram_dout;
                end
                if (smram_rd_d1 & ( cyc_d1[0])) begin
                    b_states_reg <= smram_dout;
                end
            end
        end
    end
end
// load c0/1/2
always @(posedge clk or posedge rst) begin
    if (rst) begin
        c0 <= 6'd0;
        c1 <= 6'd0;
        c2 <= 6'd0;
    end
    else begin
        if (cyc_en & cyc[6:0] == 7'd1) begin
            c0 <= c0_next;
            c1 <= c1_next;
            c2 <= c2_next;
        end
    end
end
//----------------------------------------------------------------------------
// Serial ACS Calculation
//----------------------------------------------------------------------------
// ACS plan:
//
// next_state[7:0] = {current_state[6:0], input_bit}
//
//  A: S('0'&i) -------  C: S(i&'0')
//              \     / 
//               \   / 
//                \ / 
//                 /
//                / \
//               /   \
//              /     \
//             /_______\
//  B: S('1'&i)          D: S(i&'1')
//
//  index_of_A = '0' & i
//  index_of_B = '1' & i
//  index_of_C =       i & '0'
//  index_of_D =       i & '1'
//
//  Output of Each Branch:
//  AC_E0 = reduce_xor (G0 and ('0' & i & '0')) == E0
//  AC_E1 = reduce_xor (G1 and ('0' & i & '0')) == E1
//  AC_E2 = reduce_xor (G2 and ('0' & i & '0')) == E2
//
//  BC_E0 = reduce_xor (G0 and ('1' & i & '0')) == !E0
//  BC_E1 = reduce_xor (G1 and ('1' & i & '0')) == !E1
//  BC_E2 = reduce_xor (G2 and ('1' & i & '0')) == !E2
//
//  AD_E0 = reduce_xor (G0 and ('0' & i & '1')) == !E0
//  AD_E1 = reduce_xor (G1 and ('0' & i & '1')) == !E1
//  AD_E2 = reduce_xor (G2 and ('0' & i & '1')) == !E2
//
//  BD_E0 = reduce_xor (G0 and ('1' & i & '1')) == E0
//  BD_E1 = reduce_xor (G1 and ('1' & i & '1')) == E1
//  BD_E2 = reduce_xor (G2 and ('1' & i & '1')) == E2
//
//  Branch Metric Calc:
//  Because there only exists two kinds of output, so two branch metrics should
//  be calculated.
// E0/1/2 output
assign e0 = cyc_d2[6] ^ cyc_d2[5] ^ cyc_d2[4] ^ cyc_d2[2] ^ cyc_d2[1];
assign e1 = cyc_d2[6] ^ cyc_d2[3] ^ cyc_d2[2] ^ cyc_d2[0];
assign e1 = cyc_d2[4] ^ cyc_d2[1] ^ cyc_d2[0];

assign abs_c0   = ({6{c0[5]}} ^ c0) + c0[5];
assign abs_c1   = ({6{c1[5]}} ^ c1) + c1[5];
assign abs_c2   = ({6{c2[5]}} ^ c2) + c0[5];
assign abs_c01  = abs_c0 + abs_c1;
assign abs_c12  = abs_c1 + abs_c2;
assign abs_c02  = abs_c0 + abs_c2;
assign abs_c012 = {1'b0, abs_c01} + {1'b0, abs_c2};

assign match[0] = c0[5] ^ e0;
assign match[1] = c1[5] ^ e1;
assign match[2] = c2[5] ^ e2;

// branch_ac
always @(*) begin
    case (match)
        3'b000  : branch_ac = abs_c012;
        3'b001  : branch_ac = abs_c12;
        3'b010  : branch_ac = abs_c02;
        3'b011  : branch_ac = abs_c2;
        3'b100  : branch_ac = abs_c01;
        3'b101  : branch_ac = abs_c1;
        3'b110  : branch_ac = abs_c0;
        default : branch_ac = 7'd0;
    endcase
end
// branch_bc
always @(*) begin
    case (~match)
        3'b000  : branch_bc = abs_c012;
        3'b001  : branch_bc = abs_c12;
        3'b010  : branch_bc = abs_c02;
        3'b011  : branch_bc = abs_c2;
        3'b100  : branch_bc = abs_c01;
        3'b101  : branch_bc = abs_c1;
        3'b110  : branch_bc = abs_c0;
        default : branch_bc = 7'd0;
    endcase
end
// branch_ac/bc reg
always @(posedge clk or posedge rst) begin
    if (rst) begin
        branch_ac_d1 <= 7'd0;
        branch_bc_d1 <= 7'd0;
    end
    else begin
        if (cyc_en) begin
            branch_ac_d1 <= branch_ac;
            branch_bc_d1 <= branch_bc;
        end
    end
end
// path_a
always @(*) begin
    case (cyc_d3[1:0])
        2'b00   : path_a = a_states_reg[31:24];
        2'b01   : path_a = a_states_reg[23:16];
        2'b10   : path_a = a_states_reg[15: 8];
        default : path_a = a_states_reg[ 7: 0];
    endcase
end
// path_b
always @(*) begin
    case (cyc_d3[1:0])
        2'b00   : path_b = b_states_reg[31:24];
        2'b01   : path_b = b_states_reg[23:16];
        2'b10   : path_b = b_states_reg[15: 8];
        default : path_b = b_states_reg[ 7: 0];
    endcase
end
// path_ac/bc
assign path_ac      = {1'b0, path_a} + {2'd0, branch_ac_d1};
assign path_bc      = {1'b0, path_b} + {2'd0, branch_bc_d1};
assign path_ad      = {1'b0, path_a} + {2'd0, branch_bc_d1};
assign path_bd      = {1'b0, path_b} + {2'd0, branch_ac_d1};
assign diff_c       = {1'b0, path_bc} - {1'b0, path_ac};
assign diff_d       = {1'b0, path_bd} - {1'b0, path_ad};
assign sel_ac_bc    = (diff_c == 10'd0) ? mp_sel_AB : diff_c[9];
assign sel_ad_bd    = (diff_d == 10'd0) ? mp_sel_AB : diff_d[9];
assign state_c_win  = sel_ac_bc ? path_bc : path_ac;
assign state_d_win  = sel_ad_bd ? path_bd : path_ad;
assign state_c_src  = sel_ac_bc;
assign state_d_src  = sel_ad_bd;
assign norm_c       = state_c_win - {1'b0, min_state};
assign norm_d       = state_d_win - {1'b0, min_state};
assign state_c      = norm_c[8] ? 8'd255 : norm_c[7:0];
assign state_d      = norm_d[8] ? 8'd255 : norm_d[7:0];
assign diff_cd      = {1'b0, state_d_win} - {1'b0, state_c_win};
assign sel_cd       = (diff_cd == 10'd0) ? mp_sel_CD : diff_cd[9];
assign state_min_cd = sel_cd ? state_d : state_c;
assign diff_min_sofar = {1'b0, state_min_cd} - {1'b0, min_sofar};
// state_cd reg
always @(posedge clk or posedge rst) begin
    if (rst) begin
        next_a_states <= 32'd0;
        next_b_states <= 32'd0;
    end
    else begin
        if (busy) begin
            case (cyc_d3[1:0])
                2'b00   : next_a_states[31:16] <= {state_c, state_d};
                2'b01   : next_a_states[15: 0] <= {state_c, state_d};
                2'b10   : next_b_states[31:16] <= {state_c, state_d};
                default : next_b_states[15: 0] <= {state_c, state_d};
            endcase
        end
    end
end
// min_sofar
always @(posedge clk or posedge rst) begin
    if (rst) begin
        min_sofar <= 8'd0;
    end
    else begin
        if (start) begin
            min_sofar <= 8'd0;
        end
        else if (busy) begin
            if (cyc_d3[6:0] == 7'd0 || diff_min_sofar[8]) begin
                min_sofar <= state_min_cd;
            end
        end
    end
end
// min_state
always @(posedge clk or posedge rst) begin
    if (rst) begin
        min_state <= 8'd0;
    end
    else begin
        if (start) begin
            min_state <= 8'd0;
        end
        else if (busy) begin
            if (cyc_d3[6:0] == 7'd127) begin
                if (diff_min_sofar[8]) begin
                    min_state <= state_min_cd;
                end
                else begin
                    min_state <= min_sofar;
                end
            end
        end
    end
end
// ptram write
// Each 16 cyc generate 32 path info, a write to ptram should be performed
// pt_wr
always @(posedge clk or posedge rst) begin
    if (rst) begin
        pt_wr <= 1'd0;
    end
    else begin
        if (cyc_d3[2:0] == 3'd7) begin
            pt_wr <= 1'd1;
        end
        else begin
            pt_wr <= 1'd0;
        end
    end
end
// pt_addr
always @(posedge clk or posedge rst) begin
    if (rst) begin
        pt_addr <= 9'd511;
    end
    else begin
        if (start) begin
            pt_addr <= 9'd511;
        end
        else if (cyc_d3[2:0] == 3'd7) begin
            pt_addr <= pt_addr + 1;
        end
    end
end
// pt_cache
always @(posedge clk or posedge rst) begin
    if (rst) begin
        pt_cache <= 30'd0;
    end
    else begin
        if (busy) begin
            if (cyc_d3 == 4'd0 ) pt_cache[ 1: 0] <= {state_d_src, state_c_src};
            if (cyc_d3 == 4'd1 ) pt_cache[ 3: 2] <= {state_d_src, state_c_src};
            if (cyc_d3 == 4'd2 ) pt_cache[ 5: 4] <= {state_d_src, state_c_src};
            if (cyc_d3 == 4'd3 ) pt_cache[ 7: 6] <= {state_d_src, state_c_src};
            if (cyc_d3 == 4'd4 ) pt_cache[ 9: 8] <= {state_d_src, state_c_src};
            if (cyc_d3 == 4'd5 ) pt_cache[11:10] <= {state_d_src, state_c_src};
            if (cyc_d3 == 4'd6 ) pt_cache[13:12] <= {state_d_src, state_c_src};
            if (cyc_d3 == 4'd7 ) pt_cache[15:14] <= {state_d_src, state_c_src};
            if (cyc_d3 == 4'd8 ) pt_cache[17:16] <= {state_d_src, state_c_src};
            if (cyc_d3 == 4'd9 ) pt_cache[19:18] <= {state_d_src, state_c_src};
            if (cyc_d3 == 4'd10) pt_cache[21:20] <= {state_d_src, state_c_src};
            if (cyc_d3 == 4'd11) pt_cache[23:22] <= {state_d_src, state_c_src};
            if (cyc_d3 == 4'd12) pt_cache[25:24] <= {state_d_src, state_c_src};
            if (cyc_d3 == 4'd13) pt_cache[27:26] <= {state_d_src, state_c_src};
            if (cyc_d3 == 4'd14) pt_cache[29:28] <= {state_d_src, state_c_src};
        end
    end
end
// pt_din
always @(posedge clk or posedge rst) begin
    if (rst) begin
        pt_din <= 32'd0;
    end
    else begin
        if (cyc_d3[2:0] == 3'd7) begin
            pt_din <= {state_d_src, state_c_src, pt_cache[29:0]};
        end
    end
end

// done
always @(posedge clk or posedge rst) begin
    if (rst) begin
        done_tmp1 <= 1'd0;
        done_tmp2 <= 1'd0;
        done_tmp3 <= 1'd0;
        done_tmp4 <= 1'd0;
    end
    else begin
        if (stage == codeblk_size_p7 && cyc[6:0] == 7'd127) begin
            done_tmp1 <= 1'd1;
        end
        else begin
            done_tmp1 <= 1'd0;
        end
        done_tmp2 <= done_tmp1;
        done_tmp3 <= done_tmp2;
        done_tmp4 <= done_tmp3;
    end
end
assign done = done_tmp4;
// busy
always @(posedge clk or posedge rst) begin
    if (rst) begin
        busy <= 1'd0;
    end
    else begin
        if (start) begin
            busy <= 1'd1;
        end
        else if (done) begin
            busy <= 1'd0;
        end
    end
end

endmodule
