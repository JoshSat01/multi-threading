// Proper MESI Cache Coherency Protocol
// 2-core system with directory-based coherency
// Realistic address mapping and cache structure

module mesi_cache_proper(
    input wire clk,
    input wire reset,
    
    // Core interfaces
    input wire [1:0] core_req,           // [0]=core1, [1]=core2
    input wire [1:0] core_rw,            // 1=write, 0=read
    input wire [31:0] core_addr [0:1],   // 32-bit addresses
    input wire [31:0] core_data_in [0:1], // Write data from cores
    output reg [1:0] core_ready,
    output reg [31:0] core_data_out [0:1],
    
    // Memory interface
    output reg mem_req,
    output reg mem_rw,
    output reg [31:0] mem_addr,
    output reg [31:0] mem_data_out,
    input wire [31:0] mem_data_in,
    input wire mem_ready
);

// Parameters
parameter CACHE_LINES = 64;          // 64 cache lines per core
parameter CACHE_LINE_SIZE = 4;       // 4 words per cache line (16 bytes)
parameter MEMORY_BLOCKS = 4096;      // 4K memory blocks

// MESI States
typedef enum logic [1:0] {
    I = 2'b00,  // Invalid
    S = 2'b01,  // Shared
    E = 2'b10,  // Exclusive
    M = 2'b11   // Modified
} mesi_state_t;

// Cache line structure


typedef struct packed {
    logic [19:0] tag;           // 20-bit tag (for 32-bit address)
    mesi_state_t state;         // MESI state
    logic [31:0] data [0:3];    // 4 words of data
    logic valid;                // Valid bit
    logic dirty;                // Dirty bit (needs writeback)
} cache_line_t;

// Cache memory
cache_line_t cache [0:1][0:CACHE_LINES-1];  // [core][line]

// Directory entry
typedef struct packed {
    logic [1:0] presence;       // Bitmask of cores that have this block
    logic owner;                // Which core owns it (for E/M states)
    mesi_state_t global_state;  // Global state of this block
} dir_entry_t;

// Directory
dir_entry_t directory [0:MEMORY_BLOCKS-1];

// Internal signals
logic [1:0] current_core;
logic [31:0] current_addr;
logic current_rw;
logic [31:0] current_data;
logic operation_active;
logic [3:0] burst_count;

// Controller states
typedef enum logic [3:0] {
    IDLE = 4'b0000,
    CACHE_LOOKUP = 4'b0001,
    SEND_BUS_REQUEST = 4'b0010,
    WAIT_BUS_RESPONSE = 4'b0011,
    MEMORY_READ = 4'b0100,
    MEMORY_WRITE = 4'b0101,
    INVALIDATE_OTHERS = 4'b0110,
    WRITE_BACK = 4'b0111,
    UPDATE_CACHE = 4'b1000,
    COMPLETE = 4'b1001
} state_t;

state_t current_state;

// Address decomposition functions
function logic [5:0] get_index;
    input [31:0] addr;
    get_index = addr[11:6];  // 6-bit index (64 cache lines)
endfunction

function logic [19:0] get_tag;
    input [31:0] addr;
    get_tag = addr[31:12];   // 20-bit tag
endfunction

function logic [11:0] get_block_addr;
    input [31:0] addr;
    get_block_addr = addr[31:6];  // 12-bit block address (4K blocks)
endfunction

function logic [1:0] get_offset;
    input [31:0] addr;
    get_offset = addr[5:4];  // Word offset within cache line
endfunction

// Cache hit detection
function logic cache_hit;
    input [1:0] core;
    input [31:0] addr;
    logic [5:0] index;
    logic [19:0] tag;
    begin
        index = get_index(addr);
        tag = get_tag(addr);
        cache_hit = cache[core][index].valid && 
                   (cache[core][index].tag == tag) &&
                   (cache[core][index].state != I);
    end
endfunction

