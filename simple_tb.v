
`timescale 1ns/1ps
 
module tb_ibex_demo_system;
 
  reg clk_i;
  reg rst_ni;
  wire soc_tx;
 
  // 1. Instantiate the REAL hardware top-level
  ibex_demo_system dut (
    .clk_sys_i  (clk_i),
    .rst_sys_ni (rst_ni),
    .uart_tx_o  (soc_tx), // Directly grab the UART TX port!
 
    // Tie off unused inputs to prevent 'Z' states
    .uart_rx_i  (1'b1),
    .uart2_rx_i (1'b1),
    .spi_rx_i   (1'b0),
    .xip_spi_miso_i (1'b0),
    .i2c_scl_i  (1'b1),
    .i2c_sda_i  (1'b1),
    .tck_i      (1'b0),
    .tms_i      (1'b0),
    .trst_ni    (1'b1),
    .td_i       (1'b0),
    .gp_i       (8'b0)
  );
 
  // 2. Clock (20MHz)
  initial begin
    clk_i = 0;
    forever #25 clk_i = ~clk_i;
  end
 
  // 3. Memory Injection & Reset Sequence
  reg [1023:0] mem_file;
  initial begin
    rst_ni = 0;
 
    if ($value$plusargs("MEMINIT=%s", mem_file)) begin
      $display("[TB] Loading memory from %s...", mem_file);
      // Corrected path: bypassing top_verilator
      $readmemh(mem_file, dut.u_wrapper.u_dffram.mem);
    end else begin
      $display("[TB] WARNING: No memory file provided. Use +MEMINIT=<file.vmem>");
    end
 
    #100;
    rst_ni = 1;
    $display("[TB] Reset released. Processor booting...");
  end
 
  // 4. Pure Verilog UART Decoder (115200 Baud)
  parameter BIT_PERIOD = 8681;
  reg [7:0] rx_byte;
  integer i;
 
  initial begin
    forever begin
      @(negedge soc_tx);
      #(BIT_PERIOD / 2);
      if (soc_tx == 0) begin
        #(BIT_PERIOD);
        for (i = 0; i < 8; i = i + 1) begin
          rx_byte[i] = soc_tx;
          #(BIT_PERIOD);
        end
        $write("%c", rx_byte);
      end
    end
  end
 
  // 5. Timeout Guard
  initial begin
    $dumpfile("wave.vcd");
    $dumpvars(0, tb_ibex_demo_system);
 
    #30000000;
    $display("\n[TB] 30ms Simulation timeout reached. Exiting cleanly.");
    $finish;
  end
 
endmodule
