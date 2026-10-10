`timescale 1ns / 1ps
module apb #(
    parameter DATA_WIDTH      = 32,
    parameter STRB_WIDTH      = DATA_WIDTH / 8,
    parameter MAX_WAIT_STATES = 3
)(
    input wire pclk,
    input wire presetn,
    input wire psel,
    input wire penable,
    input wire pwrite,
    input wire [DATA_WIDTH-1 : 0] pwdata,
    input wire [STRB_WIDTH-1 : 0] pstrb,

    output reg [DATA_WIDTH-1 : 0] prdata,
    output reg pready,
    output reg pslverr,

    output reg mem_wr_en,
    input wire [DATA_WIDTH-1 : 0] mem_rdata,
    input wire access_err
);

    integer wait_cnt;
    integer rand_wait;

    always @(posedge pclk or negedge presetn) begin
        if (!presetn) begin
            pready    <= 1'b0;
            pslverr   <= 1'b0;
            mem_wr_en <= 1'b0;
            wait_cnt  <= 0;
        end else begin
            pready    <= 1'b0;
            pslverr   <= 1'b0;
            mem_wr_en <= 1'b0;

            if (psel && !penable) begin
                rand_wait = $urandom_range(MAX_WAIT_STATES);
                wait_cnt <= rand_wait;
                if (rand_wait == 0) begin
                    if (access_err) begin
                        pslverr <= 1'b1;
                    end else if (pwrite) begin
                        mem_wr_en <= 1'b1;
                    end else begin
                        prdata <= mem_rdata;
                    end
                    pready <= 1'b1;
                end
            end else if (psel && penable) begin
                if (wait_cnt > 1) begin
                    wait_cnt <= wait_cnt - 1;
                end else if (wait_cnt == 1) begin
                    wait_cnt <= 0;
                    if (access_err) begin
                        pslverr <= 1'b1;
                    end else if (pwrite) begin
                        mem_wr_en <= 1'b1;
                    end else begin
                        prdata <= mem_rdata;
                    end
                    pready <= 1'b1;
                end
            end
        end
    end

endmodule
