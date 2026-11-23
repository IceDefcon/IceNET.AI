library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;
use work.UartTypes.all;

entity UartDataDisassembly is
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
end UartDataDisassembly;

architecture rtl of UartDataDisassembly is

------------------------------------------------------------------------------------------------------------
-- Constants, Types and Signals
------------------------------------------------------------------------------------------------------------
type DISASSEMBLER_STATE is
(
    DISASSEMBLER_IDLE,
    DISASSEMBLER_GET_BYTE,
    DISASSEMBLER_CONVERT,
    DISASSEMBLER_INDEX,
    DISASSEMBLER_SET_HEX,
    DISASSEMBLER_CHECK,
    DISASSEMBLER_READY,
    DISASSEMBLER_DONE
);
signal disassembly_state: DISASSEMBLER_STATE := DISASSEMBLER_IDLE;

signal uart_rd_byte : std_logic_vector(7 downto 0) := (others => '0');
signal uart_rd_byte_count : integer range 0 to 7 := 0;
signal uart_rd_hex : std_logic_vector(3 downto 0) := (others => '0');
signal temp_rd_vector : std_logic_vector(31 downto 0) := (others => '0');
signal index_lo : integer range 0 to 31 := 0;
signal index_hi : integer range 0 to 31 := 0;
signal uart_rd_trigger : std_logic := '0';
signal uart_rd_vector : std_logic_vector(31 downto 0) := (others => '0');

signal uart_burst_counter : integer range 0 to 1000 := 0;

begin

data_disassembly_process:
process(CLOCK)
begin
    if rising_edge(CLOCK) then
        if RESET = '1' then
            disassembly_state <= DISASSEMBLER_IDLE;
            uart_rd_byte <= (others => '0');
            uart_rd_byte_count <= 0;
            uart_rd_hex <= (others => '0');
            temp_rd_vector <= (others => '0');
            index_hi <= 0;
            index_lo <= 0;
            uart_rd_vector <= (others => '0');
            uart_rd_trigger <= '0';
            uart_burst_counter <= 0;
        else
            ------------------------------------------------------------------------------------------------------------
            -- State Machine
            ------------------------------------------------------------------------------------------------------------
            case disassembly_state is
                when DISASSEMBLER_IDLE =>
                    if READ_VALID = '1' then
                        uart_burst_counter <= 0;
                        disassembly_state <= DISASSEMBLER_GET_BYTE;
                    elsif uart_burst_counter = 1000 then
                        uart_rd_byte <= (others => '0');
                        uart_rd_byte_count <= 0;
                        uart_rd_hex <= (others => '0');
                        temp_rd_vector <= (others => '0');
                        index_hi <= 0;
                        index_lo <= 0;
                        uart_rd_trigger <= '0';
                        disassembly_state <= DISASSEMBLER_IDLE;
                    else
                        uart_burst_counter <= uart_burst_counter + 1;
                    end if;

                when DISASSEMBLER_GET_BYTE =>
                    uart_rd_byte <= READ_SYMBOL;
                    disassembly_state <= DISASSEMBLER_CONVERT;

                when DISASSEMBLER_CONVERT =>
                    uart_rd_hex <= ASCII_TO_HEX(uart_rd_byte);
                    disassembly_state <= DISASSEMBLER_INDEX;

                when DISASSEMBLER_INDEX =>
                    index_hi <= 31 - 4 * uart_rd_byte_count; -- 31, 27, 23, 19, 15, 11, 7, 3
                    index_lo <= 31 - 4 * uart_rd_byte_count - 3; -- 28, 24, 20, 16, 12, 8, 4, 0
                    disassembly_state <= DISASSEMBLER_SET_HEX;

                when DISASSEMBLER_SET_HEX =>
                    temp_rd_vector(index_hi downto index_lo) <= uart_rd_hex;
                    disassembly_state <= DISASSEMBLER_CHECK;

                when DISASSEMBLER_CHECK =>
                    if uart_rd_byte_count = 7 then
                        disassembly_state <= DISASSEMBLER_READY;
                    else
                        uart_rd_byte_count <= uart_rd_byte_count + 1;
                        disassembly_state <= DISASSEMBLER_IDLE;
                    end if;

                when DISASSEMBLER_READY =>
                    uart_rd_trigger <= '1';
                    uart_rd_vector <= temp_rd_vector;
                    disassembly_state <= DISASSEMBLER_DONE;

                when DISASSEMBLER_DONE =>
                    uart_rd_byte <= (others => '0');
                    uart_rd_byte_count <= 0;
                    uart_rd_hex <= (others => '0');
                    temp_rd_vector <= (others => '0');
                    index_hi <= 0;
                    index_lo <= 0;
                    uart_rd_trigger <= '0';
                    disassembly_state <= DISASSEMBLER_IDLE;

                when others =>
                    disassembly_state <= DISASSEMBLER_IDLE;

            end case;
        end if;
    end if;
end process;

UART_RX_TRIGGER <= uart_rd_trigger;
UART_RX_VECTOR <= uart_rd_vector;

end architecture;
