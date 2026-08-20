// ============================================================================
// Behavioral SPI NOR flash model (read-only, command 0x03) for XIP simulation.
//
// Models the subset of a standard SPI NOR flash (e.g. the Arty A7's onboard
// 16 MB S25FL128) that the SoC's spi_flash_xip controller uses:
//   * SPI Mode 0 (CPOL=0, CPHA=0): samples MOSI on rising SCK, drives MISO
//     on falling SCK (and immediately after CS falls, for the first bit)
//   * Command 0x03 (READ) + 24-bit address, then streams data bytes MSB-first
//     with auto-incrementing address until CS rises
//   * Any other command: drives 1'bx and complains (catches controller bugs)
//
// Backing store: a WINDOW_BYTES window starting at flash byte offset
// BASE_OFFSET, initialised from a word-vmem file (little-endian: word[i]
// bits [7:0] = flash byte BASE_OFFSET + 4*i). Reads outside the window
// return 8'hFF like blank flash, with a warning.
//
// BASE_OFFSET defaults to 0x0040_0000 — mirroring the hardware layout where
// firmware lives behind the ~3.7 MB A7-100T bitstream in the config flash.
// ============================================================================

/*`timescale 1ns / 1ps

module spi_nor_flash_model #(
  parameter int          WINDOW_BYTES = 65536,
  parameter logic [23:0] BASE_OFFSET  = 24'h40_0000,
  parameter              INIT_FILE    = ""
)(
  input  logic sck,
  input  logic csn,
  input  logic mosi,
  output logic miso
);

  logic [7:0] mem [0:WINDOW_BYTES-1];

  initial begin
    logic [31:0] words [0:WINDOW_BYTES/4-1];
    for (int i = 0; i < WINDOW_BYTES; i++) mem[i] = 8'hFF;
    if (INIT_FILE != "") begin
      for (int i = 0; i < WINDOW_BYTES/4; i++) words[i] = 32'hFFFF_FFFF;
      $readmemh(INIT_FILE, words);
      for (int i = 0; i < WINDOW_BYTES/4; i++) begin
        mem[4*i + 0] = words[i][7:0];
        mem[4*i + 1] = words[i][15:8];
        mem[4*i + 2] = words[i][23:16];
        mem[4*i + 3] = words[i][31:24];
      end
      $display("spi_nor_flash_model: loaded '%s' at flash offset 0x%06h",
               INIT_FILE, BASE_OFFSET);
    end
  end

  // ---- bit-level protocol engine -------------------------------------------
  logic [7:0]  cmd_q;
  logic [23:0] addr_q;
  logic [7:0]  dout_q;
  int          bit_cnt;

  typedef enum int { F_CMD, F_ADDR, F_DATA, F_DEAD } fstate_e;
  fstate_e fstate;

  function automatic logic [7:0] flash_byte(logic [23:0] a);
    if (a >= BASE_OFFSET && a < BASE_OFFSET + WINDOW_BYTES)
      return mem[a - BASE_OFFSET];
    $display("[%0t] spi_nor_flash_model: WARNING read outside window (0x%06h)",
             $time, a);
    return 8'hFF;
  endfunction

  always @(negedge csn) begin
    fstate  = F_CMD;
    bit_cnt = 0;
    cmd_q   = '0;
    addr_q  = '0;
  end

  // Sample MOSI on rising SCK
  always @(posedge sck) begin
    if (!csn) begin
      case (fstate)
        F_CMD: begin
          cmd_q = {cmd_q[6:0], mosi};
          bit_cnt++;
          if (bit_cnt == 8) begin
            if (cmd_q == 8'h03) begin
              fstate  = F_ADDR;
              bit_cnt = 0;
            end else begin
              $display("[%0t] spi_nor_flash_model: unsupported cmd 0x%02h",
                       $time, cmd_q);
              fstate = F_DEAD;
            end
          end
        end
        F_ADDR: begin
          addr_q = {addr_q[22:0], mosi};
          bit_cnt++;
          if (bit_cnt == 24) begin
            fstate  = F_DATA;
            bit_cnt = 0;
          end
        end
        default: ;
      endcase
    end
  end

  // Drive MISO on falling SCK (shift out MSB-first). Mode 0: data changes on
  // the falling edge and is stable across the next rising (sampling) edge.
  // bit_cnt%8 == 0 marks a byte boundary: load a fresh byte and present its
  // MSB; otherwise shift. The address increments as each byte is consumed.
  always @(negedge sck) begin
    if (!csn && fstate == F_DATA) begin
      if (bit_cnt % 8 == 0) begin
        dout_q = flash_byte(addr_q);
        addr_q = addr_q + 24'd1;
      end else begin
        dout_q = {dout_q[6:0], 1'b0};
      end
      bit_cnt++;
    end
  end

  assign miso = (!csn && fstate == F_DATA) ? dout_q[7] :
                (!csn && fstate == F_DEAD) ? 1'bx     : 1'bz;

endmodule*/

