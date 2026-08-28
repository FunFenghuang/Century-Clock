// Second counter: counts seconds (0-59), outputs BCD digits and carry signal

module sec_counter (
    input clk_50MHz, rst_n,     // System clock and active-low reset
    input up,                   // Increment: driven by 1Hz tick (normal mode) or button (edit mode)
    input down,                 // Decrement: driven by button (edit mode only)
    output sig_1min,            // Carry output: pulses high when seconds roll over from 59 to 0
    output reg [3:0] ones, tens // BCD output: tens and ones digits of the current second
);

    reg [5:0] sec;              // Binary second value (0-59)
    assign sig_1min = (up == 1'b1 && sec == 6'd59) ? 1'b1 : 1'b0;

    // Sequential counter logic
    always @(posedge clk_50MHz or negedge rst_n) begin
        if(rst_n == 1'b0) begin     
            sec <= 6'd0;
        end
        else begin 
            // Increment
            if (up == 1'b1) begin 
                if (sec == 6'd59) begin
                    sec <= 6'd0;
                end
                else begin 
                    sec <= sec + 1;
                end
            end

            // Decrement (wraps from 0 to 59)
            else if (down == 1'b1) begin 
                if (sec == 6'd0) begin
                    sec <= 6'd59;
                end
                else begin
                    sec <= sec -1'b1; 
                end
            end

            // Hold current value
            else begin
                sec <= sec;
            end
        end

    end  

    // Combinational logic: binary to BCD conversion
    always @(sec) begin
                        
        if (sec < 10) begin 
            tens = 4'd0; 
            ones = sec;
        end
        else if (sec < 20) begin
            tens = 4'd1; 
            ones = sec - 10;
        end
        else if (sec < 30) begin 
            tens = 4'd2;
            ones = sec - 20;
        end 
        else if (sec < 40) begin
            tens = 4'd3;
            ones = sec - 30;
        end
        else if (sec < 50) begin 
            tens = 4'd4;
            ones = sec - 40;
        end else begin
            tens = 4'd5;
            ones = sec - 50;
        end
    end
endmodule
    