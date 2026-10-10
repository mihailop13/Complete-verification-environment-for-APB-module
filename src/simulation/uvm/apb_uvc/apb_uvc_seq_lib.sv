`ifndef APB_UVC_SEQ_LIB_SV
`define APB_UVC_SEQ_LIB_SV

class apb_uvc_seq extends uvm_sequence #(apb_uvc_item);
  
	// registration macro
	`uvm_object_utils(apb_uvc_seq)

	// sequencer pointer macro
	`uvm_declare_p_sequencer(apb_uvc_sequencer)
	
	// fields
  	// master
	rand bit[`ADDR_WIDTH - 1:0] s_paddr;
	rand bit[`DATA_WIDTH - 1:0] s_pwdata;
	rand int s_delay_start;
 	rand bit[`STRB_WIDTH - 1:0] s_pstrb;
	rand operation_e s_operation_kind;

	// slave
	rand bit[`DATA_WIDTH - 1:0] s_prdata;
	rand int s_delay_ready;
	rand bit s_pslverr;

	// constraints  
	constraint delay_start_c	{ s_delay_start inside {[0:10]}; }
  	constraint delay_ready_c	{ s_delay_ready inside {[0:10]}; }
	
	// constructor
	extern function new(string name = "apb_uvc_seq");
	// body task
	extern virtual task body();

endclass : apb_uvc_seq

// constructor
function apb_uvc_seq::new(string name = "apb_uvc_seq");
	super.new(name);
endfunction : new

// body task
task apb_uvc_seq::body();
	req = apb_uvc_item::type_id::create("req");
	
	start_item(req);
	
	if(!req.randomize() with {
		paddr == s_paddr; pwdata == s_pwdata; 
		delay_start == s_delay_start; operation_kind == s_operation_kind; 
		delay_ready == s_delay_ready; prdata == s_prdata; 
		pstrb == s_pstrb; pslverr == s_pslverr;
	}) begin
		`uvm_fatal(get_type_name(), "Failed to randomize.")
	end  
	finish_item(req);

	if(s_operation_kind == READ) begin
		get_response(rsp);			
		`uvm_info(get_type_name(), $sformatf("Data that has been read: %h", rsp.prdata), UVM_HIGH)
	end
	
endtask : body

class write_apb_uvc_seq extends apb_uvc_seq;
	// registration macro
	`uvm_object_utils(write_apb_uvc_seq)

  	// constructor
	extern function new(string name = "write_apb_uvc_seq");
	// body task
	extern virtual task body();

endclass : write_apb_uvc_seq

// constructor
function write_apb_uvc_seq::new(string name = "write_apb_uvc_seq");
	super.new(name);
endfunction : new

// body task
task write_apb_uvc_seq::body();
	req = apb_uvc_item::type_id::create("req");
	
	start_item(req);
	
	if(!req.randomize() with {
		paddr == s_paddr; pwdata == s_pwdata; delay_start == s_delay_start; operation_kind == WRITE; delay_ready == s_delay_ready;
    prdata == s_prdata; pstrb == s_pstrb; pslverr == s_pslverr;
	}) begin
	`uvm_fatal(get_type_name(), "Failed to randomize.")
	end  
	finish_item(req);
	
endtask : body

class read_apb_uvc_seq extends apb_uvc_seq;
  	// registration macro
	`uvm_object_utils(read_apb_uvc_seq)

  	// constructor
	extern function new(string name = "read_apb_uvc_seq");
	// body task
	extern virtual task body();

endclass : read_apb_uvc_seq

// constructor
function read_apb_uvc_seq::new(string name = "read_apb_uvc_seq");
	super.new(name);
endfunction : new

// body task
task read_apb_uvc_seq::body();
	req = apb_uvc_item::type_id::create("req");
	
	start_item(req);
	
	if(!req.randomize() with {
		paddr == s_paddr; pwdata == s_pwdata; delay_start == s_delay_start; operation_kind == READ; delay_ready == s_delay_ready;
    prdata == s_prdata; pstrb == s_pstrb; pslverr == s_pslverr;
	}) begin
	`uvm_fatal(get_type_name(), "Failed to randomize.")
	end  
	finish_item(req);

	get_response(rsp);			
	`uvm_info(get_type_name(), $sformatf("Data that has been read: %h", rsp.prdata), UVM_HIGH)
	
endtask : body

class read_modify_write_apb_uvc_seq extends apb_uvc_seq;
  	// registration macro
	`uvm_object_utils(read_modify_write_apb_uvc_seq)

  	// constructor
	extern function new(string name = "read_modify_write_apb_uvc_seq");
	// body task
	extern virtual task body();

