module sensor_tcrt5000 (
    input sensor_pin,       // Señal del sensor
    output sensor_activo    // 1 cuando detecta objeto
);
    assign sensor_activo = (sensor_pin == 1'b0);  // Sensor activo en bajo
endmodule
