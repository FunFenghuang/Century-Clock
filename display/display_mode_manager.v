
//   mode = 0 -> TIME (GIO:PHUT:GIAY)
//   mode = 1 -> DATE (NGAY:THANG:NAM)

module display_mode_manager (
    input  wire clk_50MHz,
    input  wire rst_n,
    input  wire tick_1min,       // xung 1 phut tu top_counter (sig_1min_out)
    output reg  mode     // 0: TIME, 1: DATE
);

    always @(posedge clk_50MHz or negedge rst_n) begin
        if (!rst_n)
            mode <= 1'b0;      //TIME
        else if (tick_1min)
            mode <= ~mode;  // Dao moi 1 phut
    end

endmodule
