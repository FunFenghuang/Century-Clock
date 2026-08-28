module control_controller (
    input  wire       clk_50MHz, // System clock
    input  wire       rst_n,     // Active-low reset
    
    input  wire       BTN1,      // Increment (UP) button
    input  wire       BTN2,      // Decrement (DOWN) button
    input  wire [5:0] SW,        // 6 switches for field selection (SW[5]..SW[0])

    // 7-segment LED display outputs
    output wire [6:0] SEG0,
    output wire [6:0] SEG1,
    output wire [6:0] SEG2,
    output wire [6:0] SEG3,
    output wire [6:0] SEG4,
    output wire [6:0] SEG5,
    output wire [6:0] SEG6,
    output wire [6:0] SEG7
);


    // 1. CLOCK DIVIDER - Generates base timing ticks
    wire tick_100hz;
    wire tick_1hz;
    wire tick_blink;
    wire edit_enable;

    clock_divider u_clk_div (
        .clk         (clk_50MHz),
        .rst_n       (rst_n),
        .edit_enable (edit_enable),
        .tick_100hz  (tick_100hz),
        .tick_1hz    (tick_1hz),
        .tick_blink  (tick_blink)
    );

    // 2. DISPLAY MODE MANAGER - Toggles between TIME and DATE every minute
  
    wire mode;
    wire sig_1min_out;

    display_mode_manager u_disp_mode (
        .clk_50MHz   (clk_50MHz),
        .rst_n       (rst_n),
        .tick_1min   (sig_1min_out & ~edit_enable),
        .mode(mode) // 1: DATE, 0: TIME
    );

    // 3. EDIT FIELD SELECTOR - Decodes switches into the selected edit field
    wire [2:0] edit_selected;

    edit_field_selector u_field_selector (
        .mode  (mode),
        .sw            (SW),
        .edit_selected(edit_selected),
        .edit_enable (edit_enable)
    );

    // 4. BUTTON HANDLER - Debounces and edge-detects UP/DOWN buttons

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

    // 5. COUNTER CONTROLLER - Central real-time counter logic
	 
    reg        counter_mode;
    reg [1:0]  counter_edit_sel;

    // Map the 3-bit edit_selected field to mode + 2-bit selection for the counter
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
        
        // BCD data outputs
        .sec_ones(sec_ones), .sec_tens(sec_tens),
        .min_ones(min_ones), .min_tens(min_tens),
        .hr_ones(hr_ones),   .hr_tens(hr_tens),
        .day_ones(day_ones), .day_tens(day_tens),
        .mon_ones(mon_ones), .mon_tens(mon_tens),
        .yr_ones(yr_ones),   .yr_tens(yr_tens),
        .yr_hundreds(yr_hundreds), .yr_thousands(yr_thousands),
        .sig_1min_out(sig_1min_out)
    );

    // 6. BLINK SELECTOR - Generates blink mask for the currently edited field

    wire [7:0] blink_mask;

    blink_selector u_blink_sel (
        .clk_50MHz     (clk_50MHz),
        .rst_n         (rst_n),
        .tick_blink    (tick_blink),
        .mode  (mode),
        .edit_selected (edit_selected),   
        .blink_mask    (blink_mask)
    );


    // 7. DISPLAY CONTROLLER - Decodes BCD data to 7-segment outputs

    display_controller u_disp_ctrl (
        .clk_50MHz   (clk_50MHz),
        .rst_n       (rst_n),
        .mode(mode),
        .blink_mask  (blink_mask),
        
        // BCD data from counter block
        .sec_ones(sec_ones), .sec_tens(sec_tens),
        .min_ones(min_ones), .min_tens(min_tens),
        .hr_ones(hr_ones),   .hr_tens(hr_tens),
        .day_ones(day_ones), .day_tens(day_tens),
        .mon_ones(mon_ones), .mon_tens(mon_tens),
        .yr_ones(yr_ones),   .yr_tens(yr_tens),
        .yr_hundreds(yr_hundreds), .yr_thousands(yr_thousands),

        // 7-segment LED outputs
        .SEG0(SEG0), .SEG1(SEG1), .SEG2(SEG2), .SEG3(SEG3),
        .SEG4(SEG4), .SEG5(SEG5), .SEG6(SEG6), .SEG7(SEG7)
    );

endmodule
