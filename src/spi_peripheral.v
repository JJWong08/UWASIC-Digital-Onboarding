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

    wire cs_rise = !cs_sync[2] && cs_sync[1];
    wire cs_fall = cs_sync[2] && !cs_sync[1];

    // SPI byte receiver
    reg [15:0] shift_reg;
    reg [3:0] bit_count;
    reg transaction_complete;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_reg        <= 16'b0;
            bit_count        <= 4'b0;
            en_reg_out_7_0   <= 8'b0;
            en_reg_out_15_8  <= 8'b0;
            en_reg_pwm_7_0   <= 8'b0;
            en_reg_pwm_15_8  <= 8'b0;
            pwm_duty_cycle   <= 8'b0;
            transaction_complete <= 1'b0;

        end else if (cs_fall) begin
        shift_reg <= 16'b0;
        bit_count <= 4'b0;
        transaction_complete <= 1'b0;

        end else if (cs_rise) begin
            if(shift_reg[15] == 1'b1 && transaction_complete)begin
                case(shift_reg[14:8])
                    7'h00: en_reg_out_7_0  <= shift_reg[7:0];
                    7'h01: en_reg_out_15_8 <= shift_reg[7:0];
                    7'h02: en_reg_pwm_7_0  <= shift_reg[7:0];
                    7'h03: en_reg_pwm_15_8 <= shift_reg[7:0];
                    7'h04: pwm_duty_cycle  <= shift_reg[7:0];
                    default: ;
                endcase
            end
            shift_reg        <= 16'b0;
            bit_count        <= 4'b0;
            transaction_complete <= 1'b0;

        end else if (sclk_rise && !transaction_complete) begin    
            shift_reg <= {shift_reg[14:0],copi_sync[2]};
            if(bit_count == 4'd15) begin
                transaction_complete <= 1'b1;
            end
            bit_count <= bit_count + 1'b1;
        end 
    end
endmodule