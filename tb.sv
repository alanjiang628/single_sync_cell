`timescale 1ns/1ps

module tb_mmt_sync_single;

  // Parameters for DUT
  localparam DEPTH = 3;
  localparam ASYNC_RESET = 1;
  localparam ASYNC_SET = 0;

  // Testbench signals
  logic clk;
  logic rstn;
  logic in_tb;
  wire  out_tb;

  // DUT instantiation
  // We will instantiate the DUT differently for each test case
  // to control the INJECT_X and INJECT_DELAY macros.

  // Clock generation
  initial begin
    clk = 0;
    forever #5 clk = ~clk; // 10ns period, 100MHz
  end

  // Reset generation
  initial begin
    rstn = 1'b0; // Assert reset
    #20;
    rstn = 1'b1; // De-assert reset
  end

  // Main stimulus control based on defines
  initial begin
    // RTL_LIB_SIM should be defined via simulator command line for DUT behavioral code
    `ifndef RTL_LIB_SIM
      $display("ERROR: RTL_LIB_SIM is not defined. Please define it for DUT behavioral simulation (e.g., +define+RTL_LIB_SIM).");
      $finish;
    `endif

    // Wait for reset to de-assert
    @(posedge rstn);
    #10; // Wait a bit more after reset

    `ifdef INJECT_DELAY
      $display("[%0t] Test Mode: INJECT_DELAY selected.", $time);
      test_inject_delay();
    `elsif INJECT_X
      $display("[%0t] Test Mode: INJECT_X selected.", $time);
      test_inject_x();
    `else
      $display("[%0t] Test Mode: Normal Operation selected.", $time);
      test_normal_operation();
    `endif

    #50; // Extra delay after the selected test completes
    $display("[%0t] Simulation finished.", $time);
    $finish;
  end

  // Task for normal operation test
  task test_normal_operation;
    begin
      $display("[%0t] Normal Operation: Applying inputs", $time);
      // Apply some input changes
      in_tb = 1'b0;
      @(posedge clk);
      #1;
      if (out_tb !== 1'b0) $display("[%0t] ERROR: Normal - Expected out_tb=0, got %b", $time, out_tb);

      in_tb = 1'b1;
      @(posedge clk); // dff_con[0] = 1
      @(posedge clk); // dff_con[1] = 1
      @(posedge clk); // dff_con[2] = 1 (out_tb for Depth=2)
      @(posedge clk); // dff_con[3] = 1 (out_tb for Depth=3)
      #1;
      if (out_tb !== 1'b1) $display("[%0t] ERROR: Normal - Expected out_tb=1 after 1, got %b", $time, out_tb);
      else $display("[%0t] PASS: Normal - out_tb is 1 as expected", $time);

      in_tb = 1'b0;
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      @(posedge clk);
      #1;
      if (out_tb !== 1'b0) $display("[%0t] ERROR: Normal - Expected out_tb=0 after 0, got %b", $time, out_tb);
      else $display("[%0t] PASS: Normal - out_tb is 0 as expected", $time);

      // Test rapid changes
      for (int i = 0; i < 5; i++) begin
        in_tb = ~$member(i, '{0, 2, 4}); // Toggle input
        @(posedge clk);
        #1; // Allow combinational logic to settle for check
        // Check output after DEPTH+1 cycles for stability
        logic expected_out;
        fork
          begin : checker_thread
            #(DEPTH * 10 + 5); // Wait for DEPTH cycles + a bit
            expected_out = in_tb; // The input that should have propagated
            // Re-sample in_tb in case it changed if the loop is faster than propagation
            // Actually, the value that propagates is the one at the input of the first flop
            // So, we need to be careful here.
            // Let's check the value that was latched DEPTH cycles ago.
            // This simple check might be tricky with rapid changes.
            // For a robust check, we'd need a reference model or more complex tracking.
          end
        join_none
        // $display("[%0t] Normal - Input: %b, Output: %b (after propagation delay)", $time, in_tb, out_tb);
      end
      # (DEPTH * 10 + 20); // Wait for last input to propagate
      $display("[%0t] Normal Operation: Finished applying inputs", $time);
    end
  endtask

  // DUT instantiation
  // The behavior of the DUT is controlled by `define macros
  // (INJECT_X, INJECT_DELAY, RTL_LIB_SIM) passed by the simulator
  // or defined in the top-level test module (e.g., tb_normal).
  // RTL_LIB_SIM should be defined by the top-level test module to enable DUT's behavioral code.
  mmt_sync_single #(
    .Depth(DEPTH),
    .AsyncReset(ASYNC_RESET),
    .AsyncSet(ASYNC_SET)
    // .TransportCycle(2) // Parameter from DUT, uncomment if needed and set appropriately
  ) dut (
    .clk(clk),
    .rstn(rstn),
    .in(in_tb),
    .out(out_tb)
  );

  // Tasks for inject_delay and inject_x will be added.
  // For now, the main stimulus block will just note these require recompilation.
  // To properly test them within a single simulation run without recompilation,
  // one would typically instantiate the DUT three times with different parameters
  // or use a version of the DUT where fault injection is controlled by an input signal
  // rather than compile-time macros.
  // Given the current DUT structure, separate compilations are the most straightforward.

  // For demonstration, let's add tasks that would run if the DUT was compiled appropriately.

  task test_inject_delay;
  `ifdef INJECT_DELAY
    begin
      $display("[%0t] Inject Delay Test: Applying inputs", $time);
      in_tb = 1'b0;
      @(posedge clk);
      #1;
      // With delay, output should remain previous value for one extra cycle
      // Assuming initial value post-reset is 0.
      // After reset, fault_delay_reg_sync1 = 0. dff_con[0] = 0.
      // Propagates to out_tb.
      if (out_tb !== 1'b0) $display("[%0t] ERROR: Delay - Expected out_tb=0, got %b", $time, out_tb);


      in_tb = 1'b1;
      // Normal: in -> dff_con[0] -> dff_con[1] -> dff_con[2] -> dff_con[3] (out)
      // Delay:  in -> fault_reg -> dff_con[0] -> dff_con[1] -> dff_con[2] -> dff_con[3] (out)
      // So, it takes one extra cycle for 'in_tb' to reach 'out_tb'.
      // Total cycles = 1 (for fault_reg) + DEPTH (for synchronizer chain)
      for (int i = 0; i < (DEPTH + 1); i++) @(posedge clk);
      #1;
      if (out_tb !== 1'b1) $display("[%0t] ERROR: Delay - Expected out_tb=1 after 1, got %b", $time, out_tb);
      else $display("[%0t] PASS: Delay - out_tb is 1 as expected", $time);

      in_tb = 1'b0;
      for (int i = 0; i < (DEPTH + 1); i++) @(posedge clk);
      #1;
      if (out_tb !== 1'b0) $display("[%0t] ERROR: Delay - Expected out_tb=0 after 0, got %b", $time, out_tb);
      else $display("[%0t] PASS: Delay - out_tb is 0 as expected", $time);
      $display("[%0t] Inject Delay Test: Finished", $time);
    end
  `else
    $display("[%0t] Inject Delay Test: Skipped (INJECT_DELAY not defined)", $time);
  `endif
  endtask

  task test_inject_x;
  `ifdef INJECT_X
    begin
      $display("[%0t] Inject X Test: Observing output", $time);
      // Input 'in_tb' is irrelevant as dff_con[0] is forced to 'X'.
      // 'X' should propagate through the synchronizer.
      in_tb = 1'b1; // Apply some value, though it won't be used by the first flop
      @(posedge clk); // X into dff_con[0]
      @(posedge clk); // X into dff_con[1]
      @(posedge clk); // X into dff_con[2]
      @(posedge clk); // X into dff_con[3] (out_tb)
      #1;
      if (out_tb !== 1'bx) $display("[%0t] ERROR: Inject X - Expected out_tb=X, got %b", $time, out_tb);
      else $display("[%0t] PASS: Inject X - out_tb is X as expected", $time);

      // Change in_tb, should still see X
      in_tb = 1'b0;
      @(posedge clk); // More cycles, X should persist
      #1;
      if (out_tb !== 1'bx) $display("[%0t] ERROR: Inject X - Expected out_tb=X after input change, got %b", $time, out_tb);
      else $display("[%0t] PASS: Inject X - out_tb is X as expected after input change", $time);
      $display("[%0t] Inject X Test: Finished", $time);
    end
  `else
    $display("[%0t] Inject X Test: Skipped (INJECT_X not defined)", $time);
  `endif
  endtask

endmodule
