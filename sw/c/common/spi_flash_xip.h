// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#ifndef SPI_FLASH_XIP_H_
#define SPI_FLASH_XIP_H_

#include <stdint.h>

#ifdef __cplusplus
extern "C" {
#endif

// Base address of the memory mapped SPI Flash
#define XIP_BASE_ADDR 0x20000000

// Read a 32-bit word from XIP flash
uint32_t spi_flash_xip_read_word(uint32_t offset);

// Simple demo test
void spi_flash_xip_test(void);

//back to back reads test
void spi_flash_xip_back_to_back_test(void);

#ifdef __cplusplus
}
#endif

#endif
