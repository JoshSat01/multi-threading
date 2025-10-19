module system_top(
    input wire clk,
    input wire reset
);

    // Core interfaces
    wire [1:0] core_req;
    wire [1:0] core_rw;
    wire [31:0] core_addr [0:1];
    wire [31:0] core_data_in [0:1];
    wire [1:0] core_ready;
    wire [31:0] core_data_out [0:1];
    
    // Memory interface
    wire mem_req;
    wire mem_rw;
    wire [31:0] mem_addr;
    wire [31:0] mem_data_out;
    wire [31:0] mem_data_in;
    wire mem_ready;

    // Instantiate all components
    mesi_cache_proper cache(
        .clk(clk),
        .reset(reset),
        .core_req(core_req),
        .core_rw(core_rw),
        .core_addr(core_addr),
        .core_data_in(core_data_in),
        .core_ready(core_ready),
        .core_data_out(core_data_out),
        .mem_req(mem_req),
        .mem_rw(mem_rw),
        .mem_addr(mem_addr),
        .mem_data_out(mem_data_out),
        .mem_data_in(mem_data_in),
        .mem_ready(mem_ready)
    );
    
    cpu_core core1(
        .clk(clk),
        .reset(reset),
        .cache_ready(core_ready[0]),
        .cache_data(core_data_out[0]),
        .cache_req(core_req[0]),
        .cache_rw(core_rw[0]),
        .cache_addr(core_addr[0]),
        .cache_data_out(core_data_in[0])
    );
    
    cpu_core core2(
        .clk(clk),
        .reset(reset),
        .cache_ready(core_ready[1]),
        .cache_data(core_data_out[1]),
        .cache_req(core_req[1]),
        .cache_rw(core_rw[1]),
        .cache_addr(core_addr[1]),
        .cache_data_out(core_data_in[1])
    );
    
    main_memory memory(
        .clk(clk),
        .reset(reset),
        .mem_req(mem_req),
        .mem_rw(mem_rw),
        .mem_addr(mem_addr),
        .mem_data_in(mem_data_out),
        .mem_data_out(mem_data_in),
        .mem_ready(mem_ready)
    );

endmodule