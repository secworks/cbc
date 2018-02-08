# cbc
CBC block cipher mode of operation for AES as specified in
[NIST SP 800-38A](https://csrc.nist.gov/publications/detail/sp/800-38a/final). This
implementation use the AES core.

The implementation is a modified version of the AES top level
wrapper. This version adds API for IV as well as the CBC chaining
functionality.


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
