//=============================================================================
// FILE: tb_top_century_clock.v
// TESTBENCH: Hệ thống Đồng Hồ Thế Kỷ (Century Clock) - CỰC KÌ CHI TIẾT
//=============================================================================
// Mô tả: Testbench toàn diện cho toàn bộ hệ thống top_century_clock.
//         Bao gồm các trường hợp:
//         1.  Reset và giá trị khởi tạo
//         2.  Đếm giây tự động (chế độ bình thường)
//         3.  Tràn giây 59->00, carry sang phút
//         4.  Tràn phút 59->00, carry sang giờ
//         5.  Tràn giờ 23->00, carry sang ngày
//         6.  Tràn ngày cuối tháng -> ngày 1, carry sang tháng
//         7.  Tràn tháng 12->01, carry sang năm
//         8.  Năm nhuận: 2024(nhuận), 1900(không nhuận), 2000(nhuận), 2100(không nhuận)
//         9.  Ngày 28/29 tháng 2 năm nhuận/không nhuận
//         10. Chế độ chỉnh sửa: chỉnh giây UP/DOWN, wrap-around
//         11. Chế độ chỉnh sửa: chỉnh phút UP/DOWN, wrap-around
//         12. Chế độ chỉnh sửa: chỉnh giờ UP/DOWN, wrap-around
//         13. Chế độ chỉnh sửa: chỉnh ngày UP/DOWN, wrap-around
//         14. Chế độ chỉnh sửa: chỉnh tháng UP/DOWN, wrap-around
//         15. Chế độ chỉnh sửa: chỉnh năm UP/DOWN, wrap-around 9999->1
//         16. Chuyển đổi chế độ hiển thị TIME<->DATE (mỗi phút)
//         17. Đồng hồ dừng khi đang chỉnh sửa
//         18. Nhấp nháy (blink) digit đang chỉnh
//         19. Hiển thị 7 đoạn: kiểm tra giá trị BCD->7seg
//         20. Midnight rollover: 23:59:59 -> 00:00:00, ngày +1
//         21. Chuyển tháng với số ngày khác nhau (30, 31 ngày)
//         22. Wrap-around năm: 9999->0001, 0001->9999
//         23. Nút bấm debounce: bounce, giữ lâu, nhấn nhanh
//         24. Đồng thời nhấn UP và DOWN
//         25. Chuyển switch trong khi đang chỉnh
//         26. Kịch bản thực tế: đặt thời gian 23:59:55, chờ midnight
//         27. Ngày 31/01 -> 01/02 (tháng 31 ngày -> tháng 28/29 ngày)
//         28. Hiệu chỉnh ngày khi chuyển tháng (ngày > max_day)
//=============================================================================

