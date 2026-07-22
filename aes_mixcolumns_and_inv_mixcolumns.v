module mixcolumns (
    input  wire [127:0] state_in,
    input  wire         inv,          // 0 = encrypt, 1 = decrypt
    output wire [127:0] state_out
);
    function [7:0] xtime;
        input [7:0] b;
        xtime = (b[7] == 1'b1) ? ((b << 1) ^ 8'h1B) : (b << 1);
    endfunction

    function [7:0] mul;
        input [7:0] a, b;
        reg [7:0] p;
        integer i;
        begin
            p = 8'h00;
            for (i = 0; i < 8; i = i + 1) begin
                if (b[i])
                    p = p ^ a;
                a = xtime(a);
            end
            mul = p;
        end
    endfunction

    integer c;
    reg [7:0] a[0:15];
    reg [7:0] r[0:15];

    always @(*) begin
        for (c = 0; c < 16; c = c + 1)
            a[c] = state_in[127 - 8*c -: 8];

        for (c = 0; c < 4; c = c + 1) begin
            if (!inv) begin
                // Encryption
                r[c*4+0] = mul(8'h02, a[c*4+0]) ^ mul(8'h03, a[c*4+1]) ^ a[c*4+2] ^ a[c*4+3];
                r[c*4+1] = a[c*4+0] ^ mul(8'h02, a[c*4+1]) ^ mul(8'h03, a[c*4+2]) ^ a[c*4+3];
                r[c*4+2] = a[c*4+0] ^ a[c*4+1] ^ mul(8'h02, a[c*4+2]) ^ mul(8'h03, a[c*4+3]);
                r[c*4+3] = mul(8'h03, a[c*4+0]) ^ a[c*4+1] ^ a[c*4+2] ^ mul(8'h02, a[c*4+3]);
            end else begin
                // Decryption
                r[c*4+0] = mul(8'h0E, a[c*4+0]) ^ mul(8'h0B, a[c*4+1]) ^ mul(8'h0D, a[c*4+2]) ^ mul(8'h09, a[c*4+3]);
                r[c*4+1] = mul(8'h09, a[c*4+0]) ^ mul(8'h0E, a[c*4+1]) ^ mul(8'h0B, a[c*4+2]) ^ mul(8'h0D, a[c*4+3]);
                r[c*4+2] = mul(8'h0D, a[c*4+0]) ^ mul(8'h09, a[c*4+1]) ^ mul(8'h0E, a[c*4+2]) ^ mul(8'h0B, a[c*4+3]);
                r[c*4+3] = mul(8'h0B, a[c*4+0]) ^ mul(8'h0D, a[c*4+1]) ^ mul(8'h09, a[c*4+2]) ^ mul(8'h0E, a[c*4+3]);
            end
        end
    end

    assign state_out = {
        r[0], r[1], r[2], r[3],
        r[4], r[5], r[6], r[7],
        r[8], r[9], r[10], r[11],
        r[12], r[13], r[14], r[15]
    };
endmodule
