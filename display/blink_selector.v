// Blink selector: generates a blink mask for the currently edited field
// When a field is being edited, its corresponding digits blink (on/off at 2Hz)
// When no field is being edited, all digits are displayed normally

module blink_selector (
    input  wire       clk_50MHz,
    input  wire       rst_n,
    input  wire       tick_blink,      // 2Hz tick for blink toggling
    input  wire       mode,            // 0: TIME, 1: DATE
    input  wire [2:0] edit_selected,   // Currently selected edit field
    output reg  [7:0] blink_mask       // Mask for 8 digits (1=on, 0=off)
);

    // Field encoding - matches edit_field_selector
    localparam FIELD_NONE   = 3'b000;
    localparam FIELD_DAY    = 3'b001;
    localparam FIELD_MONTH  = 3'b010;
    localparam FIELD_YEAR   = 3'b011;
    localparam FIELD_HOUR   = 3'b100;
    localparam FIELD_MINUTE = 3'b101;
    localparam FIELD_SECOND = 3'b110;

    // Blink state: toggles on each tick_blink event
    reg blink_state;

    always @(posedge clk_50MHz or negedge rst_n) begin
        if (!rst_n) begin
            blink_state <= 1'b1;
        end
        else begin
            if (tick_blink) begin
                blink_state <= ~blink_state;
            end
        end
    end

    // Generate blink mask based on the currently edited field
    // Digit positions on the 7-segment LED array:
    //   TIME mode: SEG7=H10, SEG6=H1, SEG5=M10, SEG4=M1, SEG3=S10, SEG2=S1, SEG1=off, SEG0=off
    //   DATE mode: SEG7=D10, SEG6=D1, SEG5=M10, SEG4=M1, SEG3=Y1000, SEG2=Y100, SEG1=Y10, SEG0=Y1
    always @(*) begin
        blink_mask = 8'b11111111;       // Default: all digits on

        if (edit_selected != FIELD_NONE && blink_state == 1'b0) begin
            case (edit_selected )
                // TIME mode fields - only blink when mode = 0 (TIME)
                FIELD_SECOND: begin
                    if (mode == 1'b0) begin
                        blink_mask[3] = 1'b0;   // SEG3 (S10) blinks
                        blink_mask[2] = 1'b0;   // SEG2 (S1)  blinks
                    end
                end
                FIELD_MINUTE: begin
                    if (mode == 1'b0) begin
                        blink_mask[5] = 1'b0;   // SEG5 (M10) blinks
                        blink_mask[4] = 1'b0;   // SEG4 (M1)  blinks
                    end
                end
                FIELD_HOUR: begin
                    if (mode == 1'b0) begin
                        blink_mask[7] = 1'b0;   // SEG7 (H10) blinks
                        blink_mask[6] = 1'b0;   // SEG6 (H1)  blinks
                    end
                end

                // DATE mode fields - only blink when mode = 1 (DATE)
                FIELD_DAY: begin
                    if (mode == 1'b1) begin
                        blink_mask[7] = 1'b0;   // SEG7 (D10) blinks
                        blink_mask[6] = 1'b0;   // SEG6 (D1)  blinks
                    end
                end
                FIELD_MONTH: begin
                    if (mode == 1'b1) begin
                        blink_mask[5] = 1'b0;   // SEG5 (M10) blinks
                        blink_mask[4] = 1'b0;   // SEG4 (M1)  blinks
                    end
                end
                FIELD_YEAR: begin
                    if (mode == 1'b1) begin
                        blink_mask[3] = 1'b0;   // SEG3 (Y1000) blinks
                        blink_mask[2] = 1'b0;   // SEG2 (Y100)  blinks
                        blink_mask[1] = 1'b0;   // SEG1 (Y10)   blinks
                        blink_mask[0] = 1'b0;   // SEG0 (Y1)    blinks
                    end
                end

                default: ;                      // No blinking
            endcase
        end
    end

endmodule
