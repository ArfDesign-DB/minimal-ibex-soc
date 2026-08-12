// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include <stdbool.h>
#include <stdint.h>

#include "demo_system.h"
#include "gpio.h"
#include "pwm.h"
#include "timer.h"
#include "spi_flash_xip.h"

#define USE_GPIO_SHIFT_REG 0

void test_uart_irq_handler(void) __attribute__((interrupt));

void test_uart_irq_handler(void) {
  int uart_in_char;

  while ((uart_in_char = uart_in(DEFAULT_UART)) != -1) {
    uart_out(DEFAULT_UART, uart_in_char);
    uart_out(DEFAULT_UART, '\r');
    uart_out(DEFAULT_UART, '\n');
  }
}

int main(void) {
  install_exception_handler(UART_IRQ_NUM, &test_uart_irq_handler);
  uart_enable_rx_int();

  // Timer initialization
  timer_init();
  timer_enable(5000000);

  uint64_t last_elapsed_time = get_elapsed_time();

  // Reset green LEDs
  set_outputs(GPIO_OUT, 0x10);

  // PWM variables
  uint32_t counter    = UINT8_MAX;
  uint32_t brightness = 0;
  bool ascending      = true;
  uint8_t color       = 7;

  // Perform XIP test only once
  bool xip_test_done = false;

  while (1) {
    uint64_t cur_time = get_elapsed_time();

    if (cur_time != last_elapsed_time) {
      last_elapsed_time = cur_time;

      // Disable interrupts while printing
      set_global_interrupt_enable(0);

      puts("Hello World! ");
      puthex(last_elapsed_time);

      puts("   Input Value: ");
      uint32_t in_val = read_gpio(GPIO_IN_DBNC);
      puthex(in_val);
      putchar('\n');

      //----------------------------------------------------------------------
      // SPI Flash XIP Integration Test
      //----------------------------------------------------------------------
      if (!xip_test_done) {
        //spi_flash_xip_test();
        spi_flash_xip_back_to_back_test();
        xip_test_done = true;
        }

      // Re-enable interrupts
      set_global_interrupt_enable(1);

      //----------------------------------------------------------------------
      // Existing GPIO Demo
      //----------------------------------------------------------------------
      if (USE_GPIO_SHIFT_REG) {
        set_outputs(GPIO_OUT_SHIFT, in_val);
      } else {
        uint32_t out_val = read_gpio(GPIO_OUT);

        out_val = (out_val << 1) & GPIO_LED_MASK;

        if ((in_val & 0x1) || (out_val == 0)) {
          out_val = 0x10;
        }

        set_outputs(GPIO_OUT, out_val);
      }

      //----------------------------------------------------------------------
      // Existing PWM Demo
      //----------------------------------------------------------------------
      for (int i = 0; i < NUM_PWM_MODULES; i++) {
        set_pwm(PWM_FROM_ADDR_AND_INDEX(PWM_BASE, i),
                ((1 << (i % 3)) & color) ? counter : 0,
                brightness ? 1 << (brightness - 1) : 0);
      }

      if (ascending) {
        brightness++;

        if (brightness >= 5) {
          ascending = false;
        }
      } else {
        brightness--;

        if (brightness == 0) {
          ascending = true;
          color++;

          if (color >= 8) {
            color = 1;
          }
        }
      }
    }

    asm volatile("wfi");
  }
}

/*


#include <stdbool.h>
#include <stdint.h>

#include "demo_system.h"
#include "spi_flash_xip.h"


int main(void) {

  spi_flash_xip_test();

  while (1) {
    asm volatile("wfi");
  }

}
*/















