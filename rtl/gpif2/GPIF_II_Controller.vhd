library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity GPIF_II_Controller is
    generic
    (
        ADDR_DATA_TX : std_logic_vector(1 downto 0) := "00"
    );
    port
    (
        ----------------------------------------------------------------------------------------------------------------
        -- GPIF-II Interface
        ----------------------------------------------------------------------------------------------------------------
        GPIF_CLK : in  std_logic;
        GPIF_RST : in  std_logic;
        GPIF_ENB : in  std_logic;

        GPIF_D   : inout std_logic_vector(31 downto 0);
        GPIF_CTL : in    std_logic_vector(3 downto 0);

        SLOE     : out std_logic;
        SLRD     : out std_logic;
        SLWR     : out std_logic;
        SLCS     : out std_logic;
        PKTEND   : out std_logic;
        FIFOADR  : out std_logic_vector(1 downto 0);

        ----------------------------------------------------------------------------------------------------------------
        -- SignalTap Debug
        ----------------------------------------------------------------------------------------------------------------
        DEBUG_DATA    : out std_logic_vector(31 downto 0);
        DEBUG_VALID   : out std_logic;
        DEBUG_COUNTER : out std_logic_vector(31 downto 0);
        DEBUG_READY   : out std_logic;
        DEBUG_WMARK   : out std_logic;
        DEBUG_STATE   : out std_logic_vector(3 downto 0)
    );
end entity GPIF_II_Controller;

architecture rtl of GPIF_II_Controller is

----------------------------------------------------------------------------------------------------------------
-- Constants, Types and Signals
----------------------------------------------------------------------------------------------------------------

-- This controller is an x32 GPIF-II slave-FIFO reader. The FX3 firmware
-- and FPGA pin assignments must therefore also use DQ[31:0].

type GPIF_STATE_TYPE is
(
    GPIF_IDLE,
    GPIF_WAIT,
    GPIF_THINK,
    GPIF_READ_SETUP,
    GPIF_READ,
    GPIF_READ_RECOVERY
);

signal gpif_state : GPIF_STATE_TYPE := GPIF_IDLE;

-- FX3 flags. With the B200/Ettus wiring:
-- GPIF_CTL(0) = GPIF_CTL4 = READY / FLAGA
-- GPIF_CTL(1) = GPIF_CTL5 = WATERMARK / FLAGB
signal fx3_ready  : std_logic := '0';
signal fx3_ready1 : std_logic := '0';
signal fx3_wmark  : std_logic := '0';
signal fx3_wmark1 : std_logic := '0';

signal slrd_int : std_logic := '1';
signal sloe_int : std_logic := '1';

signal wait_counter : unsigned(2 downto 0) := (others => '0');

-- FX3 synchronous Slave FIFO read latency is exactly two PCLK cycles.
signal read_valid_pipeline : std_logic_vector(1 downto 0) := (others => '0');

signal debug_data_reg    : std_logic_vector(31 downto 0) := (others => '0');
signal debug_valid_reg   : std_logic := '0';
signal debug_counter_reg : unsigned(31 downto 0) := (others => '0');

begin

----------------------------------------------------------------------------------------------------------------
-- Fixed Receive-Only GPIF Outputs
----------------------------------------------------------------------------------------------------------------

-- This debug controller receives only from the FX3.
-- The FPGA therefore never drives GPIF_D.
GPIF_D <= (others => 'Z');

-- Select only the DATA_TX thread used for FX3/Host -> FPGA data.
FIFOADR <= ADDR_DATA_TX;

-- GPIF slave FIFO is always selected.
SLCS <= '0';

-- No FPGA -> FX3 writes are performed by this debug controller.
SLWR   <= '1';
PKTEND <= '1';

SLOE <= sloe_int;
SLRD <= slrd_int;

----------------------------------------------------------------------------------------------------------------
-- Debug Outputs
----------------------------------------------------------------------------------------------------------------

