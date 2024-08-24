----------------------------------------------------------------------------------
-- It is used to prevent bouncing from push button
	-- Push button will be used for ov7670 instantiation
-- This design will remove bouncing within 300 ms after trigerring process
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity debounce_circuit is
Generic (PB_BITS : integer := 0);
    Port ( clk : in  STD_LOGIC;
           input : in  STD_LOGIC;
           output : out  STD_LOGIC);
end debounce_circuit;

architecture Behavioral of debounce_circuit is

constant MAX : unsigned(PB_BITS-1 downto 0) := (others => '1');
constant MIN : unsigned(PB_BITS-1 downto 0) := (others => '0');

signal counter : unsigned(PB_BITS-1 downto 0) := (others => '0');
--signal counter : unsigned(1 downto 0) := (others => '0');

begin
counting_proc : process (clk) begin
	if rising_edge (clk) then
		if input = '1' then
			if counter = MAX then 
			-- Counter will count 2^24 * 20ns
			-- ~300ms
				output <= '1';
				counter <= MIN;
			else
			-- Bouncing with high logic below 300ms will not trigger the output
			-- output, this case, pb that reset the camera
				output <= '0';
				counter <= counter + 1;
			end if;
		else
			output <= '0';
			counter <= MIN;
		end if;
	end if;
end process counting_proc;
end Behavioral;

