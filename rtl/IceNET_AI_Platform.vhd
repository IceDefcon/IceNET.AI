library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- Author: Ice.Marek
-- IceNET Technology 2025
--
------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- FX3 Pinout
-- Cypress
-- cyusb3kit
--                                                IDC Tape: Flat to Flat Connection
-- FPGA Pinout                                        _______          _______
-- Cyclone IV                                        |       |        |       |
-- EP4CE15F23C8                                      |  PWR  | Switch |  USB  | Socket
--                                                   |       |        |       |
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------
--
-- VIN     :: VIN           |               |                 |                       |xxx| VIN      :: VIN          |                      |                   |          |
-- GND     :: GND           |               |                 |                       |xxx| GND      :: GND          |                      |                   |          |
-- PIN_A20 :: PIN_B20       | V3P3  :: V1P2 | REM         REM |                       |xxx| PIN_M19  :: PIN_M20      | V3P3     :: V1P2     | REM           REM |          |
-- PIN_A19 :: PIN_B19       | VBUS  :: VBUS | REM         REM |                       |xxx| PIN_N19  :: PIN_N20      | CTL15    :: VIO      | FX3_EXTINT    REM |          |
-- PIN_A18 :: PIN_B18       | GND   :: GND  | REM         REM |                       |xxx| PIN_B21  :: PIN_B22      | NC       :: DQ31     | REM               |          |
-- PIN_A17 :: PIN_B17       | CTL12 :: DQ15 |                 | A0        :: DQ[15]   |xxx| PIN_C21  :: PIN_C22      | PM_2     :: DQ30     |                   | PMODE[2] |
-- PIN_A16 :: PIN_B16       | CTL11 :: DQ14 |                 | A1        :: DQ[14]   |xxx| PIN_D21  :: PIN_D22      | PM_1     :: DQ29     |                   | PMODE[1] |
-- PIN_A15 :: PIN_B15       |       :: DQ13 |                 | GPIO      :: DQ[13]   |xxx| PIN_E21  :: PIN_E22      | PM_0     :: DQ28     |                   | PMODE[0] |
-- PIN_A14 :: PIN_B14       | CTL9  :: DQ12 |                 | GPIO      :: DQ[12]   |xxx| PIN_F21  :: PIN_F22      | GND      :: IO45     | REM               |          |
-- PIN_A13 :: PIN_B13       | CTL8  :: DQ11 |                 | GPIO      :: DQ[11]   |xxx| PIN_H21  :: PIN_H22      | GND      :: DQ27     | REM               |          |
-- PIN_A10 :: PIN_B10       | CTL7  :: DQ10 |                 | PKTEND#   :: DQ[10]   |xxx| PIN_J21  :: PIN_J22      | GND      :: DQ26     | REM               |          |
-- PIN_A9  :: PIN_B9        | CTL6  :: DQ9  |                 | GPIO      :: DQ[9]    |xxx| PIN_K21  :: PIN_K22      | Rx/MOSI  :: DQ25     |                   |          |
-- PIN_A8  :: PIN_B8        | CTL5  :: DQ8  |                 | FLAGB     :: DQ[8]    |xxx| PIN_L21  :: PIN_L22      | Tx/MISO  :: DQ24     |                   |          |
-- PIN_A7  :: PIN_B7        | CTL4  :: DQ7  |                 | FLAGA     :: DQ[7]    |xxx| PIN_M21  :: PIN_M22      | CTS/SSN  :: DQ23     |                   |          |
-- PIN_A6  :: PIN_B6        | CTL3  :: DQ6  |                 | SLRD#     :: DQ[6]    |xxx| PIN_N21  :: PIN_N22      | GND      :: DQ22     | REM               |          |
-- PIN_A5  :: PIN_B5        | CTL2  :: DQ5  |                 | SLOE#     :: DQ[5]    |xxx| PIN_P21  :: PIN_P22      | RTS/SCK  :: DQ21     |                   |          |
-- PIN_C3  :: PIN_C4        | CTL1  :: DQ4  |                 | SLWR#     :: DQ[4]    |xxx| PIN_R21  :: PIN_R22      | GND      :: DQ20     | REM               |          |
-- PIN_A4  :: PIN_B4        | CTL0  :: DQ3  |                 | SLCS#     :: DQ[3]    |xxx| PIN_U21  :: PIN_U22      | I2S_WS   :: DQ19     |                   |          |
-- PIN_A3  :: PIN_B3        | GND   :: DQ2  | REM             | GND       :: DQ[2]    |xxx| PIN_V21  :: PIN_V22      | I2S_SD   :: DQ18     |                   |          |
-- PIN_B2  :: PIN_B1        | PCLK  :: DQ1  |                 | IFCLK     :: DQ[1]    |xxx| PIN_W21  :: PIN_W22      | I2S_MCLK :: DQ17     |                   |          |
-- PIN_C2  :: PIN_C1        | GND   :: DQ0  | REM             |           :: DQ[0]    |xxx| PIN_Y21  :: PIN_Y22      | I2S_CLK  :: DQ16     |                   |          |
-- PIN_D2  :: PIN_E1        | SDA   :: SCL  |                 |                       |xxx| PIN_AB20 :: PIN_AA20     | GND      :: GND      | REM           REM |          |
-- PIN_F2  :: PIN_F1        |               |                 |                       |xxx| PIN_AB19 :: PIN_AA19     |                      |                   |          |
-- PIN_H2  :: PIN_H1        |               |                 |                       |xxx| PIN_AB18 :: PIN_AA18     |                      |                   |          |
-- PIN_J2  :: PIN_J1        |               |                 |                       |xxx| PIN_AB17 :: PIN_AA17     |                      |                   |          |
-- PIN_M2  :: PIN_M1        |               |                 |                       |xxx| PIN_AB16 :: PIN_AA16     |                      |                   |          |
-- PIN_N2  :: PIN_N1        |               |                 |                       |xxx| PIN_AB15 :: PIN_AA15     |                      |                   |          |
-- PIN_P2  :: PIN_P1        |               |                 |                       |xxx| PIN_AB14 :: PIN_AA14     |                      |                   |          |
-- PIN_R2  :: PIN_R1        |               |                 |                       |xxx| PIN_AB13 :: PIN_AA13     |                      |                   |          |
-- GND     :: GND           |               |                 |                       |xxx| GND      :: GND          |                      |                   |          |
-- 3V3     :: 3V3           |               |                 |                       |xxx| 3V3      :: 3V3          |                      |                   |          |
-- GND     :: GND           |               |                 |                       |xxx| GND      :: GND          |                      |                   |          |
--
----------------------------------------------------------------------------------------------------------------------------------------------------------------------------

