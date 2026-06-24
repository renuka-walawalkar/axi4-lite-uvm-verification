// =============================================================================
// AXI4-Lite Slave Register File
// 4 x 32-bit registers, address map: 0x00 / 0x04 / 0x08 / 0x0C
//
// Simplified from full AXI4-Lite spec — AWVALID and WVALID are assumed
// to arrive on the same clock cycle. WSTRB byte enables not implemented.
// Both are documented as known gaps in TEST_PLAN.md.
//
// Author: Renuka Walawalkar | June 2026
// Tool:   Cadence Xcelium 25.03
// =============================================================================

module axi4_lite_slave #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 32
)(
    input  wire                   ACLK,
    input  wire                   ARESETn,

    // Write address channel
    input  wire [ADDR_WIDTH-1:0]  AWADDR,
    input  wire                   AWVALID,
    output reg                    AWREADY,

    // Write data channel
    input  wire [DATA_WIDTH-1:0]  WDATA,
    input  wire [3:0]             WSTRB,
    input  wire                   WVALID,
    output reg                    WREADY,

    // Write response channel
    output reg  [1:0]             BRESP,
    output reg                    BVALID,
    input  wire                   BREADY,

    // Read address channel
    input  wire [ADDR_WIDTH-1:0]  ARADDR,
    input  wire                   ARVALID,
    output reg                    ARREADY,

    // Read data channel
    output reg  [DATA_WIDTH-1:0]  RDATA,
    output reg  [1:0]             RRESP,
    output reg                    RVALID,
    input  wire                   RREADY
);

// 4 x 32-bit register file
// addr[3:2] selects register: 0x00->0, 0x04->1, 0x08->2, 0x0C->3
reg [DATA_WIDTH-1:0] reg_file [0:3];

// -----------------------------------------------------------------------------
// Write FSM
// WR_IDLE: assert AWREADY+WREADY, wait for both AWVALID+WVALID
// WR_RESP: assert BVALID, wait for BREADY, then return to idle
//
// Note: BVALID is asserted in the same cycle the write is accepted.
// One-cycle delay caused testbench hang during debug — fixed by
// moving BVALID assertion into the WR_IDLE transition.
// -----------------------------------------------------------------------------
localparam WR_IDLE = 1'd0,
           WR_RESP = 1'd1;

reg wr_state;

always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        wr_state    <= WR_IDLE;
        AWREADY     <= 1'b1;
        WREADY      <= 1'b1;
        BVALID      <= 1'b0;
        BRESP       <= 2'b00;
        reg_file[0] <= 0;
        reg_file[1] <= 0;
        reg_file[2] <= 0;
        reg_file[3] <= 0;
    end else begin
        case (wr_state)
            WR_IDLE: begin
                if (AWVALID && WVALID && AWREADY && WREADY) begin
                    reg_file[AWADDR[3:2]] <= WDATA;
                    AWREADY  <= 1'b0;
                    WREADY   <= 1'b0;
                    BVALID   <= 1'b1;
                    BRESP    <= 2'b00;
                    wr_state <= WR_RESP;
                end
            end
            WR_RESP: begin
                if (BREADY) begin
                    BVALID   <= 1'b0;
                    AWREADY  <= 1'b1;
                    WREADY   <= 1'b1;
                    wr_state <= WR_IDLE;
                end
            end
            default: wr_state <= WR_IDLE;
        endcase
    end
end

// -----------------------------------------------------------------------------
// Read FSM
// RD_IDLE: assert ARREADY, wait for ARVALID
// RD_DATA: drive RDATA+RVALID, wait for RREADY, then return to idle
// -----------------------------------------------------------------------------
localparam RD_IDLE = 1'd0,
           RD_DATA = 1'd1;

reg rd_state;

always @(posedge ACLK or negedge ARESETn) begin
    if (!ARESETn) begin
        rd_state <= RD_IDLE;
        ARREADY  <= 1'b1;
        RVALID   <= 1'b0;
        RDATA    <= 0;
        RRESP    <= 2'b00;
    end else begin
        case (rd_state)
            RD_IDLE: begin
                if (ARVALID && ARREADY) begin
                    RDATA    <= reg_file[ARADDR[3:2]];
                    RRESP    <= 2'b00;
                    ARREADY  <= 1'b0;
                    RVALID   <= 1'b1;
                    rd_state <= RD_DATA;
                end
            end
            RD_DATA: begin
                if (RREADY) begin
                    RVALID   <= 1'b0;
                    ARREADY  <= 1'b1;
                    rd_state <= RD_IDLE;
                end
            end
            default: rd_state <= RD_IDLE;
        endcase
    end
end

endmodule