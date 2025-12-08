module servo_n_pos (
    input clk,          // reloj de 50 MHz
    input switch,       // control ON/OFF
    output servo        // salida PWM
);

    reg [19:0] counter = 0;          // cuenta hasta 1_000_000 → 20 ms
    reg [19:0] position = 75000;     // valor inicial (1.5 ms)

    // Calibración manual: ajusta estos dos valores
    parameter POS_0   = 40000;       // 1.0 ms → 0 grados
    parameter POS_180 = 120000;      // 2.0 ms → 180 grados (ajustar si no llega)

    // Actualiza posición del servo según el switch
    always @(posedge clk) begin
        if (switch)
            position <= POS_180;
        else
            position <= POS_0;
    end

    // Generador de PWM con periodo de 20 ms (50 MHz)
    always @(posedge clk) begin
        if (counter < 1000000)
            counter <= counter + 1;
        else
            counter <= 0;
    end

    assign servo = (counter < position) ? 1'b1 : 1'b0;

endmodule
