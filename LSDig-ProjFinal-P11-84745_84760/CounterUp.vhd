library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity CounterUp is
	generic(N : positive := 99;    -- Sets the upper limit '99'
			  M : integer := 0);
	port(clk      : in  std_logic;
		  start_1  : in  std_logic; -- Increases the counter by 1 unit
		  start_2  : in  std_logic; -- Increases the counter by 2 unit
		  start_3  : in  std_logic; -- Increases the counter by 3 unit
		  reset    : in  std_logic;
		  count    : out std_logic_vector(7 downto 0)); -- Counts in  binary
end CounterUp;

architecture Behavioral of CounterUp is

	signal s_count : unsigned(7 downto 0) := to_unsigned(M,8); -- Initialized at '0' points

begin

	process(clk)
	begin
		if(rising_edge(clk)) then
			if(reset = '1') then
				s_count <= to_unsigned(M,8);
			elsif(start_1 = '1' and s_count <= N-1) then -- Sets the upper limit 'N'
				s_count <= s_count + 1;							-- increments 1 unit
			elsif(start_2 = '1' and s_count <= N-2) then -- Sets the upper limit 'N-1'
				s_count <= s_count + 2;							-- increments 2 units
			elsif(start_3 = '1' and s_count <= N-3) then -- Sets the upper limit 'N-2'
				s_count <= s_count + 3;                   -- increments 3 units
			else
				s_count <= s_count;
			end if;
		end if;
	end process;
	count <= std_logic_vector(s_count);
	
end Behavioral;