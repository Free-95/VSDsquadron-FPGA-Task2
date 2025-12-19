module adder (
    input [3:0] a,b,
    input c_in,
    output [4:0] out
);

    assign out = a + b + c_in;

endmodule