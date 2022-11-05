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
counting_proc : process (clk)
constant CV : integer := 256;
variable v : integer range 0 to CV-1 := 0;
begin
	if rising_edge (clk) then
		if input = '1' then
			if counter = MAX then 
			-- Counter will count 2^24 * 20ns
<<<<<<<< HEAD:new_init_qqvga/debounce_circuit.vhd
			-- ~300ms
				output <= '1';
				counter <= MIN;
========
			-- ~300ms
				if (v = CV-1) then
				counter <= MIN;
				v := 0;
				else
				output <= '1';
				v := v + 1;
				end if;
>>>>>>>> r1/new_init_qqvga_st7735:new_init_qqvga_st7735/debounce_circuit.vhd
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

