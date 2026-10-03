library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity GPIF_II_Controller is
    generic
    (
        -- USB EP1 OUT is configured on FX3 GPIF thread 3.
        -- With the two-address Slave FIFO interface:
        --
        --   thread 3 = FIFOADR "11"
        --
        ADDR_DATA_TX : std_logic_vector(1 downto 0) := "11"
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

------------------------------------------------------------------------------------------------------------------------
-- State Machine
------------------------------------------------------------------------------------------------------------------------
--
-- This is the receive side of the Ettus gpif2_slave_fifo32 state machine.
--
-- Implemented Ettus states:
--
--   STATE_IDLE         -> GPIF_IDLE
--   STATE_WAIT         -> GPIF_WAIT
--   STATE_THINK        -> GPIF_THINK
--   STATE_READ         -> GPIF_READ
--   STATE_READ_FLUSH   -> GPIF_READ_FLUSH
--   STATE_READ_SINGLE  -> GPIF_READ_SINGLE
--
-- Write states are intentionally omitted because this controller is RX only.
--
------------------------------------------------------------------------------------------------------------------------

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

------------------------------------------------------------------------------------------------------------------------
-- FX3 Flags
------------------------------------------------------------------------------------------------------------------------
--
-- Top-level mapping:
--
--   GPIF_CTL(3) = physical CTL8 = FLAGD = thread-3 watermark
--   GPIF_CTL(2) = physical CTL6 = FLAGC = thread-3 ready / not-empty
--   GPIF_CTL(1) = physical CTL5 = FLAGB
--   GPIF_CTL(0) = physical CTL4 = FLAGA
--
-- This controller permanently selects thread 3, therefore:
--
--   READY = GPIF_CTL(2)
--   WMARK = GPIF_CTL(3)
--
-- The flags are double registered in the same manner as Ettus.
--
------------------------------------------------------------------------------------------------------------------------

signal fx3_ready  : std_logic := '0';
signal fx3_ready1 : std_logic := '0';

signal fx3_wmark  : std_logic := '0';
signal fx3_wmark1 : std_logic := '0';

------------------------------------------------------------------------------------------------------------------------
-- GPIF Control
------------------------------------------------------------------------------------------------------------------------

signal slrd_int : std_logic := '1';
signal sloe_int : std_logic := '1';

------------------------------------------------------------------------------------------------------------------------
-- State Counter
------------------------------------------------------------------------------------------------------------------------

signal idle_cycles : unsigned(2 downto 0) := (others => '0');

------------------------------------------------------------------------------------------------------------------------
-- Read Pipeline
------------------------------------------------------------------------------------------------------------------------
--
-- Direct equivalent of the Ettus SLRD pipeline:
--
--   slrd -> slrd1 -> slrd2 -> slrd3 -> slrd4 -> slrd5
--
-- Ettus uses:
--
--   slrd2 : capture GPIF_D
--   slrd3 : burst data valid
--   slrd5 : single-read data valid
--
------------------------------------------------------------------------------------------------------------------------

signal slrd1 : std_logic := '1';
signal slrd2 : std_logic := '1';
signal slrd3 : std_logic := '1';
signal slrd4 : std_logic := '1';
signal slrd5 : std_logic := '1';

------------------------------------------------------------------------------------------------------------------------
-- Read State Tracking
------------------------------------------------------------------------------------------------------------------------

signal first_read : std_logic := '0';

------------------------------------------------------------------------------------------------------------------------
-- GPIF Input Register
------------------------------------------------------------------------------------------------------------------------

signal gpif_data_in : std_logic_vector(31 downto 0) := (others => '0');

------------------------------------------------------------------------------------------------------------------------
-- Debug
------------------------------------------------------------------------------------------------------------------------

signal debug_data_reg    : std_logic_vector(31 downto 0) := (others => '0');
signal debug_valid_reg   : std_logic := '0';
signal debug_counter_reg : unsigned(31 downto 0) := (others => '0');

begin

------------------------------------------------------------------------------------------------------------------------
-- Fixed Receive-Only GPIF Outputs
------------------------------------------------------------------------------------------------------------------------
--
-- FPGA never drives GPIF_D.
--
-- FX3 owns GPIF_D while SLOE# is active.
--
------------------------------------------------------------------------------------------------------------------------

GPIF_D <= (others => 'Z');

------------------------------------------------------------------------------------------------------------------------
-- Permanently Select FX3 Thread 3
------------------------------------------------------------------------------------------------------------------------

FIFOADR <= ADDR_DATA_TX;

------------------------------------------------------------------------------------------------------------------------
-- GPIF Slave FIFO Always Selected
------------------------------------------------------------------------------------------------------------------------

SLCS <= '0';

------------------------------------------------------------------------------------------------------------------------
-- No FPGA -> FX3 Writes
------------------------------------------------------------------------------------------------------------------------

SLWR   <= '1';
PKTEND <= '1';

------------------------------------------------------------------------------------------------------------------------
-- Read Controls
------------------------------------------------------------------------------------------------------------------------

SLOE <= sloe_int;
SLRD <= slrd_int;

------------------------------------------------------------------------------------------------------------------------
-- Debug Outputs
------------------------------------------------------------------------------------------------------------------------

DEBUG_DATA    <= debug_data_reg;
DEBUG_VALID   <= debug_valid_reg;
DEBUG_COUNTER <= std_logic_vector(debug_counter_reg);

DEBUG_READY <= fx3_ready1;
DEBUG_WMARK <= fx3_wmark1;

with gpif_state select DEBUG_STATE <=
    "0000" when GPIF_IDLE,
    "0001" when GPIF_WAIT,
    "0010" when GPIF_THINK,
    "0011" when GPIF_READ,
    "0100" when GPIF_READ_FLUSH,
    "0101" when GPIF_READ_SINGLE,
    "1111" when others;

------------------------------------------------------------------------------------------------------------------------
-- FX3 Flag Synchronization
------------------------------------------------------------------------------------------------------------------------
--
-- Ettus performs two register stages:
--
--   gpif_ctl -> fx3_ready -> fx3_ready1
--   gpif_ctl -> fx3_wmark -> fx3_wmark1
--
-- The first stage would normally be placed close to the IO cell.
--
------------------------------------------------------------------------------------------------------------------------

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

            fx3_ready  <= GPIF_CTL(2);
            fx3_ready1 <= fx3_ready;

            fx3_wmark  <= GPIF_CTL(3);
            fx3_wmark1 <= fx3_wmark;

        end if;

    end if;
end process;

------------------------------------------------------------------------------------------------------------------------
-- SLRD Pipeline
------------------------------------------------------------------------------------------------------------------------
--
-- Direct translation of:
--
--   slrd1 <= slrd;
--   slrd2 <= slrd1;
--   slrd3 <= slrd2;
--   slrd4 <= slrd3;
--   slrd5 <= slrd4;
--
------------------------------------------------------------------------------------------------------------------------

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

------------------------------------------------------------------------------------------------------------------------
-- GPIF Data Capture
------------------------------------------------------------------------------------------------------------------------
--
-- Direct Ettus equivalent:
--
--   always @(posedge gpif_clk)
--       if (~slrd2)
--           gpif_data_in <= gpif_d;
--
-- IMPORTANT:
--
-- GPIF_D is NOT sampled directly from SLRD.
--
-- The read request propagates through the SLRD pipeline first.
--
------------------------------------------------------------------------------------------------------------------------

gpif_data_capture_process:
process(GPIF_CLK)
begin
    if rising_edge(GPIF_CLK) then

        if GPIF_RST = '1' then

            gpif_data_in <= (others => '0');

        else

            if slrd2 = '0' then
                gpif_data_in <= GPIF_D;
            end if;

        end if;

    end if;
end process;

------------------------------------------------------------------------------------------------------------------------
-- Received Data Valid / Debug Capture
------------------------------------------------------------------------------------------------------------------------
--
-- Keep the data-capture point and the data-valid point separate, exactly as in
-- the Ettus read path:
--
--   slrd2 = '0'
--       -> GPIF_D is captured into gpif_data_in by gpif_data_capture_process.
--
-- Burst read valid:
--
--   ((GPIF_READ or GPIF_READ_FLUSH) and slrd3 = '0')
--
-- Single read valid:
--
--   (GPIF_READ_SINGLE and slrd5 = '0')
--
-- Therefore DEBUG_VALID is deliberately delayed relative to the raw GPIF_D bus.
-- When DEBUG_VALID = '1', DEBUG_DATA contains the previously captured
-- gpif_data_in word; the raw GPIF_D bus may already contain another value.
--
-- Since there is no FIFO in this controller, every valid received word simply
-- overwrites DEBUG_DATA and increments DEBUG_COUNTER.
--
------------------------------------------------------------------------------------------------------------------------

debug_receive_process:
process(GPIF_CLK)
begin
    if rising_edge(GPIF_CLK) then

        if GPIF_RST = '1' then

            debug_data_reg    <= (others => '0');
            debug_valid_reg   <= '0';
            debug_counter_reg <= (others => '0');

        else

            -- Default: no newly completed GPIF word this clock.
            debug_valid_reg <= '0';

            ----------------------------------------------------------------------------------------------------------------
            -- Burst Read
            ----------------------------------------------------------------------------------------------------------------
            --
            -- Ettus uses slrd3 for the burst-valid timing. gpif_data_in was
            -- captured one pipeline stage earlier when slrd2 = '0'.
            --
            if (((gpif_state = GPIF_READ) or
                 (gpif_state = GPIF_READ_FLUSH)) and
                (slrd3 = '0')) then

                debug_data_reg    <= gpif_data_in;
                debug_valid_reg   <= '1';
                debug_counter_reg <= debug_counter_reg + 1;

            ----------------------------------------------------------------------------------------------------------------
            -- Single-Word Read
            ----------------------------------------------------------------------------------------------------------------
            --
            -- Ettus keeps the captured word in gpif_data_in until the READY
            -- flag has had time to update. slrd3 is therefore used as the
            -- single-read valid indication.
            --
            elsif ((gpif_state = GPIF_READ_SINGLE) and
                   (slrd3 = '0')) then

                debug_data_reg    <= gpif_data_in;
                debug_valid_reg   <= '1';
                debug_counter_reg <= debug_counter_reg + 1;

            end if;

        end if;

    end if;
end process;

------------------------------------------------------------------------------------------------------------------------
-- GPIF Read State Machine
------------------------------------------------------------------------------------------------------------------------
--
-- This follows the Ettus read-side behavior.
--
-- There is intentionally no local FIFO backpressure.
--
-- Therefore:
--
--   local_fifo_ready = TRUE
--   read_ready_go    = TRUE
--   fifo_nearly_full = FALSE
--
-- This is valid because DEBUG_DATA can accept/overwrite one word every clock.
--
------------------------------------------------------------------------------------------------------------------------

gpif_state_process:
process(GPIF_CLK)
begin
    if rising_edge(GPIF_CLK) then

        if GPIF_RST = '1' then

            gpif_state   <= GPIF_IDLE;

            sloe_int     <= '1';
            slrd_int     <= '1';

            idle_cycles  <= (others => '0');

            first_read   <= '0';

        elsif GPIF_ENB = '0' then

            gpif_state   <= GPIF_IDLE;

            sloe_int     <= '1';
            slrd_int     <= '1';

            idle_cycles  <= (others => '0');

            first_read   <= '0';

        else

            case gpif_state is

                ----------------------------------------------------------------------------------------------------------------
                -- IDLE
                ----------------------------------------------------------------------------------------------------------------
                --
                -- Ettus:
                --
                --   sloe      <= 1;
                --   slrd      <= 1;
                --   fifoadr   <= next_addr;
                --   state     <= STATE_WAIT;
                --   idle      <= 0;
                --   first_read <= 0;
                --
                -- FIFOADR is fixed in this implementation.
                --
                ----------------------------------------------------------------------------------------------------------------

                when GPIF_IDLE =>

                    sloe_int    <= '1';
                    slrd_int    <= '1';

                    idle_cycles <= (others => '0');

                    first_read  <= '0';

                    gpif_state  <= GPIF_WAIT;

                ----------------------------------------------------------------------------------------------------------------
                -- WAIT
                ----------------------------------------------------------------------------------------------------------------
                --
                -- Ettus waits eight GPIF clocks after selecting an address.
                --
                -- This allows:
                --
                --   FIFOADR
                --      ->
                --   FX3
                --      ->
                --   READY / WMARK
                --      ->
                --   FPGA input registers
                --
                -- to settle.
                --
                -- Our FIFOADR is fixed, but the delay is intentionally retained
                -- to preserve the Ettus sequencing.
                --
                ----------------------------------------------------------------------------------------------------------------

                when GPIF_WAIT =>

                    sloe_int <= '1';
                    slrd_int <= '1';

                    if idle_cycles = "111" then

                        idle_cycles <= (others => '0');
                        gpif_state  <= GPIF_THINK;

                    else

                        idle_cycles <= idle_cycles + 1;

                    end if;

                ----------------------------------------------------------------------------------------------------------------
                -- THINK
                ----------------------------------------------------------------------------------------------------------------
                --
                -- Ettus decision:
                --
                -- READY=1 and WMARK=1
                --     -> burst read
                --
                -- READY=1 and WMARK=0
                --     -> single-word read
                --
                -- READY=0
                --     -> return to idle
                --
                ----------------------------------------------------------------------------------------------------------------

                when GPIF_THINK =>

                    idle_cycles <= (others => '0');

                    ----------------------------------------------------------------------------------------------------------------
                    -- Burst Read
                    ----------------------------------------------------------------------------------------------------------------

                    if (fx3_ready1 = '1') and
                       (fx3_wmark1 = '1') then

                        gpif_state <= GPIF_READ;

                        slrd_int   <= '0';
                        sloe_int   <= '0';

                        first_read <= '1';

                    ----------------------------------------------------------------------------------------------------------------
                    -- Single Read
                    ----------------------------------------------------------------------------------------------------------------

                    elsif (fx3_ready1 = '1') and
                          (fx3_wmark1 = '0') then

                        gpif_state <= GPIF_READ_SINGLE;

                        slrd_int   <= '0';
                        sloe_int   <= '0';

                    ----------------------------------------------------------------------------------------------------------------
                    -- Nothing Available
                    ----------------------------------------------------------------------------------------------------------------

                    else

                        gpif_state <= GPIF_IDLE;

                    end if;

                ----------------------------------------------------------------------------------------------------------------
                -- READ
                ----------------------------------------------------------------------------------------------------------------
                --
                -- Continuous burst.
                --
                -- SLRD# remains asserted every GPIF clock.
                --
                -- One 32-bit transfer can therefore be requested every GPIF_CLK.
                --
                -- Ettus exits the burst when:
                --
                --   WMARK becomes LOW
                --
                -- or:
                --
                --   local FIFO becomes nearly full.
                --
                -- There is no local FIFO here, therefore WMARK is the only
                -- burst termination condition.
                --
                ----------------------------------------------------------------------------------------------------------------

                when GPIF_READ =>

                    ----------------------------------------------------------------------------------------------------------------
                    -- Watermark Dropped
                    ----------------------------------------------------------------------------------------------------------------

                    if fx3_wmark1 = '0' then

                        slrd_int  <= '1';
                        gpif_state <= GPIF_READ_FLUSH;

                    ----------------------------------------------------------------------------------------------------------------
                    -- Continue Burst
                    ----------------------------------------------------------------------------------------------------------------

                    else

                        slrd_int <= '0';

                    end if;

                    ----------------------------------------------------------------------------------------------------------------
                    -- Read Request Has Reached Pipeline
                    ----------------------------------------------------------------------------------------------------------------

                    if slrd3 = '0' then
                        first_read <= '0';
                    end if;

                ----------------------------------------------------------------------------------------------------------------
                -- READ FLUSH
                ----------------------------------------------------------------------------------------------------------------
                --
                -- SLRD# has already been deasserted.
                --
                -- However, reads already launched into the FX3/GPIF pipeline are
                -- still arriving.
                --
                -- This state MUST therefore remain active until slrd3 returns HIGH.
                --
                -- This is one of the most important pieces of the Ettus implementation.
                --
                ----------------------------------------------------------------------------------------------------------------

                when GPIF_READ_FLUSH =>

                    slrd_int <= '1';

                    ----------------------------------------------------------------------------------------------------------------
                    -- Once At Least One Read Reached Pipeline
                    ----------------------------------------------------------------------------------------------------------------

                    if slrd3 = '0' then
                        first_read <= '0';
                    end if;

                    ----------------------------------------------------------------------------------------------------------------
                    -- Pipeline Empty
                    ----------------------------------------------------------------------------------------------------------------

                    if (first_read = '0') and
                       (slrd3 = '1') then

                        gpif_state <= GPIF_IDLE;

                        sloe_int   <= '1';

                    end if;

                ----------------------------------------------------------------------------------------------------------------
                -- READ SINGLE
                ----------------------------------------------------------------------------------------------------------------
                --
                -- Direct translation of Ettus STATE_READ_SINGLE.
                --
                -- Used when:
                --
                --   READY = 1
                --   WMARK = 0
                --
                -- This means there is less than the watermark quantity remaining
                -- in the current FX3 DMA page.
                --
                -- Procedure:
                --
                --   clock 0:
                --       deassert SLRD# after one word
                --
                --   clocks 1..4:
                --       wait for FX3 flags to propagate
                --
                --   clock 5:
                --       inspect READY
                --
                --       READY = 0:
                --           page empty -> return IDLE
                --
                --       READY = 1:
                --           request another single word
                --
                ----------------------------------------------------------------------------------------------------------------

                when GPIF_READ_SINGLE =>

                    ----------------------------------------------------------------------------------------------------------------
                    -- End Current One-Clock SLRD Pulse
                    ----------------------------------------------------------------------------------------------------------------

                    if idle_cycles = "000" then

                        slrd_int    <= '1';
                        idle_cycles <= idle_cycles + 1;

                    ----------------------------------------------------------------------------------------------------------------
                    -- FX3 READY Should Now Reflect Previous Read
                    ----------------------------------------------------------------------------------------------------------------

                    elsif idle_cycles = "101" then

                        if fx3_ready1 = '0' then

                            gpif_state <= GPIF_IDLE;

                            sloe_int   <= '1';

                        else

                            ----------------------------------------------------------------------------------------------------------------
                            -- More Data Exists
                            --
                            -- Start Another Single-Word Read
                            ----------------------------------------------------------------------------------------------------------------

                            gpif_state <= GPIF_READ_SINGLE;

                            slrd_int   <= '0';

                        end if;

                        idle_cycles <= (others => '0');

                    ----------------------------------------------------------------------------------------------------------------
                    -- Flag Propagation Delay
                    ----------------------------------------------------------------------------------------------------------------

                    else

                        idle_cycles <= idle_cycles + 1;

                    end if;

                ----------------------------------------------------------------------------------------------------------------
                -- Safety
                ----------------------------------------------------------------------------------------------------------------

                when others =>

                    gpif_state   <= GPIF_IDLE;

                    sloe_int     <= '1';
                    slrd_int     <= '1';

                    idle_cycles  <= (others => '0');

                    first_read   <= '0';

            end case;

        end if;

    end if;
end process;

end architecture rtl;