DEBUG_DATA    <= debug_data_reg;
DEBUG_VALID   <= debug_valid_reg;
DEBUG_COUNTER <= std_logic_vector(debug_counter_reg);
DEBUG_READY   <= fx3_ready1;
DEBUG_WMARK   <= fx3_wmark1;

with gpif_state select DEBUG_STATE <=
    "0000" when GPIF_IDLE,
    "0001" when GPIF_WAIT,
    "0010" when GPIF_THINK,
    "0011" when GPIF_READ_SETUP,
    "0100" when GPIF_READ,
    "0101" when GPIF_READ_RECOVERY,
    "1111" when others;

----------------------------------------------------------------------------------------------------------------
-- FX3 Flag Synchronization
----------------------------------------------------------------------------------------------------------------

fx3_flag_process:
process(GPIF_CLK)
begin
    if rising_edge(GPIF_CLK) then
        if GPIF_RST = '1' then
            fx3_ready  <= '0';
            fx3_ready1 <= '0';
            fx3_wmark  <= '0';
            fx3_wmark1 <= '0';
        else
            fx3_ready  <= GPIF_CTL(0);
            fx3_ready1 <= fx3_ready;

            fx3_wmark  <= GPIF_CTL(1);
            fx3_wmark1 <= fx3_wmark;
        end if;
    end if;
end process;

----------------------------------------------------------------------------------------------------------------
-- Read Valid Pipeline And Debug Data Register
----------------------------------------------------------------------------------------------------------------
--
-- No FIFO is used.
-- Every accepted 32-bit GPIF word overwrites DEBUG_DATA.
-- DEBUG_VALID pulses for one GPIF_CLK cycle for each captured word.
-- DEBUG_COUNTER increments for every captured 32-bit word.
--
-- According to the FX3 synchronous Slave FIFO timing specification,
-- valid data appears exactly two PCLK cycles after the rising edge
-- on which SLRD# is sampled active.
--
----------------------------------------------------------------------------------------------------------------

debug_receive_process:
process(GPIF_CLK)
begin
    if rising_edge(GPIF_CLK) then
        if GPIF_RST = '1' then
            read_valid_pipeline <= (others => '0');

            debug_data_reg    <= (others => '0');
            debug_valid_reg   <= '0';
            debug_counter_reg <= (others => '0');
        else
            ----------------------------------------------------------------------------------------------------------------
            -- Shift the read request through the two-clock
            -- FX3 Slave FIFO read-latency pipeline.
            ----------------------------------------------------------------------------------------------------------------
            read_valid_pipeline(0) <= '0';
            read_valid_pipeline(1) <= read_valid_pipeline(0);
            ----------------------------------------------------------------------------------------------------------------
            -- Register a read request on the rising edge where
            -- the FX3 observes SLRD# asserted.
            ----------------------------------------------------------------------------------------------------------------
            if sloe_int = '0'
            and slrd_int = '0' then
                read_valid_pipeline(0) <= '1';
            end if;

            debug_valid_reg <= '0';
            ----------------------------------------------------------------------------------------------------------------
            -- Capture GPIF_D exactly two GPIF_CLK cycles after
            -- the corresponding SLRD# read request.
            --
            -- Do not check the current READY flag here. READY
            -- may already be low after the last word was read,
            -- while that final word is still moving through the
            -- two-clock output pipeline.
            ----------------------------------------------------------------------------------------------------------------
            if read_valid_pipeline(1) = '1' then
                debug_data_reg    <= GPIF_D;
                debug_valid_reg   <= '1';
                debug_counter_reg <= debug_counter_reg + 1;
            end if;
        end if;
    end if;
end process;

----------------------------------------------------------------------------------------------------------------
-- Receive-Only GPIF State Machine
----------------------------------------------------------------------------------------------------------------
--
-- The controller performs conservative single-word reads:
--
-- 1. Wait for READY.
-- 2. Assert SLOE# one clock before SLRD#.
-- 3. Assert SLRD# for exactly one GPIF clock.
-- 4. Keep SLOE# asserted while the data propagates.
-- 5. Capture data two GPIF clocks after the read request.
-- 6. Wait for the FX3 flags to update before reading again.
--
-- This controller is intended for initial GPIF debugging. It prioritizes
-- reliable transfers over maximum GPIF throughput.
--
----------------------------------------------------------------------------------------------------------------

