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

  // Step 2: Implement INJECT_RANDOM, INJECT_X logic or normal assignment for dff_con[0]

  // Define ANY_INJECTION_ACTIVE if either INJECT_X or INJECT_RANDOM is defined
  `ifdef INJECT_X
    `define ANY_INJECTION_ACTIVE
  `endif
  `ifdef INJECT_RANDOM
    `ifndef ANY_INJECTION_ACTIVE // Define only if not already defined by INJECT_X
      `define ANY_INJECTION_ACTIVE
    `endif
  `endif

  // Common logic for injection: flag for first cycle after reset
  // This is needed if INJECT_X or INJECT_RANDOM targets the first cycle post-reset.
  `ifdef ANY_INJECTION_ACTIVE
    reg is_first_cycle_after_reset_flag; // Register to indicate the first active cycle post-reset

    // Logic for is_first_cycle_after_reset_flag:
    // It's set during reset, and cleared after being high for one cycle when rstn is high.
    always @(posedge clk or negedge rstn) begin
      if (rstn == 1'b0) begin
        is_first_cycle_after_reset_flag <= 1'b1;
      end else begin // rstn == 1'b1
        if (is_first_cycle_after_reset_flag) begin
          is_first_cycle_after_reset_flag <= 1'b0;
        end
      end
    end

    // Determine the reset value for dff_con[0] based on module parameters.
    // This is common for injection scenarios as dff_con[0] still needs a defined reset value.
    wire dff_con0_reset_val;
    assign dff_con0_reset_val = (AsyncReset == 1 && AsyncSet == 0) ? 1'b0 :
                                (AsyncReset == 0 && AsyncSet == 1) ? 1'b1 :
                                1'b0; // Default reset value if params are (0,0) or (1,1)
  `endif // ANY_INJECTION_ACTIVE


  `ifdef INJECT_RANDOM
    // Combinational assignment for dff_con[0] with random injection
    // is_first_cycle_after_reset_flag uses its current registered value.
    // dff_con[0] becomes random (0 or 1) for the duration of the first cycle after reset.
    wire random_val;
    // Using $urandom_range for potentially better random distribution and simulator handling.
    assign random_val = $urandom_range(0, 1); // Generates 0 or 1.
                                        // Note: $urandom_range is a SystemVerilog feature,
                                        // typically for simulation, not synthesis.
                                        // For synthesis, a pseudo-random source (e.g., LFSR)
                                        // or an input port for the random value would be needed.

    assign dff_con[0] = (~rstn) ? dff_con0_reset_val :          // If in reset, assign reset value
                        (is_first_cycle_after_reset_flag) ? random_val : // If first cycle after reset, inject random
                        dff_con0_base_source;                  // Otherwise, normal or delayed input

  `elsif INJECT_X // INJECT_RANDOM is not defined, but INJECT_X is
    // Combinational assignment for dff_con[0] with 'X' injection
    // is_first_cycle_after_reset_flag uses its current registered value.
    // This means dff_con[0] becomes 'X' for the duration of the first cycle after reset.
    assign dff_con[0] = (~rstn) ? dff_con0_reset_val :          // If in reset, assign reset value
                        (is_first_cycle_after_reset_flag) ? 1'bx : // If first cycle after reset, dff_con[0] is 'X'
                        dff_con0_base_source;                  // Otherwise, normal or delayed input

  `else // Neither INJECT_RANDOM nor INJECT_X is defined
    // If no injection is defined, dff_con[0] is simply the base source (normal or delayed input).
    // Its value during reset also needs to be defined.
    wire dff_con0_reset_val_no_inject;
     assign dff_con0_reset_val_no_inject = (AsyncReset == 1 && AsyncSet == 0) ? 1'b0 :
                                             (AsyncReset == 0 && AsyncSet == 1) ? 1'b1 :
                                             1'b0; // Default reset value

    assign dff_con[0] = (~rstn) ? dff_con0_reset_val_no_inject : dff_con0_base_source;
  `endif // INJECT_RANDOM / INJECT_X

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
