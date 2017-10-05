//////////////////////////////////////////////////////////////////////////////
// Module Name          : vdec_hs_ser                                       //
//                                                                          //
// Type                 : Module                                            //
//                                                                          //
// Module Description   : Symbol error number calculation                   //
//                        Support channel type :                            //
//                          part1 : 8                                       //
//                          part2 : 29                                      //
//                          agch  : 22                                      //
//                                                                          //
// Timing Constraints   : Module is designed to work with a clock frequency //
//                        of 307.2 MHz                                      //
//                                                                          //
// Revision History     : 20171003    V0.1    File created                  //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
module vdec_hs_ser (
    clk,
    rst,
    start,
    busy,
    done,
    dec_bits,
    codeblk_size_p7,    // ???
    hs_mode,
    ue_mask,
    base_sys,
    ser_acc,
    diram_rd_req,
    diram_rd_ack,
    diram_raddr,
    diram_rdata
);

//---------------------------------------------------------------------------
// port
//---------------------------------------------------------------------------
input                       clk;
input                       rst;
input                       start;
output                      busy;
output                      done;
input   [28:0]              dec_bits;
input   [5:0]               codeblk_size_p7;    // part1: 8+7, part2: 29+7, agch: 22+7
input   [1:0]               hs_mode;            // 00: part1, 01: part2, 10: agch
input   [15:0]              ue_mask;
input   [15:0]              base_sys;           // ??? actual size???
output  [ 6:0]              ser_acc;
output                      diram_rd_req;
input                       diram_rd_ack;
output  [ 8:0]              diram_raddr;
input   [23:0]              diram_rdata;
reg                         diram_rd_req;
reg     [ 8:0]              diram_raddr;
reg     [ 6:0]              ser_acc;

// internal wires
reg                         ser_en;
reg                         ser_en_d1;
reg     [5:0]               bit_index;
reg     [1:0]               cc13_index;
reg     [6:0]               code_index;
reg                         diram_rd_pend;
reg     [ 3:0]              diram_cache;
reg     [ 2:0]              diram_cache_cnt;
reg     [ 5:0]              diram_sign;
wire                        diram_cache_low;
wire                        punc;
reg     [7:0]               cc13_reg;
reg                         cc13_in;
wire                        cc13_g0;
wire                        cc13_g1;
wire                        cc13_g2;
reg     [7:0]               cc12_reg;
reg                         cc12_in;
wire                        cc12_g0;
wire                        cc12_g1;
reg                         cur_data;
//---------------------------------------------------------------------------
// diram cache management
//---------------------------------------------------------------------------
// diram read
always @(posedge clk or posedge rst) begin
    if (rst) begin
        diram_rd_req <= 1'd0;
        diram_raddr <= 9'd0;
    end
    else begin
        if (start) begin
            diram_rd_req <= 1'd1;
            diram_raddr <= base_sys;
        end
        else if (ser_en & diram_cache_low & (~diram_cache_pend)) begin
            diram_rd_req <= 1'd1;
            diram_raddr <= diram_raddr + 1;
        end
    end
end
// diram read pend
always @(posedge clk or posedge rst) begin
    if (rst) begin
        diram_rd_pend <= 1'd0;
    end
    else begin
        if (start) begin
            diram_rd_pend <= 1'd1;
        end
        else if (ser_en & diram_cache_low & (~diram_cache_pend)) begin
            diram_rd_pend <= 1'd1;
        end
        else if (diram_rd_ack) begin
            diram_rd_pend <= 1'd0;
        end
    end
end
// diram_cache
always @(posedge clk or posedge rst) begin
    if (rst) begin
        diram_cache <= 4'd0;
        diram_cache_cnt <= 3'd0;
    end
    else begin
        if (start) begin
            diram_cache <= 4'd0;
            diram_cache_cnt <= 3'd0;
        end
        else if (ser_en & diram_cache_low & diram_rd_ack) begin
            diram_cache[0] <= diram_rdata[5];
            diram_cache[1] <= diram_rdata[11];
            diram_cache[2] <= diram_rdata[17];
            diram_cache[3] <= diram_rdata[23];
            diram_cache_cnt <= 3'd4;
        end
        else if (ser_en & (~punc) & (~diram_cache_low)) begin
            diram_cache_cnt <= diram_cache_cnt - 1;
        end
    end
