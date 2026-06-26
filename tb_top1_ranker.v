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

    integer errors;

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

    task do_clear;
        begin
            @(posedge clk);
            clear = 1'b1;
            @(posedge clk);
            clear = 1'b0;
        end
    endtask

    task check_result;
        input [3:0] exp_idx;
        input signed [SCORE_WIDTH-1:0] exp_score;
        input [200*8-1:0] label;
        begin
            @(posedge clk);
            if (best_index !== exp_idx || best_score !== exp_score) begin
                $display("FAIL [%0s]: expected idx=%0d score=%0d got idx=%0d score=%0d",
                          label, exp_idx, exp_score, best_index, best_score);
                errors = errors + 1;
            end else begin
                $display("PASS [%0s]: idx=%0d score=%0d", label, best_index, best_score);
            end
        end
    endtask

    initial begin
        errors = 0;
        rst_n = 1'b0;
        clear = 1'b0;
        valid = 1'b0;
        object_index = 4'd0;
        object_score = 40'sd0;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;

        // --- Case 1: original happy-path (regression) ---
        do_clear;
        send_score(4'd0, 40'sd100);
        send_score(4'd1, 40'sd300);
        send_score(4'd2, 40'sd200);
        send_score(4'd3, 40'sd150);
        check_result(4'd1, 40'sd300, "happy_path");

        // --- Case 2: tie-break -- first object to reach the score wins, later ties don't overwrite ---
        do_clear;
        send_score(4'd0, 40'sd500);
        send_score(4'd1, 40'sd500); 
        send_score(4'd2, 40'sd100);
        check_result(4'd0, 40'sd500, "tie_break_first_wins");

        // --- Case 3: all-negative scores -- ranker must still pick the least-negative correctly ---
        do_clear;
        send_score(4'd0, -40'sd500);
        send_score(4'd1, -40'sd100);
        send_score(4'd2, -40'sd900);
        send_score(4'd3, -40'sd300);
        check_result(4'd1, -40'sd100, "all_negative_scores");

        // --- Case 4: single object only ---
        do_clear;
        send_score(4'd2, 40'sd42);
        check_result(4'd2, 40'sd42, "single_object");

        // --- Case 5: clear and valid asserted same cycle -- clear must take priority ---
        do_clear;
        send_score(4'd0, 40'sd1000); 
        @(posedge clk);
        clear = 1'b1;
        valid = 1'b1;
        object_index = 4'd3;
        object_score = 40'sd999; 
        @(posedge clk);
        clear = 1'b0;
        valid = 1'b0;
        check_result(4'd0, {1'b1, {(SCORE_WIDTH-1){1'b0}}}, "clear_priority_over_valid");

        // --- Case 6: two independent ranking rounds back-to-back, separated by clear ---
        do_clear;
        send_score(4'd0, 40'sd10);
        send_score(4'd1, 40'sd20);
        check_result(4'd1, 40'sd20, "round_one");

        do_clear;
        send_score(4'd2, 40'sd5);
        send_score(4'd3, 40'sd999);
        check_result(4'd3, 40'sd999, "round_two_after_clear");

        if (errors == 0) begin
            $display("ALL PASS: top1_ranker");
        end else begin
            $display("%0d CHECK(S) FAILED", errors);
        end
        $finish;
    end

endmodule