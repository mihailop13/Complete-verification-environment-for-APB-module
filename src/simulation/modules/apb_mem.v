`timescale 1ns / 1ps

module apb_mem #(
    parameter DATA_WIDTH  = 32,
    parameter ADDR_WIDTH  = 6,
    parameter STRB_WIDTH  = DATA_WIDTH / 8,
    parameter CLEAR_LIMIT = 2**ADDR_WIDTH,
    parameter RO_INIT_BASE = 2**ADDR_WIDTH,
    parameter [DATA_WIDTH-1:0] RO_INIT_TAG = {DATA_WIDTH{1'b0}}
)(
    input  wire                  pclk,
    input  wire                  presetn,
    input  wire [ADDR_WIDTH-1:0] addr,
    input  wire [DATA_WIDTH-1:0] wdata,
    input  wire [STRB_WIDTH-1:0] wstrb,
    input  wire                  wr_en,
    input  wire                  clear,
    output wire [DATA_WIDTH-1:0] rdata
);

    reg [DATA_WIDTH-1:0] mem [0:(2**ADDR_WIDTH)-1];
    integer i;

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            for (i = 0; i < (2**ADDR_WIDTH); i = i + 1) begin
                if (i >= RO_INIT_BASE)
                    mem[i] <= RO_INIT_TAG | (i - RO_INIT_BASE);
                else
                    mem[i] <= {DATA_WIDTH{1'b0}};
            end
        end else if (clear) begin
            for (i = 0; i < CLEAR_LIMIT; i = i + 1)
                mem[i] <= {DATA_WIDTH{1'b0}};
        end else if (wr_en) begin
            for (i = 0; i < STRB_WIDTH; i = i + 1) begin
                if (wstrb[i])
                    mem[addr][i*8 +: 8] <= wdata[i*8 +: 8];
            end
        end
    end

    assign rdata = mem[addr];

endmodule
