// Display controller: receives BCD data from the counter, selects digits
// based on mode, decodes to 7-segment, and applies blink masking
//
// Data flow:
//   BCD (ones/tens) from counter_controller
//     -> digit_selector (selects digits based on mode)
//       -> bcd_to_7seg x8 (decodes to 7-segment patterns)
//         -> blink_mask_applier (applies blink effect)
//           -> SEG0..SEG7 (LED outputs)

module display_controller (
    input wire       clk_50MHz,         // Unused, declared for port compatibility with top module
    input wire       rst_n,             // Unused, declared for port compatibility with top module
    input wire       mode,              // 0: TIME, 1: DATE
    input wire [7:0] blink_mask,        // Blink mask from blink_selector

    // BCD data from counter_controller
    input wire [3:0] sec_ones, sec_tens,
    input wire [3:0] min_ones, min_tens,
    input wire [3:0] hr_ones,  hr_tens,
    input wire [3:0] day_ones, day_tens,
    input wire [3:0] mon_ones, mon_tens,
    input wire [3:0] yr_ones,  yr_tens, yr_hundreds, yr_thousands,

    // 7-segment LED outputs (active-low)
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
    // STEP 1: Select display digits based on mode
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
    // STEP 2: Decode BCD to 7-segment patterns (8 instances)
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
    // STEP 3: Apply blink mask to 7-segment outputs
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
