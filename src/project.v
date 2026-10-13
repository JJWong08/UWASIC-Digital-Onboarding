
`default_nettype none

module tt_um_uwasic_onboarding_Jordan_Wong (
    input  wire [7:0] ui_in,
    output wire [7:0] uo_out,
    input  wire [7:0] uio_in,
    output wire [7:0] uio_out,
    output wire [7:0] uio_oe,
    input  wire ena,
    input  wire clk,
    input  wire rst_n
);

    // Set all bidirectional IOs to output
    assign uio_oe = 8'hFF;

    // Declare wires
    wire [7:0] en_reg_out_7_0;
    wire [7:0] en_reg_out_15_8;
    wire [7:0] en_reg_pwm_7_0;
    wire [7:0] en_reg_pwm_15_8;
    wire [7:0] pwm_duty_cycle;

    // Instantiate the SPI module
spi_peripheral spi_peripheral_inst (
    .clk(clk),
    .rst_n(rst_n),
    .sclk(ui_in[0]),
    .copi(ui_in[1]),
    .cs_n(ui_in[2]),
    .en_reg_out_7_0(en_reg_out_7_0),
    .en_reg_out_15_8(en_reg_out_15_8),
    .en_reg_pwm_7_0(en_reg_pwm_7_0),
    .en_reg_pwm_15_8(en_reg_pwm_15_8),
    .pwm_duty_cycle(pwm_duty_cycle)
);

    // Instantiate the PWM module
    pwm_peripheral pwm_peripheral_inst (
        .clk(clk),
        .rst_n(rst_n),
        .en_reg_out_7_0(en_reg_out_7_0),
        .en_reg_out_15_8(en_reg_out_15_8),
        .en_reg_pwm_7_0(en_reg_pwm_7_0),
        .en_reg_pwm_15_8(en_reg_pwm_15_8),
        .pwm_duty_cycle(pwm_duty_cycle),
        .out({uio_out, uo_out})
    );

    // Mark unused inputs
    wire _unused = &{ena, ui_in[7:3], uio_in, 1'b0};

endmodule
