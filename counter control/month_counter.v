// Month counter: counts months (1-12), outputs BCD digits and carry signal

module month_counter(
    input clk_50MHz,
    input rst_n,
    input up, down,
    output sig_1y,              // Carry output: pulses high when months roll over from 12 to 1
    output reg [3:0] month,     // Binary month value (1-12), 4 bits required
    output reg [3:0] ones, tens // BCD output: tens and ones digits
);

    // Carry signal: asserted when incrementing past December
    assign sig_1y = (up == 1'b1 && month == 4'd12) ? 1'b1 : 1'b0;

    // Sequential counter logic
    always @(posedge clk_50MHz or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            month <= 4'd1;
        end
        else begin 
            // Increment (wraps from 12 to 1)
            if (up == 1'b1) begin 
                if (month == 4'd12) begin
                    month <= 4'd1;
                end
                else begin
                    month <= month + 4'd1;
                end
            end

            // Decrement (wraps from 1 to 12)
            else if (down == 1'b1) begin
                if (month == 4'd1) begin
                    month <= 4'd12;
                end
                else begin
                    month <= month - 4'd1;
                end
            end

            // Hold current value
            else begin 
                month <= month;
            end
        end
    end

    // Combinational logic: binary to BCD conversion
    always @(month) begin
                        
        if (month < 10) begin 
            tens = 4'd0; 
            ones = month;
        end
        else begin 
            tens = 4'd1;
            ones = month - 10;
        end 
    end
endmodule