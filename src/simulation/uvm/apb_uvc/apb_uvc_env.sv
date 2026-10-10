`ifndef APB_UVC_ENV_SV
`define APB_UVC_ENV_SV

class apb_uvc_env extends uvm_env;
  
  // registration macro
  `uvm_component_utils(apb_uvc_env)  
  
  // configuration instance
  apb_uvc_cfg m_cfg;  

  // agent instance
  apb_uvc_agent master_apb_agent;
  apb_uvc_agent slave_apb_agent;

  // item analysis port (pass-through from the active agent's m_aport)
  uvm_analysis_port #(apb_uvc_item) m_aport;
  // reset analysis port (pass-through from the active agent's m_rst_port)
  uvm_analysis_port #(bit) m_rst_port;

  // constructor
  extern function new(string name, uvm_component parent);
  // build phase
  extern virtual function void build_phase(uvm_phase phase);
  // connect phase
  extern virtual function void connect_phase(uvm_phase phase);

endclass : apb_uvc_env

// constructor
function apb_uvc_env::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// build phase
function void apb_uvc_env::build_phase(uvm_phase phase);
  super.build_phase(phase);
  
  // get configuration
  if(!uvm_config_db #(apb_uvc_cfg)::get(this, "", "m_cfg", m_cfg)) begin
    `uvm_fatal(get_type_name(), "Failed to get configuration object from config DB! [apb_uvc_env]")
  end

  // create ports
  m_aport = new("m_aport", this);
  m_rst_port = new("m_rst_port", this);

  case(m_cfg.agents_active_bitmap)
    // create master agent
    2'b01: begin
      master_apb_agent = apb_uvc_agent::type_id::create("master_apb_agent", this);
      uvm_config_db#(apb_uvc_agent_cfg)::set(this, "master_apb_agent", "m_cfg", m_cfg.master_agent_cfg);
    end
    // create slave agent
    2'b10: begin
      slave_apb_agent = apb_uvc_agent::type_id::create("slave_apb_agent", this);
      uvm_config_db#(apb_uvc_agent_cfg)::set(this, "slave_apb_agent", "m_cfg", m_cfg.slave_agent_cfg);
    end
    // create both agents
    2'b11: begin
      master_apb_agent = apb_uvc_agent::type_id::create("master_apb_agent", this);
      slave_apb_agent = apb_uvc_agent::type_id::create("slave_apb_agent", this);
      uvm_config_db#(apb_uvc_agent_cfg)::set(this, "master_apb_agent", "m_cfg", m_cfg.master_agent_cfg);
      uvm_config_db#(apb_uvc_agent_cfg)::set(this, "slave_apb_agent", "m_cfg", m_cfg.slave_agent_cfg);
    end
  endcase
  
endfunction : build_phase

// connect phase
function void apb_uvc_env::connect_phase(uvm_phase phase);
  super.connect_phase(phase);

  case(m_cfg.agents_active_bitmap)
    // master agent active
    2'b01: begin
      master_apb_agent.m_aport.connect(m_aport);
      master_apb_agent.m_rst_port.connect(m_rst_port);
    end
    // slave agent active
    2'b10: begin
      slave_apb_agent.m_aport.connect(m_aport);
      slave_apb_agent.m_rst_port.connect(m_rst_port);
    end
    // both agents active
    2'b11: begin
      master_apb_agent.m_aport.connect(m_aport);
      master_apb_agent.m_rst_port.connect(m_rst_port);
      slave_apb_agent.m_aport.connect(m_aport);
      slave_apb_agent.m_rst_port.connect(m_rst_port);
    end
  endcase
endfunction : connect_phase

`endif // APB_UVC_ENV_SV