module lcd_time_display (
    input  wire clk,           // 50 MHz
    input  wire rst,

    input  wire [4:0] hour,    // 0–23
    input  wire [5:0] min,     // 0–59
    input  wire [5:0] sec,     // 0–59

    output reg rs,
    output reg rw,
    output reg en,
    output reg [7:0] data
);

    // ============================================
    // CLOCK DIVISOR PARA GENERAR "tick" de ~1 ms
    // ============================================
    reg [15:0] div = 0;
    wire tick = (div == 16'd50000); // 50 MHz / 50,000 = 1 kHz = 1 ms

    always @(posedge clk) begin
        if (rst)
            div <= 0;
        else if (tick)
            div <= 0;
        else
            div <= div + 1;
    end

    // ============================================
    // FSM DE CONTROL PARA INICIALIZACIÓN Y ESCRITURA
    // ============================================

    localparam INIT0        = 0,
               INIT0_EN     = 1,
               INIT1        = 2,
               INIT1_EN     = 3,
               INIT2        = 4,
               INIT2_EN     = 5,
               CLEAR        = 6,
               CLEAR_EN     = 7,
               SET_LINE1    = 8,
               SET_LINE1_EN = 9,
               WRITE_H_D    = 10,
               WRITE_H_D_EN = 11,
               WRITE_H_U    = 12,
               WRITE_H_U_EN = 13,
               WRITE_COL1   = 14,
               WRITE_COL1_EN= 15,
               WRITE_M_D    = 16,
               WRITE_M_D_EN = 17,
               WRITE_M_U    = 18,
               WRITE_M_U_EN = 19,
               WRITE_COL2   = 20,
               WRITE_COL2_EN= 21,
               WRITE_S_D    = 22,
               WRITE_S_D_EN = 23,
               WRITE_S_U    = 24,
               WRITE_S_U_EN = 25;

    reg [4:0] state = INIT0;

    // ============================================
    // ASCII CONVERTER FUNCTION (0-9 → '0'-'9')
    // ============================================
    function [7:0] ascii;
        input [3:0] val;
        ascii = val + 8'h30;
    endfunction

    // ============================================
    // FSM
    // ============================================
    always @(posedge clk) begin
        if (rst) begin
            state <= INIT0;
            en    <= 0;
        end
        else if (tick) begin
            // Pulso corto de enable
            en <= 0;

            case (state)

                INIT0:        begin rs<=0; rw<=0; data<=8'h38; state<=INIT0_EN; end
                INIT0_EN:     begin en<=1; state<=INIT1; end

                INIT1:        begin rs<=0; rw<=0; data<=8'h0C; state<=INIT1_EN; end
                INIT1_EN:     begin en<=1; state<=INIT2; end

                INIT2:        begin rs<=0; rw<=0; data<=8'h06; state<=INIT2_EN; end
                INIT2_EN:     begin en<=1; state<=CLEAR; end

                CLEAR:        begin rs<=0; rw<=0; data<=8'h01; state<=CLEAR_EN; end
                CLEAR_EN:     begin en<=1; state<=SET_LINE1; end

                SET_LINE1:    begin rs<=0; rw<=0; data<=8'h88; state<=SET_LINE1_EN; end
                SET_LINE1_EN: begin en<=1; state<=WRITE_H_D; end

                WRITE_H_D:    begin rs<=1; rw<=0; data<=ascii(hour / 10); state<=WRITE_H_D_EN; end
                WRITE_H_D_EN: begin en<=1; state<=WRITE_H_U; end

                WRITE_H_U:    begin rs<=1; rw<=0; data<=ascii(hour % 10); state<=WRITE_H_U_EN; end
                WRITE_H_U_EN: begin en<=1; state<=WRITE_COL1; end

                WRITE_COL1:   begin rs<=1; rw<=0; data<=8'h3A; state<=WRITE_COL1_EN; end // ':'
                WRITE_COL1_EN:begin en<=1; state<=WRITE_M_D; end

                WRITE_M_D:    begin rs<=1; rw<=0; data<=ascii(min / 10); state<=WRITE_M_D_EN; end
                WRITE_M_D_EN: begin en<=1; state<=WRITE_M_U; end

                WRITE_M_U:    begin rs<=1; rw<=0; data<=ascii(min % 10); state<=WRITE_M_U_EN; end
                WRITE_M_U_EN: begin en<=1; state<=WRITE_COL2; end

                WRITE_COL2:   begin rs<=1; rw<=0; data<=8'h3A; state<=WRITE_COL2_EN; end // ':'
                WRITE_COL2_EN:begin en<=1; state<=WRITE_S_D; end

                WRITE_S_D:    begin rs<=1; rw<=0; data<=ascii(sec / 10); state<=WRITE_S_D_EN; end
                WRITE_S_D_EN: begin en<=1; state<=WRITE_S_U; end

                WRITE_S_U:    begin rs<=1; rw<=0; data<=ascii(sec % 10); state<=WRITE_S_U_EN; end
                WRITE_S_U_EN: begin en<=1; state<=SET_LINE1; end // Loop again

                default: state <= INIT0;

            endcase
        end else begin
            en <= 0; // en bajo fuera del tick
        end
    end

endmodule
