#include "io.h"

void main() {
    int counter = 0;
    uint32_t read_val = 0;

    while (1) {
        // CPU writes to the FPGA Register
        IO_OUT(IO_GPIO_ADDR, counter);

        // CPU reads back to verify
        read_val = IO_IN(IO_GPIO_ADDR);
        if (read_val != counter) {
            printf("Error: Readback Failed!\n");
        }

        // Increment Counter
        counter++;        
	    if (counter > 15) counter = 0;
        
        // Large Delay for Visibility
        for (volatile int i = 0; i < 500000; i++); 
    }
}
