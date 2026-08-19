module S6CLK2PIN
(
    input  I,
    output O
);

    altddio_out ALTDDIO_OUT_CLK2PIN
    (
        .outclock   (I),
        .outclocken (1'b1),

        .datain_h   (1'b1),
        .datain_l   (1'b0),

        .dataout    (O),

        .aclr       (1'b0),
        .aset       (1'b0),
        .sclr       (1'b0),
        .sset       (1'b0),

        .oe         (1'b1)
    );

    defparam
        ALTDDIO_OUT_CLK2PIN.intended_device_family = "Cyclone IV E",
        ALTDDIO_OUT_CLK2PIN.width                  = 1,
        ALTDDIO_OUT_CLK2PIN.power_up_high          = "OFF",
        ALTDDIO_OUT_CLK2PIN.oe_reg                 = "UNREGISTERED";

endmodule
