`timescale 1ns/1ps

module tb_similarity_mac;

    localparam VECTOR_DIM = 8;
    localparam DATA_WIDTH = 16;
    localparam ACC_WIDTH  = 40;
    localparam signed [DATA_WIDTH-1:0] Q15_ONE = 16'sd32767;

    reg clk;
    reg rst_n;
    reg start;
    reg signed [VECTOR_DIM*DATA_WIDTH-1:0] task_vec_flat;
    reg signed [VECTOR_DIM*DATA_WIDTH-1:0] obj_vec_flat;

    wire busy;
    wire done;
    wire signed [ACC_WIDTH-1:0] score;

    integer timeout_count;

    similarity_mac #(
        .VECTOR_DIM(VECTOR_DIM),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .task_vec_flat(task_vec_flat),
        .obj_vec_flat(obj_vec_flat),
        .busy(busy),
        .done(done),
        .score(score)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    initial begin
        rst_n = 1'b0;
        start = 1'b0;
        task_vec_flat = {VECTOR_DIM*DATA_WIDTH{1'b0}};
        obj_vec_flat  = {VECTOR_DIM*DATA_WIDTH{1'b0}};

        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        task_vec_flat[0*DATA_WIDTH +: DATA_WIDTH] = Q15_ONE;
        obj_vec_flat[0*DATA_WIDTH +: DATA_WIDTH]  = Q15_ONE;

        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        timeout_count = 0;
        while (!done && timeout_count < 50) begin
            @(posedge clk);
            timeout_count = timeout_count + 1;
        end

        if (!done) begin
            $display("FAIL: similarity_mac timed out");
            $finish;
        end

        if (score !== 40'sd1073676289) begin
            $display("FAIL: expected score=1073676289 got=%0d", score);
            $finish;
        end

        $display("PASS: similarity_mac score=%0d", score);
        $finish;
    end

endmodule
