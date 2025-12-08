module top (
    input clk,         // reloj de 50 MHz
    input button,      // entrada física (ej. botón o sensor digital)
    output servo_out   // señal PWM al servo
);

    wire servo_control;

    // Lógica actual: el botón controla el servo directamente
    assign servo_control = button;

    // Instancia del controlador de servo
    servo_n_pos servo_inst (
        .clk(clk),
        .switch(servo_control),
        .servo(servo_out)
    );

endmodule}
