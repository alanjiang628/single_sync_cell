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
  mmt_sync_single #(
    .Depth(DEPTH),
    .AsyncReset(ASYNC_RESET),
    .AsyncSet(ASYNC_SET)
  ) dut (
    .clk(clk),
    .rstn(rstn),
    .in(in_tb),
    .out(out_tb)
  );

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
    `ifndef RTL_LIB_SIM
      $display("ERROR: RTL_LIB_SIM is not defined. Please define it for DUT behavioral simulation (e.g., +define+RTL_LIB_SIM).");
      $finish;
    `endif

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

    #50;
    $display("[%0t] Simulation finished.", $time);
    $finish;
  end

  task test_normal_operation;
    begin
      $display("[%0t] Normal Operation: Applying inputs", $time);
      in_tb = 1'b0;
      repeat(DEPTH + 1) @(posedge clk); #1;
      if (out_tb !== 1'b0) $display("[%0t] ERROR: Normal - Expected out_tb=0, got %b", $time, out_tb);
      else $display("[%0t] PASS: Normal - out_tb is 0 as expected", $time);

      in_tb = 1'b1;
      repeat(DEPTH + 1) @(posedge clk); #1;
      if (out_tb !== 1'b1) $display("[%0t] ERROR: Normal - Expected out_tb=1, got %b", $time, out_tb);
      else $display("[%0t] PASS: Normal - out_tb is 1 as expected", $time);
      $display("[%0t] Normal Operation: Finished", $time);
    end
  endtask

  task test_inject_delay;
  `ifdef INJECT_DELAY
    begin
      $display("[%0t] Inject Delay Test: Applying inputs", $time);
      in_tb = 1'b0;
      // Total cycles = 1 (for fault_reg) + DEPTH (for synchronizer chain) + 1 (for final output)
      repeat(DEPTH + 1 + 1) @(posedge clk); #1;
      if (out_tb !== 1'b0) $display("[%0t] ERROR: Delay - Expected out_tb=0, got %b", $time, out_tb);
      else $display("[%0t] PASS: Delay - out_tb is 0 as expected", $time);

      in_tb = 1'b1;
      repeat(DEPTH + 1 + 1) @(posedge clk); #1;
      if (out_tb !== 1'b1) $display("[%0t] ERROR: Delay - Expected out_tb=1, got %b", $time, out_tb);
      else $display("[%0t] PASS: Delay - out_tb is 1 as expected", $time);
      $display("[%0t] Inject Delay Test: Finished", $time);
    end
  `else
    $display("[%0t] Inject Delay Test: Skipped (INJECT_DELAY not defined)", $time);
  `endif
  endtask

  task test_inject_x;
  `ifdef INJECT_X
    begin
      logic stable_val_after_x;
      $display("[%0t] Inject X Test: Simulating single 'X' injection at dff_con[0] post-reset.", $time);

      // --- Cycle C1 (First posedge clk after rstn high) ---
      // DUT: dff_con[0] is 'X'. First DFF captures 'X'. is_first_cycle_after_reset_flag becomes false.
      // TB: Set in_tb to the value that should be captured in the *next* cycle (C2).
      stable_val_after_x = 1'b1;
      in_tb = stable_val_after_x;
      $display("[%0t] Inject X: At C1, driving in_tb = %b (for C2 capture). DUT dff_con[0] is X.", $time, in_tb);
      @(posedge clk); // End of C1. After this, dff_con[1] (output of 1st flop) is 'X'.

      // --- Cycle C2 ---
      // DUT: dff_con[0] captures in_tb (stable_val_after_x). dff_con[1] (from C1) is 'X'. 2nd DFF captures 'X'.
      // TB: Keep in_tb stable or change if needed. For recovery, keep stable.
      in_tb = stable_val_after_x;
      $display("[%0t] Inject X: At C2, driving in_tb = %b. DUT dff_con[0] captures this.", $time, in_tb);
      @(posedge clk); // End of C2. After this, dff_con[1] is stable_val_after_x, dff_con[2] is 'X'.

      // Wait for 'X' to propagate to out_tb.
      // 'X' was at dff_con[1] after C1. It takes (DEPTH-1) more cycles to reach out_tb.
      // We are currently after C2. So, (DEPTH-2) more cycles are needed if DEPTH > 1.
      // If DEPTH = 1, out_tb was 'X' after C1.
      // If DEPTH = 2, out_tb was 'X' after C2.
      // If DEPTH = 3, out_tb will be 'X' after C3 (which is the next @(posedge clk)).
      $display("[%0t] Inject X: Waiting for 'X' to propagate to out_tb...", $time);
      if (DEPTH > 2) begin // If DEPTH is 3, X is at dff_con[2], needs 1 more cycle. (DEPTH-2) = 1.
          repeat(DEPTH - 2) @(posedge clk);
      end
      // For DEPTH=1, X was at out_tb after C1.
      // For DEPTH=2, X was at out_tb after C2.
      // For DEPTH=3, X is at out_tb after C2 + 1 cycle = C3.
      // The loop above handles DEPTH > 2.
      // If DEPTH=1, we are 1 cycle late for checking X. If DEPTH=2, we are at the right time.
      // Let's simplify: wait DEPTH cycles from C1 (when X hit dff_con[0])
      // We've had 2 cycles (C1, C2). So, DEPTH-2 more cycles.
      // This means total of C1 + (DEPTH-1) cycles to see X at output.
      // We are at end of C2. So (DEPTH-1-1) = (DEPTH-2) more cycles.
      // This logic is getting complicated. Let's reset timing from start of test.
      // Reset initial block: @(posedge rstn); #10;
      // test_inject_x called.
      // C1: @(posedge clk) -> X at dff_con[0], dff_con[1] becomes X
      // C2: @(posedge clk) -> stable at dff_con[0], dff_con[1] becomes stable, dff_con[2] becomes X
      // ...
      // C_DEPTH: @(posedge clk) -> dff_con[DEPTH-1] becomes X
      // C_(DEPTH+1): @(posedge clk) -> dff_con[DEPTH] (out_tb) becomes X
      // We have already executed 2 @(posedge clk) in this task.
      // So, we need (DEPTH + 1 - 2) = (DEPTH - 1) more clock cycles.
      if (DEPTH > 0) begin // Ensure we don't wait negative cycles if DEPTH is small
        repeat(DEPTH - 1) @(posedge clk);
      end
      #1; // Settle for check

      if (out_tb !== 1'bx) begin
        $display("[%0t] ERROR: Inject X - Expected out_tb to be X after X propagation, but got %b", $time, out_tb);
      end else begin
        $display("[%0t] PASS: Inject X - out_tb is X after X propagation as expected.", $time);
      end

      // Now, wait for the stable 'stable_val_after_x' to propagate fully.
      // stable_val_after_x was at dff_con[0] at C2.
      // It will take DEPTH cycles from C2 to reach out_tb.
      // We are currently at C_(DEPTH+1).
      // So, we need 1 more clock cycle for stable_val_after_x to appear at out_tb.
      $display("[%0t] Inject X: Waiting for stable value '%b' to propagate to out_tb...", $time, stable_val_after_x);
      @(posedge clk); // This is effectively C_(DEPTH+2) from rstn high, or C_(DEPTH+1) from X injection.
      #1;

      if (out_tb !== stable_val_after_x) begin
        $display("[%0t] ERROR: Inject X - Expected out_tb to recover to %b, but got %b", $time, stable_val_after_x, out_tb);
      end else begin
        $display("[%0t] PASS: Inject X - out_tb recovered to %b as expected.", $time, stable_val_after_x);
      end

      // Test with another value (0)
      stable_val_after_x = 1'b0;
      in_tb = stable_val_after_x;
      $display("[%0t] Inject X: Driving in_tb = %b for further recovery test.", $time, in_tb);
      // Value hits dff_con[0] now. Wait DEPTH cycles.
      repeat(DEPTH) @(posedge clk);
      #1;

      if (out_tb !== stable_val_after_x) begin
        $display("[%0t] ERROR: Inject X - Expected out_tb to switch to %b, but got %b", $time, stable_val_after_x, out_tb);
      end else begin
        $display("[%0t] PASS: Inject X - out_tb switched to %b as expected.", $time, stable_val_after_x);
      end

      $display("[%0t] Inject X Test: Finished.", $time);
    end
  `else
    $display("[%0t] Inject X Test: Skipped (INJECT_X not defined)", $time);
  `endif
  endtask

endmodule
