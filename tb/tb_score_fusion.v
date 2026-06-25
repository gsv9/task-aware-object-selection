`timescale 1ns/1ps

module tb_score_fusion;

    localparam DATA_WIDTH = 16;
    localparam ACC_WIDTH  = 40;

    reg signed [ACC_WIDTH-1:0] semantic_score;
    reg signed [DATA_WIDTH-1:0] spatial_score;
    reg signed [DATA_WIDTH-1:0] confidence_score;
    wire signed [ACC_WIDTH-1:0] final_score;

    score_fusion #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .semantic_score(semantic_score),
        .spatial_score(spatial_score),
        .confidence_score(confidence_score),
        .final_score(final_score)
    );

    initial begin
        semantic_score   = 40'sd1000;
        spatial_score    = 16'sd0;
        confidence_score = 16'sd0;
        #1;

        if (final_score < 40'sd699 || final_score > 40'sd701) begin
            $display("FAIL: expected about 700 got=%0d", final_score);
            $finish;
        end

        $display("PASS: score_fusion final_score=%0d", final_score);
        $finish;
    end

endmodule
