`timescale 1ns / 1ps

// ~ this is a single core _ ,  not both are here
// todo basic core is for putting and getting data from memory via cache controller
module cpu_core(
    input wire clk,
    input wire reset,

    //for cache interface
    output reg [31:0] cache_addr,
    output reg cache_rw, //1 for write, 0 for read  
    output reg cache_req, //1 to request ,// ! here this signal will be for requesting cache operation from different cores , this is single core's request line , and this is conected to two bit input of cache controller to identify which core is requesting
    output reg [31:0] cache_data_out
);

typedef enum logic [2:0]{
    IDLE = 3'b000
} core_state_t;

core_state_t state;

reg [3:0] current_instruction_location;
// Simple instruction stream for testing
reg [95:0] instruction_stream [0:7] = {
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
    if(reset) begin

        state <= IDLE;
        current_instruction_location <= 0;

    end else begin

        case(state)

            IDLE: begin

                if(current_instruction < 8) begin
                    //set up cache request here using instruction_stream[current_instruction]
                    cache_addr <= instruction_stream[current_instruction][95:64];
                    cache_rw <= (instruction_stream[current_instruction][31:0] != 0);
                    cache_data_out <= instruction_stream[current_instruction][31:0];
                    cache_req <= 1; 
                    current_instruction <= current_instruction + 1;
                end
                
            end 

        endcase
    end
end

endmodule