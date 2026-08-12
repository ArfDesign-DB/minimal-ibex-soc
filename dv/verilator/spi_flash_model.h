struct SpiFlashModel {

    uint8_t mem[1 << 16] = {0};

    uint8_t shift_reg = 0;
    uint8_t out_shift = 0;
    
    bool miso_reg = 0;

    int bit_cnt = 0;

    bool prev_sck = 0;

    enum State {
        IDLE,
        ADDR,
        DATA
    } state = IDLE;

    uint32_t addr = 0;


    uint8_t read_byte(uint32_t a) {
        return mem[a & 0xFFFF];
    }


    void step(bool sck, bool csn, bool mosi, bool &miso)
    {

        miso = miso_reg;
      
        if(csn) {
            state = IDLE;
            bit_cnt = 0;
            addr = 0;
            miso_reg = 0;
            miso = 0;
            prev_sck = sck;
            return;
        }


        bool rising_edge  = (!prev_sck && sck);
        bool falling_edge = (prev_sck && !sck);


        prev_sck = sck;


        if(rising_edge)
        {
            switch(state)
            {

            case IDLE:

                shift_reg = (shift_reg << 1) | mosi;
                bit_cnt++;

                if(bit_cnt == 8)
                {
                    if(shift_reg == 0x03)
                    {
                        state = ADDR;
                        addr = 0;
                    }

                    shift_reg = 0;
                    bit_cnt = 0;
                }

                break;


            case ADDR:

                addr = (addr << 1) | mosi;
                bit_cnt++;

                if(bit_cnt == 24)
                {
                    state = DATA;
                    bit_cnt = 0;

                    addr &= 0xFFFFFF;
                    
                    out_shift = read_byte(addr);
                    //addr++;
                }

                break;


            case DATA:
                break;

            }
        }


        if(falling_edge && state == DATA)
        {
            //miso = (out_shift & 0x80);
            //miso = ((out_shift >> 7) & 1);
            miso_reg = ((out_shift >> 7) & 1);
            miso = miso_reg;
            
            //printf("FLASH DATA: addr=%08x out_shift=%02x miso=%d\n",
           //addr,
           //out_shift,
           //miso);

            out_shift <<= 1;
            bit_cnt++;

            if(bit_cnt == 8)
            {
                bit_cnt = 0;
                addr++;
                
                out_shift = read_byte(addr);
                //addr++;
            }
        }
    }
};
