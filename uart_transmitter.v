module uart_tx (
    input wire clk,           // System Clock
    input wire rst,           // Asynchronous active-high reset
    input wire tx_enable,     // Trigger to start transmission
    input wire [7:0] tx_data, // Data payload
    output reg tx_out,        // Serial output wire
    output reg tx_busy        // High when transmitting
);

    // =================================================================
    // 1. STATE ENCODING 
    // =================================================================
    localparam IDLE  = 2'b00;
    localparam START = 2'b01;
    localparam DATA  = 2'b10;
    localparam STOP  = 2'b11;

    reg [1:0] current_state, next_state;

    // =================================================================
    // 2. INTERNAL WIRES (The FSM Commands)
    // =================================================================
    reg load_data;
    reg shift_en;
    reg clear_counter;
    reg inc_counter;

    // =================================================================
    // 3. THE DATAPATH
    // =================================================================
    reg [7:0] shift_reg;
    reg [2:0] bit_count;

    // The 8-bit Shift Register
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            shift_reg <= 8'b0000_0000;
        end else if (load_data) begin
            shift_reg <= tx_data; // Grab cars from the parking lot
        end else if (shift_en) begin
            shift_reg <= {1'b0, shift_reg[7:1]}; // Shift right by 1
        end
    end

    // The 3-bit Counter
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            bit_count <= 3'b000;
        end else if (clear_counter) begin
            bit_count <= 3'b000; // Reset counter
        end else if (inc_counter) begin
            bit_count <= bit_count + 1; // Count cars leaving
        end
    end

    // =================================================================
    // 4. THE CONTROL UNIT 
    // =================================================================

    // Block A: State Memory (Sequential)
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            current_state <= IDLE;
        end else begin
            current_state <= next_state;
        end
    end

    // Block B: Next State Logic & Datapath Control (Combinational)
    always @(*) begin
        // Default assignments to prevent latches!
        next_state    = current_state; 
        load_data     = 1'b0;
        shift_en      = 1'b0;
        clear_counter = 1'b0;
        inc_counter   = 1'b0;

        case (current_state)
            IDLE: begin
                if (tx_enable) begin
                    load_data  = 1'b1;  // FSM yells: "Grab the data!"
                    next_state = START;
                end
            end
            
            START: begin
                clear_counter = 1'b1; // FSM yells: "Reset the counter!"
                next_state    = DATA; // Unconditional jump
            end
            
            DATA: begin
                shift_en    = 1'b1; // FSM yells: "Send a bit!"
                inc_counter = 1'b1; // FSM yells: "Add 1 to count!"
                
                if (bit_count == 3'd7) begin // Using decimal '7' for clarity
                    next_state = STOP;
                end else begin
                    next_state = DATA;
                end
            end
            
            STOP: begin
                next_state = IDLE; // Unconditional jump
            end
            
            default: next_state = IDLE;
        endcase
    end

    // Block C: Output Logic (Combinational)
    always @(*) begin
        // Defaults
        tx_out  = 1'b1; // Idle state of the line is High
        tx_busy = 1'b1;

        case (current_state)
            IDLE: begin
                tx_out  = 1'b1;
                tx_busy = 1'b0;
            end
            START: begin
                tx_out  = 1'b0; // Pull line low for Start bit
            end
            DATA: begin
                tx_out  = shift_reg[0]; // Drive the LSB to the bridge
            end
            STOP: begin
                tx_out  = 1'b1; // Drive line high for Stop bit
            end
        endcase
    end

endmodule