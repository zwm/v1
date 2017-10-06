//////////////////////////////////////////////////////////////////////////////
// Module Name          : vdec_hs_crc16                                     //
//                                                                          //
// Type                 : Module                                            //
//                                                                          //
// Module Description   : Serial CRC check circuit                          //
//                                                                          //
// Timing Constraints   : Module is designed to work with a clock frequency //
//                        of 307.2 MHz                                      //
//                                                                          //
// Revision History     : 20170926    V0.1    File created                  //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
module vdec_hs_crc16 (
    crc_in,
    crc_reg,
    crc_next
);

// port
input                   crc_in;
input   [15:0]          crc_reg;
output  [15:0]          crc_next;
// internal wires
wire    [15:0]          crc_16b_next;
// crc16b
assign crc_16b_next[ 0] = crc_reg[15] ^ crc_in;
assign crc_16b_next[ 1] =               crc_reg[ 0];
assign crc_16b_next[ 2] =               crc_reg[ 1];
assign crc_16b_next[ 3] =               crc_reg[ 2];
assign crc_16b_next[ 4] =               crc_reg[ 3];
assign crc_16b_next[ 5] = crc_reg[15] ^ crc_reg[ 4];
assign crc_16b_next[ 6] =               crc_reg[ 5];
assign crc_16b_next[ 7] =               crc_reg[ 6];
assign crc_16b_next[ 8] =               crc_reg[ 7];
assign crc_16b_next[ 9] =               crc_reg[ 8];
assign crc_16b_next[10] =               crc_reg[ 9];
assign crc_16b_next[11] =               crc_reg[10];
assign crc_16b_next[12] = crc_reg[15] ^ crc_reg[11];
assign crc_16b_next[13] =               crc_reg[12];
assign crc_16b_next[14] =               crc_reg[13];
assign crc_16b_next[15] =               crc_reg[14];
// final output
assign crc_next         = crc_16b_next;

endmodule
