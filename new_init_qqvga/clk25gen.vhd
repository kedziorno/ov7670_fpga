----------------------------------------------------------------------------------
-- This entity converts 50MHz clock to 25MHz clock.
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity clk25gen is
    Port ( reset : in std_logic; clk50 : in  STD_LOGIC;
           clk25 : out  STD_LOGIC);
end clk25gen;

architecture Behavioral of clk25gen is
signal clkbuf : STD_LOGIC := '0';
begin
	process (clk50,reset) begin
	if (reset = '1') then
	clk25 <= '0';
	clkbuf <= '0';
		elsif rising_edge(clk50) then
			clk25 <= not(clkbuf);
			clkbuf <= not (clkbuf);
		end if;
	end process;
end Behavioral;

