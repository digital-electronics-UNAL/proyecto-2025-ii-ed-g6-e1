`timescale 1ns/1ps
`include "alarm_trigger_cond.v"

module tb_alarm_trigger_cond;

    reg clk = 0;
    reg rst = 1;

    reg [4:0] hour_rtc;
    reg [5:0] min_rtc;
    reg [5:0] sec_rtc;

    reg alarm_set;
    reg [4:0] alarm_hour_in;
    reg [5:0] alarm_min_in;
    reg [5:0] alarm_sec_in;

    reg pin_check;
    wire alarm_active;

    always #10 clk = ~clk;

    alarm_trigger_cond dut (
        .clk(clk),
        .rst(rst),
        .hour_rtc(hour_rtc),
        .min_rtc(min_rtc),
        .sec_rtc(sec_rtc),
        .alarm_set(alarm_set),
        .alarm_hour_in(alarm_hour_in),
        .alarm_min_in(alarm_min_in),
        .alarm_sec_in(alarm_sec_in),
        .pin_check(pin_check),
        .alarm_active(alarm_active)
    );

    initial begin
        $dumpfile("alarm_cond.vcd");
        $dumpvars(0, tb_alarm_trigger_cond);

        hour_rtc = 0;
        min_rtc  = 0;
        sec_rtc  = 0;
        pin_check = 0;
        alarm_set = 0;

        #50 rst = 0;

        // Programar alarma 01:02:03
        alarm_hour_in = 1;
        alarm_min_in  = 2;
        alarm_sec_in  = 3;
        alarm_set = 1;
        #20 alarm_set = 0;

        // Simular RTC
        repeat (5) begin
            #40 sec_rtc = sec_rtc + 1;
        end

        // Desactivar por pin_check
        #50 pin_check = 1;

        #200 $finish;
    end
endmodule
