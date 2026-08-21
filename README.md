### AES-128 Encryption & Decryption Core | Verilog RTL + Xilinx FPGA

**A synthesizable AES-128 hardware core implementing encryption and decryption in Verilog HDL, functionally verified against the AES-128 FIPS-197 known-answer test vector, cross-validated with a Python reference model, and synthesized/implemented on a Xilinx Spartan-6 FPGA using Xilinx ISE.**

##  Project Highlights

- Implemented a complete **AES-128 encryption and decryption core** in synthesizable Verilog HDL.
- Supports the complete **10-round AES-128 algorithm** with a 128-bit plaintext, 128-bit key, and 128-bit ciphertext.
- Implemented core AES transformations:
  - `SubBytes`
  - `ShiftRows`
  - `MixColumns`
  - `AddRoundKey`
  - Inverse transformations for decryption
- Implemented **on-the-fly AES-128 key expansion** generating 44 words / 11 round keys.
- Designed a **round-based sequential datapath** controlled by a start/done handshake.
- Verified RTL functionality using the official **FIPS-197 AES-128 known-answer test vector**.
- Cross-checked hardware outputs against a **Python software AES reference implementation**.
- Synthesized and implemented the design for a **Xilinx Spartan-6 (`xc6slx4-2-tqg144`)** using Xilinx ISE.
- Achieved a reported **maximum operating frequency of 177.272 MHz** with a **5.641 ns minimum period** in the FPGA timing analysis.
- Analyzed FPGA resource utilization, synthesis results, critical timing paths, and implementation reports.
- Included a board-level FPGA wrapper and **UCF pin/clock constraints** for hardware deployment.

## Overview
The **Advanced Encryption Standard (AES)** is a symmetric-key block cipher standardized by NIST.
This project implements the **AES-128** variant, which operates on:

| Parameter | Value |
|---|---:|
| Block Size | 128 bits |
| Key Size | 128 bits |
| Number of Rounds | 10 |
| Round Keys | 11 |
| Key Expansion Words | 44 × 32-bit |
| Encryption Output | 128 bits |
| Decryption Output | 128 bits |

The design uses a **round-based sequential architecture**, where the AES state is processed one round per clock cycle rather than fully unrolling all ten rounds into a large combinational datapath.
This approach provides a practical balance between **hardware resource usage, control complexity, and throughput** for FPGA-based cryptographic hardware.

##  AES Architecture
The top-level AES core integrates the key expansion, encryption/decryption datapath, round control, and output generation.

```text
                          ┌───────────────────────────────┐
                          │           aes_top             │
                          │                               │
 plaintext ───────────▶  │                               │────▶ ciphertext
 key ──────────────────▶│  Key Expansion + Round FSM     │
 clk ──────────────────▶│                                │────▶ decryptedtext
 rst_n ────────────────▶│                                │
 start ────────────────▶│                                │────▶ done
                         └───────────────────────────────┘
```

## AES Encryption Datapath
AES-128 encryption consists of an initial key addition followed by ten transformation rounds.
```text
                 128-bit Plaintext
                        │
                        ▼
                ┌────────────────┐
                │  AddRoundKey   │
                │    Round 0     │
                └───────┬────────┘
                        │
                        ▼
              ┌─────────────────────┐
              │      Round 1        │
              │                     │
              │     SubBytes        │
              │        ↓            │
              │     ShiftRows       │
              │        ↓            │
              │    MixColumns       │
              │        ↓            │
              │    AddRoundKey      │
              └─────────┬───────────┘
                        │
                       ...
                        │
                        ▼
              ┌─────────────────────┐
              │      Round 9        │
              │                     │
              │     SubBytes        │
              │     ShiftRows       │
              │    MixColumns       │
              │    AddRoundKey      │
              └─────────┬───────────┘
                        │
                        ▼
              ┌─────────────────────┐
              │     Final Round     │
              │                     │
              │     SubBytes        │
              │     ShiftRows       │
              │    AddRoundKey      │
              │  (No MixColumns)    │
              └─────────┬───────────┘
                        │
                        ▼
                 128-bit Ciphertext
```
Encryption Round Operation

For rounds 1–9:

