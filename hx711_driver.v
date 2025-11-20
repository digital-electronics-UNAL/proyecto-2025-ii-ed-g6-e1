`timescale 1ns / 1ps

module hx711_driver #(
    parameter CLK_FREQ_HZ = 50_000_000,  // reloj FPGA
    parameter SCK_FREQ_HZ = 50_000       // frecuencia de SCK (~50 kHz)
)(
    input  wire clk,
    input  wire rst_n,
    input  wire hx_dt,        // DOUT del HX711
    output reg  hx_sck,       // SCK del HX711
    output reg  [23:0] data_out,
    output reg  data_ready
);

    localparam integer CLK_DIV = CLK_FREQ_HZ / (SCK_FREQ_HZ * 2);
    reg [15:0] div_cnt;
    reg [5:0]  bit_cnt;
    reg [23:0] shift_reg;
    reg reading;

    // Divisor de reloj para generar SCK
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hx_sck <= 1'b0;
            div_cnt <= 0;
        end else if (reading) begin
            if (div_cnt == CLK_DIV) begin
                div_cnt <= 0;
                hx_sck <= ~hx_sck;
            end else
                div_cnt <= div_cnt + 1;
        end else begin
            hx_sck <= 1'b0;
            div_cnt <= 0;
        end
    end

    // Máquina de estados: espera -> lectura -> fin
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            bit_cnt   <= 0;
            reading   <= 0;
            shift_reg <= 0;
            data_ready <= 0;
        end else begin
            data_ready <= 0;

            if (!reading) begin
                if (hx_dt == 1'b0) begin
                    reading <= 1'b1;
                    bit_cnt <= 0;
                end
            end else begin
                if (hx_sck == 1'b1 && div_cnt == 0) begin
                    shift_reg <= {shift_reg[22:0], hx_dt};
                    bit_cnt <= bit_cnt + 1;
                    if (bit_cnt == 24) begin
                        reading <= 0;
                        data_out <= shift_reg;
                        data_ready <= 1'b1;
                    end
                end
            end
        end
    end

endmodule
