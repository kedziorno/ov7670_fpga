----------------------------------------------------------------------------------
-- This entity converts 50MHz clock to 25MHz clock.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clk25gen is
    Port ( clk50 : in  STD_LOGIC;
           clk25 : out  STD_LOGIC);
end clk25gen;

architecture Behavioral of clk25gen is
signal clkbuf : STD_LOGIC := '0';
begin
	process (clk50) is
    constant max : integer := 1; -- 50M
--    constant max : integer := 2; -- 100M
    variable i : integer range 0 to max-1 := 0;
  begin
		if rising_edge(clk50) then
    if (i = max-1) then
      i := 0;
			clkbuf <= not (clkbuf);
    else
      i := i + 1;
		end if;
    end if;
	end process;
			clk25 <= not(clkbuf);
end Behavioral;

