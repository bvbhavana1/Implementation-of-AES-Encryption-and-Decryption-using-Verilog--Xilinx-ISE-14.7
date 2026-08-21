`timescale 1ns / 1ps

module aes_fpga_top(
 input  wire clk,         // board oscillator (50 MHz)
    input  wire rst_n,       // active-low reset (SW0)
    input  wire start_enc,   // start encryption (SW1)
    input  wire start_dec,   // start decryption (SW2)
    output wire done_enc,    // LED for enc done
    output wire done_dec,    // LED for dec done
    output wire [7:0] leds   // optional leds show ciphertext[7:0]
);
 wire [127:0] ciphertext;
    wire [127:0] decryptedtext;
    wire enc_done;
    wire dec_done;
  // Instantiate AES core
    aes_top core (
        .clk(clk),
        .rst_n(rst_n),
        .start_enc(start_enc),
        .start_dec(start_dec),
        .plaintext(128'h00112233445566778899AABBCCDDEEFF),
        .key(128'h000102030405060708090A0B0C0D0E0F),
        .ciphertext(ciphertext),
		  .decryptedtext(decryptedtext),
        .done_enc(enc_done),
        .done_dec(dec_done)
    );

    assign done_enc = enc_done;
    assign done_dec = dec_done;
    assign leds = ciphertext[7:0];

endmodule
   