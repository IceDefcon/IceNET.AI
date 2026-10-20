library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-------------------------------------------------------------------------------
-- GPIF_II_Controller.vhd
--
-- Bidirectional 32-bit FX3 synchronous slave FIFO controller.
-- VHDL-2002.
--
-- Direction names are relative to the FPGA:
--   TX: FPGA -> FX3 -> PC
--   RX: PC -> FX3 -> FPGA
--
-- Firmware configuration:
--   TX: PIB socket/thread 0, USB endpoint 0x81
--   RX: PIB socket/thread 3, USB endpoint 0x01
--
-- Expected flag connections:
--   GPIF_CTL(0) = CTL4 = FLAGA = thread 0 write ready
--   GPIF_CTL(1) = CTL5 = FLAGB = thread 0 watermark
--   GPIF_CTL(2) = CTL6 = FLAGC = thread 3 read ready
--   GPIF_CTL(3) = CTL8 = FLAGD = thread 3 watermark
--
-- Flags are interpreted as:
--   ready = '1': transfer permitted
--   ready = '0': full / empty / unavailable
--
-- All application signals must be synchronous to GPIF_CLK.
-- Use asynchronous FIFOs when connecting another clock domain.
--
-- TX handshake:
--   A word is accepted when TX_VALID and TX_READY are both '1'
--   at a rising edge.
--   Hold TX_DATA and TX_LAST stable until accepted.
--   TX_LAST commits the current FX3 buffer with the final data write.
--   Acceptance means locally buffered, not delivered to the PC.
--
-- RX handshake:
--   RX_VALID remains asserted and RX_DATA remains stable until
--   RX_READY is sampled high.
--
-- GPIF_ENB:
--   Stops admission of new bus transactions.
--   Already-started transactions finish.
--   Buffered TX and RX data are retained.
--
-- GPIF_RST:
--   Active high; discards local buffered data and resets counters.
--   Reset must be coordinated with FX3/host stream recovery.
--
-- Limitations:
--   * Conservative single-word accesses, not a burst engine.
--   * Each application word is four bytes.
--   * No RX packet-boundary indication: GPIF flags do not encode
--     the host application's transfer boundaries.
--   * No standalone USB ZLP command.
--   * TX_LAST flushes a DMA buffer; it does not guarantee a USB
--     short packet when the byte count is a multiple of max packet.
--   * Timing assumptions must be verified with TimeQuest and hardware.
-------------------------------------------------------------------------------

entity GPIF_II_Controller is
    generic
    (
        ADDR_DATA_TX : std_logic_vector(1 downto 0) := "00";
        ADDR_DATA_RX : std_logic_vector(1 downto 0) := "11"
    );
    port
    (
        GPIF_CLK : in std_logic;
        GPIF_RST : in std_logic;
        GPIF_ENB : in std_logic;

        GPIF_D   : inout std_logic_vector(31 downto 0);
        GPIF_CTL : in std_logic_vector(3 downto 0);

        -- Active-low physical FX3 controls.
        SLOE    : out std_logic;
        SLRD    : out std_logic;
        SLWR    : out std_logic;
        SLCS    : out std_logic;
        PKTEND  : out std_logic;
        FIFOADR : out std_logic_vector(1 downto 0);

        -- Application TX: FPGA -> PC.
        TX_DATA  : in  std_logic_vector(31 downto 0);
        TX_VALID : in  std_logic;
        TX_LAST  : in  std_logic;
        TX_READY : out std_logic;

        -- Application RX: PC -> FPGA.
        RX_DATA  : out std_logic_vector(31 downto 0);
        RX_VALID : out std_logic;
        RX_READY : in  std_logic;

        -- DEBUG_DATA/VALID/COUNTER describe captured RX words.
        -- DEBUG_VALID is a one-clock capture pulse.
        DEBUG_DATA    : out std_logic_vector(31 downto 0);
        DEBUG_VALID   : out std_logic;
        DEBUG_COUNTER : out std_logic_vector(31 downto 0);

        -- Ready/watermark of the currently addressed thread.
        DEBUG_READY   : out std_logic;
        DEBUG_WMARK   : out std_logic;
        DEBUG_STATE   : out std_logic_vector(3 downto 0)
    );
end entity GPIF_II_Controller;

