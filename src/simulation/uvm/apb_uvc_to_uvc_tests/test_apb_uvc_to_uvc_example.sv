`ifndef TEST_APB_UVC_TO_UVC_EXAMPLE_SV
`define TEST_APB_UVC_TO_UVC_EXAMPLE_SV

class test_apb_uvc_to_uvc_example extends test_apb_uvc_to_uvc_base;

  // registration macro
  `uvm_component_utils(test_apb_uvc_to_uvc_example)

  // fields
  int num_of_trans            = 200; // master_apb_uvc_seq
  int num_of_full_range_trans = 600; // write_apb_uvc_seq / read_apb_uvc_seq
  int num_of_rmw_trans        = 70; // read_modify_write_apb_uvc_seq

  // sequences
  slave_apb_uvc_seq slave_seq;

  // constructor
  extern function new(string name, uvm_component parent);
  // run phase
  extern virtual task run_phase(uvm_phase phase);
  // set default configuration
  extern function void set_default_configuration();
  // master-side driving, forked alongside the slave responder in run_phase
  extern task drive_master();

endclass : test_apb_uvc_to_uvc_example

// constructor
function test_apb_uvc_to_uvc_example::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// master-side driving
task test_apb_uvc_to_uvc_example::drive_master();
  master_apb_uvc_seq             master_seq;
  write_apb_uvc_seq              wr_seq;
  read_apb_uvc_seq                rd_seq;
  read_modify_write_apb_uvc_seq   rmw_seq;

  master_seq = master_apb_uvc_seq::type_id::create("master_seq", this);
  master_seq.num_of_sequencies = num_of_trans;
  master_seq.start(apb_uvc_env_top_inst.master_apb_uvc_env_inst.master_apb_agent.m_sequencer);

  for (int i = 0; i < num_of_full_range_trans; i++) begin
    if ($urandom_range(1, 0) == 0) begin
      wr_seq = write_apb_uvc_seq::type_id::create("wr_seq", this);
      if(!wr_seq.randomize() with {
        s_operation_kind == WRITE;
        s_delay_ready    == 0;
      }) begin
        `uvm_fatal(get_type_name(), "Failed to randomize wr_seq.")
      end
      wr_seq.start(apb_uvc_env_top_inst.master_apb_uvc_env_inst.master_apb_agent.m_sequencer);
    end else begin
      rd_seq = read_apb_uvc_seq::type_id::create("rd_seq", this);
      if(!rd_seq.randomize() with {
        s_operation_kind == READ;
        s_delay_ready    == 0;
      }) begin
        `uvm_fatal(get_type_name(), "Failed to randomize rd_seq.")
      end
      rd_seq.start(apb_uvc_env_top_inst.master_apb_uvc_env_inst.master_apb_agent.m_sequencer);
    end
  end

  // 3) read-modify-write
  for (int i = 0; i < num_of_rmw_trans; i++) begin
    rmw_seq = read_modify_write_apb_uvc_seq::type_id::create("rmw_seq", this);
    if(!rmw_seq.randomize()) begin
      `uvm_fatal(get_type_name(), "Failed to randomize rmw_seq.")
    end
    rmw_seq.start(apb_uvc_env_top_inst.master_apb_uvc_env_inst.master_apb_agent.m_sequencer);
  end
endtask : drive_master

// run phase
task test_apb_uvc_to_uvc_example::run_phase(uvm_phase phase);
  super.run_phase(phase);

  uvm_test_done.raise_objection(this, get_type_name());
  `uvm_info(get_type_name(), "TEST STARTED", UVM_LOW)

  slave_seq = slave_apb_uvc_seq::type_id::create("slave_seq", this);

  fork : seq_fork_block
    begin
      slave_seq.start(apb_uvc_env_top_inst.slave_apb_uvc_env_inst.slave_apb_agent.m_sequencer);
    end
    begin
      drive_master();
    end
    join_any
  disable fork;

  #500;
  uvm_test_done.drop_objection(this, get_type_name());
  `uvm_info(get_type_name(), "TEST FINISHED", UVM_LOW)
endtask : run_phase

// set default configuration
function void test_apb_uvc_to_uvc_example::set_default_configuration();
  super.set_default_configuration();
endfunction : set_default_configuration

`endif // TEST_APB_UVC_TO_UVC_EXAMPLE_SV
