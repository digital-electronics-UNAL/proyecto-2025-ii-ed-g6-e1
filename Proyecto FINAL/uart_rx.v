module uart_rx #(
    parameter CLK_FREQ = 50000000,
    parameter BAUD     = 115200
)(
    input  wire clk,
    input  wire rst,
    input  wire rx,
    output reg  data_valid,
    output reg [7:0] data
);

    // Oversampling 16x
    localparam integer OVERSAMPLE = 16;
    localparam integer BAUD_TICK  = CLK_FREQ / (BAUD * OVERSAMPLE);

    reg [15:0] clk_cnt = 0;
    reg        sample_tick;

    // Tick generator
    always @(posedge clk) begin
        if (rst) begin
            clk_cnt <= 0;
            sample_tick <= 0;
        end else begin
            if (clk_cnt == BAUD_TICK-1) begin
                clk_cnt <= 0;
                sample_tick <= 1;
            end else begin
                clk_cnt <= clk_cnt + 1;
                sample_tick <= 0;
            end
        end
    end

    // FSM states (Verilog-2001 style)
    localparam IDLE  = 3'd0;
    localparam START = 3'd1;
    localparam DATA  = 3'd2;
    localparam STOP  = 3'd3;
    localparam DONE  = 3'd4;

    reg [2:0] state = IDLE;

    reg [3:0] sample_cnt = 0;  
    reg [3:0] bit_idx    = 0;
    reg [7:0] shreg      = 0;

    always @(posedge clk) begin
        if (rst) begin
            state      <= IDLE;
            data_valid <= 0;
            sample_cnt <= 0;
            bit_idx    <= 0;
        end else begin
            data_valid <= 0;

            case(state)

                //------------------------------------
                // IDLE: esperar start bit (rx = 0)
                //------------------------------------
                IDLE: begin
                    if (~rx) begin
                        state      <= START;
                        sample_cnt <= 0;
                    end
                end

                //------------------------------------
                // START: comprobar que rx sigue en 0
                //------------------------------------
                START: begin
                    if (sample_tick) begin
                        sample_cnt <= sample_cnt + 1;

                        if (sample_cnt == 8) begin
                            if (rx == 0)
                                state <= DATA;   // start válido
                            else
                                state <= IDLE;   // glitch
                            bit_idx <= 0;
                        end
                    end
                end

                //------------------------------------
                // DATA: capturar 8 bits
                //------------------------------------
                DATA: begin
                    if (sample_tick) begin
                        sample_cnt <= sample_cnt + 1;

                        if (sample_cnt == 8) begin
                            shreg[bit_idx] <= rx;
                            bit_idx <= bit_idx + 1;
                        end

                        if (sample_cnt == 15) begin
                            sample_cnt <= 0;
                            if (bit_idx == 8)
                                state <= STOP;
                        end
                    end
                end

                //------------------------------------
                // STOP: rx debe ser 1
                //------------------------------------
                STOP: begin
                    if (sample_tick) begin
                        sample_cnt <= sample_cnt + 1;

                        if (sample_cnt == 8) begin
                            if (rx == 1)
                                state <= DONE;
                            else
                                state <= IDLE; // framing error
                        end
                    end
                end

                //------------------------------------
                // DONE: entregar byte recibido
                //------------------------------------
                DONE: begin
                    data       <= shreg;
                    data_valid <= 1;
                    state      <= IDLE;
                end

            endcase
        end
    end
endmodule