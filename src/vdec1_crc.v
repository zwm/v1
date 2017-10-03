//////////////////////////////////////////////////////////////////////////////
// Module Name          : vdec1_crc                                         //
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
module vdec1_crc (
    crc_sel,
    crc_in,
    crc_reg,
    crc_next
);

// port
input       [1:0]           crc_sel;
input                       crc_in;
input       [23:0]          crc_reg;
output      [23:0]          crc_next;
reg         [23:0]          crc_next;
// internal wires
wire    [7:0]   crc_8b_next;
wire    [11:0]  crc_12b_next;
wire    [15:0]  crc_16b_next;
wire    [23:0]  crc_24b_next;

// crc8b
assign crc_8b_next[ 0]  = crc_reg[ 7] ^ crc_in;
assign crc_8b_next[ 1]  = crc_reg[ 7] ^ crc_reg[ 0];
assign crc_8b_next[ 2]  =               crc_reg[ 1];
assign crc_8b_next[ 3]  = crc_reg[ 7] ^ crc_reg[ 2];
assign crc_8b_next[ 4]  = crc_reg[ 7] ^ crc_reg[ 3];
assign crc_8b_next[ 5]  =               crc_reg[ 4];
assign crc_8b_next[ 6]  =               crc_reg[ 5];
assign crc_8b_next[ 7]  = crc_reg[ 7] ^ crc_reg[ 6];
// crc12b
assign crc_12b_next[ 0] = crc_reg[11] ^ crc_in;
assign crc_12b_next[ 1] = crc_reg[11] ^ crc_reg[ 0];
assign crc_12b_next[ 2] = crc_reg[11] ^ crc_reg[ 1];
assign crc_12b_next[ 3] = crc_reg[11] ^ crc_reg[ 2];
assign crc_12b_next[ 4] =               crc_reg[ 3];
assign crc_12b_next[ 5] =               crc_reg[ 4];
assign crc_12b_next[ 6] =               crc_reg[ 5];
assign crc_12b_next[ 7] =               crc_reg[ 6];
assign crc_12b_next[ 8] =               crc_reg[ 7];
assign crc_12b_next[ 9] =               crc_reg[ 8];
assign crc_12b_next[10] =               crc_reg[ 9];
assign crc_12b_next[11] = crc_reg[11] ^ crc_reg[10];
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
// crc24b
assign crc_24b_next[ 0] = crc_reg[23] ^ crc_in;
assign crc_24b_next[ 1] = crc_reg[23] ^ crc_reg[ 0];
assign crc_24b_next[ 2] =               crc_reg[ 1];
assign crc_24b_next[ 3] =               crc_reg[ 2];
assign crc_24b_next[ 4] =               crc_reg[ 3];
assign crc_24b_next[ 5] = crc_reg[23] ^ crc_reg[ 4];
assign crc_24b_next[ 6] = crc_reg[23] ^ crc_reg[ 5];
assign crc_24b_next[ 7] =               crc_reg[ 6];
assign crc_24b_next[ 8] =               crc_reg[ 7];
assign crc_24b_next[ 9] =               crc_reg[ 8];
assign crc_24b_next[10] =               crc_reg[ 9];
assign crc_24b_next[11] =               crc_reg[10];
assign crc_24b_next[12] =               crc_reg[11];
assign crc_24b_next[13] =               crc_reg[12];
assign crc_24b_next[14] =               crc_reg[13];
assign crc_24b_next[15] =               crc_reg[14];
assign crc_24b_next[16] =               crc_reg[15];
assign crc_24b_next[17] =               crc_reg[16];
assign crc_24b_next[18] =               crc_reg[17];
assign crc_24b_next[19] =               crc_reg[18];
assign crc_24b_next[20] =               crc_reg[19];
assign crc_24b_next[21] =               crc_reg[20];
assign crc_24b_next[22] =               crc_reg[21];
assign crc_24b_next[23] = crc_reg[23] ^ crc_reg[22];

// final output
always @(*) begin
    case (crc_sel)
        2'b00   : crc_next = {16'd0, crc_8b_next};
        2'b01   : crc_next = {12'd0, crc_12b_next};
        2'b10   : crc_next = { 8'd0, crc_16b_next};
        default : crc_next = {       crc_24b_next};
    endcase
end

endmodule
