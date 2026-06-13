###########################################################################################################################
# Timing Constants [ns]
###########################################################################################################################
#
#
#                               Hold Time Control (Maximum Output Delay): 40% of the clock period
# -max (Maximum Output Delay):  The maximum delay after the clock edge at which the signal can change without violating any timing requirements at the receiving device.
#                               This is used to ensure that the signal doesn't change too late, violating the hold time at the receiving end.
#
#
#                          Max 40% of period
#                          For the Hold time
#                                  |
#                                  |
#                                  |
#                                __V____         _______         _______
#                               |  |    |       |       |       |       |
#                        _______|  |    |_______|       |_______|       |_______
#                                  |
#                                  |
#                For 50Mhz clock is 20n Period its 8ns
#               So the maximum hold time after the edge
#                Of the clock cannot be more than 8ns
#           The signal can change up to 8 ns after the clock edge without violating the hold time.
#
#
#
#                               SETUP TIME Control (Minimum Output Delay): 13% of the clock time
# -min (Minimum Output Delay):  The minimum delay after the clock edge at which the signal can change.
#                               This ensures that the output signal is stable long enough to meet the setup time requirement of the receiving register.
#
#
#                      Min 13% of period
#                      For the Setup time
#                              |
#                              |
#                              |
#                              V  _____         _______         _______
#                              | |     |       |       |       |       |
#                        ______|_|     |_______|       |_______|       |_______
#                              |
#                              |
#           For 50Mhz clock is 20n Period is the 2.6ns
#            So the signal must be stable 3ns before
#                     The next clock edge
#
#
###########################################################################################################################
#
#
#                 ____V_____V____________
#                |    |     |            |
#     Input      |    |     |            |
#                |    |     |            |
#           _____|   13%    |            |______________
#                   Setup   |
#                     |    40%
#                     |    Hold
#                     |     |
#                     |  ___V_______             ___________             ___________
#                     | |           |           |           |           |           |
#                     | |           |           |           |           |           |
#                     | |           |           |           |           |           |
#           __________V_|           |___________|           |___________|           |____________
#
#
#
###########################################################################################################################

# The signal is expected to arrive no later than 5.0 ns after the clock edge
set MAX_I_DELAY_50MHz  8.0
# The signal must arrive no earlier than 2.0 ns after the clock edge
set MIN_I_DELAY_50MHz  3.0
# This specifies how long after the clock edge the signal is allowed to change
set MAX_O_DELAY_50MHz  8.0
# Indicating the earliest time the signal can change after the clock edge
set MIN_O_DELAY_50MHz  3.0

###########################################################################################################################
# Clock 50MHz :: Base
###########################################################################################################################

create_clock -name CLOCK_MAIN -period 20.000 [get_ports CLOCK]

derive_pll_clocks
derive_clock_uncertainty

###########################################################################################################################
# Input Constraints :: relative to the CLOCK_50MHz
###########################################################################################################################

# Reset
set_input_delay -clock CLOCK_MAIN -max $MAX_I_DELAY_50MHz [get_ports RESET]

# Button inputs
set_input_delay -clock CLOCK_MAIN -max $MAX_I_DELAY_50MHz [get_ports {BUTTON_1 BUTTON_2 BUTTON_3 BUTTON_4}]
set_input_delay -clock CLOCK_MAIN -min $MIN_I_DELAY_50MHz [get_ports {BUTTON_1 BUTTON_2 BUTTON_3 BUTTON_4}]

###########################################################################################################################
# Output Constraints
###########################################################################################################################

# LED outputs
set_output_delay -clock CLOCK_MAIN -max $MAX_O_DELAY_50MHz [get_ports {LED_1 LED_2 LED_3 LED_4 LED_5 LED_6 LED_7 LED_8}]
set_output_delay -clock CLOCK_MAIN -min $MIN_O_DELAY_50MHz [get_ports {LED_1 LED_2 LED_3 LED_4 LED_5 LED_6 LED_7 LED_8}]
