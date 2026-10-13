`default_nettype none

module spi_peripheral (
    input  wire clk,
    input  wire rst_n,

    input  wire sclk,
    input  wire cs_n,
    input  wire copi,

    output reg [7:0] en_reg_out_7_0,
    output reg [7:0] en_reg_out_15_8,
    output reg [7:0] en_reg_pwm_7_0,
    output reg [7:0] en_reg_pwm_15_8,
    output reg [7:0] pwm_duty_cycle
);
    localparam max_address = 7'h04;
    // Three-stage synchronizers for external SPI signals
    reg [2:0] sclk_sync;
    reg [2:0] copi_sync;
    reg [2:0] cs_sync;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sclk_sync <= 3'b00;
            copi_sync <= 3'b00;
            cs_sync   <= 3'b111;
        end else begin
            sclk_sync <= {sclk_sync[1], sclk_sync[0], sclk};
            copi_sync <= {copi_sync[1], copi_sync[0], copi};
            cs_sync   <= {cs_sync[1], cs_sync[0], cs_n};
        end
    end

    // Detect a rising edge of the synchronized SPI clock
    wire sclk_rise = !sclk_sync[2] && sclk_sync[1];
    wire sclk_fall = sclk_sync[2] && !sclk_sync[1];

    wire cs_rise = !cs_sync[2] && cs_sync[1];
    wire cs_fall = cs_sync[2] && !cs_sync[1];

    // SPI byte receiver
    reg [7:0] shift_reg;
    reg [3:0] bit_count;
    reg rw_bit;
    reg[6:0] address;
    reg[7:0] data;
    reg transaction_complete;

    // Value that would result from shifting in the next bit
    wire [7:0] next_byte = {shift_reg[6:0], copi_sync[2]};

 

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg        <= 8'b0;
            bit_count        <= 4'b0;
            address          <= 7'b0;
            rw_bit           <= 1'b0;
            data             <= 8'b0;

            en_reg_out_7_0   <= 8'b0;
            en_reg_out_15_8  <= 8'b0;
            en_reg_pwm_7_0   <= 8'b0;
            en_reg_pwm_15_8  <= 8'b0;
            pwm_duty_cycle   <= 8'b0;

            transaction_complete <= 1'b0;

        end else if (cs_fall) begin
        shift_reg <= 8'b0;
        bit_count <= 4'b0;
        transaction_complete <= 1'b0;

        end else if (cs_rise) begin
            if((rw_bit == 1'b1) && transaction_complete && address <= max_address)begin
                case(address)
                    7'h00: en_reg_out_7_0  <= data;
                    7'h01: en_reg_out_15_8 <= data;
                    7'h02: en_reg_pwm_7_0  <= data;
                    7'h03: en_reg_pwm_15_8 <= data;
                    7'h04: pwm_duty_cycle  <= data;
                    default: ;
                endcase
            end
            shift_reg        <= 8'b0;
            bit_count        <= 4'b0;
            address          <= 7'b0;
            rw_bit           <= 1'b0;
            data             <= 8'b0;
            transaction_complete <= 1'b0;

        end else if (sclk_rise && !transaction_complete) begin
            // Collect the next incoming bit
            shift_reg <= next_byte;
            if(bit_count == 4'd0) begin
                rw_bit <= copi_sync[2];
            end
            else if (bit_count == 4'd7) begin
                address <= next_byte[6:0];
            end
            else if (bit_count == 4'd15 && address < 7'h05) begin
                data <= next_byte;
                transaction_complete <= 1'b1;
            end
            bit_count <= bit_count + 1'b1;
        end 
    end
endmodule