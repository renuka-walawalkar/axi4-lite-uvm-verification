`ifndef AXI4_DRIVER_SV
`define AXI4_DRIVER_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi4_seq_item.sv"

class axi4_driver extends uvm_driver #(axi4_seq_item);

    `uvm_component_utils(axi4_driver)

    virtual axi4_if vif;

    function new(string name = "axi4_driver", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    task run_phase(uvm_phase phase);
        axi4_seq_item req;
        forever begin
            seq_item_port.get_next_item(req);
            `uvm_info("DRIVER", $sformatf("Driving: %s", req.convert2string()), UVM_LOW)
            if (req.we)
                do_write(req.addr, req.data);
            else
                do_read(req.addr, req.data);
            seq_item_port.item_done();
        end
    endtask

    task do_write(input bit [31:0] addr, input bit [31:0] data);
        @(posedge vif.ACLK);
        vif.AWADDR  <= addr;
        vif.AWVALID <= 1;
        vif.WDATA   <= data;
        vif.WVALID  <= 1;
        vif.WSTRB   <= 4'hF;
        vif.BREADY  <= 1;
        wait(vif.AWREADY && vif.WREADY);
        @(posedge vif.ACLK);
        vif.AWVALID <= 0;
        vif.WVALID  <= 0;
        wait(vif.BVALID);
        @(posedge vif.ACLK);
        vif.BREADY  <= 0;
        repeat(2) @(posedge vif.ACLK);
    endtask

    task do_read(input bit [31:0] addr, output bit [31:0] data);
        @(posedge vif.ACLK);
        vif.ARADDR  <= addr;
        vif.ARVALID <= 1;
        vif.RREADY  <= 1;
        wait(vif.ARREADY);
        @(posedge vif.ACLK);
        vif.ARVALID <= 0;
        wait(vif.RVALID);
        @(posedge vif.ACLK);
        data        = vif.RDATA;
        vif.RREADY  <= 0;
        repeat(2) @(posedge vif.ACLK);
    endtask

endclass

`endif