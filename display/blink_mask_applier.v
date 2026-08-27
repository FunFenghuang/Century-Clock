// Ap dung mat na nhap nhay len tin hieu 7 doan
// Khi blink_mask[i] = 0, digit thu i bi tat (7'b1111111)
// Khi blink_mask[i] = 1, digit thu i hien thi binh thuong

module blink_mask_applier (
    input  [7:0] blink_mask,
    input  [6:0] seg_data_in0, seg_data_in1, seg_data_in2, seg_data_in3,
    input  [6:0] seg_data_in4, seg_data_in5, seg_data_in6, seg_data_in7,
    output reg [6:0] seg_data_out0, seg_data_out1, seg_data_out2, seg_data_out3,
    output reg [6:0] seg_data_out4, seg_data_out5, seg_data_out6, seg_data_out7
);

    always @(*) begin
        seg_data_out0 = blink_mask[0] ? seg_data_in0 : 7'b1111111;
        seg_data_out1 = blink_mask[1] ? seg_data_in1 : 7'b1111111;
        seg_data_out2 = blink_mask[2] ? seg_data_in2 : 7'b1111111;
        seg_data_out3 = blink_mask[3] ? seg_data_in3 : 7'b1111111;
        seg_data_out4 = blink_mask[4] ? seg_data_in4 : 7'b1111111;
        seg_data_out5 = blink_mask[5] ? seg_data_in5 : 7'b1111111;
        seg_data_out6 = blink_mask[6] ? seg_data_in6 : 7'b1111111;
        seg_data_out7 = blink_mask[7] ? seg_data_in7 : 7'b1111111;
    end

endmodule
