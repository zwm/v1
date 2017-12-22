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
    rst_n,
    start,
    busy,
    done,
    crc_match,
    check_bits,
    check_len
);

//---------------------------------------------------------------------------
// port
//---------------------------------------------------------------------------
input                       clk;
input                       rst_n;
input                       start;
output                      busy;
output                      done;
output                      crc_match;
input   [36:0]              check_bits;
input   [ 5:0]              check_len;
reg                         busy;
reg                         done;
reg                         crc_match;
// internal wires
wire                        crc_in;
reg     [15:0]              crc_reg;
wire    [15:0]              crc_next;
reg     [ 5:0]              bit_cnt;
reg     [36:0]              data_cache;
// bit_cnt
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        bit_cnt <= 6'd0;
    end
    else begin
        if (start) begin
            bit_cnt <= check_len;
        end
        else if (bit_cnt != 0) begin
            bit_cnt <= bit_cnt - 1;
        end
    end
end
// crc_en
assign crc_en = |bit_cnt;
// crc_reg
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
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
// data_cache
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        data_cache <= 37'd0;
    end
    else begin
        if (start) begin
            data_cache <= check_bits;
        end
        else if (crc_en) begin
            data_cache <= {1'd0, data_cache[36:1]};
        end
    end
end
// crc_in
assign crc_in = data_cache[0];
// crc16 inst
vdec_hs_crc16 ucrc16 (
    .crc_in     ( crc_in    ),
    .crc_reg    ( crc_reg   ),
    .crc_next   ( crc_next  )
);
// crc_match
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        crc_match <= 1'd0;
    end
    else begin
        if (start) begin
            crc_match <= 1'd0;
        end
        else if (bit_cnt == 5'd1) begin
            if (crc_next == 16'd0) begin
                crc_match <= 1'd1;
            end
            else begin
                crc_match <= 1'd0;
            end
        end
    end
end
// done
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
        done <= 1'd0;
    end
    else begin
        if (bit_cnt == 5'd1) begin
            done <= 1'd1;
        end
        else begin
            done <= 1'd0;
        end
    end
end
// busy
always @(posedge clk or negedge rst_n) begin
    if (~rst_n) begin
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
