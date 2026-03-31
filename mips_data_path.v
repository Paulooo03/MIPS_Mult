module alu_1bit (
output result, co,
input a, b, cin, binv, less, sel1, sel0);
wire bmux, sum, and0, or0;
mux2_1 M1 (bmux, binv, b);
and M2 (and0, a, bmux);
or M3 (or0, a, bmux);
full_adder M4 (sum, co, a, bmux, cin);
mux4_1 M5 (result, and0, or0, sum, less, sel1, sel0);
endmodule

module alu_4bit (
output [3:0] result,
output co,
input [3:0] a, b,
input cin, sel1, sel0, binv,
input [3:0] less);
wire cin1, cin2, cin3;
alu_1bit M1 ( result[0], cin1, a[0], b[0], cin, binv, less[0], sel1, sel0);
alu_1bit M2 ( result[1], cin2, a[1], b[1], cin1, binv, less[1], sel1, sel0);
alu_1bit M3 ( result[2], cin3, a[2], b[2], cin2, binv, less[2], sel1, sel0);
alu_1bit M4 ( result[3], co, a[3], b[3], cin3, binv, less[3], sel1, sel0);
endmodule

module alu_4bit_upper (
output [3:0] result,
output co, set, ovr,
input [3:0] a, b,
input [3:0] less,
input cin, binv, sel1, sel0 );
wire cin1, cin2, cin3,cin4;
alu_1bit M1 ( result[0], cin1, a[0], b[0], cin, binv, less[0], sel1, sel0);
alu_1bit M2 ( result[1], cin2, a[1], b[1], cin1, binv, less[1], sel1, sel0);
alu_1bit M3 ( result[2], cin3, a[2], b[2], cin2, binv, less[2], sel1, sel0);
alu_last_bit M4 ( result[3], cin4, set, a[3], b[3], cin3, binv, less[3], sel1, sel0);
xor M5 (ovr, cin3, cin4);
assign co = cin4;
endmodule

module alu_8bit (
output [7:0] result,
output co,
input [7:0] a, b,
input cin, binv,
input [7:0]less,
input sel1, sel0
);
wire cin1;
alu_4bit M1 ( result[3:0], cin1, a[3:0], b[3:0], cin, binv, less[3:0], sel1, sel0);
alu_4bit M2 ( result[7:4], co, a[7:4], b[7:4], cin1, binv, less[7:4], sel1, sel0);
endmodule

module alu_16bit (
output [15:0] result, output co, input [15:0] a, b,
input cin, binv,
input [15:0] less,
input sel1, sel0);
wire cin1;
alu_8bit M1 ( result[7:0], cin1, a[7:0], b[7:0], cin, binv, less[7:0], sel1, sel0);
alu_8bit M2 ( result[15:8], co, a[15:8], b[15:8], cin1, binv, less[15:8], sel1, sel0);
endmodule

module alu_24bit (
output [23:0] result,
output co,
input [23:0] a, b,
input cin, binv,
input [23:0] less,
input sel1, sel0);
wire cin1;
alu_16bit M1 ( result[15:0], cin1, a[15:0], b[15:0], cin, binv, less[15:0], sel1, sel0);
alu_8bit M2 ( result[23:16], co, a[23:16], b[23:16], cin1, binv, less[23:16], sel1, sel0);
endmodule

module alu_32bit(
output [3:0] result,
output co, set, ovr,
input [3:0] a, b,
input cin, binv,
input [3:0] less,
input sel1, sel0 );
wire cin1, cin2, cin3,cin4;
alu_1bit M1 ( result[0], cin1, a[0], b[0], cin, binv, less[0], sel1, sel0);
alu_1bit M2 ( result[1], cin2, a[1], b[1], cin1, binv, less[1], sel1, sel0);
alu_1bit M3 ( result[2], cin3, a[2], b[2], cin2, binv, less[2], sel1, sel0);
alu_last_bit M4 ( result[3], cin4, set, a[3], b[3], cin3, binv, less[3], sel1, sel0);
xor M5 (ovr, cin3, cin4);
assign co = cin4;
endmodule

