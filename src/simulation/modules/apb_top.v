`timescale 1ns / 1ps
module apb_top #(
    parameter DATA_WIDTH      = 32,
    parameter MAX_WAIT_STATES = 3,
    parameter STRB_WIDTH      = DATA_WIDTH / 8
)(
    input  wire                   pclk,
    input  wire                   presetn,
    input  wire                   psel,
    input  wire                   penable,
    input  wire                   pwrite,
    input  wire [8:0]             paddr,
    input  wire [DATA_WIDTH-1:0]  pwdata,
    input  wire [STRB_WIDTH-1:0]  pstrb,

    output wire [DATA_WIDTH-1:0]  prdata,
    output wire                   pready,
    output wire                   pslverr
);

    localparam SEL_WIDTH   = 2;
    localparam LOCAL_WIDTH = 6;
    localparam RO_SIZE     = 16;

    wire in_mem_space = !paddr[8];
    wire [SEL_WIDTH-1:0]   mem_sel  = paddr[LOCAL_WIDTH +: SEL_WIDTH];
    wire [LOCAL_WIDTH-1:0] mem_addr = paddr[LOCAL_WIDTH-1:0];

    localparam [8:0] CSR_STATUS_ADDR = 9'd256;
    localparam [8:0] CSR_CTRL_ADDR   = 9'd257;
    wire is_csr_status = (paddr == CSR_STATUS_ADDR);
    wire is_csr_ctrl   = (paddr == CSR_CTRL_ADDR);
    wire is_unmapped   = !in_mem_space && !is_csr_status && !is_csr_ctrl;

    localparam [LOCAL_WIDTH-1:0] RO_LOCAL_BASE = (2**LOCAL_WIDTH) - RO_SIZE;
    wire is_ro_addr = in_mem_space && (mem_sel == 2'd3) && (mem_addr >= RO_LOCAL_BASE);
    wire access_err = is_unmapped || (pwrite && (is_ro_addr || is_csr_status));

    wire                  mem_wr_en;
    wire [DATA_WIDTH-1:0] mem_rdata;
    wire [DATA_WIDTH-1:0] rdata0, rdata1, rdata2, rdata3;

    wire csr_write = mem_wr_en && is_csr_ctrl;
    wire mem_clear = csr_write && pwdata[1]; // CTRL bit1

    // RO deo mem3 se posle reseta ucitava sa ovim tagom (24-bitni tag | 8-bitni offset)
    localparam [DATA_WIDTH-1:0] RO_INIT_TAG = 32'h524F_0000;

    apb_mem #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(LOCAL_WIDTH)) mem0 (
        .pclk    (pclk), .presetn (presetn),
        .addr (mem_addr), .wdata (pwdata), .wstrb (pstrb),
        .wr_en (mem_wr_en && in_mem_space && (mem_sel == 2'd0)),
        .clear (mem_clear),
        .rdata (rdata0)
    );

    apb_mem #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(LOCAL_WIDTH)) mem1 (
        .pclk    (pclk), .presetn (presetn),
        .addr (mem_addr), .wdata (pwdata), .wstrb (pstrb),
        .wr_en (mem_wr_en && in_mem_space && (mem_sel == 2'd1)),
        .clear (mem_clear),
        .rdata (rdata1)
    );

    apb_mem #(.DATA_WIDTH(DATA_WIDTH), .ADDR_WIDTH(LOCAL_WIDTH)) mem2 (
        .pclk    (pclk), .presetn (presetn),
        .addr (mem_addr), .wdata (pwdata), .wstrb (pstrb),
        .wr_en (mem_wr_en && in_mem_space && (mem_sel == 2'd2)),
        .clear (mem_clear),
        .rdata (rdata2)
    );

    apb_mem #(
        .DATA_WIDTH   (DATA_WIDTH),
        .ADDR_WIDTH   (LOCAL_WIDTH),
        .CLEAR_LIMIT  (RO_LOCAL_BASE),
        .RO_INIT_BASE (RO_LOCAL_BASE),
        .RO_INIT_TAG  (RO_INIT_TAG)
    ) mem3 (
        .pclk    (pclk), .presetn (presetn),
        .addr (mem_addr), .wdata (pwdata), .wstrb (pstrb),
        .wr_en (mem_wr_en && in_mem_space && (mem_sel == 2'd3)),
        .clear (mem_clear),
        .rdata (rdata3)
    );

    localparam [1:0] CAUSE_NONE     = 2'b00;
    localparam [1:0] CAUSE_UNMAPPED = 2'b01;
    localparam [1:0] CAUSE_RO_WRITE = 2'b10;

    reg                  irq_pending;
    reg [1:0]            irq_cause;
    reg [8:0]            err_addr;
    reg [DATA_WIDTH-1:0] ctrl_reg;

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            irq_pending <= 1'b0;
            irq_cause   <= CAUSE_NONE;
            err_addr    <= 9'd0;
            ctrl_reg    <= {DATA_WIDTH{1'b0}};
        end else begin
            if (pslverr) begin
                irq_pending <= 1'b1;
                irq_cause   <= is_unmapped ? CAUSE_UNMAPPED : CAUSE_RO_WRITE;
                err_addr    <= paddr;
            end
            if (csr_write) begin
                ctrl_reg <= pwdata;
                if (pwdata[0] && !pslverr)
                    irq_pending <= 1'b0;
            end
        end
    end

    wire [DATA_WIDTH-1:0] status_rdata = {{(DATA_WIDTH-12){1'b0}}, err_addr, irq_cause, irq_pending};
    wire [DATA_WIDTH-1:0] ctrl_rdata   = ctrl_reg;

    assign mem_rdata = is_csr_status ? status_rdata :
                        is_csr_ctrl   ? ctrl_rdata   :
                        (mem_sel == 2'd0) ? rdata0 :
                        (mem_sel == 2'd1) ? rdata1 :
                        (mem_sel == 2'd2) ? rdata2 :
                                            rdata3;

    apb #(
        .DATA_WIDTH      (DATA_WIDTH),
        .STRB_WIDTH      (STRB_WIDTH),
        .MAX_WAIT_STATES (MAX_WAIT_STATES)
    ) apb_inst (
        .pclk       (pclk),
        .presetn    (presetn),
        .psel       (psel),
        .penable    (penable),
        .pwrite     (pwrite),
        .pwdata     (pwdata),
        .pstrb      (pstrb),
        .prdata     (prdata),
        .pready     (pready),
        .pslverr    (pslverr),
        .mem_wr_en  (mem_wr_en),
        .mem_rdata  (mem_rdata),
        .access_err (access_err)
    );

endmodule
