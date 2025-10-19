module cpu_core(
    input wire clk,
    input wire reset,
    input wire cache_ready,
    input wire [31:0] cache_data,
    output reg cache_req,
    output reg cache_rw,
    output reg [31:0] cache_addr,
    output reg [31:0] cache_data_out
);

    typedef enum logic [2:0] {
        IDLE = 3'b000,
        READ_REQ = 3'b001,
        READ_WAIT = 3'b010,
        WRITE_REQ = 3'b011,
        WRITE_WAIT = 3'b100
    } core_state_t;
    
    core_state_t state;
    reg [31:0] pc;
    reg [31:0] registers [0:7];
    reg [2:0] instruction_count;
    
    // Simple instruction stream for testing
    reg [95:0] instruction_stream [0:7] = '{
        {32'h00001000, 32'h00000001, 32'h00000000}, // Read addr 0x1000 to reg1
        {32'h00001004, 32'h00000002, 32'h00000000}, // Read addr 0x1004 to reg2  
        {32'h00001000, 32'h00000003, 32'h12345678}, // Write 0x12345678 to addr 0x1000
        {32'h00001008, 32'h00000004, 32'h00000000}, // Read addr 0x1008 to reg4
        {32'h00001004, 32'h00000005, 32'hABCDEF12}, // Write 0xABCDEF12 to addr 0x1004
        {32'h00001000, 32'h00000006, 32'h00000000}, // Read addr 0x1000 to reg6
        {32'h0000100C, 32'h00000007, 32'h99999999}, // Write 0x99999999 to addr 0x100C
        {32'h00001008, 32'h00000000, 32'h00000000}  // Read addr 0x1008 to reg0
    };
    
    always @(posedge clk or posedge reset) begin
        if (reset) begin
            state <= IDLE;
            cache_req <= 0;
            pc <= 0;
            instruction_count <= 0;
            for (int i = 0; i < 8; i++) begin
                registers[i] <= 0;
            end
        end else begin
            case (state)
                IDLE: begin
                    if (instruction_count < 8) begin
                        // Decode instruction
                        cache_addr <= instruction_stream[instruction_count][95:64];
                        cache_rw <= (instruction_stream[instruction_count][31:0] != 0);
                        cache_data_out <= instruction_stream[instruction_count][31:0];
                        cache_req <= 1;
                        
                        if (instruction_stream[instruction_count][31:0] != 0) begin
                            state <= WRITE_REQ;
                        end else begin
                            state <= READ_REQ;
                        end
                    end
                end
                
                READ_REQ: begin
                    if (cache_ready) begin
                        registers[instruction_stream[instruction_count][35:32]] <= cache_data;
                        cache_req <= 0;
                        instruction_count <= instruction_count + 1;
                        state <= IDLE;
                        $display("Time %0t: Core - Read addr %h = %h to reg%d", 
                                $time, cache_addr, cache_data, instruction_stream[instruction_count][35:32]);
                    end
                end
                
                WRITE_REQ: begin
                    if (cache_ready) begin
                        cache_req <= 0;
                        instruction_count <= instruction_count + 1;
                        state <= IDLE;
                        $display("Time %0t: Core - Write addr %h = %h", 
                                $time, cache_addr, cache_data_out);
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end

endmodule