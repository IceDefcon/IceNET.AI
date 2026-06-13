library ieee;
use ieee.numeric_std.all;
use ieee.std_logic_1164.all;

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
    -- DEBUG LED's
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




----------------------------------------------------------------------------------------------------------------
-- Mods
----------------------------------------------------------------------------------------------------------------
--component DebounceController
--generic
--(
--    PERIOD : integer := 50000; -- 50Mhz :: 50000*20ns = 1ms
--    SM_OFFSET : integer := 3
--);
--port
--(
--    CLOCK : in  std_logic;
--    RESET : in std_logic;

--    BUTTON_IN : in  std_logic;
--    BUTTON_OUT : out std_logic
--);
--end component;

----------------------------------------------------------------------------------------------------------------
-- Main Routine
----------------------------------------------------------------------------------------------------------------
begin

--ActiveDebug_Button: DebounceController
--generic map
--(
--    PERIOD => 50000, -- 50Mhz :: 50000*20ns = 1ms
--    SM_OFFSET => 3
--)
--port map
--(
--    CLOCK => CLOCK,
--    RESET => global_fpga_reset or init_fpga_reset,

--    BUTTON_IN => BUTTON_1,
--    BUTTON_OUT => active_button_1
--);


debug_test_process:
process(CLOCK)
begin
    if rising_edge(CLOCK) then
        if RESET = '0' then

            LED_1 <= '1';
            LED_2 <= '1';
            LED_3 <= '1';
            LED_4 <= '1';
            LED_5 <= '1';
            LED_6 <= '1';
            LED_7 <= '1';
            LED_8 <= '1';
        else

            LED_1 <= '0';
            LED_2 <= '1';
            LED_3 <= '0';
            LED_4 <= '1';
            LED_5 <= '0';
            LED_6 <= '1';
            LED_7 <= '0';
            LED_8 <= '1';

        end if;
    end if;
end process;

end rtl;
