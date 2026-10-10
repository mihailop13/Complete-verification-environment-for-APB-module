`ifndef APB_UVC_ENV_TOP_SV
`define APB_UVC_ENV_TOP_SV

class apb_uvc_env_top extends uvm_env;
  
  // registration macro
  `uvm_component_utils(apb_uvc_env_top)

  // configuration reference
  apb_uvc_cfg_top uvc_cfg;  
    
  // component instance
  apb_uvc_env apb_uvc_env_inst;
  // reference model checking the DUT via the master agent's monitor
  apb_scoreboard m_scoreboard;
  // global functional coverage, fed by the same master agent's monitor
  apb_coverage m_coverage;
  // constructor
  extern function new(string name, uvm_component parent);
  // build phase
  extern virtual function void build_phase(uvm_phase phase);
  // connect phase
  extern virtual function void connect_phase(uvm_phase phase);

endclass : apb_uvc_env_top

// constructor
function apb_uvc_env_top::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// build phase
function void apb_uvc_env_top::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // get configuration
  if(!uvm_config_db #(apb_uvc_cfg_top)::get(this, "", "m_cfg", uvc_cfg)) begin
    `uvm_fatal(get_type_name(), "Failed to get configuration object from config DB [uvc_cfg]!")
  end

  // set configuration
  uvm_config_db#(apb_uvc_cfg)::set(this, "apb_uvc_env_inst", "m_cfg", uvc_cfg.inst_apb_uvc_cfg);

  // create component
  apb_uvc_env_inst = apb_uvc_env::type_id::create("apb_uvc_env_inst", this);

  // create reference model
  m_scoreboard = apb_scoreboard::type_id::create("m_scoreboard", this);

  // create global functional coverage
  m_coverage = apb_coverage::type_id::create("m_coverage", this);
endfunction : build_phase

// connect phase
function void apb_uvc_env_top::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  // hook the scoreboard up to the master agent's monitor (the agent that
  // drives apb_top in apb_uvc_tb_top.sv), via the env's pass-through ports
  apb_uvc_env_inst.m_aport.connect(m_scoreboard.item_imp_port);
  apb_uvc_env_inst.m_rst_port.connect(m_scoreboard.rst_imp_port);

  // hook the global coverage collector up to the same monitor
  apb_uvc_env_inst.m_aport.connect(m_coverage.analysis_export);
  apb_uvc_env_inst.m_rst_port.connect(m_coverage.rst_imp_port);
endfunction : connect_phase

`endif // APB_UVC_ENV_TOP_SV
