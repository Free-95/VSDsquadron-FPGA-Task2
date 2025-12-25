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