module alu_last_bit (
output result, co, set,
input a, b, cin, binv, less, sel1, sel0);
wire bmux, sum, and0, or0;
mux2_1 M1 (bmux, binv, b);
and M2 (and0, a, bmux);
or M3 (or0, a, bmux);
full_adder M4 (sum, co, a, bmux, cin);
mux4_1 M5 (result, and0, or0, sum, less, sel1, sel0);
assign set = sum;
endmodule

module DRAP_ALU (
output [31:0] result,
output co, zero, ovr,
input [31:0] a, b,
input cin, binv,
input sel1, sel0);
wire [31:0]less;
assign less[31:1] = 31'b0;
alu_32bit M1 (result[31:0], co, set, ovr, a[31:0] , b[31:0] , cin, binv, less[31:0], sel1, sel0);
assign less[0] = set;
nor M2 (zero,result[31],result[30],result[29],result[28],result[27],result[26],result[25],
result[24],result[23],result[22],result[21],result[20],result[19],
result[18],result[17],result[16],result[15],result[14],result[13],result[12],
result[11],result[10],result[9],result[8],result[7],result[6],result[5],result[4],
result[3],result[2],result[1]);
endmodule

module DRAP_datapath(
    input clk, 
    input rst, 
    output [31:0] PC_out, instr, d_memory,
    output co, zflag, ovr
);
wire [31:0] IR_out;     // Output of Instruction Register
wire [31:0] A_out;      // Output of A Register
wire [31:0] B_out;      // Output of B Register
wire [31:0] ALUOut_out; // Output of ALUOut Register
wire [31:0] MDR_out;    // Output of Memory Data Register

wire PCWrite, IRWrite;  // New control signals
wire z;
wire [31:0] pcout;
wire [4:0] wr_addr, normal_wr_addr;
wire [31:0] regWriteData, regData1, regData2, alu_in2;
wire [31:0] instruction, aluData, dmemory, sign_extend;
wire [31:0] normal_write_data, pcplus4_out; 

// Internal wires for Control Unit signals
wire RegDst, ALUSrc, memtoReg, RegWrite, memRead, memWrite;
wire Branch, Jump, sel1, sel0, cin, binv;
wire BranchNotEqual, JumpReg, JumpAndLink; 
wire mult_en, div_en, mfhi, mflo;
wire [31:0] hi_out, lo_out;

// --- CONTROL UNIT ---
DRAP_ControlUnit_Multi CU (
    .clk(clk), .rst(rst),
    .opcode(IR_out[31:26]), .funct(IR_out[5:0]),
    .RegDst(RegDst), .ALUSrc(ALUSrc), .memtoReg(memtoReg), .RegWrite(RegWrite),
    .memRead(memRead), .memWrite(memWrite), .Branch(Branch), .Jump(Jump),
    .PCWrite(PCWrite), .IRWrite(IRWrite),
    .BranchNotEqual(BranchNotEqual), .JumpReg(JumpReg), .JumpAndLink(JumpAndLink)
    // Note: sel1, sel0, cin, binv, mult_en, div_en are moved to the ALU Controller
);

// 1. Instruction Register (IR)
// Grabs instruction from memory only during FETCH state
DRAP_StageReg IR_reg (
    .clk(clk), .rst(rst), .en(IRWrite), 
    .d(instruction), // from IROM
    .q(IR_out)       // Feeds into Control Unit, RegFile, etc.
);

