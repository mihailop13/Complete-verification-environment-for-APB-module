`ifndef TEST_APB_UVC_BASE_SV
`define TEST_APB_UVC_BASE_SV

class test_apb_uvc_base extends uvm_test;
  
  // registration macro
  `uvm_component_utils(test_apb_uvc_base)
  
  // component instance
  apb_uvc_env_top m_apb_uvc_env_top;
  
  // configuration instance
  apb_uvc_cfg_top uvc_cfg;

  // constructor
  extern function new(string name, uvm_component parent);
  // build phase
  extern virtual function void build_phase(uvm_phase phase);
  // end_of_elaboration phase
  extern virtual function void end_of_elaboration_phase(uvm_phase phase);
  // set default configuration
  extern virtual function void set_default_configuration();
    
endclass : test_apb_uvc_base 

// constructor
function test_apb_uvc_base::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// build phase
function void test_apb_uvc_base::build_phase(uvm_phase phase);
  super.build_phase(phase);    
  
  // create component
  m_apb_uvc_env_top = apb_uvc_env_top::type_id::create("m_apb_uvc_env_top", this);
   
  // create and set configuration
  uvc_cfg = apb_uvc_cfg_top::type_id::create("uvc_cfg", this);
  // setting values
  set_default_configuration();
 
  // set configuration in DB
  uvm_config_db#(apb_uvc_cfg_top)::set(this, "m_apb_uvc_env_top", "m_cfg", uvc_cfg);

  // enable monitor item recording
  set_config_int("*", "recording_detail", 1);
  
  // define verbosity
  uvm_top.set_report_verbosity_level_hier(UVM_HIGH);
endfunction : build_phase

// end_of_elaboration phase
function void test_apb_uvc_base::end_of_elaboration_phase(uvm_phase phase);
  super.end_of_elaboration_phase(phase);

  // allow additional time before stopping
  uvm_test_done.set_drain_time(this, 10us);
endfunction : end_of_elaboration_phase

// set default configuration
function void test_apb_uvc_base::set_default_configuration();
  // define default configuration
  uvc_cfg.inst_apb_uvc_cfg.agents_active_bitmap = 2'b01; // master agent active

  uvc_cfg.inst_apb_uvc_cfg.master_agent_cfg.m_has_coverage = 1;
  uvc_cfg.inst_apb_uvc_cfg.master_agent_cfg.agent_mode = MASTER;  

  uvc_cfg.inst_apb_uvc_cfg.slave_agent_cfg.agent_mode = SLAVE;
  uvc_cfg.inst_apb_uvc_cfg.slave_agent_cfg.m_has_coverage = 1;

endfunction : set_default_configuration

`endif // TEST_APB_UVC_BASE_SV
