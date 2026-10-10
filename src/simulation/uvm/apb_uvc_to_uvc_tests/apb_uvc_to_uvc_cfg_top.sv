`ifndef APB_UVC_TO_UVC_CFG_TOP_SV
`define APB_UVC_TO_UVC_CFG_TOP_SV

class apb_uvc_to_uvc_cfg_top extends uvm_object;

  // UVC configuration
  apb_uvc_cfg master_apb_uvc_cfg;
  apb_uvc_cfg slave_apb_uvc_cfg;

  // registration macro
  `uvm_object_utils_begin(apb_uvc_to_uvc_cfg_top)
    `uvm_field_object(master_apb_uvc_cfg, UVM_ALL_ON)
    `uvm_field_object(slave_apb_uvc_cfg, UVM_ALL_ON)
  `uvm_object_utils_end

  // constructor
  extern function new(string name = "apb_uvc_to_uvc_cfg_top");

endclass : apb_uvc_to_uvc_cfg_top

// constructor
function apb_uvc_to_uvc_cfg_top::new(string name = "apb_uvc_to_uvc_cfg_top");
  super.new(name);
  
  // create UVC configuration
  master_apb_uvc_cfg = apb_uvc_cfg::type_id::create("master_apb_uvc_cfg");
  slave_apb_uvc_cfg = apb_uvc_cfg::type_id::create("slave_apb_uvc_cfg");
endfunction : new

`endif // APB_UVC_TO_UVC_CFG_TOP_SV
