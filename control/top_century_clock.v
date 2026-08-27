module control_controller (
    input  wire       clk_50MHz, // Xung nhịp hệ thống 
    input  wire       rst_n,     // Reset tích cực mức thấp
    
    input  wire       BTN1,      // Nút Tăng (UP)
    input  wire       BTN2,      // Nút Giảm (DOWN)
    input  wire [5:0] SW,        // 6 Switch chọn trường (SW[5]..SW[0])

    // Đầu ra hiển thị LED 7 đoạn 
    output wire [6:0] SEG0,
    output wire [6:0] SEG1,
    output wire [6:0] SEG2,
    output wire [6:0] SEG3,
    output wire [6:0] SEG4,
    output wire [6:0] SEG5,
    output wire [6:0] SEG6,
    output wire [6:0] SEG7
);


    // 1. CLOCK DIVIDER (Tạo các nhịp xung cơ bản)
    wire tick_100hz;
    wire tick_1hz;
    wire tick_1min;
    wire tick_blink;
    wire edit_enable;

    clock_divider u_clk_div (
        .clk         (clk_50MHz),
        .rst_n       (rst_n),
        .edit_enable (edit_enable),
        .tick_100hz  (tick_100hz),
        .tick_1hz    (tick_1hz),
        .tick_blink  (tick_blink),
        .tick_1min   (tick_1min)
    );

    // 2. DISPLAY MODE 
  
    wire mode;
    wire sig_1min_out;

    display_mode_manager u_disp_mode (
        .clk_50MHz   (clk_50MHz),
        .rst_n       (rst_n),
        .tick_1min   (sig_1min_out & ~edit_enable),
        .mode(mode) // 1: DATE, 0: TIME
    );

    // 3. EDIT FIELD SELECTOR 
    wire [2:0] edit_selected;

    edit_field_selector u_field_selector (
        .mode  (mode),
        .sw            (SW),             // Truyền thẳng bus 6-bit vào module
        .edit_selected(edit_selected),
        .edit_enable (edit_enable)
    );

    // 4. BUTTON HANDLER 

    wire up_tick;
    wire down_tick;

    btn_handler u_btn_up (
        .clk_50MHz  (clk_50MHz), 
        .tick_100hz (tick_100hz),
        .rst_n      (rst_n),
        .btn_in     (BTN1),
        .btn_edge   (up_tick)
    );

    btn_handler u_btn_down (
        .clk_50MHz  (clk_50MHz),
        .tick_100hz (tick_100hz),
        .rst_n      (rst_n),
        .btn_in     (BTN2),
        .btn_edge   (down_tick)
    );

    // 5. COUNTER CONTROLLER (Trung tâm đếm thời gian thực)
	 
    reg        counter_mode;
    reg [1:0]  counter_edit_sel;

    always @(*) begin
        case (edit_selected)
            3'b110:  begin counter_mode = 1'b0; counter_edit_sel = 2'b01; end // SECOND
            3'b101:  begin counter_mode = 1'b0; counter_edit_sel = 2'b10; end // MINUTE
            3'b100:  begin counter_mode = 1'b0; counter_edit_sel = 2'b11; end // HOUR
            3'b001:  begin counter_mode = 1'b1; counter_edit_sel = 2'b01; end // DAY
            3'b010:  begin counter_mode = 1'b1; counter_edit_sel = 2'b10; end // MONTH
            3'b011:  begin counter_mode = 1'b1; counter_edit_sel = 2'b11; end // YEAR
            default: begin counter_mode = 1'b0; counter_edit_sel = 2'b00; end // NONE
        endcase
    end

    wire [3:0] sec_ones, sec_tens;
    wire [3:0] min_ones, min_tens;
    wire [3:0] hr_ones,  hr_tens;
    wire [3:0] day_ones, day_tens;
    wire [3:0] mon_ones, mon_tens;
    wire [3:0] yr_ones,  yr_tens, yr_hundreds, yr_thousands;

counter_controller u_counter_ctrl (
        .clk_50MHz     (clk_50MHz),
        .rst_n         (rst_n),
        .tick_1hz      (tick_1hz),
        .up            (up_tick),
        .down          (down_tick),
        .mode          (counter_mode),
        .edit_select   (counter_edit_sel),
        .edit_enable   (edit_enable),      
        
        // Xuất dữ liệu BCD 
        .sec_ones(sec_ones), .sec_tens(sec_tens),
        .min_ones(min_ones), .min_tens(min_tens),
        .hr_ones(hr_ones),   .hr_tens(hr_tens),
        .day_ones(day_ones), .day_tens(day_tens),
        .mon_ones(mon_ones), .mon_tens(mon_tens),
        .yr_ones(yr_ones),   .yr_tens(yr_tens),
        .yr_hundreds(yr_hundreds), .yr_thousands(yr_thousands),
        .sig_1min_out(sig_1min_out)
    );
    // 6. BLINK SELECTOR 

    wire [7:0] blink_mask;

    blink_selector u_blink_sel (
        .clk_50MHz     (clk_50MHz),
        .rst_n         (rst_n),
        .tick_blink    (tick_blink),         // Dùng xung 1Hz để chớp nháy (500ms sáng/500ms tắt)
        .mode  (mode),
        .edit_selected (edit_selected),   
        .blink_mask    (blink_mask)
    );


    // 7. DISPLAY CONTROLLER (Giải mã BCD ra 7-Segment)

    display_controller u_disp_ctrl (
        .clk_50MHz   (clk_50MHz),
        .rst_n       (rst_n),
        .mode(mode),
        .blink_mask  (blink_mask),
        
    // Nhận dữ liệu BCD từ khối Đếm
        .sec_ones(sec_ones), .sec_tens(sec_tens),
        .min_ones(min_ones), .min_tens(min_tens),
        .hr_ones(hr_ones),   .hr_tens(hr_tens),
        .day_ones(day_ones), .day_tens(day_tens),
        .mon_ones(mon_ones), .mon_tens(mon_tens),
        .yr_ones(yr_ones),   .yr_tens(yr_tens),
        .yr_hundreds(yr_hundreds), .yr_thousands(yr_thousands),

        // XUất ra khối LED 7seg 
        .SEG0(SEG0), .SEG1(SEG1), .SEG2(SEG2), .SEG3(SEG3),
        .SEG4(SEG4), .SEG5(SEG5), .SEG6(SEG6), .SEG7(SEG7)
    );

endmodule
