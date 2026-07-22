module shiftrows (
    input  wire [127:0] state_in,
    input  wire         inv,        // 0 = encrypt (normal), 1 = decrypt (inverse)
    output wire [127:0] state_out
);
    wire [7:0] s[0:15];
    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1)
            assign s[i] = state_in[127 - 8*i -: 8];
    endgenerate

    // ShiftRows
    assign state_out = (inv == 1'b0) ? {
        // encryption order
        s[0],  s[5],  s[10], s[15],
        s[4],  s[9],  s[14], s[3],
        s[8],  s[13], s[2],  s[7],
        s[12], s[1],  s[6],  s[11]
    } : {
        // decryption order (inverse)
        s[0],  s[13], s[10], s[7],
        s[4],  s[1],  s[14], s[11],
        s[8],  s[5],  s[2],  s[15],
        s[12], s[9],  s[6],  s[3]
    };
endmodule
