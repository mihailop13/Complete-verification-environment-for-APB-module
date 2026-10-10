`ifndef APB_UVC_IF_SV
`define APB_UVC_IF_SV

interface apb_uvc_if(input PCLK, input PRESETn);
  
  `include "uvm_macros.svh"
  import uvm_pkg::*;
  
  // signals
  logic [`ADDR_WIDTH-1:0]   PADDR;
  logic                     PWRITE;
  logic [`DATA_WIDTH-1:0]   PWDATA;
  logic [`DATA_WIDTH-1:0]   PRDATA;
  logic                     PREADY;
  logic [`STRB_WIDTH-1:0]   PSTRB;
  logic                     PSEL;
  logic                     PENABLE;
  logic                     PSLVERR;
  
  SVA_penable_assert_chk:    assert property(@(posedge PCLK) disable iff (!PRESETn) $rose(PSEL) |=> PENABLE);
  
  SVA_pstrb_read_chk:        assert property(@(posedge PCLK) disable iff (!PRESETn) !PWRITE |-> !PSTRB);

  SVA_prdata_chk:            assert property(@(posedge PCLK) disable iff (!PRESETn) $rose(PREADY) && !PWRITE |-> !$isunknown(PRDATA));

  SVA_signals_after_rst_chk: assert property(@(posedge PCLK) disable iff (!PRESETn) PRESETn |-> !$isunknown(PADDR) && !$isunknown(PWRITE) && !$isunknown(PWDATA) && !$isunknown(PSEL) && !$isunknown(PENABLE) && !$isunknown(PREADY) && !$isunknown(PSTRB) && !$isunknown(PRDATA) && !$isunknown(PSLVERR));
  
  SVA_pready_chk:            assert property(@(posedge PCLK) disable iff (!PRESETn) $rose(PREADY) |-> PENABLE && PSEL);

  SVA_error_chk:             assert property(@(posedge PCLK) disable iff (!PRESETn) $rose(PSLVERR) |-> $rose(PREADY));
  
  SVA_psel_stable_chk:       assert property(@(posedge PCLK) disable iff (!PRESETn) $rose(PSEL) |=> PSEL s_until_with PREADY);

  SVA_paddr_stable_chk:      assert property(@(posedge PCLK) disable iff (!PRESETn) $rose(PSEL) |=> !$changed(PADDR) s_until_with PREADY);

  SVA_pwrite_stable_chk:     assert property(@(posedge PCLK) disable iff (!PRESETn) $rose(PSEL) |=> !$changed(PWRITE) s_until_with PREADY);

  SVA_penable_stable_chk:    assert property(@(posedge PCLK) disable iff (!PRESETn) $rose(PENABLE) |-> PENABLE s_until_with PREADY);

  SVA_pready_duration_chk:     assert property(@(posedge PCLK) disable iff (!PRESETn) $rose(PREADY) |=> $fell(PREADY));
  
endinterface : apb_uvc_if

`endif // APB_UVC_IF_SV