```text
SubBytes
   ↓
ShiftRows
   ↓
MixColumns
   ↓
AddRoundKey
```
For the final round:
```text
SubBytes
   ↓
ShiftRows
   ↓
AddRoundKey
```
MixColumns is intentionally omitted from the final AES round as required by the AES specification.

## AES Decryption Datapath
The design also implements AES-128 decryption using the inverse transformations and the same expanded key schedule.
```text
              128-bit Ciphertext
                       │
                       ▼
                Inverse Cipher
                       │
          ┌────────────┴────────────┐
          │                         │
          ▼                         ▼
     InvShiftRows              AddRoundKey
          │                         │
          ▼                         │
     InvSubBytes                    │
          │                         │
          └────────────┬────────────┘
                       ▼
                  InvMixColumns
                       │
                       ▼
                      ... 
                       │
                       ▼
               128-bit Plaintext
```
The inverse transformations reconstruct the original plaintext from the ciphertext using the expanded AES round keys

## AES Transformation Stages
# 1. SubBytes
Performs a byte-wise nonlinear substitution using the AES S-box.
```text
              128-bit State
                   │
                   ▼
            16 × 8-bit bytes
                   │
                   ▼
        AES S-Box substitution
                   │
                   ▼
      128-bit transformed state
```
# 2. ShiftRows
Performs the AES row permutation on the 4×4 byte state matrix.
```text
Before ShiftRows          After ShiftRows
a0 a1 a2 a3               a0 a1 a2 a3
b0 b1 b2 b3      ───▶     b1 b2 b3 b0
c0 c1 c2 c3               c2 c3 c0 c1
d0 d1 d2 d3               d3 d0 d1 d2
```

# 3. MixColumns
Performs matrix multiplication over the AES finite field GF(2⁸).
The transformation provides diffusion across the four bytes of each AES column.
```text
┌───────┐       ┌─────────────────┐       ┌───────┐
│ State │ ────▶ │ MixColumns      │ ────▶ │ State │
└───────┘       │ GF(2^8) Matrix  │       └───────┘
                └─────────────────┘
```
The inverse operation is used during decryption.

# 4. AddRoundKey
The AES state is XORed with the corresponding 128-bit round key.
```text
state_next = state ^ round_key;
```
his operation is performed during the initial key addition and every encryption/decryption round as required.

 # Key Expansion
The AES-128 key schedule expands the original 128-bit cipher key into 11 round keys.
```text
128-bit Cipher Key
        │
        ▼
   Key Expansion
        │
        ├──▶ Round Key 0
        ├──▶ Round Key 1
        ├──▶ Round Key 2
        ├──▶ Round Key 3
        ├──▶ ...
        ├──▶ Round Key 9
        └──▶ Round Key 10
```
The implementation generates:
```text
44 × 32-bit words
       =
11 × 128-bit round keys
```
The key schedule is generated from the 128-bit input cipher key and used by the encryption and decryption datapaths.

## Round-Based Control
The core uses sequential control to process the AES rounds.
Operation Sequence
```text
        IDLE
         │
         │ start = 1
         ▼
Initial AddRoundKey
         │
         ▼
     Round 1
         │
         ▼
     Round 2
         │
         ▼
        ...
         │
         ▼
      Round 9
         │
         ▼
  Final Round 10
         │
         ▼
 ciphertext valid
         │
         ▼
       done = 1
```
The start input initiates the encryption process, while done indicates completion.
This round-based organization avoids implementing ten complete AES rounds as a single large combinational path.

### Module Interface — aes_top
| Port            | Direction | Width | Description                  |
| --------------- | --------- | ----: | ---------------------------- |
| `clk`           | Input     |     1 | System clock                 |
| `rst_n`         | Input     |     1 | Active-low synchronous reset |
| `start`         | Input     |     1 | Starts AES operation         |
| `plaintext`     | Input     |   128 | 128-bit plaintext block      |
| `key`           | Input     |   128 | 128-bit AES cipher key       |
| `ciphertext`    | Output    |   128 | 128-bit encrypted output     |
| `decryptedtext` | Output    |   128 | Decrypted plaintext output   |
| `done`          | Output    |     1 | Indicates completion         |

