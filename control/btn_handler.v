module btn_handler(
    input clk_50MHz,   // 50MHz system clock
    input tick_100hz,  // 100Hz tick (10ms period) for debouncing
    input rst_n,       // Active-low reset
    input btn_in,      // Raw button input signal
    output reg btn_edge // Debounced rising-edge pulse output
);

// ---- Two-stage synchronizer (metastability protection) ----

reg btn_sync1;
reg btn_sync2;

always @(posedge clk_50MHz) begin

        if(!rst_n) begin
            btn_sync1 <= 1'b0;
            btn_sync2 <= 1'b0;
        end
        
        else begin 
            btn_sync1 <= btn_in;
            btn_sync2 <= btn_sync1;
    end
end

// ---- Debounce filter ----
// Waits for 4 consecutive stable samples (40ms) before accepting a change

reg [3:0] stable_cnt;
reg btn_debounced;

always @(posedge clk_50MHz) begin
    if(!rst_n) begin
        stable_cnt <= 4'd0;
        btn_debounced <= 1'b0; 
    end
    else if (tick_100hz) begin
        if(btn_sync2 == btn_debounced) begin
            stable_cnt <= 4'd0;
        end
        else begin 
            if(stable_cnt == 4'd4) begin
                btn_debounced <= btn_sync2;
                stable_cnt <= 4'd0;
            end
            else begin
                stable_cnt <= stable_cnt + 4'd1;
            end
        end
    end
end


// ---- Rising-edge detector ----
// Generates a single clock-cycle pulse on the rising edge of the debounced signal

reg btn_debounced_d;

always @(posedge clk_50MHz) begin
        if (!rst_n) begin
            btn_debounced_d <= 1'b0;
            btn_edge        <= 1'b0;
        end else begin
            btn_debounced_d <= btn_debounced;
            btn_edge <= btn_debounced & ~btn_debounced_d;
        end
    end
endmodule
