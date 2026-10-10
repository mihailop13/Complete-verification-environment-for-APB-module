`ifndef APB_COVERAGE_SV
`define APB_COVERAGE_SV

class apb_coverage extends uvm_subscriber #(apb_uvc_item);

    `uvm_component_utils(apb_coverage)

    // address map of DUT (mirrors apb_scoreboard)
    localparam bit [`ADDR_WIDTH-1:0] CSR_STATUS_ADDR = 9'd256;
    localparam bit [`ADDR_WIDTH-1:0] CSR_CTRL_ADDR   = 9'd257;

    uvm_analysis_imp_reset #(bit, apb_coverage) rst_imp_port;

    // sampled transaction
    apb_uvc_item m_item;

    bit reset;

    covergroup rst_cg;
        option.per_instance = 1;

        rst_cp: coverpoint this.reset {
            bins reset_active   = {0};
            bins reset_inactive = {1};
        }
    endgroup : rst_cg

    covergroup access_cg;
        option.per_instance = 1;

        addr_cp: coverpoint m_item.paddr {
            bins mem_loc[] = {[0:255]};
            bins status    = {CSR_STATUS_ADDR};
            bins ctrl      = {CSR_CTRL_ADDR};
            bins unmapped  = {[258:511]};
        }
        op_cp: coverpoint m_item.operation_kind {
            bins op_read  = {READ};
            bins op_write = {WRITE};
        }
        addr_op_cross: cross addr_cp, op_cp;
    endgroup : access_cg

    covergroup ctrl_fields_cg;
        option.per_instance = 1;

        clear_err_field_cp: coverpoint m_item.pwdata[0]
            iff (m_item.paddr == CSR_CTRL_ADDR && m_item.operation_kind == WRITE) {
            bins zero = {1'b0};
            bins one  = {1'b1};
        }
        mem_clear_field_cp: coverpoint m_item.pwdata[1]
            iff (m_item.paddr == CSR_CTRL_ADDR && m_item.operation_kind == WRITE) {
            bins zero = {1'b0};
            bins one  = {1'b1};
        }
        ctrl_fields_cross: cross clear_err_field_cp, mem_clear_field_cp;
    endgroup : ctrl_fields_cg

    // STATUS fields: the read-back value has taken on every defined state
    covergroup status_fields_cg;
        option.per_instance = 1;

        pending_field_cp: coverpoint m_item.prdata[0]
            iff (m_item.paddr == CSR_STATUS_ADDR && m_item.operation_kind == READ) {
            bins zero = {1'b0};
            bins one  = {1'b1};
        }
        cause_field_cp: coverpoint m_item.prdata[2:1]
            iff (m_item.paddr == CSR_STATUS_ADDR && m_item.operation_kind == READ) {
            bins none     = {2'b00};
            bins unmapped = {2'b01};
            bins ro_write = {2'b10};
        }
        status_fields_cross: cross pending_field_cp, cause_field_cp {
            ignore_bins pending_but_no_cause =
                binsof(pending_field_cp) intersect {1'b1} &&
                binsof(cause_field_cp)   intersect {2'b00};
        }
    endgroup : status_fields_cg

    // constructor
    extern function new(string name, uvm_component parent);
    // build phase
    extern virtual function void build_phase(uvm_phase phase);
    // analysis implementation function (required by uvm_subscriber)
    extern virtual function void write(apb_uvc_item t);
    // reset analysis implementation function
    extern virtual function void write_reset(bit rst);

endclass : apb_coverage

// constructor
function apb_coverage::new(string name, uvm_component parent);
    super.new(name, parent);
    access_cg = new();
    access_cg.set_inst_name("access_cg");
    ctrl_fields_cg = new();
    ctrl_fields_cg.set_inst_name("ctrl_fields_cg");
    status_fields_cg = new();
    status_fields_cg.set_inst_name("status_fields_cg");
    rst_cg = new();
    rst_cg.set_inst_name("rst_cg");
endfunction : new

// build phase
function void apb_coverage::build_phase(uvm_phase phase);
    super.build_phase(phase);
    rst_imp_port = new("rst_imp_port", this);
endfunction : build_phase

// analysis port function
function void apb_coverage::write(apb_uvc_item t);
    m_item = t;
    access_cg.sample();
    ctrl_fields_cg.sample();
    status_fields_cg.sample();
endfunction : write

// reset analysis port function
function void apb_coverage::write_reset(bit rst);
    reset = rst;
    rst_cg.sample();
endfunction : write_reset

`endif // APB_COVERAGE_SV
