`ifndef APB_SCOREBOARD_SV
`define APB_SCOREBOARD_SV

`uvm_analysis_imp_decl(_item)
`uvm_analysis_imp_decl(_reset)
// struct for decoding paddr into memory, status, control, and unmapped
typedef struct {
  bit       is_mem;       // paddr[8] == 0
  bit [1:0] mem_sel;      // paddr[7:6]
  bit [5:0] mem_addr;     // paddr[5:0]
  bit       is_status;    // paddr == 256
  bit       is_ctrl;      // paddr == 257
  bit       is_unmapped;  // !is_mem && !is_status && !is_ctrl
  bit       is_ro;        // mem3, highest locations [48:63]
  bit       access_err;   // is_unmapped || (WRITE && is_ro)
} apb_decode_s;

class apb_scoreboard extends uvm_scoreboard;

    `uvm_component_utils(apb_scoreboard)

    uvm_analysis_imp_item  #(apb_uvc_item, apb_scoreboard) item_imp_port;
    uvm_analysis_imp_reset #(bit,          apb_scoreboard) rst_imp_port;

    // address map of DUT
    localparam int unsigned NUM_MEM   = 4;
    localparam int unsigned MEM_DEPTH = 64;                    // 2**LOCAL_WIDTH
    localparam int unsigned RO_SIZE   = 16;
    localparam int unsigned RO_BASE   = MEM_DEPTH - RO_SIZE;   // 48

    localparam bit [8:0] CSR_STATUS_ADDR = 9'd256;
    localparam bit [8:0] CSR_CTRL_ADDR   = 9'd257;

    localparam bit [1:0] CAUSE_NONE     = 2'b00;
    localparam bit [1:0] CAUSE_UNMAPPED = 2'b01;
    localparam bit [1:0] CAUSE_RO_WRITE = 2'b10;

    bit [`DATA_WIDTH-1:0] mem[NUM_MEM-1:0][MEM_DEPTH-1:0];      // memory model for scoreboard, matrix of NUM_MEM x MEM_DEPTH
    
    // Control/Status Registers reference model
    // Status, read-only
    bit[1:0] status_err_cause;
    bit[8:0] status_err_addr;
    bit      status_err_pending;
    // Control, read/write
    bit [`DATA_WIDTH-1:0] ctrl_reg;

    // analysis imp functions
    extern virtual function void write_item(apb_uvc_item t);
    extern virtual function void write_reset(bit rst);

    // constructor
    extern function new(string name, uvm_component parent);
    // build phase
    extern virtual function void build_phase(uvm_phase phase);
    // decode_addr function, returns a struct with decoded address information
    extern virtual function apb_decode_s decode_paddr(bit [8:0] paddr, operation_e op);
    // check item function, used to check the received item against the reference model
    extern virtual function void check_item(apb_uvc_item item, apb_decode_s decoded_item);
    // update reference model function, used to update the reference model based on the received item
    extern virtual function void update_ref_model(apb_uvc_item item, apb_decode_s decoded_item);
    // predict output function, used to predict the output based on the received item and the decoded address
    extern virtual function void predict(apb_uvc_item item,
                                          apb_decode_s dec,
                                          output bit [`DATA_WIDTH-1:0] exp_prdata,
                                          output bit                   check_prdata,
                                          output bit                   exp_pslverr);

    // helping functions
    // used to reset the reference model to its initial state
    extern virtual function void                  reset_model();
    // clear memory when ctrl_reg[1] is set
    extern virtual function void                  do_clear();
    // merge data function, used to merge the old data with the new data based on the strobe
    extern virtual function bit [`DATA_WIDTH-1:0] merge_strb(bit [`DATA_WIDTH-1:0] old_data,
                                                            bit [`DATA_WIDTH-1:0] new_data,
                                                            bit [`STRB_WIDTH-1:0] strb);
    // status value function, used to get the current status value of the reference model   
    extern virtual function bit [`DATA_WIDTH-1:0] status_value();

endclass : apb_scoreboard

// constructor
function apb_scoreboard::new(string name, uvm_component parent);
    super.new(name, parent);
endfunction : new

// build phase
function void apb_scoreboard::build_phase(uvm_phase phase);
    super.build_phase(phase);

    item_imp_port = new("item_imp_port", this);
    rst_imp_port  = new("rst_imp_port",  this);
    reset_model();

endfunction : build_phase

// decode addr
function apb_decode_s apb_scoreboard::decode_paddr(bit [8:0] paddr, operation_e op);
    apb_decode_s dec;

    dec.is_mem      = !paddr[8];
    dec.mem_sel     = paddr[7:6];
    dec.mem_addr    = paddr[5:0];
    dec.is_status   = (paddr == CSR_STATUS_ADDR);
    dec.is_ctrl     = (paddr == CSR_CTRL_ADDR);
    dec.is_unmapped = !dec.is_mem && !dec.is_status && !dec.is_ctrl;
    dec.is_ro       = dec.is_mem && (dec.mem_sel == 2'd3) && (dec.mem_addr >= RO_BASE);
    dec.access_err  = dec.is_unmapped || ((op == WRITE) && (dec.is_ro || dec.is_status));

    return dec;
endfunction : decode_paddr

function void apb_scoreboard::predict(apb_uvc_item item, apb_decode_s dec,
                                      output bit [`DATA_WIDTH-1:0] exp_prdata,
                                      output bit                   check_prdata,
                                      output bit                   exp_pslverr);
    exp_prdata       = '0;
    check_prdata     = 1'b0;

    exp_pslverr = dec.access_err;
    if(exp_pslverr || item.operation_kind == WRITE) begin
        check_prdata = 1'b0;
        return;
    end
    
    // READ operation, no PSLVERR, check PRDATA
    check_prdata = 1'b1;
    if(dec.is_status) begin
        exp_prdata = status_value();
    end
    else if(dec.is_ctrl) begin
        exp_prdata = ctrl_reg;
    end
    else if(dec.is_mem) begin
        exp_prdata = mem[dec.mem_sel][dec.mem_addr];
    end
    
