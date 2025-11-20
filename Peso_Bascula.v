`timescale 1ns/1ps
module Peso_Bascula (
    input wire clk, //clock de la fpga
    input wire S_sensor, //salida del sensor
    input wire reset, //botón para resetear a 0
    input wire [1:0] sel,       // Selector (0,1,2)


    output reg [23:0] lcd_data,
    output wire [7:0] info,
    output reg [6:0] SSeg
);

    wire [23:0] S_peso;  //salida para mostrar en lcd en formato hexa
    wire L_lista;   //nueva lectura disponible
    reg [23:0] U_valor;  //guarda el valor anterior
    reg [2:0] Coincidencias; //cuenta coincidencias seguidas


//instansias del driver
hx711_driver #(50_000_000,50_000)
I1( 
    .clk(clk),                 
    .rst_n(~reset),             
    .hx_dt(S_sensor),   
    .hx_sck(),                           
    .data_out(S_peso),       
    .data_ready(L_lista) 
); 

always @(posedge clk or negedge reset) begin    //Ejecuta el bloque cuando el reloj (clk) pasa de 0 → 1 o cuando el reset pasa de 1 → 0
    if (!reset) begin
            // Cuando reset = 1, el sistema se reinicia
            U_valor       <= 24'd0;
            Coincidencias <= 3'd0;
            lcd_data      <= 24'd0;
    end else if (L_lista) begin
            // Solo actúa cuando llega una nueva lectura del sensor

            if (S_peso == U_valor) begin
                // Si la lectura actual es igual a la anterior
                Coincidencias <= Coincidencias + 1;
            end else begin
                // Si cambió, reiniciamos el conteo
                Coincidencias <= 3'd1;
            end

            // Guardamos el valor actual
            U_valor <= S_peso;

            // Si ya se repitió 5 veces el mismo valor, se acepta
            if (Coincidencias == 3'd5) begin
                lcd_data <= S_peso;
            end
        end
    end

reg [7:0] byte_sel;

 always @(*) begin
        case (sel)
            2'd0: byte_sel = lcd_data[23:16];   // Más significativos
            2'd1: byte_sel = lcd_data[15:8];    // Intermedios
            2'd2: byte_sel = lcd_data[7:0];     // Menos significativos
        endcase
    end

assign info[0] = byte_sel[0];
assign info[1] = byte_sel[1];
assign info[2] = byte_sel[2];
assign info[3] = byte_sel[3];
assign info[4] = byte_sel[4];
assign info[5] = byte_sel[5];
assign info[6] = byte_sel[6];
assign info[7] = byte_sel[7];



  always @ ( * ) begin
    case (info[0])
      1'b0: SSeg = 7'b0000001; // "0"  
  	  1'b1: SSeg = 7'b1001111; // "1" 
       default: SSeg = 7'b0000000;
    endcase
	 case (info[1])
     1'b0: SSeg = 7'b0000001; // "0"  
  	  1'b1: SSeg = 7'b1001111; // "1" 
       default: SSeg = 7'b0000000;
    endcase
	 case (info[2])
      1'b0: SSeg = 7'b0000001; // "0"  
  	  1'b1: SSeg = 7'b1001111; // "1" 
       default: SSeg = 7'b0000000;
    endcase
	 case (info[3])
      1'b0: SSeg = 7'b0000001; // "0"  
  	  1'b1: SSeg = 7'b1001111; // "1" 
       default: SSeg = 7'b0000000;
    endcase
	 case (info[4])
      1'b0: SSeg = 7'b0000001; // "0"  
  	  1'b1: SSeg = 7'b1001111; // "1" 
       default: SSeg = 7'b0000000;
    endcase
	 case (info[5])
      1'b0: SSeg = 7'b0000001; // "0"  
  	  1'b1: SSeg = 7'b1001111; // "1" 
       default: SSeg = 7'b0000000;
    endcase
	 case (info[6])
      1'b0: SSeg = 7'b0000001; // "0"  
  	  1'b1: SSeg = 7'b1001111; // "1" 
       default: SSeg = 7'b0000000;
    endcase
	 case (info[7])
      1'b0: SSeg = 7'b0000001; // "0"  
  	  1'b1: SSeg = 7'b1001111; // "1" 
       default: SSeg = 7'b0000000;
    endcase
  end

endmodule