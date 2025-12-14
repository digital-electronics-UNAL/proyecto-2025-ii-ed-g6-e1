module relay_timer #(
    parameter CLK_FREQ = 50000000,         // Frecuencia del reloj en Hz
    parameter ACTIVE_TIME_SEC = 5          // Tiempo activo en segundos
)(
    input  wire clk,
    input  wire rst,
    input  wire trigger,        // Pulso de activación (una vez por alarma)
    output reg  relay_out       // Salida al relé (activo = 1)
);

    localparam MAX_COUNT = CLK_FREQ * ACTIVE_TIME_SEC;

    reg [31:0] counter = 0;
    reg        active = 0;
    reg        prev_trigger = 0;

    wire trigger_edge = trigger & ~prev_trigger;

    always @(posedge clk) begin
        prev_trigger <= trigger;

        if (rst) begin
            active <= 0;
            counter <= 0;
            relay_out <= 0;
        end else begin
            if (trigger_edge) begin
                active <= 1;
                counter <= 0;
            end

            if (active) begin
                if (counter < MAX_COUNT - 1) begin
                    counter <= counter + 1;
                    relay_out <= 1;
                end else begin
                    active <= 0;
                    relay_out <= 0;
                end
            end else begin
                relay_out <= 0;
            end
        end
    end

endmodule
