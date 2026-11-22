////////////////////////////////////////////////////////////////
//
// Module: Lab2_ALU.v
// Author: ECE M216A Naomi Chen
//
// Description:
//      ALU for Lab2
//
// Parameters:
//      None
//
// Inputs:
//      clk_p_i    : Positive-edge triggered clock
//      reset_n_i  : Asynchronous active-low reset
//      data_a_i   : 8-bit unsigned operand A
//      data_b_i   : 8-bit unsigned operand B
//      inst_i     : 3-bit instruction selecting the ALU operation
//
// Outputs:
//      data_o     : 16-bit registered ALU result
//
////////////////////////////////////////////////////////////////

module Lab2_ALU ( 
    clk_p_i,
    reset_n_i,
    data_a_i,
    data_b_i,
    inst_i,
    data_o
    );

////////////////////////////////////////////////////////////////
//  Inputs & Outputs
input           clk_p_i;
input           reset_n_i;
input   [7:0]   data_a_i;
input   [7:0]   data_b_i;
input   [2:0]   inst_i;

output  [15:0]  data_o;
	
////////////////////////////////////////////////////////////////
//  reg & wire declarations
//  Complete all missing bit widths and logic expressions.
wire [15:0] out_inst_0; // A + B
wire [15:0] out_inst_1; // A - B, 16-bit two's complement
wire [15:0] out_inst_2; // A * B
wire [15:0] out_inst_3; // A & B, zero extended
wire [15:0] out_inst_4; // A ^ B, zero extended
wire [15:0] out_inst_5; // Unused, zero
wire [15:0] out_inst_6; // 4 * (A - B), 16-bit two's complement
wire [15:0] out_inst_7; // Unused, zero

reg     [15:0]   ALU_out_inst;
wire    [15:0]   ALU_d2_w; // D input of the output register
reg     [15:0]   ALU_d2_r; // Q output of the output register

reg	[7:0]	Data_A_o_r;
reg	[7:0]	Data_B_o_r;
reg	[2:0]	Inst_o_r;

////////////////////////////////////////////////////////////////
//  Combinational Logic
assign ALU_d2_w = ALU_out_inst;
assign data_o = ALU_d2_r;
assign out_inst_0 = {8'b0, Data_A_o_r} + {8'b0, Data_B_o_r};
assign out_inst_1 = {8'b0, Data_A_o_r} - {8'b0, Data_B_o_r};
assign out_inst_2 = {8'b0, Data_A_o_r} * {8'b0, Data_B_o_r};
assign out_inst_3 = {8'b0, (Data_A_o_r & Data_B_o_r)};
assign out_inst_4 = {8'b0, (Data_A_o_r ^ Data_B_o_r)};
assign out_inst_5 = 16'b0;
assign out_inst_6 = out_inst_1 << 2;
assign out_inst_7 = 16'b0;

// The output MUX
// Implement combinational logic without inferring latches
always @(*) begin
    case(Inst_o_r)
        3'b000:	    ALU_out_inst = out_inst_0;
        3'b001:	    ALU_out_inst = out_inst_1;
        3'b010:	    ALU_out_inst = out_inst_2;
        3'b011:	    ALU_out_inst = out_inst_3;
        3'b100:	    ALU_out_inst = out_inst_4;
        3'b101:	    ALU_out_inst = out_inst_5;
        3'b110:	    ALU_out_inst = out_inst_6;
        3'b111:	    ALU_out_inst = out_inst_7;
        default:    ALU_out_inst = 16'b0;
    endcase
end

////////////////////////////////////////////////////////////////
//  Registers
always @(posedge clk_p_i or negedge reset_n_i) begin
    if (reset_n_i == 1'b0) begin
        ALU_d2_r    <= {(16){1'b0}};
        Data_A_o_r  <= {(8){1'b0}};
        Data_B_o_r  <= {(8){1'b0}};
        Inst_o_r    <= 3'b111;
    end
    else begin
        ALU_d2_r    <= ALU_d2_w;
        Data_A_o_r  <= data_a_i;
        Data_B_o_r  <= data_b_i;
        Inst_o_r    <= inst_i; 
    end
end

endmodule
