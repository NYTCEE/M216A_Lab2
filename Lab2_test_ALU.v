`timescale 1ns/100ps

module Lab2_test_ALU();

// Inputs
reg         clk;
reg         reset;
reg  [7:0]  inputA;
reg  [7:0]  inputB;
reg  [2:0]  instruction;

// Outputs
wire [15:0] alu_out;

// Testbench variables
reg  [15:0] expected;
integer i, j, outfile, pat_error;
integer test_count;
integer true_out;

// Select instruction to test:
// 0000 - 0111: Test individual instruction
// 1000: Test all instructions
parameter [3:0] test_instruction = 4'b1000;

// Instantiate Design Under Test (DUT)
Lab2_ALU alu_0 (
    .clk_p_i   (clk),
    .reset_n_i (reset),
    .data_a_i  (inputA),
    .data_b_i  (inputB),
    .inst_i    (instruction),
    .data_o    (alu_out)
);

// Clock period = 8 ns
initial clk = 1'b0;
always #4 clk = ~clk;

// ============================================================
// Task: Test one ALU operation
// ============================================================
// Inputs are applied at the falling edge.
// The DUT captures inputs at the next rising edge.
// The output register captures the result at the
// following rising edge.
// ============================================================

task check_alu;
    input [2:0] op;
    input [7:0] a;
    input [7:0] b;

    begin
        // Calculate expected result
        case (op)
            3'b000: true_out = a + b;
            3'b001: true_out = a - b;
            3'b010: true_out = a * b;
            3'b011: true_out = a & b;
            3'b100: true_out = a ^ b;
            3'b101: true_out = 0;
            3'b110: true_out = (a - b) * 4;
            3'b111: true_out = 0;
            default: true_out = 0;
        endcase

        // Keep lower 16 bits, including two's complement
        expected = true_out[15:0];

        // Apply inputs before rising clock edge
        @(negedge clk);
        instruction = op;
        inputA = a;
        inputB = b;

        // First rising edge: capture inputs
        @(posedge clk);

        // Second rising edge: capture ALU result
        @(posedge clk);

        // Wait for nonblocking assignments to settle
        #0.1;

        test_count = test_count + 1;

        if (alu_out !== expected) begin
            pat_error = pat_error + 1;

            // Limit file size if many errors occur
            if (pat_error <= 100) begin
                $fdisplay(outfile,
                    "ERROR: inst=%b A=%d B=%d expected=%h actual=%h",
                    op, a, b, expected, alu_out);
            end
        end
    end
endtask

// ============================================================
// Task: Test all operand combinations for one instruction
// ============================================================

task test_opcode;
    input [2:0] op;

    begin
        $display("Testing instruction %b ...", op);

        if ((op == 3'b101) || (op == 3'b111)) begin
            // Unused instructions must always output zero
            // Test all values of A with varying B
            for (i=0; i<256; i=i+1) begin
                check_alu(op, i, 255-i);
            end
        end
        else begin
            // Exhaustive test of both 8-bit operands
            for (i=0; i<256; i=i+1) begin
                for (j=0; j<256; j=j+1) begin
                    check_alu(op, i, j);
                end
            end
        end
    end
endtask

// ============================================================
// Main test sequence
// ============================================================

initial begin

    outfile = $fopen("alu_out.txt", "w");

    if (!outfile) begin
        $display("Cannot write output file!");
        $finish;
    end

    pat_error = 0;
    test_count = 0;

    reset = 1'b1;
    inputA = 8'b0;
    inputB = 8'b0;
    instruction = 3'b000;

    // Asynchronous active-low reset
    #1 reset = 1'b0;
    #1;

    if (alu_out !== 16'b0) begin
        $fdisplay(outfile, "ERROR: Reset output is not zero");
        pat_error = pat_error + 1;
    end

    #1 reset = 1'b1;

    // Allow pipeline to initialize
    repeat (3) @(negedge clk);

    // Select tests
    case (test_instruction)

        4'b0000: test_opcode(3'b000); // Add
        4'b0001: test_opcode(3'b001); // Subtract
        4'b0010: test_opcode(3'b010); // Multiply
        4'b0011: test_opcode(3'b011); // AND
        4'b0100: test_opcode(3'b100); // XOR
        4'b0101: test_opcode(3'b101); // Unused
        4'b0110: test_opcode(3'b110); // Subtract x4
        4'b0111: test_opcode(3'b111); // Unused

        default: begin
            test_opcode(3'b000);
            test_opcode(3'b001);
            test_opcode(3'b010);
            test_opcode(3'b011);
            test_opcode(3'b100);
            test_opcode(3'b101);
            test_opcode(3'b110);
            test_opcode(3'b111);
        end

    endcase

    // ========================================================
    // Verify asynchronous reset after normal operation
    // ========================================================

    @(negedge clk);
    #1 reset = 1'b0;
    #0.1;

    test_count = test_count + 1;

    if (alu_out !== 16'b0) begin
        pat_error = pat_error + 1;
        $fdisplay(outfile,
            "ERROR: Asynchronous reset failed. actual=%h",
            alu_out);
    end

    #1 reset = 1'b1;

    // ========================================================
    // Final report
    // ========================================================

    $display("\n======================================");
    $display("        ALU TEST RESULTS");
    $display("======================================");
    $display("Total tests : %0d", test_count);
    $display("Errors      : %0d", pat_error);

    if (pat_error == 0)
        $display("PASS: All ALU tests passed!");
    else
        $display("FAIL: Check alu_out.txt for details.");

    $display("======================================\n");

    $fclose(outfile);

    #10 $stop;

end

endmodule
