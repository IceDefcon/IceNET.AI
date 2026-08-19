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

type GPIF_STATE_TYPE is
(
    GPIF_IDLE,
    GPIF_WAIT,
    GPIF_THINK,
    GPIF_READ,
    GPIF_READ_FLUSH,
    GPIF_READ_SINGLE
);

signal gpif_state : GPIF_STATE_TYPE := GPIF_IDLE;

-- FX3 flags. With the B200/Ettus wiring:
-- GPIF_CTL(0) = GPIF_CTL4 = READY / FLAGA
-- GPIF_CTL(1) = GPIF_CTL5 = WATERMARK / FLAGB
signal fx3_ready  : std_logic := '0';
signal fx3_ready1 : std_logic := '0';
signal fx3_wmark  : std_logic := '0';
signal fx3_wmark1 : std_logic := '0';

-- Read strobe pipeline. This follows the timing style used by the Ettus GPIF controller.
signal slrd_int : std_logic := '1';
signal slrd1    : std_logic := '1';
signal slrd2    : std_logic := '1';
signal slrd3    : std_logic := '1';
signal slrd4    : std_logic := '1';
signal slrd5    : std_logic := '1';

signal sloe_int : std_logic := '1';

signal wait_counter : unsigned(2 downto 0) := (others => '0');
signal first_read   : std_logic := '0';

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
    "0011" when GPIF_READ,
    "0100" when GPIF_READ_FLUSH,
    "0101" when GPIF_READ_SINGLE,
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
-- Read Strobe Pipeline
----------------------------------------------------------------------------------------------------------------

slrd_pipeline_process:
process(GPIF_CLK)
begin
    if rising_edge(GPIF_CLK) then
        if GPIF_RST = '1' then
            slrd1 <= '1';
            slrd2 <= '1';
            slrd3 <= '1';
            slrd4 <= '1';
            slrd5 <= '1';
        else
            slrd1 <= slrd_int;
            slrd2 <= slrd1;
            slrd3 <= slrd2;
            slrd4 <= slrd3;
            slrd5 <= slrd4;
        end if;
    end if;
end process;

----------------------------------------------------------------------------------------------------------------
-- Debug Data Register
----------------------------------------------------------------------------------------------------------------
--
-- No FIFO is used.
-- Every accepted 32-bit GPIF word overwrites DEBUG_DATA.
-- DEBUG_VALID pulses for one GPIF_CLK cycle for each captured word.
-- DEBUG_COUNTER increments for every captured word.
--
----------------------------------------------------------------------------------------------------------------

debug_receive_process:
process(GPIF_CLK)
begin
    if rising_edge(GPIF_CLK) then
        if GPIF_RST = '1' then
            debug_data_reg    <= (others => '0');
            debug_valid_reg   <= '0';
            debug_counter_reg <= (others => '0');
        else
            debug_valid_reg <= '0';

            -- The data bus is sampled two clocks after SLRD# assertion,
            -- matching the read-strobe pipeline used by the Ettus controller.
            if slrd2 = '0' then
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
-- This controller services only ADDR_DATA_TX.
-- It never stores data in a FIFO and never applies backpressure.
-- The most recently received 32-bit word is simply retained in DEBUG_DATA.
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
            first_read   <= '0';

        elsif GPIF_ENB = '0' then
            gpif_state   <= GPIF_IDLE;
            sloe_int     <= '1';
            slrd_int     <= '1';
            wait_counter <= (others => '0');
            first_read   <= '0';

        else
            case gpif_state is

                --------------------------------------------------------------------------------------------------------
                -- Idle
                --------------------------------------------------------------------------------------------------------
                when GPIF_IDLE =>
                    sloe_int     <= '1';
                    slrd_int     <= '1';
                    wait_counter <= (others => '0');
                    first_read   <= '0';

                    -- FIFOADR is fixed, but allow the FX3 address/flags time to settle.
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
                -- Decide whether a read can start
                --------------------------------------------------------------------------------------------------------
                when GPIF_THINK =>
                    wait_counter <= (others => '0');

                    if fx3_ready1 = '1' and fx3_wmark1 = '1' then
                        -- Burst read.
                        sloe_int   <= '0';
                        slrd_int   <= '0';
                        first_read <= '1';
                        gpif_state <= GPIF_READ;

                    elsif fx3_ready1 = '1' and fx3_wmark1 = '0' then
                        -- Less than a watermark of data remains. Read one beat,
                        -- wait for READY to update, then decide whether another beat exists.
                        sloe_int     <= '0';
                        slrd_int     <= '0';
                        wait_counter <= (others => '0');
                        gpif_state   <= GPIF_READ_SINGLE;

                    else
                        -- No data currently available from the selected FX3 thread.
                        sloe_int   <= '1';
                        slrd_int   <= '1';
                        gpif_state <= GPIF_THINK;
                    end if;

                --------------------------------------------------------------------------------------------------------
                -- Continuous burst read
                --------------------------------------------------------------------------------------------------------
                when GPIF_READ =>
                    sloe_int <= '0';

                    if fx3_wmark1 = '0' then
                        -- Watermark says the end of the available burst is approaching.
                        slrd_int   <= '1';
                        gpif_state <= GPIF_READ_FLUSH;
                    else
                        slrd_int <= '0';
                    end if;

                    if slrd3 = '0' then
                        first_read <= '0';
                    end if;

                --------------------------------------------------------------------------------------------------------
                -- Drain the read pipeline before releasing GPIF_D
                --------------------------------------------------------------------------------------------------------
                when GPIF_READ_FLUSH =>
                    sloe_int <= '0';
                    slrd_int <= '1';

                    if slrd3 = '0' then
                        first_read <= '0';
                    end if;

                    if first_read = '0' and slrd3 = '1' then
                        sloe_int   <= '1';
                        gpif_state <= GPIF_IDLE;
                    end if;

                --------------------------------------------------------------------------------------------------------
                -- Single-word read path used when READY=1 but WATERMARK=0
                --------------------------------------------------------------------------------------------------------
                when GPIF_READ_SINGLE =>
                    sloe_int <= '0';

                    if wait_counter = "000" then
                        -- The read strobe was asserted when entering this state.
                        -- Deassert it after one GPIF clock.
                        slrd_int     <= '1';
                        wait_counter <= wait_counter + 1;

                    elsif wait_counter = "101" then
                        -- By now the READY flag has had time to reflect the previous read.
                        if fx3_ready1 = '0' then
                            sloe_int     <= '1';
                            slrd_int     <= '1';
                            wait_counter <= (others => '0');
                            gpif_state   <= GPIF_IDLE;
                        else
                            -- Another word remains. Generate another one-cycle SLRD# pulse.
                            slrd_int     <= '0';
                            wait_counter <= (others => '0');
                        end if;

                    else
                        slrd_int     <= '1';
                        wait_counter <= wait_counter + 1;
                    end if;

                when others =>
                    gpif_state <= GPIF_IDLE;
                    sloe_int   <= '1';
                    slrd_int   <= '1';

            end case;
        end if;
    end if;
end process;

end architecture rtl;