endclass : read_modify_write_apb_uvc_seq

// constructor
function read_modify_write_apb_uvc_seq::new(string name = "read_modify_write_apb_uvc_seq");
	super.new(name);
endfunction : new

// body task
task read_modify_write_apb_uvc_seq::body();
	RSP rsp = apb_uvc_item::type_id::create("rsp");   // training
	req = apb_uvc_item::type_id::create("req");
	
	start_item(req);
	
	if(!req.randomize() with {
		paddr == s_paddr; pwdata == s_pwdata; delay_start == s_delay_start; operation_kind == READ; delay_ready == s_delay_ready;
    prdata == s_prdata; pstrb == s_pstrb; pslverr == s_pslverr;
	}) begin
	  `uvm_fatal(get_type_name(), "Failed to randomize.")
	end  
	finish_item(req);
	
	// get response from driver
	get_response(rsp);			
	`uvm_info(get_type_name(), $sformatf("Data that has been read: %h", rsp.prdata), UVM_HIGH)
	//send new WRITE transaction
	start_item(req);	
	if(!req.randomize() with {
		paddr == rsp.paddr; pwdata == rsp.prdata / 2; delay_start == s_delay_start; operation_kind == WRITE;
	}) begin
	  `uvm_fatal(get_type_name(), "Failed to randomize.")
	end  
	finish_item(req);

endtask : body

class slave_apb_uvc_seq extends apb_uvc_seq;
  
	`uvm_object_utils(slave_apb_uvc_seq)

  // constructor
	extern function new(string name = "slave_apb_uvc_seq");
	// body task
	extern virtual task body();

endclass : slave_apb_uvc_seq

// constructor
function slave_apb_uvc_seq::new(string name = "slave_apb_uvc_seq");
	super.new(name);
endfunction : new

// body task
task slave_apb_uvc_seq::body();
	req = apb_uvc_item::type_id::create("req");
	
  forever begin
    this.randomize();
    start_item(req);
    
    if(!req.randomize() with {
	    paddr == s_paddr; pwdata == s_pwdata; delay_start == s_delay_start; operation_kind == s_operation_kind; delay_ready == s_delay_ready;
      prdata == s_prdata; pstrb == s_pstrb; pslverr == s_pslverr;
    }) begin
    `uvm_fatal(get_type_name(), "Failed to randomize.")
    end  
    finish_item(req);

  end
	
endtask : body

class master_apb_uvc_seq extends apb_uvc_seq;
  
	`uvm_object_utils(master_apb_uvc_seq)

	// fields
	int num_of_sequencies;
	// constructor
	extern function new(string name = "master_apb_uvc_seq");
	// body task
	extern virtual task body();

endclass : master_apb_uvc_seq

// constructor
function master_apb_uvc_seq::new(string name = "master_apb_uvc_seq");
	super.new(name);
endfunction : new

// body task
task master_apb_uvc_seq::body();
	req = apb_uvc_item::type_id::create("req");
	for(int i = 0; i < this.num_of_sequencies; i++) begin
		this.randomize();
		start_item(req);
		if(!req.randomize() with {
			paddr == s_paddr; pwdata == s_pwdata; delay_start == s_delay_start; operation_kind == s_operation_kind; delay_ready == s_delay_ready;
		prdata == s_prdata; pstrb == s_pstrb; pslverr == s_pslverr;
		}) begin
		`uvm_fatal(get_type_name(), "Failed to randomize.")
		end  
		finish_item(req);

		if(s_operation_kind == READ) begin
		get_response(rsp);			
			`uvm_info(get_type_name(), $sformatf("Data that has been read: %h", rsp.prdata), UVM_HIGH)
		end
	end
endtask : body

`endif // APB_UVC_SEQ_LIB_SV