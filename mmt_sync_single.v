module mmt_sync_single
    #( parameter Depth = 3,
       parameter Scannable = 1,
       parameter AsyncReset = 1,
       parameter AsyncSet = 0,
       parameter TransportCycle =2)
    ( input                 clk,
      input                 rstn,
      input                 in,
      output                out
     );

wire [Depth  : 0] dff_con;
assign out = dff_con[Depth];

  // Step 1: Determine the base source for dff_con[0] if INJECT_X was NOT active.
  // This source depends on whether INJECT_DELAY is active.
  wire dff_con0_base_source;
  wire dff_con0_normal_source = in; // Input 'in'

  `ifdef INJECT_DELAY
    reg fault_delay_reg_sync1;
    assign dff_con0_base_source = fault_delay_reg_sync1;

    // Logic for the fault injection flip-flop (fault_delay_reg_sync1)
    generate
      if (AsyncReset == 1 && AsyncSet == 0) begin : fault_ff_rst_logic
        always @(posedge clk or negedge rstn) begin
          if (rstn == 1'b0)
            fault_delay_reg_sync1 <= 1'b0;
          else
            fault_delay_reg_sync1 <= in;
        end
      end else if (AsyncReset == 0 && AsyncSet == 1) begin : fault_ff_set_logic
        always @(posedge clk or negedge rstn) begin
          if (rstn == 1'b0)
            fault_delay_reg_sync1 <= 1'b1;
          else
            fault_delay_reg_sync1 <= in;
        end
      end else begin : fault_ff_sync_logic // Fallback to synchronous
        always @(posedge clk) begin
          fault_delay_reg_sync1 <= in;
        end
      end
    endgenerate
  `else // INJECT_DELAY is not defined
    assign dff_con0_base_source = dff_con0_normal_source; // i.e., 'in'
  `endif // INJECT_DELAY

  // Step 2: Implement INJECT_X logic to make dff_con[0] become 'X' for one cycle.
  `ifdef INJECT_X
    reg is_first_cycle_after_reset_flag; // Register to indicate the first active cycle post-reset

    // Logic for is_first_cycle_after_reset_flag:
    // It's set during reset, and cleared after being high for one cycle when rstn is high.
    always @(posedge clk or negedge rstn) begin
      if (rstn == 1'b0) begin
        is_first_cycle_after_reset_flag <= 1'b1;
      end else begin // rstn == 1'b1
        // If the flag was set (meaning this is the first cycle rstn is high at a posedge clk),
        // clear it for the next cycle. Otherwise, it stays cleared.
        if (is_first_cycle_after_reset_flag) begin
          is_first_cycle_after_reset_flag <= 1'b0;
        end
      end
    end

    // Determine the reset value for dff_con[0] based on module parameters
    wire dff_con0_reset_val;
    assign dff_con0_reset_val = (AsyncReset == 1 && AsyncSet == 0) ? 1'b0 :
                                (AsyncReset == 0 && AsyncSet == 1) ? 1'b1 :
                                1'b0; // Default reset value if params are (0,0) or (1,1)

    // Combinational assignment for dff_con[0]
    // is_first_cycle_after_reset_flag uses its current registered value.
    // This means dff_con[0] becomes 'X' for the duration of the first cycle after reset.
    assign dff_con[0] = (~rstn) ? dff_con0_reset_val : // If in reset, assign reset value
                        (is_first_cycle_after_reset_flag) ? 1'bx : // If first cycle after reset, dff_con[0] is 'X'
                        dff_con0_base_source;       // Otherwise, normal or delayed input
  `else // INJECT_X is not defined (but still within the implicit RTL_LIB_SIM context if we remove the outer ifdef)
    // If INJECT_X is not defined, dff_con[0] is simply the base source (normal or delayed input)
    // Its value during reset also needs to be defined.
    wire dff_con0_reset_val_no_inject;
     assign dff_con0_reset_val_no_inject = (AsyncReset == 1 && AsyncSet == 0) ? 1'b0 :
                                             (AsyncReset == 0 && AsyncSet == 1) ? 1'b1 :
                                             1'b0; // Default reset value

    assign dff_con[0] = (~rstn) ? dff_con0_reset_val_no_inject : dff_con0_base_source;
  `endif // INJECT_X

  // Step 3: Original synchronizer chain using mmt_dff instances
  // This generate block should remain as per the original mmt_dff.v or similar.
  genvar gv_i;
  generate
    for(gv_i=0; gv_i<Depth; gv_i=gv_i+1)
	  begin:syncblk
	       mmt_dff #(.AsyncReset(AsyncReset),.AsyncSet(AsyncSet)) d0nt_mmt_dff (
               .clk(clk),
               .rstn(rstn),
               .d(dff_con[gv_i]),
               .q(dff_con[gv_i+1])
           );
	  end
  endgenerate

endmodule
