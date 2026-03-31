module DRAP_ControlUnit(
    input [5:0] opcode,
    input [5:0] funct,      
    
    output reg RegDst, ALUSrc, memtoReg, RegWrite, memRead, memWrite, Branch, Jump,
    output reg sel1, sel0, cin, binv,
    output reg BranchNotEqual, JumpReg, JumpAndLink,
    
    // NEW SIGNALS FOR MULT/DIV
    output reg mult_en,
    output reg div_en,
    output reg mfhi,
    output reg mflo
);

    always @(*) begin
        // Default to 0
        RegDst = 0; ALUSrc = 0; memtoReg = 0; RegWrite = 0; 
        memRead = 0; memWrite = 0; Branch = 0; Jump = 0;
        sel1 = 0; sel0 = 0; cin = 0; binv = 0;
        BranchNotEqual = 0; JumpReg = 0; JumpAndLink = 0;
        mult_en = 0; div_en = 0; mfhi = 0; mflo = 0;

        case (opcode)
            // R-TYPE INSTRUCTIONS (opcode == 0)
            6'b000000: begin
                case (funct)
                    6'b001000: JumpReg = 1; 
                    6'b011000: mult_en = 1; // mult
                    6'b011010: div_en = 1;  // div
                    6'b010000: begin        // mfhi
                        mfhi = 1;
                        RegWrite = 1;
                        RegDst = 1; // R-type writes to $rd
                    end
                    6'b010010: begin        // mflo
                        mflo = 1;
                        RegWrite = 1;
                        RegDst = 1; // R-type writes to $rd
                    end
                    default: ; 
                endcase
            end

            // I-TYPE INSTRUCTIONS
            6'b001000: begin // addi 
                ALUSrc = 1; RegWrite = 1; sel1 = 1; sel0 = 0; cin = 0; binv = 0;
            end
            6'b001100: begin // andi
                ALUSrc = 1; RegWrite = 1; sel1 = 0; sel0 = 0; cin = 0; binv = 0;
            end
            6'b001101: begin // ori
                ALUSrc = 1; RegWrite = 1; sel1 = 0; sel0 = 1; cin = 0; binv = 0;
            end
            6'b000101: begin // bne
                Branch = 1; BranchNotEqual = 1; sel1 = 1; sel0 = 0; cin = 1; binv = 1;
            end
            // J-TYPE INSTRUCTIONS
            6'b000011: begin // jal
                Jump = 1; JumpAndLink = 1; RegWrite = 1;
            end
            default: ; 
        endcase
    end
endmodule