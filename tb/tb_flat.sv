// =============================================================================
// Flat SystemVerilog Testbench — AXI4-Lite Slave Register File
// Directed testbench using manual AXI4-Lite transaction tasks.
// Written before UVM layer to verify DUT correctness first.
// All 4 registers tested with write and read-back.
//
// Author: Renuka Walawalkar | June 2026
// Tool:   Cadence Xcelium 25.03
// =============================================================================

`include "uvm_macros.svh"
import uvm_pkg::*;

module tb_flat;

    reg ACLK;
    reg ARESETn;

    reg  [31:0] AWADDR;
    reg         AWVALID;
    wire        AWREADY;

    reg  [31:0] WDATA;
    reg  [3:0]  WSTRB;
    reg         WVALID;
    wire        WREADY;

    wire [1:0]  BRESP;
    wire        BVALID;
    reg         BREADY;

    reg  [31:0] ARADDR;
    reg         ARVALID;
    wire        ARREADY;

    wire [31:0] RDATA;
    wire [1:0]  RRESP;
    wire        RVALID;
    reg         RREADY;

    // Waveform dump — open in EPWave to verify handshakes visually
    initial $dumpfile("dump.vcd");
    initial $dumpvars(0, tb_flat);

    // DUT instantiation
    axi4_lite_slave dut (
        .ACLK    (ACLK),
        .ARESETn (ARESETn),
        .AWADDR  (AWADDR),
        .AWVALID (AWVALID),
        .AWREADY (AWREADY),
        .WDATA   (WDATA),
        .WSTRB   (WSTRB),
        .WVALID  (WVALID),
        .WREADY  (WREADY),
        .BRESP   (BRESP),
        .BVALID  (BVALID),
        .BREADY  (BREADY),
        .ARADDR  (ARADDR),
        .ARVALID (ARVALID),
        .ARREADY (ARREADY),
        .RDATA   (RDATA),
        .RRESP   (RRESP),
        .RVALID  (RVALID),
        .RREADY  (RREADY)
    );

    // 100MHz clock
    initial ACLK = 0;
    always #5 ACLK = ~ACLK;

    // Watchdog — catches infinite loops in FSM or testbench
    initial begin
        #50000;
        $display("TIMEOUT: simulation exceeded 50us");
        $finish;
    end

    // -------------------------------------------------------------------------
    // Task: axi_write
    // Drives a single AXI4-Lite write transaction.
    // Waits for AWREADY+WREADY handshake, then waits for BVALID response.
    // -------------------------------------------------------------------------
    task axi_write(input [31:0] addr, input [31:0] data);
        @(posedge ACLK);
        AWADDR  = addr;
        AWVALID = 1;
        WDATA   = data;
        WVALID  = 1;
        BREADY  = 1;
        wait(AWREADY && WREADY);
        @(posedge ACLK);
        AWVALID = 0;
        WVALID  = 0;
        wait(BVALID);
        @(posedge ACLK);
        BREADY  = 0;
        repeat(2) @(posedge ACLK);
    endtask

    // -------------------------------------------------------------------------
    // Task: axi_read
    // Drives a single AXI4-Lite read transaction.
    // Waits for ARREADY handshake, then captures RDATA when RVALID asserts.
    // -------------------------------------------------------------------------
    task axi_read(input [31:0] addr, output [31:0] data);
        @(posedge ACLK);
        ARADDR  = addr;
        ARVALID = 1;
        RREADY  = 1;
        wait(ARREADY);
        @(posedge ACLK);
        ARVALID = 0;
        wait(RVALID);
        @(posedge ACLK);
        data    = RDATA;
        RREADY  = 0;
        repeat(2) @(posedge ACLK);
    endtask

    reg [31:0] rdata;

    initial begin
        // Initialize all inputs before reset releases
        ARESETn = 0;
        AWADDR=0; AWVALID=0;
        WDATA=0;  WVALID=0; WSTRB=4'hF;
        BREADY=0;
        ARADDR=0; ARVALID=0;
        RREADY=0;

        // Hold reset for 5 cycles then release
        repeat(5) @(posedge ACLK);
        ARESETn = 1;
        repeat(2) @(posedge ACLK);

        // Test all 4 registers with write then read-back
        // Using recognizable hex patterns to make waveform easy to read
        axi_write(32'h00, 32'hDEADBEEF);
        axi_read (32'h00, rdata);
        if (rdata === 32'hDEADBEEF)
            $display("PASS: REG0 = 0x%0h", rdata);
        else
            $display("FAIL: REG0 expected 0xDEADBEEF got 0x%0h", rdata);

        axi_write(32'h04, 32'hCAFEBABE);
        axi_read (32'h04, rdata);
        if (rdata === 32'hCAFEBABE)
            $display("PASS: REG1 = 0x%0h", rdata);
        else
            $display("FAIL: REG1 expected 0xCAFEBABE got 0x%0h", rdata);

        axi_write(32'h08, 32'hBEEFCAFE);
        axi_read (32'h08, rdata);
        if (rdata === 32'hBEEFCAFE)
            $display("PASS: REG2 = 0x%0h", rdata);
        else
            $display("FAIL: REG2 expected 0xBEEFCAFE got 0x%0h", rdata);

        axi_write(32'h0C, 32'hDEADCAFE);
        axi_read (32'h0C, rdata);
        if (rdata === 32'hDEADCAFE)
            $display("PASS: REG3 = 0x%0h", rdata);
        else
            $display("FAIL: REG3 expected 0xDEADCAFE got 0x%0h", rdata);

        $display("FLAT TESTBENCH COMPLETE");
        $finish;
    end

endmodule