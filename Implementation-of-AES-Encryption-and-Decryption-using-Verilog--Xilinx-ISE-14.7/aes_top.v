//=====================================================
// AES FPGA Top Module
// Connects AES Core to FPGA I/O (buttons, LEDs)
//=====================================================
module aes_top (
    input  wire clk,            // System clock (e.g., 50 MHz)
    input  wire rst_n_btn,      // Active-low reset button
    input  wire start_btn,      // Start encryption
    output wire done_led,       // Done LED indicator
    output wire [7:0] leds      // Display lower 8 bits of ciphertext
);

    // -------------------------------------------------
    // Internal signals
    // -------------------------------------------------
    reg  [127:0] plaintext;
    reg  [127:0] key;
    wire [127:0] ciphertext;
    wire done;

    // -------------------------------------------------
    // Example fixed key and plaintext
    // (You can replace these with external inputs if needed)
    // -------------------------------------------------
    initial begin
        plaintext = 128'h00112233445566778899AABBCCDDEEFF;
        key       = 128'h000102030405060708090A0B0C0D0E0F;
    end

    // -------------------------------------------------
    // AES core instance
    // -------------------------------------------------
    aes_core aes_inst (
        .clk(clk),
        .rst_n(rst_n_btn),
        .start(start_btn),
        .plaintext(plaintext),
        .key(key),
        .decrypt_mode(1'b0),   // 0 = Encrypt
        .data_out(ciphertext),
        .done(done)
    );

    // -------------------------------------------------
    // Output LED indicators
    // -------------------------------------------------
    assign done_led = done;
    assign leds = ciphertext[7:0];   // Show lowest 8 bits on LEDs

endmodule
