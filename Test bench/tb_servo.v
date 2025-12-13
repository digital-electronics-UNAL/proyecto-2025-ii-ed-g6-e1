`timescale 1ns/1ps
`include "servo_n_pos.v"

module tb_servo;

    reg clk = 0;
    reg switch;
    wire servo;

    always #10 clk = ~clk;

    servo_n_pos dut (
        .clk(clk),
        .switch(switch),
        .servo(servo)
    );

    initial begin
        $dumpfile("servo.vcd");
        $dumpvars(0, tb_servo);

        switch = 0;
        #200 switch = 1;
        #200 switch = 0;

        #500 $finish;
    end
endmodule
