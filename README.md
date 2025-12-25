# VSDSquadron FPGA Mini Internship - Task 2 Submission

>**Objective:** Design a simple memory-mapped IP, integrate it into the existing RISC-V SoC, and validate it through simulation. Also perform hardware validation on the FPGA board.

## IP Specification
**Name:** Simple GPIO Output IP

**Functionality:**
- One 32-bit register
- Writing to the register updates the state of 4 external LEDs
- Reading the register returns the last written value

**Interface:**
- Memory-mapped, connected to the existing CPU bus
- Uses the same bus signals already present in the SoC

**Address Map:**
- Address Bit 0 is selected as the decoder for the IP.
- Base Address: `0x400000`
- Offset: `0x04` (Bit 0 set → `...0100`)
___
## Writing the IP RTL

**Module Features:**
1. Register storage
2. Write logic
3. Readback logic

**Verilog Source Code:**
```verilog
module simple_gpio_output_ip (
    input             clk,
    input             resetn,
    // Bus Interface
    input             i_sel,      // Chip Select
    input             i_we,       // Write Enable
    input      [31:0] i_wdata,    // Data from CPU
    output     [31:0] o_rdata,    // Data to CPU (Readback)
    // External Interface
    output      [3:0] o_gpio
);

   reg [31:0] storage;

    // Write Logic
    always @(posedge clk) begin
        if (!resetn) begin
            storage <= 32'b0;
        end else if (i_sel && i_we) begin
            storage <= i_wdata;
        end
    end

    // Readback Logic
    assign o_rdata = storage;

    // Output Logic
    assign o_gpio = storage[3:0];

endmodule
```
___
## Integrating the IP into SoC

