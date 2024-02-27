// wb_mux
`timescale 1ns / 1ps

import decoder_pkg::*;
module wb_mux (
    input wb_mux_t sel,
    input word alu,
    input word dm,
    input word csr,
    input word pc_plus_4,
    output word out
);

  always begin
    case (sel)
      WB_ALU: out = alu;
      WB_DM: out = dm;
      WB_CSR: out = csr;
      WB_PC_PLUS_4: out = pc_plus_4;
      default: out = alu;
    endcase
  end

endmodule
