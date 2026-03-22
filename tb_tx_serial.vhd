-- Testbench for tx_serial.vhd
-- Tests parallel-to-serial converter functionality

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity tb_tx_serial is
end entity tb_tx_serial;

architecture tb of tb_tx_serial is

    -- Parameters
    constant CLK_PERIOD : time := 10 ns;
    constant DATA_WIDTH : integer := 8;

    -- Signals
    signal clk          : std_logic := '0';
    signal rst_n        : std_logic := '0';
    signal s_req_i      : std_logic := '0';
    signal s_data_i     : std_logic_vector(DATA_WIDTH-1 downto 0) := (others => '0');
    signal s_ack_o      : std_logic;
    signal tx_valid_o   : std_logic;
    signal tx_data_o    : std_logic;

    -- Test signals
    signal test_pass    : boolean := true;
    signal test_count   : integer := 0;

begin

    -- Instantiate the DUT (Device Under Test)
    dut : entity work.tx_serial
        generic map(
            data_width_p => DATA_WIDTH
        )
        port map(
            clk        => clk,
            rst_n      => rst_n,
            s_req_i    => s_req_i,
            s_data_i   => s_data_i,
            s_ack_o    => s_ack_o,
            tx_valid_o => tx_valid_o,
            tx_data_o  => tx_data_o
        );

    -- Clock generation
    clk_gen : process
    begin
        clk <= '0';
        wait for CLK_PERIOD / 2;
        clk <= '1';
        wait for CLK_PERIOD / 2;
    end process clk_gen;

    -- Main stimulus process
    stimulus : process
        variable bit_index : integer;
    begin

        -- ===== Test 1: Reset behavior =====
        report "Test 1: Testing reset behavior";
        test_count <= test_count + 1;
        
        rst_n <= '0';
        s_req_i <= '0';
        s_data_i <= (others => '0');
        wait for 3 * CLK_PERIOD;
        
        -- Check that outputs are initialized correctly after reset
        assert tx_valid_o = '0' 
            report "ERROR: tx_valid_o should be low after reset" 
            severity error;
        assert tx_data_o = '0' 
            report "ERROR: tx_data_o should be low after reset" 
            severity error;

        report "Test 1: PASSED" severity note;
        wait for CLK_PERIOD;

        -- ===== Test 2: Basic parallel to serial conversion (0xAA = 10101010) =====
        report "Test 2: Parallel to Serial conversion with data 0xAA";
        test_count <= test_count + 1;
        
        rst_n <= '1';
        wait for CLK_PERIOD;

        s_data_i <= X"AA";  -- 10101010 in binary
        s_req_i <= '1';
        
        -- Check serial output for 8 cycles
        for i in 0 to 7 loop
            wait for CLK_PERIOD;
            report "Cycle " & integer'image(i) & ": tx_data_o = " & std_logic'image(tx_data_o) & 
                   ", expected = " & std_logic'image(s_data_i(i));
            
            assert tx_valid_o = '1' 
                report "ERROR: tx_valid_o should be high when s_req_i is high" 
                severity error;
            
            assert tx_data_o = s_data_i(i) 
                report "ERROR: tx_data_o mismatch. Got " & std_logic'image(tx_data_o) & 
                       " but expected " & std_logic'image(s_data_i(i)) 
                severity error;
        end loop;

        s_req_i <= '0';
        wait for 2 * CLK_PERIOD;
        
        assert tx_valid_o = '0' 
            report "ERROR: tx_valid_o should go low when s_req_i goes low" 
            severity error;
        
        report "Test 2: PASSED" severity note;

        -- ===== Test 3: Another value - 0x55 (01010101) =====
        report "Test 3: Parallel to Serial conversion with data 0x55";
        test_count <= test_count + 1;
        
        wait for CLK_PERIOD;
        
        s_data_i <= X"55";  -- 01010101 in binary
        s_req_i <= '1';
        
        for i in 0 to 7 loop
            wait for CLK_PERIOD;
            report "Cycle " & integer'image(i) & ": tx_data_o = " & std_logic'image(tx_data_o) & 
                   ", expected = " & std_logic'image(s_data_i(i));
            
            assert tx_valid_o = '1' 
                report "ERROR: tx_valid_o should be high" 
                severity error;
            
            assert tx_data_o = s_data_i(i) 
                report "ERROR: tx_data_o mismatch. Got " & std_logic'image(tx_data_o) & 
                       " but expected " & std_logic'image(s_data_i(i)) 
                severity error;
        end loop;

        s_req_i <= '0';
        wait for 2 * CLK_PERIOD;
        
        report "Test 3: PASSED" severity note;

        -- ===== Test 4: Edge case - all zeros (0x00) =====
        report "Test 4: Parallel to Serial conversion with data 0x00";
        test_count <= test_count + 1;
        
        wait for CLK_PERIOD;
        
        s_data_i <= X"00";
        s_req_i <= '1';
        
        for i in 0 to 7 loop
            wait for CLK_PERIOD;
            
            assert tx_data_o = '0' 
                report "ERROR: tx_data_o should be 0 for data 0x00" 
                severity error;
        end loop;

        s_req_i <= '0';
        
        report "Test 4: PASSED" severity note;

        -- ===== Test 5: Edge case - all ones (0xFF) =====
        report "Test 5: Parallel to Serial conversion with data 0xFF";
        test_count <= test_count + 1;
        
        wait for 2 * CLK_PERIOD;
        
        s_data_i <= X"FF";
        s_req_i <= '1';
        
        for i in 0 to 7 loop
            wait for CLK_PERIOD;
            
            assert tx_data_o = '1' 
                report "ERROR: tx_data_o should be 1 for data 0xFF" 
                severity error;
        end loop;

        s_req_i <= '0';
        
        report "Test 5: PASSED" severity note;

        -- ===== Test 6: Request deassert and reassert =====
        report "Test 6: Request deassert and reassert";
        test_count <= test_count + 1;
        
        wait for 2 * CLK_PERIOD;
        
        s_data_i <= X"F0";  -- 11110000 in binary
        s_req_i <= '1';
        
        -- Output first 4 bits
        for i in 0 to 3 loop
            wait for CLK_PERIOD;
            assert tx_data_o = s_data_i(i) severity error;
        end loop;
        
        -- Deassert request
        s_req_i <= '0';
        wait for 2 * CLK_PERIOD;
        
        -- Reassert request - should restart from bit 0
        s_data_i <= X"0F";  -- 00001111 in binary
        s_req_i <= '1';
        
        for i in 0 to 3 loop
            wait for CLK_PERIOD;
            assert tx_data_o = s_data_i(i) severity error;
        end loop;
        
        s_req_i <= '0';
        
        report "Test 6: PASSED" severity note;

        -- ===== End of simulation =====
        wait for 2 * CLK_PERIOD;
        report "All tests completed successfully!" severity note;
        
        wait;

    end process stimulus;

    -- Watchdog timer
    watchdog : process
    begin
        wait for 1 ms;
        report "ERROR: Simulation timeout - watchdog triggered" severity error;
        wait;
    end process watchdog;

end architecture tb;
