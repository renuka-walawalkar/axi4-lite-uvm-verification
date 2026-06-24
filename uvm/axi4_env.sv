`ifndef AXI4_ENV_SV
`define AXI4_ENV_SV

`include "uvm_macros.svh"
import uvm_pkg::*;
`include "axi4_seq_item.sv"
`include "axi4_driver.sv"
`include "axi4_sequence.sv"
`include "axi4_monitor.sv"
`include "axi4_agent.sv"

class axi4_scoreboard extends uvm_component;

    `uvm_component_utils(axi4_scoreboard)

    // TLM analysis export — receives transactions from monitor
    uvm_analysis_imp #(axi4_seq_item, axi4_scoreboard) analysis_export;

    // Expected register model
    bit [31:0] expected [0:3];

    // Coverage variables
    bit [31:0] cov_addr;
    bit        cov_we;

    // Coverage group
    covergroup axi4_cg;
          option.per_instance = 1;
          option.goal         = 100;
          cp_addr: coverpoint cov_addr {
            bins reg0 = {32'h00};
            bins reg1 = {32'h04};
            bins reg2 = {32'h08};
            bins reg3 = {32'h0C};
        }
        cp_we: coverpoint cov_we {
            bins write = {1};
            bins read  = {0};
        }
        cp_cross: cross cp_addr, cp_we;
    endgroup

    int unsigned pass_count;
    int unsigned fail_count;

    function new(string name = "axi4_scoreboard", uvm_component parent = null);
        super.new(name, parent);
        axi4_cg   = new();
        pass_count = 0;
        fail_count = 0;
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        analysis_export = new("analysis_export", this);
    endfunction

    // Called automatically when monitor writes to analysis port
    function void write(axi4_seq_item item);
        int idx = item.addr[3:2];

        // Sample coverage
        cov_addr = item.addr;
        cov_we   = item.we;
        axi4_cg.sample();

        if (item.we) begin
            expected[idx] = item.data;
            `uvm_info("SB",
                $sformatf("WRITE: REG%0d = 0x%0h", idx, item.data),
                UVM_LOW)
            pass_count++;
        end else begin
            if (item.data === expected[idx]) begin
                `uvm_info("SB",
                    $sformatf("READ PASS: REG%0d expected=0x%0h got=0x%0h",
                    idx, expected[idx], item.data), UVM_LOW)
                pass_count++;
            end else begin
                `uvm_error("SB",
                    $sformatf("READ FAIL: REG%0d expected=0x%0h got=0x%0h",
                    idx, expected[idx], item.data))
                fail_count++;
            end
        end
    endfunction

    function void report_phase(uvm_phase phase);
        `uvm_info("SB", $sformatf(
            "SCOREBOARD SUMMARY: PASS=%0d FAIL=%0d Coverage=%.1f%%",
            pass_count, fail_count, axi4_cg.get_inst_coverage()), UVM_LOW)
        if (fail_count == 0)
            `uvm_info("SB", "ALL CHECKS PASSED", UVM_LOW)
        else
            `uvm_error("SB", "FAILURES DETECTED")
    endfunction

endclass

class axi4_env extends uvm_env;

    `uvm_component_utils(axi4_env)

    axi4_agent      agent;
    axi4_monitor    monitor;
    axi4_scoreboard sb;

    function new(string name = "axi4_env", uvm_component parent = null);
        super.new(name, parent);
    endfunction

    function void build_phase(uvm_phase phase);
        super.build_phase(phase);
        agent   = axi4_agent::type_id::create("agent", this);
        monitor = axi4_monitor::type_id::create("monitor", this);
        sb      = axi4_scoreboard::type_id::create("sb", this);
    endfunction

    function void connect_phase(uvm_phase phase);
        // Connect monitor analysis port to scoreboard
        monitor.ap.connect(sb.analysis_export);
    endfunction

endclass

`endif