`timescale 1ns/1ps
`include "relay_timer.v"

module tb_relay;

    reg clk = 0, rst = 1;
    reg trigger;
    wire relay_out;

    always #5 clk = ~clk;

    relay_timer #(
        .CLK_FREQ(100),        // reducido
        .ACTIVE_TIME_SEC(2)
    ) dut (
        .clk(clk),
        .rst(rst),
        .trigger(trigger),
        .relay_out(relay_out)
    );

    initial begin
        $dumpfile("relay.vcd");
        $dumpvars(0, tb_relay);

        trigger = 0;
        #20 rst = 0;

        #50 trigger = 1; #10 trigger = 0;

        #300 $finish;
    end
endmodule
