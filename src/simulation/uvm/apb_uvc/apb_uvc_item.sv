`ifndef APB_UVC_ITEM_SV
`define APB_UVC_ITEM_SV

class apb_uvc_item extends uvm_sequence_item;
	// item fields
  	// master
	rand bit[`ADDR_WIDTH - 1 : 0] 	paddr;   
	rand bit[`DATA_WIDTH - 1 : 0] 	pwdata;
	rand int 						delay_start;
  	rand bit[`STRB_WIDTH - 1 : 0] 	pstrb;
	rand operation_e 				operation_kind;
  
  	// slave
	rand int delay_ready;
	rand bit[`DATA_WIDTH - 1 : 0] prdata;
  	rand bit pslverr;

	// registration macro
	`uvm_object_utils_begin(apb_uvc_item)
		`uvm_field_int(paddr, UVM_DEFAULT)
		`uvm_field_int(pwdata, UVM_DEFAULT)
		`uvm_field_int(delay_start, UVM_DEFAULT)
		`uvm_field_int(delay_ready, UVM_DEFAULT)
		`uvm_field_int(prdata, UVM_DEFAULT)
		`uvm_field_int(pstrb, UVM_DEFAULT)
		`uvm_field_int(pslverr, UVM_DEFAULT)
		`uvm_field_int(prdata, UVM_DEFAULT)
		`uvm_field_enum(operation_e, operation_kind, UVM_DEFAULT)
	`uvm_object_utils_end

	// constraints
	constraint addr_align_c		{ soft paddr % 4 == 0; }             
  
	constraint delay_start_c	{ soft delay_start inside {[0:10]}; }
  	constraint delay_ready_c	{ soft delay_ready inside {[0:10]}; }
  
	// constructor  
	extern function new(string name = "apb_uvc_item");

endclass : apb_uvc_item

// constructor
function apb_uvc_item::new(string name = "apb_uvc_item");
  super.new(name);
endfunction : new

`endif // APB_UVC_ITEM_SV