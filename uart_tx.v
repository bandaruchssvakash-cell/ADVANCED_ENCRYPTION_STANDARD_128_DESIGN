module uart_tx (
    input wire clk,
    input wire tx_start,    // Pulse this to start transmission
    input wire [7:0] data_in,
    output reg tx_serial,   // Connect to RsTx pin
    output reg tx_busy      // 1 while transmitting
);

    parameter CLKS_PER_BIT = 10416; // 100MHz / 9600 Baud

    parameter IDLE  = 3'b000;
    parameter START = 3'b001;
    parameter DATA  = 3'b010;
    parameter STOP  = 3'b011;
    parameter CLEANUP = 3'b100;

    reg [2:0] state = 0;
    reg [13:0] clk_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] data_copy = 0;

    always @(posedge clk) begin
        case (state)
            IDLE: begin
                tx_serial <= 1; // Idle line is High
                tx_busy <= 0;
                clk_count <= 0;
                bit_index <= 0;
                if (tx_start == 1) begin
                    tx_busy <= 1;
                    data_copy <= data_in;
                    state <= START;
                end
            end

            START: begin
                tx_serial <= 0; // Start bit is Low
                if (clk_count < CLKS_PER_BIT-1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    state <= DATA;
                end
            end

            DATA: begin
                tx_serial <= data_copy[bit_index];
                if (clk_count < CLKS_PER_BIT-1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    if (bit_index < 7) begin
                        bit_index <= bit_index + 1;
                    end else begin
                        bit_index <= 0;
                        state <= STOP;
                    end
                end
            end

            STOP: begin
                tx_serial <= 1; // Stop bit is High
                if (clk_count < CLKS_PER_BIT-1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    state <= CLEANUP;
                end
            end
            
            CLEANUP: begin
                tx_busy <= 0;
                state <= IDLE;
            end
            default: state <= IDLE; // <--- ADD THIS LINE
        endcase
    end
endmodule