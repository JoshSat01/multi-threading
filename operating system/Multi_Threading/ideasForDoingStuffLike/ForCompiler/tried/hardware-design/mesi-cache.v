`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    19:12:12 10/16/2025 
// Design Name: 
// Module Name:    CacheController 
// Project Name: 
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

todo  handles cache coherency or [atomicity ??] between 4 cores

! this will happen inside core ??  or outside core ?? 
^ [just circling around words that are taged as believable , how to achieve like what really that is ??]


*/
module CacheController(

    input wire clk,// system clock , going with CPU clock that will make this flow synchronized
    input wire reset, // system reset , for initializing state machines and registers or going to known state or default state

    input wire [1:0] which_core_requesting // which core is requesting the data , 2 bits for 4 cores
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


//~ cache line structure 64 lines , each line 4 words = 16 bytes
typedef struct packed{
    logic [19:0] tag; //& 20 bits tag for 4KB memory with 16 bytes line size
    mesi_
} cache_line_t;


cache_line_t cache_core[1:0] [0:CACHE_LINES-1]; //^ 2 cores , each with 64 cache lines

/*
! in hardware the above line , 
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

endmodule