gpif_state_process:
process(GPIF_CLK)
begin
    if rising_edge(GPIF_CLK) then
        if GPIF_RST = '1' then
            gpif_state   <= GPIF_IDLE;
            sloe_int     <= '1';
            slrd_int     <= '1';
            wait_counter <= (others => '0');

        elsif GPIF_ENB = '0' then
            gpif_state   <= GPIF_IDLE;
            sloe_int     <= '1';
            slrd_int     <= '1';
            wait_counter <= (others => '0');

        else
            case gpif_state is

                --------------------------------------------------------------------------------------------------------
                -- Idle
                --------------------------------------------------------------------------------------------------------
                when GPIF_IDLE =>
                    sloe_int     <= '1';
                    slrd_int     <= '1';
                    wait_counter <= (others => '0');

                    -- FIFOADR is fixed, but allow the address and FX3 flags
                    -- time to settle before checking READY.
                    gpif_state <= GPIF_WAIT;

                --------------------------------------------------------------------------------------------------------
                -- Wait for FIFO address and FX3 flags to settle
                --------------------------------------------------------------------------------------------------------
                when GPIF_WAIT =>
                    sloe_int <= '1';
                    slrd_int <= '1';

                    if wait_counter = "111" then
                        wait_counter <= (others => '0');
                        gpif_state   <= GPIF_THINK;
                    else
                        wait_counter <= wait_counter + 1;
                    end if;

                --------------------------------------------------------------------------------------------------------
                -- Check whether the selected FX3 thread contains data
                --------------------------------------------------------------------------------------------------------
                when GPIF_THINK =>
                    sloe_int     <= '1';
                    slrd_int     <= '1';
                    wait_counter <= (others => '0');

                    if fx3_ready1 = '1' then
                        -- Enable the FX3 data bus before asserting SLRD#.
                        sloe_int   <= '0';
                        gpif_state <= GPIF_READ_SETUP;
                    else
                        gpif_state <= GPIF_THINK;
                    end if;

                --------------------------------------------------------------------------------------------------------
                -- Allow one clock for FX3 to drive GPIF_D
                --------------------------------------------------------------------------------------------------------
                when GPIF_READ_SETUP =>
                    sloe_int <= '0';
                    slrd_int <= '0';

                    -- SLRD# becomes active after this GPIF clock edge.
                    -- FX3 samples it on the following rising edge.
                    gpif_state <= GPIF_READ;

                --------------------------------------------------------------------------------------------------------
                -- FX3 accepts one read request
                --------------------------------------------------------------------------------------------------------
                when GPIF_READ =>
                    sloe_int     <= '0';
                    slrd_int     <= '1';
                    wait_counter <= (others => '0');

                    -- The read request enters read_valid_pipeline here.
                    -- GPIF_D will be captured two GPIF clocks later.
                    gpif_state <= GPIF_READ_RECOVERY;

                --------------------------------------------------------------------------------------------------------
                -- Keep SLOE# active while data propagates
                --------------------------------------------------------------------------------------------------------
                when GPIF_READ_RECOVERY =>
                    sloe_int <= '0';
                    slrd_int <= '1';

                    -- Five recovery clocks are sufficient for:
                    -- 1. The two-clock FX3 read latency.
                    -- 2. DEBUG_DATA capture.
                    -- 3. READY/WATERMARK flag propagation.
                    if wait_counter = "101" then
                        wait_counter <= (others => '0');
                        sloe_int     <= '1';
                        gpif_state   <= GPIF_THINK;
                    else
                        wait_counter <= wait_counter + 1;
                    end if;

                when others =>
                    gpif_state   <= GPIF_IDLE;
                    sloe_int     <= '1';
                    slrd_int     <= '1';
                    wait_counter <= (others => '0');

            end case;
        end if;
    end if;
end process;

end architecture rtl;