entity IceNET_AI_Platform is
port
(
    RESET : in std_logic; -- PIN_E4
    CLOCK : in std_logic; -- PIN_T2

    ----------------------------------------------------------------------------------------------------------------
    -- Debug Buttons
    ----------------------------------------------------------------------------------------------------------------
    BUTTON_1 : in std_logic; -- PIN_H20
    BUTTON_2 : in std_logic; -- PIN_K19
    BUTTON_3 : in std_logic; -- PIN_J18
    BUTTON_4 : in std_logic; -- PIN_K18

    ----------------------------------------------------------------------------------------------------------------

    ----------------------------------------------------------------------------------------------------------------
    -- UNUSED PINS ARE STILL DRIVEN
    ----------------------------------------------------------------------------------------------------------------
    PIN_A20 : out std_logic;
    PIN_A19 : out std_logic;
    PIN_A18 : out std_logic;

    GPIF_CTL12 : out std_logic; -- PIN_A17 :: A0
    GPIF_CTL11 : out std_logic; -- PIN_A16 :: A1
    PIN_A15    : out std_logic;
    GPIF_CTL9  : out std_logic; -- PIN_A14 :: GPIO
    GPIF_CTL8  : in std_logic;  -- PIN_A13 :: GPIO
    GPIF_CTL7  : out std_logic; -- PIN_A10 :: n_PKTEND
    GPIF_CTL6  : in std_logic;  -- PIN_A9  :: GPIO
    GPIF_CTL5  : in std_logic;  -- PIN_A8  :: FLAGB
    GPIF_CTL4  : in std_logic;  -- PIN_A7  :: FLAGA
    GPIF_CTL3  : out std_logic; -- PIN_A6  :: n_SLRD
    GPIF_CTL2  : out std_logic; -- PIN_A5  :: n_SLOE
    GPIF_CTL1  : out std_logic; -- PIN_C3  :: n_SLWR
    GPIF_CTL0  : out std_logic; -- PIN_A4  :: n_SLCS

    PIN_A3  : out std_logic;
    IFCLK  : out std_logic;     -- PIN_B2 (gpif_clk)
    PIN_C2  : out std_logic;
    PIN_D2  : out std_logic;
    PIN_F2  : out std_logic;
    PIN_H2  : out std_logic;
    PIN_J2  : out std_logic;
    PIN_M2  : out std_logic;
    PIN_N2  : out std_logic;
    PIN_P2  : out std_logic;
    PIN_R2  : out std_logic;

    PIN_B20 : out std_logic;
    PIN_B19 : out std_logic;
    PIN_B18 : out std_logic;
    DQ15 : out std_logic; -- PIN_B17
    DQ14 : out std_logic; -- PIN_B16
    DQ13 : out std_logic; -- PIN_B15
    DQ12 : out std_logic; -- PIN_B14
    DQ11 : out std_logic; -- PIN_B13
    DQ10 : out std_logic; -- PIN_B10
    DQ9  : out std_logic; -- PIN_B9
    DQ8  : out std_logic; -- PIN_B8
    DQ7  : out std_logic; -- PIN_B7
    DQ6  : out std_logic; -- PIN_B6
    DQ5  : out std_logic; -- PIN_B5
    DQ4  : out std_logic; -- PIN_C4
    DQ3  : out std_logic; -- PIN_B4
    DQ2  : out std_logic; -- PIN_B3
    DQ1  : out std_logic; -- PIN_B1
    DQ0  : out std_logic; -- PIN_C1
    PIN_E1  : out std_logic;
    PIN_F1  : out std_logic;
    PIN_H1  : out std_logic;
    PIN_J1  : out std_logic;
    PIN_M1  : out std_logic;
    PIN_N1  : out std_logic;
    PIN_P1  : out std_logic;
    PIN_R1  : out std_logic;

    PIN_M19  : out std_logic;
    FX3_EXTINT  : in std_logic; -- PIN_N19
    PIN_B21  : out std_logic;
    PIN_C21  : out std_logic;
    PIN_D21  : out std_logic;
    PIN_E21  : out std_logic;
    PIN_F21  : out std_logic;
    PIN_H21  : out std_logic;
    PIN_J21  : out std_logic;
    PIN_K21  : out std_logic;
    PIN_L21  : out std_logic;
    PIN_M21  : out std_logic;
    PIN_N21  : out std_logic;
    PIN_P21  : out std_logic;
    PIN_R21  : out std_logic;
    PIN_U21  : out std_logic;
    PIN_V21  : out std_logic;
    PIN_W21  : out std_logic;
    PIN_Y21  : out std_logic;
    PIN_AB20 : out std_logic;
    PIN_AB19 : out std_logic;
    PIN_AB18 : out std_logic;
    PIN_AB17 : out std_logic;
    PIN_AB16 : out std_logic;
    PIN_AB15 : out std_logic;
    PIN_AB14 : out std_logic;
    PIN_AB13 : out std_logic;

    PIN_M20  : out std_logic;
    PIN_N20  : out std_logic;
    DQ31 : out std_logic; -- PIN_B22
    DQ30 : out std_logic; -- PIN_C22
    DQ29 : out std_logic; -- PIN_D22
    DQ28 : out std_logic; -- PIN_E22
    PIN_F22 : out std_logic;
    DQ27 : out std_logic; -- PIN_H22
    DQ26 : out std_logic; -- PIN_J22
    DQ25 : out std_logic; -- PIN_K22
    DQ24 : out std_logic; -- PIN_L22
    DQ23 : out std_logic; -- PIN_M22
    DQ22 : out std_logic; -- PIN_N22
    DQ21 : out std_logic; -- PIN_P22
    DQ20 : out std_logic; -- PIN_R22
    DQ19 : out std_logic; -- PIN_U22
    DQ18 : out std_logic; -- PIN_V22
    DQ17 : out std_logic; -- PIN_W22
    DQ16 : out std_logic; -- PIN_Y22
    PIN_AA20 : out std_logic;
    PIN_AA19 : out std_logic;
    PIN_AA18 : out std_logic;
    PIN_AA17 : out std_logic;
    PIN_AA16 : out std_logic;
    PIN_AA15 : out std_logic;
    PIN_AA14 : out std_logic;
    PIN_AA13 : out std_logic;

    GPIF_D : inout std_logic_vector(31 downto 0); -- PIN_A20..PIN_B4

    ----------------------------------------------------------------------------------------------------------------
    -- DEBUG LEDS
    ----------------------------------------------------------------------------------------------------------------

    LED_1 : out std_logic; -- PIN_U7
    LED_2 : out std_logic; -- PIN_U8
    LED_3 : out std_logic; -- PIN_R7
    LED_4 : out std_logic; -- PIN_T8
    LED_5 : out std_logic; -- PIN_R8
    LED_6 : out std_logic; -- PIN_P8
    LED_7 : out std_logic; -- PIN_M8
    LED_8 : out std_logic  -- PIN_N8
);
end IceNET_AI_Platform;

