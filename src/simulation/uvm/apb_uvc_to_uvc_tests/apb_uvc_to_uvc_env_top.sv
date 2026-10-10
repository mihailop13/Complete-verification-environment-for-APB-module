`ifndef APB_UVC_TO_UVC_ENV_TOP_SV
`define APB_UVC_TO_UVC_ENV_TOP_SV

class apb_uvc_to_uvc_env_top extends uvm_env;
  
  // registration macro
  `uvm_component_utils(apb_uvc_to_uvc_env_top)

  // configuration reference
  apb_uvc_to_uvc_cfg_top apb_uvc_cfg_inst;

  // component instance
  apb_uvc_env master_apb_uvc_env_inst;
  apb_uvc_env slave_apb_uvc_env_inst;
  // constructor
  extern function new(string name, uvm_component parent);
  // build phase
  extern virtual function void build_phase(uvm_phase phase);
  
endclass : apb_uvc_to_uvc_env_top

// constructor
function apb_uvc_to_uvc_env_top::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// build phase
function void apb_uvc_to_uvc_env_top::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // get configuration
  if(!uvm_config_db #(apb_uvc_to_uvc_cfg_top)::get(this, "", "uvc_cfg", apb_uvc_cfg_inst)) begin
    `uvm_fatal(get_type_name(), "Failed to get configuration object from config DB [uvc_cfg]!")
  end

  // set configuration
  uvm_config_db#(apb_uvc_cfg)::set(this, "master_apb_uvc_env_inst", "m_cfg", apb_uvc_cfg_inst.master_apb_uvc_cfg);
  uvm_config_db#(apb_uvc_cfg)::set(this, "slave_apb_uvc_env_inst", "m_cfg", apb_uvc_cfg_inst.slave_apb_uvc_cfg);

  // create component
  master_apb_uvc_env_inst = apb_uvc_env::type_id::create("master_apb_uvc_env_inst", this);
  slave_apb_uvc_env_inst = apb_uvc_env::type_id::create("slave_apb_uvc_env_inst", this);
endfunction : build_phase

`endif // APB_UVC_TO_UVC_ENV_TOP_SV
