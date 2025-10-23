`timescale 1ns / 1ps
//~ ////////////////////////////////////////////////////////////////////////////////
//! Company: Bug Makers Inc.
//! Engineer:  👽
//~ 
//! Create Date:    19:12:12 10/16/2025
//! Design Name:
//! Module Name:    main_memory
//! Project Name: 🐞

//~ ///////////////////////////////////////////////////////////////////////////////////////////////


module main_memory(
    input wire clk,
    input wire reset,
    input wire memory_request,
    input wire [31:0] memory_address,
    input wire memory_rw, // 1 for write, 0 for read
    input wire [31:0] memory_data_in,

    output reg memory_ready_to_interface,//1 -> can interface , 0-> busy
    output reg [31:0] memory_data_out

)

typedef enum logic [2:0] {
    MEMORY_IDLE = 2'b00,
    MEMORY_READ = 2'b01,
    MEMORY_WRITE = 2'b10,
    MEMORY_BURST = 2'b11,//here burst state is for handling different time domain between memory and cache ... 
    MEMORY_WRITE_BUFFER = 2'b100
} memory_state_type;

reg [31:0] _0xff [0:16777215]; // 16MB memory
reg [31:0] current_address;
reg operation_active; // this will handle memory availability like if a memory operation is ongoing
reg burst_counter[3:0];//for counting , ??
reg memory_buffer[31:0];//for storing data temporarily

always @(posedge clk or posedge reset) begin
    if (reset) begin
        
    end else begin
        case (state) 
            MEMORY_IDLE: begin
                memory_ready_to_interface <= 0; // not accessible this cycle
                memory_buffer <= 0;
                if(memory_request && !operation_active) begin
                    current_address <= memory_address;
                    memory_buffer <= 0;
                    operation_active <= 1;// mark memory as busy
                    burst_counter <= 0;
                    if(memory_rw) begin
                        state <= MEMORY_WRITE;
                    end else begin
                        state <= MEMORY_READ;
                    end
                end
            end


            MEMORY_READ: begin
                // Read one word (4 bytes)
                memory_data_out[0:7] <= _0xff[current_address];
                memory_data_out[8:15] <= _0xff[current_address + 1]; 
                memory_data_out[16:23] <= _0xff[current_address + 2];
                memory_data_out[24:31] <= _0xff[current_address + 3];  
                memory_ready_to_interface <= 1;

                if(burst_counter == 3) begin 
                    state <= MEMORY_IDLE;
                    operation_active <= 0;
                end else begin
                    burst_counter <= burst_counter + 1;
                    current_address <= current_address + 4;
                end
            end

            MEMORY_WRITE: begin
                memory_buffer <= memory_data_in; //hold data from outside
                state <= MEMORY_WRITE_BUFFER;
              
            end


            MEMORY_WRITE_BUFFER: begin
                // Write one word (4 bytes)
                _0xff[current_address]     <= memory_buffer[0:7];
                _0xff[current_address + 1] <= memory_buffer[8:15];
                _0xff[current_address + 2] <= memory_buffer[16:23];
                _0xff[current_address + 3] <= memory_buffer[24:31];
                memory_ready_to_interface <= 1;//next cycle that data is ready to interfaceS

                if(burst_counter == 3) begin 
                    state <= MEMORY_IDLE;
                    operation_active <= 0;
                end else begin
                    burst_counter <= burst_counter + 1;
                    current_address <= current_address + 4;
                    state <= MEMORY_BURST;
                end
            end


            MEMORY_BURST: begin 
                if(memory_rw) begin 
                    state <= MEMORY_WRITE;
                    memory_ready_to_interface <= 0;//busy
                end else begin 
                    state <= MEMORY_READ;
                end
            end

        endcase
    end
end



endmodule