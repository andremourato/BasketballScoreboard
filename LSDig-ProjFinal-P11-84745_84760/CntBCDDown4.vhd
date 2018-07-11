library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;

entity CntBCDDown4 is
	generic(N 		: unsigned := X"1000");
	port(reset		: in  std_logic;
		  clk			: in  std_logic;
		  enable	   : in  std_logic;
		  count		: out std_logic_vector(15 downto 0));
end CntBCDDown4;

architecture Behavioral of CntBCDDown4 is

	signal s_count : unsigned(15 downto 0) := N;-- Initialized at 10 minutes(X"1000") 

begin

	count_proc : process(clk)
	begin
		
		if (reset = '1') then
			s_count <= N; -- RESETS TO INITIAL VALUE
		elsif (rising_edge(clk)) then
			if (enable = '1' and s_count /= X"0") then -- If it is enabled and isn't at '0'
				if (s_count(3 downto 0) = X"0") then
					s_count(3 downto 0) <= X"9";
					if (s_count(7 downto 4) = X"0") then
						s_count(7 downto 4) <= X"5";
						if (s_count(11 downto 8) = X"0") then
							s_count(11 downto 8) <= X"9";
							if (s_count(15 downto 12) = X"1") then
								s_count(15 downto 12) <= X"0";
							else
								s_count(15 downto 12) <= X"0";
							end if;
						else
							s_count(11 downto 8) <= s_count(11 downto 8) - 1;
						end if;
					else
						s_count(7 downto 4) <= s_count(7 downto 4) - 1;
					end if;
				else
					s_count(3 downto 0) <= s_count(3 downto 0) - 1;
				end if;
			end if;
		end if;
	end process;

	count <= std_logic_vector(s_count);
end Behavioral;
