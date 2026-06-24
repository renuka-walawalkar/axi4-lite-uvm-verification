`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi4_if.sv"
`include "axi4_seq_item.sv"
`include "axi4_driver.sv"
`include "axi4_sequence.sv"
`include "axi4_agent.sv"
`include "axi4_env.sv"
`include "axi4_monitor.sv"

class axi4_test extends uvm_test;

    `uvm_component_utils(axi4_test)

    axi4_env env;

    function new(string name = "axi4_test", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        env = axi4_env::type_id::create("env", this);
    endfunction

    task run_phase(uvm_phase phase);
        axi4_write_seq write_seq;
        axi4_read_seq  read_seq;

        phase.raise_objection(this);

        // Wait for reset to complete
        // Reset is handled in the top module initial block
        #100;

        // Run write sequence
        write_seq = axi4_write_seq::type_id::create("write_seq");
        write_seq.start(env.agent.sequencer);

        #50;

        // Run read sequence
        read_seq = axi4_read_seq::type_id::create("read_seq");
        read_seq.start(env.agent.sequencer);

        phase.drop_objection(this);
    endtask

endclass

module tb;

    reg ACLK;
    reg ARESETn;

    initial ACLK = 0;
    always #5 ACLK = ~ACLK;

    initial $dumpfile("dump.vcd");
    initial $dumpvars(0, tb);
    initial $dumpvars(0, tb.axi_if);
   

    // Interface instantiation
    axi4_if axi_if (.ACLK(ACLK), .ARESETn(ARESETn));

    // DUT connected through interface
    axi4_lite_slave dut (
        .ACLK    (ACLK),
        .ARESETn (ARESETn),
        .AWADDR  (axi_if.AWADDR),
        .AWVALID (axi_if.AWVALID),
        .AWREADY (axi_if.AWREADY),
        .WDATA   (axi_if.WDATA),
        .WSTRB   (axi_if.WSTRB),
        .WVALID  (axi_if.WVALID),
        .WREADY  (axi_if.WREADY),
        .BRESP   (axi_if.BRESP),
        .BVALID  (axi_if.BVALID),
        .BREADY  (axi_if.BREADY),
        .ARADDR  (axi_if.ARADDR),
        .ARVALID (axi_if.ARVALID),
        .ARREADY (axi_if.ARREADY),
        .RDATA   (axi_if.RDATA),
        .RRESP   (axi_if.RRESP),
        .RVALID  (axi_if.RVALID),
        .RREADY  (axi_if.RREADY)
    );

    // Timeout watchdog
    initial begin
        #100000;
        $display("TIMEOUT");
        $finish;
    end

    // Reset block — separate from UVM startup
    initial begin
        ARESETn        = 0;
        axi_if.AWVALID = 0;
        axi_if.WVALID  = 0;
        axi_if.BREADY  = 0;
        axi_if.ARVALID = 0;
        axi_if.RREADY  = 0;
        axi_if.WSTRB   = 4'hF;
        axi_if.AWADDR  = 0;
        axi_if.WDATA   = 0;
        axi_if.ARADDR  = 0;
        repeat(5) @(posedge ACLK);
        ARESETn = 1;
    end

    // UVM startup — must be at time 0
    initial begin
        uvm_config_db #(virtual axi4_if)::set(
            null, "uvm_test_top.*", "vif", axi_if);
        run_test("axi4_test");
    end

endmodule