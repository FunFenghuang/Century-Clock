module clock_divider #(parameter clk_f = 50000000) ( 
    input  wire clk,
    input  wire rst_n,
    input  wire edit_enable,
    output reg  tick_100hz,
    output reg  tick_1hz,
    output reg  tick_blink
);


    // Công thức: giới hạn = (Tần số vào / Tần số ra) - 1
    localparam MAX_100HZ = (clk_f / 100) - 1; // Tính từ 50MHz
    localparam MAX_1HZ   = 100 - 1;           // Đếm 100 nhịp của 100Hz = 1 giây
    localparam MAX_2HZ   = 50 - 1;            // Đếm 50 nhịp cuả 100Hz

    reg [18:0] counter_100hz;
    reg [6:0]  counter_1hz;
    reg [5:0]  counter_blink;

    // TẦNG 1: Tạo xung tick_100hz
    always @(posedge clk or negedge rst_n) begin 
        if (!rst_n) begin
            counter_100hz <= 0;
            tick_100hz    <= 0;
        end else begin
            if (counter_100hz == MAX_100HZ) begin
                counter_100hz <= 0;
                tick_100hz    <= 1; 
            end else begin
                counter_100hz <= counter_100hz + 1; 
                tick_100hz    <= 0;
            end
        end 
    end


    // TẦNG 2: Tạo xung tick_1hz 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_1hz <= 0;
            tick_1hz    <= 0;
        end else begin
            tick_1hz <= 0; 
            
            if (tick_100hz) begin 
                if (counter_1hz == MAX_1HZ) begin
                    counter_1hz <= 0;
                    tick_1hz    <= 1; 
                end else begin
                    counter_1hz <= counter_1hz + 1;
                end
            end
        end 
    end

    // Tầng 3 : Tạo xung tick_blink
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_blink <= 0;
            tick_blink    <= 0;
        end else begin
            tick_blink <= 0; 
            
            if (tick_100hz) begin 
                if (counter_blink == MAX_2HZ) begin
                    counter_blink <= 0;
                    tick_blink    <= 1; 
                end else begin
                    counter_blink <= counter_blink + 1;
                end
            end
        end 
    end

endmodule