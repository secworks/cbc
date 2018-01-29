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

#### Altera Cyclone V

ALMs:      2722
Registers: 3208
Max clock:   92 MHz
