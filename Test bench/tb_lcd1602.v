`timescale 1ns/1ps
`include "lcd1602_controller.v"

module tb_lcd1602;

    reg clk = 0;
    reg reset = 0;
    reg ready_i = 0;
    reg [3:0] in1, in2;

    wire rs, rw, enable;
    wire [7:0] data;

    // CLK rápido para simular
    always #5 clk = ~clk; // 100 MHz

    LCD1602_controller #(
        .COUNT_MAX(20)   // ⚠️ reducido para simulación
    ) dut (
        .clk(clk),
        .reset(reset),
        .ready_i(ready_i),
        .in1(in1),
        .in2(in2),
        .rs(rs),
        .rw(rw),
        .enable(enable),
        .data(data)
    );

    initial begin
        $dumpfile("lcd.vcd");
        $dumpvars(0, tb_lcd1602);

        in1 = 0;
        in2 = 0;

        #50 reset = 1;
        #50 ready_i = 1;

        #200 in1[0] = 1;   // AGUA OK
        #200 in2[0] = 1;   // COMIDA OK

        #500 $finish;
    end
endmodule
