//////////////////////////////////////////////////////////////////////////////
// Module Name          : vdec_hs                                           //
//                                                                          //
// Type                 : Module                                            //
//                                                                          //
// Module Description   : Top of vdec_hs                                    //
//                                                                          //
// Timing Constraints   : Module is designed to work with a clock frequency //
//                        of 307.2 MHz                                      //
//                                                                          //
// Revision History     : 20171004    V0.1    File created                  //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
module vdec_hs (
    clk,
    rst_n,
    //
    busy,
    done,
    //
    done_hsscch_part1,
    done_hsscch_part2,
    done_agch,
    done_ns_hsscch_part1,
    done_ns_hsscch_part2,
    //
    status,
    // mpif
    mp_vdec_sel_AB,
    mp_vdec_sel_CD,
    // HSDPA Interface
    hsscch_uemask,

    start_part1,
    start_part2,
    hsscch_ca_sel,
    hsscch_pp_sel,
    hsscch_ch_sel,
    hsscch_uemask2_sel,

    ns_hsscch_uemask,
    start_ns_part1,
    start_ns_part2,
    ns_hsscch_sel,
    // HSUPA Interface
    agch_uemask1,
    agch_uemask2,
    start_agch,
    agch_sel,
    agch_crc1,
    agch_crc2,
    // DIRAM
    diram_dout,
    diram_rd_addr,
    diram_rd_ack,
    diram_rd_req,
    // dec output
    vdec_crc,
    vdec_ser_acc,
    vdec_output,
    // RAM
    sm0_cen_out,
    sm0_wen_out,
    sm0_a_out,
    sm0_d_out,
    sm0_q_in,
    sm1_cen_out,
    sm1_wen_out,
    sm1_a_out,
    sm1_d_out,
    sm1_q_in,
    pt_cen_out,
    pt_wen_out,
    pt_a_out,
    pt_d_out,
    pt_q_in
);