end
// diram_cache_low
assign diram_cache_low = (diram_cache_cnt == 3'd0) ? 1'b1 : 1'b0;
//diram_data
always @(*) begin
    case (diram_cache_cnt)
        2'b00 : diram_sign = diram_cache[3];
        2'b01 : diram_sign = diram_cache[2];
        2'b10 : diram_sign = diram_cache[1];
        2'b11 : diram_sign = diram_cache[0];
    endcase
end
// ser_en
always @(posedge clk or posedge rst) begin
    if (rst) begin
        ser_en <= 1'd0;
    end
    else begin
        if (start) begin
            ser_en <= 1'd1;
        end
        else if (ser_en == 1 && diram_cache_low == 0 && bit_index == codeblk_size_p7 && cc13_index == 2'd2) begin
            ser_en <= 1'd0;
        end
    end
end
// bit_index
always @(posedge clk or posedge rst) begin
    if (rst) begin
        bit_index <= 6'd0;
    end
    else begin
        if (start) begin
            bit_index <= 6'd0;
        end
        else if (ser_en == 1 && (~diram_cache_low) && cc13_index == 2'd2) begin
            bit_index <= bit_index + 1;
        end
    end
end
// cc13_index
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cc13_index <= 2'd0;
    end
    else begin
        if (start) begin
            cc13_index <= 2'd0;
        end
        else if (ser_en == 1 && (~diram_cache_low)) begin       // count range: 0~2
            cc13_index[0] <= ~(cc13_index[1] | cc13_index[0])
            cc13_index[1] <= cc13_index[0];
        end
    end
end
// de-ratematching
vdec_hs_derm uderm (
    .hs_mode                ( hs_mode               ),
    .index                  ( code_index            ),
    .punc                   ( punc                  )
);
//---------------------------------------------------------------------------
// Information Bits CC1/3 coding
//---------------------------------------------------------------------------
// CC1/3 input
always @(*) begin
    case (bit_index[5:0])
        6'd0    : cc13_in = dec_bits[0];
        6'd1    : cc13_in = dec_bits[1];
        6'd2    : cc13_in = dec_bits[2];
        6'd3    : cc13_in = dec_bits[3];
        6'd4    : cc13_in = dec_bits[4];
        6'd5    : cc13_in = dec_bits[5];
        6'd6    : cc13_in = dec_bits[6];
        6'd7    : cc13_in = dec_bits[7];
        6'd8    : cc13_in = dec_bits[8];
        6'd9    : cc13_in = dec_bits[9];
        6'd10   : cc13_in = dec_bits[10];
        6'd11   : cc13_in = dec_bits[11];
        6'd12   : cc13_in = dec_bits[12];
        6'd13   : cc13_in = dec_bits[13];
        6'd14   : cc13_in = dec_bits[14];
        6'd15   : cc13_in = dec_bits[15];
        6'd16   : cc13_in = dec_bits[16];
        6'd17   : cc13_in = dec_bits[17];
        6'd18   : cc13_in = dec_bits[18];
        6'd19   : cc13_in = dec_bits[19];
        6'd20   : cc13_in = dec_bits[20];
        6'd21   : cc13_in = dec_bits[21];
        6'd22   : cc13_in = dec_bits[22];
        6'd23   : cc13_in = dec_bits[23];
        6'd24   : cc13_in = dec_bits[24];
        6'd25   : cc13_in = dec_bits[25];
        6'd26   : cc13_in = dec_bits[26];
        6'd27   : cc13_in = dec_bits[27];
        6'd28   : cc13_in = dec_bits[28];
        default : cc13_in <= 1'd0;
    endcase
end
// CC1/3 reg
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cc13_reg <= 8'd0;
    end
    else begin
        if (start) begin
            cc13_reg <= 8'd0;
        end
        else if (ser_en & (~diram_cache_low) & (cc13_index == 2'd2)) begin
            cc13_reg <= {cc13_in, cc13_reg[7:1]};
        end
    end
end
// CC1/3 output
assign cc13_g0 = cc13_reg[7] ^ cc13_reg[6] ^ cc13_reg[5] ^ cc13_reg[4] ^ cc13_reg[2] ^ cc13_reg[1] ^ cc13_in;
assign cc13_g1 = cc13_reg[7] ^ cc13_reg[6] ^ cc13_reg[3] ^ cc13_reg[2] ^ cc13_reg[0] ^ cc13_in;
assign cc13_g2 = cc13_reg[7] ^ cc13_reg[4] ^ cc13_reg[1] ^ cc13_reg[0] ^ cc13_in;
//---------------------------------------------------------------------------
// UE Mask CC1/2 coding
//---------------------------------------------------------------------------
// CC1/2 input
always @(*) begin
    if (hs_mode == 2'b00) begin
        case (code_index[6:1])
            6'd0    : cc12_in = ue_mask[0];
            6'd1    : cc12_in = ue_mask[1];
            6'd2    : cc12_in = ue_mask[2];
            6'd3    : cc12_in = ue_mask[3];
            6'd4    : cc12_in = ue_mask[4];
            6'd5    : cc12_in = ue_mask[5];
            6'd6    : cc12_in = ue_mask[6];
            6'd7    : cc12_in = ue_mask[7];
            6'd8    : cc12_in = ue_mask[8];
            6'd9    : cc12_in = ue_mask[9];
            6'd10   : cc12_in = ue_mask[10];
            6'd11   : cc12_in = ue_mask[11];
            6'd12   : cc12_in = ue_mask[12];
            6'd13   : cc12_in = ue_mask[13];
            6'd14   : cc12_in = ue_mask[14];
            6'd15   : cc12_in = ue_mask[15];
            default : cc12_in = 1'd0;
        endcase
    end
    else begin
        cc12_in = 1'd0;
    end
end
// CC1/2 reg
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cc12_reg <= 8'd0;
    end
    else begin
        if (start) begin
            cc12_reg <= 8'd0;
        end
        else if (hs_mode == 2'b00) begin
            if (ser_en & (~diram_cache_low) & code_index[0]) begin
                cc12_reg <= {cc12_in, cc12_reg[7:1]};
            end
        end
    end
end
// CC1/2 output
assign cc12_g0 = cc12_reg[7] ^ cc12_reg[3] ^ cc12_reg[2] ^ cc12_reg[1] ^ cc12_in;
assign cc12_g1 = cc12_reg[7] ^ cc12_reg[6] ^ cc12_reg[4] ^ cc12_reg[2] ^ cc12_reg[1] ^ cc12_reg[0] ^ cc12_in;
always @(*) begin
    if (cc13_index == 2'd0) begin               // g0
        if (code_index[0]) begin
            cur_data = cc13_g0 ^ cc12_g0;
        end
        else begin
            cur_data = cc13_g0 ^ cc12_g1;
        end
    end
    else if (cc13_index == 2'd1) begin          // g1
        if (code_index[0]) begin
            cur_data = cc13_g1 ^ cc12_g0;
        end
        else begin
            cur_data = cc13_g1 ^ cc12_g1;
        end
    end
    else begin                                  // g2
        if (code_index[0]) begin
            cur_data = cc13_g2 ^ cc12_g0;
        end
        else begin
            cur_data = cc13_g2 ^ cc12_g1;
        end
    end

end
//---------------------------------------------------------------------------
// SER Calc
//---------------------------------------------------------------------------
// ser_acc
always @(posedge clk or posedge rst) begin
    if (rst) begin
        ser_acc <= 7'd0;
    end
    else begin
        if (start) begin
            ser_acc <= 7'd0;
        end
        else if (ser_en & (~diram_cache_low) & (~punc)) begin
            if (cur_data != diram_data) begin
                ser_acc <= ser_acc + 1;
            end
        end
    end
end
//---------------------------------------------------------------------------
// Done & Busy
//---------------------------------------------------------------------------
// ser_en_d1
always @(posedge clk or posedge rst) begin
    if (rst) begin
        ser_en_d1 <= 1'd0;
    end
    else begin
        ser_en_d1 <= ser_en;
    end
end
// done
assign done = (~ser_en) & ser_en_d1;
// busy
assign busy = start | ser_en | done;

endmodule
