module top_ultrasonic(
    input  wire clk,
    input  wire rst,
    input  wire echo_i,
    output wire trigger_o,
	 //output [31:0] echo_out,
    output wire led_o
);

    wire [31:0] echo_counter;
    reg  led_reg;

    ultrasonic_controller ultrasonic0 (
        .clk(clk),
        .rst(rst),
        .ready_i(1'b1),
        .echo_i(echo_i),
        .trigger_o(trigger_o),
        .echo_counter(echo_counter)
    );

    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            led_reg <= 1'b1;
        end else begin
            if (echo_counter < 32'd50000)
                led_reg <= 1'b0;
            else
                led_reg <= 1'b1;
        end
    end
	 
	 //assign echo_out = echo_counter;

    assign led_o = led_reg;

endmodule
