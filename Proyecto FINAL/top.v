module top (
    input  wire clk,             // reloj 50 MHz
    input  wire rst,
    input  wire rx,

    input  wire ir_bowl_pin,     // IR en el tazón (parte 1)
    input  wire ir_storage_pin,  // IR en almacenamiento (parte 2)
    input  wire echo_i,          // Sensor ultrasónico
    output wire trigger_o,       // Trigger del HCSR04

    output wire servo_out,       // PWM al servo
    output wire relay_out,       // Salida al transistor del relé

    output wire rs,
    output wire rw,
    output wire enable,
    output wire [7:0] data_o
);

    // UART
    wire        data_valid;
    wire [7:0]  data;

    uart_rx #(
        .CLK_FREQ(50000000),
        .BAUD(115200)
    ) uart_rx_inst (
        .clk(clk),
        .rst(~rst),
        .rx(rx),
        .data_valid(data_valid),
        .data(data)
    );

    // Parser de hora
    wire        synced;
    wire [4:0]  hour_p;
    wire [5:0]  min_p;
    wire [5:0]  sec_p;

    time_parser parser_inst (
        .clk(clk),
        .rst(~rst),
        .data_valid(data_valid),
        .data(data),
        .hour(hour_p),
        .min(min_p),
        .sec(sec_p),
        .synced(synced)
    );

    // RTC
    wire [4:0] hour_rtc;
    wire [5:0] min_rtc;
    wire [5:0] sec_rtc;

    rtc_counter #(.CLK_FREQ(50000000)) rtc_inst (
        .clk(clk),
        .rst(~rst),
        .synced(synced),
        .hour_in(hour_p),
        .min_in(min_p),
        .sec_in(sec_p),
        .hour(hour_rtc),
        .min(min_rtc),
        .sec(sec_rtc)
    );

    // Parser de múltiples alarmas
    wire [4:0] alarm_hour1, alarm_hour2, alarm_hour3;
    wire [5:0] alarm_min1,  alarm_min2,  alarm_min3;
    wire [5:0] alarm_sec1,  alarm_sec2,  alarm_sec3;
    wire       set1, set2, set3;

    multi_alarm_parser alarm_parser_inst (
        .clk(clk),
        .rst(~rst),
        .data_valid(data_valid),
        .data(data),
        .hour1(alarm_hour1), .min1(alarm_min1), .sec1(alarm_sec1), .set1(set1),
        .hour2(alarm_hour2), .min2(alarm_min2), .sec2(alarm_sec2), .set2(set2),
        .hour3(alarm_hour3), .min3(alarm_min3), .sec3(alarm_sec3), .set3(set3)
    );

    // Sensor IR en tazón + antirrebote
    wire sensor_bowl_raw;
    wire sensor_bowl_clean;

    sensor_tcrt5000 sensor_bowl_inst (
        .sensor_pin(ir_bowl_pin),
        .sensor_activo(sensor_bowl_raw)
    );

    antirrebote #(.COUNT(50000)) debounce_bowl (
        .clk(clk),
        .btn(sensor_bowl_raw),
        .clean(sensor_bowl_clean)
    );

    // Triggers para el SERVO (con sensor)
    wire alarm_active1_servo, alarm_active2_servo, alarm_active3_servo;

    alarm_trigger_cond alarm1_servo (
        .clk(clk), .rst(~rst),
        .hour_rtc(hour_rtc), .min_rtc(min_rtc), .sec_rtc(sec_rtc),
        .alarm_set(set1),
        .alarm_hour_in(alarm_hour1), .alarm_min_in(alarm_min1), .alarm_sec_in(alarm_sec1),
        .pin_check(sensor_bowl_clean),
        .alarm_active(alarm_active1_servo)
    );

    alarm_trigger_cond alarm2_servo (
        .clk(clk), .rst(~rst),
        .hour_rtc(hour_rtc), .min_rtc(min_rtc), .sec_rtc(sec_rtc),
        .alarm_set(set2),
        .alarm_hour_in(alarm_hour2), .alarm_min_in(alarm_min2), .alarm_sec_in(alarm_sec2),
        .pin_check(sensor_bowl_clean),
        .alarm_active(alarm_active2_servo)
    );

    alarm_trigger_cond alarm3_servo (
        .clk(clk), .rst(~rst),
        .hour_rtc(hour_rtc), .min_rtc(min_rtc), .sec_rtc(sec_rtc),
        .alarm_set(set3),
        .alarm_hour_in(alarm_hour3), .alarm_min_in(alarm_min3), .alarm_sec_in(alarm_sec3),
        .pin_check(sensor_bowl_clean),
        .alarm_active(alarm_active3_servo)
    );

    wire servo_control = alarm_active1_servo | alarm_active2_servo | alarm_active3_servo;

    servo_n_pos servo_inst (
        .clk(clk),
        .switch(servo_control),
        .servo(servo_out)
    );

    // Triggers para el RELÉ (sin sensor)
    wire alarm_active1_relay, alarm_active2_relay, alarm_active3_relay;

    alarm_trigger_simple alarm1_relay (
        .clk(clk), .rst(~rst),
        .hour_rtc(hour_rtc), .min_rtc(min_rtc), .sec_rtc(sec_rtc),
        .alarm_set(set1),
        .alarm_hour_in(alarm_hour1), .alarm_min_in(alarm_min1), .alarm_sec_in(alarm_sec1),
        .alarm_active(alarm_active1_relay)
    );

    alarm_trigger_simple alarm2_relay (
        .clk(clk), .rst(~rst),
        .hour_rtc(hour_rtc), .min_rtc(min_rtc), .sec_rtc(sec_rtc),
        .alarm_set(set2),
        .alarm_hour_in(alarm_hour2), .alarm_min_in(alarm_min2), .alarm_sec_in(alarm_sec2),
        .alarm_active(alarm_active2_relay)
    );

    alarm_trigger_simple alarm3_relay (
        .clk(clk), .rst(~rst),
        .hour_rtc(hour_rtc), .min_rtc(min_rtc), .sec_rtc(sec_rtc),
        .alarm_set(set3),
        .alarm_hour_in(alarm_hour3), .alarm_min_in(alarm_min3), .alarm_sec_in(alarm_sec3),
        .alarm_active(alarm_active3_relay)
    );

    wire relay_trigger = alarm_active1_relay | alarm_active2_relay | alarm_active3_relay;

    relay_timer #(
        .CLK_FREQ(50000000),
        .ACTIVE_TIME_SEC(5)
    ) relay_inst (
        .clk(clk),
        .rst(~rst),
        .trigger(relay_trigger),
        .relay_out(relay_out)
    );

    // Sensor ultrasónico
    wire [31:0] echo_counter;
    wire nivel_agua_okay;

    ultrasonic_controller #(.TIME_TRIG(500)) ultra_inst (
        .clk(clk),
        .rst(rst),
        .ready_i(1'b1),
        .echo_i(echo_i),
        .trigger_o(trigger_o),
        .echo_counter(echo_counter)
    );

    assign nivel_agua_okay = (echo_counter < 32'd30000);

    // Sensor IR en almacenamiento + antirrebote
    wire sensor_storage_raw;
    wire sensor_storage_clean;

    sensor_tcrt5000 sensor_storage_inst (
        .sensor_pin(ir_storage_pin),
        .sensor_activo(sensor_storage_raw)
    );

    antirrebote #(.COUNT(500_000)) debounce_storage (
        .clk(clk),
        .btn(sensor_storage_raw),
        .clean(sensor_storage_clean)
    );

    // LCD
    LCD1602_controller lcd (
        .clk(clk),
        .reset(rst),
        .ready_i(1'b1),
        .in1({3'b000, nivel_agua_okay}),
        .in2({3'b000, sensor_storage_clean}),
        .rs(rs),
        .rw(rw),
        .enable(enable),
        .data(data_o)
    );

endmodule