`timescale 1ns / 1ns

module counter_test();

    reg cnt_clk, aclk;

    always #5 cnt_clk = ~cnt_clk;
    always #6 aclk = ~aclk;

    reg cnt_rst, aresetn;
    reg arvalid, rready;
    wire arready, rvalid;
    wire [63:0] cnt, rdata;

    counter_64 u_cnt(
        .cnt_clk(cnt_clk),
        .cnt_rst(cnt_rst),
        .cnt(cnt),
        .aclk(aclk),
        .aresetn(aresetn),
        .arvalid(arvalid),
        .arready(arready),
        .araddr(12'd0),
        .arprot(3'd0),
        .rvalid(rvalid),
        .rready(rready),
        .rresp(),
        .rdata(rdata),
        .awvalid(1'b0),
        .awready(),
        .awaddr(12'd0),
        .awprot(3'd0),
        .wvalid(1'b0),
        .wready(),
        .wdata(64'd0),
        .wstrb(8'd0),
        .bvalid(),
        .bready(1'b0),
        .bresp()
    );

    integer i;

    initial begin
        cnt_clk = 1'b0;
        aclk = 1'b0;
        cnt_rst = 1'b1;
        aresetn = 1'b0;
        arvalid = 1'b0;
        rready = 1'b0;
        #100;
        cnt_rst = 1'b0;
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
