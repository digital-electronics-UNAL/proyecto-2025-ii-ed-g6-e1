module top_rele (
    input wire clk,
    input wire switch,          // En el futuro: switch, sensor, UART...
    output wire relay_out       // Hacia la base del transistor
);

// En el futuro podrías tener algo como:
// wire activate = (switch | sensor | comando_uart);
wire activate = switch;

relay_controller controller_inst (
    .clk(clk),
    .activate(activate),
    .relay_out(relay_out)
);

endmodule