**Update `riscv.v`:**
Make the following updates in the `SOC` module -
1. Include the instantiation of `simple_gpio_output_ip` module.
2. Create `wire gpio_sel = isIO & mem_wordaddr[IO_GPIO_bit]`.
3. Update the `IO_rdata` logic to return `gpio_rdata` when the CPU reads from the GPIO address.
```verilog
module SOC (
   //  input 	     CLK,  // system clock 
    input 	     RESET,// reset button
    output     [3:0] LEDS, 
    input 	     RXD,  // UART receive
    output 	     TXD   // UART transmit
);

   wire clk;
   wire resetn;

   wire [31:0] mem_addr;
   wire [31:0] mem_rdata;
   wire mem_rstrb;
   wire [31:0] mem_wdata;
   wire [3:0]  mem_wmask;
   wire [31:0] gpio_rdata;

   Processor CPU(
      .clk(clk),
      .resetn(resetn),		 
      .mem_addr(mem_addr),
      .mem_rdata(mem_rdata),
      .mem_rstrb(mem_rstrb),
      .mem_wdata(mem_wdata),
      .mem_wmask(mem_wmask)
   );
   
   wire [31:0] RAM_rdata;
   wire [29:0] mem_wordaddr = mem_addr[31:2];
   wire isIO  = mem_addr[22];
   wire isRAM = !isIO;
   wire mem_wstrb = |mem_wmask;   

   Memory RAM(
      .clk(clk),
      .mem_addr(mem_addr),
      .mem_rdata(RAM_rdata),
      .mem_rstrb(isRAM & mem_rstrb),
      .mem_wdata(mem_wdata),
      .mem_wmask({4{isRAM}}&mem_wmask)
   );


   // Memory-mapped IO in IO page, 1-hot addressing in word address.   
   localparam IO_GPIO_bit      = 0;  // GPIO 
   localparam IO_UART_DAT_bit  = 1;  // W data to send (8 bits) 
   localparam IO_UART_CNTL_bit = 2;  // R status. bit 9: busy sending
   
   wire uart_valid = isIO & mem_wstrb & mem_wordaddr[IO_UART_DAT_bit];
   wire uart_ready;
   wire gpio_sel = isIO & mem_wordaddr[IO_GPIO_bit];

   corescore_emitter_uart #(
      .clk_freq_hz(12*1000000),
      .baud_rate(9600)
      //   .baud_rate(1000000)
   ) UART(
      .i_clk(clk),
      .i_rst(!resetn),
      .i_data(mem_wdata[7:0]),
      .i_valid(uart_valid),
      .o_ready(uart_ready),
      .o_uart_tx(TXD)      			       
   );

   wire [31:0] IO_rdata = 
           mem_wordaddr[IO_UART_CNTL_bit] ? { 22'b0, !uart_ready, 9'b0} :
           mem_wordaddr[IO_GPIO_bit]      ? gpio_rdata :     
                                            32'b0;
   
   assign mem_rdata = isRAM ? RAM_rdata :
	                      IO_rdata ;
   
   
`ifdef BENCH
   always @(posedge clk) begin
      if(uart_valid) begin
	 $write("%c", mem_wdata[7:0] );
	 $fflush(32'h8000_0001);
      end
   end
`endif   
   
   wire clk_int;

   SB_HFOSC #(
   .CLKHF_DIV("0b10") // 12 MHz
   ) hfosc (
      .CLKHFPU(1'b1),
      .CLKHFEN(1'b1),
      .CLKHF(clk_int)
   );



   // Gearbox and reset circuitry.
   Clockworks CW(
     .CLK(clk_int),
     .RESET(RESET),
     .clk(clk),
     .resetn(resetn)
   );

   // GPIO IP
   simple_gpio_output_ip MyGPIO (
       .clk(clk),
       .resetn(resetn),
       .i_sel(gpio_sel),
       .i_we(mem_wstrb),       // mem_wstrb is high on write
       .i_wdata(mem_wdata),
       .o_rdata(gpio_rdata),
       .o_gpio(LEDS)
   );

endmodule
```

**Update `VSDSquadronFM.pcf`:**
Map output ports of IP to GPIOs on board -
```pcf
# Clock & Reset
set_io CLK 21
set_io RESET 10

# UART
set_io TXD 11
set_io RXD 12

# --- GPIO Pins ---
set_io LEDS[0] 38  # Bit 0 (LSB)
set_io LEDS[1] 43  # Bit 1
set_io LEDS[2] 45  # Bit 2
set_io LEDS[3] 47  # Bit 3 (MSB)
```
___
## Firmware Development

**Software Application `gpio.c`:**
A simple 4-bit counter to test the GPIO IP.
```c
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
```

**Update Driver `io.h`:**
```h
#include <stdint.h>

#define IO_BASE       0x400000

// Bit 0 set -> Offset 4
#define IO_GPIO_ADDR  4
#define IO_UART_DAT   8
#define IO_UART_CNTL  16

#define IO_IN(port)       *(volatile uint32_t*)(IO_BASE + port)
#define IO_OUT(port,val)  *(volatile uint32_t*)(IO_BASE + port)=(val)
```
___
## Performing Simulation

**Create Simulation Environment:**
- Create `sim_cells.v` to mock Lattice iCE40 specific blocks (`SB_HFOSC`).
```verilog
`timescale 1ns/1ps

// Mock Lattice iCE40 Oscillator
module SB_HFOSC (
    input       CLKHFEN,
    input       CLKHFPU,
    output reg  CLKHF
);
    parameter CLKHF_DIV = "0b00";
    initial CLKHF = 0;
    always #41.666 CLKHF = ~CLKHF; // ~12MHz
endmodule

// Mock Lattice iCE40 PLL (Pass-through)
module SB_PLL40_CORE (
    input   REFERENCECLK,
    output  PLLOUTCORE,
    output  PLLOUTGLOBAL,
    input   EXTFEEDBACK,
    input   DYNAMICDELAY,
    output  LOCK,
    input   BYPASS,
    input   RESETB,
    input   LATCHINPUTVALUE,
    input   SDI,
    input   SCLK,
    input   SHIFTREG_O
);
    parameter FEEDBACK_PATH = "SIMPLE";
    parameter PLLOUT_SELECT = "GENCLK";
    parameter DIVR = 4'b0000;
    parameter DIVF = 7'b0000000;
    parameter DIVQ = 3'b000;
    parameter FILTER_RANGE = 3'b000;

    assign PLLOUTCORE = REFERENCECLK;
    assign PLLOUTGLOBAL = REFERENCECLK;
    assign LOCK = 1'b1;
endmodule
```

- Create `tb.v` (Testbench) to instantiate the SoC, generate Reset/Power, and run the simulation for sufficient time.
```verilog
`timescale 1ns/1ps

module testbench;
    // Inputs to SoC
    reg RESET;
    reg RXD;
    
    // Outputs from SoC
    wire [3:0] LEDS; // GPIO counter
    wire TXD;

    // Instantiate the SoC
    SOC uut (
        .RESET(RESET),
        .LEDS(LEDS), 
        .RXD(RXD),
        .TXD(TXD)
    );

    initial begin
        $dumpfile("gpio_test.vcd");
        $dumpvars(0, testbench);

        // Initialize Inputs
        RXD = 1;
        RESET = 0; 
        
        // Reset Sequence (Pulse Reset High)
        #100 RESET = 1; 
        #100 RESET = 0; 

        // Run simulation
        // Wait long enough for the C-code to execute a few loops
        #600000; 
        $finish;
    end
endmodule
```

**Execute Simulation:**
1. Comment out the delay loop in software application `gpio.c` to speed up the simulation.
2. Convert it to a `.hex` file.
   ```bash
   cd ./basicRISCV/Firmware
   make gpio.bram.hex
   ```
3. Simulate the SoC.
   ```bash
   cd ../RTL
   iverilog -D BENCH -o gpio_test tb.v riscv.v simple_gpio_output_ip.v sim_cells.v
   vvp gpio_test
   ```
4. Observe the waveform.
   ```bash
   gtkwave gpio_test.vcd
   ```
   
___
## Performing Hardware Validation

**Steps:**
1. Uncomment the delay loop in software application `gpio.c` and rewrite the `gpio.bram.hex` file. This delay provides visibility of change in real-time.
2. Update the first line in `build` section of `Makefile` in `RTL` directory as follows -
   ```bash
   yosys  -q -p "synth_ice40 -top $(TOP) -json $(TOP).json" $(VERILOG_FILE) simple_gpio_output_ip.v
   ```
3. Perform the Synthesis & Flash through `Yosys (Synth) → Nextpnr (Place & Route) → Icepack (Bitstream)`.
   ```bash
   make build
   make flash
   ```
4. Make the physical connections and observe the output.

