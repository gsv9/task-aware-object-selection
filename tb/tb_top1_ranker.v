`timescale 1ns/1ps

module tb_top1_ranker;

    localparam SCORE_WIDTH = 40;

    reg clk;
    reg rst_n;
    reg clear;
    reg valid;
    reg [3:0] object_index;
    reg signed [SCORE_WIDTH-1:0] object_score;

    wire [3:0] best_index;
    wire signed [SCORE_WIDTH-1:0] best_score;

    top1_ranker #(
        .MAX_OBJECTS(4),
        .SCORE_WIDTH(SCORE_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .clear(clear),
        .valid(valid),
        .object_index(object_index),
        .object_score(object_score),
        .best_index(best_index),
        .best_score(best_score)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task send_score;
        input [3:0] idx;
        input signed [SCORE_WIDTH-1:0] score;
        begin
            @(posedge clk);
            object_index = idx;
            object_score = score;
            valid = 1'b1;
            @(posedge clk);
            valid = 1'b0;
        end
    endtask

    initial begin
        rst_n = 1'b0;
        clear = 1'b0;
        valid = 1'b0;
        object_index = 4'd0;
        object_score = 40'sd0;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;

        @(posedge clk);
        clear = 1'b1;
        @(posedge clk);
        clear = 1'b0;

        send_score(4'd0, 40'sd100);
        send_score(4'd1, 40'sd300);
        send_score(4'd2, 40'sd200);
        send_score(4'd3, 40'sd150);

        @(posedge clk);
        if (best_index !== 4'd1 || best_score !== 40'sd300) begin
            $display("FAIL: expected best_index=1 best_score=300 got index=%0d score=%0d", best_index, best_score);
            $finish;
        end

        $display("PASS: top1_ranker best_index=%0d best_score=%0d", best_index, best_score);
        $finish;
    end

endmodule
