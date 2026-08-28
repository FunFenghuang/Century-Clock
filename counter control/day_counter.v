// Day counter: counts days with month-aware max-day logic, outputs BCD digits

module day_counter(
    input clk_50MHz,
    input rst_n,
    input up, down,
    input [3:0] month,          // Current month (binary), used to determine max days
    input leap,                 // Leap year flag from leap_year_detector
    output sig_1m,              // Carry output: pulses high when days roll over
    output reg [3:0] ones, tens // BCD output: tens and ones digits
);

    reg [4:0] max_day_in_month;
    reg [4:0] day;

    // Determine maximum number of days in the current month
    always @(month or leap) begin
        case (month)
            4'd1, 4'd3, 4'd5, 4'd7, 4'd8, 4'd10, 4'd12: begin 
                max_day_in_month = 5'd31;
            end
            4'd4, 4'd6, 4'd9, 4'd11: begin 
                max_day_in_month = 5'd30;
            end
            4'd2: begin 
                if (leap == 1'b1) begin
                    max_day_in_month = 5'd29;
                end
                else begin
                    max_day_in_month = 5'd28;
                end
            end
            default: begin 
                max_day_in_month = 5'd31;
            end
        endcase
    end

    // Carry signal: asserted when incrementing past the last day of the month
    assign sig_1m = (up == 1'b1 && day >= max_day_in_month) ? 1'b1 : 1'b0;

    // Sequential counter logic
    always @(posedge clk_50MHz or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            day <= 5'd1;                        // Day always starts from 1
        end
        else begin 
            // Increment (wraps to 1 after max day)
            if (up == 1'b1) begin 
                if (day >= max_day_in_month) begin
                    day <= 5'd1;
                end
                else begin
                    day <= day + 5'd1;
                end
            end

            // Decrement (wraps to max day from 1)
            else if (down == 1'b1) begin
                if (day == 5'd1) begin
                    day <= max_day_in_month;
                end
                else begin
                     if (day > max_day_in_month) begin
                        day <= max_day_in_month;
                    end
                    else begin
                        day <= day - 5'd1;
                    end
                end
            end

            // Hold: clamp to max_day if month changed and current day exceeds new max
            else begin 
                if (day > max_day_in_month) begin
                    day <= max_day_in_month;
                end
                else begin
                    day <= day;
                end

            end
        end
    end

    // Combinational logic: binary to BCD conversion
    always @(day) begin
        
        if (day < 10) begin 
            tens = 4'd0; 
            ones = day;
        end
        else  if(day < 20) begin
            tens = 4'd1; 
            ones = day - 10;
        end
        else if (day < 30) begin 
            tens = 4'd2;
            ones = day - 20;
        end 
        else begin                              
            tens = 4'd3;
            ones = day - 30;
        end 
    end
endmodule