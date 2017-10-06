//////////////////////////////////////////////////////////////////////////////
// Module Name          : vdec_hs_ctrl                                      //
//                                                                          //
// Type                 : Module                                            //
//                                                                          //
// Module Description   : FSM of vdec_hs                                    //
//                                                                          //
// Timing Constraints   : Module is designed to work with a clock frequency //
//                        of 307.2 MHz                                      //
//                                                                          //
// Revision History     : 20171004    V0.1    File created                  //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
module vdec_hs_ctrl (
    clk,
    rst,
    start,
    busy,
    done,
    hs_mode,
    crc_match,
    agch_crc_sel,
    fwd_start,
    fwd_done,
    bwd_start,
    bwd_done,
    crc_start,
    crc_done,
    ser_start,
    ser_done,
    fsm_out
);

//---------------------------------------------------------------------------
// port
//---------------------------------------------------------------------------
input                       clk;
input                       rst;
input                       start;
output                      busy;
output                      done;
input   [ 1:0]              hs_mode;
input                       crc_match;
output                      agch_crc_sel;
output                      fwd_start;
input                       fwd_done;
output                      bwd_start;
input                       bwd_done;
output                      crc_start;
input                       crc_done;
output                      ser_start;
input                       ser_done;
output  [ 2:0]              fsm_out;
reg                         fwd_start;
reg                         bwd_start;
reg                         crc_start;
reg                         ser_start;
// internal wires
reg     [ 2:0]              fsm;
reg     [ 2:0]              fsm_next;
// State Machine Define
parameter   IDLE            = 3'b000;
parameter   FWD             = 3'b001;
parameter   BWD             = 3'b010;
parameter   CRC1            = 3'b011;
parameter   CRC2            = 3'b100;
parameter   SER             = 3'b101;
parameter   FINISH          = 3'b110;
// fsm
always @(posedge clk or posedge rst) begin
    if (rst) begin
        fsm <= IDLE;
    end
    else begin
        fsm <= fsm_next;
    end
end
// fsm_next
always @(*) begin
    case (fsm)
        IDLE :      // wait for start
            if (start) begin
                fsm_next = FWD;
            end
            else begin
                fsm_next = IDLE;
            end
        FWD :       // vdec forward
            if (fwd_done) begin
                fsm_next = BWD;
            end
            else begin
                fsm_next = FWD;
            end
        BWD :       // vdec traceback
            if (bwd_done) begin
                if (hs_mode == 2'b00) begin     // part1
                    fsm_next = SER;
                end
                else begin
                    fsm_next = CRC1;
                end
            end
            else begin
                fsm_next = BWD;
            end
        CRC1 :      // 1st CRC check
            if (crc_done) begin
                if (hs_mode == 2'b01) begin     // part2
                    if (crc_match) begin
                        fsm_next = SER;
                    end
                    else begin
                        fsm_next = FINISH;
                    end
                end
                else begin                      // agch
                    if (crc_match) begin
                        fsm_next = SER;
                    end
                    else begin
                        fsm_next = CRC2;
                    end
                end
            end
            else begin
                fsm_next = CRC1;
            end
        CRC2 :      // 2nd CRC check
            if (crc_done) begin
                if (crc_match) begin
                    fsm_next = SER;
                end
                else begin
                    fsm_next = FINISH;
                end
            end
            else begin
                fsm_next = CRC2;
            end
        SER :       // SER calc
            if (ser_done) begin
                fsm_next = FINISH;
            end
            else begin
                fsm_next = SER;
            end
        FINISH :    // Finish!!
            fsm_next = IDLE;
    endcase
end
// drive output
// fwd_start
always @(posedge clk or posedge rst) begin
    if (rst) begin
        fwd_start <= 1'd0;
    end
    else begin
        if (fsm == IDLE && fsm_next == FWD) begin
            fwd_start <= 1'd1;
        end
        else begin
            fwd_start <= 1'd0;
        end
    end
end
// bwd_start
always @(posedge clk or posedge rst) begin
    if (rst) begin
        bwd_start <= 1'd0;
    end
    else begin
        if (fsm == FWD && fsm_next == BWD) begin
            bwd_start <= 1'd1;
        end
        else begin
            bwd_start <= 1'd0;
        end
    end
end
// crc_start
always @(posedge clk or posedge rst) begin
    if (rst) begin
        crc_start <= 1'd0;
    end
    else begin
        if ((fsm == BWD && fsm_next == CRC1) || (fsm == CRC1 && fsm_next == CRC2)) begin
            crc_start <= 1'd1;
        end
        else begin
            crc_start <= 1'd0;
        end
    end
end
// ser_start
always @(posedge clk or posedge rst) begin
    if (rst) begin
        ser_start <= 1'd0;
    end
    else begin
        if (fsm != SER && fsm_next == SER) begin
            ser_start <= 1'd1;
        end
        else begin
            ser_start <= 1'd0;
        end
    end
end
// Output
assign fsm_out      = fsm;
assign agch_crc_sel = (fsm == CRC2  ) ? 1'd1 : 1'd0;
assign busy         = (fsm == IDLE  ) ? 1'd0 : 1'd1;
assign done         = (fsm == FINISH) ? 1'd1 : 1'd0;

endmodule
