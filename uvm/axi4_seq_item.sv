`ifndef AXI4_SEQ_ITEM_SV
`define AXI4_SEQ_ITEM_SV

`include "uvm_macros.svh"
import uvm_pkg::*;

class axi4_seq_item extends uvm_sequence_item;

    `uvm_object_utils(axi4_seq_item)

    rand bit [31:0] addr;
    rand bit [31:0] data;
    rand bit        we;

    constraint valid_addr {
        addr inside {32'h00, 32'h04, 32'h08, 32'h0C};
    }

    function new(string name = "axi4_seq_item");
        super.new(name);
    endfunction

    function string convert2string();
        return $sformatf("addr=0x%0h data=0x%0h we=%0b", addr, data, we);
    endfunction

endclass

`endif