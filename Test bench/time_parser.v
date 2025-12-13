module time_parser (
    input  wire clk,
    input  wire rst,
    input  wire data_valid,
    input  wire [7:0] data,

    output reg  [4:0] hour,
    output reg  [5:0] min,
    output reg  [5:0] sec,
    output reg        synced
);

    localparam P_IDLE = 0,
               P_T    = 1,
               P_COL1 = 2,
               P_HH1  = 3,
               P_HH2  = 4,
               P_COL2 = 5,
               P_MM1  = 6,
               P_MM2  = 7,
               P_COL3 = 8,
               P_SS1  = 9,
               P_SS2  = 10,
               P_END  = 11;

    reg [3:0] state = P_IDLE;

    reg [7:0] hh, mm, ss;

    function [3:0] digit;
        input [7:0] c;
        if (c >= "0" && c <= "9")
            digit = c - "0";
        else
            digit = 0;
    endfunction

    always @(posedge clk) begin
        if (rst) begin
            state  <= P_IDLE;
            synced <= 0;
            hh <= 0;
            mm <= 0;
            ss <= 0;
        end else begin
            synced <= 0;

            if (data_valid) begin
                case (state)

                    P_IDLE: begin
                        hh <= 0; mm <= 0; ss <= 0;
                        if (data == "T") state <= P_T;
                    end

                    P_T:    if (data == ":") state <= P_HH1;
                             else state <= P_IDLE;

                    P_HH1:  begin hh[7:4] <= digit(data); state <= P_HH2; end
                    P_HH2:  begin hh[3:0] <= digit(data); state <= P_COL1; end

                    P_COL1: if (data == ":") state <= P_MM1;
                             else state <= P_IDLE;

                    P_MM1:  begin mm[7:4] <= digit(data); state <= P_MM2; end
                    P_MM2:  begin mm[3:0] <= digit(data); state <= P_COL2; end

                    P_COL2: if (data == ":") state <= P_SS1;
                             else state <= P_IDLE;

                    P_SS1:  begin ss[7:4] <= digit(data); state <= P_SS2; end
                    P_SS2:  begin ss[3:0] <= digit(data); state <= P_END; end

                    P_END: begin
                        if (data == "\n") begin
                            hour   <= hh[7:4]*10 + hh[3:0];
                            min    <= mm[7:4]*10 + mm[3:0];
                            sec    <= ss[7:4]*10 + ss[3:0];
                            synced <= 1;
                        end
                        state <= P_IDLE;
                    end

                endcase
            end
        end
    end

endmodule