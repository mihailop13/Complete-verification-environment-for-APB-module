`ifndef APB_UVC_AGENT_CFG_SV
`define APB_UVC_AGENT_CFG_SV

class apb_uvc_agent_cfg extends uvm_object;
  
  // configuration fields
  bit m_has_coverage;
  agent_mode_e agent_mode;
  // active/passive configuration - driver/sequencer are only created when UVM_ACTIVE
  uvm_active_passive_enum is_active;

  // registration macro
  `uvm_object_utils_begin(apb_uvc_agent_cfg)
    `uvm_field_int(m_has_coverage, UVM_ALL_ON)
    `uvm_field_enum(agent_mode_e, agent_mode, UVM_ALL_ON)
    `uvm_field_enum(uvm_active_passive_enum, is_active, UVM_ALL_ON)
  `uvm_object_utils_end

  // constructor
  extern function new(string name = "apb_uvc_agent_cfg");

endclass : apb_uvc_agent_cfg

// constructor
function apb_uvc_agent_cfg::new(string name = "apb_uvc_agent_cfg");
  super.new(name);
  // active by default, matches uvm_agent's own default
  is_active = UVM_ACTIVE;
endfunction : new

`endif // APB_UVC_AGENT_CFG_SV
