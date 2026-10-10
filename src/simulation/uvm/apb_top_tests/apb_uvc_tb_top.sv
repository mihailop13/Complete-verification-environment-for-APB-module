`ifndef APB_UVC_TB_TOP_SV
`define APB_UVC_TB_TOP_SV

// define timescale
`timescale 1ns/1ns

module apb_uvc_tb_top;
  
  `include "uvm_macros.svh"  
  import uvm_pkg::*;
  
  // import test package
  import apb_uvc_test_pkg::*;
      
  // signals
  // input
  reg         PRESETn_tb;
  reg         PCLK_tb;
  apb_uvc_if apb_uvc_if_inst(PCLK_tb, PRESETn_tb);

  apb_top dut (
    .pclk    (PCLK_tb),
    .presetn (PRESETn_tb),
    .psel    (apb_uvc_if_inst.PSEL),
    .penable (apb_uvc_if_inst.PENABLE),
    .pwrite  (apb_uvc_if_inst.PWRITE),
    .paddr   (apb_uvc_if_inst.PADDR[8:0]),
    .pwdata  (apb_uvc_if_inst.PWDATA),
    .pstrb   (apb_uvc_if_inst.PSTRB),
    .prdata  (apb_uvc_if_inst.PRDATA),
    .pready  (apb_uvc_if_inst.PREADY),
    .pslverr (apb_uvc_if_inst.PSLVERR)
  );

  initial begin : config_if_block
    uvm_config_db#(virtual apb_uvc_if)::set(uvm_root::get(), "uvm_test_top.m_apb_uvc_env_top.apb_uvc_env_inst.master_apb_agent", "m_vif", apb_uvc_if_inst);
  end

  // define initial clock value and generate reset
  initial begin : clock_and_rst_init_block
    PRESETn_tb <= 1'b0;
    PCLK_tb <= 1'b1;
    #501 PRESETn_tb <= 1'b1;
  end
  
  // generate clock
  always begin : clock_gen_block
    #50 PCLK_tb <= ~PCLK_tb;
  end
  
  // run test
  initial begin : run_test_block
    run_test();
  end
  
endmodule : apb_uvc_tb_top

`endif // APB_UVC_TB_TOP_SV
