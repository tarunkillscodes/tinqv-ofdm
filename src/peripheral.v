module tqvp_example (
    input         clk,          // Clock - the TinyQV project clock is normally set to 64MHz.
    input         rst_n,        // Reset_n - low to reset.

    input  [7:0]  ui_in,        // The input PMOD, always available.  Note that ui_in[7] is normally used for UART RX.
                                // The inputs are synchronized to the clock, note this will introduce 2 cycles of delay on the inputs.

    output [7:0]  uo_out,       // The output PMOD.  Each wire is only connected if this peripheral is selected.
                                // Note that uo_out[0] is normally used for UART TX.

    input [3:0]   address,      // Address within this peripheral's address space

    input         data_write,   // Data write request from the TinyQV core.
    input [7:0]   data_in,      // Data in to the peripheral, valid when data_write is high.

    output [7:0]  data_out      // Data out from the peripheral, set this in accordance with the supplied address
);

//-----------CSR REGISTERS -------------------//
    reg [7:0] control_reg;//start,schemesel(1bits),valid_in
    reg [7:0] status_reg;//ready_out,bitcount(2 bits)
    reg [7:0] Data_in;
    reg [7:0] Data_out;

//-----------MAIN FSM -----------------------//

    // States
    reg [1:0] state, next_state;
    localparam IDLE   = 2'd0,
               MAP    = 2'd1,
               OUTPUT = 2'd2;

    // Next-state logic
    always @(*) begin
        next_state = state;
        case (state)
            IDLE:   if (status_reg[0]) next_state = MAP;
            MAP:    next_state = OUTPUT;
            OUTPUT: if (bit_count == 0) next_state = IDLE;
                    else next_state = MAP;
        endcase
    end
    
    // State registers and writing output to the out peripheral
    always @(posedge clk or negedge rst) begin
        if (!rst) begin
            state      <= IDLE;
            status_reg  <= 8'd0;
        end else begin
            state <= next_state;
            if (state == IDLE && valid_in) begin
                Data_in <= data_in;
                status_reg[4:2]  <= 3'd8;
            end else if (state == OUTPUT) begin
                status_reg[1] <= 1;
                if (control_reg[1] == 1'b0) begin
                    Data_in <= Data_in >> 2; // QPSK uses 2 bits
                    status_reg[4:2]  <= status_reg[4:2] - 2;
                end else if (control_reg[1] == 1'b1) begin
                    Data_in <= Data_in >> 4; // 16-QAM uses 4 bits
                    status_reg[4:2]  <= status_reg[4:2] - 4;
                end else if(status_reg[4:2] == 3'd0) begin 
                    status_reg[0] <= 1;
            end
        end
    end

//---------MAPPINNNNN---------------------//
    // Symbol mapping
    always @(*) begin
        Data_out  = 0;
        status_reg[1] = 0;
        
        if (state == MAP) begin
            if (control_reg[1] == 0) begin
                // QPSK mapping (Gray code)
                
                case (Data_in[1:0])
                    2'b00: begin Data_out[3:0] =  1; Data_out[7:4] =  1; end
                    2'b01: begin Data_out[3:0] = -1; Data_out[7:4] =  1; end
                    2'b11: begin Data_out[3:0] = -1; Data_out[7:4] = -1; end
                    2'b10: begin Data_out[3:0] =  1; Data_out[7:4] = -1; end
                    default: begin Data_out[3:0] = 0; Data_out[7:4] = 0; end
                endcase
            end else if (control_reg[1] == 1) begin
                // 16-QAM mapping (Gray code)
                bit_group = Data_in[3:0];
                case (Data_in[3:0])
                    4'b0000: begin Data_out[3:0] =-3; Data_out[7:4]=-3; end
                    4'b0001: begin Data_out[3:0] =-3; Data_out[7:4]=-1; end
                    4'b0011: begin Data_out[3:0] =-3; Data_out[7:4]= 1; end
                    4'b0010: begin Data_out[3:0] =-3; Data_out[7:4]= 3; end
                    4'b0100: begin Data_out[3:0] =-1; Data_out[7:4]=-3; end
                    4'b0101: begin Data_out[3:0] =-1; Data_out[7:4]=-1; end
                    4'b0111: begin Data_out[3:0] =-1; Data_out[7:4]= 1; end
                    4'b0110: begin Data_out[3:0] =-1; Data_out[7:4]= 3; end
                    4'b1100: begin Data_out[3:0] = 1; Data_out[7:4]=-3; end
                    4'b1101: begin Data_out[3:0] = 1; Data_out[7:4]=-1; end
                    4'b1111: begin Data_out[3:0] = 1; Data_out[7:4]= 1; end
                    4'b1110: begin Data_out[3:0] = 1; Data_out[7:4]= 3; end
                    4'b1000: begin Data_out[3:0] = 3; Data_out[7:4]=-3; end
                    4'b1001: begin Data_out[3:0] = 3; Data_out[7:4]=-1; end
                    4'b1011: begin Data_out[3:0] = 3; Data_out[7:4]= 1; end
                    4'b1010: begin Data_out[3:0] = 3; Data_out[7:4]= 3; end
                    default: begin Data_out[3:0] = 0; Data_out[7:4]= 0; end
                endcase
            end
        end
    end
//-------------REGSITER WRITE ------------------------//


always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            control_reg <= 8'b0;
            Data_in     <= 8'b0;
        end else if (data_write) begin
            case (address)
                4'h0: control_reg <= data_in;
                4'h2: Data_in     <= data_in;
            endcase
        end
    end


//--------------REGSISTER READ ------------------//

  always @(*) begin
        case (address)
            4'h0: data_out = control_reg;
            4'h1: data_out = status_reg;
            4'h2: data_out = Data_in;
            4'h3: if(status_reg[0] == 1)data_out = Data_out;
            default: data_out = 8'h00;
        endcase
    end



