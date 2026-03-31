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
        
        $display("Simulation Complete.");
        $finish;
    end

    // Monitor outputs to the console
    initial begin
        $display("Time\t | PC_out\t | Instr\t | RegWriteData");
        $display("---------------------------------------------------------------");
        
        // This will print to the console every time the clock goes high
        $monitor("%0t\t | %h\t | %h\t | %h", 
                 $time, PC_out, instr, uut.regWriteData);
    end

endmodule