//---------------------------------------------------------------------------
// port
//---------------------------------------------------------------------------
input                       clk;
input                       rst_n;
output                      busy;
output                      done;
output                      done_hsscch_part1;
output                      done_hsscch_part2;
output                      done_agch;
output                      done_ns_hsscch_part1;
output                      done_ns_hsscch_part2;
output  [31:0]              status;
input                       mp_vdec_sel_AB;
input                       mp_vdec_sel_CD;
input   [15:0]              hsscch_uemask;
input                       start_part1;
input                       start_part2;
input                       hsscch_ca_sel;
input                       hsscch_pp_sel;
input   [ 1:0]              hsscch_ch_sel;
input                       hsscch_uemask2_sel;
input   [15:0]              ns_hsscch_uemask;
input                       start_ns_part1;
input                       start_ns_part2;
input                       ns_hsscch_sel;
input   [15:0]              agch_uemask1;
input   [15:0]              agch_uemask2;
input                       start_agch;
input                       agch_sel;
output                      agch_crc1;
output                      agch_crc2;
input   [23:0]              diram_dout;
output  [ 9:0]              diram_rd_addr;      // HSPA_CRAM 608x24b
input                       diram_rd_ack;
output                      diram_rd_req;
output                      vdec_crc;
output  [ 6:0]              vdec_ser_acc;
output  [31:0]              vdec_output;
output                      sm0_cen_out;
output                      sm0_wen_out;
output  [ 5:0]              sm0_a_out;
output  [31:0]              sm0_d_out;
input   [31:0]              sm0_q_in;
output                      sm1_cen_out;
output                      sm1_wen_out;
output  [ 5:0]              sm1_a_out;
output  [31:0]              sm1_d_out;
input   [31:0]              sm1_q_in;
output                      pt_cen_out;
output                      pt_wen_out;
output  [ 8:0]              pt_a_out;
output  [31:0]              pt_d_out;
input   [31:0]              pt_q_in;
reg                         agch_crc1;
reg                         agch_crc2;
//---------------------------------------------------------------------------
// internal wires
//---------------------------------------------------------------------------
wire                        vdec_hs_start;
wire                        vdec_hs_busy;
wire                        vdec_hs_done;
wire    [ 3:0]              hsscch_sel;
reg     [ 1:0]              hs_mode;
reg                         ns_type;
wire                        crc_match;
wire                        agch_crc_sel;
wire                        fwd_start;
wire                        fwd_done;
wire                        bwd_start;
wire                        bwd_done;
wire                        crc_start;
wire                        crc_done;
wire                        ser_start;
wire                        ser_done;
wire    [2:0]               fsm_out;
wire                        fwd_busy;
reg     [5:0]               codeblk_size_p7;
wire    [15:0]              hs_uemask;
wire    [15:0]              agch_uemask;
reg     [ 9:0]              base_sys;
wire                        fwd_sm0_rd;
wire                        fwd_sm0_wr;
wire    [ 5:0]              fwd_sm0_addr;
wire    [31:0]              fwd_sm0_din;
wire    [31:0]              fwd_sm0_dout;
wire                        fwd_sm1_rd;
wire                        fwd_sm1_wr;
wire    [ 5:0]              fwd_sm1_addr;
wire    [31:0]              fwd_sm1_din;
wire    [31:0]              fwd_sm1_dout;
wire                        fwd_pt_wr;
wire    [ 8:0]              fwd_pt_wr_addr;
wire    [31:0]              fwd_pt_din;
wire                        bwd_pt_rd;
wire    [ 8:0]              bwd_pt_rd_addr;
wire    [31:0]              bwd_pt_dout;
wire                        bwd_busy;
wire    [28:0]              bwd_dec_bits;
wire                        crc_busy;
reg     [36:0]              crc_check_bits;     // hsscch: 21+16    agch: 6+16
reg     [ 5:0]              crc_check_len;
wire                        ser_busy;
wire    [28:0]              ser_dec_bits;
wire    [ 6:0]              ser_acc;
wire                        fwd_diram_rd_req;
wire                        fwd_diram_rd_ack;
wire    [ 9:0]              fwd_diram_rd_addr;
wire    [23:0]              fwd_diram_dout;
wire                        ser_diram_rd_req;
wire                        ser_diram_rd_ack;
wire    [ 9:0]              ser_diram_rd_addr;
wire    [23:0]              ser_diram_dout;
reg                         fwd_diram_rd_pend;
reg                         ser_diram_rd_pend;
reg     [ 7:0]              ns_part1_c0;
reg     [ 7:0]              ca0_part1_c0;
reg     [ 7:0]              ca0_part1_c1;
reg     [ 7:0]              ca0_part1_c2;
reg     [ 7:0]              ca0_part1_c3;
reg     [ 7:0]              ca0_part1_c4;
reg     [ 7:0]              ca1_part1_c0;
reg     [ 7:0]              ca1_part1_c1;
reg     [ 7:0]              ca1_part1_c2;
reg     [ 7:0]              ca1_part1_c3;
//---------------------------------------------------------------------------
// TOP LOGIC
//---------------------------------------------------------------------------
assign vdec_hs_start    = start_part1 | start_part2 | start_ns_part1 | start_ns_part2 | start_agch;
assign hs_uemask        = ns_type ? ns_hsscch_uemask : hsscch_uemask;
assign agch_uemask      = agch_crc_sel ? agch_uemask2 : agch_uemask1;
assign hsscch_sel       = {hsscch_ca_sel, hsscch_pp_sel, hsscch_ch_sel};
// hs_mode & ns_type
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        hs_mode <= 2'd0;
        ns_type <= 1'd0;
    end
    else begin
        if (~vdec_hs_busy) begin
            if (start_part1) begin          // hsscch_part1
                hs_mode <= 2'd0;
                ns_type <= 1'd0;
            end
            else if (start_part2) begin     // hsscch_part2
                hs_mode <= 2'd1;
                ns_type <= 1'd0;
            end
            else if (start_ns_part1) begin  // ns_hsscch_part1
                hs_mode <= 2'd0;
                ns_type <= 1'd1;
            end
            else if (start_ns_part2) begin  // ns_hsscch_part2
                hs_mode <= 2'd1;
                ns_type <= 1'd1;
            end
            else if (start_agch) begin      // agch
                hs_mode <= 2'd2;
                ns_type <= 1'd0;
            end
        end
    end