architecture rtl of IceNET_AI_Platform is

----------------------------------------------------------------------------------------------------------------
-- Constatns, Types and Signals
----------------------------------------------------------------------------------------------------------------
signal clocks_ready_count : unsigned(15 downto 0) := (others => '0');
signal clocks_ready : std_logic := '0';

signal global_reset : std_logic := '0';
signal gpif_rst : std_logic := '0';

----------------------------------------------------------------------------------------------------------------
-- PLL
----------------------------------------------------------------------------------------------------------------
signal gpif_clk    : std_logic;
signal pll_locked  : std_logic;

signal fifoadr : std_logic_vector(1 downto 0) := "00";

----------------------------------------------------------------------------------------------------------------
-- Debug
----------------------------------------------------------------------------------------------------------------
signal debug_clock_50_counter : integer range 0 to 50 := 0;
signal debug_clock_100_counter : integer range 0 to 50 := 0;

signal debug_led_1 : std_logic := '0';
signal debug_led_2 : std_logic := '0';

----------------------------------------------------------------------------------------------------------------
-- Mods
----------------------------------------------------------------------------------------------------------------
component TimedReset
port
(
    RESET : in  std_logic;
    CLOCK : in  std_logic;
    TIMED_RESET : out std_logic
);
end component;

component reset_sync
port
(
    clk       : in  std_logic;
    reset_in  : in  std_logic;
    reset_out : out std_logic
);
end component;

