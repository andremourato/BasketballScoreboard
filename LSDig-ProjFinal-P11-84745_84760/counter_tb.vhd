library IEEE;
use IEEE.STD_LOGIC_1164.all;


entity counter_tb is 
end counter_tb;


architecture Stimulus of counter_tb is 
	signal s_clk,start_tb,reset_tb: std_logic;
	signal count_tb : std_logic_vector (6 downto 0 );
begin
	uut: entity work.CounterUp(Behavioral)
		port map (clk  =>s_clk,
					 start=>start_tb,
					 reset=>reset_tb,
					 count=>count_tb);
	
	Syncronous_process:process
	
	begin 
		
		s_clk<='0'; wait for 100 ns;
		s_clk<='1'; wait for 100 ns;
		
	end process;
	
	Asyncronous_process:process
	
	begin 
		
		start_tb<='1';
		reset_tb<='0';
		wait for 40 ns;
		
		start_tb<='1';
		reset_tb<='0';
		wait for 40 ns;
		
		start_tb<='1';
		reset_tb<='0';
		wait for 40 ns;
		
		start_tb<='1';
		reset_tb<='0';
		wait for 40 ns;
				start_tb<='1';
		reset_tb<='0';
		wait for 40 ns;
		
		start_tb<='1';
		reset_tb<='1';
		wait for 40 ns ;
		
		start_tb<='0';
		reset_tb<='1';
		wait for 40 ns ;
		
		start_tb<='0';
		reset_tb<='0';
		wait for 40 ns;
		
		
		
	end process;
	

	
end Stimulus;