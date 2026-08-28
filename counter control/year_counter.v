// Year counter: counts years (1-9999), converts to BCD using Double Dabble algorithm

module year_counter(
    input clk_50MHz,
    input rst_n,
    input up, down,
    output reg [3:0] ones, tens, hundreds, thousands,  // Individual BCD digits for display
    output reg [13:0] year                              // Binary year value (max 9999, 14 bits)
);

    // Sequential counter logic
    always @(posedge clk_50MHz or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            year <= 14'd2026;           // Reset to the current year
        end
        else begin 
            // Increment (wraps from 9999 to 1)
            if (up == 1'b1) begin 
                if (year == 14'd9999) begin     
                    year <= 14'd1;
                end
                else begin
                    year <= year + 14'd1;
                end
            end

            // Decrement (wraps from 1 to 9999)
            else if (down == 1'b1) begin
                if (year == 14'd1) begin
                    year <= 14'd9999;
                end
                else begin
                    year <= year - 14'd1;
                end
            end

            // Hold current value
            else begin 
                year <= year;
            end
        end
    end

    // Binary to BCD conversion using Double Dabble algorithm (for large numbers)

    integer i;
    reg [29:0] shift_reg;       // 14 bits for year + 4 BCD digits x 4 bits = 30 bits total
    
    always @(year) begin
        
        // Step 1: Initialize shift register
        shift_reg = 30'd0;
        shift_reg[13:0] = year;
        
        // Step 2: Shift and add-3 correction (14 iterations for 14-bit input)
        for (i = 0; i < 14; i = i + 1) begin
            if (shift_reg[29:26] >= 4'd5) begin 
                shift_reg[29:26] = shift_reg[29:26] + 4'd3; 
            end
            
            if (shift_reg[25:22] >= 4'd5) begin 
                shift_reg[25:22] = shift_reg[25:22] + 4'd3; 
            end
            
            if (shift_reg[21:18] >= 4'd5) begin 
                shift_reg[21:18] = shift_reg[21:18] + 4'd3; 
            end
            
            if (shift_reg[17:14] >= 4'd5) begin 
                shift_reg[17:14] = shift_reg[17:14] + 4'd3; 
            end
            
            shift_reg = shift_reg << 1;
        end
        
        // Step 3: Extract BCD digits from the shift register
        thousands = shift_reg[29:26];
        hundreds  = shift_reg[25:22];
        tens      = shift_reg[21:18];
        ones      = shift_reg[17:14];
    end
endmodule