component gen_clks
port
(
    areset  : in  std_logic := '0';
    inclk0  : in  std_logic := '0';
    c0      : out std_logic;
    locked  : out std_logic
);
end component;

component S6CLK2PIN
port
(
    I : in  std_logic;
    O : out std_logic
);
end component;

component gpif2_slave_fifo32
    generic (
        DATA_RX_FIFO_SIZE : integer := 12;
        DATA_TX_FIFO_SIZE : integer := 12;
        CTRL_RX_FIFO_SIZE : integer := 5;
        CTRL_TX_FIFO_SIZE : integer := 5;

        ADDR_DATA_TX : std_logic_vector(1 downto 0) := "00";
        ADDR_DATA_RX : std_logic_vector(1 downto 0) := "01";
        ADDR_CTRL_TX : std_logic_vector(1 downto 0) := "10";
        ADDR_CTRL_RX : std_logic_vector(1 downto 0) := "11"
    );
    port (
        -- GPIF signals
        gpif_clk : in  std_logic;
        gpif_rst : in  std_logic;
        gpif_enb : in  std_logic;
        gpif_d   : inout std_logic_vector(31 downto 0);
        gpif_ctl : in  std_logic_vector(3 downto 0);

        sloe    : out std_logic;
        slrd    : out std_logic;
        slwr    : out std_logic;
        slcs    : out std_logic;
        pktend  : out std_logic;
        fifoadr : out std_logic_vector(1 downto 0);

        -- FIFO interfaces
        fifo_clk : in std_logic;
        fifo_rst : in std_logic;

        -- TX Data interface
        tx_tdata  : out std_logic_vector(63 downto 0);
        tx_tlast  : out std_logic;
        tx_tvalid : out std_logic;
        tx_tready : in std_logic;

        -- RX Data interface
        rx_tdata  : in std_logic_vector(63 downto 0);
        rx_tlast  : in std_logic;
        rx_tvalid : in std_logic;
        rx_tready : out std_logic;

        -- Incoming control interface
        ctrl_tdata  : out std_logic_vector(63 downto 0);
        ctrl_tlast  : out std_logic;
        ctrl_tvalid : out std_logic;
        ctrl_tready : in std_logic;

        -- Outgoing control interface
        resp_tdata  : in std_logic_vector(63 downto 0);
        resp_tlast  : in std_logic;
        resp_tvalid : in std_logic;
        resp_tready : out std_logic;

        -- Debug
        debug : out std_logic_vector(31 downto 0)
    );
