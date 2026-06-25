`timescale 1ns/1ps

module tb_task_accelerator_top;

    localparam MAX_OBJECTS = 4;
    localparam VECTOR_DIM  = 8;
    localparam DATA_WIDTH  = 16;
    localparam ACC_WIDTH   = 40;
    localparam signed [DATA_WIDTH-1:0] Q15_ONE = 16'sd32767;
    localparam signed [DATA_WIDTH-1:0] Q15_HALF = 16'sd16384;

    reg clk;
    reg rst_n;
    reg start;
    reg [3:0] num_objects;
    reg signed [VECTOR_DIM*DATA_WIDTH-1:0] task_vec_flat;
    reg signed [MAX_OBJECTS*VECTOR_DIM*DATA_WIDTH-1:0] object_vecs_flat;
    reg signed [MAX_OBJECTS*DATA_WIDTH-1:0] confidence_flat;
    reg signed [MAX_OBJECTS*DATA_WIDTH-1:0] spatial_flat;

    wire busy;
    wire done;
    wire [3:0] best_index;
    wire signed [ACC_WIDTH-1:0] best_score;
    wire [31:0] cycle_count;

    integer timeout_count;

    task_accelerator_top #(
        .MAX_OBJECTS(MAX_OBJECTS),
        .VECTOR_DIM(VECTOR_DIM),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) dut (
        .clk(clk),
        .rst_n(rst_n),
        .start(start),
        .num_objects(num_objects),
        .task_vec_flat(task_vec_flat),
        .object_vecs_flat(object_vecs_flat),
        .confidence_flat(confidence_flat),
        .spatial_flat(spatial_flat),
        .busy(busy),
        .done(done),
        .best_index(best_index),
        .best_score(best_score),
        .cycle_count(cycle_count)
    );

    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    task set_task;
        input integer dim;
        input signed [DATA_WIDTH-1:0] value;
        begin
            task_vec_flat[dim*DATA_WIDTH +: DATA_WIDTH] = value;
        end
    endtask

    task set_object;
        input integer obj;
        input integer dim;
        input signed [DATA_WIDTH-1:0] value;
        begin
            object_vecs_flat[(obj*VECTOR_DIM + dim)*DATA_WIDTH +: DATA_WIDTH] = value;
        end
    endtask

    task set_confidence;
        input integer obj;
        input signed [DATA_WIDTH-1:0] value;
        begin
            confidence_flat[obj*DATA_WIDTH +: DATA_WIDTH] = value;
        end
    endtask

    task set_spatial;
        input integer obj;
        input signed [DATA_WIDTH-1:0] value;
        begin
            spatial_flat[obj*DATA_WIDTH +: DATA_WIDTH] = value;
        end
    endtask

    initial begin
        rst_n = 1'b0;
        start = 1'b0;
        num_objects = 4'd4;
        task_vec_flat = {VECTOR_DIM*DATA_WIDTH{1'b0}};
        object_vecs_flat = {MAX_OBJECTS*VECTOR_DIM*DATA_WIDTH{1'b0}};
        confidence_flat = {MAX_OBJECTS*DATA_WIDTH{1'b0}};
        spatial_flat = {MAX_OBJECTS*DATA_WIDTH{1'b0}};

        repeat (4) @(posedge clk);
        rst_n = 1'b1;

        set_task(0, Q15_ONE);

        set_object(0, 1, Q15_ONE);
        set_object(1, 0, Q15_ONE);
        set_object(2, 2, Q15_ONE);
        set_object(3, 3, Q15_ONE);

        set_confidence(0, Q15_HALF);
        set_confidence(1, Q15_HALF);
        set_confidence(2, Q15_HALF);
        set_confidence(3, Q15_HALF);

        set_spatial(0, Q15_HALF);
        set_spatial(1, Q15_HALF);
        set_spatial(2, Q15_HALF);
        set_spatial(3, Q15_HALF);

        @(posedge clk);
        start = 1'b1;
        @(posedge clk);
        start = 1'b0;

        timeout_count = 0;
        while (!done && timeout_count < 200) begin
            @(posedge clk);
            timeout_count = timeout_count + 1;
        end

        if (!done) begin
            $display("FAIL: task_accelerator_top timed out");
            $finish;
        end

        if (best_index !== 4'd1) begin
            $display("FAIL: expected best_index=1 got=%0d best_score=%0d cycles=%0d", best_index, best_score, cycle_count);
            $finish;
        end

        $display("PASS: task_accelerator_top best_index=%0d best_score=%0d cycles=%0d", best_index, best_score, cycle_count);
        $finish;
    end

endmodule
