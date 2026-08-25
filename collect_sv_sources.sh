#!/bin/bash
# collect_sv_sources.sh — gather all SV files for conversion

OUTDIR=verilog_out
mkdir -p $OUTDIR

# Packages and system defines (must be listed first for sv2v to resolve macros/types)
PKGS=(
  rtl/system/timescale.v
  rtl/system/i2c_master_defines.v
  vendor/lowrisc_ibex/rtl/ibex_pkg.sv
  vendor/lowrisc_ibex/dv/uvm/core_ibex/common/prim/prim_pkg.sv
  vendor/lowrisc_ip/ip/prim/rtl/prim_assert.sv
  vendor/lowrisc_ip/ip/prim/rtl/prim_util_pkg.sv
  vendor/lowrisc_ip/ip/prim/rtl/prim_ram_1p_pkg.sv
  vendor/lowrisc_ip/ip/prim/rtl/prim_secded_pkg.sv
  vendor/lowrisc_ibex/dv/uvm/core_ibex/common/prim/prim_buf.sv
  vendor/lowrisc_ip/ip/prim_generic/rtl/prim_generic_buf.sv
  vendor/lowrisc_ip/ip/prim_generic/rtl/prim_generic_clock_gating.sv
  vendor/lowrisc_ibex/dv/uvm/core_ibex/common/prim/prim_clock_gating.sv
  vendor/lowrisc_ip/ip/prim/rtl/prim_fifo_sync.sv
  vendor/lowrisc_ip/ip/prim/rtl/prim_fifo_sync_cnt.sv
  rtl/system/jtag_id_pkg.sv
  vendor/lowrisc_ip/ip/prim_generic/rtl/prim_generic_clock_inv.sv
  build/lowrisc_ibex_demo_system_0/src/lowrisc_prim_abstract_clock_inv_0/prim_clock_inv.sv
  vendor/lowrisc_ibex/dv/uvm/core_ibex/common/prim/prim_clock_mux2.sv
  vendor/lowrisc_ip/ip/prim_generic/rtl/prim_generic_clock_mux2.sv
  vendor/lowrisc_ip/ip/prim/rtl/prim_fifo_async_simple.sv
  vendor/lowrisc_ip/ip/prim/rtl/prim_sync_reqack.sv
  vendor/lowrisc_ip/ip/prim/rtl/prim_flop_2sync.sv
  vendor/lowrisc_ibex/dv/uvm/core_ibex/common/prim/prim_flop.sv
  vendor/lowrisc_ip/ip/prim_generic/rtl/prim_generic_flop.sv
  vendor/lowrisc_ibex/shared/rtl/timer.sv
  vendor/pulp_riscv_dbg/debug_rom/debug_rom.sv
)

# Ibex core RTL
CORE=(
  vendor/lowrisc_ibex/rtl/ibex_alu.sv
  vendor/lowrisc_ibex/rtl/ibex_compressed_decoder.sv
  vendor/lowrisc_ibex/rtl/ibex_controller.sv
  vendor/lowrisc_ibex/rtl/ibex_counter.sv
  vendor/lowrisc_ibex/rtl/ibex_csr.sv
  vendor/lowrisc_ibex/rtl/ibex_cs_registers.sv
  vendor/lowrisc_ibex/rtl/ibex_decoder.sv
  vendor/lowrisc_ibex/rtl/ibex_ex_block.sv
  vendor/lowrisc_ibex/rtl/ibex_fetch_fifo.sv
  vendor/lowrisc_ibex/rtl/ibex_id_stage.sv
  vendor/lowrisc_ibex/rtl/ibex_if_stage.sv
  vendor/lowrisc_ibex/rtl/ibex_load_store_unit.sv
  vendor/lowrisc_ibex/rtl/ibex_multdiv_fast.sv
  vendor/lowrisc_ibex/rtl/ibex_multdiv_slow.sv
  vendor/lowrisc_ibex/rtl/ibex_prefetch_buffer.sv
  vendor/lowrisc_ibex/rtl/ibex_register_file_ff.sv
  vendor/lowrisc_ibex/rtl/ibex_wb_stage.sv
  vendor/lowrisc_ibex/rtl/ibex_core.sv
  vendor/lowrisc_ibex/rtl/ibex_top.sv
)

# Debug module
DBG=(
  vendor/pulp_riscv_dbg/src/dm_pkg.sv
  vendor/pulp_riscv_dbg/src/dm_csrs.sv
  vendor/pulp_riscv_dbg/src/dm_mem.sv
  vendor/pulp_riscv_dbg/src/dm_sba.sv
  vendor/pulp_riscv_dbg/src/dmi_jtag.sv
  vendor/pulp_riscv_dbg/src/dmi_jtag_tap.sv
  vendor/pulp_riscv_dbg/src/dmi_cdc.sv
  #vendor/lowrisc_ibex/vendor/google_riscv-dv/src/riscv_debug_rom_gen.sv
  #vendor/pulp_riscv_dbg/debug_rom/debug_rom.sv
  vendor/pulp_riscv_dbg/debug_rom/debug_rom_one_scratch.sv
  rtl/system/dm_top.sv
)

# System top, interconnect, memories, and peripherals
SYS=(
  # Interconnect & Bridges
  rtl/system/obi2wb.sv
  rtl/system/wb_interconnect.sv

  # Memories
  rtl/system/boot_rom.sv
  rtl/system/boot_rom_wrapper.sv
  rtl/system/dffram.sv
  rtl/system/sram_controller.sv
  rtl/system/sram_model.sv

  # Peripherals (UART, GPIO, PWM, SPI, I2C, Timers/Debounce)
  rtl/system/uart.sv
  rtl/system/gpio.sv
  rtl/system/pwm.sv
  rtl/system/pwm_wrapper.sv
  rtl/system/spi_host.sv
  rtl/system/spi_top.sv
  rtl/system/spi_flash_xip.sv
  rtl/system/debounce.sv
  rtl/system/i2c_wb_wrapper.v
  rtl/system/i2c_master_top.v
  rtl/system/i2c_master_byte_ctrl.v
  rtl/system/i2c_master_bit_ctrl.v
  #rtl/system/i2c_slave_bfm.sv

  # Top levels
  rtl/system/ibex_demo_system.sv
  rtl/system/wrapper_top.sv
)

echo "Packages/Defines: ${#PKGS[@]} files"
echo "Core:             ${#CORE[@]} files"
echo "Debug:            ${#DBG[@]} files"
echo "System:           ${#SYS[@]} files"

echo "Running sv2v to generate a single merged file..."

# Merge everything into one file (simpler for Yosys)
sv2v "${PKGS[@]}" "${CORE[@]}" "${DBG[@]}" "${SYS[@]}" \
  -Ivendor/lowrisc_ip/ip/prim/rtl \
  -Ivendor/lowrisc_ibex/vendor/lowrisc_ip/dv/sv/dv_utils \
  -Irtl/system \
  -DSYNTHESIS \
  -DYOSYS \
  --exclude=assert \
  > $OUTDIR/ibex_soc_merged.v

if [ $? -eq 0 ]; then
    echo "Success! Converted merged file created at:"
    ls -la $OUTDIR/ibex_soc_merged.v
    echo "Total lines:"
    wc -l $OUTDIR/ibex_soc_merged.v
else
    echo "Error: sv2v conversion failed."
fi
