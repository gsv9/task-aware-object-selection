`timescale 1ns/1ps

module axi_lite_task_accelerator #(
    parameter MAX_OBJECTS = 4,
    parameter VECTOR_DIM  = 8,
    parameter DATA_WIDTH  = 16,
    parameter ACC_WIDTH   = 40,
    parameter AXI_ADDR_WIDTH = 16,
    parameter AXI_DATA_WIDTH = 32
)(
    input  wire aclk,
    input  wire aresetn,

    input  wire [AXI_ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire s_axi_awvalid,
    output reg  s_axi_awready,

    input  wire [AXI_DATA_WIDTH-1:0] s_axi_wdata,
    input  wire [(AXI_DATA_WIDTH/8)-1:0] s_axi_wstrb,
    input  wire s_axi_wvalid,
    output reg  s_axi_wready,

    output reg  [1:0] s_axi_bresp,
    output reg  s_axi_bvalid,
    input  wire s_axi_bready,

    input  wire [AXI_ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire s_axi_arvalid,
    output reg  s_axi_arready,

    output reg  [AXI_DATA_WIDTH-1:0] s_axi_rdata,
    output reg  [1:0] s_axi_rresp,
    output reg  s_axi_rvalid,
    input  wire s_axi_rready
);

    localparam ADDR_CONTROL    = 16'h0000;
    localparam ADDR_STATUS     = 16'h0004;
    localparam ADDR_NUM_OBJECT = 16'h0008;
    localparam ADDR_BEST_INDEX = 16'h000C;
    localparam ADDR_BEST_LOW   = 16'h0010;
    localparam ADDR_BEST_HIGH  = 16'h0014;
    localparam ADDR_CYCLES     = 16'h0018;

    localparam ADDR_TASK_BASE  = 16'h0100;
    localparam ADDR_OBJ_BASE   = 16'h0300;
    localparam ADDR_CONF_BASE  = 16'h0900;
    localparam ADDR_SPAT_BASE  = 16'h0A00;

    reg start_pulse;
    reg [3:0] num_objects_reg;
    reg [VECTOR_DIM*DATA_WIDTH-1:0] task_vec_flat;
    reg [MAX_OBJECTS*VECTOR_DIM*DATA_WIDTH-1:0] object_vecs_flat;
    reg [MAX_OBJECTS*DATA_WIDTH-1:0] confidence_flat;
    reg [MAX_OBJECTS*DATA_WIDTH-1:0] spatial_flat;

    wire core_busy;
    wire core_done;
    wire [3:0] core_best_index;
    wire signed [ACC_WIDTH-1:0] core_best_score;
    wire [31:0] core_cycle_count;

    integer write_index;
    integer read_index;

    task_accelerator_core #(
        .MAX_OBJECTS(MAX_OBJECTS),
        .VECTOR_DIM(VECTOR_DIM),
        .DATA_WIDTH(DATA_WIDTH),
        .ACC_WIDTH(ACC_WIDTH)
    ) u_task_accelerator_core (
        .clk(aclk),
        .rst_n(aresetn),
        .start(start_pulse),
        .num_objects(num_objects_reg),
        .task_vec_flat(task_vec_flat),
        .object_vecs_flat(object_vecs_flat),
        .confidence_flat(confidence_flat),
        .spatial_flat(spatial_flat),
        .busy(core_busy),
        .done(core_done),
        .best_index(core_best_index),
        .best_score(core_best_score),
        .cycle_count(core_cycle_count)
    );

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            s_axi_bvalid  <= 1'b0;
            start_pulse   <= 1'b0;
            num_objects_reg <= 4'd0;
            task_vec_flat <= {VECTOR_DIM*DATA_WIDTH{1'b0}};
            object_vecs_flat <= {MAX_OBJECTS*VECTOR_DIM*DATA_WIDTH{1'b0}};
            confidence_flat <= {MAX_OBJECTS*DATA_WIDTH{1'b0}};
            spatial_flat <= {MAX_OBJECTS*DATA_WIDTH{1'b0}};
        end else begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            start_pulse   <= 1'b0;

            if (!s_axi_bvalid && s_axi_awvalid && s_axi_wvalid) begin
                s_axi_awready <= 1'b1;
                s_axi_wready  <= 1'b1;
                s_axi_bvalid  <= 1'b1;
                s_axi_bresp   <= 2'b00;

                if (s_axi_awaddr == ADDR_CONTROL) begin
                    start_pulse <= s_axi_wdata[0];
                end else if (s_axi_awaddr == ADDR_NUM_OBJECT) begin
                    num_objects_reg <= s_axi_wdata[3:0];
                end else if (s_axi_awaddr >= ADDR_TASK_BASE &&
                             s_axi_awaddr < ADDR_TASK_BASE + VECTOR_DIM*4) begin
                    write_index = (s_axi_awaddr - ADDR_TASK_BASE) >> 2;
                    task_vec_flat[write_index*DATA_WIDTH +: DATA_WIDTH] <= s_axi_wdata[DATA_WIDTH-1:0];
                end else if (s_axi_awaddr >= ADDR_OBJ_BASE &&
                             s_axi_awaddr < ADDR_OBJ_BASE + MAX_OBJECTS*VECTOR_DIM*4) begin
                    write_index = (s_axi_awaddr - ADDR_OBJ_BASE) >> 2;
                    object_vecs_flat[write_index*DATA_WIDTH +: DATA_WIDTH] <= s_axi_wdata[DATA_WIDTH-1:0];
                end else if (s_axi_awaddr >= ADDR_CONF_BASE &&
                             s_axi_awaddr < ADDR_CONF_BASE + MAX_OBJECTS*4) begin
                    write_index = (s_axi_awaddr - ADDR_CONF_BASE) >> 2;
                    confidence_flat[write_index*DATA_WIDTH +: DATA_WIDTH] <= s_axi_wdata[DATA_WIDTH-1:0];
                end else if (s_axi_awaddr >= ADDR_SPAT_BASE &&
                             s_axi_awaddr < ADDR_SPAT_BASE + MAX_OBJECTS*4) begin
                    write_index = (s_axi_awaddr - ADDR_SPAT_BASE) >> 2;
                    spatial_flat[write_index*DATA_WIDTH +: DATA_WIDTH] <= s_axi_wdata[DATA_WIDTH-1:0];
                end
            end

            if (s_axi_bvalid && s_axi_bready) begin
                s_axi_bvalid <= 1'b0;
            end
        end
    end

    always @(posedge aclk or negedge aresetn) begin
        if (!aresetn) begin
            s_axi_arready <= 1'b0;
            s_axi_rdata   <= {AXI_DATA_WIDTH{1'b0}};
            s_axi_rresp   <= 2'b00;
            s_axi_rvalid  <= 1'b0;
        end else begin
            s_axi_arready <= 1'b0;

            if (!s_axi_rvalid && s_axi_arvalid) begin
                s_axi_arready <= 1'b1;
                s_axi_rvalid  <= 1'b1;
                s_axi_rresp   <= 2'b00;
                s_axi_rdata   <= {AXI_DATA_WIDTH{1'b0}};

                if (s_axi_araddr == ADDR_STATUS) begin
                    s_axi_rdata <= {30'd0, core_busy, core_done};
                end else if (s_axi_araddr == ADDR_NUM_OBJECT) begin
                    s_axi_rdata <= {28'd0, num_objects_reg};
                end else if (s_axi_araddr == ADDR_BEST_INDEX) begin
                    s_axi_rdata <= {28'd0, core_best_index};
                end else if (s_axi_araddr == ADDR_BEST_LOW) begin
                    s_axi_rdata <= core_best_score[31:0];
                end else if (s_axi_araddr == ADDR_BEST_HIGH) begin
                    s_axi_rdata <= {{(AXI_DATA_WIDTH-(ACC_WIDTH-32)){core_best_score[ACC_WIDTH-1]}}, core_best_score[ACC_WIDTH-1:32]};
                end else if (s_axi_araddr == ADDR_CYCLES) begin
                    s_axi_rdata <= core_cycle_count;
                end else if (s_axi_araddr >= ADDR_TASK_BASE &&
                             s_axi_araddr < ADDR_TASK_BASE + VECTOR_DIM*4) begin
                    read_index = (s_axi_araddr - ADDR_TASK_BASE) >> 2;
                    s_axi_rdata <= {{(AXI_DATA_WIDTH-DATA_WIDTH){task_vec_flat[read_index*DATA_WIDTH+DATA_WIDTH-1]}},
                                    task_vec_flat[read_index*DATA_WIDTH +: DATA_WIDTH]};
                end else if (s_axi_araddr >= ADDR_OBJ_BASE &&
                             s_axi_araddr < ADDR_OBJ_BASE + MAX_OBJECTS*VECTOR_DIM*4) begin
                    read_index = (s_axi_araddr - ADDR_OBJ_BASE) >> 2;
                    s_axi_rdata <= {{(AXI_DATA_WIDTH-DATA_WIDTH){object_vecs_flat[read_index*DATA_WIDTH+DATA_WIDTH-1]}},
                                    object_vecs_flat[read_index*DATA_WIDTH +: DATA_WIDTH]};
                end
            end

            if (s_axi_rvalid && s_axi_rready) begin
                s_axi_rvalid <= 1'b0;
            end
        end
    end

endmodule