### Functional Verification
The AES core was verified using the standard AES-128 known-answer test vector.
Test Vector
| Input                       | Value                              |
| --------------------------- | ---------------------------------- |
| **Key**                     | `000102030405060708090A0B0C0D0E0F` |
| **Plaintext**               | `00112233445566778899AABBCCDDEEFF` |
| **Expected Ciphertext**     | `69C4E0D86A7B0430D8CDB78070B4C55A` |
| **Expected Decrypted Text** | `00112233445566778899AABBCCDDEEFF` |

## Verification Result
```text
AES TOP TESTBENCH START

Encryption Completed:
Ciphertext = 69c4e0d86a7b0430d8cdb78070b4c55a

Decryption Completed:
DecryptedText = 00112233445566778899aabbccddeeff

AES TOP TESTBENCH END
```
The RTL-generated ciphertext exactly matches the official AES-128 known-answer vector, and the subsequent decryption reconstructs the original plaintext

## Verification Flow
```text
           AES RTL
              │
              ▼
        Verilog Testbench
              │
              ▼
       Ciphertext Output
              │
        ┌─────┴─────┐
        │           │
        ▼           ▼
   FIPS-197     Python AES
   Reference    Reference
        │           │
        └─────┬─────┘
              ▼
        Output Match ✓
```
## Simulation
The design was simulated using Xilinx ISim, with additional verification using a Python software reference implementation.
Simulation Waveforms
![image alt](https://github.com/bvbhavana1/Implementation-of-AES-Encryption-and-Decryption-using-Verilog--Xilinx-ISE-14.7/blob/8e6ca437b921b4b24b9f63163caccea4618279c4/results/AES_3.jpeg)
![image alt]()
Python Reference Verification
![image alt]()
The hardware outputs were cross-checked against a Python AES implementation.

### Top-Level RTL Block Diagram

The top-level RTL view shows the AES-128 core interface, including the 128-bit plaintext and key inputs, clock/reset and start control, and ciphertext/ready outputs.

![image alt](https://github.com/bvbhavana1/Implementation-of-AES-Encryption-and-Decryption-using-Verilog--Xilinx-ISE-14.7/blob/0682d6e6c9e439f59a8052d66435e1558babbe80/results/AES_1.jpeg)

### Detailed RTL Schematic

The detailed RTL schematic shows the internal synthesized RTL structure and connectivity of the AES datapath and control logic.
![image alt]()
 
 Zoomed version ![image alt]()
These schematics provide visibility into the synthesized hardware structure and the resulting FPGA-mapped implementation.


## FPGA Implementation
The AES design was synthesized and implemented using the Xilinx ISE design flow.
```text
              Verilog RTL
                  │
                  ▼
              XST Synthesis
                  │
                  ▼
              Translate
                  │
                  ▼
              MAP
                  │
                  ▼
              Place & Route
                  │
                  ▼
              Timing Analysis
                  │
                  ▼
              FPGA Bitstream / NGC
```
### Target Device 

| Parameter            | Value                     |
| -------------------- | ------------------------- |
| **FPGA Family**      | Xilinx Spartan-6          |
| **Device**           | `xc6slx4-2-tqg144`        |
| **Top-Level Module** | `AES_FPGA_TOP`            |
| **Tool**             | Xilinx ISE 14.x           |
| **Simulator**        | ISim                      |
| **Board Clock**      | 50 MHz onboard oscillator |
| **Constraints**      | UCF                       |
The repository includes a board-level wrapper for FPGA deployment and a UCF constraints file defining clock, I/O, and board-level connections.

###  FPGA Resource Utilization
Post-MAP utilization for the target Spartan-6 device:
| Resource                | Used | Available | Utilization |
| ----------------------- | ---: | --------: | ----------: |
| **Slice Registers**     |  149 |     4,800 |      **3%** |
| **Slice LUTs**          |  857 |     2,400 |     **35%** |
| LUTs Used as Logic      |  857 |     2,400 |     **35%** |
| LUT-FF Pairs            |  865 |         — |           — |
| Fully Used LUT-FF Pairs |  141 |       865 |         16% |
| Bonded IOBs             |   12 |       102 |     **11%** |
| BUFG / BUFGCTRL         |    1 |        16 |      **6%** |
| Unique Control Sets     |    8 |         — |           — |

## Resource Utilization Summary
```text
Slice Registers     3%   ███
Slice LUTs         35%   ██████████████████
Bonded IOBs        11%   █████
BUFG Resources      6%   ███
```
The implementation uses 857 LUTs and 149 slice registers, with LUT utilization being the dominant FPGA resource.

### Post-Optimization HDL Statistics
The XST synthesis reports the following post-optimization resources:
| Resource               | Count |
| ---------------------- | ----: |
| RAMs                   |   177 |
| Registers / Flip-Flops |   520 |
| Adders / Subtractors   |     1 |
| Comparators            |     1 |
| Multiplexers           | 4,995 |
| XORs                   | 5,933 |

### RAM Breakdown
| Resource                     |   Count |
| ---------------------------- | ------: |
| 16 × 128-bit Single-Port ROM |       1 |
| 256 × 8-bit Single-Port ROM  |     176 |
| **Total RAMs**               | **177** |

### Multiplexer Breakdown
| Resource        |     Count |
| --------------- | --------: |
| 128-bit 2:1 MUX |         1 |
| 16-bit 2:1 MUX  |     4,992 |
| 4-bit 2:1 MUX   |         2 |
| **Total**       | **4,995** |

### XOR Breakdown
| Resource     |     Count |
| ------------ | --------: |
| 128-bit XOR2 |        13 |
| 16-bit XOR2  |     5,328 |
| 16-bit XOR3  |       288 |
| 16-bit XOR4  |       144 |
| 8-bit XOR4   |       160 |
| **Total**    | **5,933** |

![image alt]() HDL Synthesis Report

### Post-MAP Primitive Utilization
| Primitive             |     Count |
| --------------------- | --------: |
| **Total BELs**        | **1,242** |
| INV                   |         2 |
| LUT2                  |        35 |
| LUT3                  |        30 |
| LUT4                  |        41 |
| LUT5                  |        58 |
| LUT6                  |       691 |
| MUXF7                 |       257 |
| MUXF8                 |       128 |
| FDCE Flip-Flops       |       149 |
| BUFGP                 |         1 |
| IBUF                  |         3 |
| OBUF                  |         8 |
| **Total I/O Buffers** |    **11** |

design Summary  ![image alt]()

## FPGA Timing Analysis
The implemented design achieved the following reported timing results:
| Timing Metric                |           Value |
| ---------------------------- | --------------: |
| **Minimum Period**           |    **5.641 ns** |
| **Maximum Frequency**        | **177.272 MHz** |
| Minimum Input Arrival Time   |        6.071 ns |
| Maximum Output Required Time |        4.118 ns |
| Clock Buffer                 |           BUFGP |
| Clock Load                   |             149 |

Critical Path
```text
        FDCE
          │
          ▼
        LUT6
          │
          ▼
        MUXF7
          │
          ▼
        MUXF8
          │
          ▼
        LUT6
          │
          ▼
        LUT6
          │
          ▼
        FDCE
```
The reported critical path was:
```text
AES_INST/state_108
        │
        ▼
AES_INST/state_59
```
with a total path delay of 5.641 ns.

# Timing Breakdown
```text
Logic Delay   : 1.688 ns  (29.9%)
Routing Delay : 3.953 ns  (70.1%)
Total Delay   : 5.641 ns
```
Routing contributes the majority of the reported critical-path delay, making physical implementation and routing optimization important for further frequency improvement.

### Input / Output Timing
| Constraint       | Paths / Ports |    Delay | Logic Levels | Source → Destination               |
| ---------------- | ------------: | -------: | -----------: | ---------------------------------- |
| OFFSET IN BEFORE |     438 / 435 | 6.071 ns |            3 | `start_enc` → `AES_INST/state_124` |
| OFFSET OUT AFTER |         8 / 8 | 4.118 ns |            1 | `AES_INST/ciphertext_5` → `led<7>` |

### Synthesis Configuration
| Option               | Value              |
| -------------------- | ------------------ |
| Input Project        | `AES_FPGA_TOP.prj` |
| Output Format        | NGC                |
| Target Device        | `xc6slx4-2-tqg144` |
| Top Module           | `AES_FPGA_TOP`     |
| FSM Extraction       | Auto               |
| FSM Style            | LUT                |
| RAM Extraction       | Enabled            |
| ROM Extraction       | Enabled            |
| Resource Sharing     | Enabled            |
| Register Duplication | Enabled            |
| Global Max Fanout    | 100,000            |
| Clock Buffer         | BUFG               |

Synthesis option summary ![image alt]()

### XST Run Statistics
| Metric                 |      Value |
| ---------------------- | ---------: |
| Total REAL Time        | 807.00 sec |
| Total CPU Time         | 162.62 sec |
| Memory Usage           |   ~1.02 GB |
| Errors                 |      **0** |
The reported synthesis run completed with 0 errors. 

## Verification Strategy
The verification flow combines three levels:
```text
              ┌─────────────────┐
              │   AES RTL       │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │ Verilog TB      │
              └────────┬────────┘
                       │
                       ▼
              ┌─────────────────┐
              │ ISim Simulation │
              └────────┬────────┘
                       │
             ┌─────────┴─────────┐
             ▼                   ▼
      FIPS-197 Vector      Python Reference
             │                   │
             └─────────┬─────────┘
                       ▼
                  Output Match
```                       
This provides both known-answer verification and independent software cross-validation.

 ## Key Engineering Takeaways
# RTL Design
* AES-128 hardware architecture
* Sequential round-based datapath
*  Finite-state / round control
* Combinational cryptographic transformations
* Synthesizable Verilog HDL
# Verification
* FIPS-197 known-answer testing
* RTL simulation
* Waveform-based debugging
* Python software cross-verification
* Encryption and decryption validation
# FPGA Implementation
* Xilinx ISE synthesis flow
* Spartan-6 FPGA targeting
* UCF constraint creation
* LUT / FF resource analysis
* Critical-path analysis
* Timing closure concepts
* Place-and-route analysis
# Hardware Optimization
* Resource sharing
* LUT utilization analysis
* Routing-delay analysis

  ## Design Trade-Off
The implementation uses a round-based architecture rather than fully unrolling all ten AES rounds.
```text
        Fully Unrolled AES
                │
                ├── Higher parallelism
                ├── Higher throughput
                └── Larger hardware cost
                         │
                         ▼
                ┌────────────────┐
                │ Design Tradeoff│
                └────────────────┘
                         ▲
                         │
        Round-Based AES
                │
                ├── Sequential processing
                ├── Reduced datapath complexity
                └── Practical FPGA resource usage
```
The implementation therefore provides a useful balance between cryptographic functionality, hardware resource utilization, and achievable clock frequency.

## Future Improvements
* Extend the core to support AES-192 and AES-256.
* Develop a more deeply pipelined AES datapath for higher throughput.
* Add an explicit encrypt/decrypt mode control to the core interface.
* Develop an AXI-Stream or Wishbone interface for SoC integration.
* Improve verification using randomized and constrained-random test vectors.
* Perform power analysis on the FPGA implementation.

  ## Conclusion
This project demonstrates a complete implementation of AES-128 encryption and decryption, progressing from RTL design and functional verification to FPGA synthesis, placement, routing, and timing analysis.
The implementation successfully reproduces the official AES-128 known-answer test vector:
```text
Plaintext:
00112233445566778899AABBCCDDEEFF

Key:
000102030405060708090A0B0C0D0E0F

Ciphertext:
69C4E0D86A7B0430D8CDB78070B4C55A
```
The FPGA implementation on the Xilinx Spartan-6 xc6slx4-2-tqg144 reports:
```text
857 LUTs · 149 Slice Registers · 35% LUT utilization · 3% register utilization · 177.272 MHz maximum reported frequency · 5.641 ns critical-path delay · 0 synthesis errors
```
Overall, the project demonstrates practical experience in:
```text
Verilog RTL → Cryptographic Datapath Design → Functional Verification → FPGA Synthesis → Place & Route → Timing Analysis
```




