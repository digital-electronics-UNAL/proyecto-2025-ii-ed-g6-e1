module top_final (
    input clk,                // reloj 50 MHz
    input sensor_pin,         // señal del sensor IR (activa en bajo)
    input reset,              // reset para LCD
    input ready_i,            // señal para empezar escritura LCD

    // Señales de salida a la LCD
    output rs,
    output rw,
    output enable,
    output [7:0] data,
    output sensor_out_led     // LED opcional para debug visual
);

    wire sensor_activo_raw;
    wire sensor_activo_clean;

    // === Módulo del sensor IR ===
    sensor_tcrt5000 sensor (
        .sensor_pin(sensor_pin),
        .sensor_activo(sensor_activo_raw)
    );

    // === Antirrebote para limpiar señal del sensor ===
    antirrebote #(.COUNT(500_000)) filtro (
        .clk(clk),
        .btn(sensor_activo_raw),
        .clean(sensor_activo_clean)
    );

    assign sensor_out_led = sensor_activo_clean;  // opcional: LED de estado

    // === Módulo LCD ===
    LCD1602_controller lcd (
        .clk(clk),
        .reset(reset),
        .ready_i(ready_i),

        // Entrada dinámica: muestra 1 o 0 según sensor
        .in1({3'b000, sensor_activo_clean}),  // 4 bits, LSB es sensor
        .in2(4'b0000),  // no usado, pero necesita conexión

        .rs(rs),
        .rw(rw),
        .enable(enable),
        .data(data)
    );

endmodule
