`ifndef APB_UVC_AGENT_SV
`define APB_UVC_AGENT_SV

class apb_uvc_agent extends uvm_agent;
  
  // registration macro
  `uvm_component_utils(apb_uvc_agent)

  // analysis port
  uvm_analysis_port #(apb_uvc_item) m_aport;
  // reset analysis port (pass-through from m_monitor.m_rst_port)
  uvm_analysis_port #(bit) m_rst_port;

  // virtual interface reference
  virtual interface apb_uvc_if m_vif;
      
  // configuration reference
  apb_uvc_agent_cfg m_cfg;
  
  // components instances
  apb_uvc_driver m_driver;
  apb_uvc_sequencer m_sequencer;
  apb_uvc_monitor m_monitor;
  apb_uvc_cov m_cov;
  
  // constructor
  extern function new(string name, uvm_component parent);
  // build phase
  extern virtual function void build_phase(uvm_phase phase);
  // connect phase
  extern virtual function void connect_phase(uvm_phase phase);
  // print configuration
  extern virtual function void print_cfg();

endclass : apb_uvc_agent

// constructor
function apb_uvc_agent::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// build phase
function void apb_uvc_agent::build_phase(uvm_phase phase);
  super.build_phase(phase);
  // create ports
  m_aport = new("m_aport", this);
  m_rst_port = new("m_rst_port", this);
  // get interface
  if(!uvm_config_db#(virtual apb_uvc_if)::get(this, "", "m_vif", m_vif)) begin
    `uvm_fatal(get_type_name(), "Failed to get virtual interface from config DB!")
  end

  // get configuration
  if(!uvm_config_db #(apb_uvc_agent_cfg)::get(this, "", "m_cfg", m_cfg)) begin
    `uvm_fatal(get_type_name(), "Failed to get configuration object from config DB!")
  end else begin
    print_cfg();
  end

  // create components
  // monitor is always created, it is passive by nature
  m_monitor = apb_uvc_monitor::type_id::create("m_monitor", this);
  if (m_cfg.m_has_coverage == 1) begin
    m_cov = apb_uvc_cov::type_id::create("apb_uvc_cov", this);
  end

  // driver and sequencer only make sense for an active agent
  if (m_cfg.is_active == UVM_ACTIVE) begin
    m_driver = apb_uvc_driver::type_id::create("m_driver", this);
    m_sequencer = apb_uvc_sequencer::type_id::create("m_sequencer", this);
  end
endfunction : build_phase

// connect phase
function void apb_uvc_agent::connect_phase(uvm_phase phase);
  super.connect_phase(phase);
  
  // connect ports
  m_monitor.m_aport.connect(m_aport);
  m_monitor.m_rst_port.connect(m_rst_port);
  if (m_cfg.m_has_coverage == 1) begin
    m_monitor.m_aport.connect(m_cov.analysis_export);
    m_monitor.m_rst_port.connect(m_cov.rst_port);
  end

  m_monitor.m_vif = m_vif;

  // driver and sequencer only exist for an active agent
  if (m_cfg.is_active == UVM_ACTIVE) begin
    m_driver.seq_item_port.connect(m_sequencer.seq_item_export);
    m_driver.m_vif = m_vif;
    m_driver.m_cfg = m_cfg;
    m_sequencer.m_cfg = m_cfg;
  end
endfunction : connect_phase

// print configuration
function void apb_uvc_agent::print_cfg();
  `uvm_info(get_type_name(), $sformatf("Configuration: \n%s", m_cfg.sprint()), UVM_HIGH)
endfunction : print_cfg

`endif // APB_UVC_AGENT_SV