end component;

----------------------------------------------------------------------------------------------------------------
-- Main Routine
----------------------------------------------------------------------------------------------------------------
begin

TimedReset_mod: TimedReset
port map
(
   RESET => RESET,
   CLOCK => CLOCK,

   TIMED_RESET => global_reset
);

process(gpif_clk, global_reset, pll_locked)
begin
    if global_reset = '1' or pll_locked = '0' then
        clocks_ready_count <= (others => '0');
        clocks_ready       <= '0';

    elsif rising_edge(gpif_clk) then
        if clocks_ready = '0' then
            clocks_ready_count <= clocks_ready_count + 1;
            if clocks_ready_count = x"FFFF" then
                clocks_ready <= '1';
            else
                clocks_ready <= '0';
            end if;
        end if;
    end if;
end process;

u_reset_sync : reset_sync
port map
(
    clk       => gpif_clk,
    reset_in  => not clocks_ready,
    reset_out => gpif_rst
);

u_clk_out : S6CLK2PIN
port map
(
    I => gpif_clk,
    O => IFCLK
);

debug_clock_50_process:
process(CLOCK)
begin
    if rising_edge(CLOCK) then
        if global_reset = '1' then
            LED_1 <= '1';
            debug_clock_50_counter <= 0;
            debug_led_1 <= '0';
        else
            if debug_clock_50_counter = 49 then
                debug_clock_50_counter <= 0;
                debug_led_1 <= not debug_led_1;
            else
                debug_clock_50_counter <= debug_clock_50_counter + 1;
            end if;
            LED_1 <= debug_led_1;
        end if;
    end if;
end process;

debug_clock_100_process:
process(gpif_clk)
begin
    if rising_edge(gpif_clk) then
        if global_reset = '1' then
            LED_2 <= '1';
            debug_clock_100_counter <= 0;
            debug_led_2 <= '0';
        else
            if debug_clock_100_counter = 49 then
                debug_clock_100_counter <= 0;
                debug_led_2 <= not debug_led_2;
            else
                debug_clock_100_counter <= debug_clock_100_counter + 1;
            end if;
            LED_2 <= debug_led_2;
        end if;
    end if;
end process;


LED_3 <= '1';
LED_4 <= '1';
LED_5 <= '1';
LED_6 <= '1';
LED_7 <= '1';
LED_8 <= '1';

----------------------------------------------------------------------------------------------------------------
-- PLL
----------------------------------------------------------------------------------------------------------------
gen_clks_mod : gen_clks
port map
(
    areset => global_reset,
    inclk0 => CLOCK,
    c0     => gpif_clk,
    locked => pll_locked
);

----------------------------------------------------------------------------------------------------------------
-- GPIF-II
----------------------------------------------------------------------------------------------------------------
u_gpif2_slave_fifo32 : gpif2_slave_fifo32
    generic map (
        DATA_RX_FIFO_SIZE => 12,
        DATA_TX_FIFO_SIZE => 12,
        CTRL_RX_FIFO_SIZE => 5,
        CTRL_TX_FIFO_SIZE => 5,

        ADDR_DATA_TX => "00",
        ADDR_DATA_RX => "01",
        ADDR_CTRL_TX => "10",
        ADDR_CTRL_RX => "11"
    )
    port map (
        -- GPIF
        gpif_clk => gpif_clk,
        gpif_rst => gpif_rst,
        gpif_enb => '1',
        gpif_d   => GPIF_D,
        gpif_ctl => GPIF_CTL8 & GPIF_CTL6 & GPIF_CTL5 & GPIF_CTL4,

        sloe    => GPIF_CTL2,
        slrd    => GPIF_CTL3,
        slwr    => GPIF_CTL1,
        slcs    => GPIF_CTL0,
        pktend  => GPIF_CTL7,
        fifoadr => fifoadr,

        -- FIFO clocks
        fifo_clk => gpif_clk,
        fifo_rst => gpif_rst,

        -- TX
        tx_tdata  => open,
        tx_tlast  => open,
        tx_tvalid => open,
        tx_tready => '0',

        -- RX
        rx_tdata  => (others => '0'),
        rx_tlast  => '0',
        rx_tvalid => '0',
        rx_tready => open,

        -- CTRL RX
        ctrl_tdata  => open,
        ctrl_tlast  => open,
        ctrl_tvalid => open,
        ctrl_tready => '0',

        -- CTRL TX
        resp_tdata  => (others => '0'),
        resp_tlast  => '0',
        resp_tvalid => '0',
        resp_tready => open,

        -- Debug
        debug => open
    );

