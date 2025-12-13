`timescale 1ns/1ps
`include "ultrasonic_controller.v"

module tb_ultrasonic;

    reg clk=0, rst=0;
    reg ready_i=1;
    reg echo_i=0;
    wire trigger_o;
    wire [31:0] echo_counter;

    always #5 clk = ~clk;

    ultrasonic_controller #(.TIME_TRIG(5)) dut (
        .clk(clk),
        .rst(rst),
        .ready_i(ready_i),
        .echo_i(echo_i),
        .trigger_o(trigger_o),
        .echo_counter(echo_counter)
    );

    initial begin
        $dumpfile("ultra.vcd");
        $dumpvars(0, tb_ultrasonic);

        #10 rst=1;

        #50 echo_i=1;
        #50 echo_i=0;

        #200 $finish;
    end
endmodule
