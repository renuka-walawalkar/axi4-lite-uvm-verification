# Test Plan: AXI4-Lite Slave Register File
**Author:** Renuka Walawalkar  
**Date:** June 2026  
**Tool:** Cadence Xcelium 25.03, UVM IEEE 1800.2-2017  
**EDA Playground: https://edaplayground.com/x/6xRf

---

## 1. Design Under Test

AXI4-Lite slave register file with 4 x 32-bit registers.
Supports single write and read transactions per AXI4-Lite 
protocol. Address map:

| Register | Address |
|----------|---------|
| REG0     | 0x00    |
| REG1     | 0x04    |
| REG2     | 0x08    |
| REG3     | 0x0C    |

---

## 2. Verification Goals

- Verify correct write behavior across all 4 registers
- Verify correct read-back after write for all 4 registers
- Verify AXI4-Lite VALID/READY handshake protocol compliance
- Verify correct write response (BRESP = 2'b00)
- Verify correct read response (RRESP = 2'b00)

---

## 3. Test Plan

### Test 1 — Directed Write and Read (Flat Testbench)
**Stimulus:** Manual write of known values to all 4 registers  
**Expected:** Read-back matches written value for each register  
**Pass Criteria:** $display prints PASS for all 4 registers  
**Status:** PASSED

### Test 2 — Constrained Random Write Sequence (UVM)
**Stimulus:** 4 randomized write transactions with address 
constrained to {0x00, 0x04, 0x08, 0x0C}  
**Expected:** Driver logs 4 write transactions, monitor 
observes 4 write handshakes, scoreboard records expected values  
**Pass Criteria:** UVM_ERROR=0, UVM_FATAL=0, DRIVER count=4  
**Status:** PASSED

### Test 3 — Constrained Random Read Sequence (UVM)
**Stimulus:** 4 randomized read transactions following write sequence  
**Expected:** Driver logs 4 read transactions  
**Pass Criteria:** UVM_ERROR=0, UVM_FATAL=0, DRIVER count=8 total  
**Status:** PASSED

### Test 4 — Scoreboard Check
**Stimulus:** Write followed by read on same address  
**Expected:** Scoreboard write function records expected value, 
read function compares and reports PASS  
**Pass Criteria:** PASS=4 FAIL=0 in scoreboard summary  
**Status:** PASSED

---

## 4. Coverage Plan

### Implemented Coverage Groups

**cp_addr** — Coverpoint on transaction address  
Bins: reg0(0x00), reg1(0x04), reg2(0x08), reg3(0x0C)

**cp_we** — Coverpoint on transaction type  
Bins: write(1), read(0)

**cp_cross** — Cross coverage between address and type  
Goal: Every register exercised with both write and read

### Known Coverage Gap
Functional coverage collection requires a full Cadence 
Xcelium license. EDA Playground free tier does not enable 
coverage sampling — confirmed via COVNSM warning in 
simulation log. Coverage group is implemented and 
instrumented correctly. Collection to be verified with 
full license access.

---

## 5. What Was Not Tested

- Simultaneous read and write (not supported by AXI4-Lite)
- AWVALID arriving before WVALID on separate clock cycles
- Invalid addresses outside {0x00, 0x04, 0x08, 0x0C}
- Back-to-back transactions without idle cycles
- Reset during active transaction
- WSTRB byte enable functionality

These are identified as future test extensions.

---

## 6. UVM Architecture
xi4_test

└── axi4_env

├── axi4_agent

│   ├── axi4_driver      (drives AXI signals)

│   └── uvm_sequencer    (feeds transactions to driver)

├── axi4_monitor         (observes AXI write handshakes)

└── axi4_scoreboard      (checks correctness via TLM)

└── uvm_analysis_imp (receives from monitor.ap)

Sequences: axi4_write_seq, axi4_read_seq, axi4_mixed_seq

---

## 7. Simulation Results
UVM_INFO  : 20

UVM_WARNING : 0

UVM_ERROR : 0

UVM_FATAL : 0
[DRIVER] 8   [MON] 4   [SB] 6
SCOREBOARD SUMMARY: PASS=4 FAIL=0

ALL CHECKS PASSED

Simulation complete at time 545 NS