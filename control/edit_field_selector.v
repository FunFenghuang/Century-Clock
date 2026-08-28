module edit_field_selector (
    input  wire       mode,            // 0: TIME, 1: DATE
    input  wire [5:0] sw,              // sw[5]:sec, sw[4]:min, sw[3]:hour, sw[2]:year, sw[1]:month, sw[0]:day
    output reg  [2:0] edit_selected,
    output wire edit_enable
);

    // Field encoding
    localparam FIELD_NONE   = 3'b000;
    localparam FIELD_DAY    = 3'b001;
    localparam FIELD_MONTH  = 3'b010;
    localparam FIELD_YEAR   = 3'b011;
    localparam FIELD_HOUR   = 3'b100;
    localparam FIELD_MINUTE = 3'b101;
    localparam FIELD_SECOND = 3'b110;

    // Priority encoder: selects the highest-priority active switch
    // mode = 0 -> TIME : Second > Minute > Hour
    // mode = 1 -> DATE : Day > Month > Year
  
always @(*) begin
        edit_selected = FIELD_NONE;
        
        if (mode == 1'b0) begin // TIME mode
            if      (sw[5]) edit_selected = FIELD_SECOND;
            else if (sw[4]) edit_selected = FIELD_MINUTE;
            else if (sw[3]) edit_selected = FIELD_HOUR;
        end 
        else begin              // DATE mode
            if      (sw[0]) edit_selected = FIELD_DAY;
            else if (sw[1]) edit_selected = FIELD_MONTH;
            else if (sw[2]) edit_selected = FIELD_YEAR;
        end
    end
    assign edit_enable = (edit_selected != FIELD_NONE);

endmodule