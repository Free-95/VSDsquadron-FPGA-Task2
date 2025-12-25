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

// --- FOR HARDWARE TEST ---
//module simple_gpio_output_ip (
//    input             clk,
//    input             resetn,
//    input             i_sel,
//    input             i_we,
//    input      [31:0] i_wdata,
//    output     [31:0] o_rdata,
//    output      [3:0] o_gpio
//);
//
//    // Create a large hardware counter (24 bits)
//    // 12 MHz clock = 12,000,000 ticks per second.
//    // 2^23 = ~8.3 million. So bit [23] toggles every ~0.7 seconds.
//    reg [26:0] heartbeat;
//
//    always @(posedge clk) begin
//        heartbeat <= heartbeat + 1;
//    end
//
//    // Map the top bits to the LEDs
//    // LED 0 blinks fast, LED 3 blinks slow.
//    assign o_gpio[0] = heartbeat[23]; // ~1.4 Hz
//    assign o_gpio[1] = heartbeat[24]; // ~0.7 Hz
//    assign o_gpio[2] = heartbeat[25]; // ~0.35 Hz
//    assign o_gpio[3] = heartbeat[26]; // ~0.17 Hz
//
//    // Keep the bus logic valid (so the CPU doesn't hang waiting for read)
//    assign o_rdata = 32'hDEAD_BEEF; 
//
//endmodule
