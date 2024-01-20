// Testbench for the program memory of the CPU
// Created:     2024-01-20
// Modified:    2024-01-20
// Author:      Kagan Dikmen

`include "program_memory.v"

`timescale 1ns/1ps

module program_memory_tb
    #(
    parameter PC_WIDTH = 8
    )(
    );

    reg clk_t, rst_t, w_en_t;
    reg [PC_WIDTH-1:0] addr_t;
    wire [31:0] data_t;

    program_memory #(.PC_WIDTH(PC_WIDTH))
                    program_memory_ut
                    (
                        .clk(clk_t),
                        .rst(rst_t),
                        .w_en(w_en_t),
                        .addr(addr_t),
                        .data(data_t)
                    );
    
    always #1 clk_t = ~clk_t;
    
    initial
    begin

        clk_t <= 1'b0;
        rst_t <= 1'b0;
        w_en_t <= 1'b0;
        addr_t <= 'b0;

        #5;
        rst_t <= 1'b1;

        #10;
        rst_t <= 1'b0;

        #5;
        addr_t <= 'd3;

        #5;
        addr_t <= 'd10;

        #5;
        addr_t <= 'd15;

        #5;
        addr_t <= 'd2;

        #5;
        addr_t <= 'd0;
        
    end

endmodule