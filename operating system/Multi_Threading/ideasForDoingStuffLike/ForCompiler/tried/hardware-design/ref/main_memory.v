module main_memory(
    input wire clk,
    input wire reset,
    input wire mem_req,
    input wire mem_rw,
    input wire [31:0] mem_addr,
    input wire [31:0] mem_data_in,
    output reg [31:0] mem_data_out,
    output reg mem_ready
);

    // 16MB memory (4K blocks × 4KB per block)
    reg [7:0] memory [0:16777215];
    reg [3:0] burst_counter;
    reg [31:0] current_addr;
    reg operation_active;
    
    typedef enum logic [1:0] {
        MEM_IDLE = 2'b00,
        MEM_READ = 2'b01,
        MEM_WRITE = 2'b10,
        MEM_BURST = 2'b11
    } mem_state_t;
    
    mem_state_t state;
    
    // Initialize memory with test data
    initial begin
        for (int i = 0; i < 16777216; i++) begin
            memory[i] = i[7:0];  // Pattern for testing
        end
    end
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= MEM_IDLE;
            mem_ready <= 0;
            burst_counter <= 0;
            operation_active <= 0;
        end else begin
            case (state)
                MEM_IDLE: begin
                    mem_ready <= 0;
                    if (mem_req && !operation_active) begin
                        current_addr <= mem_addr;
                        operation_active <= 1;
                        burst_counter <= 0;
                        
                        if (mem_rw) begin
                            state <= MEM_WRITE;
                        end else begin
                            state <= MEM_READ;
                        end
                    end
                end
                
                MEM_READ: begin
                    // Read one word (4 bytes)
                    mem_data_out[7:0]   <= memory[current_addr];
                    mem_data_out[15:8]  <= memory[current_addr + 1];
                    mem_data_out[23:16] <= memory[current_addr + 2];
                    mem_data_out[31:24] <= memory[current_addr + 3];
                    mem_ready <= 1;
                    
                    if (burst_counter == 3) begin
                        state <= MEM_IDLE;
                        operation_active <= 0;
                        burst_counter <= 0;
                    end else begin
                        state <= MEM_BURST;
                        burst_counter <= burst_counter + 1;
                        current_addr <= current_addr + 4;
                    end
                end
                
                MEM_WRITE: begin
                    // Write one word (4 bytes)
                    memory[current_addr]     <= mem_data_in[7:0];
                    memory[current_addr + 1] <= mem_data_in[15:8];
                    memory[current_addr + 2] <= mem_data_in[23:16];
                    memory[current_addr + 3] <= mem_data_in[31:24];
                    mem_ready <= 1;
                    
                    if (burst_counter == 3) begin
                        state <= MEM_IDLE;
                        operation_active <= 0;
                        burst_counter <= 0;
                    end else begin
                        state <= MEM_BURST;
                        burst_counter <= burst_counter + 1;
                        current_addr <= current_addr + 4;
                    end
                end
                
                MEM_BURST: begin
                    mem_ready <= 0;
                    state <= MEM_READ;  // Continue burst
                end
            endcase
        end
    end

endmodule