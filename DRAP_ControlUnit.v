module DRAP_ControlUnit_Multi (
    input clk,
    input rst,
    input [5:0] opcode,
    input [5:0] funct,
    
    // Core Datapath Control Signals
    output reg PCWrite,
    output reg IRWrite,
    output reg RegWrite,
    output reg memRead,
    output reg memWrite,
    output reg ALUSrc,
    output reg RegDst,
    output reg memtoReg,
    
    // Flow Control & Custom Datapath Signals
    output reg Branch,
    output reg Jump,
    output reg BranchNotEqual,
    output reg JumpReg,
    output reg JumpAndLink,
    output reg mfhi,
    output reg mflo
);

    // FSM States
    parameter FETCH    = 2'b00;
    parameter DECODE   = 2'b01;
    parameter EXECUTE  = 2'b10;
    parameter MEM_WB   = 2'b11;

    reg [1:0] current_state, next_state;

    // State Transition Register
    always @(posedge clk or posedge rst) begin
        if (rst) current_state <= FETCH;
        else current_state <= next_state;
    end

    // Next State Logic
    always @(*) begin
        case (current_state)
            FETCH:   next_state = DECODE;
            DECODE:  next_state = EXECUTE;
            EXECUTE: begin
                // Jumps, Branches, MULT, and DIV finish in the Execute stage.
                // Standard math (ADDI, ANDI, ORI) and MFLO need a Writeback stage.
                if (opcode == 6'h05 || opcode == 6'h03 || (opcode == 6'h00 && (funct == 6'h08 || funct == 6'h18 || funct == 6'h1A)))
                    next_state = FETCH;
                else
                    next_state = MEM_WB;
            end
            MEM_WB:  next_state = FETCH;
            default: next_state = FETCH;
        endcase
    end

    // Output Logic (Moore/Mealy)
    always @(*) begin
        // 1. Default all signals to 0 to prevent accidental writes or latches
        PCWrite = 0; IRWrite = 0; RegWrite = 0;
        memRead = 0; memWrite = 0; ALUSrc = 0; RegDst = 0; memtoReg = 0;
        Branch = 0; Jump = 0; BranchNotEqual = 0; JumpReg = 0; JumpAndLink = 0;
        mfhi = 0; mflo = 0;

        // 2. Drive signals based on current FSM state
        case (current_state)
            FETCH: begin
                IRWrite = 1; // Latch the instruction from memory
                // Note: We DO NOT update PC here in your architecture, otherwise 
                // the branch target adders in your IFetch module will calculate wrong!
            end

            DECODE: begin
                // Wait state: A and B registers automatically latch RegData1 & 2
            end

            EXECUTE: begin
                // Set ALUSrc for standard instructions
                if (opcode != 6'h00) ALUSrc = 1; // I-Type (Immediate)
                else ALUSrc = 0;                 // R-Type

                // Process Branch/Jump instructions (They finish in this state)
                case (opcode)
                    6'h05: begin // BNE
                        BranchNotEqual = 1; Branch = 1;
                        PCWrite = 1; // Update PC with branch target or PC+4
                    end
                    6'h03: begin // JAL
                        JumpAndLink = 1; Jump = 1; RegWrite = 1;
                        PCWrite = 1; // Update PC with jump target
                    end
                    6'h00: begin
                        if (funct == 6'h08) begin // JR
                            JumpReg = 1; 
                            PCWrite = 1; // Update PC with $rs
                        end
                        else if (funct == 6'h18 || funct == 6'h1A) begin // MULT / DIV
                            PCWrite = 1; // MULT/DIV modules write internally, just advance PC
                        end
                    end
                    default: ; // Do nothing for others
                endcase
            end

            MEM_WB: begin
                // All instructions that reach this state just need to advance PC by 4
                PCWrite = 1; 

                case (opcode)
                    6'h08, 6'h0C, 6'h0D: begin // ADDI, ANDI, ORI
                        RegWrite = 1; 
                        RegDst = 0; // Write to rt
                    end
                    6'h00: begin
                        if (funct == 6'h12) begin // MFLO
                            mflo = 1; 
                            RegWrite = 1; 
                            RegDst = 1; // Write to rd
                        end
                    end
                    default: ; // Do nothing
                endcase
            end
        endcase
    end
endmodule