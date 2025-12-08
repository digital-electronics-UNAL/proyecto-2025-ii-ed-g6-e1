module LCD1602_controller #(parameter NUM_COMMANDS = 4, 
                                      NUM_DATA_ALL = 32,  
                                      NUM_DATA_PERLINE = 16,
                                      DATA_BITS = 8,
                                      COUNT_MAX = 800000)(
    input clk,            
    input reset,          
    input ready_i,
    input [3:0] in1,    
    input [3:0] in2,    
    output reg rs,       
    output reg rw,
    output enable,    
    output reg [DATA_BITS-1:0] data
);

// ======================== ESTADOS ===========================
localparam IDLE = 3'b000;
localparam CONFIG_CMD1 = 3'b001;
localparam WR_STATIC_TEXT_1L = 3'b010;
localparam CONFIG_CMD2 = 3'b011;
localparam WR_STATIC_TEXT_2L = 3'b100;
localparam WRITE_DYNAMIC_TEXT = 3'b101;

// Subestados dinámicos
localparam SET_CURSOR = 2'b00;
localparam WRITE_CHAR = 2'b01;

reg [2:0] fsm_state;
reg [2:0] next_state;
reg clk_16ms;

reg [1:0] sel_dynamic_state;
reg sel_use_cursor;

// ======================== COMANDOS ============================
localparam CLEAR_DISPLAY = 8'h01;
localparam SHIFT_CURSOR_RIGHT = 8'h06;
localparam DISPON_CURSOROFF = 8'h0C;
localparam DISPON_CURSORBLINK = 8'h0E;
localparam LINES2_MATRIX5x8_MODE8bit = 8'h38;
localparam START_2LINE = 8'hC0;

// ======================== CONTADORES ==========================
reg [$clog2(COUNT_MAX)-1:0] clk_counter;
reg [$clog2(NUM_COMMANDS):0] command_counter;
reg [$clog2(NUM_DATA_PERLINE):0] data_counter;

// ======================== MEMORIAS ============================
reg [DATA_BITS-1:0] static_data_mem [0: NUM_DATA_ALL-1];
reg [DATA_BITS-1:0] config_mem [0:NUM_COMMANDS-1]; 
reg [DATA_BITS-1:0] cursor_data [0:1];

// Texto dinámico
reg [7:0] dynamic_text[0:7];
reg [2:0] text_index;

// ======================== INIT ================================
initial begin
    fsm_state <= IDLE;

    cursor_data[0] <= 8'h80 + 8'h05;  // Línea 1 (no la usamos)
    cursor_data[1] <= 8'hC0 + 8'h07;  // Línea 2 posición dinámico

    sel_dynamic_state <= SET_CURSOR;
    sel_use_cursor <= 1;  // SIEMPRE la segunda línea

    command_counter <= 0;
    data_counter <= 0;

    rs <= 0;
    rw <= 0;
    data <= 0;

    clk_16ms <= 0;
    clk_counter <= 0;

    $readmemh("/home/sebastian/Documentos/DIGITAL/lab4/data.txt", static_data_mem);

    config_mem[0] <= LINES2_MATRIX5x8_MODE8bit;
    config_mem[1] <= SHIFT_CURSOR_RIGHT;
    config_mem[2] <= DISPON_CURSOROFF;
    config_mem[3] <= CLEAR_DISPLAY;
end


// ===================== DIVISOR ============================
always @(posedge clk) begin
    if (clk_counter == COUNT_MAX-1) begin
        clk_16ms <= ~clk_16ms;
        clk_counter <= 0;
    end else begin
        clk_counter <= clk_counter + 1;
    end
end


// ===================== FSM PRINCIPAL ============================
always @(posedge clk_16ms) begin
    if (!reset)
        fsm_state <= IDLE;
    else
        fsm_state <= next_state;
end

always @(*) begin
    case(fsm_state)
        IDLE:             next_state = (ready_i) ? CONFIG_CMD1 : IDLE;
        CONFIG_CMD1:      next_state = (command_counter == NUM_COMMANDS) ? WR_STATIC_TEXT_1L : CONFIG_CMD1;
        WR_STATIC_TEXT_1L:next_state = (data_counter == NUM_DATA_PERLINE) ? CONFIG_CMD2 : WR_STATIC_TEXT_1L;
        CONFIG_CMD2:      next_state = WR_STATIC_TEXT_2L;
        WR_STATIC_TEXT_2L:next_state = (data_counter == NUM_DATA_PERLINE) ? WRITE_DYNAMIC_TEXT : WR_STATIC_TEXT_2L;
        default:          next_state = WRITE_DYNAMIC_TEXT;
    endcase
end


// ===================== ACCIONES ============================
always @(posedge clk_16ms) begin
    if (!reset) begin
        command_counter <= 0;
        data_counter <= 0;
        data <= 0;
    end else begin
        case (next_state)

            IDLE: begin
                command_counter <= 0;
                data_counter <= 0;
                rs <= 0;
                data <= 0;
            end

            CONFIG_CMD1: begin
                rs <= 0;
                data <= config_mem[command_counter];
                command_counter <= command_counter + 1;
            end

            WR_STATIC_TEXT_1L: begin
                rs <= 1;
                data <= static_data_mem[data_counter];
                data_counter <= data_counter + 1;
            end

            CONFIG_CMD2: begin
                data_counter <= 0;
                rs <= 0;
                data <= START_2LINE;
            end

            WR_STATIC_TEXT_2L: begin
                rs <= 1;
                data <= static_data_mem[NUM_DATA_PERLINE + data_counter];
                data_counter <= data_counter + 1;

                sel_dynamic_state <= SET_CURSOR;
                sel_use_cursor <= 1;   // SIEMPRE segunda línea
            end

            WRITE_DYNAMIC_TEXT: begin
                case (sel_dynamic_state)

                    SET_CURSOR: begin
                        rs <= 0;
                        data <= cursor_data[1];  
                        text_index <= 0;
                        sel_dynamic_state <= WRITE_CHAR;
                    end

                    WRITE_CHAR: begin
                        rs <= 1;
                        data <= dynamic_text[text_index];

                        if (text_index == 7) begin
                            sel_dynamic_state <= SET_CURSOR;
                        end else begin
                            text_index <= text_index + 1;
                        end
                    end

                endcase
            end

        endcase
    end
end


// ===================== ACTUALIZAR TEXTO DINÁMICO ============================
always @(posedge clk) begin
    if (!reset) begin
        dynamic_text[0] <= " ";
        dynamic_text[1] <= " ";
        dynamic_text[2] <= " ";
        dynamic_text[3] <= " ";
        dynamic_text[4] <= " ";
        dynamic_text[5] <= " ";
        dynamic_text[6] <= " ";
        dynamic_text[7] <= " ";
    end 
    else begin
        if (in2[0]) begin  
            // === TEXTO: "OKAY"
            dynamic_text[0] <= "O";
            dynamic_text[1] <= "K";
            dynamic_text[2] <= "A";
            dynamic_text[3] <= "Y";
            dynamic_text[4] <= " ";
            dynamic_text[5] <= " ";
            dynamic_text[6] <= " ";
            dynamic_text[7] <= " ";
        end 
        else begin
            // === TEXTO: "LLENAR!"
            dynamic_text[0] <= "L";
            dynamic_text[1] <= "L";
            dynamic_text[2] <= "E";
            dynamic_text[3] <= "N";
            dynamic_text[4] <= "A";
            dynamic_text[5] <= "R";
            dynamic_text[6] <= "!";
            dynamic_text[7] <= " ";
        end
    end
end


assign enable = clk_16ms;

endmodule
