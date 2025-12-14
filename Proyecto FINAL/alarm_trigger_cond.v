module alarm_trigger_cond (
    input  wire       clk,
    input  wire       rst,

    input  wire [4:0] hour_rtc,
    input  wire [5:0] min_rtc,
    input  wire [5:0] sec_rtc,

    input  wire       alarm_set,
    input  wire [4:0] alarm_hour_in,
    input  wire [5:0] alarm_min_in,
    input  wire [5:0] alarm_sec_in,

    input  wire       pin_check,      // entrada digital que se revisa

    output reg        alarm_active    // se mantiene activo hasta que pin_check = 1
);

    reg [4:0] alarm_hour;
    reg [5:0] alarm_min;
    reg [5:0] alarm_sec;

    reg [5:0] prev_sec;

    always @(posedge clk) begin
        if (rst) begin
            alarm_hour   <= 0;
            alarm_min    <= 0;
            alarm_sec    <= 0;
            alarm_active <= 0;
            prev_sec     <= 0;
        end else begin
            // Alarma programada por UART
            if (alarm_set) begin
                alarm_hour <= alarm_hour_in;
                alarm_min  <= alarm_min_in;
                alarm_sec  <= alarm_sec_in;
            end

            // Desactiva si el pin pasa a 1
            if (alarm_active && pin_check == 1)
                alarm_active <= 0;

            // Detectar flanco de segundo
            if (sec_rtc != prev_sec) begin
                prev_sec <= sec_rtc;

                // Si el reloj coincide con la hora de la alarma
                // y el pin está en 0, activar alarma
                if (
                    hour_rtc == alarm_hour &&
                    min_rtc  == alarm_min  &&
                    sec_rtc  == alarm_sec &&
                    pin_check == 0
                ) begin
                    alarm_active <= 1;
                end
            end
        end
    end
endmodule
