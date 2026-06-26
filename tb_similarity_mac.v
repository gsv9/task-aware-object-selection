`timescale 1ns/1ps

module tb_similarity_mac;

    localparam VECTOR_DIM = 8;
    localparam DATA_WIDTH = 16;
    localparam ACC_WIDTH  = 40;
    localparam signed [DATA_WIDTH-1:0] Q15_ONE  = 16'sd32767;
    localparam signed [DATA_WIDTH-1:0] Q15_MIN  = -16'sd32768;

    reg clk;
    reg rst_n;
    reg start;
    reg signed [VECTOR_DIM*DATA_WIDTH-1:0] task_vec_flat;
    reg signed [VECTOR_DIM*DATA_WIDTH-1:0] obj_vec_flat;

    wire busy;
    wire done;
    wire signed [ACC_WIDTH-1:0] score;

    integer errors;
    integer i;

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

    task run_and_check;
        input signed [ACC_WIDTH-1:0] expected;
        input [200*8-1:0] label;
        integer timeout_count;
        begin
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
                $display("FAIL [%0s]: timed out waiting for done", label);
                errors = errors + 1;
            end else if (score !== expected) begin
                $display("FAIL [%0s]: expected=%0d got=%0d", label, expected, score);
                errors = errors + 1;
            end else begin
                $display("PASS [%0s]: score=%0d", label, score);
            end
        end
    endtask

    initial begin
        errors = 0;
        rst_n = 1'b0;
        start = 1'b0;
        task_vec_flat = {VECTOR_DIM*DATA_WIDTH{1'b0}};
        obj_vec_flat  = {VECTOR_DIM*DATA_WIDTH{1'b0}};

        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        // --- Case 1: original single-dim positive*positive case (regression) ---
        task_vec_flat = {VECTOR_DIM*DATA_WIDTH{1'b0}};
        obj_vec_flat  = {VECTOR_DIM*DATA_WIDTH{1'b0}};
        task_vec_flat[0*DATA_WIDTH +: DATA_WIDTH] = Q15_ONE;
        obj_vec_flat[0*DATA_WIDTH +: DATA_WIDTH]  = Q15_ONE;
        run_and_check(40'sd1073676289, "single_dim_pos_pos");

        // --- Case 2: all-zero vectors -> score must be exactly 0 ---
        task_vec_flat = {VECTOR_DIM*DATA_WIDTH{1'b0}};
        obj_vec_flat  = {VECTOR_DIM*DATA_WIDTH{1'b0}};
        run_and_check(40'sd0, "all_zero_vectors");

        // --- Case 3: full 8-dim vector, all dims = small known value (10*10*8=800) ---
        for (i = 0; i < VECTOR_DIM; i = i + 1) begin
            task_vec_flat[i*DATA_WIDTH +: DATA_WIDTH] = 16'sd10;
            obj_vec_flat[i*DATA_WIDTH +: DATA_WIDTH]  = 16'sd10;
        end
        run_and_check(40'sd800, "full_vector_all_dims");

        // --- Case 4: negative*negative -> positive product (object opposite-signed but still similar) ---
        for (i = 0; i < VECTOR_DIM; i = i + 1) begin
            task_vec_flat[i*DATA_WIDTH +: DATA_WIDTH] = -16'sd10;
            obj_vec_flat[i*DATA_WIDTH +: DATA_WIDTH]  = -16'sd10;
        end
        run_and_check(40'sd800, "negative_times_negative");

        // --- Case 5: mixed sign -> negative score (dissimilar/opposed object) ---
        for (i = 0; i < VECTOR_DIM; i = i + 1) begin
            task_vec_flat[i*DATA_WIDTH +: DATA_WIDTH] = 16'sd10;
            obj_vec_flat[i*DATA_WIDTH +: DATA_WIDTH]  = -16'sd10;
        end
        run_and_check(-40'sd800, "mixed_sign_negative_score");

        // --- Case 6: max-magnitude stress (Q15_MIN * Q15_MIN across all 8 dims) ---
        // Checks no overflow/wraparound given ACC_WIDTH headroom.
        for (i = 0; i < VECTOR_DIM; i = i + 1) begin
            task_vec_flat[i*DATA_WIDTH +: DATA_WIDTH] = Q15_MIN;
            obj_vec_flat[i*DATA_WIDTH +: DATA_WIDTH]  = Q15_MIN;
        end
        // Expected: 8 * (32768*32768) = 8 * 1073741824 = 8589934592
        run_and_check(40'sd8589934592, "max_magnitude_no_overflow");

        // --- Case 7: back-to-back operation with no reset between, different vectors ---
        // Confirms idx/acc properly re-init on second start without an intervening reset.
        task_vec_flat = {VECTOR_DIM*DATA_WIDTH{1'b0}};
        obj_vec_flat  = {VECTOR_DIM*DATA_WIDTH{1'b0}};
        task_vec_flat[0*DATA_WIDTH +: DATA_WIDTH] = 16'sd5;
        obj_vec_flat[0*DATA_WIDTH +: DATA_WIDTH]  = 16'sd5;
        run_and_check(40'sd25, "back_to_back_op1");

        task_vec_flat[1*DATA_WIDTH +: DATA_WIDTH] = 16'sd7;
        obj_vec_flat[1*DATA_WIDTH +: DATA_WIDTH]  = 16'sd7;
        run_and_check(40'sd74, "back_to_back_op2"); // 25 + 49

        // --- Case 8: spurious start asserted while busy must be ignored ---
        task_vec_flat = {VECTOR_DIM*DATA_WIDTH{1'b0}};
        obj_vec_flat  = {VECTOR_DIM*DATA_WIDTH{1'b0}};
        for (i = 0; i < VECTOR_DIM; i = i + 1) begin
            task_vec_flat[i*DATA_WIDTH +: DATA_WIDTH] = 16'sd2;
            obj_vec_flat[i*DATA_WIDTH +: DATA_WIDTH]  = 16'sd2;
        end
        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        // fire a second start pulse while busy -- should be ignored, not restart the counter
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;
        begin : spurious_wait
            integer t;
            t = 0;
            while (!done && t < 50) begin
                @(posedge clk);
                t = t + 1;
            end
            if (!done) begin
                $display("FAIL [spurious_start_while_busy]: timed out");
                errors = errors + 1;
            end else if (score !== 40'sd32) begin
                $display("FAIL [spurious_start_while_busy]: expected=32 got=%0d", score);
                errors = errors + 1;
            end else begin
                $display("PASS [spurious_start_while_busy]: score=%0d", score);
            end
        end

        if (errors == 0) begin
            $display("ALL PASS: similarity_mac");
        end else begin
            $display("%0d CHECK(S) FAILED", errors);
        end
        $finish;
    end

endmodule