`timescale 1ns / 1ps

module spi_nor_flash_model #(
  parameter int          WINDOW_BYTES = 65536,
  parameter logic [23:0] BASE_OFFSET  = 24'h40_0000,
  parameter              INIT_FILE    = ""
)(
  input  logic sck,
  input  logic csn,
  input  logic mosi,
  output logic miso
);

  // ==========================================================================
  // Flash memory
  // ==========================================================================

  logic [7:0] mem [0:WINDOW_BYTES-1];

  initial begin
    logic [31:0] words [0:WINDOW_BYTES/4-1];

    // Default erased state.
    for (int i = 0; i < WINDOW_BYTES; i++) begin
      mem[i] = 8'hFF;
    end

    // Load firmware image if provided.
    if (INIT_FILE != "") begin

      for (int i = 0; i < WINDOW_BYTES/4; i++) begin
        words[i] = 32'hFFFF_FFFF;
      end

      $readmemh(INIT_FILE, words);

      // Store VMEM words in little-endian byte order.
      for (int i = 0; i < WINDOW_BYTES/4; i++) begin
        mem[4*i + 0] = words[i][7:0];
        mem[4*i + 1] = words[i][15:8];
        mem[4*i + 2] = words[i][23:16];
        mem[4*i + 3] = words[i][31:24];
      end

      $display(
        "spi_nor_flash_model: loaded '%s' at flash offset 0x%06h",
        INIT_FILE,
        BASE_OFFSET
      );
    end
  end


  // ==========================================================================
  // SPI protocol state
  // ==========================================================================

  logic [7:0]  cmd_q;
  logic [23:0] addr_q;
  logic [7:0]  dout_q;

  logic [4:0]  rx_bit_cnt;
  logic [2:0]  tx_bit_cnt;

  typedef enum int {
    F_CMD,
    F_ADDR,
    F_DATA,
    F_DEAD
  } fstate_e;

  fstate_e fstate;


  // ==========================================================================
  // Flash byte lookup
  //
  // Explicit 32-bit arithmetic avoids Verilator width warnings.
  // ==========================================================================

  function automatic logic [7:0] flash_byte(
    input logic [23:0] a
  );

    logic [31:0] a_ext;
    logic [31:0] base_ext;
    logic [31:0] window_ext;
    logic [31:0] window_end;
    logic [31:0] mem_idx;

    a_ext      = {8'h00, a};
    base_ext   = {8'h00, BASE_OFFSET};
    window_ext = WINDOW_BYTES;
    window_end = base_ext + window_ext;
    mem_idx    = a_ext - base_ext;

    if ((a_ext >= base_ext) &&
        (a_ext < window_end)) begin
      return mem[mem_idx];
    end

    return 8'hFF;

  endfunction


  // ==========================================================================
  // SPI behavioral protocol engine
  //
  // This is a simulation-only SPI NOR model.
  //
  // The protocol state is intentionally updated from:
  //
  //   - CSN falling edge
  //   - SCK rising edge
  //   - SCK falling edge
  //
  // Therefore MULTIDRIVEN and BLKSEQ are disabled locally.
  // ==========================================================================

  // verilator lint_off MULTIDRIVEN
  // verilator lint_off BLKSEQ


  // ==========================================================================
  // Chip-select falling edge
  // ==========================================================================

  always @(negedge csn) begin

    fstate     = F_CMD;
    rx_bit_cnt = 5'd0;
    tx_bit_cnt = 3'd0;

    cmd_q      = 8'h00;
    addr_q     = 24'h000000;
    dout_q     = 8'h00;

  end


  // ==========================================================================
  // Rising SCK
  //
  // SPI Mode 0:
  // Rising edge samples MOSI.
  // ==========================================================================

  always @(posedge sck) begin

    if (!csn) begin

      case (fstate)

        // --------------------------------------------------------------------
        // Command phase
        // --------------------------------------------------------------------

        F_CMD: begin

          cmd_q      = {cmd_q[6:0], mosi};
          rx_bit_cnt = rx_bit_cnt + 5'd1;

          if (rx_bit_cnt == 5'd8) begin

            if (cmd_q == 8'h03) begin
              fstate     = F_ADDR;
              rx_bit_cnt = 5'd0;
            end
            else begin
              fstate = F_DEAD;
            end

          end

        end


        // --------------------------------------------------------------------
        // 24-bit address phase
        // --------------------------------------------------------------------

        F_ADDR: begin

          addr_q     = {addr_q[22:0], mosi};
          rx_bit_cnt = rx_bit_cnt + 5'd1;

          if (rx_bit_cnt == 5'd24) begin
            fstate     = F_DATA;
            rx_bit_cnt = 5'd0;
            tx_bit_cnt = 3'd0;
          end

        end


        // --------------------------------------------------------------------
        // Data phase
        // --------------------------------------------------------------------

        F_DATA: begin
          // No MOSI processing during READ.
        end


        // --------------------------------------------------------------------
        // Unsupported command
        // --------------------------------------------------------------------

        F_DEAD: begin
          // Ignore the remainder of the transaction.
        end


        default: begin
          fstate = F_DEAD;
        end

      endcase

    end

  end


  // ==========================================================================
  // Falling SCK
  //
  // SPI Mode 0:
  // Falling edge changes MISO.
  // ==========================================================================

  always @(negedge sck) begin

    if (!csn && fstate == F_DATA) begin

      // ----------------------------------------------------------------------
      // Start of a new byte.
      // ----------------------------------------------------------------------

      if (tx_bit_cnt == 3'd0) begin

        dout_q     = flash_byte(addr_q);
        addr_q     = addr_q + 24'd1;
        tx_bit_cnt = 3'd1;

      end


      // ----------------------------------------------------------------------
      // Last bit of current byte.
      // ----------------------------------------------------------------------

      else if (tx_bit_cnt == 3'd7) begin

        dout_q     = {dout_q[6:0], 1'b0};
        tx_bit_cnt = 3'd0;

      end


      // ----------------------------------------------------------------------
      // Middle of current byte.
      // ----------------------------------------------------------------------

      else begin

        dout_q     = {dout_q[6:0], 1'b0};
        tx_bit_cnt = tx_bit_cnt + 3'd1;

      end

    end

  end


  // ==========================================================================
  // MISO output
  // ==========================================================================

  assign miso =
      (!csn && fstate == F_DATA) ? dout_q[7] :
      (!csn && fstate == F_DEAD) ? 1'bx :
                                    1'bz;


  // verilator lint_on BLKSEQ
  // verilator lint_on MULTIDRIVEN

endmodule
