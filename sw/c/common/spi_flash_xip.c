// Copyright lowRISC contributors.
// Licensed under the Apache License, Version 2.0, see LICENSE for details.
// SPDX-License-Identifier: Apache-2.0

#include "spi_flash_xip.h"

#include "demo_system.h"

volatile uint32_t *const xip_flash =
    (volatile uint32_t *)XIP_BASE_ADDR;

uint32_t spi_flash_xip_read_word(uint32_t offset)
{
    return xip_flash[offset / 4];
}

void spi_flash_xip_test(void)
{
    puts("=================\n");
    puts("Starting SPI Flash XIP Read...\n");
    puts("=================\n");

    uint32_t data = spi_flash_xip_read_word(0);

    puts("XIP Read Data = 0x");
    puthex(data);
    putchar('\n');

    puts("SPI Flash XIP Read Complete\n");
}

void spi_flash_xip_back_to_back_test(void)
{
    puts("\n");
    puts("Starting Back-to-Back SPI Flash XIP Read...\n");
    puts("---------------------------------------------------------------\n");
    puts("\n");

    for (uint32_t addr = 0; addr < 16; addr += 4) {
        puts("Read @0x");
        puthex(addr);
        puts(" = 0x");
        puthex(spi_flash_xip_read_word(addr));
        putchar('\n');
    }

    puts("\n");
    puts("Back-to-Back SPI Flash XIP Read Complete\n");
    //puts("\n");
    puts("---------------------------------------------------------------\n");
}



