//////////////////////////////////////////////////////////////////////////////
// Module Name          : vdec_hs_bwd                                       //
//                                                                          //
// Type                 : Module                                            //
//                                                                          //
// Module Description   : Backward traceback                                //
//                        Code rate         : only 1/3                      //
//                        Codeblk_size      : max 29                        //
//                        Tail bits         : 8                             //
//                                                                          //
// Timing Constraints   : Module is designed to work with a clock frequency //
//                        of 307.2 MHz                                      //
//                                                                          //
// Revision History     : 20171003    V0.1    File created                  //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
module vdec_hs_bwd (
    clk,
    rst,
    start,
    busy,
    done,
    dec_bits,
    codeblk_size_p7,
    pt_rd,
    pt_addr,
    pt_dout
);

//---------------------------------------------------------------------------
// port
//---------------------------------------------------------------------------
input                       clk;
input                       rst;
input                       start;
output                      busy;
output                      done;
output  [28:0]              dec_bits;
input   [ 5:0]              codeblk_size_p7;
output                      pt_rd;
output  [8:0]               pt_addr;            // ptram: 37*8*32b=296*32b
input   [31:0]              pt_dout;
reg                         busy;
reg                         done;
reg     [28:0]              dec_bits;
reg                         pt_rd;
reg     [8:0]               pt_addr;

// internal wires
reg                         pt_rd_d1;
reg     [7:0]               pre_state;
reg     [7:0]               cur_state;
reg     [3:0]               train_cnt;
reg                         done_tmp1;
// pt_addr
always @(posedge clk or posedge rst) begin
    if (rst) begin
        pt_addr <= 9'd0;
    end
    else begin
        if (start) begin
            pt_addr <= {codeblk_size_p7[5:0], 3'd0};
        end
        else if (pt_addr[8:3] != 0) begin
            pt_addr[8:3] <= pt_addr[8:3] - 1;
            pt_addr[2:0] <= pre_state[7:5];
        end
    end
end
// pt_rd
always @(posedge clk or posedge rst) begin
    if (rst) begin
        pt_rd <= 1'd0;
    end
    else begin
        if (start) begin
            pt_rd <= 1'd1;
        end
        else if (pt_addr[8:3] == 0) begin
            pt_rd <= 1'd0;
        end
    end
end
// pt_rd_d1
always @(posedge clk or posedge rst) begin
    if (rst) begin
        pt_rd_d1 <= 1'd0;
    end
    else begin
        pt_rd_d1 <= pt_rd;
    end
end
// cur_state
always @(posedge clk or posedge rst) begin
    if (rst) begin
        cur_state <= 8'd0;
    end
    else begin
        if (start) begin
            cur_state <= 8'd0;
        end
        else if (pt_rd_d1) begin
            cur_state <= pre_state;
        end
    end
end
// pre_state
always @(*) begin
    case (cur_state[4:0])
        5'd0    : pre_state = {pt_dout[ 0], cur_state[7:1]};
        5'd1    : pre_state = {pt_dout[ 1], cur_state[7:1]};
        5'd2    : pre_state = {pt_dout[ 2], cur_state[7:1]};
        5'd3    : pre_state = {pt_dout[ 3], cur_state[7:1]};
        5'd4    : pre_state = {pt_dout[ 4], cur_state[7:1]};
        5'd5    : pre_state = {pt_dout[ 5], cur_state[7:1]};
        5'd6    : pre_state = {pt_dout[ 6], cur_state[7:1]};
        5'd7    : pre_state = {pt_dout[ 7], cur_state[7:1]};
        5'd8    : pre_state = {pt_dout[ 8], cur_state[7:1]};
        5'd9    : pre_state = {pt_dout[ 9], cur_state[7:1]};
        5'd10   : pre_state = {pt_dout[10], cur_state[7:1]};
        5'd11   : pre_state = {pt_dout[11], cur_state[7:1]};
        5'd12   : pre_state = {pt_dout[12], cur_state[7:1]};
        5'd13   : pre_state = {pt_dout[13], cur_state[7:1]};
        5'd14   : pre_state = {pt_dout[14], cur_state[7:1]};
        5'd15   : pre_state = {pt_dout[15], cur_state[7:1]};
        5'd16   : pre_state = {pt_dout[16], cur_state[7:1]};
        5'd17   : pre_state = {pt_dout[17], cur_state[7:1]};
        5'd18   : pre_state = {pt_dout[18], cur_state[7:1]};
        5'd19   : pre_state = {pt_dout[19], cur_state[7:1]};
        5'd20   : pre_state = {pt_dout[20], cur_state[7:1]};
        5'd21   : pre_state = {pt_dout[21], cur_state[7:1]};
        5'd22   : pre_state = {pt_dout[22], cur_state[7:1]};
        5'd23   : pre_state = {pt_dout[23], cur_state[7:1]};
        5'd24   : pre_state = {pt_dout[24], cur_state[7:1]};
        5'd25   : pre_state = {pt_dout[25], cur_state[7:1]};
        5'd26   : pre_state = {pt_dout[26], cur_state[7:1]};
        5'd27   : pre_state = {pt_dout[27], cur_state[7:1]};
        5'd28   : pre_state = {pt_dout[28], cur_state[7:1]};
        5'd29   : pre_state = {pt_dout[29], cur_state[7:1]};
        5'd30   : pre_state = {pt_dout[30], cur_state[7:1]};
        default : pre_state = {pt_dout[31], cur_state[7:1]};
    endcase
end
// train_ctn
always @(posedge clk or posedge rst) begin
    if (rst) begin
        train_cnt <= 4'd0;
    end
    else begin
        if (start) begin
            train_cnt <= 4'd8;
        end
        else if (train_cnt != 4'd0 && pt_rd_d1) begin
            train_cnt <= train_cnt - 1;
        end
    end
end
// output
always @(posedge clk or posedge rst) begin
    if (rst) begin
        dec_bits <= 29'd0;
    end
    else begin
        if (start) begin
            dec_bits <= 29'd0;
        end
        else if (pt_rd_d1 == 1 && train_cnt == 4'd0) begin
            dec_bits <= {dec_bits[27:0], pre_state[7]};
        end
    end
end
// done
always @(posedge clk or posedge rst) begin
    if (rst) begin
        done_tmp1 <= 1'd0;
        done <= 1'd0;
    end
    else begin
        if (pt_rd == 1'd0 && pt_rd_d1 == 1) begin
            done_tmp1 <= 1'd1;
        end
        else begin
            done_tmp1 <= 1'd0;
        end
        done <= done_tmp1;
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
