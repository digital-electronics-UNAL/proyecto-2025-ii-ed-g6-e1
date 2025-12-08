module ultrasonic_controller #(
    parameter TIME_TRIG   = 500
)(
    input  wire        clk,
    input  wire        rst,       
    input  wire        ready_i,
    input  wire        echo_i,
    output wire        trigger_o,
    output reg  [31:0] echo_counter
);

    localparam IDLE       = 2'b00;
    localparam TRIGGER    = 2'b01;
    localparam WAIT_ECHO  = 2'b10;
    localparam COUNT_ECHO = 2'b11;

    reg [1:0] state;
    reg [1:0] next_state;

    reg echo_meta,  echo_sync;
    reg ready_meta, ready_sync;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            echo_meta  <= 1'b0;
            echo_sync  <= 1'b0;
            ready_meta <= 1'b0;
            ready_sync <= 1'b0;
        end else begin
            echo_meta  <= echo_i;
            echo_sync  <= echo_meta;
            ready_meta <= ready_i;
            ready_sync <= ready_meta;
        end
    end

    localparam TRIG_CNT_WIDTH = $clog2(TIME_TRIG);
    reg [TRIG_CNT_WIDTH-1:0] trig_counter;
    wire trig_done;

    assign trig_done = (trig_counter == TIME_TRIG-1);

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            trig_counter <= {TRIG_CNT_WIDTH{1'b0}};
        end else begin
            case (state)
                IDLE: begin
                    trig_counter <= {TRIG_CNT_WIDTH{1'b0}};
                end
                TRIGGER: begin
                    trig_counter <= trig_counter + 1'b1;
                end
                default: begin
                    trig_counter <= trig_counter;
                end
            endcase
        end
    end

    reg [31:0] echo_counter_int;

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            echo_counter_int <= 32'd0;
            echo_counter     <= 32'd0;
        end else begin
            case (state)
                WAIT_ECHO: begin
                    echo_counter_int <= 32'd0;
                end
                COUNT_ECHO: begin
                    echo_counter_int <= echo_counter_int + 1'b1;
                end
                default: begin
                    echo_counter_int <= echo_counter_int;
                end
            endcase

            if (state == COUNT_ECHO && next_state == IDLE) begin
                echo_counter <= echo_counter_int;
            end else begin
                echo_counter <= echo_counter;
            end
        end
    end

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state <= IDLE;
        end else begin
            state <= next_state;
        end
    end

    always @(*) begin
        case (state)
            IDLE: begin
                if (ready_sync)
                    next_state = TRIGGER;
                else
                    next_state = IDLE;
            end
            TRIGGER: begin
                if (trig_done)
                    next_state = WAIT_ECHO;
                else
                    next_state = TRIGGER;
            end
            WAIT_ECHO: begin
                if (echo_sync)
                    next_state = COUNT_ECHO;
                else
                    next_state = WAIT_ECHO;
            end
            COUNT_ECHO: begin
                if (echo_sync)
                    next_state = COUNT_ECHO;
                else
                    next_state = IDLE;
            end
            default: begin
                next_state = IDLE;
            end
        endcase
    end

    assign trigger_o = (state == TRIGGER);

endmodule