`ifndef AXI4_IF_SV
`define AXI4_IF_SV

interface axi4_if (input logic ACLK, input logic ARESETn);

    logic [31:0] AWADDR;
    logic        AWVALID;
    logic        AWREADY;

    logic [31:0] WDATA;
    logic [3:0]  WSTRB;
    logic        WVALID;
    logic        WREADY;

    logic [1:0]  BRESP;
    logic        BVALID;
    logic        BREADY;

    logic [31:0] ARADDR;
    logic        ARVALID;
    logic        ARREADY;

    logic [31:0] RDATA;
    logic [1:0]  RRESP;
    logic        RVALID;
    logic        RREADY;

endinterface

`endif