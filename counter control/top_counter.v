module counter_controller (
    input clk_50MHz,
    input rst_n,
    input tick_1hz,             // 1Hz tick from clock divider, drives the clock in normal mode
    input edit_enable,          // 1 = a switch is active -> freeze all counters, only the selected field responds to up/down

    /* mode: selects the active counter group. An external block toggles this every minute to switch display.
       mode = 0 -> operating on the TIME group: HOUR : MINUTE : SECOND
       mode = 1 -> operating on the DATE group: DAY : MONTH : YEAR */
    input mode,

    input [1:0] edit_select,    // selects a field within the current group
    input up, down,              // increment/decrement buttons (active when edit_enable = 1)

    // BCD output data for display
    output [3:0] sec_ones, sec_tens,
    output [3:0] min_ones, min_tens,
    output [3:0] hr_ones, hr_tens,
    output [3:0] day_ones, day_tens,
    output [3:0] mon_ones, mon_tens,
    output [3:0] yr_ones, yr_tens, yr_hundreds, yr_thousands,
    output wire sig_1min_out
);

    assign sig_1min_out = sig_1min;

    /* edit_select encoding combined with mode to identify
       exactly 1 of 6 editable fields:
       mode == 0 (TIME group: HOUR:MINUTE:SECOND):
           edit_select = 2'b01 -> SECOND
           edit_select = 2'b10 -> MINUTE
           edit_select = 2'b11 -> HOUR
       mode == 1 (DATE group: DAY:MONTH:YEAR):
           edit_select = 2'b01 -> DAY
           edit_select = 2'b10 -> MONTH
           edit_select = 2'b11 -> YEAR
       edit_select = 2'b00 -> no field selected */

    localparam SEL_1 = 2'b01;
    localparam SEL_2 = 2'b10;
    localparam SEL_3 = 2'b11;

    // Internal carry signals between counter stages
    wire sig_1min, sig_1h, sig_1d, sig_1m, sig_1y;
    wire [3:0] month_bin;   // Binary month value, needed by day_counter for max-day calculation
    wire [13:0] year_bin;   // Binary year value, needed by leap_year_detector
    wire leap;

    // Clock runs normally only when no field is being edited
    wire run = !edit_enable;

    // Route up/down signals to the appropriate counter based on mode and edit_select
    wire sec_up   = edit_enable && !mode && edit_select==SEL_1 && up;
    wire sec_down = edit_enable && !mode && edit_select==SEL_1 && down;

    wire min_up   = edit_enable && !mode && edit_select==SEL_2 && up;
    wire min_down = edit_enable && !mode && edit_select==SEL_2 && down;

    wire hr_up    = edit_enable && !mode && edit_select==SEL_3 && up;
    wire hr_down  = edit_enable && !mode && edit_select==SEL_3 && down;

    wire day_up   = edit_enable &&  mode && edit_select==SEL_1 && up;
    wire day_down = edit_enable &&  mode && edit_select==SEL_1 && down;

    wire mon_up   = edit_enable &&  mode && edit_select==SEL_2 && up;
    wire mon_down = edit_enable &&  mode && edit_select==SEL_2 && down;

    wire yr_up    = edit_enable &&  mode && edit_select==SEL_3 && up;
    wire yr_down  = edit_enable &&  mode && edit_select==SEL_3 && down;

    // Second counter: in run mode increments on 1Hz tick; in edit mode responds to manual up/down
    sec_counter my_sec (
        .clk_50MHz(clk_50MHz),
        .rst_n(rst_n),
        .up (run ? tick_1hz : sec_up),
        .down (sec_down),
        .sig_1min(sig_1min),
        .ones(sec_ones),
        .tens(sec_tens)
    );

    // Minute counter: in run mode increments on carry from seconds
    min_counter my_min (
        .clk_50MHz(clk_50MHz),
        .rst_n(rst_n),
        .up (run ? sig_1min : min_up),
        .down (min_down),
        .sig_1h(sig_1h),
        .ones(min_ones),
        .tens(min_tens)
    );

    // Hour counter: in run mode increments on carry from minutes
    hour_counter my_hr (
        .clk_50MHz(clk_50MHz),
        .rst_n(rst_n),
        .up (run ? sig_1h : hr_up),
        .down (hr_down),
        .sig_1d(sig_1d),
        .ones(hr_ones),
        .tens(hr_tens)
    );

    // Day counter: in run mode increments on carry from hours
    day_counter my_day (
        .clk_50MHz(clk_50MHz),
        .rst_n(rst_n),
        .up (run ? sig_1d : day_up),
        .down (day_down),
        .month(month_bin),
        .leap(leap),
        .sig_1m(sig_1m),
        .ones(day_ones),
        .tens(day_tens)
    );

    // Month counter: in run mode increments on carry from days
    month_counter my_month (
        .clk_50MHz(clk_50MHz),
        .rst_n(rst_n),
        .up (run ? sig_1m : mon_up),
        .down (mon_down),
        .sig_1y(sig_1y),
        .month(month_bin),
        .ones(mon_ones),
        .tens(mon_tens)
    );

    // Year counter: in run mode increments on carry from months
    year_counter my_year (
        .clk_50MHz(clk_50MHz),
        .rst_n(rst_n),
        .up (run ? sig_1y : yr_up),
        .down (yr_down),
        .ones(yr_ones),
        .tens(yr_tens),
        .hundreds(yr_hundreds),
        .thousands(yr_thousands),
        .year(year_bin)
    );

    // Leap year detector: determines if the current year is a leap year
    leap_year_detector my_leap (
        .year(year_bin),
        .ones(yr_ones),
        .tens(yr_tens),
        .hundreds(yr_hundreds),
        .thousands(yr_thousands),
        .leap(leap)
    );

endmodule
