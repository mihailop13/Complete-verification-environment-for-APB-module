`ifndef APB_UVC_CFG_SV
`define APB_UVC_CFG_SV

class apb_uvc_cfg extends uvm_object;
  
  // agent configuration
  apb_uvc_agent_cfg   master_agent_cfg;
  apb_uvc_agent_cfg   slave_agent_cfg;
  // bitmap for what agents are active (00 - none, 01 - master, 10 - slave, 11 - both)
  bit[1:0]            agents_active_bitmap;
  
  // registration macro
  `uvm_object_utils_begin(apb_uvc_cfg)
    `uvm_field_object(master_agent_cfg, UVM_ALL_ON)
    `uvm_field_object(slave_agent_cfg, UVM_ALL_ON)
    `uvm_field_int(agents_active_bitmap, UVM_ALL_ON)
  `uvm_object_utils_end
  
  // constructor   
  extern function new(string name = "apb_uvc_cfg");
    
endclass : apb_uvc_cfg

// constructor
function apb_uvc_cfg::new(string name = "apb_uvc_cfg");
  super.new(name);
  // create agent configuration
  master_agent_cfg = apb_uvc_agent_cfg::type_id::create("m_master_agent_cfg");
  slave_agent_cfg = apb_uvc_agent_cfg::type_id::create("m_slave_agent_cfg");
endfunction : new

`endif // apb_UVC_CFG_SV
