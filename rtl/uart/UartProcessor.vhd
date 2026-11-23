library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.UartTypes.all;

entity UartProcessor is
port
(
    CLOCK : in std_logic;
    RESET : in std_logic;

    UART_TX_TRIGGER : in std_logic;
    UART_TX_VECTOR : in std_logic_vector(31 downto 0);

    UART_RX_TRIGGER : out std_logic;
    UART_RX_VECTOR : out std_logic_vector(31 downto 0);

    SYNCED_UART_RX : in std_logic;
    SYNCED_UART_TX : out std_logic;

    J504_DATA : out std_logic_vector(3 downto 0)
);
end UartProcessor;

architecture rtl of UartProcessor is

------------------------------------------------------------------------------------------------------------
-- Constants, Types and Signals
------------------------------------------------------------------------------------------------------------
constant DEBUG_UART_COUNT : integer := 100_000_000;

signal UART_LOG_MESSAGE_TRIGGER : std_logic := '0';
signal UART_LOG_MESSAGE_ID : UART_LOG_ID := ("0000", "0000");
signal UART_LOG_MESSAGE_KEY : UART_LOG_KEY := ("0000", "0000");
signal UART_LOG_MESSAGE_DATA : UART_LOG_DATA := ("0000", "0000", "0000", "0000");

signal uart_wr_valid : std_logic := '0';
signal uart_wr_symbol : std_logic_vector(7 downto 0) := (others => '0');
signal uart_wr_busy : std_logic := '0';

signal uart_rd_valid : std_logic := '0';
signal uart_rd_symbol : std_logic_vector(7 downto 0) := (others => '0');
signal uart_rd_busy : std_logic := '0';

signal debug_uart_trigger : std_logic := '0';
signal debug_uart_counter : integer range 0 to DEBUG_UART_COUNT := 0;
signal debug_uart_message : std_logic_vector(31 downto 0) := (others => '0');

------------------------------------------------------------------------------------------------------------
-- Components
------------------------------------------------------------------------------------------------------------
component UartDataAssembly
generic
(
    UART_CTRL : std_logic := '0'
);
port
(
    CLOCK : in std_logic;
    RESET : in std_logic;

    UART_LOG_TRIGGER : in std_logic;
    UART_LOG_MESSAGE_ID : in UART_LOG_ID;
    UART_LOG_MESSAGE_KEY : in UART_LOG_KEY;
    UART_LOG_MESSAGE_DATA : in UART_LOG_DATA;

    WRITE_VALID : out std_logic;
    WRITE_SYMBOL : out std_logic_vector(7 downto 0);

    WRITE_BUSY : in std_logic
);
end component;

component UartDataDisassembly
port
(
    CLOCK : in std_logic;
    RESET : in std_logic;

    UART_RX_TRIGGER : out std_logic;
    UART_RX_VECTOR : out std_logic_vector(31 downto 0);

    READ_VALID : in std_logic;
    READ_SYMBOL : in std_logic_vector(7 downto 0);

    READ_BUSY : in std_logic
);
end component;

component UartTx
port
(
    CLOCK : in std_logic;
    RESET : in std_logic;

    WRITE_ENABLE : in std_logic;
    WRITE_SYMBOL : in std_logic_vector(7 downto 0);
    WRITE_BUSY : out std_logic;

    SYNCED_UART_TX : out std_logic
);
end component;

component UartRx
port
(
    CLOCK : in std_logic;
    RESET : in std_logic;

    READ_VALID : out std_logic;
    READ_SYMBOL : out std_logic_vector(7 downto 0);
    READ_BUSY : out std_logic;

    SYNCED_UART_RX : in std_logic
);
end component;

begin

------------------------------------------------------------------------------------------------------------
-- Main Routine
------------------------------------------------------------------------------------------------------------

--debug_trigger_process:
--process(CLOCK)
--begin
--    if rising_edge(CLOCK) then
--        if debug_uart_counter = DEBUG_UART_COUNT then
--            debug_uart_counter <= 0;
--            debug_uart_trigger <= '1';
--        else
--            debug_uart_counter <= debug_uart_counter + 1;
--            debug_uart_trigger <= '0';
--        end if;
--    end if;
--end process;

--debug_uart_message <= x"12345678";

