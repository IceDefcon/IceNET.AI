library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- CYUSB3KIT-003 slfifosync, PC bulk OUT -> PIB thread 3 -> FPGA.
-- Top-level vector order: FLAGD, FLAGC, FLAGB, FLAGA.
-- ADDR_DATA_RX names the FPGA receive address in this project.
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

    SLOE    : out std_logic;
    SLRD    : out std_logic;
    SLWR    : out std_logic;
    SLCS    : out std_logic;
    PKTEND  : out std_logic;
    FIFOADR : out std_logic_vector(1 downto 0);

    TX_DATA  : in std_logic_vector(31 downto 0);
    TX_VALID : in std_logic;
    TX_LAST  : in std_logic;
    TX_READY : out std_logic;

    RX_DATA  : out std_logic_vector(31 downto 0);
    RX_VALID : out std_logic;
    RX_READY : in std_logic;

    DEBUG_DATA    : out std_logic_vector(31 downto 0);
    DEBUG_VALID   : out std_logic;
    DEBUG_COUNTER : out std_logic_vector(31 downto 0);
    DEBUG_READY   : out std_logic;
    DEBUG_WMARK   : out std_logic;
    DEBUG_STATE   : out std_logic_vector(3 downto 0)
);
end entity GPIF_II_Controller;

architecture rtl of GPIF_II_Controller is
    type state_t is (disabled, select_fifo, wait_ready, read_strobe,
                     delay_one, delay_two, capture_word, settle_flags);
    signal state : state_t := disabled;
    signal ready_q, wmark_q : std_logic := '0';
    signal selected, reading : std_logic := '0';
    signal word_q : std_logic_vector(31 downto 0) := (others => '0');
    signal valid_q, capture_pulse : std_logic := '0';
    signal word_count : unsigned(31 downto 0) := (others => '0');
begin
    FIFOADR <= ADDR_DATA_RX;
    GPIF_D <= (others => 'Z');
    SLWR <= '1';
    PKTEND <= '1';
    TX_READY <= '0';
    SLCS <= not selected;
    SLOE <= not selected;
    SLRD <= not reading;

    RX_DATA <= word_q;
    RX_VALID <= valid_q;
    DEBUG_DATA <= word_q;
    DEBUG_VALID <= capture_pulse;
    DEBUG_COUNTER <= std_logic_vector(word_count);
    DEBUG_READY <= ready_q;
    DEBUG_WMARK <= wmark_q;

    -- State codes are explicit for the Signal Tap display.
    with state select DEBUG_STATE <=
        x"0" when disabled,    x"1" when select_fifo,
        x"2" when wait_ready,  x"3" when read_strobe,
        x"4" when delay_one,   x"5" when delay_two,
        x"6" when capture_word,x"7" when settle_flags;

    process (GPIF_CLK)
    begin
        if rising_edge(GPIF_CLK) then
            ready_q <= GPIF_CTL(2); -- FLAGC: dedicated thread 3 ready
            wmark_q <= GPIF_CTL(3); -- FLAGD: diagnostic only
            capture_pulse <= '0';
            if GPIF_RST = '1' then
                state <= disabled;
                selected <= '0';
                reading <= '0';
                valid_q <= '0';
                word_q <= (others => '0');
                word_count <= (others => '0');
            else
                if valid_q = '1' and RX_READY = '1' then
                    valid_q <= '0';
                end if;

                -- A disable stops new requests. Finish any outstanding read.
                case state is
                    when disabled =>
                        if GPIF_ENB = '1' then
                            selected <= '1';
                            state <= select_fifo;
                        end if;

                    when select_fifo =>
                        state <= wait_ready;

                    when wait_ready =>
                        if GPIF_ENB = '0' then
                            selected <= '0';
                            state <= disabled;
                        elsif ready_q = '1' and valid_q = '0' then
                            reading <= '1';
                            state <= read_strobe;
                        end if;

                    when read_strobe =>
                        -- Edge N: FX3 samples active-low SLRD.
                        reading <= '0';
                        state <= delay_one;

                    when delay_one =>
                        state <= delay_two;      -- N+1

                    when delay_two =>
                        state <= capture_word;   -- N+2: FX3 launches data

                    when capture_word =>
                        word_q <= GPIF_D;        -- N+3: capture returned word
                        word_count <= word_count + 1;
                        valid_q <= '1';
                        capture_pulse <= '1';
                        state <= settle_flags;

                    when settle_flags =>
                        state <= wait_ready;
                end case;
            end if;
        end if;
    end process;
end architecture rtl;
