`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: K SREE SAI VENKAT
// 
// Create Date: 28.03.2026 16:31:27
// Design Name: 
// Module Name: tb_Configurable_Decimator
// Project Name: RADAR_RX
// Target Devices: MPSoC (xczu15eg-ffvc900-2-i)
// Tool Versions: 2024.2
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_Configurable_Decimator;
    
    reg         clk            ;
    reg         fir_rst        ;
    reg  [31:0] Rx_data        ;
    reg         Rx_ttl         ;
    reg  [ 1:0] decimation_rate;
    wire [15:0] decimator_i    ;
    wire [15:0] decimator_q    ;
    wire        decimator_v    ;
    
Configurable_Decimator inst
(
    .clk             (clk	     	 ),
    .fir_rst         (fir_rst	     ),
    .Rx_data         (Rx_data	     ),
    .Rx_ttl          (Rx_ttl	     ),
    .decimation_rate (decimation_rate),
    .decimator_i     (decimator_i    ),
    .decimator_q     (decimator_q    ),
    .decimator_v     (decimator_v    )
);

always #5 clk = ~clk;	//100MHz clock

initial begin
    clk   			= 0;
	decimation_rate	= 2'd3;
    fir_rst   		= 1;
    #100;
    fir_rst 		= 0;
end

    
endmodule