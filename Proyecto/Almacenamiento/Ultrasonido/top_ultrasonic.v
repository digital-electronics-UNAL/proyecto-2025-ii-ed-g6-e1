module top_ultrasonic (
    input  wire clk,           // 50 MHz
    input  wire rst,           // activo en bajo
    input  wire sensor_pin,    // señal del sensor IR (activa en bajo)
    input  wire echo_i,        // pin ECHO del HCSR04
    output wire trigger_o,     // pin TRIG del HCSR04

    // LCD
    output wire rs,
    output wire rw,
    output wire enable,
    output wire [7:0] data,

    // LEDs de estado (opcionales)
    output wire led_agua,      // LED: OK/NOK para agua
    output wire led_comida     // LED: OK/NOK para comida
);

    // === Señal del sensor ultrasónico ===
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

    // Umbral ajustable (ej: 10 cm = 30_000)
    assign nivel_agua_okay = (echo_counter < 32'd30000);
    assign led_agua = nivel_agua_okay;

    // === Sensor IR con antirrebote ===
    wire sensor_activo_raw;
    wire sensor_activo_clean;

    sensor_tcrt5000 sensor_ir (
        .sensor_pin(sensor_pin),
        .sensor_activo(sensor_activo_raw)
    );

    antirrebote #(.COUNT(500_000)) filtro_ir (
        .clk(clk),
        .btn(sensor_activo_raw),
        .clean(sensor_activo_clean)
    );

    assign led_comida = sensor_activo_clean;

    // === LCD ===
    LCD1602_controller lcd (
        .clk(clk),
        .reset(rst),
        .ready_i(1'b1),  // siempre activo

        // Línea 1: AGUA   → HCSR04
        // Línea 2: COMIDA → IR
        .in1({3'b000, nivel_agua_okay}),
        .in2({3'b000, sensor_activo_clean}),

        .rs(rs),
        .rw(rw),
        .enable(enable),
        .data(data)
    );

endmodule

