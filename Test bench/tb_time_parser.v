`timescale 1ns/1ps
`include "time_parser.v"

module tb_time_parser;

    reg clk = 0;
    reg rst = 1;
    reg data_valid = 0;
    reg [7:0] data;

    wire [4:0] hour;
    wire [5:0] min;
    wire [5:0] sec;
    wire synced;

    always #10 clk = ~clk;

    time_parser dut (
        .clk(clk),
        .rst(rst),
        .data_valid(data_valid),
        .data(data),
        .hour(hour),
        .min(min),
        .sec(sec),
        .synced(synced)
    );

    task send_char;
        input [7:0] c;
        begin
            @(posedge clk);
            data <= c;
            data_valid <= 1;
            @(posedge clk);
            data_valid <= 0;
        end
    endtask

    initial begin
        $dumpfile("time_parser.vcd");
        $dumpvars(0, tb_time_parser);

        #50 rst = 0;

        // Enviar "T:12:34:56\n"
        send_char("T");
        send_char(":");
        send_char("1");
        send_char("2");
        send_char(":");
        send_char("3");
        send_char("4");
        send_char(":");
        send_char("5");
        send_char("6");
        send_char("\n");

        #200 $finish;
    end
endmodule
