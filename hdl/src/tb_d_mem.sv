// tb_mem
`timescale 1ns / 1ps

module tb_d_mem;
  //import config_pkg::*;
  import decoder_pkg::*;
  import mem_pkg::*;

  logic clk;
  IMemAddrT address;
  logic[31:0] data_out;
  logic reset;
  logic write_enable;
  logic[31:0] data_in;
  logic sign_extend;
  mem_width_t width;
  d_mem_spram dut (
      .clk(clk),
      .reset(reset),
      .addr(address),
      .width(width),
      .sign_extend(sign_extend),
      .write_enable(write_enable),
      .data_in(data_in),
      .data_out(data_out)
  );


  always #10 clk = ~clk;

  initial begin
    $dumpfile("spram.fst");
    $dumpvars;
    reset = 1;
    clk = 0;
    write_enable = 0;
    address = 0;
    sign_extend = 0;
    width = mem_width_t'(WORD);
    data_in = 'hBAD01928;
    $display(data_out);

    #10;
    reset = 0;

    #10;

    address = 1;

    #20;
    
    address = 2;

    #20;
    
    address = 3;

    #20;
    
    address = 4;

    #20;
    
    address = 5;

    #20;
    
    address = 6;

    #20;
    
    address = 7;

    #20;
    
    address = 8;

    #20;
    
    width = mem_width_t'(BYTE);
    address = 0;
    
    #20;
    
    address = 1;

    #20;
    
    address = 2;

    #20;
    
    address = 3;

    #20;
    
    address = 4;

    #20;
    
    address = 5;

    #20;
    
    address = 6;

    #20;
    
    address = 7;

    #20;
    
    address = 8;

    #20;
    
    address = 9;

    #20;
    
    address = 10;

    #20;
    
    address = 11;

    #20;
    width = mem_width_t'(HALFWORD);
    address = 0;
    
    #20;
    
    address = 1;

    #20;
    
    address = 2;

    #20;
    
    address = 3;

    #20;
    
    address = 4;

    #20;
    
    address = 5;

    #20;
    
    address = 6;

    #20;
    
    address = 7;

    #20;
    
    address = 8;

    #20;
    
    address = 9;

    #20;
    
    address = 10;

    #20;
    
    address = 0;
    write_enable = 1;
    width = mem_width_t'(WORD);
    
    #20;
    
    write_enable = 0;
    
    #20;
    
    address = 4;
    write_enable = 1;
    width = mem_width_t'(BYTE);
    
    #20;

    write_enable = 0;
    width = mem_width_t'(WORD);
    
    #20;
    
    address = 8;
    write_enable = 1;
    width = mem_width_t'(HALFWORD);
    
    #20;
    
    write_enable = 0;
    width = mem_width_t'(WORD);
    
    #20;
    
    $display(data_out);

    $finish;
  end
endmodule
