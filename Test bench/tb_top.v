`timescale 1ns/1ps
`include "top.v"
`include "LCD1602_controller.v"
`include "alarm_trigger_cond.v"
`include "alarm_trigger_simple.v"
`include "multi_alarm_parser.v"
`include "relay_timer.v"
`include "rtc_counter.v"
`include "sensor_tcrt5000.v"
`include "servo_n_pos.v"
`include "time_parser.v"
`include "uart_rx.v"
`include "ultrasonic_controller.v"
`include "antirebote.v"


module tb_top;

    reg clk=0, rst=0;
    reg rx=1;
    reg ir_bowl_pin=1;
    reg ir_storage_pin=1;
    reg echo_i=0;

    wire trigger_o, servo_out, relay_out;
    wire rs, rw, enable;
    wire [7:0] data_o;

    always #10 clk = ~clk;

    top dut (
        .clk(clk),
        .rst(rst),
        .rx(rx),
        .ir_bowl_pin(ir_bowl_pin),
        .ir_storage_pin(ir_storage_pin),
        .echo_i(echo_i),
        .trigger_o(trigger_o),
        .servo_out(servo_out),
        .relay_out(relay_out),
        .rs(rs),
        .rw(rw),
        .enable(enable),
        .data_o(data_o)
    );

    initial begin
        $dumpfile("top.vcd");
        $dumpvars(0, tb_top);

        #50 rst=1;

        #200 ir_bowl_pin=0;    // simula objeto
        #200 ir_storage_pin=0;

        #500 $finish;
    end
endmodule
