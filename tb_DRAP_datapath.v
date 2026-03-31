`timescale 1ns / 1ps

module tb_DRAP_datapath;

    // Inputs
    reg clk;
    reg rst;

    // Outputs
    wire [31:0] PC_out;
    wire [31:0] instr;
    wire [31:0] d_memory;
    wire co;
    wire zflag;
    wire ovr;

    // CPI Tracking Variables
    integer cycles_per_instr = 0;
    reg [31:0] prev_PC = 32'hFFFF_FFFF; 
    reg [31:0] prev_instr = 32'h0;

    // Instantiate the Unit Under Test (UUT)
    DRAP_datapath uut (
        .clk(clk), 
        .rst(rst), 
        .PC_out(PC_out), 
        .instr(instr), 
        .d_memory(d_memory), 
        .co(co), 
        .zflag(zflag), 
        .ovr(ovr)
    );

    // Clock generation (10ns period)
    always #5 clk = ~clk;

    initial begin
        // Initialize Inputs
        clk = 0;
        rst = 1;

        // Wait 15 ns to let everything settle, then release reset
        #15;
        rst = 0;

        // Run the simulation for enough time to finish the program
        #300; 
        
        $display("---------------------------------------------------------------");
        $display("Simulation Complete.");
        $finish;
    end

    // Print the header once at the start
    initial begin
        $display("Time\t | PC_out\t | Instr\t | RegWriteData\t | CPI");
        $display("---------------------------------------------------------------");
    end

    // 1. Increment the cycle counter on every positive clock edge
    always @(posedge clk) begin
        if (!rst) begin
            cycles_per_instr = cycles_per_instr + 1;
        end
    end

    // 2. Capture the instruction once memory has fetched it
    always @(instr) begin
        if (!rst) begin
            prev_instr = instr;
        end
    end

    // 3. Detect instruction boundaries when the PC changes
    always @(PC_out) begin
        if (!rst) begin
            // Don't print for the very first uninitialized state
            if (prev_PC != 32'hFFFF_FFFF) begin
                $display("%0t\t | %h\t | %h\t | %h\t | %0d", 
                         $time, prev_PC, prev_instr, uut.regWriteData, cycles_per_instr);
            end
            
            // Setup for the newly fetched instruction
            prev_PC = PC_out;
            cycles_per_instr = 0; // Reset the cycle counter
        end
    end

endmodule