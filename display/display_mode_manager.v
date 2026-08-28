// Display mode manager: toggles between TIME and DATE display modes
//   mode = 0 -> TIME (HH:MM:SS)
//   mode = 1 -> DATE (DD:MM:YYYY)

module display_mode_manager (
    input  wire clk_50MHz,
    input  wire rst_n,
    input  wire tick_1min,       // 1-minute tick from counter_controller (sig_1min_out)
    output reg  mode             // 0: TIME, 1: DATE
);

    always @(posedge clk_50MHz or negedge rst_n) begin
        if (!rst_n)
            mode <= 1'b0;       // Default to TIME mode
        else if (tick_1min)
            mode <= ~mode;      // Toggle every minute
    end

endmodule
