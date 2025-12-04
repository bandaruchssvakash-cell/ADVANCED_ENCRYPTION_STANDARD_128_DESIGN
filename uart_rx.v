module uart_rx (
    input wire clk,       // 100 MHz clock
    input wire rx,        // Serial data in (RsRx)
    output reg [7:0] data_out,
    output reg byte_ready
);

    // 100MHz / 9600 baud = 10416 ticks per bit
    parameter CLKS_PER_BIT = 10416;

    parameter IDLE = 3'b000;
    parameter START_BIT = 3'b001;
    parameter DATA_BITS = 3'b010;
    parameter STOP_BIT = 3'b011;
    parameter CLEANUP = 3'b100;

    reg [2:0] state = 0;
    reg [13:0] clk_count = 0;
    reg [2:0] bit_index = 0;
    reg [7:0] shift_reg = 0;

    always @(posedge clk) begin
        case (state)
            IDLE: begin
                byte_ready <= 0;
                clk_count <= 0;
                bit_index <= 0;
                if (rx == 0) // Start bit detected
                    state <= START_BIT;
            end

            START_BIT: begin
                // Wait half a bit width to sample in the middle
                if (clk_count == (CLKS_PER_BIT-1)/2) begin
                    if (rx == 0) begin
                        clk_count <= 0;
                        state <= DATA_BITS;
                    end else
                        state <= IDLE;
                end else
                    clk_count <= clk_count + 1;
            end

            DATA_BITS: begin
                if (clk_count < CLKS_PER_BIT-1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    clk_count <= 0;
                    shift_reg[bit_index] <= rx; // Sample data
                    if (bit_index < 7) begin
                        bit_index <= bit_index + 1;
                    end else begin
                        bit_index <= 0;
                        state <= STOP_BIT;
                    end
                end
            end

            STOP_BIT: begin
                if (clk_count < CLKS_PER_BIT-1) begin
                    clk_count <= clk_count + 1;
                end else begin
                    byte_ready <= 1;
                    data_out <= shift_reg;
                    state <= CLEANUP;
                end
            end

            CLEANUP: begin
                byte_ready <= 0;
                state <= IDLE;
            end
            default: state <= IDLE; // <--- ADD THIS LINE
        endcase
    end
endmodule