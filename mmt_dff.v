module mmt_dff 
    #( parameter DrvStr    = 2,
       parameter AsyncReset = 1,
       parameter AsyncSet   = 0,
       parameter Scannable  = 1 )
    ( input                     clk,
      input                     rstn,
      input                     d,
      output                    q
    );

`ifdef RTL_LIB_SIM
reg    q_reg;
assign q = q_reg;

 generate
    if(AsyncReset == 1 & AsyncSet == 0) begin:dffrstn
        always@(posedge clk or negedge rstn)
        begin
            if(rstn == 1'b0)begin
                 q_reg <= 1'b0;
            end
            else begin
                 q_reg <= d;   
            end
        end
    end
    else if (AsyncReset == 0 & AsyncSet == 1) begin:dffsetn
        always@(posedge clk or negedge rstn)
        begin
            if(rstn == 1'b0)begin
                 q_reg <= 1'b1;
            end
            else begin
                 q_reg <= d;   
            end
        end
    end
 //   else
 //       $display("Error: Parameter AsyncReset AsyncSet set incorrectly");
 endgenerate

`endif

endmodule

 