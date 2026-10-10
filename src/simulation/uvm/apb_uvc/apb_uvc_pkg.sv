`ifndef APB_UVC_PKG_SV
`define APB_UVC_PKG_SV

`define ADDR_WIDTH  9
`define DATA_WIDTH  32
`define STRB_WIDTH  `DATA_WIDTH/8

`include "apb_uvc_if.sv"

package apb_uvc_pkg;

`include "uvm_macros.svh"
import uvm_pkg::*;

`include "apb_uvc_common.sv"
`include "apb_uvc_agent_cfg.sv"
`include "apb_uvc_cfg.sv"
`include "apb_uvc_item.sv"
`include "apb_uvc_driver.sv"
`include "apb_uvc_sequencer.sv"
`include "apb_uvc_monitor.sv"
`include "apb_uvc_cov.sv"
`include "apb_uvc_agent.sv"
`include "apb_uvc_env.sv"
`include "apb_uvc_seq_lib.sv"

endpackage : apb_uvc_pkg

`endif // APB_UVC_PKG_SV
