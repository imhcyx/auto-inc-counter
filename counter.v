`timescale 1ns / 1ns

module scalar_sync #(parameter STAGES = 2)(
    input clk_dst,
    input src,
    output dst
);
    reg [STAGES-1:0] shift;
    always @(posedge clk_dst) begin
        shift <= {shift[STAGES-2:0], src};
    end
    assign dst = shift[STAGES-1];
endmodule

module counter_64(
    input           cnt_clk,
    input           cnt_rst,
    output  [63:0]  cnt,
    input           aclk,
    input           aresetn,
    input           arvalid,
    output          arready,
    input   [11:0]  araddr,
    input   [2 :0]  arprot,
    output          rvalid,
    input           rready,
    output  [1 :0]  rresp,
    output  [63:0]  rdata,
    input           awvalid,
    output          awready,
    input   [11:0]  awaddr,
    input   [2 :0]  awprot,
    input           wvalid,
    output          wready,
    input   [63:0]  wdata,
    input   [7 :0]  wstrb,
    output          bvalid,
    input           bready,
    output  [1 :0]  bresp
);

    reg [63:0] cnt_r;

    always @(posedge cnt_clk) begin
        if (cnt_rst) cnt_r <= 64'd0;
        else cnt_r <= cnt_r + 64'd1;
    end

    assign cnt = cnt_r;

    // axi stuff

    wire ar_fire = arvalid && arready;
    wire r_fire = rvalid && rready;
    wire aw_fire = awvalid && awready;
    wire w_fire = wvalid && wready;
    wire b_fire = bvalid && bready;

    reg r_inflight, w_inflight;

    always @(posedge aclk) begin
        if (!aresetn) r_inflight <= 1'b0;
        else r_inflight <= r_inflight ^ ar_fire ^ r_fire;
    end

    always @(posedge aclk) begin
        if (!aresetn) w_inflight <= 1'b0;
        else w_inflight <= w_inflight ^ aw_fire ^ b_fire;
    end

    assign arready = !r_inflight;
    assign awready = !w_inflight;

    // read over axi

    // clock domains: aclk(A) cnt_clk(C)

    reg data_req, data_ack; // A, C
    reg [63:0] data_a, data_c; // A, C
    wire data_req_c, data_ack_a;

    scalar_sync u_req_sync(.clk_dst(cnt_clk),   .src(data_req),     .dst(data_req_c));
    scalar_sync u_ack_sync(.clk_dst(aclk),      .src(data_ack),     .dst(data_ack_a));

    always @(posedge aclk) begin
        if (!aresetn)                       data_req <= 1'b0;
        else if (data_ack_a)                data_req <= 1'b0;
        else if (ar_fire)                   data_req <= 1'b1;
    end

    always @(posedge cnt_clk) begin
        if (cnt_rst)                        data_c <= 64'd0;
        else if (data_req_c && !data_ack)   data_c <= cnt_r;
    end

    always @(posedge cnt_clk) begin
        if (cnt_rst)                        data_ack <= 1'b0;
        else                                data_ack <= data_req_c;
    end

    always @(posedge aclk) begin
        if (!aresetn)                       data_a <= 64'd0;
        else if (data_ack_a && data_req)    data_a <= data_c;
    end

    reg [1:0] data_ack_a_scan;
    always @(posedge aclk) begin
        data_ack_a_scan <= {data_ack_a_scan[0], data_ack_a};
    end

    reg rvalid_r;
    always @(posedge aclk) begin
        if (!aresetn)                       rvalid_r <= 1'b0;
        else if (r_fire)                    rvalid_r <= 1'b0;
        else if (data_ack_a_scan == 2'b10)  rvalid_r <= 1'b1;
    end

    assign rvalid = rvalid_r;
    assign rdata = data_a;
    assign rresp = 2'd0;

    // ignore writes

    assign wready = 1'b1;
    assign bvalid = w_inflight;
    assign bresp = 2'd0;

endmodule
