`ifndef TEST_APB_UVC_TO_UVC_BASE_SV
`define TEST_APB_UVC_TO_UVC_BASE_SV

class test_apb_uvc_to_uvc_base extends uvm_test;

  // registration macro
  `uvm_component_utils(test_apb_uvc_to_uvc_base)

  // component instance
  apb_uvc_to_uvc_env_top apb_uvc_env_top_inst;

  // configuration instance
  apb_uvc_to_uvc_cfg_top uvc_cfg;

  // constructor
  extern function new(string name, uvm_component parent);
  // build phase
  extern virtual function void build_phase(uvm_phase phase);
  // end_of_elaboration phase
  extern virtual function void end_of_elaboration_phase(uvm_phase phase);
  // set default configuration
  extern virtual function void set_default_configuration();

endclass : test_apb_uvc_to_uvc_base

// constructor
function test_apb_uvc_to_uvc_base::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// build phase
function void test_apb_uvc_to_uvc_base::build_phase(uvm_phase phase);
  super.build_phase(phase);    
  
  // create component
  apb_uvc_env_top_inst = apb_uvc_to_uvc_env_top::type_id::create("apb_uvc_env_top_inst", this);
   
  // create and set configuration
  uvc_cfg = apb_uvc_to_uvc_cfg_top::type_id::create("uvc_cfg", this);

  // setting values
  set_default_configuration();

  // set configuration in DB
  uvm_config_db#(apb_uvc_to_uvc_cfg_top)::set(this, "apb_uvc_env_top_inst", "uvc_cfg", uvc_cfg);

  // enable monitor item recording
  set_config_int("*", "recording_detail", 1);
  
  // define verbosity
  uvm_top.set_report_verbosity_level_hier(UVM_HIGH);
endfunction : build_phase

// end_of_elaboration phase
function void test_apb_uvc_to_uvc_base::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);

  // allow additional time before stopping
  uvm_test_done.set_drain_time(this, 10us);
endfunction : end_of_elaboration_phase

// set default configuration
function void test_apb_uvc_to_uvc_base::set_default_configuration();
  // define default master_uvc configuration
  uvc_cfg.master_apb_uvc_cfg.agents_active_bitmap = 2'b01;           // master agent active
  uvc_cfg.master_apb_uvc_cfg.master_agent_cfg.m_has_coverage = 1;
  uvc_cfg.master_apb_uvc_cfg.master_agent_cfg.agent_mode = MASTER;  
  uvc_cfg.master_apb_uvc_cfg.slave_agent_cfg.agent_mode = SLAVE;
  uvc_cfg.master_apb_uvc_cfg.slave_agent_cfg.m_has_coverage = 1;

  // define default slave_uvc configuration
  uvc_cfg.slave_apb_uvc_cfg.agents_active_bitmap = 2'b10;           // master agent active
  uvc_cfg.slave_apb_uvc_cfg.master_agent_cfg.m_has_coverage = 1;
  uvc_cfg.slave_apb_uvc_cfg.master_agent_cfg.agent_mode = MASTER;  
  uvc_cfg.slave_apb_uvc_cfg.slave_agent_cfg.agent_mode = SLAVE;
  uvc_cfg.slave_apb_uvc_cfg.slave_agent_cfg.m_has_coverage = 1;

endfunction : set_default_configuration

`endif // TEST_APB_UVC_TO_UVC_BASE_SV
