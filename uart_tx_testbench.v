module tb_uart_tx;

    // =================================================================
    // 1. Declare Testbench Signals
    // =================================================================
    // Inputs to the DUT must be 'reg'
    reg tb_clk;
    reg tb_rst;
    reg tb_tx_enable;
    reg [7:0] tb_tx_data;

    // Outputs from the DUT must be 'wire'
    wire tb_tx_out;
    wire tb_tx_busy;

    // =================================================================
    // 2. Instantiate the Device Under Test (DUT)
    // =================================================================
    uart_tx uut (
        .clk(tb_clk),
        .rst(tb_rst),
        .tx_enable(tb_tx_enable),
        .tx_data(tb_tx_data),
        .tx_out(tb_tx_out),
        .tx_busy(tb_tx_busy)
    );

    // =================================================================
    // 3. Generate the Clock
    // =================================================================
    // Period = 10 time units (Toggles every 5)
    always begin
        #5 tb_clk = ~tb_clk; 
    end

    // =================================================================
    // 4. Stimulus Block (The Software Script)
    // =================================================================
    initial begin
        // Print output to the console every time tx_out or tx_busy changes
        $monitor("Time: %0t | tx_busy: %b | tx_out (The Bridge): %b", $time, tb_tx_busy, tb_tx_out);

        // --- Initialization ---
        tb_clk       = 0;
        tb_rst       = 1;
        tb_tx_enable = 0;
        tb_tx_data   = 8'h00;

        #10; // Wait 1 clock cycle
        tb_rst = 0; // Release reset. System is now IDLE.
        #10;

        // --- Test Case 1: Send 8'hA5 (Binary: 1010_0101) ---
        $display("\n--- Starting Test Case 1: Sending 8'hA5 ---");
        tb_tx_data   = 8'b10100101; 
        
        // Pulse the enable button
        tb_tx_enable = 1; 
        #10;              // Hold enable high for 1 clock cycle
        tb_tx_enable = 0; // Release the button

        // The FSM takes over! It takes 1 tick per state.
        // Start(1) + Data(8) + Stop(1) = 10 clock cycles.
        // 10 cycles * 10 time units = 100 time units.
        #120; // Wait a bit longer than required to watch it return to IDLE

        // --- Test Case 2: Send 8'h3C (Binary: 0011_1100) ---
        $display("\n--- Starting Test Case 2: Sending 8'h3C ---");
        tb_tx_data   = 8'b00111100;
        
        tb_tx_enable = 1;
        #10;
        tb_tx_enable = 0;
        
        #120;

        // End the simulation
        $display("\n--- Simulation Complete ---");
        $finish;
    end

endmodule