//======================================================================
//
// tb_cbc.v
// --------
// Testbench for the cbc mode.
// Testvectors from:
// https://csrc.nist.gov/publications/detail/sp/800-38a/final
//
//
// Author: Joachim Strombergson
// Copyright (c) 2018, Assured AB
// All rights reserved.
//
// Redistribution and use in source and binary forms, with or
// without modification, are permitted provided that the following
// conditions are met:
//
// 1. Redistributions of source code must retain the above copyright
//    notice, this list of conditions and the following disclaimer.
//
// 2. Redistributions in binary form must reproduce the above copyright
//    notice, this list of conditions and the following disclaimer in
//    the documentation and/or other materials provided with the
//    distribution.
//
// THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
// "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
// LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS
// FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE
// COPYRIGHT OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT,
// INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING,
// BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;
// LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER
// CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT,
// STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
// ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF
// ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
//
//======================================================================


//------------------------------------------------------------------
// Test module.
//------------------------------------------------------------------
module tb_cbc();

  //----------------------------------------------------------------
  // Internal constant and parameter definitions.
  //----------------------------------------------------------------
  parameter DEBUG     = 0;

  parameter CLK_HALF_PERIOD = 1;
  parameter CLK_PERIOD      = 2 * CLK_HALF_PERIOD;

  // The DUT address map.
  parameter ADDR_NAME0       = 8'h00;
  parameter ADDR_NAME1       = 8'h01;
  parameter ADDR_VERSION     = 8'h02;

  parameter ADDR_CTRL        = 8'h08;
  parameter CTRL_INIT_BIT    = 0;
  parameter CTRL_NEXT_BIT    = 1;
  parameter CTRL_ENCDEC_BIT  = 2;
  parameter CTRL_KEYLEN_BIT  = 3;

  parameter ADDR_STATUS      = 8'h09;
  parameter STATUS_READY_BIT = 0;
  parameter STATUS_VALID_BIT = 1;

  parameter ADDR_CONFIG      = 8'h0a;

  parameter ADDR_KEY0        = 8'h10;
  parameter ADDR_KEY1        = 8'h11;
  parameter ADDR_KEY2        = 8'h12;
  parameter ADDR_KEY3        = 8'h13;
  parameter ADDR_KEY4        = 8'h14;
  parameter ADDR_KEY5        = 8'h15;
  parameter ADDR_KEY6        = 8'h16;
  parameter ADDR_KEY7        = 8'h17;

  parameter ADDR_BLOCK0      = 8'h20;
  parameter ADDR_BLOCK1      = 8'h21;
  parameter ADDR_BLOCK2      = 8'h22;
  parameter ADDR_BLOCK3      = 8'h23;

  parameter ADDR_RESULT0     = 8'h30;
  parameter ADDR_RESULT1     = 8'h31;
  parameter ADDR_RESULT2     = 8'h32;
  parameter ADDR_RESULT3     = 8'h33;

  parameter ADDR_IV0         = 8'h40;
  parameter ADDR_IV1         = 8'h41;
  parameter ADDR_IV2         = 8'h42;
  parameter ADDR_IV3         = 8'h43;

  parameter AES_128_BIT_KEY = 0;
  parameter AES_256_BIT_KEY = 1;

  parameter AES_DECIPHER = 1'b0;
  parameter AES_ENCIPHER = 1'b1;


  //----------------------------------------------------------------
  // Register and Wire declarations.
  //----------------------------------------------------------------
  reg [31 : 0]  cycle_ctr;
  reg [31 : 0]  error_ctr;
  reg [31 : 0]  tc_ctr;

  reg [31 : 0]  read_data;
  reg [127 : 0] result_data;

  reg           tb_clk;
  reg           tb_reset_n;
  reg           tb_cs;
  reg           tb_we;
  reg [7  : 0]  tb_address;
  reg [31 : 0]  tb_write_data;
  wire [31 : 0] tb_read_data;


  //----------------------------------------------------------------
  // Device Under Test.
  //----------------------------------------------------------------
  cbc dut(
          .clk(tb_clk),
          .reset_n(tb_reset_n),
          .cs(tb_cs),
          .we(tb_we),
          .address(tb_address),
          .write_data(tb_write_data),
          .read_data(tb_read_data)
         );


  //----------------------------------------------------------------
  // clk_gen
  //
  // Always running clock generator process.
  //----------------------------------------------------------------
  always
    begin : clk_gen
      #CLK_HALF_PERIOD;
      tb_clk = !tb_clk;
    end // clk_gen


  //----------------------------------------------------------------
  // sys_monitor()
  //
  // An always running process that creates a cycle counter and
  // conditionally displays information about the DUT.
  //----------------------------------------------------------------
  always
    begin : sys_monitor
      cycle_ctr = cycle_ctr + 1;

      #(CLK_PERIOD);

      if (DEBUG)
        begin
          dump_dut_state();
        end
    end


  //----------------------------------------------------------------
  // dump_dut_state()
  //
  // Dump the state of the dump when needed.
  //----------------------------------------------------------------
  task dump_dut_state;
    begin
      $display("cycle: 0x%016x", cycle_ctr);
      $display("State of DUT");
      $display("------------");
      $display("ctrl_reg:   init   = 0x%01x, next   = 0x%01x", dut.init_reg, dut.next_reg);
      $display("config_reg: encdec = 0x%01x, length = 0x%01x ", dut.encdec_reg, dut.keylen_reg);
      $display("");

      $display("block: 0x%08x, 0x%08x, 0x%08x, 0x%08x",
               dut.block_reg[0], dut.block_reg[1], dut.block_reg[2], dut.block_reg[3]);
      $display("iv:    0x%08x, 0x%08x, 0x%08x, 0x%08x",
               dut.iv_reg[0], dut.iv_reg[1], dut.iv_reg[2], dut.iv_reg[3]);
      $display("");
      $display("cbc block: 0x%032x", dut.core_block);
      $display("");

    end
  endtask // dump_dut_state


  //----------------------------------------------------------------
  // reset_dut()
  //
  // Toggle reset to put the DUT into a well known state.
  //----------------------------------------------------------------
  task reset_dut;
    begin
      $display("*** Toggle reset.");
      tb_reset_n = 0;

      #(2 * CLK_PERIOD);
      tb_reset_n = 1;
      $display("");
    end
  endtask // reset_dut


  //----------------------------------------------------------------
  // display_test_results()
  //
  // Display the accumulated test results.
  //----------------------------------------------------------------
  task display_test_results;
    begin
      if (error_ctr == 0)
        begin
          $display("*** All %02d test cases completed successfully", tc_ctr);
        end
      else
        begin
          $display("*** %02d tests completed - %02d test cases did not complete successfully.",
                   tc_ctr, error_ctr);
        end
    end
  endtask // display_test_results


  //----------------------------------------------------------------
  // init_sim()
  //
  // Initialize all counters and testbed functionality as well
  // as setting the DUT inputs to defined values.
  //----------------------------------------------------------------
  task init_sim;
    begin
      cycle_ctr     = 0;
      error_ctr     = 0;
      tc_ctr        = 0;

      tb_clk        = 0;
      tb_reset_n    = 1;

      tb_cs         = 0;
      tb_we         = 0;
      tb_address    = 8'h0;
      tb_write_data = 32'h0;
    end
  endtask // init_sim


  //----------------------------------------------------------------
  // write_word()
  //
  // Write the given word to the DUT using the DUT interface.
  //----------------------------------------------------------------
  task write_word(input [11 : 0] address,
                  input [31 : 0] word);
    begin
      if (DEBUG)
        begin
          $display("*** Writing 0x%08x to 0x%02x.", word, address);
          $display("");
        end

      tb_address = address;
      tb_write_data = word;
      tb_cs = 1;
      tb_we = 1;
      #(2 * CLK_PERIOD);
      tb_cs = 0;
      tb_we = 0;
    end
  endtask // write_word


  //----------------------------------------------------------------
  // write_block()
  //
  // Write the given block to the dut.
  //----------------------------------------------------------------
  task write_block(input [127 : 0] block);
    begin
      write_word(ADDR_BLOCK0, block[127  :  96]);
      write_word(ADDR_BLOCK1, block[95   :  64]);
      write_word(ADDR_BLOCK2, block[63   :  32]);
      write_word(ADDR_BLOCK3, block[31   :   0]);
    end
  endtask // write_block


  //----------------------------------------------------------------
  // write_iv()
  //
  // Write the given block to the dut.
  //----------------------------------------------------------------
  task write_iv(input [127 : 0] iv);
    begin
      write_word(ADDR_IV0, iv[127  :  96]);
      write_word(ADDR_IV1, iv[95   :  64]);
      write_word(ADDR_IV2, iv[63   :  32]);
      write_word(ADDR_IV3, iv[31   :   0]);
    end
  endtask // write_iv


  //----------------------------------------------------------------
  // read_word()
  //
  // Read a data word from the given address in the DUT.
  // the word read will be available in the global variable
  // read_data.
  //----------------------------------------------------------------
  task read_word(input [11 : 0]  address);
    begin
      tb_address = address;
      tb_cs = 1;
      tb_we = 0;
      #(CLK_PERIOD);
      read_data = tb_read_data;
      tb_cs = 0;

      if (DEBUG)
        begin
          $display("*** Reading 0x%08x from 0x%02x.", read_data, address);
          $display("");
        end
    end
  endtask // read_word


  //----------------------------------------------------------------
  // read_result()
  //
  // Read the result block in the dut.
  //----------------------------------------------------------------
  task read_result;
    begin
      read_word(ADDR_RESULT0);
      result_data[127 : 096] = read_data;
      read_word(ADDR_RESULT1);
      result_data[095 : 064] = read_data;
      read_word(ADDR_RESULT2);
      result_data[063 : 032] = read_data;
      read_word(ADDR_RESULT3);
      result_data[031 : 000] = read_data;
    end
  endtask // read_result


  //----------------------------------------------------------------
  // init_key()
  //
  // init the key in the dut by writing the given key and
  // key length and then trigger init processing.
  //----------------------------------------------------------------
  task init_key(input [255 : 0] key, input key_length);
    begin
      if (DEBUG)
        begin
          $display("key length: 0x%01x", key_length);
          $display("Initializing key expansion for key: 0x%016x", key);
        end

      write_word(ADDR_KEY0, key[255  : 224]);
      write_word(ADDR_KEY1, key[223  : 192]);
      write_word(ADDR_KEY2, key[191  : 160]);
      write_word(ADDR_KEY3, key[159  : 128]);
      write_word(ADDR_KEY4, key[127  :  96]);
      write_word(ADDR_KEY5, key[95   :  64]);
      write_word(ADDR_KEY6, key[63   :  32]);
      write_word(ADDR_KEY7, key[31   :   0]);

      if (key_length)
        begin
          write_word(ADDR_CONFIG, 8'h02);
        end
      else
        begin
          write_word(ADDR_CONFIG, 8'h00);
        end

      write_word(ADDR_CTRL, 8'h01);

      #(100 * CLK_PERIOD);
    end
  endtask // init_key


  //----------------------------------------------------------------
  // check_result()
  //----------------------------------------------------------------
  task check_result(input [127 : 0] result, input [127 : 0] expected);
    begin
      if (result == expected)
        begin
          $display("*** Correct result received");
          $display("");
        end
      else
        begin
          $display("*** ERROR: Incorrect result");
          $display("Expected: 0x%032x", expected);
          $display("Got:      0x%032x", result);
          $display("");

          error_ctr = error_ctr + 1;
        end
    end
  endtask // cbc_mode_single_block_test


  //----------------------------------------------------------------
  // cbc_128_test()
  //----------------------------------------------------------------
  task cbc_128_test;
    reg [255 : 0] nist_aes128_key;
    reg [255 : 0] nist_aes256_key;

    reg [127 : 0] nist_plaintext0;
    reg [127 : 0] nist_plaintext1;
    reg [127 : 0] nist_plaintext2;
    reg [127 : 0] nist_plaintext3;

    reg [127 : 0] nist_iv;

    reg [127 : 0] nist_cbc_128_enc_expected0;
    reg [127 : 0] nist_cbc_128_enc_expected1;
    reg [127 : 0] nist_cbc_128_enc_expected2;
    reg [127 : 0] nist_cbc_128_enc_expected3;

    reg [127 : 0] nist_cbc_256_enc_expected0;
    reg [127 : 0] nist_cbc_256_enc_expected1;
    reg [127 : 0] nist_cbc_256_enc_expected2;
    reg [127 : 0] nist_cbc_256_enc_expected3;

    begin
      nist_aes128_key = 256'h2b7e151628aed2a6abf7158809cf4f3c00000000000000000000000000000000;

      nist_plaintext0 = 128'h6bc1bee22e409f96e93d7e117393172a;
      nist_plaintext1 = 128'hae2d8a571e03ac9c9eb76fac45af8e51;
      nist_plaintext2 = 128'h30c81c46a35ce411e5fbc1191a0a52ef;
      nist_plaintext3 = 128'hf69f2445df4f9b17ad2b417be66c3710;

      nist_iv = 128'h000102030405060708090a0b0c0d0e0f;

      nist_cbc_128_enc_expected0 = 128'h7649abac8119b246cee98e9b12e9197d;
      nist_cbc_128_enc_expected1 = 128'h5086cb9b507219ee95db113a917678b2;
      nist_cbc_128_enc_expected2 = 128'h73bed6b8e3c1743b7116e69e22229516;
      nist_cbc_128_enc_expected3 = 128'h3ff1caa1681fac09120eca307586e1a7;


      $display("CBC 128 bit key test");
      $display("--------------------");

      init_key(nist_aes128_key, AES_128_BIT_KEY);

      $display("First block.");
      tc_ctr = tc_ctr + 1;
      write_block(nist_plaintext0);
      write_iv(nist_iv);
      write_word(ADDR_CONFIG, (8'h00 + (AES_128_BIT_KEY << 1) + AES_ENCIPHER));
      write_word(ADDR_CTRL, 8'h02);
      #(100 * CLK_PERIOD);
      read_result();
      check_result(result_data, nist_cbc_128_enc_expected0);

      $display("Second block.");
      tc_ctr = tc_ctr + 1;
      write_block(nist_plaintext1);
      write_word(ADDR_CONFIG, (8'h00 + (AES_128_BIT_KEY << 1) + AES_ENCIPHER));
      write_word(ADDR_CTRL, 8'h02);
      #(100 * CLK_PERIOD);
      read_result();
      check_result(result_data, nist_cbc_128_enc_expected1);

      $display("Third block.");
      tc_ctr = tc_ctr + 1;
      write_block(nist_plaintext2);
      write_word(ADDR_CONFIG, (8'h00 + (AES_128_BIT_KEY << 1) + AES_ENCIPHER));
      write_word(ADDR_CTRL, 8'h02);
      #(100 * CLK_PERIOD);
      read_result();
      check_result(result_data, nist_cbc_128_enc_expected2);

      $display("Fourth block.");
      tc_ctr = tc_ctr + 1;
      write_block(nist_plaintext3);
      write_word(ADDR_CONFIG, (8'h00 + (AES_128_BIT_KEY << 1) + AES_ENCIPHER));
      write_word(ADDR_CTRL, 8'h02);
      #(100 * CLK_PERIOD);
      read_result();
      check_result(result_data, nist_cbc_128_enc_expected3);
    end
  endtask // cbc_128_test


  //----------------------------------------------------------------
  // cbc_256_test()
  //----------------------------------------------------------------
  task cbc_256_test;
    reg [255 : 0] nist_aes256_key;

    reg [127 : 0] nist_plaintext0;
    reg [127 : 0] nist_plaintext1;
    reg [127 : 0] nist_plaintext2;
    reg [127 : 0] nist_plaintext3;

    reg [127 : 0] nist_iv;

    reg [127 : 0] nist_cbc_256_enc_expected0;
    reg [127 : 0] nist_cbc_256_enc_expected1;
    reg [127 : 0] nist_cbc_256_enc_expected2;
    reg [127 : 0] nist_cbc_256_enc_expected3;

    begin
      nist_aes256_key = 256'h603deb1015ca71be2b73aef0857d77811f352c073b6108d72d9810a30914dff4;

      nist_plaintext0 = 128'h6bc1bee22e409f96e93d7e117393172a;
      nist_plaintext1 = 128'hae2d8a571e03ac9c9eb76fac45af8e51;
      nist_plaintext2 = 128'h30c81c46a35ce411e5fbc1191a0a52ef;
      nist_plaintext3 = 128'hf69f2445df4f9b17ad2b417be66c3710;

      nist_iv = 128'h000102030405060708090a0b0c0d0e0f;

      nist_cbc_256_enc_expected0 = 128'hf58c4c04d6e5f1ba779eabfb5f7bfbd6;
      nist_cbc_256_enc_expected1 = 128'h9cfc4e967edb808d679f777bc6702c7d;
      nist_cbc_256_enc_expected2 = 128'h39f23369a9d9bacfa530e26304231461;
      nist_cbc_256_enc_expected3 = 128'hb2eb05e2c39be9fcda6c19078c6a9d1b;


      $display("");
      $display("CBC 256 bit key test");
      $display("--------------------");


      init_key(nist_aes256_key, AES_256_BIT_KEY);

      $display("First block.");
      tc_ctr = tc_ctr + 1;
      write_block(nist_plaintext0);
      write_iv(nist_iv);
      write_word(ADDR_CONFIG, (8'h00 + (AES_256_BIT_KEY << 1) + AES_ENCIPHER));
      write_word(ADDR_CTRL, 8'h02);
      #(100 * CLK_PERIOD);
      read_result();
      check_result(result_data, nist_cbc_256_enc_expected0);

      $display("Second block.");
      tc_ctr = tc_ctr + 1;
      write_block(nist_plaintext1);
      write_word(ADDR_CONFIG, (8'h00 + (AES_256_BIT_KEY << 1) + AES_ENCIPHER));
      write_word(ADDR_CTRL, 8'h02);
      #(100 * CLK_PERIOD);
      read_result();
      check_result(result_data, nist_cbc_256_enc_expected1);

      $display("Third block.");
      tc_ctr = tc_ctr + 1;
      write_block(nist_plaintext2);
      write_word(ADDR_CONFIG, (8'h00 + (AES_256_BIT_KEY << 1) + AES_ENCIPHER));
      write_word(ADDR_CTRL, 8'h02);
      #(100 * CLK_PERIOD);
      read_result();
      check_result(result_data, nist_cbc_256_enc_expected2);

      $display("Fourth block.");
      tc_ctr = tc_ctr + 1;
      write_block(nist_plaintext3);
      write_word(ADDR_CONFIG, (8'h00 + (AES_256_BIT_KEY << 1) + AES_ENCIPHER));
      write_word(ADDR_CTRL, 8'h02);
      #(100 * CLK_PERIOD);
      read_result();
      check_result(result_data, nist_cbc_256_enc_expected3);
    end
  endtask // cbc_256_test


  //----------------------------------------------------------------
  // main
  //
  // The main test functionality.
  //----------------------------------------------------------------
  initial
    begin : main
      $display("   -= Testbench for CBC started =-");
      $display("    ==============================");
      $display("");

      init_sim();
      dump_dut_state();
      reset_dut();
      dump_dut_state();

      cbc_128_test();
      cbc_256_test();

      display_test_results();

      $display("");
      $display("*** CBC simulation done. ***");
      $finish;
    end // main
endmodule // tb_cbc

//======================================================================
// EOF tb_cbc.v
//======================================================================
