// ECE M216A Lab 2B
// Moore FSM: detect the serial bit pattern 1101101, including overlaps.
// 'out' goes high for exactly one full clock cycle on each detection.
module FSM (
    input  clk,
    input  rst,   // Active-low asynchronous reset: rst=0 resets the FSM.
    input  data,
    output out
);
    reg [2:0] state, next_state;

    // S_k means that the most recently received bits match the first k
    // bits of the pattern 1101101. S7 is the detected state.
    localparam S0 = 3'd0,
               S1 = 3'd1,
               S2 = 3'd2,
               S3 = 3'd3,
               S4 = 3'd4,
               S5 = 3'd5,
               S6 = 3'd6,
               S7 = 3'd7;

    // State register
    always @(posedge clk or negedge rst) begin
        if (!rst)
            state <= S0;
        else
            state <= next_state;
    end

    // Combinational next-state logic. Crucial overlap transition:
    // after a full match (S7), another 1 moves to S5, not S1/S2/S0.
    always @(*) begin
        case (state)
            S0: next_state = data ? S1 : S0;
            S1: next_state = data ? S2 : S0;
            S2: next_state = data ? S2 : S3;
            S3: next_state = data ? S4 : S0;
            S4: next_state = data ? S5 : S0;
            S5: next_state = data ? S2 : S6;
            S6: next_state = data ? S7 : S0;
            S7: next_state = data ? S5 : S0;
            default: next_state = S0;
        endcase
    end

    // Moore output: registered state determines the output.
    assign out = (state == S7);
endmodule