endfunction : predict

function void apb_scoreboard::check_item(apb_uvc_item item, apb_decode_s decoded_item);

    bit [`DATA_WIDTH-1:0] exp_prdata;
    bit                   check_prdata;
    bit                   exp_pslverr;

    predict(item, decoded_item, exp_prdata, check_prdata, exp_pslverr);

    // check PSLVERR
    if (item.pslverr !== exp_pslverr) begin
        `uvm_error(get_type_name(),
        $sformatf("PSLVERR MISMATCH @ paddr=0x%03h (%s): expected=%0b, actual=%0b",
                    item.paddr, item.operation_kind.name(), exp_pslverr, item.pslverr))
        // return, error is already reported, no need to check PRDATA
        return;
    end

    // check PRDATA
    if (item.operation_kind == READ && check_prdata) begin
        if (item.prdata !== exp_prdata) begin
            `uvm_error(get_type_name(), $sformatf("PRDATA MISMATCH @ paddr=0x%03h: expected=0x%08h, actual=0x%08h", item.paddr, exp_prdata, item.prdata))
            return;
        end
    end
endfunction : check_item

// update ref model
function void apb_scoreboard::update_ref_model(apb_uvc_item item, apb_decode_s decoded_item);

    if(decoded_item.access_err) begin
        status_err_pending = 1'b1;
        status_err_cause   = decoded_item.is_unmapped ? CAUSE_UNMAPPED : CAUSE_RO_WRITE;
        status_err_addr    = item.paddr;
        return;
    end

    // update memory model
    if(item.paddr == CSR_CTRL_ADDR && item.operation_kind == WRITE) begin
        ctrl_reg = item.pwdata;
        if (item.pwdata[1]) begin
            // clear memory model
            do_clear(); 
        end 
        if (item.pwdata[0]) begin
            // clear interrupt pending
            status_err_pending = 0;
        end
    end
    else if(decoded_item.is_mem && item.operation_kind == WRITE) begin
        mem[decoded_item.mem_sel][decoded_item.mem_addr] = merge_strb(mem[decoded_item.mem_sel][decoded_item.mem_addr], item.pwdata, item.pstrb);
    end

endfunction : update_ref_model

// analysis imp functions
function void apb_scoreboard::write_item(apb_uvc_item t);
    apb_uvc_item item;
    apb_decode_s decoded_item;

    // monitor sends item HANDLE, item then should be cloned
    if(!$cast(item, t.clone())) begin
        `uvm_error("APB_SCOREBOARD", $sformatf("Received item is not of type apb_uvc_item: %p", t))
        return;
    end

    decoded_item = decode_paddr(item.paddr, item.operation_kind);

    // check_item
    check_item(item, decoded_item);

    // update_ref_model
    update_ref_model(item, decoded_item);
endfunction : write_item

function void apb_scoreboard::write_reset(bit rst);
    if (rst) begin
        `uvm_info(get_type_name(), "Reset observed, reinitializing reference model.", UVM_MEDIUM)
        reset_model();
    end
endfunction : write_reset

// helping functions
function void apb_scoreboard::reset_model();
  foreach (mem[i, j]) begin
    mem[i][j] = '0;
  end
  ctrl_reg    = '0;
  status_err_pending = 1'b0;
  status_err_cause   = CAUSE_NONE;
  status_err_addr    = '0;
  for (int i = RO_BASE; i < MEM_DEPTH; i++) begin
    mem[3][i] = 32'h524F_0000 | (i - RO_BASE);
  end

endfunction : reset_model

// ctrl[1] -> clear memory
function void apb_scoreboard::do_clear();
  for (int i = 0; i < NUM_MEM; i++) begin
    int unsigned limit = (i == 3) ? RO_BASE : MEM_DEPTH;
    for (int j = 0; j < limit; j++) begin
      mem[i][j] = '0;
    end
  end
  `uvm_info(get_type_name(), "Memory clear applied to reference model.", UVM_MEDIUM)
endfunction : do_clear

// masked write: merge old_data with new_data based on strb
function bit [`DATA_WIDTH-1:0] apb_scoreboard::merge_strb(bit [`DATA_WIDTH-1:0] old_data,
                                                          bit [`DATA_WIDTH-1:0] new_data,
                                                          bit [`STRB_WIDTH-1:0] strb);
  bit [`DATA_WIDTH-1:0] res = old_data;
  for (int i = 0; i < `STRB_WIDTH; i++) begin
    if (strb[i]) res[i*8 +: 8] = new_data[i*8 +: 8];
  end
  return res;
endfunction : merge_strb

// value of reference model status register
function bit [`DATA_WIDTH-1:0] apb_scoreboard::status_value();
  return {{(`DATA_WIDTH-12){1'b0}}, status_err_addr, status_err_cause, status_err_pending};
endfunction : status_value

`endif // APB_SCOREBOARD_SV