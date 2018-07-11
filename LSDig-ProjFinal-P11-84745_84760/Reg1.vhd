library IEEE;
use IEEE.STD_LOGIC_1164.all;

entity Reg1 is
	port(asyncReset : in  std_logic;
		  clk			 : in  std_logic;
		  enable		 : in  std_logic;
		  dataIn		 : in  std_logic;
		  dataOut	 : out std_logic);
end Reg1;

architecture Behavioral of Reg1 is
begin
	reg_proc : process(asyncReset, clk)
	begin
		if (asyncReset = '1') then
			dataOut <= '0';
		elsif (rising_edge(clk)) then
			if (enable = '1') then
				dataOut <= dataIn;
			end if;
		end if;
	end process;
end Behavioral;
