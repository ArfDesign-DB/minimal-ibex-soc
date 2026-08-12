#pragma once

#include "sim_ctrl_extension.h"
#include "Vtop_verilator.h"
#include "spi_flash_model.h"

class SpiFlashExtension : public SimCtrlExtension {
 public:
  explicit SpiFlashExtension(Vtop_verilator *top);

  void OnClock(unsigned long sim_time) override;

 private:
  Vtop_verilator *top_;
  SpiFlashModel flash_;
};
