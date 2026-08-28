// Helper module: converts thousands and hundreds BCD digits
// into a combined 2-digit binary value for divisibility checks

module hundreds_thousands_bin(
    input [3:0] hundreds,
    input [3:0] thousands,
    output [6:0] binary_2digit
);

    assign binary_2digit = (thousands * 4'd10) + hundreds;
endmodule

// Leap year detector: determines if the current year is a leap year
// Rule: divisible by 4 AND (not divisible by 100 OR divisible by 400)

module leap_year_detector(
    input [13:0] year, 
    input [3:0] ones, tens, hundreds, thousands, 
    output leap
);

    wire [6:0] binary_hundreds_thousands;   // Binary value of the upper 2 digits for div-400 check

    hundreds_thousands_bin my_hundreds_thousands_bin(
        .thousands(thousands),
        .hundreds(hundreds),
        .binary_2digit(binary_hundreds_thousands)
    );

    // Divisibility checks using bit-level operations
    wire div4 = year[1:0] == 2'b00;         // Divisible by 4: last 2 binary bits are 0
    wire div100 = ones == 4'd0 && tens == 4'd0;
    wire div400 = (ones == 4'd0 && tens == 4'd0) && (binary_hundreds_thousands[1:0] == 2'b00);

    assign leap = (div4 && !div100) || div400;
endmodule
