# cbc
CBC block cipher mode of operation for AES as specified in
[NIST SP 800-38A](https://csrc.nist.gov/publications/detail/sp/800-38a/final). This
implementation use the AES core.

The implementation is a modified version of the AES top level
wrapper. This version adds API for IV as well as the CBC chaining
functionality.

## Core Usage

### Usage sequence:
1. Load the key to be used by writing the key to the key registers (0x10..0x17).
2. Set the key length by writing to the config register.
3. Set the key length by writing to the KEYLEN bit in the config register.
4. Initialize key expansion by writing a one to the init bit in the
   control register (0x08).
5. Wait for the ready bit in the status register to be cleared and then to be set again. This means that the key expansion has been completed.
6. Write the IV to the IV registers (0x40..0x43)
7. Select encryption or decryption operation by writing (1 - ENC, or 0 -
   DEC) to the configuration register (0x0a).
8. Write the cleartext (or ciphertext) block to the block registers (0x20..0x23).
9. Start block processing by writing a one to the next bit in the control register.
10. Wait for the ready bit in the status register to be cleared and then to be set again. This means that the data block has been processed.
11. Read out the ciphertext block from the result registers (0x30..0x33).


## Implementation status
Implementation done.
Simulation gives correct results for 128 and 256 bit keys for all blocks.


## Implementation results

### FPGA results

#### Altera Cyclone-V

- ALMs:      2722
- Registers: 3208
- 92 MHz


#### Xilinx Artix-7

- LUTs:      3712
- Slices:    1950
- Registers: 3119
- 182 MHz


#### Xilinx Spartan-6

- LUTs:      3926
- Slices:    1887
- Registers: 3135
- 106 MHz