architecture rtl of GPIF_II_Controller is

    type state_type is
    (
        ST_IDLE,        -- 0
        ST_RX_SETUP,    -- 1
        ST_RX_CHECK,    -- 2
        ST_RX_STROBE,   -- 3
        ST_RX_WAIT,     -- 4
        ST_RX_CAPTURE,  -- 5
        ST_TX_SETUP,    -- 6
        ST_TX_CHECK,    -- 7
        ST_TX_STROBE,   -- 8
        ST_TX_HOLD,     -- 9
        ST_GUARD        -- 10
    );

    signal state : state_type := ST_IDLE;

    signal delay_count : natural range 0 to 7 := 0;
    signal address_reg : std_logic_vector(1 downto 0)
                       := ADDR_DATA_TX;

    -- One-entry transmit buffer.
    signal tx_data_reg : std_logic_vector(31 downto 0)
                      := (others => '0');
    signal tx_last_reg : std_logic := '0';
    signal tx_pending  : std_logic := '0';
    signal tx_ready_i  : std_logic;

    -- One-entry receive buffer.
    signal rx_data_reg  : std_logic_vector(31 downto 0)
                       := (others => '0');
    signal rx_valid_reg : std_logic := '0';

    signal rx_count : unsigned(31 downto 0) := (others => '0');
    signal debug_valid_reg : std_logic := '0';

    -- Round-robin preference when both directions request service.
    signal prefer_tx : std_logic := '0';

    signal drive_data : std_logic;

