module rtc_counter #(
    parameter CLK_FREQ = 50000000
)(
    input  wire clk,
    input  wire rst,

    input  wire        synced,
    input  wire [4:0]  hour_in,
    input  wire [5:0]  min_in,
    input  wire [5:0]  sec_in,

    output reg [4:0] hour,
    output reg [5:0] min,
    output reg [5:0] sec
);

    localparam SEC_TICK = CLK_FREQ;

    reg [31:0] tick_cnt;

    // Nuevo: detección de flanco ascendente en 'synced'
    reg synced_d;
    wire synced_edge = synced & ~synced_d;

    always @(posedge clk) begin
        synced_d <= synced; // guarda el estado anterior de 'synced'

        if (rst) begin
            hour <= 0;
            min  <= 0;
            sec  <= 0;
            tick_cnt <= 0;
        end
        else if (synced_edge) begin
            // Captura nueva hora solo cuando synced pasa de 0 a 1
            hour <= hour_in;
            min  <= min_in;
            sec  <= sec_in;
            tick_cnt <= 0;
        end
        else if (tick_cnt == SEC_TICK - 1) begin
            tick_cnt <= 0;

            if (sec == 59) begin
                sec <= 0;
                if (min == 59) begin
                    min <= 0;
                    if (hour == 23)
                        hour <= 0;
                    else
                        hour <= hour + 1;
                end else begin
                    min <= min + 1;
                end
            end else begin
                sec <= sec + 1;
            end
        end else begin
            tick_cnt <= tick_cnt + 1;
        end
    end
endmodule
