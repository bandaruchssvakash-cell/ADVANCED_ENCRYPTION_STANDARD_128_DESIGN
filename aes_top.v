`timescale 1ns / 1ps

module aes_top(
    input wire clk,         // 100 MHz System Clock
    input wire RsRx,        // UART RX
    output wire RsTx,       // UART TX
    input wire btnC,        // Reset
    input wire sw_encrypt,  // Switch
    output wire [15:0] led  // Debug LEDs
);

    // --- 1. Clock Management (100 MHz -> 10 MHz) ---
    reg [2:0] clk_counter = 0;
    reg clk_10mhz_raw = 0;
    
    always @(posedge clk) begin
        if (clk_counter == 4) begin 
            clk_counter <= 0;
            clk_10mhz_raw <= ~clk_10mhz_raw;
        end else begin
            clk_counter <= clk_counter + 1;
        end
    end

    wire sys_clk;
    BUFG clk_buf (.I(clk_10mhz_raw), .O(sys_clk));

    // --- 2. Signals ---
    wire [7:0] rx_byte;
    wire rx_ready;
    
    reg tx_start = 0;
    reg [7:0] tx_data = 0;
    wire tx_busy;
    wire tx_serial_wire;
    
    reg [127:0] key_reg = 0;
    reg [127:0] text_reg = 0;
    reg aes_start = 0;
    wire aes_done;
    wire [127:0] aes_result;
    
    reg [4:0] byte_counter = 0;
    reg [1:0] tx_substate = 0;
    
    parameter WAIT_KEY    = 3'b000;
    parameter WAIT_TEXT   = 3'b001;
    parameter FIRE_AES    = 3'b010;
    parameter WAIT_DONE   = 3'b011;
    parameter SEND_RESULT = 3'b100;
    parameter DONE        = 3'b101;
    
    reg [2:0] state = WAIT_KEY;

    assign RsTx = tx_serial_wire;
    assign led = { (state == DONE), aes_result[14:0] }; 

    // --- 3. Instantiations ---
    uart_rx #(.CLKS_PER_BIT(1041)) receiver (
        .clk(sys_clk), .rx(RsRx), .data_out(rx_byte), .byte_ready(rx_ready)
    );

    uart_tx #(.CLKS_PER_BIT(1041)) transmitter (
        .clk(sys_clk), .tx_start(tx_start), .data_in(tx_data), 
        .tx_serial(tx_serial_wire), .tx_busy(tx_busy)
    );

    aes_128 aes_core (
        .clk(sys_clk), .rst(btnC), .start(aes_start), 
        .data_in(text_reg),      
        .key(key_reg), .encrypt(sw_encrypt), 
        .data_out(aes_result),   
        .done(aes_done)
    );

    // --- 4. Main Logic (Synchronous Reset Fix) ---
    always @(posedge sys_clk) begin
        if (btnC) begin
            state <= WAIT_KEY;
            byte_counter <= 0;
            aes_start <= 0;
            tx_start <= 0;
            tx_data <= 0;
            tx_substate <= 0;
            key_reg <= 0;
            text_reg <= 0;
        end else begin
            case (state)
                WAIT_KEY: begin
                    if (rx_ready) begin
                        key_reg <= {key_reg[119:0], rx_byte}; 
                        byte_counter <= byte_counter + 1;
                        if (byte_counter == 15) begin
                             byte_counter <= 0;
                             state <= WAIT_TEXT;
                        end
                    end
                end

                WAIT_TEXT: begin
                    if (rx_ready) begin
                        text_reg <= {text_reg[119:0], rx_byte}; 
                        byte_counter <= byte_counter + 1;
                        if (byte_counter == 15) begin
                             state <= FIRE_AES;
                        end
                    end
                end

                FIRE_AES: begin
                    aes_start <= 1;
                    state <= WAIT_DONE;
                end

                WAIT_DONE: begin
                    aes_start <= 0;
                    if (aes_done) begin
                        byte_counter <= 0;
                        tx_substate <= 0; 
                        state <= SEND_RESULT;
                    end
                end

                SEND_RESULT: begin
                    case (tx_substate)
                        0: begin 
                            if (!tx_busy) begin
                                tx_data <= aes_result[127 - (byte_counter * 8) -: 8];
                                tx_start <= 1;
                                tx_substate <= 1;
                            end
                        end
                        1: begin 
                            tx_start <= 0;
                            tx_substate <= 2;
                        end
                        2: begin 
                            if (!tx_busy) begin
                                if (byte_counter == 15) begin
                                    state <= DONE;
                                end else begin
                                    byte_counter <= byte_counter + 1;
                                    tx_substate <= 0; 
                                end
                            end
                        end
                    endcase
                end 
                
                DONE: begin
                    // Done
                end
                
                default: state <= WAIT_KEY;
            endcase
        end
    end

endmodule