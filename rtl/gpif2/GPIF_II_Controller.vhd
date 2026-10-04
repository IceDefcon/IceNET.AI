library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

--
-- B210 GPIF-II transaction engine, translated to VHDL and adapted only for
-- the two threads exposed by the Cypress synchronous Slave-FIFO firmware.
--
-- B210 source counterpart:
--   gpif2_slave_fifo32.v
--
-- Identical GPIF transaction behaviour retained from the B210 controller:
--
--   * STATE_IDLE / STATE_WAIT / STATE_THINK arbitration sequence.
--   * Eight PCLK cycles of FIFOADR and flag settling in STATE_WAIT.
--   * Double-registered READY and watermark flags.
--   * slrd1..slrd5 read pipeline, with burst data valid at slrd3 and
--     single-read data valid at slrd5.
--   * STATE_READ, STATE_READ_FLUSH and STATE_READ_SINGLE timing.
--   * STATE_WRITE and STATE_WRITE_FLUSH timing.
--   * PKTEND# handling and the 256-word padding workaround.
--   * FPGA drives GPIF_D only while SLOE# is inactive (logic high).
--
-- Necessary two-thread adaptation:
--
--   B210 has four GPIF threads and two clock-domain-crossing packet FIFOs.
--   This FPGA test design has the Cypress pair below and a single synchronous
--   loopback FIFO in the GPIF clock domain:
--
--     USB EP1 OUT -> FX3 thread 3 -> FIFOADR "11" -> FPGA
--     FPGA        -> FX3 thread 0 -> FIFOADR "00" -> USB EP1 IN
--
-- The FIFO preserves every received word and its end-of-packet marker while
-- the B210 state machine changes direction. This is a real packet loop-through
-- path, rather than a one-word approximation of the B210 write logic.
--
entity GPIF_II_Controller is
    generic
    (
        -- B210 naming is retained deliberately. DATA_TX is data read from
        -- FX3 into the FPGA; DATA_RX is data written from FPGA into FX3.
        ADDR_DATA_TX : std_logic_vector(1 downto 0) := "11";
        ADDR_DATA_RX : std_logic_vector(1 downto 0) := "00";

        -- 2**10 = 1024 x 32-bit words. The depth can be raised to 13 to
        -- match the B210 DATA_*_FIFO_SIZE setting exactly if desired.
        LOOP_FIFO_ADDR_WIDTH : positive := 10
    );
    port
    (
        ----------------------------------------------------------------------------------------------------------------
        -- GPIF-II interface
        ----------------------------------------------------------------------------------------------------------------
        GPIF_CLK : in    std_logic;
        GPIF_RST : in    std_logic;
        GPIF_ENB : in    std_logic;

        GPIF_D   : inout std_logic_vector(31 downto 0);
        GPIF_CTL : in    std_logic_vector(3 downto 0);

        SLOE     : out std_logic;
        SLRD     : out std_logic;
        SLWR     : out std_logic;
        SLCS     : out std_logic;
        PKTEND   : out std_logic;
        FIFOADR  : out std_logic_vector(1 downto 0);

        ----------------------------------------------------------------------------------------------------------------
        -- SignalTap debug
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

    --------------------------------------------------------------------------------------------------------------------
    -- Constants and loopback FIFO
    --------------------------------------------------------------------------------------------------------------------
    constant LOOP_FIFO_DEPTH             : natural := 2 ** LOOP_FIFO_ADDR_WIDTH;
    constant LOOP_FIFO_SAFETY_WORDS      : natural := 16;
    constant LOOP_FIFO_NEARLY_FULL_COUNT : natural := LOOP_FIFO_DEPTH - LOOP_FIFO_SAFETY_WORDS;

    subtype LOOP_FIFO_PTR_TYPE is unsigned(LOOP_FIFO_ADDR_WIDTH - 1 downto 0);
    subtype LOOP_FIFO_COUNT_TYPE is unsigned(LOOP_FIFO_ADDR_WIDTH downto 0);

    constant LOOP_FIFO_NEARLY_FULL_U : LOOP_FIFO_COUNT_TYPE :=
        to_unsigned(LOOP_FIFO_NEARLY_FULL_COUNT, LOOP_FIFO_COUNT_TYPE'length);

    type LOOP_FIFO_DATA_MEM_TYPE is array (0 to LOOP_FIFO_DEPTH - 1) of std_logic_vector(31 downto 0);
    type LOOP_FIFO_EOP_MEM_TYPE  is array (0 to LOOP_FIFO_DEPTH - 1) of std_logic;

    signal loop_fifo_data_mem : LOOP_FIFO_DATA_MEM_TYPE;
    signal loop_fifo_eop_mem  : LOOP_FIFO_EOP_MEM_TYPE;

    signal loop_fifo_wr_ptr : LOOP_FIFO_PTR_TYPE := (others => '0');
    signal loop_fifo_rd_ptr : LOOP_FIFO_PTR_TYPE := (others => '0');
    signal loop_fifo_count  : LOOP_FIFO_COUNT_TYPE := (others => '0');

    signal loop_fifo_front_data : std_logic_vector(31 downto 0);
    signal loop_fifo_front_eop  : std_logic;
    signal loop_fifo_has_data   : std_logic;
    signal loop_fifo_has_space  : std_logic;
    signal loop_fifo_nearly_full : std_logic;

    --------------------------------------------------------------------------------------------------------------------
    -- Direct B210 state encoding
    --------------------------------------------------------------------------------------------------------------------
    type GPIF_STATE_TYPE is
    (
        STATE_IDLE,
        STATE_THINK,
        STATE_READ,
        STATE_WRITE,
        STATE_WAIT,
        STATE_READ_FLUSH,
        STATE_WRITE_FLUSH,
        STATE_READ_SINGLE
    );

    signal gpif_state : GPIF_STATE_TYPE := STATE_IDLE;

    --------------------------------------------------------------------------------------------------------------------
    -- GPIF controls, input/output data and arbitration signals
    --------------------------------------------------------------------------------------------------------------------
    signal sloe_int      : std_logic := '1';
    signal slrd_int      : std_logic := '1';
    signal slwr_int      : std_logic := '1';
    signal pktend_int    : std_logic := '1';
    signal fifoadr_reg   : std_logic_vector(1 downto 0) := ADDR_DATA_RX;
    signal next_addr     : std_logic_vector(1 downto 0) := ADDR_DATA_TX;
    signal last_addr     : std_logic_vector(1 downto 0) := ADDR_DATA_RX;

    signal gpif_data_in  : std_logic_vector(31 downto 0) := (others => '0');
    signal gpif_data_out : std_logic_vector(31 downto 0) := (others => '0');

    signal idle_cycles   : unsigned(2 downto 0) := (others => '0');
    signal transfer_size : unsigned(15 downto 0) := to_unsigned(1, 16);
    signal first_read    : std_logic := '0';
    signal pad           : std_logic := '0';

    --------------------------------------------------------------------------------------------------------------------
    -- Selected FX3 flag inputs
    --------------------------------------------------------------------------------------------------------------------
    -- GPIF_CTL bit assignment in this top-level design:
    --
    --   (3) = CTL8 = FLAGD = thread-3 watermark
    --   (2) = CTL6 = FLAGC = thread-3 ready/not-empty
    --   (1) = CTL5 = FLAGB = thread-0 watermark
    --   (0) = CTL4 = FLAGA = thread-0 ready/not-full
    --
    -- B210 feeds one READY/WMARK pair into its controller. Here that pair is
    -- multiplexed from the active FIFOADR, then registered identically.
    --------------------------------------------------------------------------------------------------------------------
    signal selected_ready_raw : std_logic := '0';
    signal selected_wmark_raw : std_logic := '0';
    signal fx3_ready          : std_logic := '0';
    signal fx3_ready1         : std_logic := '0';
    signal fx3_wmark          : std_logic := '0';
    signal fx3_wmark1         : std_logic := '0';

    --------------------------------------------------------------------------------------------------------------------
    -- B210 read and end-of-packet pipelines
    --------------------------------------------------------------------------------------------------------------------
    signal slrd1 : std_logic := '1';
    signal slrd2 : std_logic := '1';
    signal slrd3 : std_logic := '1';
    signal slrd4 : std_logic := '1';
    signal slrd5 : std_logic := '1';

    signal rx_eop  : std_logic := '0';
    signal rx_eop1 : std_logic := '1';
    signal rx_eop2 : std_logic := '1';

    signal read_fifo_xfer : std_logic;
    signal read_fifo_eop  : std_logic;
    signal write_fifo_xfer : std_logic;
    signal write_fifo_eop  : std_logic;
    signal loop_fifo_push  : std_logic;
    signal loop_fifo_pop   : std_logic;

    signal local_fifo_ready : std_logic;
    signal fifo_nearly_full : std_logic := '0';
    signal read_ready_go    : std_logic := '0';
    signal write_ready_go   : std_logic := '0';

    --------------------------------------------------------------------------------------------------------------------
    -- SignalTap debug
    --------------------------------------------------------------------------------------------------------------------
    signal debug_data_reg    : std_logic_vector(31 downto 0) := (others => '0');
    signal debug_valid_reg   : std_logic := '0';
    signal debug_counter_reg : unsigned(31 downto 0) := (others => '0');

begin

    --------------------------------------------------------------------------------------------------------------------
    -- Compile-time guard for the in-flight SLRD pipeline margin.
    --------------------------------------------------------------------------------------------------------------------
    assert LOOP_FIFO_ADDR_WIDTH >= 5
        report "LOOP_FIFO_ADDR_WIDTH must be at least 5"
        severity failure;

    --------------------------------------------------------------------------------------------------------------------
    -- GPIF electrical direction and static outputs
    --------------------------------------------------------------------------------------------------------------------
    -- This is a literal VHDL equivalent of the B210 line:
    --
    --   assign gpif_d = sloe ? gpif_data_out : 32'bz;
    --
    -- SLOE# is active low. FX3 owns GPIF_D on reads; FPGA owns it for
    -- writes and while the bus is parked.
    --------------------------------------------------------------------------------------------------------------------
    GPIF_D <= gpif_data_out when sloe_int = '1' else (others => 'Z');

    SLOE    <= sloe_int;
    SLRD    <= slrd_int;
    SLWR    <= slwr_int;
    PKTEND  <= pktend_int;
    FIFOADR <= fifoadr_reg;
    SLCS    <= '0';

    --------------------------------------------------------------------------------------------------------------------
    -- Loopback FIFO status and output
    --------------------------------------------------------------------------------------------------------------------
    loop_fifo_front_data <= loop_fifo_data_mem(to_integer(loop_fifo_rd_ptr));
    loop_fifo_front_eop  <= loop_fifo_eop_mem(to_integer(loop_fifo_rd_ptr));

    loop_fifo_has_data <= '1' when loop_fifo_count /= to_unsigned(0, loop_fifo_count'length) else '0';
    loop_fifo_has_space <= '1' when loop_fifo_count < LOOP_FIFO_NEARLY_FULL_U else '0';
    loop_fifo_nearly_full <= '1' when loop_fifo_count >= LOOP_FIFO_NEARLY_FULL_U else '0';

    --------------------------------------------------------------------------------------------------------------------
    -- Select the proper physical Cypress flags for the active thread.
    --------------------------------------------------------------------------------------------------------------------
    selected_flag_mux_process : process(fifoadr_reg, GPIF_CTL)
    begin
        if fifoadr_reg = ADDR_DATA_TX then
            selected_ready_raw <= GPIF_CTL(2);
            selected_wmark_raw <= GPIF_CTL(3);
        elsif fifoadr_reg = ADDR_DATA_RX then
            selected_ready_raw <= GPIF_CTL(0);
            selected_wmark_raw <= GPIF_CTL(1);
        else
            selected_ready_raw <= '0';
            selected_wmark_raw <= '0';
        end if;
    end process;

    --------------------------------------------------------------------------------------------------------------------
    -- B210 double-registering of FX3 flags
    --------------------------------------------------------------------------------------------------------------------
    fx3_flag_process : process(GPIF_CLK)
    begin
        if rising_edge(GPIF_CLK) then
            if GPIF_RST = '1' then
                fx3_ready  <= '0';
                fx3_ready1 <= '0';
                fx3_wmark  <= '0';
                fx3_wmark1 <= '0';
            else
                fx3_ready  <= selected_ready_raw;
                fx3_ready1 <= fx3_ready;
                fx3_wmark  <= selected_wmark_raw;
                fx3_wmark1 <= fx3_wmark;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------------------------------------------------
    -- B210 next-address rotation, restricted to the two Cypress data threads.
    --------------------------------------------------------------------------------------------------------------------
    next_address_process : process(GPIF_CLK)
    begin
        if rising_edge(GPIF_CLK) then
            if GPIF_RST = '1' then
                next_addr <= ADDR_DATA_TX;
            elsif fifoadr_reg = ADDR_DATA_TX then
                next_addr <= ADDR_DATA_RX;
            else
                next_addr <= ADDR_DATA_TX;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------------------------------------------------
    -- B210 local FIFO readiness functions, registered on GPIF_CLK.
    --------------------------------------------------------------------------------------------------------------------
    local_fifo_ready <= '1' when
                        ((fifoadr_reg = ADDR_DATA_TX) and (loop_fifo_has_space = '1')) or
                        ((fifoadr_reg = ADDR_DATA_RX) and (loop_fifo_has_data = '1'))
                        else '0';

    fifo_status_process : process(GPIF_CLK)
    begin
        if rising_edge(GPIF_CLK) then
            if GPIF_RST = '1' then
                fifo_nearly_full <= '0';
                read_ready_go    <= '0';
                write_ready_go   <= '0';
            elsif fifoadr_reg = ADDR_DATA_TX then
                fifo_nearly_full <= loop_fifo_nearly_full;
                read_ready_go    <= loop_fifo_has_space;
                write_ready_go   <= '0';
            elsif fifoadr_reg = ADDR_DATA_RX then
                fifo_nearly_full <= '0';
                read_ready_go    <= '0';
                write_ready_go   <= loop_fifo_has_data;
            else
                fifo_nearly_full <= '0';
                read_ready_go    <= '0';
                write_ready_go   <= '0';
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------------------------------------------------
    -- B210 SLRD# pipeline and GPIF input capture
    --------------------------------------------------------------------------------------------------------------------
    slrd_pipeline_process : process(GPIF_CLK)
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

    gpif_input_capture_process : process(GPIF_CLK)
    begin
        if rising_edge(GPIF_CLK) then
            if GPIF_RST = '1' then
                gpif_data_in <= (others => '0');
            elsif slrd2 = '0' then
                gpif_data_in <= GPIF_D;
            end if;
        end if;
    end process;

    rx_eop_pipeline_process : process(GPIF_CLK)
    begin
        if rising_edge(GPIF_CLK) then
            if GPIF_RST = '1' then
                rx_eop1 <= '1';
                rx_eop2 <= '1';
            else
                rx_eop2 <= rx_eop1;
                rx_eop1 <= rx_eop;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------------------------------------------------
    -- Exact B210 validity equations, adapted to the selected DATA_TX thread.
    --------------------------------------------------------------------------------------------------------------------
    read_fifo_xfer <= '1' when
                       (((gpif_state = STATE_READ) or (gpif_state = STATE_READ_FLUSH)) and (slrd3 = '0')) or
                       ((gpif_state = STATE_READ_SINGLE) and (slrd5 = '0'))
                       else '0';

    read_fifo_eop <= '1' when
                      ((gpif_state = STATE_READ_FLUSH) and (rx_eop2 = '1')) or
                      ((gpif_state = STATE_READ_SINGLE) and (fx3_ready1 = '0'))
                      else '0';

    write_fifo_xfer <= '1' when
                        (((gpif_state = STATE_WRITE) and (fx3_wmark1 = '1') and (pad = '0')) or
                         ((gpif_state = STATE_THINK) and (fx3_ready1 = '1'))) and
                        (fifoadr_reg = ADDR_DATA_RX) and (loop_fifo_has_data = '1')
                        else '0';

    write_fifo_eop <= loop_fifo_front_eop;

    loop_fifo_push <= '1' when (read_fifo_xfer = '1') and (loop_fifo_has_space = '1') else '0';
    loop_fifo_pop  <= '1' when (write_fifo_xfer = '1') and (loop_fifo_has_data = '1') else '0';

    --------------------------------------------------------------------------------------------------------------------
    -- Single-clock loopback FIFO. It replaces the B210's two asynchronous
    -- 64-bit packet FIFOs because this test design has only GPIF_CLK.
    --------------------------------------------------------------------------------------------------------------------
    loop_fifo_process : process(GPIF_CLK)
    begin
        if rising_edge(GPIF_CLK) then
            if GPIF_RST = '1' then
                loop_fifo_wr_ptr   <= (others => '0');
                loop_fifo_rd_ptr   <= (others => '0');
                loop_fifo_count    <= (others => '0');
                debug_data_reg     <= (others => '0');
                debug_valid_reg    <= '0';
                debug_counter_reg  <= (others => '0');
            else
                debug_valid_reg <= '0';

                if loop_fifo_push = '1' then
                    loop_fifo_data_mem(to_integer(loop_fifo_wr_ptr)) <= gpif_data_in;
                    loop_fifo_eop_mem(to_integer(loop_fifo_wr_ptr))  <= read_fifo_eop;
                    loop_fifo_wr_ptr <= loop_fifo_wr_ptr + 1;

                    -- Same observation point as B210 data_tx_tvalid.
                    debug_data_reg    <= gpif_data_in;
                    debug_valid_reg   <= '1';
                    debug_counter_reg <= debug_counter_reg + 1;
                end if;

                if loop_fifo_pop = '1' then
                    loop_fifo_rd_ptr <= loop_fifo_rd_ptr + 1;
                end if;

                if (loop_fifo_push = '1') and (loop_fifo_pop = '0') then
                    loop_fifo_count <= loop_fifo_count + 1;
                elsif (loop_fifo_push = '0') and (loop_fifo_pop = '1') then
                    loop_fifo_count <= loop_fifo_count - 1;
                end if;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------------------------------------------------
    -- GPIF bus-master state machine: direct translation of B210
    -- gpif2_slave_fifo32 STATE_IDLE through STATE_WRITE_FLUSH.
    --------------------------------------------------------------------------------------------------------------------
    gpif_state_process : process(GPIF_CLK)
    begin
        if rising_edge(GPIF_CLK) then
            if GPIF_RST = '1' then
                gpif_state    <= STATE_IDLE;
                sloe_int      <= '1';
                slrd_int      <= '1';
                slwr_int      <= '1';
                pktend_int    <= '1';
                gpif_data_out <= (others => '0');
                idle_cycles   <= (others => '0');
                fifoadr_reg   <= ADDR_DATA_RX;
                first_read    <= '0';
                last_addr     <= ADDR_DATA_RX;
                rx_eop        <= '0';
                transfer_size <= to_unsigned(1, transfer_size'length);
                pad           <= '0';

            elsif GPIF_ENB = '1' then
                case gpif_state is

                    --------------------------------------------------------------------------------------------------------
                    when STATE_IDLE =>
                        sloe_int      <= '1';
                        slrd_int      <= '1';
                        slwr_int      <= '1';
                        pktend_int    <= '1';
                        gpif_data_out <= (others => '0');
                        fifoadr_reg   <= next_addr;
                        gpif_state    <= STATE_WAIT;
                        idle_cycles   <= (others => '0');
                        rx_eop        <= '0';
                        first_read    <= '0';

                    --------------------------------------------------------------------------------------------------------
                    when STATE_WAIT =>
                        if local_fifo_ready = '1' then
                            idle_cycles <= idle_cycles + 1;
                            if idle_cycles = "111" then
                                gpif_state <= STATE_THINK;
                            end if;
                        else
                            idle_cycles <= (others => '0');
                            fifoadr_reg <= next_addr;
                        end if;

                    --------------------------------------------------------------------------------------------------------
                    when STATE_THINK =>
                        if (fx3_ready1 = '1') and (fx3_wmark1 = '1') and (read_ready_go = '1') then
                            gpif_state <= STATE_READ;
                            slrd_int   <= '0';
                            rx_eop     <= '0';
                            first_read <= '1';
                            sloe_int   <= '0';

                        elsif (fx3_ready1 = '1') and (fx3_wmark1 = '0') and (read_ready_go = '1') then
                            gpif_state <= STATE_READ_SINGLE;
                            slrd_int   <= '0';
                            sloe_int   <= '0';

                        elsif (fx3_ready1 = '1') and (write_ready_go = '1') and
                              (write_fifo_eop = '1') and (transfer_size(7 downto 0) = to_unsigned(0, 8)) then
                            pktend_int    <= '1';
                            slwr_int      <= '0';
                            transfer_size <= transfer_size + 1;
                            gpif_data_out <= loop_fifo_front_data;
                            pad           <= '1';

                        elsif (((fx3_ready1 = '1') and (write_ready_go = '1') and (write_fifo_eop = '1')) or
                               (pad = '1')) then
                            pktend_int    <= '0';
                            gpif_state    <= STATE_WRITE_FLUSH;
                            idle_cycles   <= to_unsigned(5, idle_cycles'length);
                            slwr_int      <= '0';
                            transfer_size <= to_unsigned(1, transfer_size'length);
                            gpif_data_out <= loop_fifo_front_data;
                            pad           <= '0';

                        elsif (fx3_ready1 = '1') and (write_ready_go = '1') then
                            gpif_state    <= STATE_WRITE;
                            slwr_int      <= '0';
                            gpif_data_out <= loop_fifo_front_data;
                            transfer_size <= transfer_size + 1;

                        else
                            gpif_state <= STATE_IDLE;
                        end if;

                        idle_cycles <= (others => '0');
                        last_addr   <= fifoadr_reg;

                    --------------------------------------------------------------------------------------------------------
                    when STATE_READ_SINGLE =>
                        if idle_cycles = "000" then
                            slrd_int    <= '1';
                            idle_cycles <= idle_cycles + 1;
                        elsif idle_cycles = "101" then
                            if fx3_ready1 = '0' then
                                gpif_state <= STATE_IDLE;
                                sloe_int   <= '1';
                            else
                                gpif_state <= STATE_READ_SINGLE;
                                slrd_int   <= '0';
                            end if;
                            idle_cycles <= (others => '0');
                        else
                            idle_cycles <= idle_cycles + 1;
                        end if;

                    --------------------------------------------------------------------------------------------------------
                    when STATE_READ =>
                        if (fx3_wmark1 = '0') or (fifo_nearly_full = '1') then
                            slrd_int   <= '1';
                            gpif_state <= STATE_READ_FLUSH;
                        else
                            slrd_int <= '0';
                        end if;

                        if fx3_wmark1 = '0' then
                            rx_eop <= '1';
                        end if;

                        if slrd3 = '0' then
                            first_read <= '0';
                        end if;

                    --------------------------------------------------------------------------------------------------------
                    when STATE_READ_FLUSH =>
                        slrd_int <= '1';
                        rx_eop   <= '0';

                        if slrd3 = '0' then
                            first_read <= '0';
                        end if;

                        if (first_read = '0') and (slrd3 = '1') then
                            gpif_state <= STATE_IDLE;
                            sloe_int   <= '1';
                        end if;

                    --------------------------------------------------------------------------------------------------------
                    when STATE_WRITE =>
                        if (write_fifo_eop = '1') and (write_fifo_xfer = '1') and
                           (transfer_size(7 downto 0) = to_unsigned(0, 8)) then
                            pktend_int    <= '1';
                            slwr_int      <= '0';
                            transfer_size <= transfer_size + 1;
                            pad           <= '1';

                        elsif (((write_fifo_eop = '1') and (write_fifo_xfer = '1')) or (pad = '1')) then
                            pktend_int    <= '0';
                            gpif_state    <= STATE_WRITE_FLUSH;
                            idle_cycles   <= to_unsigned(5, idle_cycles'length);
                            slwr_int      <= '0';
                            transfer_size <= to_unsigned(1, transfer_size'length);
                            pad           <= '0';

                        elsif write_fifo_xfer = '1' then
                            pktend_int    <= '1';
                            slwr_int      <= '0';
                            transfer_size <= transfer_size + 1;

                        else
                            gpif_state  <= STATE_WRITE_FLUSH;
                            idle_cycles <= to_unsigned(6, idle_cycles'length);
                            pktend_int  <= '1';
                            slwr_int    <= '1';
                        end if;

                        gpif_data_out <= loop_fifo_front_data;

                    --------------------------------------------------------------------------------------------------------
                    when STATE_WRITE_FLUSH =>
                        slrd_int      <= '1';
                        slwr_int      <= '1';
                        pktend_int    <= '1';
                        gpif_data_out <= (others => '0');
                        idle_cycles   <= idle_cycles + 1;

                        if idle_cycles = "111" then
                            gpif_state <= STATE_IDLE;
                        end if;

                    when others =>
                        gpif_state <= STATE_IDLE;
                end case;
            end if;
        end if;
    end process;

    --------------------------------------------------------------------------------------------------------------------
    -- SignalTap outputs
    --------------------------------------------------------------------------------------------------------------------
    DEBUG_DATA    <= debug_data_reg;
    DEBUG_VALID   <= debug_valid_reg;
    DEBUG_COUNTER <= std_logic_vector(debug_counter_reg);
    DEBUG_READY   <= fx3_ready1;
    DEBUG_WMARK   <= fx3_wmark1;

    with gpif_state select DEBUG_STATE <=
        "0000" when STATE_IDLE,
        "0001" when STATE_THINK,
        "0010" when STATE_READ,
        "0011" when STATE_WRITE,
        "0100" when STATE_WAIT,
        "0101" when STATE_READ_FLUSH,
        "0110" when STATE_WRITE_FLUSH,
        "0111" when STATE_READ_SINGLE,
        "1111" when others;

end architecture rtl;
