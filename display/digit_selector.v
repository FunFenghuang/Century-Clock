// Chon digit hien thi dua tren mode
// mode = 0 -> TIME: HH:MM:SS (dig7..dig0)
// mode = 1 -> DATE: DD-MM-YYYY (dig7..dig0)

module digit_selector (
    // Du lieu BCD tu counter_controller
    input [3:0] sec_ones, sec_tens,
    input [3:0] min_ones, min_tens,
    input [3:0] hr_ones,  hr_tens,
    input [3:0] day_ones, day_tens,
    input [3:0] mon_ones, mon_tens,
    input [3:0] yr_ones,  yr_tens,
    input [3:0] yr_hundreds, yr_thousands,

    input mode,             // 0: DATE, 1: TIME

    // 8 digit output cho 8 led 7 doan
    output reg [3:0] dig0, dig1, dig2, dig3,
    output reg [3:0] dig4, dig5, dig6, dig7
);

    always @(*) begin
        if (mode == 1'b0) begin
            // TIME mode: HH:MM:SS
            // SEG7 SEG6 : SEG5 SEG4 : SEG3 SEG2   SEG1 SEG0
            //  H10  H1  :  M10  M1  :  S10  S1     off  off
            dig7 = hr_tens;
            dig6 = hr_ones;
            dig5 = min_tens;
            dig4 = min_ones;
            dig3 = sec_tens;
            dig2 = sec_ones;
            dig1 = 4'b1111;         // tat (off)
            dig0 = 4'b1111;         // tat (off)
        end
        else begin
            // DATE mode: DD-MM-YYYY
            // SEG7 SEG6 : SEG5 SEG4 : SEG3 SEG2 SEG1 SEG0
            //  D10  D1  :  M10  M1  :  Y3   Y2   Y1   Y0
            dig7 = day_tens;
            dig6 = day_ones;
            dig5 = mon_tens;
            dig4 = mon_ones;
            dig3 = yr_thousands;
            dig2 = yr_hundreds;
            dig1 = yr_tens;
            dig0 = yr_ones;
        end
    end

endmodule
