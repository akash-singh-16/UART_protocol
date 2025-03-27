# UART_Protocol

The Universal Asynchronous Receiver-Transmitter (UART) is a widely used serial communication protocol for full-duplex data exchange between devices. Unlike synchronous protocols, UART does not require a clock signal, instead relying on a predefined baud rate for synchronization. The protocol operates with:

TX (Transmitter) – Sends serial data.

RX (Receiver) – Receives serial data.

Start Bit – Indicates the beginning of data transmission.

Data Bits – Typically 8-bit data frames.

Parity Bit (Optional) – Used for error detection.

Stop Bit(s) – Marks the end of transmission.

UART is commonly used in embedded systems, serial debugging, and low-bandwidth communication applications.

Project Implementation
UART Transmitter (TX) and Receiver (RX) Modules: Designed and implemented using SystemVerilog.

Finite State Machine (FSM) for TX and RX: Handles different states, including:

Idle State – Waiting for data transmission.

Start State – Initiating data transfer.

Transfer State – Sequentially transmitting or receiving bits.

Completion State – Indicating end of transmission.

Object-Oriented SystemVerilog Testbench:

Modular and Scalable Design for easy extension.

Class-Based Approach for better maintainability.

Transaction Generator, Driver, Monitor, and Scoreboard for comprehensive verification.

This project demonstrates a structured approach to UART design and verification, ensuring reliable serial communication in embedded systems and digital designs.
