UART Transmitter (8-N-1) IP Core

📌 Project Overview

This repository contains the complete RTL design, verification, and synthesis of a parameterized UART Transmitter IP Core.

As my first formal VLSI project, I focused heavily on adhering to a professional hardware engineering lifecycle—moving strictly from protocol specification to micro-architecture, and finally to RTL implementation and Static Timing Analysis (STA).

⚙️ The Engineering Process

1. Specification & Requirements

The goal was to design an asynchronous serial transmitter adhering to the standard UART 8-N-1 protocol:

Idle State: Line held HIGH.

Start Bit: 1 clock cycle LOW to wake the receiver.

Data Payload: 8 bits transmitted sequentially, Least Significant Bit (LSB) first.

Stop Bit: 1 clock cycle HIGH to conclude the frame.

2. Architecture & Datapath Separation

To ensure clean synthesis and prevent timing violations, the architecture strictly separates the Control Unit (FSM) from the Datapath (Registers/Counters). The FSM acts as the "brain," sending control signals to the "muscle."

graph TD
    subgraph UART_TX_CORE [UART Transmitter IP Core]
        direction TB
        
        %% External Inputs
        clk((clk))
        tx_enable([tx_enable])
        tx_data[/tx_data 7:0/]
        
        %% Internal Blocks
        FSM{Control Unit FSM}
        SHIFT[8-Bit Shift Register]
        COUNT[3-Bit Counter]
        
        %% Connections
        tx_enable --> FSM
        tx_data --> SHIFT
        
        FSM -- load_data --> SHIFT
        FSM -- shift_en --> SHIFT
        FSM -- clear_counter --> COUNT
        FSM -- inc_counter --> COUNT
        
        COUNT -- bit_count == 7 --> FSM
        
        %% External Outputs
        FSM -- tx_busy --> BUSY([tx_busy])
        SHIFT -- LSB --> TX_OUT([tx_out])
    end


3. Micro-Architecture (Finite State Machine)

The Control Unit is implemented as a 4-state Moore/Mealy hybrid machine. Below is the exact signal flow and state transition graph used to code the Next-State logic:

stateDiagram-v2
    [*] --> IDLE
    
    IDLE --> IDLE : tx_enable = 0\ntx_out = 1
    IDLE --> START : tx_enable = 1\n(Assert load_data)
    
    START --> DATA : Auto-transition\ntx_out = 0\n(Assert clear_counter)
    
    DATA --> DATA : bit_count < 7\ntx_out = Shift_Reg[0]\n(Assert shift_en, inc_counter)
    DATA --> STOP : bit_count = 7
    
    STOP --> IDLE : Auto-transition\ntx_out = 1


📊 Verification (Testbench)

The RTL was verified using a self-checking testbench in Xilinx Vivado.

Test Scenario: Transmitting the hex payload 8'hA5 (Binary: 10100101).
As shown in the waveform below, the FSM successfully pulls the line LOW for the START bit, shifts the alternating bits (1-0-1-0-0-1-0-1) LSB-first, and pulls the line HIGH for the STOP bit.

![Waveform](https://github.com/GovindrajR/UART_Transmitter/blob/main/waveform.png?raw=true)
![Utilization Report](https://github.com/GovindrajR/UART_Transmitter/blob/main/utilizaton%20summary.png?raw=true)
![Power Report](https://github.com/GovindrajR/UART_Transmitter/blob/main/power%20report.png?raw=true)

📈 Synthesis & Implementation Results

The design was synthesized in Xilinx Vivado. The explicit Datapath-Control separation resulted in a highly optimized, lightweight logic footprint with zero latches.

Resource Utilization

LUTs: 15 (0.01%)

Registers (Flip-Flops): 15 (0.01%)

Total On-Chip Power: 0.376 W (Dynamic: 0.244 W)

Timing Analysis

Because the datapath relies entirely on direct register shifts and a minimal 3-bit counter, the combinational delay ($T_{comb}$) is negligible. With standard XDC constraints, this core is capable of closing timing at $>100$ MHz.

Designed by [Your Name] | Built for VLSI/Embedded Hardware Portfolio
