module relay_controller (
    input wire clk,
    input wire activate,       // Señal que indica si el relé debe activarse
    output reg relay_out       // Salida hacia el transistor
);

always @(posedge clk) begin
    relay_out <= activate;
end

endmodule
