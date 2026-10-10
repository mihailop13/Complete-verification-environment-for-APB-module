`ifndef APB_UVC_COV_SV
`define APB_UVC_COV_SV

`uvm_analysis_imp_decl(_rst)

class apb_uvc_cov extends uvm_subscriber #(apb_uvc_item);
  
  // registration macro
  `uvm_component_utils(apb_uvc_cov)
  
  uvm_analysis_imp_rst#(bit, apb_uvc_cov) rst_port;

  // coverage fields
  apb_uvc_item m_item;
  bit reset;

  covergroup apb_uvc_rst_cg;
    option.per_instance = 1;
	  rst_cp: coverpoint this.reset {
		  bins reset_active = {0};
		  bins reset_inactive = {1};		
	  }
	endgroup : apb_uvc_rst_cg

  covergroup apb_uvc_cg;
    option.per_instance = 1;
    
    operation_cp: coverpoint m_item.operation_kind{
			bins operation_write = { WRITE };
			bins operation_read = { READ };
		}
    
    pstrb_cp: coverpoint m_item.pstrb; // bins are automaticaly created

    paddr_cp: coverpoint m_item.paddr;

    pwdata_cp: coverpoint m_item.pwdata iff(m_item.operation_kind == WRITE);

    idle_state_cp: coverpoint m_item.delay_start {
      bins no_idle = {0};
      bins idle = {[1:$]};
    }

		wait_states_cp: coverpoint m_item.delay_ready{
			bins no_wait_states = {0};
      bins wait_states = {[1:$]};		
		}

		error_cp: coverpoint m_item.pslverr{
			bins error_active = {1};
      bins error_not_active = {0};
		}
		
    operation_error_cross_cp: cross operation_cp, error_cp;
    wait_states_operation_cross_cp: cross operation_cp, wait_states_cp;
		operation_paddr_cross_cp: cross operation_cp, paddr_cp;
  endgroup : apb_uvc_cg
  
  // constructor
  extern function new(string name, uvm_component parent);
  // analysis implementation port function
  extern function void write(apb_uvc_item t);
  // reset analysis implementation port function
  extern function void write_rst(bit rst);

endclass : apb_uvc_cov

function apb_uvc_cov::new(string name, uvm_component parent);
  super.new(name, parent);
  apb_uvc_rst_cg = new();
	apb_uvc_rst_cg.set_inst_name("apb_uvc_rst_cg");
  apb_uvc_cg = new();
	apb_uvc_cg.set_inst_name("apb_uvc_cg");
  rst_port = new("rst_port", this);
endfunction : new

// analysis port function
function void apb_uvc_cov::write(apb_uvc_item t);
	m_item = t;
  apb_uvc_cg.sample();
endfunction : write

function void apb_uvc_cov::write_rst(bit rst);
    reset = rst;
    apb_uvc_rst_cg.sample();
endfunction : write_rst

`endif // APB_UVC_COV_SV
