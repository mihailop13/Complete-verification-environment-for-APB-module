`ifndef APB_UVC_DRIVER_SV
`define APB_UVC_DRIVER_SV

class apb_uvc_driver extends uvm_driver #(apb_uvc_item);

	// registration macro
	`uvm_component_utils(apb_uvc_driver)

	// virtual interface reference
	virtual interface apb_uvc_if m_vif;

	// configuration reference
	apb_uvc_agent_cfg m_cfg;

	// request item
	REQ m_req;
  	RSP rsp;

	// constructor
	extern function new(string name, uvm_component parent);
	// build phase
	extern virtual function void build_phase(uvm_phase phase);
	// run phase
	extern virtual task run_phase(uvm_phase phase);
	// process item
	extern virtual task process_item(apb_uvc_item item);
	//handle reset
	extern task handle_reset(apb_uvc_item item);

endclass : apb_uvc_driver

// constructor
function apb_uvc_driver::new(string name, uvm_component parent);
	super.new(name, parent);
endfunction : new

// build phase
function void apb_uvc_driver::build_phase(uvm_phase phase);
  	super.build_phase(phase);
endfunction : build_phase

// run phase
task apb_uvc_driver::run_phase(uvm_phase phase);
	super.run_phase(phase);
	// init signals
	m_vif.PADDR = 0;
	m_vif.PWRITE = 0;
	m_vif.PWDATA = 0;
	m_vif.PSTRB = 0;
	m_vif.PSEL = 0;
	m_vif.PENABLE = 0;
	m_vif.PRDATA = 0;
	m_vif.PREADY = 0;
	m_vif.PSLVERR = 0;
	wait(m_vif.PRESETn == 1);

	forever begin
	  	seq_item_port.get_next_item(m_req);
		fork : run_phase_fork_block
			begin
				process_item(m_req);
			end
			begin
				handle_reset(m_req);
			end
	  	join_any
		disable fork;
	  	seq_item_port.item_done();
	end
endtask : run_phase

// process item
task apb_uvc_driver::process_item(apb_uvc_item item);
	`uvm_info(get_type_name(), $sformatf("Item to be driven: \n%s", item.sprint()), UVM_HIGH)
	// wait until reset is de-asserted
	wait(m_vif.PRESETn == 1);  
	`uvm_info(get_type_name(), $sformatf("Reset de-asserted, proccess item: "), UVM_HIGH)
	if(m_cfg.agent_mode == MASTER) begin
		// MASTER
		repeat(item.delay_start) begin
			@(posedge m_vif.PCLK);
		end
		m_vif.PSEL <= 1;
		m_vif.PADDR <= item.paddr;
		if(item.operation_kind == READ) begin
			m_vif.PWRITE <= 0;
		m_vif.PSTRB <= 0;
		end
		else begin 
			m_vif.PWRITE <= 1;
		m_vif.PSTRB <= item.pstrb;
		end

		if(item.operation_kind == WRITE) begin
			m_vif.PWDATA <= item.pwdata;
		end

		@(posedge m_vif.PCLK);
		m_vif.PENABLE <= 1;

		@(posedge m_vif.PREADY);
	
		// slave responded
		if(item.operation_kind == READ) begin
			$cast(rsp, m_req.clone());
			rsp.set_id_info(m_req);
			rsp.prdata <= m_vif.PRDATA;
			seq_item_port.put(rsp);		// send response to sequnecer
		end

		@(negedge m_vif.PREADY);
		// end of a transaction 
		m_vif.PSEL <= 0;
		m_vif.PENABLE <= 0;
		m_vif.PADDR <= 0;
		m_vif.PWRITE <= 0;
		m_vif.PWDATA <= 0;
		m_vif.PSTRB <= 0;
	end
		else begin
		// SLAVE
		// wait for PENABLE
		@(posedge m_vif.PENABLE);
		repeat(item.delay_ready) begin
			@(posedge m_vif.PCLK);
		end
		m_vif.PREADY <= 1;
		if(m_vif.PWRITE == 0) begin
		m_vif.PRDATA <= item.prdata;
		end
		m_vif.PSLVERR <= item.pslverr;
		@(posedge m_vif.PCLK);
		m_vif.PREADY <= 0;
		m_vif.PRDATA <= 0;
		m_vif.PSLVERR <= 0;
	end
	
endtask : process_item

//handle reset
task apb_uvc_driver::handle_reset(apb_uvc_item item); 
	@(negedge m_vif.PRESETn);
	`uvm_info(get_type_name(), $sformatf("Reset de-asserted, handle reset"), UVM_HIGH)
	if(m_cfg.agent_mode == MASTER) begin
		m_vif.PADDR <= 0;
		m_vif.PWRITE <= 0;
		m_vif.PWDATA <= 0;
		m_vif.PSEL <= 0;
		m_vif.PENABLE <= 0;
		m_vif.PSTRB <= 0;
	end
	else begin
		m_vif.PRDATA <= 0;
		m_vif.PREADY <= 0;
		m_vif.PSLVERR <= 0;
	end

	if(item.operation_kind == READ) begin
		$cast(rsp, m_req.clone());
		rsp.set_id_info(m_req);
		rsp.prdata <= m_vif.PRDATA;
		seq_item_port.put(rsp);		// send response to sequnecer
	end

endtask : handle_reset

`endif // APB_UVC_DRIVER_SV