begin

    assert ADDR_DATA_TX /= ADDR_DATA_RX
        report "GPIF TX and RX addresses must differ"
        severity failure;

    ---------------------------------------------------------------------------
    -- Application interface.
    ---------------------------------------------------------------------------

    tx_ready_i <= '1'
        when tx_pending = '0' and
             GPIF_ENB = '1' and
             GPIF_RST = '0'
        else '0';

    TX_READY <= tx_ready_i;

    RX_DATA  <= rx_data_reg;
    RX_VALID <= rx_valid_reg;

    FIFOADR <= address_reg;

    -- The FPGA must never drive DQ during reads.
    GPIF_D <= tx_data_reg when drive_data = '1'
              else (others => 'Z');

    ---------------------------------------------------------------------------
    -- Debug.
    ---------------------------------------------------------------------------

    DEBUG_DATA    <= rx_data_reg;
    DEBUG_VALID   <= debug_valid_reg;
    DEBUG_COUNTER <= std_logic_vector(rx_count);

    DEBUG_READY <= GPIF_CTL(0) when address_reg = ADDR_DATA_TX
                   else GPIF_CTL(2);

    DEBUG_WMARK <= GPIF_CTL(1) when address_reg = ADDR_DATA_TX
                   else GPIF_CTL(3);

    DEBUG_STATE <= std_logic_vector(
        to_unsigned(state_type'pos(state), 4));

    ---------------------------------------------------------------------------
    -- Physical control decode.
    --
    -- GPIF_ENB does not asynchronously gate physical strobes:
    -- a transaction already started is allowed to finish.
    ---------------------------------------------------------------------------

    process(state, GPIF_RST, tx_last_reg)
    begin
        SLOE       <= '1';
        SLRD       <= '1';
        SLWR       <= '1';
        SLCS       <= '1';
        PKTEND     <= '1';
        drive_data <= '0';

        if GPIF_RST = '0' then
            case state is

                when ST_RX_SETUP |
                     ST_RX_CHECK |
                     ST_RX_WAIT |
                     ST_RX_CAPTURE =>
                    SLCS <= '0';
                    SLOE <= '0';

                when ST_RX_STROBE =>
                    SLCS <= '0';
                    SLOE <= '0';
                    SLRD <= '0';

                when ST_TX_SETUP |
                     ST_TX_CHECK |
                     ST_TX_HOLD =>
                    SLCS       <= '0';
                    drive_data <= '1';

                when ST_TX_STROBE =>
                    SLCS       <= '0';
                    SLWR       <= '0';
                    drive_data <= '1';

                    if tx_last_reg = '1' then
                        PKTEND <= '0';
                    end if;

                when others =>
                    null;

            end case;
        end if;
    end process;

    ---------------------------------------------------------------------------
    -- Controller.
    --
    -- Ready flags are synchronous interface inputs, not asynchronous GPIOs.
    -- Constrain their input delays relative to the forwarded GPIF clock.
    --
    -- This implementation intentionally leaves several idle cycles after
    -- each access so that flag changes settle before another access.
    -- It uses the actual ready flags for individual-word transfers.
    -- Watermark flags are exposed for debug but do not gate tail reads.
    ---------------------------------------------------------------------------

    process(GPIF_CLK, GPIF_RST)
    begin
        if GPIF_RST = '1' then
            state           <= ST_IDLE;
            delay_count     <= 0;
            address_reg     <= ADDR_DATA_TX;

            tx_data_reg     <= (others => '0');
            tx_last_reg     <= '0';
            tx_pending      <= '0';

            rx_data_reg     <= (others => '0');
            rx_valid_reg    <= '0';
            rx_count        <= (others => '0');
            debug_valid_reg <= '0';

            prefer_tx       <= '0';

        elsif rising_edge(GPIF_CLK) then

            debug_valid_reg <= '0';

            -- Accept one application transmit word.
            if TX_VALID = '1' and tx_ready_i = '1' then
                tx_data_reg <= TX_DATA;
                tx_last_reg <= TX_LAST;
                tx_pending  <= '1';
            end if;

            -- Consume the buffered receive word.
            if rx_valid_reg = '1' and RX_READY = '1' then
                rx_valid_reg <= '0';
            end if;

            case state is

                ---------------------------------------------------------------
                -- Select an available direction.
                ---------------------------------------------------------------

                when ST_IDLE =>
                    if GPIF_ENB = '1' then

                        if tx_pending = '1' and
                           GPIF_CTL(0) = '1' and
                           (prefer_tx = '1' or
                            rx_valid_reg = '1' or
                            GPIF_CTL(2) /= '1') then

                            address_reg <= ADDR_DATA_TX;
                            delay_count <= 3;
                            state       <= ST_TX_SETUP;

                        elsif rx_valid_reg = '0' and
                              GPIF_CTL(2) = '1' then

                            address_reg <= ADDR_DATA_RX;
                            delay_count <= 3;
                            state       <= ST_RX_SETUP;

                        end if;
                    end if;

                ---------------------------------------------------------------
                -- RX: PC -> FPGA.
                --
                -- Keep address, chip-select and output-enable stable before
                -- the read. Reserve the RX buffer for the entire transaction.
                ---------------------------------------------------------------

                when ST_RX_SETUP =>
                    if delay_count = 0 then
                        state <= ST_RX_CHECK;
                    else
                        delay_count <= delay_count - 1;
                    end if;

                when ST_RX_CHECK =>
                    if GPIF_ENB = '1' and GPIF_CTL(2) = '1' then
                        state <= ST_RX_STROBE;
                    else
                        delay_count <= 4;
                        state       <= ST_GUARD;
                    end if;

                when ST_RX_STROBE =>
                    -- FX3 samples the single SLRD# pulse at this edge.
                    -- Do not issue another read until this word is captured.
                    delay_count <= 1;
                    state       <= ST_RX_WAIT;

                when ST_RX_WAIT =>
                    -- Two intervening rising edges; SLOE# remains asserted.
                    if delay_count = 0 then
                        state <= ST_RX_CAPTURE;
                    else
                        delay_count <= delay_count - 1;
                    end if;

                when ST_RX_CAPTURE =>
                    -- Capture on the third edge after the read-strobe edge.
                    -- No further read has been issued, so the returned word
                    -- remains on DQ while SLOE# stays asserted.
                    rx_data_reg     <= GPIF_D;
                    rx_valid_reg    <= '1';
                    rx_count        <= rx_count + 1;
                    debug_valid_reg <= '1';

                    prefer_tx   <= '1';
                    delay_count <= 4;
                    state       <= ST_GUARD;

                ---------------------------------------------------------------
                -- TX: FPGA -> PC.
                ---------------------------------------------------------------

                when ST_TX_SETUP =>
                    if delay_count = 0 then
                        state <= ST_TX_CHECK;
                    else
                        delay_count <= delay_count - 1;
                    end if;

                when ST_TX_CHECK =>
                    if GPIF_ENB = '1' and GPIF_CTL(0) = '1' then
                        state <= ST_TX_STROBE;
                    else
                        -- Keep the buffered word for a later retry.
                        delay_count <= 4;
                        state       <= ST_GUARD;
                    end if;

                when ST_TX_STROBE =>
                    -- FX3 samples the data at this edge.
                    -- If TX_LAST was set, PKTEND# is sampled with SLWR#.
                    tx_pending <= '0';
                    prefer_tx  <= '0';
                    state      <= ST_TX_HOLD;

                when ST_TX_HOLD =>
                    -- Retain bus drive for one cycle after the write.
                    delay_count <= 4;
                    state       <= ST_GUARD;

                ---------------------------------------------------------------
                -- All controls inactive and DQ high-impedance.
                -- Allow flag propagation and bus turnaround.
                ---------------------------------------------------------------

                when ST_GUARD =>
                    if delay_count = 0 then
                        state <= ST_IDLE;
                    else
                        delay_count <= delay_count - 1;
                    end if;

            end case;
        end if;
    end process;

end architecture rtl;
