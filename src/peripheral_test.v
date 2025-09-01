module ofdmoffloader #(
    parameter DATA_WIDTH = 32
)(
    input              clk,
    input              rst,

    // Control
    input      [1:0]   scheme_sel,   // 00 = QPSK, 01 = 16-QAM
    input              valid_in,
    output reg         ready_out,

    // Input bits
    input      [DATA_WIDTH-1:0] data_in,
    input      [5:0]   num_bits,     // how many bits are valid (max 32)

    // Output I/Q symbol
    output reg signed [15:0] I_out,
    output reg signed [15:0] Q_out,
    output reg         valid_out
);

    // States
    reg [1:0] state, next_state;
    localparam IDLE   = 2'd0,
               MAP    = 2'd1,
               OUTPUT = 2'd2;

    // Buffers
    reg [3:0] bit_group;
    reg [DATA_WIDTH-1:0] data_shift;
    reg [5:0] bit_count;

    // Next-state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:   if (valid_in) next_state = MAP;
            MAP:    next_state = OUTPUT;
            OUTPUT: if (bit_count == 0) next_state = IDLE;
                    else next_state = MAP;
        endcase
    end

    // State registers
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state      <= IDLE;
            bit_count  <= 0;
            data_shift <= 0;
        end else begin
            state <= next_state;
            if (state == IDLE && valid_in) begin
                data_shift <= data_in;
                bit_count  <= num_bits;
            end else if (state == OUTPUT) begin
                if (scheme_sel == 2'b00) begin
                    data_shift <= data_shift >> 2; // QPSK uses 2 bits
                    bit_count  <= bit_count - 2;
                end else if (scheme_sel == 2'b01) begin
                    data_shift <= data_shift >> 4; // 16-QAM uses 4 bits
                    bit_count  <= bit_count - 4;
                end
            end
        end
    end

    // Symbol mapping
    always @(*) begin
        I_out     = 0;
        Q_out     = 0;
        valid_out = 0;
        ready_out = (state == IDLE);

        if (state == MAP) begin
            valid_out = 1;

            if (scheme_sel == 2'b00) begin
                // QPSK mapping (Gray code)
                bit_group = data_shift[1:0];
                case (bit_group)
                    2'b00: begin I_out =  23170; Q_out =  23170; end
                    2'b01: begin I_out = -23170; Q_out =  23170; end
                    2'b11: begin I_out = -23170; Q_out = -23170; end
                    2'b10: begin I_out =  23170; Q_out = -23170; end
                    default: begin I_out = 0; Q_out = 0; end
                endcase
            end else if (scheme_sel == 2'b01) begin
                // 16-QAM mapping (Gray code)
                bit_group = data_shift[3:0];
                case (bit_group)
                    4'b0000: begin I_out=-3; Q_out=-3; end
                    4'b0001: begin I_out=-3; Q_out=-1; end
                    4'b0011: begin I_out=-3; Q_out= 1; end
                    4'b0010: begin I_out=-3; Q_out= 3; end
                    4'b0100: begin I_out=-1; Q_out=-3; end
                    4'b0101: begin I_out=-1; Q_out=-1; end
                    4'b0111: begin I_out=-1; Q_out= 1; end
                    4'b0110: begin I_out=-1; Q_out= 3; end
                    4'b1100: begin I_out= 1; Q_out=-3; end
                    4'b1101: begin I_out= 1; Q_out=-1; end
                    4'b1111: begin I_out= 1; Q_out= 1; end
                    4'b1110: begin I_out= 1; Q_out= 3; end
                    4'b1000: begin I_out= 3; Q_out=-3; end
                    4'b1001: begin I_out= 3; Q_out=-1; end
                    4'b1011: begin I_out= 3; Q_out= 1; end
                    4'b1010: begin I_out= 3; Q_out= 3; end
                    default: begin I_out=0; Q_out=0; end
                endcase
            end
        end
    end

endmodule

