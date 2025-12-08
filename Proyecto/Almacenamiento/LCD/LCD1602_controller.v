module LCD1602_controller #(parameter NUM_COMMANDS = 4, 
                                      NUM_DATA_ALL = 32,  
                                      NUM_DATA_PERLINE = 16,
                                      DATA_BITS = 8,
                                      COUNT_MAX = 800000)(
    input clk,            
    input reset,          
    input ready_i,
    input [3:0] in1,        // Línea 1 (AGUA)
    input [3:0] in2,        // Línea 2 (COMIDA)
    output reg rs,       
    output reg rw,
    output enable,    
    output reg [DATA_BITS-1:0] data
);

// ======================== ESTADOS ===========================
localparam IDLE               = 3'b000;
localparam CONFIG_CMD1        = 3'b001;
localparam WR_STATIC_TEXT_1L  = 3'b010;
localparam CONFIG_CMD2        = 3'b011;
localparam WR_STATIC_TEXT_2L  = 3'b100;
localparam WRITE_DYNAMIC_TEXT = 3'b101;

// Subestados dinámicos
localparam SET_CURSOR_1 = 2'b00;
localparam WRITE_CHARS_1 = 2'b01;
localparam SET_CURSOR_2 = 2'b10;
localparam WRITE_CHARS_2 = 2'b11;

reg [2:0] fsm_state;
reg [2:0] next_state;
reg clk_16ms;

reg [1:0] dyn_state;

// ======================== COMANDOS ============================
localparam CLEAR_DISPLAY            = 8'h01;
localparam SHIFT_CURSOR_RIGHT       = 8'h06;
localparam DISPON_CURSOROFF         = 8'h0C;
localparam LINES2_MATRIX5x8_MODE8bit = 8'h38;
localparam START_2LINE              = 8'hC0;

// ======================== CONTADORES ==========================
reg [$clog2(COUNT_MAX)-1:0] clk_counter;
reg [$clog2(NUM_COMMANDS):0] command_counter;
reg [$clog2(NUM_DATA_PERLINE):0] data_counter;

// ======================== MEMORIAS ============================
reg [7:0] static_data_mem [0: NUM_DATA_ALL-1];
reg [7:0] config_mem [0:NUM_COMMANDS-1];
reg [7:0] cursor_data [0:1];     // 0 = línea 1, 1 = línea 2

// Texto dinámico
reg [7:0] dynamic_text_1[0:7];   // AGUA
reg [7:0] dynamic_text_2[0:7];   // COMIDA

reg [2:0] text_index;

// ======================== INIT ================================
initial begin
    fsm_state <= IDLE;

    // Línea 1: "AGUA:" → después de la posición 5
    cursor_data[0] <= 8'h80 + 8'h05;

    // Línea 2: "COMIDA:" → posición 7
    cursor_data[1] <= 8'hC0 + 8'h07;

    dyn_state <= SET_CURSOR_1;

    command_counter <= 0;
    data_counter <= 0;
    rs <= 0;
    rw <= 0;
    data <= 0;

    clk_16ms <= 0;
    clk_counter <= 0;

    // Cargar texto estático desde archivo
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

assign enable = clk_16ms;

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

                dyn_state <= SET_CURSOR_1;
            end

            WRITE_DYNAMIC_TEXT: begin
                case (dyn_state)

                    // ---------------- LINEA 1 ----------------
                    SET_CURSOR_1: begin
                        rs <= 0;
                        data <= cursor_data[0];
                        text_index <= 0;
                        dyn_state <= WRITE_CHARS_1;
                    end

                    WRITE_CHARS_1: begin
                        rs <= 1;
                        data <= dynamic_text_1[text_index];

                        if (text_index == 7)
                            dyn_state <= SET_CURSOR_2;
                        else
                            text_index <= text_index + 1;
                    end

                    // ---------------- LINEA 2 ----------------
                    SET_CURSOR_2: begin
                        rs <= 0;
                        data <= cursor_data[1];
                        text_index <= 0;
                        dyn_state <= WRITE_CHARS_2;
                    end

                    WRITE_CHARS_2: begin
                        rs <= 1;
                        data <= dynamic_text_2[text_index];

                        if (text_index == 7)
                            dyn_state <= SET_CURSOR_1;   // vuelve a la línea 1
                        else
                            text_index <= text_index + 1;
                    end

                endcase
            end

        endcase
    end
end


// ===================== ACTUALIZAR TEXTO DINÁMICO ============================
always @(posedge clk) begin
    if (!reset) begin
        dynamic_text_1[0] <= " "; dynamic_text_1[1] <= " "; dynamic_text_1[2] <= " ";
        dynamic_text_1[3] <= " "; dynamic_text_1[4] <= " "; dynamic_text_1[5] <= " ";
        dynamic_text_1[6] <= " "; dynamic_text_1[7] <= " ";

        dynamic_text_2[0] <= " "; dynamic_text_2[1] <= " "; dynamic_text_2[2] <= " ";
        dynamic_text_2[3] <= " "; dynamic_text_2[4] <= " "; dynamic_text_2[5] <= " ";
        dynamic_text_2[6] <= " "; dynamic_text_2[7] <= " ";
    end 
    else begin
        // ========== Línea 1: AGUA ==========
        if (in1[0]) begin
            dynamic_text_1[0] <= "O"; dynamic_text_1[1] <= "K"; dynamic_text_1[2] <= "A"; dynamic_text_1[3] <= "Y";
            dynamic_text_1[4] <= " "; dynamic_text_1[5] <= " "; dynamic_text_1[6] <= " "; dynamic_text_1[7] <= " ";
        end else begin
            dynamic_text_1[0] <= "L"; dynamic_text_1[1] <= "L"; dynamic_text_1[2] <= "E"; dynamic_text_1[3] <= "N";
            dynamic_text_1[4] <= "A"; dynamic_text_1[5] <= "R"; dynamic_text_1[6] <= "!"; dynamic_text_1[7] <= " ";
        end

        // ========== Línea 2: COMIDA ==========
        if (in2[0]) begin
            dynamic_text_2[0] <= "O"; dynamic_text_2[1] <= "K"; dynamic_text_2[2] <= "A"; dynamic_text_2[3] <= "Y";
            dynamic_text_2[4] <= " "; dynamic_text_2[5] <= " "; dynamic_text_2[6] <= " "; dynamic_text_2[7] <= " ";
        end else begin
            dynamic_text_2[0] <= "L"; dynamic_text_2[1] <= "L"; dynamic_text_2[2] <= "E"; dynamic_text_2[3] <= "N";
            dynamic_text_2[4] <= "A"; dynamic_text_2[5] <= "R"; dynamic_text_2[6] <= "!"; dynamic_text_2[7] <= " ";
        end
    end
end

endmodule

