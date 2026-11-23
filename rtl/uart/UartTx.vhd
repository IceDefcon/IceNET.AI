library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

entity UartTx is
port
(
    CLOCK : in std_logic;
    RESET : in std_logic;

    WRITE_ENABLE : in std_logic;
    WRITE_SYMBOL : in std_logic_vector(7 downto 0);
    WRITE_BUSY : out std_logic;

    SYNCED_UART_TX : out std_logic
);
end UartTx;

architecture rtl of UartTx is

---------------------------------------------------------------------------------------------------
-- Constants, Types and Signals
---------------------------------------------------------------------------------------------------
constant bit_baud : integer range 0 to 255 := 10; -- 10*10ns ---> 10M Baud @ 100Mhz
constant bit_start : integer range 0 to 255 := 0;
constant bit_0 : integer range 0 to 4095 := bit_start + bit_baud;
constant bit_1 : integer range 0 to 4095 := bit_0 + bit_baud;
constant bit_2 : integer range 0 to 4095 := bit_1 + bit_baud;
constant bit_3 : integer range 0 to 4095 := bit_2 + bit_baud;
constant bit_4 : integer range 0 to 4095 := bit_3 + bit_baud;
constant bit_5 : integer range 0 to 4095 := bit_4 + bit_baud;
constant bit_6 : integer range 0 to 4095 := bit_5 + bit_baud;
constant bit_7 : integer range 0 to 4095 := bit_6 + bit_baud;
constant bit_stop : integer range 0 to 4095 := bit_7 + bit_baud;
constant bit_next : integer range 0 to 4095 := bit_stop + bit_baud;

signal symbol_process_timer : integer range 0 to 4095 := 0;

type SYMBOL_SM is
(
    SYMBOL_IDLE,
    SYMBOL_PROCESS,
    SYMBOL_DONE
);
signal symbol_state: SYMBOL_SM := SYMBOL_IDLE;

signal uart_tx : std_logic := '1';

signal reset_sync   : std_logic_vector(1 downto 0) := (others => '1');
signal reset_int    : std_logic := '1';

attribute IOB : string;
attribute IOB of SYNCED_UART_TX : signal is "TRUE";

---------------------------------------------------------------------------------------------------
-- Components
---------------------------------------------------------------------------------------------------


---------------------------------------------------------------------------------------------------
-- MAIN ROUTINE
---------------------------------------------------------------------------------------------------
begin

reset_sync_process:
process(CLOCK, RESET)
begin
    if RESET = '1' then
        reset_sync <= (others => '1');
    elsif rising_edge(CLOCK) then
        reset_sync(0) <= '0';
        reset_sync(1) <= reset_sync(0);
    end if;
end process;

reset_int <= reset_sync(1);

state_machine_process:
process(CLOCK)
begin
    if rising_edge(CLOCK) then
        ---------------------------------------------------------------------------------------------------
        -- RESET Values
        ---------------------------------------------------------------------------------------------------
        if reset_int = '1' then
            symbol_state <= SYMBOL_IDLE;
            symbol_process_timer <= 0;
            SYNCED_UART_TX <= '1';
            WRITE_BUSY <= '0';
            uart_tx <= '1';
        else
            ---------------------------------------------------------------------------------------------------
            -- ANTI LATCH
            ---------------------------------------------------------------------------------------------------


            ---------------------------------------------------------------------------------------------------
            -- State Machine
            ---------------------------------------------------------------------------------------------------
            case symbol_state is

                ---------------------------------------------------------------------------------------------------
                -- IDLE
                ---------------------------------------------------------------------------------------------------
                when SYMBOL_IDLE =>
                    if WRITE_ENABLE = '1' then
                        WRITE_BUSY <= '1';
                        symbol_state <= SYMBOL_PROCESS;
                    end if;

                ---------------------------------------------------------------------------------------------------
                -- START PROCESS
                ---------------------------------------------------------------------------------------------------
                when SYMBOL_PROCESS =>
                    if symbol_process_timer = 4095 then
                    else
                        if symbol_process_timer = bit_start then
                            ---------------------------------------------------------------------------------------------------
                            -- BIT START
                            ---------------------------------------------------------------------------------------------------
                            uart_tx <= '0';

                        elsif symbol_process_timer = bit_0 then
                            ---------------------------------------------------------------------------------------------------
                            -- BIT 0
                            ---------------------------------------------------------------------------------------------------
                            uart_tx <= WRITE_SYMBOL(0);

                        elsif symbol_process_timer = bit_1 then
                            ---------------------------------------------------------------------------------------------------
                            -- BIT 1
                            ---------------------------------------------------------------------------------------------------
                            uart_tx <= WRITE_SYMBOL(1);

                        elsif symbol_process_timer = bit_2 then
                            ---------------------------------------------------------------------------------------------------
                            -- BIT 2
                            ---------------------------------------------------------------------------------------------------
                            uart_tx <= WRITE_SYMBOL(2);

                        elsif symbol_process_timer = bit_3 then
                            ---------------------------------------------------------------------------------------------------
                            -- BIT 3
                            ---------------------------------------------------------------------------------------------------
                            uart_tx <= WRITE_SYMBOL(3);

                        elsif symbol_process_timer = bit_4 then
                            ---------------------------------------------------------------------------------------------------
                            -- BIT 4
                            ---------------------------------------------------------------------------------------------------
                            uart_tx <= WRITE_SYMBOL(4);

                        elsif symbol_process_timer = bit_5 then
                            ---------------------------------------------------------------------------------------------------
                            -- BIT 5
                            ---------------------------------------------------------------------------------------------------
                            uart_tx <= WRITE_SYMBOL(5);

                        elsif symbol_process_timer = bit_6 then
                            ---------------------------------------------------------------------------------------------------
                            -- BIT 6
                            ---------------------------------------------------------------------------------------------------
                            uart_tx <= WRITE_SYMBOL(6);

                        elsif symbol_process_timer = bit_7 then
                            ---------------------------------------------------------------------------------------------------
                            -- BIT 7
                            ---------------------------------------------------------------------------------------------------
                            uart_tx <= WRITE_SYMBOL(7);

                        elsif symbol_process_timer = bit_stop then
                            ---------------------------------------------------------------------------------------------------
                            -- BIT STOP
                            ---------------------------------------------------------------------------------------------------
                            uart_tx <= '1';

                        elsif symbol_process_timer = bit_next then
                            ---------------------------------------------------------------------------------------------------
                            -- BIT NEXT
                            ---------------------------------------------------------------------------------------------------
                            symbol_state <= SYMBOL_DONE;

                        end if;

                        symbol_process_timer <= symbol_process_timer + 1;
                    end if;

                ---------------------------------------------------------------------------------------------------
                -- DONE
                ---------------------------------------------------------------------------------------------------
                when SYMBOL_DONE =>
                    WRITE_BUSY <= '0';
                    symbol_process_timer <= 0;
                    symbol_state <= SYMBOL_IDLE;

                when others =>
                    symbol_state <= SYMBOL_IDLE;

            end case;

            ---------------------------------------------------------------------------------------------------
            -- SYNC
            ---------------------------------------------------------------------------------------------------
            SYNCED_UART_TX <= uart_tx;

        end if;
    end if;
end process;

end architecture;
