//=====================================================
// AES Core Module - Performs AES-128 Encryption & Decryption
//=====================================================
module aes_core (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [127:0] plaintext,
    input  wire [127:0] key,
    input  wire         decrypt_mode,     // 0 = Encrypt, 1 = Decrypt
    output reg  [127:0] data_out,
    output reg          done
);

    // -------------------------------------------------
    // Internal signals
    // -------------------------------------------------
    reg [127:0] state;
    reg [3:0]   round;
    reg working;

    // Expanded keys
    wire [1407:0] round_keys;

    // Instantiate key expansion
    key_expansion key_exp_inst (
        .key_in(key),
        .round_keys(round_keys)
    );

    // -------------------------------------------------
    // Helper function to get current round key
    // -------------------------------------------------
    function [127:0] get_round_key(input [3:0] round_num);
        get_round_key = round_keys[(1407 - (round_num*128)) -: 128];
    endfunction

    // -------------------------------------------------
    // Instantiate SubBytes, ShiftRows, MixColumns
    // -------------------------------------------------
    wire [127:0] sub_out, shift_out, mix_out;

    // Encryption path
    sbox s_inst[15:0] (
        .in (state),
        .out(sub_out)
    );

    shiftrows shift_inst (
        .in(sub_out),
        .out(shift_out)
    );

    mixcolumns mix_inst (
        .in(shift_out),
        .out(mix_out)
    );

    // -------------------------------------------------
    // State machine for AES Rounds
    // -------------------------------------------------
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state   <= 128'h0;
            data_out <= 128'h0;
            round   <= 4'd0;
            done    <= 1'b0;
            working <= 1'b0;
        end
        else begin
            if (start && !working) begin
                // Start new AES operation
                state   <= plaintext ^ get_round_key(0); // Initial AddRoundKey
                round   <= 1;
                done    <= 0;
                working <= 1;
            end
            else if (working) begin
                if (round < 10) begin
                    // Main AES rounds (1–9)
                    state <= mix_out ^ get_round_key(round);
                    round <= round + 1;
                end
                else if (round == 10) begin
                    // Final round (no MixColumns)
                    state <= shift_out ^ get_round_key(10);
                    data_out <= state;
                    done <= 1;
                    working <= 0;
                    round <= 0;
                end
            end
        end
    end
endmodule
