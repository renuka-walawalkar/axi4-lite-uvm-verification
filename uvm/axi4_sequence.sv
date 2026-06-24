`ifndef AXI4_SEQUENCE_SV
`define AXI4_SEQUENCE_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi4_seq_item.sv"

class axi4_write_seq extends uvm_sequence #(axi4_seq_item);

    `uvm_object_utils(axi4_write_seq)

    function new(string name = "axi4_write_seq");
        super.new(name);
    endfunction

    task body();
        axi4_seq_item item;
        // Write to all 4 registers with random data
        repeat(4) begin
            item = axi4_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with { we == 1; })
                `uvm_fatal("SEQ", "Randomization failed")
            finish_item(item);
        end
    endtask

endclass

class axi4_read_seq extends uvm_sequence #(axi4_seq_item);

    `uvm_object_utils(axi4_read_seq)

    function new(string name = "axi4_read_seq");
        super.new(name);
    endfunction

    task body();
        axi4_seq_item item;
        // Read from all 4 registers
        repeat(4) begin
            item = axi4_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize() with { we == 0; })
                `uvm_fatal("SEQ", "Randomization failed")
            finish_item(item);
        end
    endtask

endclass

class axi4_mixed_seq extends uvm_sequence #(axi4_seq_item);

    `uvm_object_utils(axi4_mixed_seq)

    function new(string name = "axi4_mixed_seq");
        super.new(name);
    endfunction

    task body();
        axi4_seq_item item;
        // Randomized mix of reads and writes
        repeat(8) begin
            item = axi4_seq_item::type_id::create("item");
            start_item(item);
            if (!item.randomize())
                `uvm_fatal("SEQ", "Randomization failed")
            finish_item(item);
        end
    endtask

endclass

`endif