module multi_alarm_parser (
    input  wire clk,
    input  wire rst,
    input  wire data_valid,
    input  wire [7:0] data,

    output reg  [4:0] hour1, hour2, hour3,
    output reg  [5:0] min1,  min2,  min3,
    output reg  [5:0] sec1,  sec2,  sec3,
    output reg        set1,  set2,  set3
);

    localparam P_IDLE = 0,
               P_H    = 1,
               P_NUM  = 2,
               P_COL0 = 3,
               P_HH1  = 4,
               P_HH2  = 5,
               P_COL1 = 6,
               P_MM1  = 7,
               P_MM2  = 8,
               P_COL2 = 9,
               P_SS1  = 10,
               P_SS2  = 11,
               P_END  = 12;

    reg [3:0] state = P_IDLE;
    reg [1:0] which;
    reg [7:0] hh, mm, ss;

    function [3:0] digit;
        input [7:0] c;
        if (c >= "0" && c <= "9") digit = c - "0";
        else digit = 0;
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            state <= P_IDLE;
            which <= 0;
            hh <= 0; mm <= 0; ss <= 0;
            set1 <= 0; set2 <= 0; set3 <= 0;
        end else begin
            set1 <= 0;
            set2 <= 0;
            set3 <= 0;

            if (data_valid) begin
                case (state)
                    P_IDLE: if (data == "H") state <= P_H;

                    P_H: begin
                        if (data == "1") begin which <= 1; state <= P_COL0; end
                        else if (data == "2") begin which <= 2; state <= P_COL0; end
                        else if (data == "3") begin which <= 3; state <= P_COL0; end
                        else state <= P_IDLE;
                    end

                    P_COL0: if (data == ":") state <= P_HH1; else state <= P_IDLE;

                    P_HH1: begin hh[7:4] <= digit(data); state <= P_HH2; end
                    P_HH2: begin hh[3:0] <= digit(data); state <= P_COL1; end

                    P_COL1: if (data == ":") state <= P_MM1; else state <= P_IDLE;

                    P_MM1: begin mm[7:4] <= digit(data); state <= P_MM2; end
                    P_MM2: begin mm[3:0] <= digit(data); state <= P_COL2; end

                    P_COL2: if (data == ":") state <= P_SS1; else state <= P_IDLE;

                    P_SS1: begin ss[7:4] <= digit(data); state <= P_SS2; end
                    P_SS2: begin ss[3:0] <= digit(data); state <= P_END; end

                    P_END: begin
                        if (data == "\n") begin
                            case (which)
                                1: begin hour1 <= hh[7:4]*10 + hh[3:0]; min1 <= mm[7:4]*10 + mm[3:0]; sec1 <= ss[7:4]*10 + ss[3:0]; set1 <= 1; end
                                2: begin hour2 <= hh[7:4]*10 + hh[3:0]; min2 <= mm[7:4]*10 + mm[3:0]; sec2 <= ss[7:4]*10 + ss[3:0]; set2 <= 1; end
                                3: begin hour3 <= hh[7:4]*10 + hh[3:0]; min3 <= mm[7:4]*10 + mm[3:0]; sec3 <= ss[7:4]*10 + ss[3:0]; set3 <= 1; end
                            endcase
                        end
                        state <= P_IDLE;
                    end
                endcase
            end
        end
    end
endmodule