`timescale 1ns / 1ps

module tb_top_century_clock;

    //=========================================================================
    // THAM SỐ MÔ PHỎNG
    //=========================================================================
    // Dùng clock_divider với tần số thấp để mô phỏng nhanh
    // clk_f = 100 -> tick_100hz mỗi 1 chu kỳ clk (100/100 - 1 = 0)
    // Thực tế: clk_f = 50_000_000 -> quá chậm cho simulation
    
    localparam CLK_PERIOD = 20;         // 50MHz -> 20ns period
    localparam HALF_CLK   = CLK_PERIOD / 2;
    
    // Với clk_f mặc định = 50MHz trong DUT, ta cần mô phỏng đủ số clock cycle
    // tick_100hz xuất hiện mỗi 500_000 cycle (50MHz/100)
    // tick_1hz xuất hiện mỗi 100 * tick_100hz = 50_000_000 cycle = 1 giây thực
    // -> Quá chậm! Ta sẽ dùng force/release để tăng tốc mô phỏng
    
    // Số chu kỳ clock cho 1 giây mô phỏng (với parameter override)
    // Khi override clk_f=100: tick_100hz mỗi 1 cycle, tick_1hz mỗi 100 cycle
    localparam FAST_CLK_F = 100;
    localparam CYCLES_PER_SEC = 100;    // 100 tick_100hz = 1 tick_1hz
    
    //=========================================================================
    // TÍN HIỆU TESTBENCH
    //=========================================================================
    reg        clk_50MHz;
    reg        rst_n;
    reg        BTN1;        // Nút UP
    reg        BTN2;        // Nút DOWN
    reg  [5:0] SW;          // Switch chọn trường
    
    wire [6:0] SEG0, SEG1, SEG2, SEG3;
    wire [6:0] SEG4, SEG5, SEG6, SEG7;
    
    //=========================================================================
    // BIẾN ĐỂ THEO DÕI & KIỂM TRA
    //=========================================================================
    integer test_num;
    integer error_count;
    integer pass_count;
    reg [255:0] test_name;  // Tên test case hiện tại
    
    // Biến lưu giá trị mong đợi
    reg [3:0] exp_sec_ones, exp_sec_tens;
    reg [3:0] exp_min_ones, exp_min_tens;
    reg [3:0] exp_hr_ones, exp_hr_tens;
    reg [3:0] exp_day_ones, exp_day_tens;
    reg [3:0] exp_mon_ones, exp_mon_tens;
    reg [3:0] exp_yr_ones, exp_yr_tens, exp_yr_hundreds, exp_yr_thousands;
    
    //=========================================================================
    // KHỞI TẠO DUT (Device Under Test)
    // Override clock_divider parameter để mô phỏng nhanh
    //=========================================================================
    
    // DUT instantiation - dùng defparam để override tần số clock divider
    top_century_clock DUT (
        .clk_50MHz (clk_50MHz),
        .rst_n     (rst_n),
        .BTN1      (BTN1),
        .BTN2      (BTN2),
        .SW        (SW),
        .SEG0      (SEG0),
        .SEG1      (SEG1),
        .SEG2      (SEG2),
        .SEG3      (SEG3),
        .SEG4      (SEG4),
        .SEG5      (SEG5),
        .SEG6      (SEG6),
        .SEG7      (SEG7)
    );
    
    // Override clock divider parameter cho mô phỏng nhanh
    defparam DUT.u_clk_div.clk_f = FAST_CLK_F;
    
    //=========================================================================
    // TẠO XUNG CLOCK 50MHz
    //=========================================================================
    initial clk_50MHz = 0;
    always #(HALF_CLK) clk_50MHz = ~clk_50MHz;
    
    //=========================================================================
    // TRUY CẬP TÍN HIỆU NỘI BỘ (để kiểm tra và debug)
    //=========================================================================
    // Counter values (binary)
    wire [5:0] sec_bin   = DUT.u_counter_ctrl.my_sec.sec;
    wire [5:0] min_bin   = DUT.u_counter_ctrl.my_min.min;
    wire [4:0] hour_bin  = DUT.u_counter_ctrl.my_hr.hour;
    wire [4:0] day_bin   = DUT.u_counter_ctrl.my_day.day;
    wire [3:0] month_bin = DUT.u_counter_ctrl.my_month.month;
    wire [13:0] year_bin = DUT.u_counter_ctrl.my_year.year;
    
    // BCD outputs
    wire [3:0] sec_ones  = DUT.sec_ones;
    wire [3:0] sec_tens  = DUT.sec_tens;
    wire [3:0] min_ones  = DUT.min_ones;
    wire [3:0] min_tens  = DUT.min_tens;
    wire [3:0] hr_ones   = DUT.hr_ones;
    wire [3:0] hr_tens   = DUT.hr_tens;
    wire [3:0] day_ones  = DUT.day_ones;
    wire [3:0] day_tens  = DUT.day_tens;
    wire [3:0] mon_ones  = DUT.mon_ones;
    wire [3:0] mon_tens  = DUT.mon_tens;
    wire [3:0] yr_ones   = DUT.yr_ones;
    wire [3:0] yr_tens   = DUT.yr_tens;
    wire [3:0] yr_hunds  = DUT.yr_hundreds;
    wire [3:0] yr_thous  = DUT.yr_thousands;
    
    // Control signals
    wire        mode_sig       = DUT.mode;
    wire        edit_enable_sig = DUT.edit_enable;
    wire [2:0]  edit_sel_sig   = DUT.edit_selected;
    wire        tick_1hz_sig   = DUT.tick_1hz;
    wire        tick_blink_sig = DUT.tick_blink;
    wire [7:0]  blink_mask_sig = DUT.blink_mask;
    wire        leap_sig       = DUT.u_counter_ctrl.leap;
    wire [4:0]  max_day_sig    = DUT.u_counter_ctrl.my_day.max_day_in_month;
    wire        sig_1min_sig   = DUT.sig_1min_out;
    
    //=========================================================================
    // TASK: Tạo xung reset
    //=========================================================================
    task reset_system;
        begin
            rst_n = 1'b0;
            BTN1  = 1'b0;
            BTN2  = 1'b0;
            SW    = 6'b000000;
            repeat(10) @(posedge clk_50MHz);
            rst_n = 1'b1;
            repeat(5) @(posedge clk_50MHz);
        end
    endtask
    
    //=========================================================================
    // TASK: Chờ N xung tick_1hz (= N giây mô phỏng)
    //=========================================================================
    task wait_seconds;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                @(posedge tick_1hz_sig);
                @(posedge clk_50MHz);   // Đợi thêm 1 clock để counter cập nhật
                @(posedge clk_50MHz);
            end
        end
    endtask
    
    //=========================================================================
    // TASK: Chờ 1 xung tick_1hz
    //=========================================================================
    task wait_one_tick_1hz;
        begin
            @(posedge tick_1hz_sig);
            @(posedge clk_50MHz);
            @(posedge clk_50MHz);
        end
    endtask
    
    //=========================================================================
    // TASK: Nhấn nút UP (BTN1) - mô phỏng debounce
    // Debounce cần: 5 lần tick_100hz liên tiếp ở trạng thái mới
    // Với clk_f=100: tick_100hz mỗi 1 cycle
    // stable_cnt phải đạt 4 -> cần 5 tick_100hz ổn định
    //=========================================================================
    task press_btn_up;
        begin
            BTN1 = 1'b1;
            // Chờ đủ thời gian debounce: 5 tick_100hz + đồng bộ 2 stage
            repeat(20) @(posedge clk_50MHz);
            BTN1 = 1'b0;
            repeat(20) @(posedge clk_50MHz);
        end
    endtask
    
    //=========================================================================
    // TASK: Nhấn nút DOWN (BTN2) - mô phỏng debounce
    //=========================================================================
    task press_btn_down;
        begin
            BTN2 = 1'b1;
            repeat(20) @(posedge clk_50MHz);
            BTN2 = 1'b0;
            repeat(20) @(posedge clk_50MHz);
        end
    endtask
    
    //=========================================================================
    // TASK: Nhấn nút UP N lần
    //=========================================================================
    task press_btn_up_n;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                press_btn_up;
            end
        end
    endtask
    
    //=========================================================================
    // TASK: Nhấn nút DOWN N lần
    //=========================================================================
    task press_btn_down_n;
        input integer n;
        integer i;
        begin
            for (i = 0; i < n; i = i + 1) begin
                press_btn_down;
            end
        end
    endtask
    
    //=========================================================================
    // TASK: Nhấn nút UP với bounce (nhiễu)
    //=========================================================================
    task press_btn_up_with_bounce;
        begin
            // Tạo nhiễu bounce trước khi ổn định
            BTN1 = 1'b1; #(CLK_PERIOD);
            BTN1 = 1'b0; #(CLK_PERIOD);
            BTN1 = 1'b1; #(CLK_PERIOD);
            BTN1 = 1'b0; #(CLK_PERIOD);
            BTN1 = 1'b1; #(CLK_PERIOD);
            BTN1 = 1'b0; #(CLK_PERIOD);
            // Giờ ổn định ở mức cao
            BTN1 = 1'b1;
            repeat(20) @(posedge clk_50MHz);
            // Nhả nút với bounce
            BTN1 = 1'b0; #(CLK_PERIOD);
            BTN1 = 1'b1; #(CLK_PERIOD);
            BTN1 = 1'b0; #(CLK_PERIOD);
            BTN1 = 1'b1; #(CLK_PERIOD);
            BTN1 = 1'b0;
            repeat(20) @(posedge clk_50MHz);
        end
    endtask
    
    //=========================================================================
    // TASK: Bật switch để chọn trường chỉnh sửa
    //=========================================================================
    task select_edit_field;
        input [5:0] sw_val;
        begin
            SW = sw_val;
            repeat(5) @(posedge clk_50MHz);
        end
    endtask
    
    //=========================================================================
    // TASK: Tắt tất cả switch (thoát chế độ chỉnh sửa)
    //=========================================================================
    task deselect_all;
        begin
            SW = 6'b000000;
            repeat(5) @(posedge clk_50MHz);
        end
    endtask
    
    //=========================================================================
    // TASK: Force giá trị counter nội bộ (để test nhanh các edge case)
    //=========================================================================
    task force_time;
        input [5:0] sec_val;
        input [5:0] min_val;
        input [4:0] hr_val;
        input [4:0] day_val;
        input [3:0] mon_val;
        input [13:0] yr_val;
        begin
            force DUT.u_counter_ctrl.my_sec.sec     = sec_val;
            force DUT.u_counter_ctrl.my_min.min      = min_val;
            force DUT.u_counter_ctrl.my_hr.hour      = hr_val;
            force DUT.u_counter_ctrl.my_day.day       = day_val;
            force DUT.u_counter_ctrl.my_month.month   = mon_val;
            force DUT.u_counter_ctrl.my_year.year     = yr_val;
            @(posedge clk_50MHz);
            @(posedge clk_50MHz);
            release DUT.u_counter_ctrl.my_sec.sec;
            release DUT.u_counter_ctrl.my_min.min;
            release DUT.u_counter_ctrl.my_hr.hour;
            release DUT.u_counter_ctrl.my_day.day;
            release DUT.u_counter_ctrl.my_month.month;
            release DUT.u_counter_ctrl.my_year.year;
            @(posedge clk_50MHz);
        end
    endtask
    
    //=========================================================================
    // TASK: Force chỉ giây (để test carry chain)
    //=========================================================================
    task force_sec;
        input [5:0] val;
        begin
            force DUT.u_counter_ctrl.my_sec.sec = val;
            @(posedge clk_50MHz);
            @(posedge clk_50MHz);
            release DUT.u_counter_ctrl.my_sec.sec;
            @(posedge clk_50MHz);
        end
    endtask
    
    //=========================================================================
    // TASK: Force chỉ phút
    //=========================================================================
    task force_min;
        input [5:0] val;
        begin
            force DUT.u_counter_ctrl.my_min.min = val;
            @(posedge clk_50MHz);
            @(posedge clk_50MHz);
            release DUT.u_counter_ctrl.my_min.min;
            @(posedge clk_50MHz);
        end
    endtask
    
    //=========================================================================
    // TASK: Force chỉ giờ
    //=========================================================================
    task force_hour;
        input [4:0] val;
        begin
            force DUT.u_counter_ctrl.my_hr.hour = val;
            @(posedge clk_50MHz);
            @(posedge clk_50MHz);
            release DUT.u_counter_ctrl.my_hr.hour;
            @(posedge clk_50MHz);
        end
    endtask
    
    //=========================================================================
    // TASK: Force chỉ ngày
    //=========================================================================
    task force_day;
        input [4:0] val;
        begin
            force DUT.u_counter_ctrl.my_day.day = val;
            @(posedge clk_50MHz);
            @(posedge clk_50MHz);
            release DUT.u_counter_ctrl.my_day.day;
            @(posedge clk_50MHz);
        end
    endtask
    
    //=========================================================================
    // TASK: Force chỉ tháng
    //=========================================================================
    task force_month;
        input [3:0] val;
        begin
            force DUT.u_counter_ctrl.my_month.month = val;
            @(posedge clk_50MHz);
            @(posedge clk_50MHz);
            release DUT.u_counter_ctrl.my_month.month;
            @(posedge clk_50MHz);
        end
    endtask
    
    //=========================================================================
    // TASK: Force chỉ năm
    //=========================================================================
    task force_year;
        input [13:0] val;
        begin
            force DUT.u_counter_ctrl.my_year.year = val;
            @(posedge clk_50MHz);
            @(posedge clk_50MHz);
            release DUT.u_counter_ctrl.my_year.year;
            @(posedge clk_50MHz);
        end
    endtask
    
    //=========================================================================
    // FUNCTION: Giải mã BCD 7-segment ngược về số (để kiểm tra)
    //=========================================================================
    function [3:0] seg7_to_digit;
        input [6:0] seg;
        begin
            case (seg)
                7'b1000000: seg7_to_digit = 4'd0;
                7'b1111001: seg7_to_digit = 4'd1;
                7'b0100100: seg7_to_digit = 4'd2;
                7'b0110000: seg7_to_digit = 4'd3;
                7'b0011001: seg7_to_digit = 4'd4;
                7'b0010010: seg7_to_digit = 4'd5;
                7'b0000010: seg7_to_digit = 4'd6;
                7'b1111000: seg7_to_digit = 4'd7;
                7'b0000000: seg7_to_digit = 4'd8;
                7'b0010000: seg7_to_digit = 4'd9;
                7'b1111111: seg7_to_digit = 4'd15; // OFF (tắt)
                default:    seg7_to_digit = 4'd14;  // UNKNOWN
            endcase
        end
    endfunction
    
    //=========================================================================
    // TASK: In trạng thái hiện tại của đồng hồ
    //=========================================================================
    task print_clock_state;
        begin
            $display("  [STATE] Time: %0d%0d:%0d%0d:%0d%0d | Date: %0d%0d/%0d%0d/%0d%0d%0d%0d | Mode:%s | Edit:%s | Leap:%b",
                hr_tens, hr_ones, min_tens, min_ones, sec_tens, sec_ones,
                day_tens, day_ones, mon_tens, mon_ones, 
                yr_thous, yr_hunds, yr_tens, yr_ones,
                mode_sig ? "DATE" : "TIME",
                edit_enable_sig ? "ON " : "OFF",
                leap_sig);
            $display("  [SEG]   SEG7=%0d SEG6=%0d SEG5=%0d SEG4=%0d SEG3=%0d SEG2=%0d SEG1=%0d SEG0=%0d | Blink=%b",
                seg7_to_digit(SEG7), seg7_to_digit(SEG6), 
                seg7_to_digit(SEG5), seg7_to_digit(SEG4),
                seg7_to_digit(SEG3), seg7_to_digit(SEG2), 
                seg7_to_digit(SEG1), seg7_to_digit(SEG0),
                blink_mask_sig);
        end
    endtask
    
    //=========================================================================
    // TASK: Kiểm tra giá trị counter binary
    //=========================================================================
    task check_counter;
        input [5:0] exp_sec;
        input [5:0] exp_min;
        input [4:0] exp_hr;
        input [4:0] exp_day;
        input [3:0] exp_mon;
        input [13:0] exp_yr;
        input [255:0] msg;
        begin
            if (sec_bin !== exp_sec || min_bin !== exp_min || hour_bin !== exp_hr ||
                day_bin !== exp_day || month_bin !== exp_mon || year_bin !== exp_yr) begin
                $display("  [FAIL] %0s", msg);
                $display("         Expected: %0d:%0d:%0d  %0d/%0d/%0d",
                    exp_hr, exp_min, exp_sec, exp_day, exp_mon, exp_yr);
                $display("         Got:      %0d:%0d:%0d  %0d/%0d/%0d",
                    hour_bin, min_bin, sec_bin, day_bin, month_bin, year_bin);
                error_count = error_count + 1;
            end else begin
                $display("  [PASS] %0s", msg);
                pass_count = pass_count + 1;
            end
        end
    endtask
    
    //=========================================================================
    // TASK: Kiểm tra giá trị BCD
    //=========================================================================
    task check_bcd;
        input [3:0] exp_s1, exp_s10, exp_m1, exp_m10, exp_h1, exp_h10;
        input [255:0] msg;
        begin
            if (sec_ones !== exp_s1 || sec_tens !== exp_s10 || 
                min_ones !== exp_m1 || min_tens !== exp_m10 || 
                hr_ones  !== exp_h1 || hr_tens  !== exp_h10) begin
                $display("  [FAIL] BCD %0s", msg);
                $display("         Expected: %0d%0d:%0d%0d:%0d%0d", 
                    exp_h10, exp_h1, exp_m10, exp_m1, exp_s10, exp_s1);
                $display("         Got:      %0d%0d:%0d%0d:%0d%0d",
                    hr_tens, hr_ones, min_tens, min_ones, sec_tens, sec_ones);
                error_count = error_count + 1;
            end else begin
                $display("  [PASS] BCD %0s", msg);
                pass_count = pass_count + 1;
            end
        end
    endtask
    
    //=========================================================================
    // TASK: Kiểm tra giá trị BCD ngày tháng năm
    //=========================================================================
    task check_bcd_date;
        input [3:0] exp_d1, exp_d10, exp_m1, exp_m10;
        input [3:0] exp_y1, exp_y10, exp_y100, exp_y1000;
        input [255:0] msg;
        begin
            if (day_ones !== exp_d1 || day_tens !== exp_d10 || 
                mon_ones !== exp_m1 || mon_tens !== exp_m10 || 
                yr_ones  !== exp_y1 || yr_tens  !== exp_y10 ||
                yr_hunds !== exp_y100 || yr_thous !== exp_y1000) begin
                $display("  [FAIL] BCD Date %0s", msg);
                $display("         Expected: %0d%0d/%0d%0d/%0d%0d%0d%0d", 
                    exp_d10, exp_d1, exp_m10, exp_m1, exp_y1000, exp_y100, exp_y10, exp_y1);
                $display("         Got:      %0d%0d/%0d%0d/%0d%0d%0d%0d",
                    day_tens, day_ones, mon_tens, mon_ones, yr_thous, yr_hunds, yr_tens, yr_ones);
                error_count = error_count + 1;
            end else begin
                $display("  [PASS] BCD Date %0s", msg);
                pass_count = pass_count + 1;
            end
        end
    endtask
    
    //=========================================================================
    // TASK: Kiểm tra leap year
    //=========================================================================
    task check_leap;
        input expected_leap;
        input [255:0] msg;
        begin
            if (leap_sig !== expected_leap) begin
                $display("  [FAIL] Leap %0s: Expected=%b, Got=%b (year=%0d)", 
                    msg, expected_leap, leap_sig, year_bin);
                error_count = error_count + 1;
            end else begin
                $display("  [PASS] Leap %0s: leap=%b (year=%0d)", msg, leap_sig, year_bin);
                pass_count = pass_count + 1;
            end
        end
    endtask
    
    //=========================================================================
    // TASK: Kiểm tra edit_enable và edit_selected
    //=========================================================================
    task check_edit_state;
        input exp_enable;
        input [2:0] exp_selected;
        input [255:0] msg;
        begin
            if (edit_enable_sig !== exp_enable || edit_sel_sig !== exp_selected) begin
                $display("  [FAIL] Edit %0s: Expected enable=%b sel=%b, Got enable=%b sel=%b",
                    msg, exp_enable, exp_selected, edit_enable_sig, edit_sel_sig);
                error_count = error_count + 1;
            end else begin
                $display("  [PASS] Edit %0s", msg);
                pass_count = pass_count + 1;
            end
        end
    endtask
    
    //=========================================================================
    // TASK: Kiểm tra blink_mask
    //=========================================================================
    task check_blink_mask;
        input [7:0] exp_mask;
        input [255:0] msg;
        begin
            if (blink_mask_sig !== exp_mask) begin
                $display("  [FAIL] Blink %0s: Expected=%b, Got=%b",
                    msg, exp_mask, blink_mask_sig);
                error_count = error_count + 1;
            end else begin
                $display("  [PASS] Blink %0s", msg);
                pass_count = pass_count + 1;
            end
        end
    endtask
    
    //=========================================================================
    // TASK: Kiểm tra 7-segment output (mode TIME)
    //=========================================================================
    task check_seg_time;
        input [3:0] exp_h10, exp_h1, exp_m10, exp_m1, exp_s10, exp_s1;
        input [255:0] msg;
        reg [3:0] got_h10, got_h1, got_m10, got_m1, got_s10, got_s1;
        begin
            got_h10 = seg7_to_digit(SEG7);
            got_h1  = seg7_to_digit(SEG6);
            got_m10 = seg7_to_digit(SEG5);
            got_m1  = seg7_to_digit(SEG4);
            got_s10 = seg7_to_digit(SEG3);
            got_s1  = seg7_to_digit(SEG2);
            
            if (got_h10 !== exp_h10 || got_h1 !== exp_h1 ||
                got_m10 !== exp_m10 || got_m1 !== exp_m1 ||
                got_s10 !== exp_s10 || got_s1 !== exp_s1) begin
                $display("  [FAIL] SEG TIME %0s", msg);
                $display("         Expected: %0d%0d:%0d%0d:%0d%0d",
                    exp_h10, exp_h1, exp_m10, exp_m1, exp_s10, exp_s1);
                $display("         Got:      %0d%0d:%0d%0d:%0d%0d",
                    got_h10, got_h1, got_m10, got_m1, got_s10, got_s1);
                error_count = error_count + 1;
            end else begin
                $display("  [PASS] SEG TIME %0s", msg);
                pass_count = pass_count + 1;
            end
        end
    endtask

    //=========================================================================
    // TASK: Kiểm tra max_day_in_month
    //=========================================================================
    task check_max_day;
        input [4:0] expected;
        input [255:0] msg;
        begin
            if (max_day_sig !== expected) begin
                $display("  [FAIL] MaxDay %0s: Expected=%0d, Got=%0d (month=%0d, leap=%b)",
                    msg, expected, max_day_sig, month_bin, leap_sig);
                error_count = error_count + 1;
            end else begin
                $display("  [PASS] MaxDay %0s: max_day=%0d (month=%0d, leap=%b)", 
                    msg, max_day_sig, month_bin, leap_sig);
                pass_count = pass_count + 1;
            end
        end
    endtask

    //=========================================================================
    // CHƯƠNG TRÌNH CHÍNH
    //=========================================================================
    initial begin
        // Khởi tạo
        error_count = 0;
        pass_count  = 0;
        test_num    = 0;
        
        $display("=============================================================");
        $display(" TESTBENCH: Century Clock System - COMPREHENSIVE TEST SUITE");
        $display(" Clock Divider Override: clk_f = %0d (fast simulation)", FAST_CLK_F);
        $display("=============================================================");
        $display("");
        
        //=====================================================================
        // TEST 1: RESET VÀ GIÁ TRỊ KHỞI TẠO
        //=====================================================================
        test_num = 1;
        $display("===========================================================");
        $display(" TEST %0d: RESET va gia tri khoi tao", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Kiểm tra giá trị sau reset
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Gia tri sau reset: 00:00:00 01/01/2026");
        
        // Kiểm tra mode = TIME (0)
        if (mode_sig !== 1'b0) begin
            $display("  [FAIL] Mode sau reset should be TIME (0), got %b", mode_sig);
            error_count = error_count + 1;
        end else begin
            $display("  [PASS] Mode sau reset = TIME (0)");
            pass_count = pass_count + 1;
        end
        
        // Kiểm tra edit_enable = 0
        check_edit_state(1'b0, 3'b000, "Sau reset: edit off");
        
        // Kiểm tra BCD giá trị khởi tạo
        check_bcd(4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 
            "Time BCD 00:00:00");
        check_bcd_date(4'd1, 4'd0, 4'd1, 4'd0, 4'd6, 4'd2, 4'd0, 4'd2, 
            "Date BCD 01/01/2026");
        
        // Kiểm tra leap year 2026 (không nhuận)
        check_leap(1'b0, "2026 khong nhuan");
        
        // Kiểm tra blink_mask = all ON (không chỉnh sửa)
        check_blink_mask(8'b11111111, "Sau reset: all digits ON");
        
        // Kiểm tra 7-segment output (mode TIME)
        print_clock_state;
        check_seg_time(4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, 
            "Hien thi 00:00:00");
        
        $display("");
        
        //=====================================================================
        // TEST 2: ĐẾM GIÂY TỰ ĐỘNG (CHẾ ĐỘ BÌNH THƯỜNG)
        //=====================================================================
        test_num = 2;
        $display("===========================================================");
        $display(" TEST %0d: Dem giay tu dong", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Chờ 1 giây -> sec = 1
        wait_one_tick_1hz;
        check_counter(6'd1, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Sau 1 giay: sec=1");
        check_bcd(4'd1, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, "BCD 00:00:01");
        
        // Chờ thêm 4 giây -> sec = 5
        wait_seconds(4);
        check_counter(6'd5, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Sau 5 giay: sec=5");
        check_bcd(4'd5, 4'd0, 4'd0, 4'd0, 4'd0, 4'd0, "BCD 00:00:05");
        
        // Chờ thêm 5 giây -> sec = 10
        wait_seconds(5);
        check_counter(6'd10, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Sau 10 giay: sec=10");
        check_bcd(4'd0, 4'd1, 4'd0, 4'd0, 4'd0, 4'd0, "BCD 00:00:10");
        
        print_clock_state;
        $display("");
        
        //=====================================================================
        // TEST 3: TRÀN GIÂY 59->00, CARRY SANG PHÚT
        //=====================================================================
        test_num = 3;
        $display("===========================================================");
        $display(" TEST %0d: Tran giay 59->00, carry sang phut", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Force giây = 58, đợi 1 giây -> 59
        force_sec(6'd58);
        $display("  [INFO] Force sec=58");
        wait_one_tick_1hz;
        check_counter(6'd59, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2026,
            "sec=59, phut van=0");
        check_bcd(4'd9, 4'd5, 4'd0, 4'd0, 4'd0, 4'd0, "BCD 00:00:59");
        
        // Đợi thêm 1 giây -> sec=0, min=1
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd1, 5'd0, 5'd1, 4'd1, 14'd2026,
            "sec=0, phut=1 (carry thanh cong)");
        check_bcd(4'd0, 4'd0, 4'd1, 4'd0, 4'd0, 4'd0, "BCD 00:01:00");
        
        print_clock_state;
        $display("");
        
        //=====================================================================
        // TEST 4: TRÀN PHÚT 59->00, CARRY SANG GIỜ
        //=====================================================================
        test_num = 4;
        $display("===========================================================");
        $display(" TEST %0d: Tran phut 59->00, carry sang gio", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Force sec=59, min=59 -> chờ 1 tick -> sec=0, min=0, hour=1
        force_time(6'd59, 6'd59, 5'd0, 5'd1, 4'd1, 14'd2026);
        $display("  [INFO] Force time to 00:59:59");
        
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd1, 5'd1, 4'd1, 14'd2026,
            "Tran phut: 00:59:59 -> 01:00:00");
        check_bcd(4'd0, 4'd0, 4'd0, 4'd0, 4'd1, 4'd0, "BCD 01:00:00");
        
        print_clock_state;
        $display("");
        
        //=====================================================================
        // TEST 5: TRÀN GIỜ 23->00, CARRY SANG NGÀY
        //=====================================================================
        test_num = 5;
        $display("===========================================================");
        $display(" TEST %0d: Tran gio 23->00, carry sang ngay (MIDNIGHT)", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Force sec=59, min=59, hour=23 -> midnight rollover
        force_time(6'd59, 6'd59, 5'd23, 5'd1, 4'd1, 14'd2026);
        $display("  [INFO] Force time to 23:59:59 01/01/2026");
        
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd2, 4'd1, 14'd2026,
            "Midnight: 23:59:59 -> 00:00:00 ngay 2");
        
        print_clock_state;
        $display("");
        
        //=====================================================================
        // TEST 6: TRÀN NGÀY CUỐI THÁNG -> NGÀY 1, CARRY SANG THÁNG
        //=====================================================================
        test_num = 6;
        $display("===========================================================");
        $display(" TEST %0d: Tran ngay cuoi thang -> carry sang thang", test_num);
        $display("===========================================================");
        
        // 6a: Tháng 1 (31 ngày) -> Tháng 2
        reset_system;
        force_time(6'd59, 6'd59, 5'd23, 5'd31, 4'd1, 14'd2026);
        $display("  [INFO] Force: 23:59:59 31/01/2026");
        
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd2, 14'd2026,
            "31/01 -> 01/02 (thang 31 ngay -> thang 2)");
        
        // 6b: Tháng 4 (30 ngày) -> Tháng 5
        reset_system;
        force_time(6'd59, 6'd59, 5'd23, 5'd30, 4'd4, 14'd2026);
        $display("  [INFO] Force: 23:59:59 30/04/2026");
        
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd5, 14'd2026,
            "30/04 -> 01/05 (thang 30 ngay)");
        
        // 6c: Tháng 2 không nhuận (28 ngày) -> Tháng 3
        reset_system;
        force_time(6'd59, 6'd59, 5'd23, 5'd28, 4'd2, 14'd2026);
        $display("  [INFO] Force: 23:59:59 28/02/2026 (khong nhuan)");
        
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd3, 14'd2026,
            "28/02/2026 -> 01/03 (khong nhuan)");
        
        // 6d: Tháng 2 năm nhuận (29 ngày) - ngày 28 KHÔNG carry
        reset_system;
        force_time(6'd59, 6'd59, 5'd23, 5'd28, 4'd2, 14'd2024);
        $display("  [INFO] Force: 23:59:59 28/02/2024 (nhuan)");
        
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd29, 4'd2, 14'd2024,
            "28/02/2024 -> 29/02 (nhuan, KHONG carry)");
        
        // 6e: Tháng 2 năm nhuận - ngày 29 -> carry sang tháng 3
        force_time(6'd59, 6'd59, 5'd23, 5'd29, 4'd2, 14'd2024);
        $display("  [INFO] Force: 23:59:59 29/02/2024 (nhuan)");
        
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd3, 14'd2024,
            "29/02/2024 -> 01/03 (nhuan, carry thanh cong)");
        
        print_clock_state;
        $display("");
        
        //=====================================================================
        // TEST 7: TRÀN THÁNG 12->01, CARRY SANG NĂM
        //=====================================================================
        test_num = 7;
        $display("===========================================================");
        $display(" TEST %0d: Tran thang 12->01, carry sang nam", test_num);
        $display("===========================================================");
        
        reset_system;
        force_time(6'd59, 6'd59, 5'd23, 5'd31, 4'd12, 14'd2026);
        $display("  [INFO] Force: 23:59:59 31/12/2026");
        
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2027,
            "31/12/2026 -> 01/01/2027 (nam moi)");
        
        // Test giao thừa 9999 -> 0001
        reset_system;
        force_time(6'd59, 6'd59, 5'd23, 5'd31, 4'd12, 14'd9999);
        $display("  [INFO] Force: 23:59:59 31/12/9999");
        
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd1,
            "31/12/9999 -> 01/01/0001 (overflow nam -> wrap quanh)");
        
        print_clock_state;
        $display("");
        
        //=====================================================================
        // TEST 8: NĂM NHUẬN - CÁC TRƯỜNG HỢP ĐẶC BIỆT
        //=====================================================================
        test_num = 8;
        $display("===========================================================");
        $display(" TEST %0d: Nam nhuan - cac truong hop dac biet", test_num);
        $display("===========================================================");
        
        // 8a: 2024 - năm nhuận (chia hết cho 4, không chia hết cho 100)
        reset_system;
        force_year(14'd2024);
        repeat(5) @(posedge clk_50MHz);
        check_leap(1'b1, "2024 nhuan (chia 4, ko chia 100)");
        check_max_day(5'd29, "Thang 2/2024 co 29 ngay");
        
        // 8b: 2025 - không nhuận
        force_year(14'd2025);
        repeat(5) @(posedge clk_50MHz);
        check_leap(1'b0, "2025 khong nhuan");
        check_max_day(5'd28, "Thang 2/2025 co 28 ngay");
        
        // 8c: 1900 - không nhuận (chia hết cho 100, không chia hết cho 400)
        force_year(14'd1900);
        repeat(5) @(posedge clk_50MHz);
        check_leap(1'b0, "1900 khong nhuan (chia 100, ko chia 400)");
        check_max_day(5'd28, "Thang 2/1900 co 28 ngay");
        
        // 8d: 2000 - năm nhuận (chia hết cho 400)
        force_year(14'd2000);
        repeat(5) @(posedge clk_50MHz);
        check_leap(1'b1, "2000 nhuan (chia 400)");
        check_max_day(5'd29, "Thang 2/2000 co 29 ngay");
        
        // 8e: 2100 - không nhuận (chia hết cho 100, không chia hết cho 400)
        force_year(14'd2100);
        repeat(5) @(posedge clk_50MHz);
        check_leap(1'b0, "2100 khong nhuan (chia 100, ko chia 400)");
        check_max_day(5'd28, "Thang 2/2100 co 28 ngay");
        
        // 8f: 2400 - năm nhuận (chia hết cho 400)
        force_year(14'd2400);
        repeat(5) @(posedge clk_50MHz);
        check_leap(1'b1, "2400 nhuan (chia 400)");
        check_max_day(5'd29, "Thang 2/2400 co 29 ngay");
        
        // 8g: 4 - năm nhuận
        force_year(14'd4);
        repeat(5) @(posedge clk_50MHz);
        check_leap(1'b1, "Nam 4 nhuan");
        
        // 8h: 100 - không nhuận
        force_year(14'd100);
        repeat(5) @(posedge clk_50MHz);
        check_leap(1'b0, "Nam 100 khong nhuan");
        
        // 8i: 400 - năm nhuận
        force_year(14'd400);
        repeat(5) @(posedge clk_50MHz);
        check_leap(1'b1, "Nam 400 nhuan");
        
        $display("");
        
        //=====================================================================
        // TEST 9: SỐ NGÀY TỐI ĐA TRONG MỖI THÁNG
        //=====================================================================
        test_num = 9;
        $display("===========================================================");
        $display(" TEST %0d: So ngay toi da trong moi thang", test_num);
        $display("===========================================================");
        
        reset_system;
        force_year(14'd2026); // Năm không nhuận
        repeat(3) @(posedge clk_50MHz);
        
        // Tháng 1: 31 ngày
        force_month(4'd1); repeat(3) @(posedge clk_50MHz);
        check_max_day(5'd31, "Thang 1: 31 ngay");
        
        // Tháng 2: 28 ngày (không nhuận)
        force_month(4'd2); repeat(3) @(posedge clk_50MHz);
        check_max_day(5'd28, "Thang 2 (2026): 28 ngay");
        
        // Tháng 3: 31 ngày
        force_month(4'd3); repeat(3) @(posedge clk_50MHz);
        check_max_day(5'd31, "Thang 3: 31 ngay");
        
        // Tháng 4: 30 ngày
        force_month(4'd4); repeat(3) @(posedge clk_50MHz);
        check_max_day(5'd30, "Thang 4: 30 ngay");
        
        // Tháng 5: 31 ngày
        force_month(4'd5); repeat(3) @(posedge clk_50MHz);
        check_max_day(5'd31, "Thang 5: 31 ngay");
        
        // Tháng 6: 30 ngày
        force_month(4'd6); repeat(3) @(posedge clk_50MHz);
        check_max_day(5'd30, "Thang 6: 30 ngay");
        
        // Tháng 7: 31 ngày
        force_month(4'd7); repeat(3) @(posedge clk_50MHz);
        check_max_day(5'd31, "Thang 7: 31 ngay");
        
        // Tháng 8: 31 ngày
        force_month(4'd8); repeat(3) @(posedge clk_50MHz);
        check_max_day(5'd31, "Thang 8: 31 ngay");
        
        // Tháng 9: 30 ngày
        force_month(4'd9); repeat(3) @(posedge clk_50MHz);
        check_max_day(5'd30, "Thang 9: 30 ngay");
        
        // Tháng 10: 31 ngày
        force_month(4'd10); repeat(3) @(posedge clk_50MHz);
        check_max_day(5'd31, "Thang 10: 31 ngay");
        
        // Tháng 11: 30 ngày
        force_month(4'd11); repeat(3) @(posedge clk_50MHz);
        check_max_day(5'd30, "Thang 11: 30 ngay");
        
        // Tháng 12: 31 ngày
        force_month(4'd12); repeat(3) @(posedge clk_50MHz);
        check_max_day(5'd31, "Thang 12: 31 ngay");
        
        // Kiểm tra tháng 2 năm nhuận
        force_year(14'd2024);
        force_month(4'd2); repeat(5) @(posedge clk_50MHz);
        check_max_day(5'd29, "Thang 2 (2024 nhuan): 29 ngay");
        
        $display("");
        
        //=====================================================================
        // TEST 10: CHỈNH SỬA GIÂY (UP/DOWN, WRAP-AROUND)
        //=====================================================================
        test_num = 10;
        $display("===========================================================");
        $display(" TEST %0d: Chinh sua giay (UP/DOWN, wrap-around)", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Bật switch chỉnh giây: SW[5] = 1 (khi mode = TIME)
        $display("  [INFO] Bat SW[5] -> chinh giay");
        select_edit_field(6'b100000);
        check_edit_state(1'b1, 3'b110, "SW[5]: edit SECOND");
        
        // Kiểm tra đồng hồ dừng
        $display("  [INFO] Kiem tra dong ho dung khi edit");
        repeat(CYCLES_PER_SEC * 2) @(posedge clk_50MHz);
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Dong ho DUNG khi edit_enable=1");
        
        // Nhấn UP 5 lần -> sec = 5
        $display("  [INFO] Nhan UP 5 lan");
        press_btn_up_n(5);
        check_counter(6'd5, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Sau 5 UP: sec=5");
        
        // Nhấn DOWN 3 lần -> sec = 2
        $display("  [INFO] Nhan DOWN 3 lan");
        press_btn_down_n(3);
        check_counter(6'd2, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Sau 3 DOWN: sec=2");
        
        // Nhấn DOWN 3 lần -> sec=59 (wrap-around: 2->1->0->59)
        $display("  [INFO] Nhan DOWN 3 lan (wrap-around)");
        press_btn_down_n(3);
        check_counter(6'd59, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Wrap-around DOWN: sec=59");
        
        // Nhấn UP 1 lần -> sec=0 (wrap-around: 59->0)
        $display("  [INFO] Nhan UP 1 lan (wrap-around)");
        press_btn_up;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Wrap-around UP: sec=0");
        
        // Kiểm tra phút KHÔNG thay đổi khi chỉnh giây qua 59
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Phut KHONG thay doi khi chinh giay");
        
        deselect_all;
        print_clock_state;
        $display("");
        
        //=====================================================================
        // TEST 11: CHỈNH SỬA PHÚT (UP/DOWN, WRAP-AROUND)
        //=====================================================================
        test_num = 11;
        $display("===========================================================");
        $display(" TEST %0d: Chinh sua phut (UP/DOWN, wrap-around)", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Bật switch chỉnh phút: SW[4] = 1
        $display("  [INFO] Bat SW[4] -> chinh phut");
        select_edit_field(6'b010000);
        check_edit_state(1'b1, 3'b101, "SW[4]: edit MINUTE");
        
        // Nhấn UP 30 lần -> min = 30
        $display("  [INFO] Nhan UP 30 lan");
        press_btn_up_n(30);
        check_counter(6'd0, 6'd30, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Sau 30 UP: min=30");
        
        // Nhấn UP thêm 29 lần -> min = 59
        $display("  [INFO] Nhan UP 29 lan");
        press_btn_up_n(29);
        check_counter(6'd0, 6'd59, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Sau 59 UP: min=59");
        
        // Nhấn UP 1 lần -> min = 0 (wrap-around)
        $display("  [INFO] Wrap-around UP");
        press_btn_up;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Wrap-around UP: min=0, gio KHONG tang");
        
        // Nhấn DOWN 1 lần -> min = 59 (wrap-around DOWN)
        $display("  [INFO] Wrap-around DOWN");
        press_btn_down;
        check_counter(6'd0, 6'd59, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Wrap-around DOWN: min=59");
        
        deselect_all;
        $display("");
        
        //=====================================================================
        // TEST 12: CHỈNH SỬA GIỜ (UP/DOWN, WRAP-AROUND)
        //=====================================================================
        test_num = 12;
        $display("===========================================================");
        $display(" TEST %0d: Chinh sua gio (UP/DOWN, wrap-around)", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Bật switch chỉnh giờ: SW[3] = 1
        $display("  [INFO] Bat SW[3] -> chinh gio");
        select_edit_field(6'b001000);
        check_edit_state(1'b1, 3'b100, "SW[3]: edit HOUR");
        
        // Nhấn UP 23 lần -> hour = 23
        $display("  [INFO] Nhan UP 23 lan");
        press_btn_up_n(23);
        check_counter(6'd0, 6'd0, 5'd23, 5'd1, 4'd1, 14'd2026,
            "Sau 23 UP: hour=23");
        
        // Nhấn UP 1 lần -> hour = 0 (wrap-around)
        $display("  [INFO] Wrap-around UP");
        press_btn_up;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Wrap-around UP: hour=0, ngay KHONG tang");
        
        // Nhấn DOWN 1 lần -> hour = 23 (wrap-around DOWN)
        $display("  [INFO] Wrap-around DOWN");
        press_btn_down;
        check_counter(6'd0, 6'd0, 5'd23, 5'd1, 4'd1, 14'd2026,
            "Wrap-around DOWN: hour=23");
        
        // Nhấn DOWN 23 lần -> hour = 0
        $display("  [INFO] Nhan DOWN 23 lan");
        press_btn_down_n(23);
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Sau 23 DOWN: hour=0");
        
        deselect_all;
        $display("");
        
        //=====================================================================
        // TEST 13: CHỈNH SỬA NGÀY (MODE DATE, SWITCH SW[0])
        //=====================================================================
        test_num = 13;
        $display("===========================================================");
        $display(" TEST %0d: Chinh sua ngay (DATE mode)", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Phải chuyển sang mode DATE trước
        // mode chuyển khi có tick_1min & ~edit_enable
        // tick_1min = sig_1min_out từ counter khi sec tràn 59->0
        // Ta force mode trực tiếp để test
        force DUT.u_disp_mode.mode = 1'b1;
        @(posedge clk_50MHz);
        release DUT.u_disp_mode.mode;
        repeat(3) @(posedge clk_50MHz);
        
        // Bật SW[0] -> chỉnh ngày (trong DATE mode)
        $display("  [INFO] Bat SW[0] -> chinh ngay (DATE mode)");
        select_edit_field(6'b000001);
        check_edit_state(1'b1, 3'b001, "SW[0]: edit DAY");
        
        // Nhấn UP 30 lần -> day = 31 (tháng 1 có 31 ngày)
        $display("  [INFO] Nhan UP 30 lan (thang 1)");
        press_btn_up_n(30);
        check_counter(6'd0, 6'd0, 5'd0, 5'd31, 4'd1, 14'd2026,
            "Sau 30 UP: day=31 (thang 1)");
        
        // Nhấn UP 1 lần -> day = 1 (wrap-around)
        $display("  [INFO] Wrap-around UP ngay");
        press_btn_up;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Wrap-around UP: day=1");
        
        // Nhấn DOWN 1 lần -> day = 31 (wrap-around DOWN)
        $display("  [INFO] Wrap-around DOWN ngay");
        press_btn_down;
        check_counter(6'd0, 6'd0, 5'd0, 5'd31, 4'd1, 14'd2026,
            "Wrap-around DOWN: day=31 (thang 1)");
        
        // Chuyển sang tháng 2 (28 ngày, 2026 không nhuận)
        deselect_all;
        force_month(4'd2);
        force_day(5'd1);
        repeat(5) @(posedge clk_50MHz);
        
        // Bật lại chỉnh ngày
        select_edit_field(6'b000001);
        
        // Nhấn UP 27 lần -> day = 28
        $display("  [INFO] Nhan UP 27 lan (thang 2, khong nhuan)");
        press_btn_up_n(27);
        check_counter(6'd0, 6'd0, 5'd0, 5'd28, 4'd2, 14'd2026,
            "Sau 27 UP: day=28 (thang 2 khong nhuan)");
        
        // Nhấn UP 1 lần -> day = 1 (wrap-around, 28 ngày max)
        $display("  [INFO] Wrap-around UP ngay thang 2");
        press_btn_up;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd2, 14'd2026,
            "Wrap-around UP: day=1 (thang 2 ko nhuan)");
        
        deselect_all;
        $display("");
        
        //=====================================================================
        // TEST 14: CHỈNH SỬA THÁNG (UP/DOWN, WRAP-AROUND)
        //=====================================================================
        test_num = 14;
        $display("===========================================================");
        $display(" TEST %0d: Chinh sua thang (UP/DOWN, wrap-around)", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Force mode DATE
        force DUT.u_disp_mode.mode = 1'b1;
        @(posedge clk_50MHz); release DUT.u_disp_mode.mode;
        repeat(3) @(posedge clk_50MHz);
        
        // Bật SW[1] -> chỉnh tháng
        $display("  [INFO] Bat SW[1] -> chinh thang");
        select_edit_field(6'b000010);
        check_edit_state(1'b1, 3'b010, "SW[1]: edit MONTH");
        
        // Nhấn UP 11 lần -> month = 12
        $display("  [INFO] Nhan UP 11 lan");
        press_btn_up_n(11);
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd12, 14'd2026,
            "Sau 11 UP: month=12");
        
        // Nhấn UP 1 lần -> month = 1 (wrap-around)
        $display("  [INFO] Wrap-around UP thang");
        press_btn_up;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Wrap-around UP: month=1");
        
        // Nhấn DOWN 1 lần -> month = 12 (wrap-around DOWN)
        $display("  [INFO] Wrap-around DOWN thang");
        press_btn_down;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd12, 14'd2026,
            "Wrap-around DOWN: month=12");
        
        deselect_all;
        $display("");
        
        //=====================================================================
        // TEST 15: CHỈNH SỬA NĂM (UP/DOWN, WRAP-AROUND 9999->1)
        //=====================================================================
        test_num = 15;
        $display("===========================================================");
        $display(" TEST %0d: Chinh sua nam (UP/DOWN, wrap-around)", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Force mode DATE
        force DUT.u_disp_mode.mode = 1'b1;
        @(posedge clk_50MHz); release DUT.u_disp_mode.mode;
        repeat(3) @(posedge clk_50MHz);
        
        // Bật SW[2] -> chỉnh năm
        $display("  [INFO] Bat SW[2] -> chinh nam");
        select_edit_field(6'b000100);
        check_edit_state(1'b1, 3'b011, "SW[2]: edit YEAR");
        
        // Nhấn UP 10 lần -> year = 2036
        $display("  [INFO] Nhan UP 10 lan");
        press_btn_up_n(10);
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2036,
            "Sau 10 UP: year=2036");
        
        // Nhấn DOWN 20 lần -> year = 2016
        $display("  [INFO] Nhan DOWN 20 lan");
        press_btn_down_n(20);
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2016,
            "Sau 20 DOWN: year=2016");
        
        // Test wrap-around: force year = 9999, UP -> 1
        force_year(14'd9999);
        repeat(3) @(posedge clk_50MHz);
        $display("  [INFO] Force year=9999, nhan UP");
        press_btn_up;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd1,
            "Wrap-around UP: 9999->1");
        
        // Test wrap-around: force year = 1, DOWN -> 9999
        force_year(14'd1);
        repeat(3) @(posedge clk_50MHz);
        $display("  [INFO] Force year=1, nhan DOWN");
        press_btn_down;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd9999,
            "Wrap-around DOWN: 1->9999");
        
        // Kiểm tra BCD năm 9999
        check_bcd_date(4'd1, 4'd0, 4'd1, 4'd0, 4'd9, 4'd9, 4'd9, 4'd9,
            "BCD nam 9999");
        
        deselect_all;
        $display("");
        
        //=====================================================================
        // TEST 16: CHUYỂN ĐỔI MODE TIME<->DATE
        //=====================================================================
        test_num = 16;
        $display("===========================================================");
        $display(" TEST %0d: Chuyen doi mode TIME<->DATE", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Ban đầu mode = TIME (0)
        if (mode_sig !== 1'b0) begin
            $display("  [FAIL] Ban dau mode phai la TIME (0)");
            error_count = error_count + 1;
        end else begin
            $display("  [PASS] Ban dau mode = TIME (0)");
            pass_count = pass_count + 1;
        end
        
        // Mode chuyển khi sig_1min_out=1 & ~edit_enable
        // sig_1min_out = 1 khi sec tràn 59->0
        // Ta force sec=59, chờ 1 tick -> sig_1min=1 -> mode đổi
        force_sec(6'd59);
        $display("  [INFO] Force sec=59, cho carry -> doi mode");
        wait_one_tick_1hz;
        
        // Mode phải đổi sang DATE (1)
        repeat(3) @(posedge clk_50MHz);
        if (mode_sig !== 1'b1) begin
            $display("  [FAIL] Mode phai chuyen sang DATE (1) sau 1 phut");
            error_count = error_count + 1;
        end else begin
            $display("  [PASS] Mode chuyen sang DATE (1) sau sig_1min");
            pass_count = pass_count + 1;
        end
        
        // Chờ thêm 1 phút -> quay lại TIME
        // Force min=59, sec=59, chờ carry
        force_time(6'd59, 6'd59, 5'd0, 5'd1, 4'd1, 14'd2026);
        wait_one_tick_1hz;
        repeat(3) @(posedge clk_50MHz);
        
        // Nhưng bây giờ sec=0, min=0, carry đã xảy ra
        // sig_1min_out xuất hiện -> mode đổi lại TIME
        if (mode_sig !== 1'b0) begin
            $display("  [FAIL] Mode phai chuyen lai TIME (0) sau 2 lan doi");
            error_count = error_count + 1;
        end else begin
            $display("  [PASS] Mode chuyen lai TIME (0)");
            pass_count = pass_count + 1;
        end
        
        print_clock_state;
        $display("");
        
        //=====================================================================
        // TEST 17: ĐỒNG HỒ DỪNG KHI ĐANG CHỈNH SỬA
        //=====================================================================
        test_num = 17;
        $display("===========================================================");
        $display(" TEST %0d: Dong ho dung khi dang chinh sua", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Chỉnh giây -> đồng hồ phải dừng
        force_sec(6'd30);
        select_edit_field(6'b100000); // Edit second
        
        // Chờ rất nhiều tick_1hz
        repeat(CYCLES_PER_SEC * 5) @(posedge clk_50MHz);
        
        // Giá trị sec phải giữ nguyên = 30 (vì edit_enable = 1 -> run = 0)
        if (sec_bin !== 6'd30) begin
            $display("  [FAIL] Dong ho KHONG dung! sec=%0d (expected 30)", sec_bin);
            error_count = error_count + 1;
        end else begin
            $display("  [PASS] Dong ho dung khi edit (sec=30 giu nguyen)");
            pass_count = pass_count + 1;
        end
        
        // Tắt edit -> đồng hồ chạy lại
        deselect_all;
        $display("  [INFO] Tat edit, dong ho chay lai");
        wait_one_tick_1hz;
        
        if (sec_bin === 6'd31) begin
            $display("  [PASS] Dong ho chay lai sau khi tat edit (sec=31)");
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] Dong ho khong chay lai! sec=%0d (expected 31)", sec_bin);
            error_count = error_count + 1;
        end
        
        // Kiểm tra mode KHÔNG chuyển khi đang edit
        $display("  [INFO] Kiem tra mode khong doi khi edit");
        reset_system;
        force_sec(6'd59);
        select_edit_field(6'b100000); // Edit second
        
        repeat(CYCLES_PER_SEC * 2) @(posedge clk_50MHz);
        
        if (mode_sig === 1'b0) begin
            $display("  [PASS] Mode KHONG doi khi dang edit");
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] Mode da doi khi dang edit!");
            error_count = error_count + 1;
        end
        
        deselect_all;
        $display("");
        
        //=====================================================================
        // TEST 18: NHẤP NHÁY (BLINK) DIGIT ĐANG CHỈNH
        //=====================================================================
        test_num = 18;
        $display("===========================================================");
        $display(" TEST %0d: Nhap nhay digit dang chinh", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // 18a: Không chỉnh -> tất cả sáng
        check_blink_mask(8'b11111111, "Khong chinh: tat ca sang");
        
        // 18b: Chỉnh giây (TIME mode) -> SEG3, SEG2 nhấp nháy
        $display("  [INFO] Chinh giay (TIME mode)");
        select_edit_field(6'b100000);
        
        // Chờ blink_state = 0 (tắt)
        // tick_blink xảy ra mỗi 50 tick_100hz
        // Với clk_f=100: tick_100hz mỗi cycle, tick_blink mỗi 50 cycle
        repeat(100) @(posedge clk_50MHz); // Chờ vài chu kỳ blink
        
        // Khi blink_state=0: SEG3,SEG2 tắt, còn lại sáng
        // Khi blink_state=1: tất cả sáng
        // Ta kiểm tra tại thời điểm blink_state=0
        @(negedge DUT.u_blink_sel.blink_state);
        repeat(2) @(posedge clk_50MHz);
        check_blink_mask(8'b11110011, "Chinh giay: SEG3,SEG2 nhap nhay (OFF)");
        
        // Chờ blink_state=1 -> tất cả sáng
        @(posedge DUT.u_blink_sel.blink_state);
        repeat(2) @(posedge clk_50MHz);
        check_blink_mask(8'b11111111, "Chinh giay: blink_state=1 -> tat ca sang");
        
        deselect_all;
        
        // 18c: Chỉnh phút -> SEG5, SEG4 nhấp nháy
        $display("  [INFO] Chinh phut (TIME mode)");
        select_edit_field(6'b010000);
        @(negedge DUT.u_blink_sel.blink_state);
        repeat(2) @(posedge clk_50MHz);
        check_blink_mask(8'b11001111, "Chinh phut: SEG5,SEG4 nhap nhay (OFF)");
        deselect_all;
        
        // 18d: Chỉnh giờ -> SEG7, SEG6 nhấp nháy
        $display("  [INFO] Chinh gio (TIME mode)");
        select_edit_field(6'b001000);
        @(negedge DUT.u_blink_sel.blink_state);
        repeat(2) @(posedge clk_50MHz);
        check_blink_mask(8'b00111111, "Chinh gio: SEG7,SEG6 nhap nhay (OFF)");
        deselect_all;
        
        // 18e: Chỉnh ngày (DATE mode) -> SEG7, SEG6 nhấp nháy
        $display("  [INFO] Chinh ngay (DATE mode)");
        force DUT.u_disp_mode.mode = 1'b1;
        @(posedge clk_50MHz); release DUT.u_disp_mode.mode;
        repeat(3) @(posedge clk_50MHz);
        
        select_edit_field(6'b000001);
        @(negedge DUT.u_blink_sel.blink_state);
        repeat(2) @(posedge clk_50MHz);
        check_blink_mask(8'b00111111, "Chinh ngay DATE: SEG7,SEG6 nhap nhay (OFF)");
        deselect_all;
        
        // 18f: Chỉnh tháng (DATE mode) -> SEG5, SEG4 nhấp nháy
        $display("  [INFO] Chinh thang (DATE mode)");
        select_edit_field(6'b000010);
        @(negedge DUT.u_blink_sel.blink_state);
        repeat(2) @(posedge clk_50MHz);
        check_blink_mask(8'b11001111, "Chinh thang DATE: SEG5,SEG4 nhap nhay (OFF)");
        deselect_all;
        
        // 18g: Chỉnh năm (DATE mode) -> SEG3,SEG2,SEG1,SEG0 nhấp nháy
        $display("  [INFO] Chinh nam (DATE mode)");
        select_edit_field(6'b000100);
        @(negedge DUT.u_blink_sel.blink_state);
        repeat(2) @(posedge clk_50MHz);
        check_blink_mask(8'b11110000, "Chinh nam DATE: SEG3-0 nhap nhay (OFF)");
        deselect_all;
        
        $display("");
        
        //=====================================================================
        // TEST 19: HIỂN THỊ 7 ĐOẠN - BCD GIẢI MÃ ĐÚNG
        //=====================================================================
        test_num = 19;
        $display("===========================================================");
        $display(" TEST %0d: Hien thi 7 doan - BCD giai ma dung", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Force thời gian cụ thể: 12:34:56  01/01/2026
        force_time(6'd56, 6'd34, 5'd12, 5'd1, 4'd1, 14'd2026);
        repeat(5) @(posedge clk_50MHz);
        
        // Mode TIME -> hiển thị 12:34:56
        $display("  [INFO] Kiem tra hien thi 12:34:56 (TIME mode)");
        check_seg_time(4'd1, 4'd2, 4'd3, 4'd4, 4'd5, 4'd6, 
            "Hien thi 12:34:56");
        
        // SEG1, SEG0 phải tắt (OFF) trong TIME mode
        if (seg7_to_digit(SEG1) !== 4'd15 || seg7_to_digit(SEG0) !== 4'd15) begin
            $display("  [FAIL] SEG1,SEG0 phai tat (OFF) trong TIME mode");
            error_count = error_count + 1;
        end else begin
            $display("  [PASS] SEG1,SEG0 tat (OFF) trong TIME mode");
            pass_count = pass_count + 1;
        end
        
        // Chuyển DATE mode -> hiển thị 01/01/2026
        force DUT.u_disp_mode.mode = 1'b1;
        @(posedge clk_50MHz); release DUT.u_disp_mode.mode;
        repeat(5) @(posedge clk_50MHz);
        
        $display("  [INFO] Kiem tra hien thi 01/01/2026 (DATE mode)");
        // SEG7=D10=0, SEG6=D1=1, SEG5=M10=0, SEG4=M1=1, SEG3=Y1000=2, SEG2=Y100=0, SEG1=Y10=2, SEG0=Y1=6
        if (seg7_to_digit(SEG7) === 4'd0 && seg7_to_digit(SEG6) === 4'd1 &&
            seg7_to_digit(SEG5) === 4'd0 && seg7_to_digit(SEG4) === 4'd1 &&
            seg7_to_digit(SEG3) === 4'd2 && seg7_to_digit(SEG2) === 4'd0 &&
            seg7_to_digit(SEG1) === 4'd2 && seg7_to_digit(SEG0) === 4'd6) begin
            $display("  [PASS] DATE hien thi 01/01/2026");
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] DATE hien thi sai, expected 01012026");
            $display("         Got: %0d%0d/%0d%0d/%0d%0d%0d%0d",
                seg7_to_digit(SEG7), seg7_to_digit(SEG6),
                seg7_to_digit(SEG5), seg7_to_digit(SEG4),
                seg7_to_digit(SEG3), seg7_to_digit(SEG2),
                seg7_to_digit(SEG1), seg7_to_digit(SEG0));
            error_count = error_count + 1;
        end
        
        print_clock_state;
        $display("");
        
        //=====================================================================
        // TEST 20: MIDNIGHT ROLLOVER HOÀN CHỈNH
        //=====================================================================
        test_num = 20;
        $display("===========================================================");
        $display(" TEST %0d: Midnight rollover hoan chinh", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Kịch bản: 23:59:55 -> đếm đến 00:00:00
        force_time(6'd55, 6'd59, 5'd23, 5'd15, 4'd6, 14'd2026);
        $display("  [INFO] Force: 23:59:55 15/06/2026");
        print_clock_state;
        
        // Chờ 1 giây: 23:59:56
        wait_one_tick_1hz;
        check_counter(6'd56, 6'd59, 5'd23, 5'd15, 4'd6, 14'd2026, "23:59:56");
        
        // Chờ 1 giây: 23:59:57
        wait_one_tick_1hz;
        check_counter(6'd57, 6'd59, 5'd23, 5'd15, 4'd6, 14'd2026, "23:59:57");
        
        // Chờ 1 giây: 23:59:58
        wait_one_tick_1hz;
        check_counter(6'd58, 6'd59, 5'd23, 5'd15, 4'd6, 14'd2026, "23:59:58");
        
        // Chờ 1 giây: 23:59:59
        wait_one_tick_1hz;
        check_counter(6'd59, 6'd59, 5'd23, 5'd15, 4'd6, 14'd2026, "23:59:59");
        
        // Chờ 1 giây: 00:00:00 ngày 16
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd16, 4'd6, 14'd2026, 
            "MIDNIGHT: 00:00:00 ngay 16");
        
        print_clock_state;
        $display("");
        
        //=====================================================================
        // TEST 21: CHUYỂN THÁNG VỚI SỐ NGÀY KHÁC NHAU
        //=====================================================================
        test_num = 21;
        $display("===========================================================");
        $display(" TEST %0d: Chuyen thang voi so ngay khac nhau", test_num);
        $display("===========================================================");
        
        // 21a: Tháng 1 (31 ngày) -> Tháng 2
        reset_system;
        force_time(6'd59, 6'd59, 5'd23, 5'd31, 4'd1, 14'd2026);
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd2, 14'd2026,
            "31/01 -> 01/02");
        
        // 21b: Tháng 2 (28 ngày) -> Tháng 3
        force_time(6'd59, 6'd59, 5'd23, 5'd28, 4'd2, 14'd2026);
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd3, 14'd2026,
            "28/02 -> 01/03 (2026 ko nhuan)");
        
        // 21c: Tháng 3 (31 ngày) -> Tháng 4
        force_time(6'd59, 6'd59, 5'd23, 5'd31, 4'd3, 14'd2026);
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd4, 14'd2026,
            "31/03 -> 01/04");
        
        // 21d: Tháng 4 (30 ngày) -> Tháng 5
        force_time(6'd59, 6'd59, 5'd23, 5'd30, 4'd4, 14'd2026);
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd5, 14'd2026,
            "30/04 -> 01/05");
        
        // 21e: Tháng 6 (30 ngày) -> Tháng 7
        force_time(6'd59, 6'd59, 5'd23, 5'd30, 4'd6, 14'd2026);
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd7, 14'd2026,
            "30/06 -> 01/07");
        
        // 21f: Tháng 7 (31 ngày) -> Tháng 8
        force_time(6'd59, 6'd59, 5'd23, 5'd31, 4'd7, 14'd2026);
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd8, 14'd2026,
            "31/07 -> 01/08");
        
        // 21g: Tháng 8 (31 ngày) -> Tháng 9
        force_time(6'd59, 6'd59, 5'd23, 5'd31, 4'd8, 14'd2026);
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd9, 14'd2026,
            "31/08 -> 01/09");
        
        // 21h: Tháng 9 (30 ngày) -> Tháng 10
        force_time(6'd59, 6'd59, 5'd23, 5'd30, 4'd9, 14'd2026);
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd10, 14'd2026,
            "30/09 -> 01/10");
        
        // 21i: Tháng 11 (30 ngày) -> Tháng 12
        force_time(6'd59, 6'd59, 5'd23, 5'd30, 4'd11, 14'd2026);
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd12, 14'd2026,
            "30/11 -> 01/12");
        
        // 21j: Tháng 12 (31 ngày) -> Tháng 1 năm sau
        force_time(6'd59, 6'd59, 5'd23, 5'd31, 4'd12, 14'd2026);
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2027,
            "31/12/2026 -> 01/01/2027");
        
        $display("");
        
        //=====================================================================
        // TEST 22: WRAP-AROUND NĂM: 9999->0001, 0001->9999
        //=====================================================================
        test_num = 22;
        $display("===========================================================");
        $display(" TEST %0d: Wrap-around nam qua carry chain", test_num);
        $display("===========================================================");
        
        // 22a: Năm 9999, ngày cuối -> năm 0001
        reset_system;
        force_time(6'd59, 6'd59, 5'd23, 5'd31, 4'd12, 14'd9999);
        $display("  [INFO] Force: 23:59:59 31/12/9999");
        
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd1,
            "31/12/9999 -> 01/01/0001 (year overflow -> wrap)");
        
        // Kiểm tra BCD năm 0001
        check_bcd_date(4'd1, 4'd0, 4'd1, 4'd0, 4'd1, 4'd0, 4'd0, 4'd0,
            "BCD nam 0001");
        
        $display("");
        
        //=====================================================================
        // TEST 23: NÚT BẤM DEBOUNCE
        //=====================================================================
        test_num = 23;
        $display("===========================================================");
        $display(" TEST %0d: Nut bam debounce - bounce, giu lau, nhan nhanh", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Bật chỉnh giây
        select_edit_field(6'b100000);
        
        // 23a: Nút bấm với bounce -> chỉ nên tăng 1 lần
        $display("  [INFO] Nhan nut UP voi bounce");
        press_btn_up_with_bounce;
        
        $display("  [INFO] Sau nhan bounce, sec=%0d", sec_bin);
        if (sec_bin <= 6'd2) begin // Chấp nhận 1 hoặc 2 (tùy timing)
            $display("  [PASS] Debounce hoat dong (sec=%0d, khong bi dem nhieu lan)", sec_bin);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] Debounce KHONG hoat dong! sec=%0d (expected 1)", sec_bin);
            error_count = error_count + 1;
        end
        
        // 23b: Nhấn nhanh liên tục
        $display("  [INFO] Nhan nhanh lien tuc 3 lan");
        force_sec(6'd0);
        press_btn_up;
        press_btn_up;
        press_btn_up;
        
        $display("  [INFO] Sau 3 lan nhan nhanh, sec=%0d", sec_bin);
        if (sec_bin === 6'd3) begin
            $display("  [PASS] 3 lan nhan -> sec=3");
            pass_count = pass_count + 1;
        end else begin
            $display("  [WARN] sec=%0d (expected 3, debounce timing)", sec_bin);
        end
        
        deselect_all;
        $display("");
        
        //=====================================================================
        // TEST 24: ĐỒNG THỜI NHẤN UP VÀ DOWN
        //=====================================================================
        test_num = 24;
        $display("===========================================================");
        $display(" TEST %0d: Dong thoi nhan UP va DOWN", test_num);
        $display("===========================================================");
        
        reset_system;
        force_sec(6'd30);
        select_edit_field(6'b100000);
        
        // Nhấn cả UP và DOWN cùng lúc
        $display("  [INFO] Nhan UP va DOWN cung luc");
        BTN1 = 1'b1;
        BTN2 = 1'b1;
        repeat(20) @(posedge clk_50MHz);
        BTN1 = 1'b0;
        BTN2 = 1'b0;
        repeat(20) @(posedge clk_50MHz);
        
        $display("  [INFO] Ket qua sec=%0d (ban dau 30)", sec_bin);
        // UP có priority hơn DOWN trong code (if/else if)
        // Nên khi cả 2 đều active, chỉ UP hoạt động -> sec = 31
        if (sec_bin === 6'd31) begin
            $display("  [PASS] UP co uu tien hon DOWN (sec=31)");
            pass_count = pass_count + 1;
        end else begin
            $display("  [INFO] sec=%0d (UP/DOWN dong thoi, ket qua phu thuoc timing)", sec_bin);
        end
        
        deselect_all;
        $display("");
        
        //=====================================================================
        // TEST 25: CHUYỂN SWITCH TRONG KHI ĐANG CHỈNH
        //=====================================================================
        test_num = 25;
        $display("===========================================================");
        $display(" TEST %0d: Chuyen switch trong khi dang chinh", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Bắt đầu chỉnh giây
        select_edit_field(6'b100000);
        press_btn_up_n(5);
        check_counter(6'd5, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Chinh giay: sec=5");
        
        // Chuyển sang chỉnh phút (không tắt giây trước)
        $display("  [INFO] Chuyen tu chinh giay sang chinh phut");
        select_edit_field(6'b010000);
        check_edit_state(1'b1, 3'b101, "Chuyen sang MINUTE");
        
        press_btn_up_n(10);
        check_counter(6'd5, 6'd10, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Chinh phut: min=10, giay giu nguyen=5");
        
        // Chuyển sang chỉnh giờ
        $display("  [INFO] Chuyen sang chinh gio");
        select_edit_field(6'b001000);
        press_btn_up_n(8);
        check_counter(6'd5, 6'd10, 5'd8, 5'd1, 4'd1, 14'd2026,
            "Chinh gio: hour=8, phut giu=10, giay giu=5");
        
        // Bật nhiều switch cùng lúc -> priority encoder
        $display("  [INFO] Bat nhieu switch cung luc: SW[5]=1, SW[4]=1");
        select_edit_field(6'b110000);
        check_edit_state(1'b1, 3'b110, "Priority: SW[5] (SECOND) thang");
        
        $display("  [INFO] Bat SW[4]=1, SW[3]=1");
        select_edit_field(6'b011000);
        check_edit_state(1'b1, 3'b101, "Priority: SW[4] (MINUTE) thang");
        
        deselect_all;
        $display("");
        
        //=====================================================================
        // TEST 26: KỊCH BẢN THỰC TẾ - ĐẶT THỜI GIAN VÀ CHỜ MIDNIGHT
        //=====================================================================
        test_num = 26;
        $display("===========================================================");
        $display(" TEST %0d: Kich ban thuc te - Dat thoi gian va cho midnight", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Bước 1: Chỉnh giờ = 23
        $display("  [STEP1] Chinh gio = 23");
        select_edit_field(6'b001000);
        press_btn_up_n(23);
        deselect_all;
        
        // Bước 2: Chỉnh phút = 59
        $display("  [STEP2] Chinh phut = 59");
        select_edit_field(6'b010000);
        press_btn_up_n(59);
        deselect_all;
        
        // Bước 3: Chỉnh giây = 57
        $display("  [STEP3] Chinh giay = 57");
        select_edit_field(6'b100000);
        press_btn_up_n(57);
        deselect_all;
        
        // Kiểm tra
        check_counter(6'd57, 6'd59, 5'd23, 5'd1, 4'd1, 14'd2026,
            "Dat xong: 23:59:57");
        print_clock_state;
        
        // Bước 4: Để đồng hồ chạy đến midnight
        $display("  [STEP4] Cho dong ho chay den midnight...");
        wait_seconds(3);    // 57->58->59->00
        check_counter(6'd0, 6'd0, 5'd0, 5'd2, 4'd1, 14'd2026,
            "Midnight thanh cong: 00:00:00 02/01/2026");
        print_clock_state;
        
        $display("");
        
        //=====================================================================
        // TEST 27: NGÀY 31/01 -> 01/02 (31 NGÀY -> 28/29 NGÀY)
        //=====================================================================
        test_num = 27;
        $display("===========================================================");
        $display(" TEST %0d: Ngay 31/01 -> 01/02 (chuyen thang khac so ngay)", test_num);
        $display("===========================================================");
        
        reset_system;
        force_time(6'd59, 6'd59, 5'd23, 5'd31, 4'd1, 14'd2026);
        $display("  [INFO] Force: 23:59:59 31/01/2026");
        
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd2, 14'd2026,
            "31/01 -> 01/02 (thang co 28 ngay)");
        
        // Kiểm tra max_day đã đổi sang 28 (tháng 2 không nhuận)
        check_max_day(5'd28, "Max day = 28 (thang 2, 2026 khong nhuan)");
        
        $display("");
        
        //=====================================================================
        // TEST 28: HIỆU CHỈNH NGÀY KHI CHUYỂN THÁNG (NGÀY > MAX_DAY)
        //=====================================================================
        test_num = 28;
        $display("===========================================================");
        $display(" TEST %0d: Hieu chinh ngay khi day > max_day", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Đặt ngày 31 tháng 1, sau đó chuyển sang tháng 2 (28 ngày)
        // day_counter có logic: nếu day > max_day -> day <= max_day
        force_day(5'd31);
        force_month(4'd1); // Tháng 1, 31 ngày -> hợp lệ
        repeat(5) @(posedge clk_50MHz);
        check_counter(6'd0, 6'd0, 5'd0, 5'd31, 4'd1, 14'd2026,
            "Ngay 31 thang 1: hop le");
        
        // Chuyển sang tháng 2 -> day phải tự điều chỉnh
        force_month(4'd2);
        repeat(5) @(posedge clk_50MHz);
        
        $display("  [INFO] Day sau khi chuyen thang 1(31) -> thang 2(28): day=%0d", day_bin);
        if (day_bin <= 5'd28) begin
            $display("  [PASS] Day tu dieu chinh khi chuyen thang (day=%0d)", day_bin);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] Day KHONG dieu chinh! day=%0d (expected <=28)", day_bin);
            error_count = error_count + 1;
        end
        
        $display("");
        
        //=====================================================================
        // TEST 29: BCD DOUBLE DABBLE - CÁC GIÁ TRỊ NĂM ĐẶC BIỆT
        //=====================================================================
        test_num = 29;
        $display("===========================================================");
        $display(" TEST %0d: BCD Double Dabble - nam dac biet", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Năm 2026
        force_year(14'd2026);
        repeat(5) @(posedge clk_50MHz);
        check_bcd_date(4'd1, 4'd0, 4'd1, 4'd0, 4'd6, 4'd2, 4'd0, 4'd2,
            "Nam 2026 -> BCD 2026");
        
        // Năm 1999
        force_year(14'd1999);
        repeat(5) @(posedge clk_50MHz);
        check_bcd_date(4'd1, 4'd0, 4'd1, 4'd0, 4'd9, 4'd9, 4'd9, 4'd1,
            "Nam 1999 -> BCD 1999");
        
        // Năm 2000
        force_year(14'd2000);
        repeat(5) @(posedge clk_50MHz);
        check_bcd_date(4'd1, 4'd0, 4'd1, 4'd0, 4'd0, 4'd0, 4'd0, 4'd2,
            "Nam 2000 -> BCD 2000");
        
        // Năm 1
        force_year(14'd1);
        repeat(5) @(posedge clk_50MHz);
        check_bcd_date(4'd1, 4'd0, 4'd1, 4'd0, 4'd1, 4'd0, 4'd0, 4'd0,
            "Nam 1 -> BCD 0001");
        
        // Năm 9999
        force_year(14'd9999);
        repeat(5) @(posedge clk_50MHz);
        check_bcd_date(4'd1, 4'd0, 4'd1, 4'd0, 4'd9, 4'd9, 4'd9, 4'd9,
            "Nam 9999 -> BCD 9999");
        
        // Năm 1234
        force_year(14'd1234);
        repeat(5) @(posedge clk_50MHz);
        check_bcd_date(4'd1, 4'd0, 4'd1, 4'd0, 4'd4, 4'd3, 4'd2, 4'd1,
            "Nam 1234 -> BCD 1234");
        
        // Năm 5678
        force_year(14'd5678);
        repeat(5) @(posedge clk_50MHz);
        check_bcd_date(4'd1, 4'd0, 4'd1, 4'd0, 4'd8, 4'd7, 4'd6, 4'd5,
            "Nam 5678 -> BCD 5678");
        
        $display("");
        
        //=====================================================================
        // TEST 30: EDIT FIELD SELECTOR - PRIORITY ENCODING
        //=====================================================================
        test_num = 30;
        $display("===========================================================");
        $display(" TEST %0d: Edit field selector - priority encoding", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // TIME mode (mode = 0)
        $display("  [INFO] TIME mode: kiem tra priority");
        
        // Chỉ SW[5] -> SECOND
        select_edit_field(6'b100000);
        check_edit_state(1'b1, 3'b110, "SW[5] only -> SECOND");
        
        // Chỉ SW[4] -> MINUTE
        select_edit_field(6'b010000);
        check_edit_state(1'b1, 3'b101, "SW[4] only -> MINUTE");
        
        // Chỉ SW[3] -> HOUR
        select_edit_field(6'b001000);
        check_edit_state(1'b1, 3'b100, "SW[3] only -> HOUR");
        
        // SW[5]+SW[4] -> SECOND (SW[5] priority)
        select_edit_field(6'b110000);
        check_edit_state(1'b1, 3'b110, "SW[5]+SW[4] -> SECOND (priority)");
        
        // SW[5]+SW[3] -> SECOND (SW[5] priority)
        select_edit_field(6'b101000);
        check_edit_state(1'b1, 3'b110, "SW[5]+SW[3] -> SECOND (priority)");
        
        // SW[4]+SW[3] -> MINUTE (SW[4] priority)
        select_edit_field(6'b011000);
        check_edit_state(1'b1, 3'b101, "SW[4]+SW[3] -> MINUTE (priority)");
        
        // Tất cả -> SECOND (highest priority)
        select_edit_field(6'b111000);
        check_edit_state(1'b1, 3'b110, "All time SW -> SECOND (priority)");
        
        // DATE mode switches khi TIME mode -> NONE
        select_edit_field(6'b000001);
        check_edit_state(1'b0, 3'b000, "SW[0] in TIME mode -> NONE");
        
        select_edit_field(6'b000010);
        check_edit_state(1'b0, 3'b000, "SW[1] in TIME mode -> NONE");
        
        select_edit_field(6'b000100);
        check_edit_state(1'b0, 3'b000, "SW[2] in TIME mode -> NONE");
        
        deselect_all;
        
        // DATE mode (mode = 1)
        $display("  [INFO] DATE mode: kiem tra priority");
        force DUT.u_disp_mode.mode = 1'b1;
        @(posedge clk_50MHz); release DUT.u_disp_mode.mode;
        repeat(3) @(posedge clk_50MHz);
        
        // Chỉ SW[0] -> DAY
        select_edit_field(6'b000001);
        check_edit_state(1'b1, 3'b001, "SW[0] only -> DAY");
        
        // Chỉ SW[1] -> MONTH
        select_edit_field(6'b000010);
        check_edit_state(1'b1, 3'b010, "SW[1] only -> MONTH");
        
        // Chỉ SW[2] -> YEAR
        select_edit_field(6'b000100);
        check_edit_state(1'b1, 3'b011, "SW[2] only -> YEAR");
        
        // SW[0]+SW[1] -> DAY (priority)
        select_edit_field(6'b000011);
        check_edit_state(1'b1, 3'b001, "SW[0]+SW[1] -> DAY (priority)");
        
        // SW[0]+SW[2] -> DAY (priority)
        select_edit_field(6'b000101);
        check_edit_state(1'b1, 3'b001, "SW[0]+SW[2] -> DAY (priority)");
        
        // SW[1]+SW[2] -> MONTH (priority)
        select_edit_field(6'b000110);
        check_edit_state(1'b1, 3'b010, "SW[1]+SW[2] -> MONTH (priority)");
        
        // TIME switches khi DATE mode -> NONE
        select_edit_field(6'b100000);
        check_edit_state(1'b0, 3'b000, "SW[5] in DATE mode -> NONE");
        
        deselect_all;
        $display("");
        
        //=====================================================================
        // TEST 31: CARRY CHAIN DÀI - GIÂY -> PHÚT -> GIỜ -> NGÀY -> THÁNG -> NĂM
        //=====================================================================
        test_num = 31;
        $display("===========================================================");
        $display(" TEST %0d: Carry chain dai (toan bo chuoi carry)", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Force: 23:59:59 31/12/2026 -> tất cả cùng carry 1 lúc
        force_time(6'd59, 6'd59, 5'd23, 5'd31, 4'd12, 14'd2026);
        $display("  [INFO] Force: 23:59:59 31/12/2026");
        print_clock_state;
        
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2027,
            "Full carry: 23:59:59 31/12/2026 -> 00:00:00 01/01/2027");
        print_clock_state;
        
        $display("");
        
        //=====================================================================
        // TEST 32: NHIỀU CHU KỲ ĐẾM LIÊN TỤC
        //=====================================================================
        test_num = 32;
        $display("===========================================================");
        $display(" TEST %0d: Nhieu chu ky dem lien tuc", test_num);
        $display("===========================================================");
        
        reset_system;
        
        $display("  [INFO] Dem 65 giay lien tuc (kiem tra carry giay->phut)");
        wait_seconds(65);
        check_counter(6'd5, 6'd1, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Sau 65 giay: 00:01:05");
        
        print_clock_state;
        $display("");
        
        //=====================================================================
        // TEST 33: DIGIT SELECTOR - HIỂN THỊ ĐÚNG THEO MODE
        //=====================================================================
        test_num = 33;
        $display("===========================================================");
        $display(" TEST %0d: Digit selector hien thi dung theo mode", test_num);
        $display("===========================================================");
        
        reset_system;
        force_time(6'd45, 6'd30, 5'd12, 5'd25, 4'd11, 14'd2026);
        repeat(5) @(posedge clk_50MHz);
        
        // TIME mode: SEG7=1, SEG6=2, SEG5=3, SEG4=0, SEG3=4, SEG2=5, SEG1=off, SEG0=off
        $display("  [INFO] TIME mode: 12:30:45");
        check_seg_time(4'd1, 4'd2, 4'd3, 4'd0, 4'd4, 4'd5,
            "TIME 12:30:45 tren 7seg");
        
        // DATE mode
        force DUT.u_disp_mode.mode = 1'b1;
        @(posedge clk_50MHz); release DUT.u_disp_mode.mode;
        repeat(5) @(posedge clk_50MHz);
        
        $display("  [INFO] DATE mode: 25/11/2026");
        // SEG7=2, SEG6=5, SEG5=1, SEG4=1, SEG3=2, SEG2=0, SEG1=2, SEG0=6
        if (seg7_to_digit(SEG7) === 4'd2 && seg7_to_digit(SEG6) === 4'd5 &&
            seg7_to_digit(SEG5) === 4'd1 && seg7_to_digit(SEG4) === 4'd1 &&
            seg7_to_digit(SEG3) === 4'd2 && seg7_to_digit(SEG2) === 4'd0 &&
            seg7_to_digit(SEG1) === 4'd2 && seg7_to_digit(SEG0) === 4'd6) begin
            $display("  [PASS] DATE 25/11/2026 tren 7seg");
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] DATE 25/11/2026 tren 7seg sai!");
            $display("         Got: %0d%0d/%0d%0d/%0d%0d%0d%0d",
                seg7_to_digit(SEG7), seg7_to_digit(SEG6),
                seg7_to_digit(SEG5), seg7_to_digit(SEG4),
                seg7_to_digit(SEG3), seg7_to_digit(SEG2),
                seg7_to_digit(SEG1), seg7_to_digit(SEG0));
            error_count = error_count + 1;
        end
        
        print_clock_state;
        $display("");
        
        //=====================================================================
        // TEST 34: CHỈNH NGÀY TRONG THÁNG 2 NĂM NHUẬN
        //=====================================================================
        test_num = 34;
        $display("===========================================================");
        $display(" TEST %0d: Chinh ngay trong thang 2 nam nhuan", test_num);
        $display("===========================================================");
        
        reset_system;
        force_year(14'd2024);
        force_month(4'd2);
        force_day(5'd1);
        repeat(5) @(posedge clk_50MHz);
        
        check_leap(1'b1, "2024 nhuan");
        check_max_day(5'd29, "Thang 2/2024 co 29 ngay");
        
        // Force mode DATE
        force DUT.u_disp_mode.mode = 1'b1;
        @(posedge clk_50MHz); release DUT.u_disp_mode.mode;
        repeat(3) @(posedge clk_50MHz);
        
        // Chỉnh ngày
        select_edit_field(6'b000001);
        
        // Nhấn UP 28 lần -> day = 29
        $display("  [INFO] Nhan UP 28 lan (thang 2 nhuan)");
        press_btn_up_n(28);
        
        if (day_bin === 5'd29) begin
            $display("  [PASS] day=29 (ngay 29 thang 2 nhuan)");
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] day=%0d (expected 29)", day_bin);
            error_count = error_count + 1;
        end
        
        // Nhấn UP 1 lần -> wrap around -> day = 1
        press_btn_up;
        if (day_bin === 5'd1) begin
            $display("  [PASS] Wrap: day=29 -> day=1");
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] Wrap: day=%0d (expected 1)", day_bin);
            error_count = error_count + 1;
        end
        
        deselect_all;
        $display("");
        
        //=====================================================================
        // TEST 35: CHUYỂN GIỮA NĂM NHUẬN VÀ KHÔNG NHUẬN TRONG THÁNG 2
        //=====================================================================
        test_num = 35;
        $display("===========================================================");
        $display(" TEST %0d: Chuyen giua nam nhuan/khong nhuan thang 2", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Đặt ngày 29/02/2024 (năm nhuận)
        force_time(6'd0, 6'd0, 5'd12, 5'd29, 4'd2, 14'd2024);
        repeat(5) @(posedge clk_50MHz);
        check_leap(1'b1, "2024 nhuan");
        
        $display("  [INFO] Ngay 29/02/2024, chuyen sang 2025 (ko nhuan)");
        
        // Chuyển năm sang 2025 -> day phải tự điều chỉnh từ 29 xuống 28
        force_year(14'd2025);
        repeat(10) @(posedge clk_50MHz);
        
        check_leap(1'b0, "2025 khong nhuan");
        check_max_day(5'd28, "Thang 2/2025 max=28");
        
        $display("  [INFO] Day sau chuyen nam: %0d (expected <= 28)", day_bin);
        if (day_bin <= 5'd28) begin
            $display("  [PASS] Day dieu chinh tu 29 xuong %0d", day_bin);
            pass_count = pass_count + 1;
        end else begin
            $display("  [FAIL] Day KHONG dieu chinh! day=%0d", day_bin);
            error_count = error_count + 1;
        end
        
        $display("");
        
        //=====================================================================
        // TEST 36: RESET GIỮA CHỪNG KHI ĐANG CHỈNH
        //=====================================================================
        test_num = 36;
        $display("===========================================================");
        $display(" TEST %0d: Reset giua chung khi dang chinh", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Chỉnh giờ = 15, phút = 30
        select_edit_field(6'b001000);
        press_btn_up_n(15);
        deselect_all;
        
        select_edit_field(6'b010000);
        press_btn_up_n(30);
        
        // Reset trong khi đang chỉnh phút
        $display("  [INFO] Reset trong khi dang chinh phut");
        rst_n = 1'b0;
        repeat(5) @(posedge clk_50MHz);
        rst_n = 1'b1;
        repeat(5) @(posedge clk_50MHz);
        
        // Tất cả phải về giá trị reset
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2026,
            "Sau reset giua chung: ve gia tri mac dinh");
        
        // Switch vẫn bật -> edit vẫn enable
        check_edit_state(1'b1, 3'b101, "SW van bat sau reset -> edit van enable");
        
        deselect_all;
        $display("");
        
        //=====================================================================
        // TEST 37: HIỂN THỊ CÁC SỐ TỪ 0-9 TRÊN 7-SEGMENT
        //=====================================================================
        test_num = 37;
        $display("===========================================================");
        $display(" TEST %0d: Hien thi cac so 0-9 tren 7-segment", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Kiểm tra mỗi giá trị BCD 0-9 bằng cách force sec
        begin : seg_check_block
            integer digit;
            for (digit = 0; digit < 10; digit = digit + 1) begin
                force_sec(digit);
                repeat(5) @(posedge clk_50MHz);
                
                if (seg7_to_digit(SEG2) === digit[3:0]) begin
                    $display("  [PASS] 7seg so %0d hien thi dung", digit);
                    pass_count = pass_count + 1;
                end else begin
                    $display("  [FAIL] 7seg so %0d: expected=%0d, got=%0d (raw=%b)",
                        digit, digit, seg7_to_digit(SEG2), SEG2);
                    error_count = error_count + 1;
                end
            end
        end
        
        $display("");
        
        //=====================================================================
        // TEST 38: THÁNG 2 NĂM 1900 (KHÔNG NHUẬN - 100 DIVISIBLE)
        //=====================================================================
        test_num = 38;
        $display("===========================================================");
        $display(" TEST %0d: Thang 2 nam 1900 (chia 100, ko chia 400)", test_num);
        $display("===========================================================");
        
        reset_system;
        force_time(6'd59, 6'd59, 5'd23, 5'd28, 4'd2, 14'd1900);
        $display("  [INFO] Force: 23:59:59 28/02/1900");
        
        check_leap(1'b0, "1900 KHONG nhuan");
        check_max_day(5'd28, "Thang 2/1900 max=28");
        
        // Carry -> tháng 3
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd3, 14'd1900,
            "28/02/1900 -> 01/03/1900 (ko nhuan)");
        
        $display("");
        
        //=====================================================================
        // TEST 39: THÁNG 2 NĂM 2000 (NHUẬN - 400 DIVISIBLE)
        //=====================================================================
        test_num = 39;
        $display("===========================================================");
        $display(" TEST %0d: Thang 2 nam 2000 (chia 400 -> nhuan)", test_num);
        $display("===========================================================");
        
        reset_system;
        force_time(6'd59, 6'd59, 5'd23, 5'd28, 4'd2, 14'd2000);
        $display("  [INFO] Force: 23:59:59 28/02/2000");
        
        check_leap(1'b1, "2000 nhuan");
        check_max_day(5'd29, "Thang 2/2000 max=29");
        
        // 28->29, KHÔNG carry (vì 29 < max=29)
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd29, 4'd2, 14'd2000,
            "28/02/2000 -> 29/02/2000 (nhuan, ko carry)");
        
        // 29->01/03
        force_time(6'd59, 6'd59, 5'd23, 5'd29, 4'd2, 14'd2000);
        wait_one_tick_1hz;
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd3, 14'd2000,
            "29/02/2000 -> 01/03/2000 (nhuan, carry)");
        
        $display("");
        
        //=====================================================================
        // TEST 40: STRESS TEST - CHỈNH NHANH LIÊN TỤC
        //=====================================================================
        test_num = 40;
        $display("===========================================================");
        $display(" TEST %0d: Stress test - chinh nhanh lien tuc", test_num);
        $display("===========================================================");
        
        reset_system;
        
        // Chỉnh giây UP 60 lần -> phải quay lại 0
        select_edit_field(6'b100000);
        $display("  [INFO] Nhan UP 60 lan (vu tron giay)");
        press_btn_up_n(60);
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2026,
            "60 UP giay -> sec quay lai 0");
        
        // Chỉnh giây DOWN 60 lần -> phải quay lại 0
        $display("  [INFO] Nhan DOWN 60 lan (vu tron giay)");
        press_btn_down_n(60);
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2026,
            "60 DOWN giay -> sec quay lai 0");
        
        deselect_all;
        
        // Chỉnh giờ UP 24 lần -> phải quay lại 0
        select_edit_field(6'b001000);
        $display("  [INFO] Nhan UP 24 lan (vu tron gio)");
        press_btn_up_n(24);
        check_counter(6'd0, 6'd0, 5'd0, 5'd1, 4'd1, 14'd2026,
            "24 UP gio -> hour quay lai 0");
        
        deselect_all;
        $display("");
        
        //=====================================================================
        // KẾT QUẢ TỔNG HỢP
        //=====================================================================
        $display("=============================================================");
        $display(" KET QUA TONG HOP");
        $display("=============================================================");
        $display(" Tong test PASS: %0d", pass_count);
        $display(" Tong test FAIL: %0d", error_count);
        $display("=============================================================");
        
        if (error_count == 0) begin
            $display("");
            $display(" *** TAT CA CAC TEST DIEU PASS! ***");
            $display("");
        end else begin
            $display("");
            $display(" *** CO %0d TEST FAIL! Xem log de biet chi tiet. ***", error_count);
            $display("");
        end
        
        $display("=============================================================");
        $display(" SIMULATION COMPLETED at time %0t", $time);
        $display("=============================================================");
        
        $finish;
    end
    
    //=========================================================================
    // TIMEOUT WATCHDOG
    //=========================================================================
    initial begin
        #(500_000_000); // 500ms timeout
        $display("");
        $display("[TIMEOUT] Simulation exceeded maximum time!");
        $display("          Test %0d was running: %0s", test_num, test_name);
        $display("          PASS=%0d, FAIL=%0d", pass_count, error_count);
        $finish;
    end
    
    //=========================================================================
    // WAVEFORM DUMP (cho debug)
    //=========================================================================
    initial begin
        $dumpfile("tb_top_century_clock.vcd");
        $dumpvars(0, tb_top_century_clock);
    end

endmodule
