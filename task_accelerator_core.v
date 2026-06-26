`timescale 1ns/1ps

module task_accelerator_core #(
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

    output reg  busy,
    output reg  done,
    output reg  [3:0] best_index,
    output reg  signed [ACC_WIDTH-1:0] best_score,
    output reg  [31:0] cycle_count
);

    localparam ST_IDLE         = 3'd0;
    localparam ST_START_OBJECT = 3'd1;
    localparam ST_WAIT_MAC     = 3'd2;
    localparam ST_UPDATE_RANK  = 3'd3;
    localparam ST_NEXT_OBJECT  = 3'd4;
    localparam ST_DONE         = 3'd5;

    reg [2:0] state;
    reg [3:0] current_object;

    reg mac_start;
    wire mac_busy;
    wire mac_done;
    wire signed [ACC_WIDTH-1:0] semantic_score;

    reg ranker_clear;
    reg ranker_valid;
    wire [3:0] ranker_best_index;
    wire signed [ACC_WIDTH-1:0] ranker_best_score;

    wire signed [VECTOR_DIM*DATA_WIDTH-1:0] current_obj_vec_flat;
    wire signed [DATA_WIDTH-1:0] current_confidence;
    wire signed [DATA_WIDTH-1:0] current_spatial;
    wire signed [ACC_WIDTH-1:0] fused_score;

    assign current_obj_vec_flat =
        object_vecs_flat[current_object*VECTOR_DIM*DATA_WIDTH +: VECTOR_DIM*DATA_WIDTH];

    assign current_confidence =
        confidence_flat[current_object*DATA_WIDTH +: DATA_WIDTH];

    assign current_spatial =
        spatial_flat[current_object*DATA_WIDTH +: DATA_WIDTH];

    similarity_mac #(
        .VECTOR_DIM(VECTOR_DIM),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) u_similarity_mac (
        .clk(clk),
        .rst_n(rst_n),
        .start(mac_start),
        .task_vec_flat(task_vec_flat),
        .obj_vec_flat(current_obj_vec_flat),
        .busy(mac_busy),
        .done(mac_done),
        .score(semantic_score)
    );

    score_fusion #(
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) u_score_fusion (
        .semantic_score(semantic_score),
        .spatial_score(current_spatial),
        .confidence_score(current_confidence),
        .final_score(fused_score)
    );

    top1_ranker #(
        .MAX_OBJECTS(MAX_OBJECTS),
        .SCORE_WIDTH(ACC_WIDTH)
    ) u_top1_ranker (
        .clk(clk),
        .rst_n(rst_n),
        .clear(ranker_clear),
        .valid(ranker_valid),
        .object_index(current_object),
        .object_score(fused_score),
        .best_index(ranker_best_index),
        .best_score(ranker_best_score)
    );

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state          <= ST_IDLE;
            current_object <= 4'd0;
            mac_start      <= 1'b0;
            ranker_clear   <= 1'b0;
            ranker_valid   <= 1'b0;
            busy           <= 1'b0;
            done           <= 1'b0;
            best_index     <= 4'd0;
            best_score     <= {ACC_WIDTH{1'b0}};
            cycle_count    <= 32'd0;
        end else begin
            mac_start    <= 1'b0;
            ranker_clear <= 1'b0;
            ranker_valid <= 1'b0;

            if (busy) begin
                cycle_count <= cycle_count + 1'b1;
            end

            case (state)
                ST_IDLE: begin
                    busy <= 1'b0;
                    done <= 1'b0;

                    if (start) begin
                        current_object <= 4'd0;
                        cycle_count    <= 32'd0;
                        ranker_clear   <= 1'b1;
                        busy           <= 1'b1;

                        if (num_objects == 4'd0) begin
                            state <= ST_DONE;
                        end else begin
                            state <= ST_START_OBJECT;
                        end
                    end
                end

                ST_START_OBJECT: begin
                    mac_start <= 1'b1;
                    state     <= ST_WAIT_MAC;
                end

                ST_WAIT_MAC: begin
                    if (mac_done) begin
                        state <= ST_UPDATE_RANK;
                    end
                end

                ST_UPDATE_RANK: begin
                    ranker_valid <= 1'b1;
                    state        <= ST_NEXT_OBJECT;
                end

                ST_NEXT_OBJECT: begin
                    if ((current_object + 1'b1) >= num_objects) begin
                        state <= ST_DONE;
                    end else begin
                        current_object <= current_object + 1'b1;
                        state          <= ST_START_OBJECT;
                    end
                end

                ST_DONE: begin
                    busy       <= 1'b0;
                    done       <= 1'b1;
                    best_index <= ranker_best_index;
                    best_score <= ranker_best_score;

                    if (!start) begin
                        state <= ST_IDLE;
                    end
                end

                default: begin
                    state <= ST_IDLE;
                end
            endcase
        end
    end

endmodule
