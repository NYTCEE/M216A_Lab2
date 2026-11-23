`timescale 1ns/100ps
module FSM_tb;
    reg clk;
    reg rst;
    reg data;
    wire out;
    integer errors;

    FSM dut (.clk(clk), .rst(rst), .data(data), .out(out));

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // Set data on falling edge; read output shortly after rising edge.
    task send_bit;
        input bit_in;
        input expected_out;
        begin
            @(negedge clk);
            data = bit_in;
            @(posedge clk);
            #1;
            if (out !== expected_out) begin
                $display("FAIL t=%0t data=%b expected=%b got=%b",
                         $time, bit_in, expected_out, out);
                errors = errors + 1;
            end else begin
                $display("PASS t=%0t data=%b out=%b", $time, bit_in, out);
            end
        end
    endtask

    initial begin
        rst = 1'b0;
        data = 1'b0;
        errors = 0;
        #12;
        rst = 1'b1;

        // 1101101101 contains TWO overlapping instances of 1101101:
        // bits 1-7 and 4-10. Output pulses at positions 7 and 10.
        send_bit(1'b1, 1'b0); // 1
        send_bit(1'b1, 1'b0); // 2
        send_bit(1'b0, 1'b0); // 3
        send_bit(1'b1, 1'b0); // 4
        send_bit(1'b1, 1'b0); // 5
        send_bit(1'b0, 1'b0); // 6
        send_bit(1'b1, 1'b1); // 7: first match
        send_bit(1'b1, 1'b0); // 8
        send_bit(1'b0, 1'b0); // 9
        send_bit(1'b1, 1'b1); // 10: second match
        send_bit(1'b0, 1'b0); // output pulse must end

        // Check asynchronous active-low reset without awaiting next clock.
        #2;
        rst = 1'b0;
        #1;
        if (out !== 1'b0) begin
            $display("FAIL asynchronous reset");
            errors = errors + 1;
        end

        if (errors == 0)
            $display("FSM TESTS PASSED");
        else
            $display("FSM TESTS FAILED: %0d errors", errors);
        $finish;
    end
endmodule
