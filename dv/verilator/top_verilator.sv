// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

// This is the top level that connects the demo system to the virtual devices.
module top_verilator (
    input logic clk_i,
    input logic rst_ni,
    
    output logic xip_spi_sck_o,
    output logic xip_spi_csn_o,
    output logic xip_spi_mosi_o,
    input  logic xip_spi_miso_i
    
    );

  localparam ClockFrequency = 50_000_000;
  localparam BaudRate       = 115_200;

  logic uart_sys_rx, uart_sys_tx;
  /*
  // XIP SPI interface
  logic xip_spi_sck;
  logic xip_spi_csn;
  logic xip_spi_mosi;
  logic xip_spi_miso;
 */
  // Instantiating the Ibex Demo System.
  ibex_demo_system #(
    .GpiWidth       ( 8                   ),
    .GpoWidth       ( 16                  ),
    .PwmWidth       ( 12                  ),
    .ClockFrequency ( ClockFrequency      ),
    .BaudRate       ( BaudRate            ),
    .RegFile        ( ibex_pkg::RegFileFF )
  ) u_ibex_demo_system (
    //Input
    .clk_sys_i (clk_i),
    .rst_sys_ni(rst_ni),
    .uart_rx_i (uart_sys_rx),

    //Output
    .uart_tx_o(uart_sys_tx),

    // tie off JTAG
    .trst_ni(1'b1),
    .tms_i  (1'b0),
    .tck_i  (1'b0),
    .td_i   (1'b0),
    .td_o   (    ),

    // Remaining IO
    .gp_i      (0),
    .gp_o      ( ),
    .pwm_o     ( ),
    .spi_rx_i  (0),
    .spi_tx_o  ( ),
    .spi_sck_o ( ),
    
    /*
        // XIP SPI interface
    .xip_spi_sck_o (xip_spi_sck),
    .xip_spi_csn_o (xip_spi_csn),
    .xip_spi_mosi_o(xip_spi_mosi),
    .xip_spi_miso_i(xip_spi_miso)
    */
    
    // XIP SPI interface
    .xip_spi_sck_o (xip_spi_sck_o),
    .xip_spi_csn_o (xip_spi_csn_o),
    .xip_spi_mosi_o(xip_spi_mosi_o),
    .xip_spi_miso_i(xip_spi_miso_i)
    
  );

  // Virtual UART
  uartdpi #(
    .BAUD(BaudRate),
    .FREQ(ClockFrequency)
  ) u_uartdpi (
    .clk_i,
    .rst_ni,
    .active (1'b1       ),
    .tx_o   (uart_sys_rx),
    .rx_i   (uart_sys_tx)
  );
endmodule
