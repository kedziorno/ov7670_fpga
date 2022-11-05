library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity address_generator is
Generic (PIXELS : integer := 0);
  Port ( 
    reset : in std_logic; clk25 : in STD_LOGIC;
    enable : in STD_LOGIC;
    vsync : in STD_LOGIC;
    address : out STD_LOGIC_VECTOR (14 downto 0)
  );  
end address_generator;


architecture Behavioral of address_generator is

  signal addr: STD_LOGIC_VECTOR(address'range) := (others => '0');
  
begin

  address <= addr; 

process (clk25,reset) begin
if (reset = '1') then
addr <= (others => '0');
	elsif rising_edge (clk25) then
		if (enable='1') then
			if (addr = PIXELS-1) then
			addr <= (others => '0');	
			else
			addr <= addr + 1 ;
			end if;
		end if;
		
		if vsync = '0' then 
			addr <= (others => '0');
		end if;
	end if;
end process;    
end Behavioral;
