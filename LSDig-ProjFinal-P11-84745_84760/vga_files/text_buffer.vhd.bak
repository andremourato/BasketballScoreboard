----------------------------------------------------------------------------------------------------------------------------------------------------------------
-- LSD.TOS, March 2017 (DO NOT REMOVE THIS LINE)
--
-- Text buffer (RAM with one synchronous read port and one write port)
--
-- There are 128 rows and 128 columns
--

library ieee;
use     ieee.std_logic_1164.all;
use     ieee.numeric_std.all;

entity text_buffer is
  port
  (
    clock : in  std_logic; -- main clock

    write_row     : in std_logic_vector(6 downto 0); -- row number for writes
    write_column  : in std_logic_vector(6 downto 0); -- column number for writes
    write_data    : in std_logic_vector(6 downto 0); -- data to write
    write_enable  : in std_logic;                    -- write enable signal

    read_row_0    : in  std_logic_vector(6 downto 0); -- row number for reads
    read_column_0 : in  std_logic_vector(6 downto 0); -- column number for reads
    read_data_1   : out std_logic_vector(6 downto 0)  -- data read
  );
end text_buffer;

architecture v1 of text_buffer is
  --
  -- dual port RAM memory
  --
  type ram_t is array(0 to 128*128-1) of std_logic_vector(6 downto 0);
  signal ram : ram_t;
  --
  -- Addresses
  --
  signal write_addr   : std_logic_vector(13 downto 0);
  signal read_addr_0x : std_logic_vector(13 downto 0);
begin
  write_addr <= write_row & write_column;
  read_addr_0x <= read_row_0 & read_column_0;
  --
  -- Dual port ram
  --
  process(clock) is
  begin
    if rising_edge(clock) then
      if write_enable = '1' then
        ram(to_integer(unsigned(write_addr))) <= write_data;
      end if;
      read_data_1 <= ram(to_integer(unsigned(read_addr_0x)));
    end if;
  end process;
end v1;
