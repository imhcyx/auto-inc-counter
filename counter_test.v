`timescale 1ns / 1ns

module counter_test();

    reg cnt_clk, aclk;

    always #5 cnt_clk = ~cnt_clk;
    always #6 aclk = ~aclk;

    reg cnt_resetn, aresetn;
    reg arvalid, rready;
    wire arready, rvalid;
    wire [63:0] cnt, rdata;

    counter_64 u_cnt(
        .cnt_clk(cnt_clk),
        .cnt_resetn(cnt_resetn),
        .cnt(cnt),
        .s_axi_aclk(aclk),
        .s_axi_aresetn(aresetn),
        .s_axi_arvalid(arvalid),
        .s_axi_arready(arready),
        .s_axi_araddr(12'd0),
        .s_axi_arprot(3'd0),
        .s_axi_rvalid(rvalid),
        .s_axi_rready(rready),
        .s_axi_rresp(),
        .s_axi_rdata(rdata),
        .s_axi_awvalid(1'b0),
        .s_axi_awready(),
        .s_axi_awaddr(12'd0),
        .s_axi_awprot(3'd0),
        .s_axi_wvalid(1'b0),
        .s_axi_wready(),
        .s_axi_wdata(64'd0),
        .s_axi_wstrb(8'd0),
        .s_axi_bvalid(),
        .s_axi_bready(1'b0),
        .s_axi_bresp()
    );

    integer i;

    initial begin
        cnt_clk = 1'b0;
        aclk = 1'b0;
        cnt_resetn = 1'b0;
        aresetn = 1'b0;
        arvalid = 1'b0;
        rready = 1'b0;
        #100;
        cnt_resetn = 1'b1;
        aresetn = 1'b1;
        #200;
        for (i=0; i<10; i=i+1) begin
            arvalid = 1'b1;
            @(posedge aclk); while (!arready) @(posedge aclk);
            arvalid = 1'b0;
            rready = 1'b1;
            @(posedge aclk); while (!rvalid) @(posedge aclk);
            rready = 1'b0;
            $display("counter value: %d", rdata);
            #100;
        end
        $finish;
    end

    initial begin
        $dumpfile("dump.vcd");
        $dumpvars();
    end

endmodule
