//////////////////////////////////////////////////////////////////////////////
// Module Name          : vdec_hs_crc_check                                 //
//                                                                          //
// Type                 : Module                                            //
//                                                                          //
// Module Description   : Serial CRC check                                  //
//                        Info Length   : 21/6                              //
//                        CRC Length    : 16                                //
//                                                                          //
// Timing Constraints   : Module is designed to work with a clock frequency //
//                        of 307.2 MHz                                      //
//                                                                          //
// Revision History     : 20171003    V0.1    File created                  //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
module vdec_hs_crc_check (
    clk,
    rst,
    start,
    busy,
    done,
    crc_match,
    info_bits,
    crc_bits,
    info_len
);

//---------------------------------------------------------------------------
// port
//---------------------------------------------------------------------------
input                       clk;
input                       rst;
input                       start;
output                      busy;
output                      done;
output                      crc_match;
input   [20:0]              info_bits;
input   [15:0]              crc_bits;
input   [ 4:0]              info_len;
reg                         busy;
reg                         done;
reg                         crc_match;
// internal wires
wire                        crc_in;
reg     [15:0]              crc_reg;
wire    [15:0]              crc_next;
reg     [ 4:0]              bit_cnt;
reg     [20:0]              info_cache;
// bit_cnt
always @(posedge clk or posedge rst) begin
    if (rst) begin
        bit_cnt <= 5'd0;
    end
    else begin
        if (start) begin
            bit_cnt <= info_len;
        end
        else if (bit_cnt != 0) begin
            bit_cnt <= bit_cnt - 1;
        end
    end
end
// crc_en
assign crc_en = |bit_cnt;
// crc_reg
always @(posedge clk or posedge rst) begin
    if (rst) begin
        crc_reg <= 16'd0;
    end
    else begin
        if (start) begin
            crc_reg <= 16'd0;
        end
        else if (crc_en) begin
            crc_reg <= crc_next;
        end
    end
end
// info_cache
always @(posedge clk or posedge rst) begin
    if (rst) begin
        info_cache <= 21'd0;
    end
    else begin
        if (start) begin
            info_cache <= info_bits;
        end
        else if (crc_en) begin
            info_cache <= {1'd0, info_cache[20:1]};
        end
    end
end
// crc_in
assign crc_in = info_cache[0];
// crc16 inst
vdec_hs_crc16 ucrc16 (
    .crc_in     ( crc_in    ),
    .crc_reg    ( crc_reg   ),
    .crc_next   ( crc_next  )
);
// crc_match
always @(posedge clk or posedge rst) begin
    if (rst) begin
        crc_match <= 1'd0;
    end
    else begin
        if (start) begin
            crc_match <= 1'd0;
        end
        else if (bit_cnt == 4'd1) begin
            if (crc_bits == crc_next) begin
                crc_match <= 1'd1;
            end
            else begin
                crc_match <= 1'd0;
            end
        end
    end
end
// done
always @(posedge clk or posedge rst) begin
    if (rst) begin
        done <= 1'd0;
    end
    else begin
        if (bit_cnt == 4'd1) begin
            done <= 1'd1;
        end
        else begin
            done <= 1'd0;
        end
    end
end
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
