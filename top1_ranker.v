`timescale 1ns/1ps

module top1_ranker #(
    parameter MAX_OBJECTS = 4,
    parameter SCORE_WIDTH = 40
)(
    input  wire clk,
    input  wire rst_n,
    input  wire clear,
    input  wire valid,
    input  wire [3:0] object_index,
    input  wire signed [SCORE_WIDTH-1:0] object_score,

    output reg  [3:0] best_index,
    output reg  signed [SCORE_WIDTH-1:0] best_score
);

    localparam signed [SCORE_WIDTH-1:0] MIN_SCORE = {1'b1, {(SCORE_WIDTH-1){1'b0}}};

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            best_index <= 4'd0;
            best_score <= MIN_SCORE;
        end else if (clear) begin
            best_index <= 4'd0;
            best_score <= MIN_SCORE;
        end else if (valid) begin
            if (object_score > best_score) begin
                best_index <= object_index;
                best_score <= object_score;
            end
        end
    end

endmodule
