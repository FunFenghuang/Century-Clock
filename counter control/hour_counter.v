// Hour counter: counts hours (0-23), outputs BCD digits and carry signal

module hour_counter(
    input clk_50MHz,
    input rst_n,
    input up, down,
    output sig_1d,              // Carry output: pulses high when hours roll over from 23 to 0
    output reg [3:0] ones, tens // BCD output: tens and ones digits
);

    reg [4:0] hour;             // Binary hour value (0-23), requires 5 bits
    assign sig_1d = (up == 1'b1 && hour == 5'd23) ? 1'b1 : 1'b0;

    // Sequential counter logic
    always @(posedge clk_50MHz or negedge rst_n) begin
        if(rst_n == 1'b0) begin
            hour <= 5'd0;
        end
        else begin 
            // Increment (wraps from 23 to 0)
            if (up == 1'b1) begin 
                if (hour == 5'd23) begin
                    hour <= 5'd0;
                end
                else begin
                    hour <= hour + 5'd1;
                end
            end

            // Decrement (wraps from 0 to 23)
            else if (down == 1'b1) begin
                if (hour == 5'd0) begin
                    hour <= 5'd23;
                end
                else begin
                    hour <= hour - 5'd1;
                end
            end

            // Hold current value
            else begin 
                hour <= hour;
            end
        end
    end

    // Combinational logic: binary to BCD conversion
    always @(hour) begin
                        
        if (hour < 10) begin 
            tens = 4'd0; 
            ones = hour;
        end
        else if (hour < 20) begin
            tens = 4'd1; 
            ones = hour - 10;
        end
        else begin 
            tens = 4'd2;
            ones = hour - 20;
        end 
    end
endmodule