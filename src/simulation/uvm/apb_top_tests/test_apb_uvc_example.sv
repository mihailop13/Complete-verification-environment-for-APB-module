`ifndef TEST_APB_UVC_EXAMPLE_SV
`define TEST_APB_UVC_EXAMPLE_SV

class test_apb_uvc_example extends test_apb_uvc_base;

  // registration macro
  `uvm_component_utils(test_apb_uvc_example)

  // address map of DUT (mirrors apb_coverage/apb_scoreboard)
  localparam bit [`ADDR_WIDTH-1:0] CSR_STATUS_ADDR = 9'd256;
  localparam bit [`ADDR_WIDTH-1:0] CSR_CTRL_ADDR   = 9'd257;
  localparam bit [`ADDR_WIDTH-1:0] RO_MEM_ADDR     = 9'd240;

  // fields
  int num_of_full_range_trans_per_block = 500; // write_apb_uvc_seq / read_apb_uvc_seq, per block (x4 blocks)
  int num_of_rmw_trans                 = 100;  // read_modify_write_apb_uvc_seq

  // constructor
  extern function new(string name, uvm_component parent);
  // run phase
  extern virtual task run_phase(uvm_phase phase);
  // set default configuration
  extern function void set_default_configuration();

endclass : test_apb_uvc_example

// constructor
function test_apb_uvc_example::new(string name, uvm_component parent);
  super.new(name, parent);
endfunction : new

// run phase
task test_apb_uvc_example::run_phase(uvm_phase phase);
  write_apb_uvc_seq             wr_seq;
  read_apb_uvc_seq               rd_seq;
  read_modify_write_apb_uvc_seq  rmw_seq;

  super.run_phase(phase);

  uvm_test_done.raise_objection(this, get_type_name());
  `uvm_info(get_type_name(), "TEST STARTED", UVM_LOW)

  // initial CTRL/STATUS read 
  rd_seq = read_apb_uvc_seq::type_id::create("rd_seq", this);
  if(!rd_seq.randomize() with {
    s_paddr          == CSR_CTRL_ADDR;
    s_operation_kind == READ;
    s_delay_ready    == 0;
  }) begin
    `uvm_fatal(get_type_name(), "Failed to randomize rd_seq (initial CTRL read).")
  end
  rd_seq.start(m_apb_uvc_env_top.apb_uvc_env_inst.master_apb_agent.m_sequencer);

  rd_seq = read_apb_uvc_seq::type_id::create("rd_seq", this);
  if(!rd_seq.randomize() with {
    s_paddr          == CSR_STATUS_ADDR;
    s_operation_kind == READ;
    s_delay_ready    == 0;
  }) begin
    `uvm_fatal(get_type_name(), "Failed to randomize rd_seq (initial STATUS read).")
  end
  rd_seq.start(m_apb_uvc_env_top.apb_uvc_env_inst.master_apb_agent.m_sequencer);

  //  whole address space
  for (int combo = 0; combo < 4; combo++) begin
    bit clear_err = combo[0];
    bit mem_clear = combo[1];

    for (int i = 0; i < num_of_full_range_trans_per_block; i++) begin
      if ($urandom_range(1, 0) == 0) begin
        wr_seq = write_apb_uvc_seq::type_id::create("wr_seq", this);
        if(!wr_seq.randomize() with {
          s_operation_kind == WRITE;
          s_delay_ready    == 0;
        }) begin
          `uvm_fatal(get_type_name(), "Failed to randomize wr_seq.")
        end
        wr_seq.start(m_apb_uvc_env_top.apb_uvc_env_inst.master_apb_agent.m_sequencer);
      end else begin
        rd_seq = read_apb_uvc_seq::type_id::create("rd_seq", this);
        if(!rd_seq.randomize() with {
          s_operation_kind == READ;
          s_delay_ready    == 0;
        }) begin
          `uvm_fatal(get_type_name(), "Failed to randomize rd_seq.")
        end
        rd_seq.start(m_apb_uvc_env_top.apb_uvc_env_inst.master_apb_agent.m_sequencer);
      end
    end

    wr_seq = write_apb_uvc_seq::type_id::create("wr_seq", this);
    if(!wr_seq.randomize() with {
      s_paddr          == CSR_CTRL_ADDR;
      s_pwdata[0]      == clear_err;
      s_pwdata[1]      == mem_clear;
      s_operation_kind == WRITE;
      s_delay_ready    == 0;
    }) begin
      `uvm_fatal(get_type_name(), "Failed to randomize wr_seq (CSR_CTRL).")
    end
    wr_seq.start(m_apb_uvc_env_top.apb_uvc_env_inst.master_apb_agent.m_sequencer);

    rd_seq = read_apb_uvc_seq::type_id::create("rd_seq", this);
    if(!rd_seq.randomize() with {
      s_paddr          == CSR_STATUS_ADDR;
      s_operation_kind == READ;
      s_delay_ready    == 0;
    }) begin
      `uvm_fatal(get_type_name(), "Failed to randomize rd_seq (CSR_STATUS).")
    end
    rd_seq.start(m_apb_uvc_env_top.apb_uvc_env_inst.master_apb_agent.m_sequencer);

    
    if (combo == 0) begin
      wr_seq = write_apb_uvc_seq::type_id::create("wr_seq", this);
      if(!wr_seq.randomize() with {
        s_paddr          == RO_MEM_ADDR;
        s_operation_kind == WRITE;
        s_delay_ready    == 0;
      }) begin
        `uvm_fatal(get_type_name(), "Failed to randomize wr_seq (RO write).")
      end
      wr_seq.start(m_apb_uvc_env_top.apb_uvc_env_inst.master_apb_agent.m_sequencer);

      rd_seq = read_apb_uvc_seq::type_id::create("rd_seq", this);
      if(!rd_seq.randomize() with {
        s_paddr          == CSR_STATUS_ADDR;
        s_operation_kind == READ;
        s_delay_ready    == 0;
      }) begin
        `uvm_fatal(get_type_name(), "Failed to randomize rd_seq (post RO-write STATUS read).")
      end
      rd_seq.start(m_apb_uvc_env_top.apb_uvc_env_inst.master_apb_agent.m_sequencer);
    end
  end

  //read-modify-write
  for (int i = 0; i < num_of_rmw_trans; i++) begin
    rmw_seq = read_modify_write_apb_uvc_seq::type_id::create("rmw_seq", this);
    if(!rmw_seq.randomize()) begin
      `uvm_fatal(get_type_name(), "Failed to randomize rmw_seq.")
    end
    rmw_seq.start(m_apb_uvc_env_top.apb_uvc_env_inst.master_apb_agent.m_sequencer);
  end

  #500;
  uvm_test_done.drop_objection(this, get_type_name());
  `uvm_info(get_type_name(), "TEST FINISHED", UVM_LOW)
endtask : run_phase

// set default configuration
function void test_apb_uvc_example::set_default_configuration();
  super.set_default_configuration();
endfunction : set_default_configuration

`endif // TEST_APB_UVC_EXAMPLE_SV
