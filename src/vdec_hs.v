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
    res,
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
    mpreq,
    mpa,
    mpd,
    mpq,
    mpbusy,
    u_mpw,
    u_mpr,
    mp_vdec_sel_AB,
    mp_vdec_sel_CD,
    // HSDPA Interface
    carrier_sel,
    hsscch_uemask,

    start_part1,
    start_part2,
    part1_sel,
    part2_sel,
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
input                       res;
output                      busy;
output                      done;
output                      done_hsscch_part1;
output                      done_hsscch_part2;
output                      done_agch;
output                      done_ns_hsscch_part1;
output                      done_ns_hsscch_part2;
output  [31:0]              status;
input                       mpreq;
input   [11:0]              mpa;
input   [31:0]              mpd;
output  [31:0]              mpq;
output                      mpbusy;
input                       u_mpw;
input                       u_mpr;
input                       mp_vdec_sel_AB;
input                       mp_vdec_sel_CD;
input                       carrier_sel;
input   [15:0]              hsscch_uemask;
input                       start_part1;
input                       start_part2;
input   [ 1:0]              part1_sel;
input   [ 1:0]              part2_sel;
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
output  [ 8:0]              diram_rd_addr;      // HSPA_CRAM 608x24b
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



endmodule

