`timescale 1ns/1ps
`include "alarm_trigger_simple.v"

module tb_alarm_simple;

    reg clk = 0, rst = 1;
    reg [4:0] hour_rtc;
    reg [5:0] min_rtc, sec_rtc;
    reg alarm_set;
    reg [4:0] alarm_hour_in;
    reg [5:0] alarm_min_in, alarm_sec_in;
    wire alarm_active;

    always #10 clk = ~clk; // 50 MHz

    alarm_trigger_simple dut (
        .clk(clk),
        .rst(rst),
        .hour_rtc(hour_rtc),
        .min_rtc(min_rtc),
        .sec_rtc(sec_rtc),
        .alarm_set(alarm_set),
        .alarm_hour_in(alarm_hour_in),
        .alarm_min_in(alarm_min_in),
        .alarm_sec_in(alarm_sec_in),
        .alarm_active(alarm_active)
    );

    initial begin
        $dumpfile("alarm_simple.vcd");
        $dumpvars(0, tb_alarm_simple);

        // Estado inicial RTC
        hour_rtc = 1;
        min_rtc  = 2;
        sec_rtc  = 0;
        alarm_set = 0;

        #50 rst = 0;

        // Programar alarma 01:02:03
        #20 alarm_hour_in = 1;
            alarm_min_in  = 2;
            alarm_sec_in  = 3;
            alarm_set     = 1;
        #20 alarm_set = 0;

        // Simular segundos
        #100 sec_rtc = 1;
        #100 sec_rtc = 2;
        #100 sec_rtc = 3;  // 🔥 AQUÍ SE ACTIVA

        #200 sec_rtc = 4;

        #500 $finish;
    end
endmodule
