`ifndef APB_UVC_MONITOR_SV
`define APB_UVC_MONITOR_SV

class apb_uvc_monitor extends uvm_monitor;

	// registration macro
	`uvm_component_utils(apb_uvc_monitor)

	// analysis port
	uvm_analysis_port #(apb_uvc_item) m_aport;
  	uvm_analysis_port #(bit) m_rst_port;

	// virtual interface reference
	virtual interface apb_uvc_if m_vif;

	// monitor item
	apb_uvc_item m_item;

	// constructor
	extern function new(string name, uvm_component parent);
	// build phase
	extern virtual function void build_phase(uvm_phase phase);
	// run phase
	extern virtual task run_phase(uvm_phase phase);
	// handle reset
	extern virtual task handle_reset();
	// collect item
	extern virtual task collect_item();
	// print item
	extern virtual function void print_item(apb_uvc_item item);

endclass : apb_uvc_monitor

// constructor
function apb_uvc_monitor::new(string name, uvm_component parent);
	super.new(name, parent);
endfunction : new

// build phase
function void apb_uvc_monitor::build_phase(uvm_phase phase);
	super.build_phase(phase);

	// create port
	m_aport = new("m_aport", this);
  	m_rst_port = new("m_rst_port", this);
  
	// create item
	m_item = apb_uvc_item::type_id::create("m_item", this);
endfunction : build_phase

// connect phase
task apb_uvc_monitor::run_phase(uvm_phase phase);
	super.run_phase(phase);
	m_item.paddr = 0;
	m_item.pwdata = 0;
	m_item.pstrb = 0;
	m_item.prdata = 0;
	m_item.delay_start = 0;
	m_item.delay_ready = 0;
	m_item.pslverr = 0;
	forever begin
		fork : run_phase_fork_block
			begin
				handle_reset();
			end
			begin
				collect_item();    
			end
		join_any // run_phase_fork_block
		disable fork;
	end
endtask : run_phase

// handle reset
task apb_uvc_monitor::handle_reset();
	// wait reset assertion
	m_rst_port.write(1'b1);    // to cover initial reset
	@(negedge m_vif.PRESETn);
	`uvm_info(get_type_name(), "Reset asserted.", UVM_HIGH)
	m_item.paddr = 0;
	m_item.pwdata = 0;
	m_item.pstrb = 0;
	m_item.prdata = 0;
	m_item.delay_ready = 0;
	m_item.delay_start = 0;
	m_item.pslverr = 0;
	m_rst_port.write(1'b0);
endtask : handle_reset

// collect item
task apb_uvc_monitor::collect_item();  
	// wait until reset is de-asserted
	wait(m_vif.PRESETn == 1);
	`uvm_info(get_type_name(), "Reset de-asserted. Starting to collect items...", UVM_HIGH)

	forever begin
		m_item.delay_start = 0;
		m_item.delay_ready = 0; 
		// wait signal change 
		while(m_vif.PSEL == 0) begin
			m_item.delay_start++;
			@(posedge m_vif.PCLK);
		end
		//counter also counts the inital (0th) posedge -- but only when the
		//loop actually ran; guard against underflowing to -1 when PSEL was
		//already 1 (0 delay).
		if(m_item.delay_start != 0) begin
			m_item.delay_start--;
		end
		m_item.paddr = m_vif.PADDR;
		m_item.operation_kind = m_vif.PWRITE == 1 ? WRITE : READ;
		m_item.pwdata = m_vif.PWDATA;
		m_item.pstrb = m_vif.PSTRB;
		@(posedge m_vif.PENABLE);
		while(m_vif.PREADY == 0 && m_vif.PENABLE == 1) begin
			m_item.delay_ready++;
			@(posedge m_vif.PCLK);
		end
		//counter also counts the inital (0th) posedge -- but only when the
		//loop actually ran; guard against underflowing to -1 when PREADY was
		//already 1 (0 wait states).
		if(m_item.delay_ready != 0) begin
			m_item.delay_ready--;
		end
		m_item.prdata = m_vif.PRDATA;
		m_item.pslverr = m_vif.PSLVERR;
		if(m_item.operation_kind == READ) begin
				`uvm_info(get_type_name(), $sformatf("Data read: %h, from addres: %h", m_item.prdata, m_item.paddr), UVM_HIGH)
		end
		m_aport.write(m_item); 	
		print_item(m_item);
		@(negedge m_vif.PSEL);					//waiting for addr to change back to zero, driver chnages addr to zero after negedge pready
	end 
endtask : collect_item

// print item
function void apb_uvc_monitor::print_item(apb_uvc_item item);
  `uvm_info(get_type_name(), $sformatf("Item collected: \n%s", item.sprint()), UVM_HIGH)
endfunction : print_item

`endif // APB_UVC_MONITOR_SV
