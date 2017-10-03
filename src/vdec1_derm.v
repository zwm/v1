//////////////////////////////////////////////////////////////////////////////
// Module Name          : vdec1_derm                                        //
//                                                                          //
// Type                 : Module                                            //
//                                                                          //
// Module Description   : De-ratematching                                   //
//                                                                          //
// Timing Constraints   : Module is designed to work with a clock frequency //
//                        of 307.2 MHz                                      //
//                                                                          //
// Revision History     : 20170926    V0.1    File created                  //
//                                                                          //
//////////////////////////////////////////////////////////////////////////////
module vdec1_derm (
    hs_mode,
    index,
    punc
);

// port
input   [1:0]       hs_mode;        // 00: part1, 01: part2, 10: agch
input   [7:0]       index;
output              punc;

//---------------------------------------------------------------------------
// part1 proc
//---------------------------------------------------------------------------
reg                 punc_part1;
// 1,2,4,8,42,45,47,48 are punctured.
always @(*) begin
    if ((   index == 8'd0      ) ||
        (   index == 8'd1      ) ||
        (   index == 8'd3      ) ||
        (   index == 8'd7      ) ||
        (   index == 8'd41     ) ||
        (   index == 8'd44     ) ||
        (   index == 8'd46     ) ||
        (   index == 8'd47     )) begin
        punc_part1 = 1'b1;
    end
    else begin
        punc_part1 = 1'b0;
    end
end
//---------------------------------------------------------------------------
// part2 proc
//---------------------------------------------------------------------------
reg                 punc_part2;
// 1,2,3,4,5,6,7,8,12,14,15,24,42,48,54,57,60,66,69,96,99,101,102,104,105,106,107,108,109,110,111 are punctured.
always @(*) begin
    if ((   index == 8'd0      ) ||
        (   index == 8'd1      ) ||
        (   index == 8'd2      ) ||
        (   index == 8'd3      ) ||
        (   index == 8'd4      ) ||
        (   index == 8'd5      ) ||
        (   index == 8'd6      ) ||
        (   index == 8'd7      ) ||
        (   index == 8'd11     ) ||
        (   index == 8'd13     ) ||
        (   index == 8'd14     ) ||
        (   index == 8'd23     ) ||
        (   index == 8'd41     ) ||
        (   index == 8'd47     ) ||
        (   index == 8'd53     ) ||
        (   index == 8'd56     ) ||
        (   index == 8'd59     ) ||
        (   index == 8'd65     ) ||
        (   index == 8'd68     ) ||
        (   index == 8'd95     ) ||
        (   index == 8'd98     ) ||
        (   index == 8'd100    ) ||
        (   index == 8'd101    ) ||
        (   index == 8'd103    ) ||
        (   index == 8'd104    ) ||
        (   index == 8'd105    ) ||
        (   index == 8'd106    ) ||
        (   index == 8'd107    ) ||
        (   index == 8'd108    ) ||
        (   index == 8'd109    ) ||
        (   index == 8'd110    )) begin
        punc_part2 = 1'b1;
    end
    else begin
        punc_part2 = 1'b0;
    end
end
//---------------------------------------------------------------------------
// agch proc
//---------------------------------------------------------------------------
reg                 punc_agch;
// 1,2,5,6,7,11,12,14,15,17,23,24,31,37,44,47,61,63,64,71,72,75,77,80,83,84,85,87,88,90 are punctured.
always @(*) begin
    if ((   index == 8'd0      ) ||
        (   index == 8'd1      ) ||
        (   index == 8'd4      ) ||
        (   index == 8'd5      ) ||
        (   index == 8'd6      ) ||
        (   index == 8'd10     ) ||
        (   index == 8'd11     ) ||
        (   index == 8'd13     ) ||
        (   index == 8'd14     ) ||
        (   index == 8'd16     ) ||
        (   index == 8'd22     ) ||
        (   index == 8'd23     ) ||
        (   index == 8'd30     ) ||
        (   index == 8'd36     ) ||
        (   index == 8'd43     ) ||
        (   index == 8'd46     ) ||
        (   index == 8'd60     ) ||
        (   index == 8'd62     ) ||
        (   index == 8'd63     ) ||
        (   index == 8'd70     ) ||
        (   index == 8'd71     ) ||
        (   index == 8'd74     ) ||
        (   index == 8'd76     ) ||
        (   index == 8'd79     ) ||
        (   index == 8'd82     ) ||
        (   index == 8'd83     ) ||
        (   index == 8'd84     ) ||
        (   index == 8'd86     ) ||
        (   index == 8'd87     ) ||
        (   index == 8'd89     )) begin
        punc_agch = 1'b1;
    end
    else begin
        punc_agch = 1'b0;
    end
end
//---------------------------------------------------------------------------
// output
//---------------------------------------------------------------------------
reg                 punc;
// proc
always @(*) begin
    case (hs_mode)
        2'b00   : punc = punc_part1;
        2'b01   : punc = punc_part2;
        2'b10   : punc = punc_agch;
        default : punc = 1'b0;
    endcase
end

endmodule
