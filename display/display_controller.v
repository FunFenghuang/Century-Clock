// Khoi dieu khien hien thi: nhan du lieu BCD tu counter, chon digit theo mode,
// giai ma 7 doan, ap dung nhap nhay
//
// Luong du lieu:
//   BCD (ones/tens) tu counter_controller
//     -> digit_selector (chon theo mode)
//       -> bcd_to_7seg x8 (giai ma 7 doan)
//         -> blink_mask_applier (ap dung nhap nhay)
//           -> SEG0..SEG7 (dau ra LED)

module display_controller (
    input wire       clk_50MHz,         // khong dung, khai bao de khop voi control_controller
    input wire       rst_n,             // khong dung, khai bao de khop voi control_controller
    input wire       mode,      // 0: DATE, 1: TIME
    input wire [7:0] blink_mask,        // mat na nhap nhay tu blink_selector

    // Du lieu BCD tu counter_controller (KHONG THAY DOI)
    input wire [3:0] sec_ones, sec_tens,
    input wire [3:0] min_ones, min_tens,
    input wire [3:0] hr_ones,  hr_tens,
    input wire [3:0] day_ones, day_tens,
    input wire [3:0] mon_ones, mon_tens,
    input wire [3:0] yr_ones,  yr_tens, yr_hundreds, yr_thousands,

    // Xuat ra 8 LED 7 doan
    output wire [6:0] SEG0,
    output wire [6:0] SEG1,
    output wire [6:0] SEG2,
    output wire [6:0] SEG3,
    output wire [6:0] SEG4,
    output wire [6:0] SEG5,
    output wire [6:0] SEG6,
    output wire [6:0] SEG7
);

    // ========================================================
    // BUOC 1: Chon digit hien thi theo mode
    // ========================================================
    wire [3:0] dig0, dig1, dig2, dig3, dig4, dig5, dig6, dig7;

    digit_selector my_digit_sel (
        .sec_ones(sec_ones), .sec_tens(sec_tens),
        .min_ones(min_ones), .min_tens(min_tens),
        .hr_ones(hr_ones),   .hr_tens(hr_tens),
        .day_ones(day_ones), .day_tens(day_tens),
        .mon_ones(mon_ones), .mon_tens(mon_tens),
        .yr_ones(yr_ones),   .yr_tens(yr_tens),
        .yr_hundreds(yr_hundreds), .yr_thousands(yr_thousands),

        .mode(mode),

        .dig0(dig0), .dig1(dig1), .dig2(dig2), .dig3(dig3),
        .dig4(dig4), .dig5(dig5), .dig6(dig6), .dig7(dig7)
    );

    // ========================================================
    // BUOC 2: Giai ma BCD sang ma 7 doan (8 instance)
    // ========================================================
    wire [6:0] seg_raw0, seg_raw1, seg_raw2, seg_raw3;
    wire [6:0] seg_raw4, seg_raw5, seg_raw6, seg_raw7;

    bcd_to_7seg my_seg0 (.data(dig0), .seg_data(seg_raw0));
    bcd_to_7seg my_seg1 (.data(dig1), .seg_data(seg_raw1));
    bcd_to_7seg my_seg2 (.data(dig2), .seg_data(seg_raw2));
    bcd_to_7seg my_seg3 (.data(dig3), .seg_data(seg_raw3));
    bcd_to_7seg my_seg4 (.data(dig4), .seg_data(seg_raw4));
    bcd_to_7seg my_seg5 (.data(dig5), .seg_data(seg_raw5));
    bcd_to_7seg my_seg6 (.data(dig6), .seg_data(seg_raw6));
    bcd_to_7seg my_seg7 (.data(dig7), .seg_data(seg_raw7));

    // ========================================================
    // BUOC 3: Ap dung mat na nhap nhay
    // ========================================================
    blink_mask_applier my_blink_apply (
        .blink_mask(blink_mask),

        .seg_data_in0(seg_raw0), .seg_data_in1(seg_raw1),
        .seg_data_in2(seg_raw2), .seg_data_in3(seg_raw3),
        .seg_data_in4(seg_raw4), .seg_data_in5(seg_raw5),
        .seg_data_in6(seg_raw6), .seg_data_in7(seg_raw7),

        .seg_data_out0(SEG0), .seg_data_out1(SEG1),
        .seg_data_out2(SEG2), .seg_data_out3(SEG3),
        .seg_data_out4(SEG4), .seg_data_out5(SEG5),
        .seg_data_out6(SEG6), .seg_data_out7(SEG7)
    );

endmodule
