`ifndef AXI4_AGENT_SV
`define AXI4_AGENT_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi4_seq_item.sv"
`include "axi4_driver.sv"
`include "axi4_sequence.sv"

class axi4_agent extends uvm_agent;

    `uvm_component_utils(axi4_agent)

    axi4_driver  driver;
    uvm_sequencer #(axi4_seq_item) sequencer;

    virtual axi4_if vif;

    function new(string name = "axi4_agent", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        driver    = axi4_driver::type_id::create("driver", this);
        sequencer = uvm_sequencer #(axi4_seq_item)::type_id::create(
                        "sequencer", this);
        if (!uvm_config_db #(virtual axi4_if)::get(
                this, "", "vif", vif))
            `uvm_fatal("AGENT", "Could not get vif from config db")
    endfunction

    function void connect_phase(uvm_phase phase);
        driver.seq_item_port.connect(sequencer.seq_item_export);
        driver.vif = vif;
    endfunction

endclass

`endif