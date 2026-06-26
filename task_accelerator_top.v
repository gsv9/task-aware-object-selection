`timescale 1ns/1ps

module task_accelerator_top #(
    parameter MAX_OBJECTS = 4,
    parameter VECTOR_DIM  = 8,
    parameter DATA_WIDTH  = 16,
    parameter ACC_WIDTH   = 40
)(
    input  wire clk,
    input  wire rst_n,
    input  wire start,
    input  wire [3:0] num_objects,

    input  wire signed [VECTOR_DIM*DATA_WIDTH-1:0] task_vec_flat,
    input  wire signed [MAX_OBJECTS*VECTOR_DIM*DATA_WIDTH-1:0] object_vecs_flat,
    input  wire signed [MAX_OBJECTS*DATA_WIDTH-1:0] confidence_flat,
    input  wire signed [MAX_OBJECTS*DATA_WIDTH-1:0] spatial_flat,

    output wire busy,
    output wire done,
    output wire [3:0] best_index,
    output wire signed [ACC_WIDTH-1:0] best_score,
    output wire [31:0] cycle_count
);

    task_accelerator_core #(
        .MAX_OBJECTS(MAX_OBJECTS),
        .VECTOR_DIM(VECTOR_DIM),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) u_task_accelerator_core (
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

endmodule
