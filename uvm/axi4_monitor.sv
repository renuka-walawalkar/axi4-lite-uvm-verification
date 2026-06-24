`ifndef AXI4_MONITOR_SV
`define AXI4_MONITOR_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi4_seq_item.sv"

class axi4_monitor extends uvm_monitor;

    `uvm_component_utils(axi4_monitor)

    virtual axi4_if vif;

    // Analysis port — sends observed transactions to scoreboard
    uvm_analysis_port #(axi4_seq_item) ap;

    function new(string name = "axi4_monitor", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        ap = new("ap", this);
        if (!uvm_config_db #(virtual axi4_if)::get(
                this, "", "vif", vif))
            `uvm_fatal("MON", "Could not get vif from config db")
    endfunction

    task run_phase(uvm_phase phase);
        axi4_seq_item item;
        forever begin
            item = axi4_seq_item::type_id::create("mon_item");
            // Observe write transactions
            // Wait for write address handshake
            @(posedge vif.ACLK);
            while (!(vif.AWVALID && vif.AWREADY))
                @(posedge vif.ACLK);
            item.addr = vif.AWADDR;
            item.data = vif.WDATA;
            item.we   = 1;
            // Wait for write response
            @(posedge vif.ACLK);
            while (!vif.BVALID)
                @(posedge vif.ACLK);
            // Send observed transaction to scoreboard
            ap.write(item);
            `uvm_info("MON",
                $sformatf("Observed WRITE: addr=0x%0h data=0x%0h",
                item.addr, item.data), UVM_LOW)
        end
    endtask

endclass

`endif