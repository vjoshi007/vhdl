
--  description :-  code to convert data to sequential
--  latency     :- 
--  todo        :- 
--  author      :- vivek joshi

library ieee                ;
use ieee.std_logic_1164.all ;
use ieee.numeric_std.all    ; 

entity tx_serial is 
 generic(
        data_width_p : integer:=8 ; 
 )
 port(
        clk         : in std_logic ;
        rst_n       : in std_logic ;
    --  parallel               
        s_req_i     : in std_logic ; 
        s_data_i    : in std_logic_vector(data_width_p-1 downto 0) ;
        s_ack_o     : out std_logic ;
    -- serial                         
        tx_valid_o  : out std_logic ;
        tx_data_o   : out std_logic 
  );
end tx_serial ;

architecture rtl of tx_serial is 
    
    constant log2_width : integer := 3 ; -- should rather be using a log2 function to make the code generic

    signal    mux_sel_cntr   : unsigned(log2_width-1 downto 0) ;
    signal    mux_sel_clr    : std_logic                       ; 
    
    begin 

    mux_select_line_pro : process(clk, rst_n)
      begin 
        if (rst_n) then 
            mux_sel_cntr <= (others => '0') ; 
            mux_sel_clr  <=  '0' ;   
        elsif rising_edge(clk) then 
            if s_req_i = '1' then
                mux_sel_cntr = mux_sel_cntr + 1;
                mux_sel_clr  = '0' ;
            elsif mux_sel_clr = '0' then 
                mux_sel_clr = '1';
                mux_sel_cntr = (others => '0') ;
            end if;        
        end if ;
    end process mux_select_line_pro ;   

    par_to_ser_pro : process(clk, rst_n)
     begin 
        if(rst_n) then 
             tx_data_o   <= '0';
             data_clr    <= '0';
             tx_valid_o  <= '0';
        elsif rising_edge(clk) then 
            if(s_req_i = '1') then 
                tx_data_o <= s_data_i(mux_sel_cntr);
                data_clr  <= '1'
            elsif (data_clr = '1') then 
                tx_data_o <= '0';
                data_clr  <= '0';
            end if;        
            tx_valid_o <= s_req_i ;      
        end if;
    end process par_to_ser_pro;

end rtl;
