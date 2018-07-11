library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity Bin2BCD_3Digits is
	port(binIn 	: in  std_logic_vector(7 downto 0);
		  bcdMS 	: out std_logic_vector(3 downto 0);
		  bcdMid : out std_logic_vector(3 downto 0);
		  bcdLS 	: out std_logic_vector(3 downto 0));
end Bin2BCD_3Digits;

architecture Behavioral of Bin2BCD_3Digits is
	
	signal s_bcdMS  : std_logic_vector(7 downto 0); -- Most significant bit
	signal s_bcdMid : std_logic_vector(7 downto 0);
	signal s_bcdLS  : std_logic_vector(7 downto 0); -- Least significant bit
	
begin

	s_bcdMS <= std_logic_vector(unsigned(binIn(7 downto 0))/100);
	s_bcdMid<= std_logic_vector((unsigned(binIn(7 downto 0))rem 100)/10);
	s_bcdLS <= std_logic_vector(unsigned(binIn(7 downto 0))rem 10);
	bcdMS <= s_bcdMS(3 downto 0);
	bcdMid <= s_bcdMid(3 downto 0);
	bcdLS <= s_bcdLS(3 downto 0);
	
end Behavioral;