// 2. A and B Registers
// Constantly grabs data from RegFile on every clock
DRAP_StageReg A_reg (.clk(clk), .rst(rst), .en(1'b1), .d(regData1), .q(A_out));
DRAP_StageReg B_reg (.clk(clk), .rst(rst), .en(1'b1), .d(regData2), .q(B_out));

// 3. ALUOut Register
// Grabs ALU result at the end of EXECUTE state
DRAP_StageReg ALUOut_reg (.clk(clk), .rst(rst), .en(1'b1), .d(aluData), .q(ALUOut_out));

// 4. Memory Data Register (MDR)
// Grabs Data Memory output at the end of MEM state
DRAP_StageReg MDR_reg (.clk(clk), .rst(rst), .en(1'b1), .d(dmemory), .q(MDR_out));

// --- UPDATED IFETCH INSTANTIATION ---
DRAP_Ifetch M1 (
    .PC_out(pcout), .pcplus4_out(pcplus4_out), 
    .sign_ext_in(sign_extend[29:0]), 
    .instruction(instruction[25:0]), // This one stays raw instruction directly from ROM
    .rs_val(A_out),                  // Changed to A_out
    .Br_in(Branch), .Zero_in(z), .jmp(Jump), .rst(rst), .clk(clk),
    .BranchNotEqual(BranchNotEqual), .JumpReg(JumpReg),
    .PCWrite(PCWrite)                // <--- NEW: Hooked up to CU
);

DRAP_Irom M3 (
    .iROMdata(instruction), 
    .address(pcout[6:0]), 
    .clk(clk)
);

DRAP_regFile M4 (
    .clk(clk), .rst(rst), .wr_en(RegWrite), 
    .r_addr1(IR_out[25:21]), // Changed to IR_out
    .r_addr2(IR_out[20:16]), // Changed to IR_out
    .w_addr(wr_addr), 
    .w_data(regWriteData), 
    .r_data1(regData1), .r_data2(regData2)
);

mux5bit_2to1 M5 (
    .muxout(normal_wr_addr), 
    .op0(IR_out[20:16]),     // Changed to IR_out
    .op1(IR_out[15:11]),     // Changed to IR_out
    .sel(RegDst)
);

// --- NEW: JAL Write Address Mux ---
// Forces the write address to register 31 ($ra) if JumpAndLink is active
assign wr_addr = JumpAndLink ? 5'd31 : normal_wr_addr;


MUX32BIT_2TO1 M6 (
    .out(alu_in2), 
    .in0(B_out), 
    .in1(sign_extend), 
    .sel(ALUSrc)
);

DRAP_sign_xtnd M7 (
    .signExtend(sign_extend), 
    .instr(IR_out[15:0])
);

DRAP_ALU M8 (
    .result(aluData), .co(co), .zero(z), .ovr(ovr), 
    .a(A_out), .b(alu_in2), .cin(cin), .binv(binv), .sel1(sel1), .sel0(sel0)
);

DRAP_MultDiv M_MultDiv (
    .clk(clk), .rst(rst),
    .a(A_out), .b(B_out),
    .mult_en(mult_en), .div_en(div_en),
    .hi(hi_out), .lo(lo_out)
);

DRAP_Dmemory M9 (
    .data_out(dmemory), .data_in(B_out), .address(ALUOut_out[6:0]), // Changed to B_out and ALUOut_out
    .clk(clk), .write(memWrite), .read(memRead)
);

MUX32BIT_2TO1 M10 (
    .out(normal_write_data), 
    .in0(ALUOut_out),        // Changed to ALUOut_out
    .in1(MDR_out),           // Changed to MDR_out
    .sel(memtoReg)
);

DRAP_ALUControl ALU_Ctrl (
    .opcode(IR_out[31:26]), .funct(IR_out[5:0]),
    .sel1(sel1), .sel0(sel0), .binv(binv), .cin(cin),
    .mult_en(mult_en), .div_en(div_en)
);

// --- NEW: JAL Write Data Mux ---
// Forces the write data to be PC+4 if JumpAndLink is active
assign normal_write_data = mfhi     ? hi_out :
                           mflo     ? lo_out :
                           memtoReg ? dmemory : 
                                      aluData;

assign regWriteData = JumpAndLink ? pcplus4_out : normal_write_data;

assign zflag = z;
assign instr = instruction;
assign d_memory = dmemory;
assign PC_out = pcout;

endmodule

module DRAP_Dmemory (
    output [31:0] data_out,
    input  [31:0] data_in,
    input  [6:0]  address,
    input         clk,
    input         write,
    input         read  // Added to match the 6 ports in your datapath
);

    // Memory array: 128 words, 32 bits wide
    reg [31:0] Dmemory [127:0];

    // Asynchronous read: continuously outputs the data at the given address.
    // (In simple datapaths, it's safe to ignore the 'read' signal for the output, 
    // since the MemtoReg mux decides whether we actually care about this data).
    assign data_out = Dmemory[address];

    // Synchronous write
    always @ (posedge clk) begin
        if (write) begin
            Dmemory[address] <= data_in; // Using non-blocking (<=) for memory writes is best practice
        end
    end

endmodule

module DRAP_Ifetch(
    output [31:0] PC_out,
    output [31:0] pcplus4_out, // NEW: Export PC+4 for the JAL instruction
    input [29:0] sign_ext_in, 
    input [25:0] instruction,
    input [31:0] rs_val,       // NEW: Import regData1 for the JR instruction
    input Br_in, Zero_in, jmp, rst, clk,
    input BranchNotEqual,      // NEW: Control signal for BNE
    input JumpReg,              // NEW: Control signal for JR
    input PCWrite              // <--- NEW: Add this
);

wire [31:0] pcout, pcplus4, shl2, cond_br, jmp_addr;
wire [31:0] tmp1, next_pc, tmp2;
wire w1, actual_zero;

assign PC_out = pcout;
assign pcplus4_out = pcplus4; // Exporting PC+4 to the datapath

// Change 1'b1 to PCWrite
DRAP_PC M1(pcout, tmp2, PCWrite, rst, clk);
DRAP_IFETCH_ADDER M2(pcplus4, pcout, 32'h4);
DRAP_shiftl2 M3(shl2, sign_ext_in[29:0]);
DRAP_IFETCH_ADDER M4(cond_br, pcplus4, shl2);

// --- NEW: BNE Logic ---
// If BranchNotEqual is high, we invert the Zero flag. 
// This allows the AND gate to trigger the branch when Zero is 0.
assign actual_zero = BranchNotEqual ? ~Zero_in : Zero_in;
and M6(w1, Br_in, actual_zero);

Ifetch_mux1 M5(tmp1, pcplus4, cond_br, w1);
Ifetch_sh2 M7(jmp_addr, instruction, pcplus4[31:28]); 

// Standard Jump Mux
Ifetch_mux1 M8(next_pc, tmp1, jmp_addr, jmp);

// --- NEW: JR Logic ---
// Selects between the normal next PC (branch/jump/PC+4) and the value inside $rs
Ifetch_mux1 M9(tmp2, next_pc, rs_val, JumpReg);

endmodule

module DRAP_ALUControl (
    input [5:0] opcode,
    input [5:0] funct,
    output reg sel1, sel0, binv, cin, mult_en, div_en
);
    always @(*) begin
        sel1 = 0; sel0 = 0; binv = 0; cin = 0; mult_en = 0; div_en = 0;

        case (opcode)
            6'h00: begin // R-Type
                case (funct)
                    6'h18: mult_en = 1; // mult
                    6'h1A: div_en = 1;  // div
                    6'h2A: begin // slt (NEW!)
                        sel1 = 1; sel0 = 1; binv = 1; cin = 1;
                    end
                endcase
            end
            6'h08: begin sel1 = 1; sel0 = 0; binv = 0; cin = 0; end // ADDI
            6'h0C: begin sel1 = 0; sel0 = 0; binv = 0; cin = 0; end // ANDI
            6'h0D: begin sel1 = 0; sel0 = 1; binv = 0; cin = 0; end // ORI
            6'h05: begin sel1 = 1; sel0 = 0; binv = 1; cin = 1; end // BNE
            default: ; 
        endcase
    end
endmodule

module DRAP_StageReg #(parameter WIDTH = 32) (
    input clk,
    input rst,
    input en, // Enable signal (used mainly for the Instruction Register)
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk or posedge rst) begin
        if (rst) 
            q <= 0;
        else if (en) 
            q <= d;
    end
endmodule

module DRAP_IFETCH_ADDER(sum, op1, op2);
parameter B = 32; //data bits
output [B-1: 0] sum;
input [B-1: 0] op1, op2;
assign sum = op1 + op2;
endmodule

module DRAP_Imemory (data_out, data_in, address, clk, write);
parameter B = 32; //data bits
parameter W = 7; //address bits. 7 = 2**7 = 128 word memory
output [B-1: 0] data_out;
input [B-1: 0] data_in;
input [W-1: 0] address;
input clk, write;
reg [B-1: 0] Imemory [2**W-1: 0];
assign data_out = Imemory[address];
always @ (posedge clk)
if (write) Imemory[address] = data_in;
endmodule

module DRAP_Irom (
    output reg [31:0] iROMdata, 
    input wire [6:0] address, 
    input wire clk
);

    reg [6:0] addr;
    always @(posedge clk) addr <= address;

    always @(*) begin
        case (addr)
            // 1. Load unsorted values
            7'h00 : iROMdata = 32'h2001000F; // addi $1, $0, 15
            7'h04 : iROMdata = 32'h20020008; // addi $2, $0, 8
            7'h08 : iROMdata = 32'h20030002; // addi $3, $0, 2
            
            // 2. Compare $1 and $2
            7'h0C : iROMdata = 32'h0022202A; // slt $4, $1, $2  ($4 = 1 if $1 < $2)
            7'h10 : iROMdata = 32'h14800003; // bne $4, $0, 3   (Skip swap if already sorted)
            
            // 3. Swap $1 and $2 (uses $5 as temp)
            7'h14 : iROMdata = 32'h20250000; // addi $5, $1, 0  (temp = $1)
            7'h18 : iROMdata = 32'h20410000; // addi $1, $2, 0  ($1 = $2)
            7'h1C : iROMdata = 32'h20A20000; // addi $2, $5, 0  ($2 = temp)
            
            // 4. Compare $2 and $3
            7'h20 : iROMdata = 32'h0043202A; // slt $4, $2, $3
            7'h24 : iROMdata = 32'h14800003; // bne $4, $0, 3
            
            // 5. Swap $2 and $3
            7'h28 : iROMdata = 32'h20450000; // addi $5, $2, 0
            7'h2C : iROMdata = 32'h20620000; // addi $2, $3, 0
            7'h30 : iROMdata = 32'h20A30000; // addi $3, $5, 0
            
            // 6. Compare $1 and $2 AGAIN (because smallest bubbled down)
            7'h34 : iROMdata = 32'h0022202A; // slt $4, $1, $2
            7'h38 : iROMdata = 32'h14800003; // bne $4, $0, 3
            
            // 7. Swap $1 and $2
            7'h3C : iROMdata = 32'h20250000; // addi $5, $1, 0
            7'h40 : iROMdata = 32'h20410000; // addi $1, $2, 0
            7'h44 : iROMdata = 32'h20A20000; // addi $2, $5, 0
            
            // 8. Halt
            7'h48 : iROMdata = 32'h1400FFFF; // bne $0, $0, -1 (Infinite Loop)
            
            default: iROMdata = 32'h00000000; // NOP
        endcase
    end
endmodule

module DRAP_PC(PC_out, PC_in, PC_load, rst, clk);
parameter B = 32; //data bits
output [B-1: 0] PC_out;
input [B-1: 0] PC_in;
input PC_load, rst, clk;
reg [B-1: 0] tmp;
always @ (posedge clk, posedge rst)
if (rst)
tmp <= 0;
else
if (PC_load) tmp <= PC_in;
assign PC_out = tmp;
endmodule

module DRAP_regFile
#(
parameter B = 32, //number of bits
W = 5 //number of address bits
)
(input wire clk,
input wire rst, wr_en,
input wire [W-1:0] r_addr1, r_addr2, w_addr,
input wire [B-1:0] w_data,
output wire [B-1:0] r_data1, r_data2);
reg [B-1:0] array_reg [2**W-1:0];// = 32'b00000000_00000000_00000000_00000000;
always @(posedge clk, posedge rst)
if (rst)
begin
array_reg[5'b00000] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b00001] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b00010] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b00011] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b00100] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b00101] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b00110] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b00111] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b01000] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b01001] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b01010] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b01011] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b01100] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b01101] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b01110] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b01111] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b10000] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b10001] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b10010] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b10011] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b10100] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b10101] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b10110] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b10111] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b11000] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b11001] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b11010] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b11011] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b11100] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b11101] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b11110] <= 32'b00000000_00000000_00000000_00000000;
array_reg[5'b11111] <= 32'b00000000_00000000_00000000_00000000;
end
else
if (wr_en)
array_reg[w_addr] <=w_data;
// read operation
assign r_data1 = array_reg[r_addr1];
assign r_data2 = array_reg[r_addr2];
endmodule

module DRAP_shiftl2(shl2,sign_ext);
output [31:0] shl2;
input [29:0] sign_ext;
assign shl2 = {sign_ext[29:0],2'b0};
endmodule

module DRAP_sign_xtnd(signExtend, instr);
output [31:0] signExtend;
input [15:0] instr;
reg [31:0] tmp;
always @*
if (instr[15]) tmp = {16'b11111111_11111111,instr};
else tmp = {16'b00000000_00000000,instr};
assign signExtend = tmp;
endmodule

// MODULE full_adder.v
// sum = a b' c' + a' b cin' + a b cin + a' b' cin
// cout = a b + a cin + b cin
module full_adder (
output sum, co,
input a, bmux, cin);
wire co1, co2, co3, x_or, x_nor, cin_n, sum1, sum2;
// sum
xor M1 (x_or, a, bmux);
xnor M2 (x_nor, a, bmux);
not M3 (cin_n, cin);
and M4 (sum1, cin_n, x_or);
and M5 (sum2, cin, x_nor);
or M6(sum, sum1, sum2);
// cout
and M7 (co1, a, bmux);
and M8 (co2, a, cin);
and M9 (co3, bmux, cin);
or M10 (co, co1, co2, co3);
endmodule

module Ifetch_mux1(mux_out1, op0, op1, sel);
parameter B = 32; //data bits
output [B-1: 0] mux_out1;
input [B-1: 0] op0, op1;
input sel;
reg [B-1:0] tmp;
always @ (sel, op0, op1)
if (sel) tmp = op1;
else tmp = op0;
assign mux_out1 = tmp;
endmodule

module Ifetch_sh2(sh2_out, instr_in, PCplus4);
output [31: 0] sh2_out;
input [25: 0] instr_in; // from address portion of instruction
input [3: 0] PCplus4;
assign sh2_out = {PCplus4,instr_in,2'b00};
endmodule

module mux2_1 (
output bmux,
input binv, b);
wire w1, w2, binv_n, bn;
not M1 (bn, b);
not M2 (binv_n, binv);
and M3 (w1, b, binv_n);
and M4 (w2, bn, binv);
or M5 (bmux, w1, w2);
endmodule

module mux4_1 (
output result,
input and0, or0, sum, less, sel1, sel0);
wire sel1n, sel0n, mux0, mux1, mux2;
not M1 (sel1n, sel1);
not M2 (sel0n, sel0);
and M3 (mux0, and0, sel1n, sel0n);
and M4 (mux1, or0, sel1n, sel0);
and M5 (mux2, sum, sel1, sel0n);
and M6 (mux3, less, sel1, sel0);
or M7 (result, mux0, mux1, mux2, mux3);
endmodule

module mux5bit_2to1(muxout, op0, op1, sel);
output[4:0] muxout;
input[4:0] op0, op1;
input sel;
reg[4:0] tmp;
always @(posedge sel)
if (sel) tmp <= op1;
else tmp <= op0;
assign muxout = tmp;
endmodule

module MUX32BIT_2TO1 (
    output [31:0] out,
    input  [31:0] in0,
    input  [31:0] in1,
    input         sel
);

    // If sel is 1, output in1. If sel is 0, output in0.
    assign out = sel ? in1 : in0;

endmodule

module DRAP_MultDiv(
    input clk,
    input rst,
    input [31:0] a,       // regData1 ($rs)
    input [31:0] b,       // regData2 ($rt)
    input mult_en,        // Control signal for multiply
    input div_en,         // Control signal for divide
    output reg [31:0] hi, // HI register output
    output reg [31:0] lo  // LO register output
);

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            hi <= 32'b0;
            lo <= 32'b0;
        end else if (mult_en) begin
            // 64-bit result split into HI and LO
            {hi, lo} <= a * b; 
        end else if (div_en && b != 0) begin
            // Protect against divide-by-zero
            lo <= a / b;       // Quotient
            hi <= a % b;       // Remainder
        end
    end

endmodule

module DRAP_StageReg #(parameter WIDTH = 32) (
    input clk,
    input rst,
    input en, // Enable signal (used mainly for the Instruction Register)
    input [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk or posedge rst) begin
        if (rst) 
            q <= 0;
        else if (en) 
            q <= d;
    end
endmodule
