`timescale 1ns/1ps

module score_fusion #(
    parameter DATA_WIDTH = 16,
    parameter ACC_WIDTH  = 40,
    parameter ALPHA_Q15  = 16'sd22938, // 0.70 in Q1.15
    parameter BETA_Q15   = 16'sd6554,  // 0.20 in Q1.15
    parameter GAMMA_Q15  = 16'sd3277   // 0.10 in Q1.15
)(
    input  wire signed [ACC_WIDTH-1:0]  semantic_score,
    input  wire signed [DATA_WIDTH-1:0] spatial_score,
    input  wire signed [DATA_WIDTH-1:0] confidence_score,
    output wire signed [ACC_WIDTH-1:0]  final_score
);

    wire signed [ACC_WIDTH-1:0] spatial_aligned;
    wire signed [ACC_WIDTH-1:0] confidence_aligned;

    wire signed [ACC_WIDTH+DATA_WIDTH-1:0] weighted_semantic;
    wire signed [ACC_WIDTH+DATA_WIDTH-1:0] weighted_spatial;
    wire signed [ACC_WIDTH+DATA_WIDTH-1:0] weighted_confidence;
    wire signed [ACC_WIDTH+DATA_WIDTH+1:0] weighted_sum;

    assign spatial_aligned = {{(ACC_WIDTH-DATA_WIDTH-15){spatial_score[DATA_WIDTH-1]}}, spatial_score, 15'b0};
    assign confidence_aligned = {{(ACC_WIDTH-DATA_WIDTH-15){confidence_score[DATA_WIDTH-1]}}, confidence_score, 15'b0};

    assign weighted_semantic   = semantic_score      * ALPHA_Q15;
    assign weighted_spatial    = spatial_aligned     * BETA_Q15;
    assign weighted_confidence = confidence_aligned  * GAMMA_Q15;

    assign weighted_sum = weighted_semantic + weighted_spatial + weighted_confidence;
    assign final_score  = weighted_sum >>> 15;

endmodule
