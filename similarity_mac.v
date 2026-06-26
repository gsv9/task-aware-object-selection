`timescale 1ns/1ps

module similarity_mac #(
    parameter VECTOR_DIM = 8,
    parameter DATA_WIDTH = 16,
    parameter ACC_WIDTH  = 40
)(
    input  wire clk,
    input  wire rst_n,
    input  wire start,

    input  wire signed [VECTOR_DIM*DATA_WIDTH-1:0] task_vec_flat,
    input  wire signed [VECTOR_DIM*DATA_WIDTH-1:0] obj_vec_flat,

    output reg  busy,
    output reg  done,
    output reg  signed [ACC_WIDTH-1:0] score
);

    localparam IDX_WIDTH = (VECTOR_DIM <= 2) ? 1 : $clog2(VECTOR_DIM);

    reg [IDX_WIDTH-1:0] idx;
    reg signed [ACC_WIDTH-1:0] acc;

    wire signed [DATA_WIDTH-1:0] task_val;
    wire signed [DATA_WIDTH-1:0] obj_val;
    wire signed [2*DATA_WIDTH-1:0] product;

    assign task_val = task_vec_flat[idx*DATA_WIDTH +: DATA_WIDTH];
    assign obj_val  = obj_vec_flat[idx*DATA_WIDTH +: DATA_WIDTH];
    assign product  = task_val * obj_val;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            idx   <= {IDX_WIDTH{1'b0}};
            acc   <= {ACC_WIDTH{1'b0}};
            score <= {ACC_WIDTH{1'b0}};
            busy  <= 1'b0;
            done  <= 1'b0;
        end else begin
            done <= 1'b0;

            if (start && !busy) begin
                idx  <= {IDX_WIDTH{1'b0}};
                acc  <= {ACC_WIDTH{1'b0}};
                busy <= 1'b1;
            end else if (busy) begin
                acc <= acc + {{(ACC_WIDTH-(2*DATA_WIDTH)){product[2*DATA_WIDTH-1]}}, product};

                if (idx == VECTOR_DIM-1) begin
                    score <= acc + {{(ACC_WIDTH-(2*DATA_WIDTH)){product[2*DATA_WIDTH-1]}}, product};
                    busy  <= 1'b0;
                    done  <= 1'b1;
                end else begin
                    idx <= idx + 1'b1;
                end
            end
        end
    end

endmodule