end
// base_sys
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        base_sys <= 10'd0;
    end
    else begin
        if (~vdec_hs_busy) begin
            if (start_part1) begin          // hsscch_part1
                case (hsscch_sel)
                    4'd0    : base_sys <= 10'h000;  // byte address : 0x000
                    4'd1    : base_sys <= 10'h020;  // byte address : 0x080
                    4'd2    : base_sys <= 10'h040;  // byte address : 0x100
                    4'd3    : base_sys <= 10'h060;  // byte address : 0x180
                    4'd4    : base_sys <= 10'h080;  // byte address : 0x200
                    4'd5    : base_sys <= 10'h0A0;  // byte address : 0x280
                    4'd6    : base_sys <= 10'h0C0;  // byte address : 0x300
                    4'd7    : base_sys <= 10'h0E0;  // byte address : 0x380
                    4'd8    : base_sys <= 10'h160;  // byte address : 0x580
                    4'd9    : base_sys <= 10'h180;  // byte address : 0x600
                    4'd10   : base_sys <= 10'h1A0;  // byte address : 0x680
                    4'd11   : base_sys <= 10'h1C0;  // byte address : 0x700
                    4'd12   : base_sys <= 10'h1E0;  // byte address : 0x780
                    4'd13   : base_sys <= 10'h200;  // byte address : 0x800
                    4'd14   : base_sys <= 10'h220;  // byte address : 0x880
                    default : base_sys <= 10'h240;  // byte address : 0x900
                endcase
            end
            else if (start_part2) begin     // hsscch_part2
                case (hsscch_sel)
                    4'd0    : base_sys <= 10'h00A;
                    4'd1    : base_sys <= 10'h02A;
                    4'd2    : base_sys <= 10'h04A;
                    4'd3    : base_sys <= 10'h06A;
                    4'd4    : base_sys <= 10'h08A;
                    4'd5    : base_sys <= 10'h0AA;
                    4'd6    : base_sys <= 10'h0CA;
                    4'd7    : base_sys <= 10'h0EA;
                    4'd8    : base_sys <= 10'h16A;
                    4'd9    : base_sys <= 10'h18A;
                    4'd10   : base_sys <= 10'h1AA;
                    4'd11   : base_sys <= 10'h1CA;
                    4'd12   : base_sys <= 10'h1EA;
                    4'd13   : base_sys <= 10'h20A;
                    4'd14   : base_sys <= 10'h22A;
                    default : base_sys <= 10'h24A;
                endcase
            end
            else if (start_ns_part1) begin  // ns_hsscch_part1
                if (ns_hsscch_sel == 1'd0) begin
                    base_sys <= 10'h120;            // byte address : 0x480
                end
                else begin
                    base_sys <= 10'h140;            // byte address : 0x500
                end
            end
            else if (start_ns_part2) begin  // ns_hsscch_part2
                if (ns_hsscch_sel == 1'd0) begin
                    base_sys <= 10'h12A;
                end
                else begin
                    base_sys <= 10'h14A;
                end
            end
            else if (start_agch) begin      // agch
                if (agch_sel == 1'd0) begin
                    base_sys <= 10'h100;            // byte address : 0x400
                end
                else begin
                    base_sys <= 10'h110;            // byte address : 0x440
                end
            end
        end
    end
end
// codeblk_size_p7
always @(*) begin
    case (hs_mode)
        2'd0    : codeblk_size_p7 = 6'd15;      // part1    : 8  + 7 = 15
        2'd1    : codeblk_size_p7 = 6'd36;      // part2    : 29 + 7 = 36
        default : codeblk_size_p7 = 6'd29;      // agch     : 22 + 7 = 29
    endcase
end
// crc_check_len
always @(*) begin
    case (hs_mode)
        2'd0    : crc_check_len = 6'd8;         // part1    :  8 +  0 = 8
        2'd1    : crc_check_len = 6'd37;        // part2    : 21 + 16 = 37
        default : crc_check_len = 6'd22;        // agch     :  6 + 16 = 22
    endcase
end
// ser_dec_bits
assign ser_dec_bits = bwd_dec_bits;
// part1 reg
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        ns_part1_c0  <= 8'd0;
        ca0_part1_c0 <= 8'd0;
        ca0_part1_c1 <= 8'd0;
        ca0_part1_c2 <= 8'd0;
        ca0_part1_c3 <= 8'd0;
        ca0_part1_c4 <= 8'd0;
        ca1_part1_c0 <= 8'd0;
        ca1_part1_c1 <= 8'd0;
        ca1_part1_c2 <= 8'd0;
        ca1_part1_c3 <= 8'd0;
    end
    else begin
        if (hs_mode == 0 && bwd_done == 1) begin
            if (ns_type) begin
                ns_part1_c0  <= bwd_dec_bits[7:0];
            end
            else if (hsscch_uemask2_sel) begin
                ca0_part1_c4 <= bwd_dec_bits[7:0];
            end
            else begin
                case ({hsscch_ca_sel, hsscch_ch_sel})
                    3'd0    : ca0_part1_c0 <= bwd_dec_bits[7:0];
                    3'd1    : ca0_part1_c1 <= bwd_dec_bits[7:0];
                    3'd2    : ca0_part1_c2 <= bwd_dec_bits[7:0];
                    3'd3    : ca0_part1_c3 <= bwd_dec_bits[7:0];
                    3'd4    : ca1_part1_c0 <= bwd_dec_bits[7:0];
                    3'd5    : ca1_part1_c1 <= bwd_dec_bits[7:0];
                    3'd6    : ca1_part1_c2 <= bwd_dec_bits[7:0];
                    default : ca1_part1_c3 <= bwd_dec_bits[7:0];
                endcase
            end
        end
    end
end
// crc_check_bits
always @(*) begin
    if (hs_mode == 3'd0) begin          // part1
        crc_check_bits = 37'd0;
    end
    else if (hs_mode == 3'd1) begin     // part2
        // parity
        crc_check_bits[36] = bwd_dec_bits[13] ^ hs_uemask[15];
        crc_check_bits[35] = bwd_dec_bits[14] ^ hs_uemask[14];
        crc_check_bits[34] = bwd_dec_bits[15] ^ hs_uemask[13];
        crc_check_bits[33] = bwd_dec_bits[16] ^ hs_uemask[12];
        crc_check_bits[32] = bwd_dec_bits[17] ^ hs_uemask[11];
        crc_check_bits[31] = bwd_dec_bits[18] ^ hs_uemask[10];
        crc_check_bits[30] = bwd_dec_bits[19] ^ hs_uemask[ 9];
        crc_check_bits[29] = bwd_dec_bits[20] ^ hs_uemask[ 8];
        crc_check_bits[28] = bwd_dec_bits[21] ^ hs_uemask[ 7];
        crc_check_bits[27] = bwd_dec_bits[22] ^ hs_uemask[ 6];
        crc_check_bits[26] = bwd_dec_bits[23] ^ hs_uemask[ 5];
        crc_check_bits[25] = bwd_dec_bits[24] ^ hs_uemask[ 4];
        crc_check_bits[24] = bwd_dec_bits[25] ^ hs_uemask[ 3];
        crc_check_bits[23] = bwd_dec_bits[26] ^ hs_uemask[ 2];
        crc_check_bits[22] = bwd_dec_bits[27] ^ hs_uemask[ 1];
        crc_check_bits[21] = bwd_dec_bits[28] ^ hs_uemask[ 0];
        // info
        if (ns_type) begin  // ns_hsscch decode
            crc_check_bits[20:0] = {bwd_dec_bits[12:0], ns_part1_c0[7:0]};
        end
        else if (hsscch_uemask2_sel) begin
            crc_check_bits[20:0] = {bwd_dec_bits[12:0], ca0_part1_c4[7:0]};
        end
        else begin
            case ({hsscch_ca_sel, hsscch_ch_sel})
                3'd0    : crc_check_bits[20:0] = {bwd_dec_bits[12:0], ca0_part1_c0[7:0]};
                3'd1    : crc_check_bits[20:0] = {bwd_dec_bits[12:0], ca0_part1_c1[7:0]};
                3'd2    : crc_check_bits[20:0] = {bwd_dec_bits[12:0], ca0_part1_c2[7:0]};
                3'd3    : crc_check_bits[20:0] = {bwd_dec_bits[12:0], ca0_part1_c3[7:0]};
                3'd4    : crc_check_bits[20:0] = {bwd_dec_bits[12:0], ca1_part1_c0[7:0]};
                3'd5    : crc_check_bits[20:0] = {bwd_dec_bits[12:0], ca1_part1_c1[7:0]};
                3'd6    : crc_check_bits[20:0] = {bwd_dec_bits[12:0], ca1_part1_c2[7:0]};
                default : crc_check_bits[20:0] = {bwd_dec_bits[12:0], ca1_part1_c3[7:0]};
            endcase
        end
    end
    else begin                          // agch
        crc_check_bits[36:22] = 15'd0;
        crc_check_bits[21] = bwd_dec_bits[ 6] ^ agch_uemask[15];
        crc_check_bits[20] = bwd_dec_bits[ 7] ^ agch_uemask[14];
        crc_check_bits[19] = bwd_dec_bits[ 8] ^ agch_uemask[13];
        crc_check_bits[18] = bwd_dec_bits[ 9] ^ agch_uemask[12];
        crc_check_bits[17] = bwd_dec_bits[10] ^ agch_uemask[11];
        crc_check_bits[16] = bwd_dec_bits[11] ^ agch_uemask[10];
        crc_check_bits[15] = bwd_dec_bits[12] ^ agch_uemask[ 9];
        crc_check_bits[14] = bwd_dec_bits[13] ^ agch_uemask[ 8];
        crc_check_bits[13] = bwd_dec_bits[14] ^ agch_uemask[ 7];
        crc_check_bits[12] = bwd_dec_bits[15] ^ agch_uemask[ 6];
        crc_check_bits[11] = bwd_dec_bits[16] ^ agch_uemask[ 5];
        crc_check_bits[10] = bwd_dec_bits[17] ^ agch_uemask[ 4];
        crc_check_bits[ 9] = bwd_dec_bits[18] ^ agch_uemask[ 3];
        crc_check_bits[ 8] = bwd_dec_bits[19] ^ agch_uemask[ 2];
        crc_check_bits[ 7] = bwd_dec_bits[20] ^ agch_uemask[ 1];
        crc_check_bits[ 6] = bwd_dec_bits[21] ^ agch_uemask[ 0];
        crc_check_bits[ 5] = bwd_dec_bits[5];
        crc_check_bits[ 4] = bwd_dec_bits[4];
        crc_check_bits[ 3] = bwd_dec_bits[3];
        crc_check_bits[ 2] = bwd_dec_bits[2];
        crc_check_bits[ 1] = bwd_dec_bits[1];
        crc_check_bits[ 0] = bwd_dec_bits[0];
    end
end
//---------------------------------------------------------------------------
// VDEC_HS FSM
//---------------------------------------------------------------------------
vdec_hs_ctrl u0_fsm (
    .clk                    ( clk                           ),
    .rst_n                  ( rst_n                         ),
    .start                  ( vdec_hs_start                 ),
    .busy                   ( vdec_hs_busy                  ),
    .done                   ( vdec_hs_done                  ),
    .hs_mode                ( hs_mode                       ),
    .crc_match              ( crc_match                     ),
    .agch_crc_sel           ( agch_crc_sel                  ),
    .fwd_start              ( fwd_start                     ),
    .fwd_done               ( fwd_done                      ),
    .bwd_start              ( bwd_start                     ),
    .bwd_done               ( bwd_done                      ),
    .crc_start              ( crc_start                     ),
    .crc_done               ( crc_done                      ),
    .ser_start              ( ser_start                     ),
    .ser_done               ( ser_done                      ),
    .fsm_out                ( fsm_out                       )
);
//---------------------------------------------------------------------------
// VDEC_HS FORWARD METRIC CALC
//---------------------------------------------------------------------------
vdec_hs_fwd u1_fwd (
    .clk                    ( clk                           ),
    .rst_n                  ( rst_n                         ),
    .start                  ( fwd_start                     ),
    .busy                   ( fwd_busy                      ),
    .done                   ( fwd_done                      ),
    .codeblk_size_p7        ( codeblk_size_p7               ),
    .hs_mode                ( hs_mode                       ),
    .ue_mask                ( hs_uemask                     ),
    .base_sys               ( base_sys                      ),
    .mp_sel_AB              ( mp_vdec_sel_AB                ),
    .mp_sel_CD              ( mp_vdec_sel_CD                ),
    .diram_rd_req           ( fwd_diram_rd_req              ),
    .diram_rd_ack           ( fwd_diram_rd_ack              ),
    .diram_raddr            ( fwd_diram_rd_addr             ),
    .diram_rdata            ( fwd_diram_dout                ),
    .sm0_rd                 ( fwd_sm0_rd                    ),
    .sm0_wr                 ( fwd_sm0_wr                    ),
    .sm0_addr               ( fwd_sm0_addr                  ),
    .sm0_din                ( fwd_sm0_din                   ),
    .sm0_dout               ( fwd_sm0_dout                  ),
    .sm1_rd                 ( fwd_sm1_rd                    ),
    .sm1_wr                 ( fwd_sm1_wr                    ),
    .sm1_addr               ( fwd_sm1_addr                  ),
    .sm1_din                ( fwd_sm1_din                   ),
    .sm1_dout               ( fwd_sm1_dout                  ),
    .pt_wr                  ( fwd_pt_wr                     ),
    .pt_addr                ( fwd_pt_wr_addr                ),
    .pt_din                 ( fwd_pt_din                    )
);
//---------------------------------------------------------------------------
// VDEC_HS TRACEBACK PROC
//---------------------------------------------------------------------------
vdec_hs_bwd u2_traceback (
    .clk                    ( clk                           ),
    .rst_n                  ( rst_n                         ),
    .start                  ( bwd_start                     ),
    .busy                   ( bwd_busy                      ),
    .done                   ( bwd_done                      ),
    .dec_bits               ( bwd_dec_bits                  ),
    .codeblk_size_p7        ( codeblk_size_p7               ),
    .pt_rd                  ( bwd_pt_rd                     ),
    .pt_addr                ( bwd_pt_rd_addr                ),
    .pt_dout                ( bwd_pt_dout                   )
);
//---------------------------------------------------------------------------
// VDEC_HS CRC CHECK
//---------------------------------------------------------------------------
vdec_hs_crc_check u3_crc (
    .clk                    ( clk                           ),
    .rst_n                  ( rst_n                         ),
    .start                  ( crc_start                     ),
    .busy                   ( crc_busy                      ),
    .done                   ( crc_done                      ),
    .crc_match              ( crc_match                     ),
    .check_bits             ( crc_check_bits                ),
    .check_len              ( crc_check_len                 )
);
//---------------------------------------------------------------------------
// VDEC_HS SER CALC
//---------------------------------------------------------------------------
vdec_hs_ser u4_ser (
    .clk                    ( clk                           ),
    .rst_n                  ( rst_n                         ),
    .start                  ( ser_start                     ),
    .busy                   ( ser_busy                      ),
    .done                   ( ser_done                      ),
    .dec_bits               ( ser_dec_bits                  ),
    .codeblk_size_p7        ( codeblk_size_p7               ),
    .hs_mode                ( hs_mode                       ),
    .ue_mask                ( hs_uemask                     ),
    .base_sys               ( base_sys                      ),
    .ser_acc                ( ser_acc                       ),
    .diram_rd_req           ( ser_diram_rd_req              ),
    .diram_rd_ack           ( ser_diram_rd_ack              ),
    .diram_raddr            ( ser_diram_rd_addr             ),
    .diram_rdata            ( ser_diram_dout                )
);
//---------------------------------------------------------------------------
// DIRAM MUX
//---------------------------------------------------------------------------
// fwd_diram_rd_pend
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        fwd_diram_rd_pend <= 1'd0;
    end
    else begin
        if (fwd_diram_rd_req) begin
            fwd_diram_rd_pend <= 1'd1;
        end
        else if (fwd_diram_rd_ack) begin
            fwd_diram_rd_pend <= 1'd0;
        end
    end
end
// ser_diram_rd_pend
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        ser_diram_rd_pend <= 1'd0;
    end
    else begin
        if (ser_diram_rd_req) begin
            ser_diram_rd_pend <= 1'd1;
        end
        else if (ser_diram_rd_ack) begin
            ser_diram_rd_pend <= 1'd0;
        end
    end
end
// ram port
assign diram_rd_req     = fwd_diram_rd_req | ser_diram_rd_req;
assign diram_rd_addr    = (ser_diram_rd_req | ser_diram_rd_pend) ? ser_diram_rd_addr : fwd_diram_rd_addr;
assign fwd_diram_rd_ack = diram_rd_ack;
assign ser_diram_rd_ack = diram_rd_ack;
assign fwd_diram_dout   = diram_dout;
assign ser_diram_dout   = diram_dout;
//---------------------------------------------------------------------------
// RAM
//---------------------------------------------------------------------------
// sm0
assign sm0_cen_out          = ~(fwd_sm0_rd | fwd_sm0_wr);
assign sm0_wen_out          = ~(             fwd_sm0_wr);
assign sm0_a_out            = fwd_sm0_addr;
assign sm0_d_out            = fwd_sm0_din;
assign fwd_sm0_dout         = sm0_q_in;
// sm1
assign sm1_cen_out          = ~(fwd_sm1_rd | fwd_sm1_wr);
assign sm1_wen_out          = ~(             fwd_sm1_wr);
assign sm1_a_out            = fwd_sm1_addr;
assign sm1_d_out            = fwd_sm1_din;
assign fwd_sm1_dout         = sm1_q_in;
// pt
assign pt_cen_out           = ~(bwd_pt_rd | fwd_pt_wr);
assign pt_wen_out           = ~(            fwd_pt_wr);
assign pt_a_out             = bwd_pt_rd ? bwd_pt_rd_addr : fwd_pt_wr_addr;
assign pt_d_out             = fwd_pt_din;
assign bwd_pt_dout          = pt_q_in;
//---------------------------------------------------------------------------
// OUTPUT
//---------------------------------------------------------------------------
assign busy                 = vdec_hs_busy;
assign done                 = vdec_hs_done;
assign done_hsscch_part1    = (hs_mode == 2'd0) ? ((~ns_type) & vdec_hs_done) : 1'd0;
assign done_hsscch_part2    = (hs_mode == 2'd1) ? ((~ns_type) & vdec_hs_done) : 1'd0;
assign done_ns_hsscch_part1 = (hs_mode == 2'd0) ? (( ns_type) & vdec_hs_done) : 1'd0;
assign done_ns_hsscch_part2 = (hs_mode == 2'd1) ? (( ns_type) & vdec_hs_done) : 1'd0;
assign done_agch            = (hs_mode == 2'd2) ? vdec_hs_done : 1'd0;
assign status               = {29'd0, fsm_out[2:0]}; // ??? more info???
assign vdec_crc             = crc_match;
assign vdec_ser_acc         = ser_acc;
// vdec_output is bit reversed of bwd_dec_bits to compatible with V2!!!
assign vdec_output[31]      = bwd_dec_bits[ 0];
assign vdec_output[30]      = bwd_dec_bits[ 1];
assign vdec_output[29]      = bwd_dec_bits[ 2];
assign vdec_output[28]      = bwd_dec_bits[ 3];
assign vdec_output[27]      = bwd_dec_bits[ 4];
assign vdec_output[26]      = bwd_dec_bits[ 5];
assign vdec_output[25]      = bwd_dec_bits[ 6];
assign vdec_output[24]      = bwd_dec_bits[ 7];
assign vdec_output[23]      = bwd_dec_bits[ 8];
assign vdec_output[22]      = bwd_dec_bits[ 9];
assign vdec_output[21]      = bwd_dec_bits[10];
assign vdec_output[20]      = bwd_dec_bits[11];
assign vdec_output[19]      = bwd_dec_bits[12];
assign vdec_output[18]      = bwd_dec_bits[13];
assign vdec_output[17]      = bwd_dec_bits[14];
assign vdec_output[16]      = bwd_dec_bits[15];
assign vdec_output[15]      = bwd_dec_bits[16];
assign vdec_output[14]      = bwd_dec_bits[17];
assign vdec_output[13]      = bwd_dec_bits[18];
assign vdec_output[12]      = bwd_dec_bits[19];
assign vdec_output[11]      = bwd_dec_bits[20];
assign vdec_output[10]      = bwd_dec_bits[21];
assign vdec_output[9]       = bwd_dec_bits[22];
assign vdec_output[8]       = bwd_dec_bits[23];
assign vdec_output[7]       = bwd_dec_bits[24];
assign vdec_output[6]       = bwd_dec_bits[25];
assign vdec_output[5]       = bwd_dec_bits[26];
assign vdec_output[4]       = bwd_dec_bits[27];
assign vdec_output[3]       = bwd_dec_bits[28];
assign vdec_output[2]       = 1'd0;
assign vdec_output[1]       = 1'd0;
assign vdec_output[0]       = 1'd0;
// agch crc1 & crc2
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        agch_crc1 <= 1'd0;
        agch_crc2 <= 1'd0;
    end
    else begin
        // crc1
        if (start_agch) begin
            agch_crc1 <= 1'd0;
        end
        else if (hs_mode == 2'd2 && crc_done == 1'd1 && agch_crc_sel == 1'd0) begin
            agch_crc1 <= crc_match;
        end
        // crc2
        if (start_agch) begin
            agch_crc2 <= 1'd0;
        end
        else if (hs_mode == 2'd2 && crc_done == 1'd1 && agch_crc_sel == 1'd1) begin
            agch_crc2 <= crc_match;
        end
    end
end

endmodule

