// n_clic
`timescale 1ns / 1ps

module n_clic
  import decoder_pkg::*;
  import config_pkg::*;
(
    input logic clk,
    input logic reset,

    // csr registers
    input logic csr_enable,
    input csr_addr_t csr_addr,
    input r rs1_zimm,
    input word rs1_data,
    input csr_op_t csr_op,

    // epc
    input IMemAddrT pc_in,
    // input IMemAddrT ra_in,

    //
    output word csr_out,
    output IMemAddrT int_addr,
    pc_interrupt_mux_t pc_interrupt_sel,
    output PrioT level_out,  // stack depth
    output logic interrupt_out
);

  // CSR m_int_thresh
  logic m_int_thresh_write_enable;
  word m_int_thresh_out;
  logic [PrioWidth-1:0] m_int_thresh_data;

  csr #(
      .CsrWidth(PrioWidth),
      .Addr(MIntThreshAddr)
  ) m_int_thresh (
      // in
      .clk,
      .reset,
      .csr_enable,
      .csr_addr,
      .rs1_zimm,
      .rs1_data,
      .csr_op,
      .ext_data(m_int_thresh_data),
      .ext_write_enable(m_int_thresh_write_enable),
      // out
      .out(m_int_thresh_out)
  );

  // packed struct allowng for 5 bit immediates in CSR
  typedef struct packed {
    logic [PrioWidth-1:0] prio;
    logic enabled;
    logic pended;  // LSB
  } entry_t;

  // stack_t data_in;

  // stack
  logic push;
  logic pop;
  typedef struct packed {
    IMemAddrT addr;
    PrioT     prio;
  } stack_t;

  stack_t stack_out;
  // epc address stack
  stack #(
      .StackDepth(PrioLevels),
      .DataWidth ($bits(stack_t))
  ) epc_stack (
      // in
      .clk,
      .reset,
      .push,
      .pop,
      .data_in  ({pc_in, m_int_thresh.data}),
      // out,
      .data_out (stack_out),
      .index_out(level_out)
  );

  // generate vector table

  typedef logic [(IMemAddrWidth - 2)-1:0] IMemAddrStore;

  entry_t                            entry           [VecSize];
  PrioT                              prio            [VecSize];
  IMemAddrStore                      csr_vec_data    [VecSize];
  logic                              ext_write_enable[VecSize];
  logic         [$bits(entry_t)-1:0] ext_entry_data;
  generate
    word temp_vec  [VecSize];
    word temp_entry[VecSize];

    for (genvar k = 0; k < VecSize; k++) begin : gen_vec
      csr #(
          .Addr(VecCsrBase + k),
          .CsrWidth(IMemAddrWidth - 2)
      ) csr_vec (
          // in
          .clk(clk),
          .reset(reset),
          .csr_enable(csr_enable),
          .csr_addr(csr_addr),
          .csr_op(csr_op),
          .rs1_zimm(rs1_zimm),
          .rs1_data(rs1_data),
          .ext_write_enable(0),
          .ext_data(0),
          // out
          .out(temp_vec[k])
      );

      csr #(
          .Addr(EntryCsrBase + k),
          .CsrWidth($bits(entry_t))
      ) csr_entry (
          // in
          .clk(clk),
          .reset(reset),
          .csr_enable(csr_enable),
          .csr_addr(csr_addr),
          .csr_op(csr_op),
          .rs1_zimm(rs1_zimm),
          .rs1_data(rs1_data),
          .ext_write_enable(ext_write_enable[k]),
          .ext_data(ext_entry_data),
          // out
          .out(temp_entry[k])
      );

      assign entry[k]        = entry_t'(temp_entry[k]);  // gen_vec[k].csr_entry.data;
      assign prio[k]         = entry[k].prio;  // a bit of a hack to please Verilator
      assign csr_vec_data[k] = IMemAddrStore'(temp_vec[k]);  // gen_vec[k].csr_vec.data;
    end
  endgenerate

  // stupid implementation to find max priority
  PrioT         max_prio [VecSize];
  IMemAddrStore max_vec  [VecSize];
  VecT          max_index[VecSize];
  always_comb begin
    // check first index in vector table
    if (entry[0].enabled && entry[0].pended && (prio[0] >= m_int_thresh.data)) begin
      max_prio[0]  = prio[0];
      max_vec[0]   = csr_vec_data[0];
      max_index[0] = 0;
    end else begin
      max_prio[0]  = m_int_thresh.data;
      max_vec[0]   = 0;
      max_index[0] = 0;
    end
    // check rest of vector table
    for (integer k = 1; k < VecSize; k++) begin
      if (entry[k].enabled && entry[k].pended && (prio[k] >= max_prio[k-1])) begin
        max_prio[k]  = prio[k];
        max_vec[k]   = csr_vec_data[k];
        max_index[k] = VecT'(k);
      end else begin
        max_prio[k]  = max_prio[k-1];
        max_vec[k]   = max_vec[k-1];
        max_index[k] = max_index[k-1];
      end
    end
  end

  // handle interrupts: tail-chain-, take-, exit- and no-interrupt
  always_comb begin
    ext_write_enable = '{default: '0};  // we don't touch the csr:s by default
    ext_entry_data   = entry[max_index[VecSize-1]] & ~1;  // clear pend bit
    // check return from interrupt condition
    if ((pc_in == ~(IMemAddrWidth'(0))) &&
        entry[max_index[VecSize-1]].enabled && entry[max_index[VecSize-1]].pended &&
        (max_prio[VecSize-1] >= m_int_thresh.data)) begin
      push = 0;
      pop = 0;
      int_addr = {max_vec[VecSize-1], 2'b00};  // convert to byte address inestruction memory
      m_int_thresh_data = 0;  // no update of threshold
      m_int_thresh_write_enable = 0;  // no update of threshold
      interrupt_out = 1;
      pc_interrupt_sel = PC_INTERRUPT;
      ext_write_enable[max_index[VecSize-1]] = 1;  // write to pended interrupt
      $display("tail chaining level_out %d, pop %d", level_out, pop);
    end else if (max_prio[VecSize-1] > m_int_thresh.data) begin
      push = 1;
      pop = 0;
      int_addr = {max_vec[VecSize-1], 2'b00};  // convert to byte address inestruction memory
      m_int_thresh_data = max_prio[VecSize-1];
      m_int_thresh_write_enable = 1;
      interrupt_out = 1;
      pc_interrupt_sel = PC_INTERRUPT;
      ext_write_enable[max_index[VecSize-1]] = 1;  // write to pended interrupt
      $display("interrupt take int_addr %d", int_addr);
    end else if (pc_in == ~(IMemAddrWidth'(0))) begin
      push = 0;
      pop = 1;
      int_addr = stack_out.addr;
      m_int_thresh_data = stack_out.prio;
      m_int_thresh_write_enable = 1;
      interrupt_out = 0;
      pc_interrupt_sel = PC_INTERRUPT;
      $display("interrupt return");
    end else begin
      push = 0;
      pop = 0;
      m_int_thresh_data = 0;
      m_int_thresh_write_enable = 0;
      int_addr = pc_in;
      interrupt_out = 0;
      pc_interrupt_sel = PC_NORMAL;
      // $display("interrupt NOT take");
    end
  end

  // set csr_out
  always_latch begin
    if (csr_addr == MIntThreshAddr) begin
      csr_out = m_int_thresh_out;
    end else begin
      for (int k = 0; k < VecSize; k++) begin
        /* verilator lint_off WIDTHEXPAND */
        if (csr_addr == VecCsrBase + k) begin
          csr_out = temp_vec[k];
          break;
        end
        if (csr_addr == EntryCsrBase + k) begin
          csr_out = temp_vec[k];
          break;
        end
      end
    end
  end
endmodule

