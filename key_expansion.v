//=====================================================
// AES Key Expansion for AES-128
//=====================================================
module key_expansion (
    input  wire [127:0] key_in,       // Original cipher key
    output wire [1407:0] round_keys   // 11 round keys × 128 bits = 1408 bits
);
    // Round constants (Rcon)
    reg [31:0] Rcon [0:9];
    initial begin
        Rcon[0] = 32'h01000000;
        Rcon[1] = 32'h02000000;
        Rcon[2] = 32'h04000000;
        Rcon[3] = 32'h08000000;
        Rcon[4] = 32'h10000000;
        Rcon[5] = 32'h20000000;
        Rcon[6] = 32'h40000000;
        Rcon[7] = 32'h80000000;
        Rcon[8] = 32'h1B000000;
        Rcon[9] = 32'h36000000;
    end

    // W[0..43] = 44 words (each 32 bits)
    reg [31:0] w [0:43];
    integer i;

    // S-Box instance
    wire [7:0] sbox_out [0:3];
    reg  [7:0] sbox_in  [0:3];
    genvar j;
    generate
        for (j = 0; j < 4; j = j + 1)
            sbox s_inst (.in(sbox_in[j]), .out(sbox_out[j]));
    endgenerate

    // Key expansion process
    always @(*) begin
        // Initial 4 words
        {w[0], w[1], w[2], w[3]} = key_in;

        for (i = 4; i < 44; i = i + 1) begin
            reg [31:0] temp;
            temp = w[i-1];
            if (i % 4 == 0) begin
                // RotWord: rotate left 8 bits
                temp = {temp[23:0], temp[31:24]};

                // SubWord: apply S-box on each byte
                sbox_in[0] = temp[31:24];
                sbox_in[1] = temp[23:16];
                sbox_in[2] = temp[15:8];
                sbox_in[3] = temp[7:0];
                temp = {sbox_out[0], sbox_out[1], sbox_out[2], sbox_out[3]};

                // XOR with round constant
                temp = temp ^ Rcon[(i/4)-1];
            end
            w[i] = w[i-4] ^ temp;
        end
    end

    // Combine all round keys (11 total)
    assign round_keys = {
        w[0],  w[1],  w[2],  w[3],
        w[4],  w[5],  w[6],  w[7],
        w[8],  w[9],  w[10], w[11],
        w[12], w[13], w[14], w[15],
        w[16], w[17], w[18], w[19],
        w[20], w[21], w[22], w[23],
        w[24], w[25], w[26], w[27],
        w[28], w[29], w[30], w[31],
        w[32], w[33], w[34], w[35],
        w[36], w[37], w[38], w[39],
        w[40], w[41], w[42], w[43]
    };
endmodule
