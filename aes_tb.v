Testbench   `timescale 1ns / 1ps
module tb_aes;

    // Inputs
    reg clk;
    reg rst_n;
    reg start;
    reg [127:0] plaintext;
    reg [127:0] key;

    // Outputs
    wire [127:0] ciphertext;
    wire [127:0] decryptedtext;
    wire done;
	 // Instantiate the Unit Under Test (UUT)
    aes_top uut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .plaintext(plaintext),
        .key(key),
        .ciphertext(ciphertext),
        .decryptedtext(decryptedtext),
        .done(done)
    );

    // Clock generation: 10ns period
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
	 // Test sequence
    initial begin
        // Initialize inputs
        key       = 128'h000102030405060708090A0B0C0D0E0F;
        plaintext = 128'h00112233445566778899AABBCCDDEEFF;
        rst_n     = 0;
        start     = 0;

        #20;
        rst_n = 1;        // Release reset
        #20;
        start = 1;        // Start AES operation
        #10;
		  start = 0;

        // Wait until operation is complete
        wait(done);
        #20;

        // End simulation
    end

endmodule  
