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

    input wire [1:0] which_core_requested // which core is requesting the data , 2 bits for 4 cores
);



parameter CACHE_LINES = 64; //& number of cache lines per core
parameter CACHE_LINE_SIZE = 4; //& size of each cache line in bytes , here 4 words = 16 bytes
parameter memory_block = 4096; //& size of main memory in bytes , 4KB


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

logic is_core_making_bugs; //& ⚡flag to indicate if the controller is idle

//~ /////////////////////////////////////////////////////////////////////////////////////////////////////////////////
// Main state machine and logic to handle MESI protocol will be implemented here
always @(posedge clk or posedge reset) begin
  
end


/*
~ FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF

                    FUNCTIONS AND TASKS FOR CACHE CONTROLLER

~ FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF
*/

function logic 

//~ /////////////////////////////////////////////////////////////////////////////////////////////////////////////////////
endmodule
