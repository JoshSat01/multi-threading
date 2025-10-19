module testbench;
    reg clk;
    reg reset;
    
    // Instantiate the complete system
    system_top dut(
        .clk(clk),
        .reset(reset)
    );
    
    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end
    
    // Test sequence
    initial begin
        reset = 1;
        #20 reset = 0;
        
        $display("Starting MESI Protocol Test...");
        
        // Let the test run for some time
        #1000;
        
        $display("Test Complete");
        $finish;
    end
    
    // Monitor
    always @(posedge clk) begin
        if (dut.cache.operation_active) begin
            $display("Time %0t: Cache operation - Core %0d, Addr %h, State: %s",
                    $time, dut.cache.current_core, dut.cache.current_addr,
                    dut.cache.cache_state_to_string(dut.cache.cache[dut.cache.current_core][dut.cache.get_index(dut.cache.current_addr)].state));
        end
    end

endmodule