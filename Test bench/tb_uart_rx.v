`timescale 1ns/1ps
`include "uart_rx.v"

module tb_uart_rx;

    reg clk = 0;
    reg rst = 1;
    reg rx  = 1;   // línea en reposo
    wire data_valid;
    wire [7:0] data;

    // reloj rápido para simular
    always #5 clk = ~clk; // 100 MHz

    // UART con parámetros reducidos
    uart_rx #(
        .CLK_FREQ(100_000_000),
        .BAUD(1_000_000)        // BAUD alto → simulación rápida
    ) dut (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .data_valid(data_valid),
        .data(data)
    );

    // duración de 1 bit UART
    localparam BIT_TIME = 1000; // ns (1 MHz)

    task send_byte;
        input [7:0] b;
        integer i;
        begin
            // start bit
            rx = 0;
            #(BIT_TIME);

            // 8 bits LSB first
            for (i = 0; i < 8; i = i + 1) begin
                rx = b[i];
                #(BIT_TIME);
            end

            // stop bit
            rx = 1;
            #(BIT_TIME);
        end
    endtask

    initial begin
        $dumpfile("uart_rx.vcd");
        $dumpvars(0, tb_uart_rx);

        #50 rst = 0;

        // Enviar carácter 'T'
        send_byte("T");

        // Enviar ':'
        send_byte(":");

        // Enviar '1'
        send_byte("1");

        #500 $finish;
    end

endmodule
