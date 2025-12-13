`timescale 1ns/1ps
`include "rtc_counter.v"

module tb_rtc;

    reg clk = 0, rst = 1, synced = 0;
    reg [4:0] hour_in;
    reg [5:0] min_in, sec_in;
    wire [4:0] hour;
    wire [5:0] min;
    wire [5:0] sec;

    always #5 clk = ~clk;

    rtc_counter #(.CLK_FREQ(10)) dut (
        .clk(clk),
        .rst(rst),
        .synced(synced),
        .hour_in(hour_in),
        .min_in(min_in),
        .sec_in(sec_in),
        .hour(hour),
        .min(min),
        .sec(sec)
    );

    initial begin
        $dumpfile("rtc.vcd");
        $dumpvars(0, tb_rtc);

        hour_in=10; min_in=20; sec_in=30;

        #20 rst=0;
        #20 synced=1; #10 synced=0;

        #200 $finish;
    end
endmodule