GPIF_CTL11 <= fifoadr(1);
GPIF_CTL12 <= fifoadr(0);






























----------------------------------------------------------------------------------------------------------------
-- UNUSED PINS DRIVEN
----------------------------------------------------------------------------------------------------------------
PIN_A20 <= '0';
PIN_A19 <= '0';
PIN_A18 <= '0';
--PIN_A17 <= '0';
--PIN_A16 <= '0';
PIN_A15 <= '0';
--PIN_A14 <= '0';
--PIN_A13 <= '0';
--PIN_A10 <= '0';
--PIN_A9  <= '0';
--PIN_A8  <= '0';
--PIN_A7  <= '0';
--PIN_A6  <= '0';
--PIN_A5  <= '0';
--PIN_C3  <= '0';
--PIN_A4  <= '0';
PIN_A3  <= '0';
--PIN_B2  <= '0';
PIN_C2  <= '0';
PIN_D2  <= '0';
PIN_F2  <= '0';
PIN_H2  <= '0';
PIN_J2  <= '0';
PIN_M2  <= '0';
PIN_N2  <= '0';
PIN_P2  <= '0';
PIN_R2  <= '0';

PIN_B20 <= '0';
PIN_B19 <= '0';
PIN_B18 <= '0';
--PIN_B17 <= '0';
--PIN_B16 <= '0';
--PIN_B15 <= '0';
--PIN_B14 <= '0';
--PIN_B13 <= '0';
--PIN_B10 <= '0';
--PIN_B9  <= '0';
--PIN_B8  <= '0';
--PIN_B7  <= '0';
--PIN_B6  <= '0';
--PIN_B5  <= '0';
--PIN_C4  <= '0';
--PIN_B4  <= '0';
--PIN_B3  <= '0';
--PIN_B1  <= '0';
--PIN_C1  <= '0';
PIN_E1  <= '0';
PIN_F1  <= '0';
PIN_H1  <= '0';
PIN_J1  <= '0';
PIN_M1  <= '0';
PIN_N1  <= '0';
PIN_P1  <= '0';
PIN_R1  <= '0';

PIN_M19  <= '0';
--PIN_N19  <= '0';
PIN_B21  <= '0';
PIN_C21  <= '0';
PIN_D21  <= '0';
PIN_E21  <= '0';
PIN_F21  <= '0';
PIN_H21  <= '0';
PIN_J21  <= '0';
PIN_K21  <= '0';
PIN_L21  <= '0';
PIN_M21  <= '0';
PIN_N21  <= '0';
PIN_P21  <= '0';
PIN_R21  <= '0';
PIN_U21  <= '0';
PIN_V21  <= '0';
PIN_W21  <= '0';
PIN_Y21  <= '0';
PIN_AB20 <= '0';
PIN_AB19 <= '0';
PIN_AB18 <= '0';
PIN_AB17 <= '0';
PIN_AB16 <= '0';
PIN_AB15 <= '0';
PIN_AB14 <= '0';
PIN_AB13 <= '0';

PIN_M20  <= '0';
PIN_N20  <= '0';
--PIN_B22  <= '0';
--PIN_C22  <= '0';
--PIN_D22  <= '0';
--PIN_E22  <= '0';
PIN_F22  <= '0';
--PIN_H22  <= '0';
--PIN_J22  <= '0';
--PIN_K22  <= '0';
--PIN_L22  <= '0';
--PIN_M22  <= '0';
--PIN_N22  <= '0';
--PIN_P22  <= '0';
--PIN_R22  <= '0';
--PIN_U22  <= '0';
--PIN_V22  <= '0';
--PIN_W22  <= '0';
--PIN_Y22  <= '0';
PIN_AA20 <= '0';
PIN_AA19 <= '0';
PIN_AA18 <= '0';
PIN_AA17 <= '0';
PIN_AA16 <= '0';
PIN_AA15 <= '0';
PIN_AA14 <= '0';
PIN_AA13 <= '0';

end rtl;