// Main state machine
always @(posedge clk or posedge reset) begin
    if (reset) begin
        current_state <= IDLE;
        core_ready <= 2'b00;
        operation_active <= 0;
        mem_req <= 0;
        
        // Initialize cache
        for (int core = 0; core < 2; core++) begin
            for (int line = 0; line < CACHE_LINES; line++) begin
                cache[core][line].valid <= 0;
                cache[core][line].state <= I;
                cache[core][line].dirty <= 0;
                cache[core][line].tag <= 0;
                for (int word = 0; word < 4; word++) begin
                    cache[core][line].data[word] <= 0;
                end
            end
        end
        
        // Initialize directory
        for (int block = 0; block < MEMORY_BLOCKS; block++) begin
            directory[block].presence <= 2'b00;
            directory[block].owner <= 0;
            directory[block].global_state <= E;
        end
    end else begin
        case (current_state)
            IDLE: begin
                core_ready <= 2'b00; /*
                    ~ two bits to indicate which core is ready like they represent two cores here
                    ! telling both cores as cache is not ready for any operation right now
                */
                mem_req <= 0;
                
                // Priority: core 0 then core 1
                if (core_req[0] && !operation_active) begin
                    current_core <= 0;
                    current_addr <= core_addr[0];
                    current_rw <= core_rw[0];
                    current_data <= core_data_in[0];
                    operation_active <= 1;
                    current_state <= CACHE_LOOKUP;
                end else if (core_req[1] && !operation_active) begin
                    current_core <= 1;
                    current_addr <= core_addr[1];
                    current_rw <= core_rw[1];
                    current_data <= core_data_in[1];
                    operation_active <= 1;
                    current_state <= CACHE_LOOKUP;
                end
            end
            
            CACHE_LOOKUP: begin
                if (cache_hit(current_core, current_addr)) begin
                    // Cache hit - check permissions
                    if (can_access_cache(current_core, current_addr, current_rw)) begin
                        current_state <= UPDATE_CACHE;
                    end else begin
                        current_state <= SEND_BUS_REQUEST;
                    end
                end else begin
                    // Cache miss
                    current_state <= SEND_BUS_REQUEST;
                end
            end
            
            SEND_BUS_REQUEST: begin
                // Check directory and send appropriate bus transactions
                logic [11:0] block_addr = get_block_addr(current_addr);
                dir_entry_t dir_entry = directory[block_addr];
                
                if (current_rw) begin
                    // Write request - need exclusive access
                    if (dir_entry.presence != 2'b00) begin
                        // Other cores have this block - need to invalidate
                        current_state <= INVALIDATE_OTHERS;
                    end else begin
                        // No other copies - go to memory
                        current_state <= MEMORY_READ;  // Read-for-ownership
                    end
                end else begin
                    // Read request
                    if (dir_entry.global_state == M || dir_entry.global_state == E) begin
                        // Block is owned by another core
                        current_state <= INVALIDATE_OTHERS;
                    end else begin
                        current_state <= MEMORY_READ;
                    end
                end
            end
            
            INVALIDATE_OTHERS: begin
                logic [11:0] block_addr = get_block_addr(current_addr);
                logic other_core = (current_core == 0) ? 1 : 0;
                logic [5:0] index = get_index(current_addr);
                logic [19:0] tag = get_tag(current_addr);
                
                // Invalidate other core's copy if it exists
                if (cache[other_core][index].valid && 
                    cache[other_core][index].tag == tag) begin
                    cache[other_core][index].state <= I;
                    if (cache[other_core][index].dirty) begin
                        // Write back modified data
                        current_state <= WRITE_BACK;
                    end else begin
                        directory[block_addr].presence[current_core] <= 1;
                        directory[block_addr].presence[other_core] <= 0;
                        directory[block_addr].owner <= current_core;
                        current_state <= MEMORY_READ;
                    end
                end else begin
                    current_state <= MEMORY_READ;
                end
            end
            
            MEMORY_READ: begin
                mem_req <= 1;
                mem_rw <= 0;
                mem_addr <= {get_block_addr(current_addr), 6'b000000};
                burst_count <= 0;
                
                if (mem_ready) begin
                    // Start burst read
                    current_state <= WAIT_BUS_RESPONSE;
                end
            end
            
            WAIT_BUS_RESPONSE: begin
                if (mem_ready) begin
                    logic [5:0] index = get_index(current_addr);
                    cache[current_core][index].data[burst_count] <= mem_data_in;
                    
                    if (burst_count == 3) begin
                        mem_req <= 0;
                        current_state <= UPDATE_CACHE;
                    end else begin
                        burst_count <= burst_count + 1;
                        mem_addr <= mem_addr + 4;  // Next word
                    end
                end
            end
            
            UPDATE_CACHE: begin
                logic [5:0] index = get_index(current_addr);
                logic [19:0] tag = get_tag(current_addr);
                logic [11:0] block_addr = get_block_addr(current_addr);
                logic [1:0] offset = get_offset(current_addr);
                
                // Update cache line
                cache[current_core][index].valid <= 1;
                cache[current_core][index].tag <= tag;
                
                if (current_rw) begin
                    // Write operation
                    cache[current_core][index].data[offset] <= current_data;
                    cache[current_core][index].state <= M;
                    cache[current_core][index].dirty <= 1;
                    directory[block_addr].global_state <= M;
                end else begin
                    // Read operation
                     if ((current_core == 0 && directory[block_addr].presence == 2'b01) ||
            (current_core == 1 && directory[block_addr].presence == 2'b10)) begin
                        cache[current_core][index].state <= E; 
                        directory[block_addr].global_state <= E;
                    end else begin
                        cache[current_core][index].state <= S;
                        directory[block_addr].global_state <= S;
                    end
                    cache[current_core][index].dirty <= 0;
                    core_data_out[current_core] <= cache[current_core][index].data[offset];
                end
                
                directory[block_addr].presence[current_core] <= 1;
                directory[block_addr].owner <= current_core;
                
                current_state <= COMPLETE;
            end
            
            COMPLETE: begin
                core_ready[current_core] <= 1;
                operation_active <= 0;
                current_state <= IDLE;
            end
            
            default: current_state <= IDLE;
        endcase
    end
end

// Check if cache access is allowed
function logic can_access_cache;
    input [1:0] core;
    input [31:0] addr;
    input rw;
    logic [5:0] index;
    begin
        index = get_index(addr);
        case (cache[core][index].state)
            I: can_access_cache = 0;  // Never allow access to Invalid
            S: can_access_cache = !rw; // Shared: read only
            E: can_access_cache = 1;   // Exclusive: read or write
            M: can_access_cache = 1;   // Modified: read or write
            default: can_access_cache = 0;
        endcase
    end
endfunction

// Performance monitoring
always @(posedge clk) begin
    if (operation_active && current_state == CACHE_LOOKUP) begin
        if (cache_hit(current_core, current_addr)) begin
            $display("Time %0t: Core %0d CACHE HIT for addr %h", 
                     $time, current_core, current_addr);
        end else begin
            $display("Time %0t: Core %0d CACHE MISS for addr %h", 
                     $time, current_core, current_addr);
        end
    end
end

endmodule