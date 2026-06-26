`timescale 1ns/1ps

module tb_score_fusion;

    localparam DATA_WIDTH = 16;
    localparam ACC_WIDTH  = 40;

    reg signed [ACC_WIDTH-1:0] semantic_score;
    reg signed [DATA_WIDTH-1:0] spatial_score;
    reg signed [DATA_WIDTH-1:0] confidence_score;
    wire signed [ACC_WIDTH-1:0] final_score;

    integer errors;

    score_fusion #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .semantic_score(semantic_score),
        .spatial_score(spatial_score),
        .confidence_score(confidence_score),
        .final_score(final_score)
    );

    task check;
        input signed [ACC_WIDTH-1:0] expected;
        input signed [ACC_WIDTH-1:0] tolerance;
        input [200*8-1:0] label;
        begin
            #1;
            if (final_score < (expected - tolerance) || final_score > (expected + tolerance)) begin
                $display("FAIL [%0s]: expected ~%0d (+/-%0d) got=%0d", label, expected, tolerance, final_score);
                errors = errors + 1;
            end else begin
                $display("PASS [%0s]: final_score=%0d", label, final_score);
            end
        end
    endtask

    initial begin
        errors = 0;

        // Semantic-only path. ALPHA~0.9238 -> 1000*0.9238 ~ 923
        semantic_score = 40'sd1000; spatial_score = 0; confidence_score = 0;
        check(40'sd923, 1, "semantic_only");

        // Spatial-only path. BETA~0.0286 -> 100*0.0286 ~ 2
        semantic_score = 0; spatial_score = 16'sd100; confidence_score = 0;
        check(40'sd2, 1, "spatial_only");

        // Confidence-only path. GAMMA~0.0476 -> 100*0.0476 ~ 4
        semantic_score = 0; spatial_score = 0; confidence_score = 16'sd100;
        check(40'sd4, 1, "confidence_only");

        // Combined, all positive
        semantic_score = 40'sd1000; spatial_score = 16'sd100; confidence_score = 16'sd100;
        check(40'sd931, 1, "combined_positive");

        // Negative semantic score (object actively dissimilar to task)
        semantic_score = -40'sd1000; spatial_score = 16'sd100; confidence_score = 16'sd100;
        check(-40'sd917, 1, "negative_semantic");

        // Negative spatial/confidence
        semantic_score = 40'sd1000; spatial_score = -16'sd100; confidence_score = -16'sd100;
        check(40'sd916, 1, "negative_spatial_confidence");

        // All zero
        semantic_score = 0; spatial_score = 0; confidence_score = 0;
        check(40'sd0, 0, "all_zero");

        // Max-magnitude stress test: largest representable semantic_score
        // alongside max spatial/confidence, to confirm no overflow/wraparound
        // in the ACC_WIDTH-wide final_score (ALPHA<1.0 keeps the dominant
        // semantic term within range; spatial/confidence are DATA_WIDTH-wide
        // so their contribution is small relative to ACC_WIDTH headroom).
        semantic_score = {1'b0, {(ACC_WIDTH-1){1'b1}}};      // max positive ACC_WIDTH value
        spatial_score = {1'b0, {(DATA_WIDTH-1){1'b1}}};      // max positive DATA_WIDTH value
        confidence_score = {1'b0, {(DATA_WIDTH-1){1'b1}}};
        #1;
        $display("INFO [max_magnitude_stress]: semantic=%0d spatial=%0d confidence=%0d -> final_score=%0d",
                  semantic_score, spatial_score, confidence_score, final_score);
        if (final_score < 0) begin
            $display("FAIL [max_magnitude_stress]: final_score wrapped negative -- overflow in ACC_WIDTH");
            errors = errors + 1;
        end

        if (errors == 0) begin
            $display("ALL PASS: score_fusion (%0d checks)", 7);
        end else begin
            $display("%0d CHECK(S) FAILED", errors);
        end
        $finish;
    end

endmodule