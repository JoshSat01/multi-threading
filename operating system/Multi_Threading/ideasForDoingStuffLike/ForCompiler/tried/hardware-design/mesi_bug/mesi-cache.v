`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Bug Makers Inc.
// Engineer: 👽
// 
// Create Date:    19:12:12 10/16/2025 
// Design Name: 
// Module Name:    CacheController 
// Project Name: 🐞
// PROJECT TRYING DEEPSEEK LINK : https://chat.deepseek.com/share/wk686d3grstv0d5toj
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

//~ MESI Cache Coherency Protocol

/*

todo  handles cache coherency or [atomicity ??] between 2 cores

! this will happen inside core ??  or outside core ?? 
^ [just circling around words that are taged as believable , how to achieve like what really that is ??]

~ here going with in hardware design level flipping bits like 0 to 1 or 1 to 0...............

*/
module CacheController(

    input wire clk,// system clock , going with CPU clock that will make this flow synchronized
    input wire reset, // system reset , for initializing state machines and registers or going to known state or default state

    input wire [1:0] which_core_requested, // which core is requesting the cache , 2 bits for 2 cores 2'b01 _ core 0 , 2'b10 _ core 1
    input wire [31:0] cache_add [1:0], // address from cores
    input wire cache_rw[1:0], //1 for write, 0 for read
    input wire [31:0] cache_data_out[1:0] //data to be written to cache from cores

);

parameter CACHE_LINES = 64; //& number of cache lines per core to hold data like memory 


//~ mesi states
typedef enum logic [1:0] {
    MODIFIED = 2'b00,
    EXCLUSIVE = 2'b01,
    SHARED = 2'b10,
    INVALID = 2'b11
} mesi_state_t;


//~ //////////////////////////////////////////////////////////////////////////////////////////////////////////////
/*
! in hardware the below line , 
~ cache_core becomes

///////////////////////////////////////////////////////////////////////

Bank 0: [0:CACHE_LINES-1]
┌─────────┬─────────┬──────────────┬──────────────────┐
│ valid   │ dirty   │ tag[19:0]    │ data[511:0]      │  ← cache[0][0]
│ valid   │ dirty   │ tag[19:0]    │ data[511:0]      │  ← cache[0][1]
│ ...     │ ...     │ ...          │ ...              │
│ valid   │ dirty   │ tag[19:0]    │ data[511:0]      │  ← cache[0][CACHE_LINES-1]
└─────────┴─────────┴──────────────┴──────────────────┘

Bank 1: [0:CACHE_LINES-1]  
┌─────────┬─────────┬──────────────┬──────────────────┐
│ valid   │ dirty   │ tag[19:0]    │ data[511:0]      │  ← cache[1][0]
│ valid   │ dirty   │ tag[19:0]    │ data[511:0]      │  ← cache[1][1]
│ ...     │ ...     │ ...          │ ...              │
│ valid   │ dirty   │ tag[19:0]    │ data[511:0]      │  ← cache[1][CACHE_LINES-1]
└─────────┴─────────┴──────────────┴──────────────────┘

////////////////////////////////////////////////////////////////////////
*/

//~ cache line structure 64 lines total , each line holds below design
typedef struct packed{
    logic [19:0] tag; //& 20 bits tag for 4KB memory with 16 bytes line size
    mesi_state_t state; //& mesi state of the cache line that handles atomicity
    logic [31:0] data [0:3] ; //& 4 words of data per cache line
    logic valid; //& valid bit to indicate if the cache line contains valid data
    logic dirty; //& dirty bit to indicate if the cache line has been modified
} cache_line_t;


cache_line_t cache_core[1:0] [0:CACHE_LINES-1]; //^ 2 cores , each with 64 cache lines

//~ //////////////////////////////////////////////////////////////////////////////////////////////////////////////

// ! know about what ??

//directory
typedef struct packed {
    logic [1:0] where_this_block_is_cached; //& 2 bits to indicate which cores have this block cached
    logic owner_core; //& which core is the owner of this block
    mesi_state_t global_state_core [1:0]; //& mesi state for each core
} directory_entry_t;

directory_entry_t directory [0:memory_block-1]; //^ directory for main memory blocks


//~ //////////////////////////////////////////////////////////////////////////////////////////////////////////////

// Internal signals
logic [1:0] current_core;
logic [31:0] current_addr;
logic current_rw;
logic [31:0] current_data;
logic [3:0] burst_count;

logic is_cache_making_bugs; //& ⚡flag to indicate if the cache controller is idle

//~ /////////////////////////////////////////////////////////////////////////////////////////////////////////////////

// ! state machine and logic to handle MESI protocol

typedef enum logic [3:0]{
    IDLE = 4'b0000,
    BUG_CACHED = 4'b0001 //🐞

} state_type;

state_type state;

//~ /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Main state machine and logic to handle MESI protocol will be implemented here
always @(posedge clk or posedge reset) begin
    if(reset) begin 
        is_cache_making_bugs <= 1'b0; //& on reset , cache is idle
    end
    else begin 
        case(state)
            IDLE: begin 
                //here if more cores requesting at the same time , we can have priority based handling , can ask why core 0 ?? 
                if(which_core_requested == 2'b01 && !is_cache_making_bugs ) begin
                    current_core <= 0;
                    current_addr <= core_addr[0];
                    current_rw <= core_rw[0];
                    current_data <= core_data_in[0];
                    is_cache_making_bugs <= 1;
                end else if(which_core_requested == 2'b10 && !is_cache_making_bugs ) begin
                    current_core <= 1;
                    current_addr <= core_addr[1];
                    current_rw <= core_rw[1];
                    current_data <= core_data_in[1];
                    is_cache_making_bugs <= 1;
                end
            end
            BUG_CACHED:begin 

            end

        endcase
    end
end


/*
~ FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

                    FUNCTIONS AND TASKS FOR CACHE CONTROLLER

~ FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
*/


//& to get location in cache based on 8 bit or 1 byte memory address // here in memory is byte addressable or each 8 bit
//&                   tag(22 bits)    index(6 bits)    offset(2 bits) 
//! 32 bit address -> [31:10]            [9:4]             [3:2]        [1:0]   here this is start of memory location not cache line offset
//~ making 64 blocks , each block has 64 lines , each line has 16 bytes (4 words of 32 bits)
//~ so need 12 bits for block address to point to specific cache line in block
//&                 block_address[15:4]

function logic [1:0] get_offset;
    input logic [31:0] addr;
    get_offset = addr[3:2];
endfunction

function logic [5:0] get_index;
    input logic [31:0] addr;
    get_index = addr[9:4];
endfunction

function logic [19:0] get_tag;
    input logic [31:0] addr;
    get_tag = addr[31:10];  
endfunction

//32 bit address and here 64 blocks of memory in cache , so need 6 bits to address 64 blocks
function logic [11:0] get_block_addr;
    input logic [31:0] addr;
    get_block_addr = addr[15:4];  // 12-bit block address (64 blocks) to point to specific cache in block
endfunction


//~ /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////

endmodule
