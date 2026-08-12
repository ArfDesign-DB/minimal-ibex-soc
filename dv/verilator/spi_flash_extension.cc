#include <iostream>
#include "spi_flash_extension.h"

SpiFlashExtension::SpiFlashExtension(Vtop_verilator *top)
    : top_(top) {

  // Optional flash preload
  //flash_.mem[0x000000] = 0x12345678;
  flash_.mem[0] = 0x78;
  flash_.mem[1] = 0x56;
  flash_.mem[2] = 0x34;
  flash_.mem[3] = 0x12;
  
  flash_.mem[4] = 0xEF;
  flash_.mem[5] = 0xCD;
  flash_.mem[6] = 0xAB;
  flash_.mem[7] = 0x90;

  flash_.mem[8]  = 0x11;
  flash_.mem[9]  = 0x22;
  flash_.mem[10] = 0x33;
  flash_.mem[11] = 0x44;
  
  flash_.mem[12]  = 0x55;
  flash_.mem[13]  = 0x25;
  flash_.mem[14] = 0x3F;
  flash_.mem[15] = 0xDF;
  
  /*
  //simulation purpose ----debug
  printf("FLASH INIT: %02x %02x %02x %02x\n",
       flash_.mem[0],
       flash_.mem[1],
       flash_.mem[2],
       flash_.mem[3]);
  */
}


void SpiFlashExtension::OnClock(unsigned long sim_time) {

    static bool printed = false;
    static int cnt = 0;

    if (!printed) {
        std::cout << "SpiFlashExtension is alive!" << std::endl;
        printed = true;
    }


    bool miso = 0;


    // Debug SPI signals
    /*
    if (cnt < 100) {
        std::cout
            << "time=" << sim_time
            << " SCK=" << (int)top_->xip_spi_sck_o
            << " CS=" << (int)top_->xip_spi_csn_o
            << " MOSI=" << (int)top_->xip_spi_mosi_o
            << " MISO(before)=" << (int)top_->xip_spi_miso_i
            << std::endl;

        cnt++;
    }
   */

    //top_->xip_spi_miso_i = miso;

    // Flash model transaction
    flash_.step(
        top_->xip_spi_sck_o,
        top_->xip_spi_csn_o,
        top_->xip_spi_mosi_o,
        miso
    );


    // Drive flash output back to SPI controller
    top_->xip_spi_miso_i = miso;
    
    // Store next value for next SPI edge
    //flash_.miso = miso;

   /*
    if (cnt < 100) {
        std::cout
            << "MISO(after)="
            << (int)miso
            << std::endl;
    }
    */
}




