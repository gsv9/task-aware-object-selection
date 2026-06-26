`timescale 1ns/1ps

// score_fusion: combines semantic, spatial, and confidence scores into a
// single fused score using Q1.15 fixed-point weights.
//
// final_score = ALPHA*semantic_score + BETA*spatial_score + GAMMA*confidence_score
//
// Weight values preserve the README's 97:3:5 emphasis on
// task_score : spatial_score : confidence_score, but renormalized so the
// three sum to exactly 1.0 (the README's raw 0.97/0.03/0.05 sums to 1.05,
// which is a bug in its own right -- a weighted "average" whose weights
// don't sum to 1 isn't an average, it's an unintentional 5% gain).
//   ALPHA = 30272/32768 = 0.923828125  (~0.9238, ratio-preserved from 0.97)
//   BETA  =   936/32768 = 0.028564453  (~0.0286, ratio-preserved from 0.03)
//   GAMMA =  1560/32768 = 0.047607422  (~0.0476, ratio-preserved from 0.05)
// ALPHA is computed as the remainder (32768 - BETA_Q15 - GAMMA_Q15) rather
// than its own independent rounding, so the three coefficients sum to
// EXACTLY 32768 (unity gain in Q1.15) with zero systematic drift.
// If the software-side weights change, regenerate all three together using
// the same remainder method -- don't just round each independently.
//
// Fixed-point convention: semantic_score, spatial_score, confidence_score
// are all treated as plain integers (not pre-scaled). Each is multiplied by
// a Q1.15 coefficient, the three Q1.15-scaled partial products are summed,
// and the sum is right-shifted by 15 exactly once to return to integer
// scale. Do NOT pre-shift spatial/confidence before this multiply - that
// was the source of a 2^15x scaling bug in the previous version.

module score_fusion #(
    parameter DATA_WIDTH = 16,
    parameter ACC_WIDTH  = 40,
    parameter ALPHA_Q15  = 16'sd30272, // 0.923828125 (ratio-preserved 0.97)
    parameter BETA_Q15   = 16'sd936,   // 0.028564453 (ratio-preserved 0.03)
    parameter GAMMA_Q15  = 16'sd1560   // 0.047607422 (ratio-preserved 0.05)
)(
    input  wire signed [ACC_WIDTH-1:0]  semantic_score,
    input  wire signed [DATA_WIDTH-1:0] spatial_score,
    input  wire signed [DATA_WIDTH-1:0] confidence_score,
    output wire signed [ACC_WIDTH-1:0]  final_score
);

    // Sign-extend spatial/confidence straight to ACC_WIDTH. No pre-shift -
    // the Q15 multiply below is the only scaling applied to these terms,
    // same as semantic_score gets.
    wire signed [ACC_WIDTH-1:0] spatial_aligned;
    wire signed [ACC_WIDTH-1:0] confidence_aligned;

    wire signed [ACC_WIDTH+DATA_WIDTH-1:0] weighted_semantic;
    wire signed [ACC_WIDTH+DATA_WIDTH-1:0] weighted_spatial;
    wire signed [ACC_WIDTH+DATA_WIDTH-1:0] weighted_confidence;
    wire signed [ACC_WIDTH+DATA_WIDTH+1:0] weighted_sum;

    assign spatial_aligned    = {{(ACC_WIDTH-DATA_WIDTH){spatial_score[DATA_WIDTH-1]}}, spatial_score};
    assign confidence_aligned = {{(ACC_WIDTH-DATA_WIDTH){confidence_score[DATA_WIDTH-1]}}, confidence_score};

    assign weighted_semantic   = semantic_score      * ALPHA_Q15;
    assign weighted_spatial    = spatial_aligned     * BETA_Q15;
    assign weighted_confidence = confidence_aligned  * GAMMA_Q15;

    assign weighted_sum = weighted_semantic + weighted_spatial + weighted_confidence;
    assign final_score  = weighted_sum >>> 15;

endmodule