--UART_LOG_MESSAGE_TRIGGER <= debug_uart_trigger;
--UART_LOG_MESSAGE_ID(0) <= debug_uart_message(31 downto 28);
--UART_LOG_MESSAGE_ID(1) <= debug_uart_message(27 downto 24);
--UART_LOG_MESSAGE_KEY(0) <= debug_uart_message(23 downto 20);
--UART_LOG_MESSAGE_KEY(1) <= debug_uart_message(19 downto 16);
--UART_LOG_MESSAGE_DATA(0) <= debug_uart_message(15 downto 12);
--UART_LOG_MESSAGE_DATA(1) <= debug_uart_message(11 downto 8);
--UART_LOG_MESSAGE_DATA(2) <= debug_uart_message(7 downto 4);
--UART_LOG_MESSAGE_DATA(3) <= debug_uart_message(3 downto 0);

uart_switch_process:
process(CLOCK)
begin
    if rising_edge(CLOCK) then
        if RESET = '1' then
            UART_LOG_MESSAGE_TRIGGER <= '0';
            UART_LOG_MESSAGE_ID(0) <= "0000";
            UART_LOG_MESSAGE_ID(1) <= "0000";
            UART_LOG_MESSAGE_KEY(0) <= "0000";
            UART_LOG_MESSAGE_KEY(1) <= "0000";
            UART_LOG_MESSAGE_DATA(0) <= "0000";
            UART_LOG_MESSAGE_DATA(1) <= "0000";
            UART_LOG_MESSAGE_DATA(2) <= "0000";
            UART_LOG_MESSAGE_DATA(3) <= "0000";
        else
            if UART_TX_TRIGGER = '1' then
                UART_LOG_MESSAGE_TRIGGER <= '1';
                UART_LOG_MESSAGE_ID(0) <= UART_TX_VECTOR(31 downto 28);
                UART_LOG_MESSAGE_ID(1) <= UART_TX_VECTOR(27 downto 24);
                UART_LOG_MESSAGE_KEY(0) <= UART_TX_VECTOR(23 downto 20);
                UART_LOG_MESSAGE_KEY(1) <= UART_TX_VECTOR(19 downto 16);
                UART_LOG_MESSAGE_DATA(0) <= UART_TX_VECTOR(15 downto 12);
                UART_LOG_MESSAGE_DATA(1) <= UART_TX_VECTOR(11 downto 8);
                UART_LOG_MESSAGE_DATA(2) <= UART_TX_VECTOR(7 downto 4);
                UART_LOG_MESSAGE_DATA(3) <= UART_TX_VECTOR(3 downto 0);
            else
                UART_LOG_MESSAGE_TRIGGER <= '0';
            end if;
        end if;
    end if;
end process;

UartDataAssembly_module: UartDataAssembly
generic map
(
    UART_CTRL => '1'
)
port map
(
    CLOCK => CLOCK,
    RESET => RESET,
    -- IN
    UART_LOG_TRIGGER => UART_LOG_MESSAGE_TRIGGER,
    UART_LOG_MESSAGE_ID => UART_LOG_MESSAGE_ID,
    UART_LOG_MESSAGE_KEY => UART_LOG_MESSAGE_KEY,
    UART_LOG_MESSAGE_DATA => UART_LOG_MESSAGE_DATA,
    -- OUT
    WRITE_VALID => uart_wr_valid,
    WRITE_SYMBOL => uart_wr_symbol,
    -- IN
    WRITE_BUSY => uart_wr_busy
);

UartTx_module: UartTx
port map
(
    CLOCK => CLOCK,
    RESET => RESET,
    -- IN
    WRITE_ENABLE => uart_wr_valid,
    WRITE_SYMBOL => uart_wr_symbol,
    -- OUT
    WRITE_BUSY => uart_wr_busy,
    -- OUT
    SYNCED_UART_TX => SYNCED_UART_TX
);

UartRx_module: UartRx
port map
(
    CLOCK => CLOCK,
    RESET => RESET,
    -- OUT
    READ_VALID => uart_rd_valid,
    READ_SYMBOL => uart_rd_symbol,
    -- OUT
    READ_BUSY => uart_rd_busy,
    -- IN
    SYNCED_UART_RX => SYNCED_UART_RX
);

UartDataDisassembly_module: UartDataDisassembly
port map
(
    CLOCK => CLOCK,
    RESET => RESET,
    -- OUT
    UART_RX_TRIGGER => UART_RX_TRIGGER,
    UART_RX_VECTOR => UART_RX_VECTOR,
    -- IN
    READ_VALID => uart_rd_valid,
    READ_SYMBOL => uart_rd_symbol,
    -- IN
    READ_BUSY => uart_rd_busy
);

------------------------------------------------------------------------------------------------------------
-- Debug J504 Data
------------------------------------------------------------------------------------------------------------
J504_DATA <= uart_rd_valid
& uart_rd_busy
& uart_wr_valid
& uart_wr_busy;

end architecture;

