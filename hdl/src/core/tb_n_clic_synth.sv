// tb_n_clic
`timescale 1ns / 1ps

module tb_n_clic_synth;
  import decoder_pkg::*;
  import config_pkg::*;

  localparam csr_addr_t VecCsrBase = 'hb00;

  logic clk;
  logic reset;

  logic csr_enable;
  csr_addr_t csr_addr;
  r rs1_zimm;
  word rs1_data;
  csr_op_t csr_op;
  word out;

  logic [IMemAddrWidth-1:0] pc_in;
  logic [IMemAddrWidth-1:0] n_clic_pc_out;
  n_clic dut (
      // in
      .clk,
      .reset,
      .csr_enable,
      .csr_addr,
      .rs1_zimm,
      .rs1_data,
      .csr_op,
      //
      .pc_in(pc_reg_out),
      .pc_out(n_clic_pc_out),
      // out
      .out(out)
  );

  logic [IMemAddrWidth-1:0] pc_reg_out;
  reg_n #(
      .DataWidth(IMemAddrWidth)
  ) pc_reg (
      // in
      .clk,
      .reset,
      .in (pc_mux_out),
      // out
      .out(pc_reg_out)
  );

  pc_mux_t pc_mux_sel;
  logic [IMemAddrWidth-1:0] pc_branch;
  logic [IMemAddrWidth-1:0] pc_mux_out;
  pc_mux #(
      .AddrWidth(IMemAddrWidth)
  ) pc_mux (
      // in
      .sel(pc_mux_sel),
      .pc_next(n_clic_pc_out),
      .pc_branch(pc_branch),
      // out
      .out(pc_mux_out)
  );

  // emulate the register file, for observing old_csr
  word old_csr;
  reg_n rf_reg (
      // in
      .clk,
      .reset,
      .in (out),
      // out
      .out(old_csr)
  );

  always #10 clk = ~clk;

  initial begin
    $dumpfile("n_clic.fst");
    $dumpvars;

    csr_enable = 0;
    csr_addr = 0;
    rs1_zimm = 0;
    rs1_data = 0;
    csr_op = CSRRW;
    pc_in = 0;

    clk = 0;
    reset = 1;
    #15 $display("time ", $time());  // force clock

    reset = 0;

    pc_mux_sel = PC_NEXT;
    pc_branch = 0;

    // test csr:s
    csr_addr = VecCsrBase;
    csr_enable = 1;
    rs1_zimm = 0;
    rs1_data = 0;
    csr_op = CSRRSI;

    #20;
    $display("VecCsrBase out %h", out);
    assert (out == 0);

    rs1_data = 'hfff_ffff;
    csr_op   = CSRRW;
    #20;
    $display("VecCsrBase out %h", out);
    $display("VecCsrBase old_csr %h", old_csr);
    assert (old_csr == 0);
    assert (out == 'h3f);
    csr_enable = 0;  // don't write to csr
    rs1_data   = '0;

    #20;
    $display("VecCsrBase + 2 out %h", out);
    $display("VecCsrBase + 2 old_csr %h", old_csr);
    assert (out == 'h3f);
    assert (old_csr == 'h3f);

    $finish;

  end
endmodule
