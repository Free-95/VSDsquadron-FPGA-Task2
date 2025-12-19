module tb;
    reg [3:0] a, b; 
    reg c_in;
    wire [4:0] out;

    adder uut (.a(a), .b(b), .c_in(c_in), .out(out));

    initial begin: init
        integer i;
        for (i = 0; i < 4; i=i+1) begin
            #10;
            a = $urandom_range(15, 0);
            b = $urandom_range(15, 0);
            c_in = $urandom_range(1, 0);
            $display("Input 1: %d, Input 2: %d, Carry: %b, Sum: %d", a, b, c_in, out);
        end

    end
endmodule