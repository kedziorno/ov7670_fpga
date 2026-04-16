library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity address_generator is
  Port ( 
    clk25 : in STD_LOGIC;
    enable : in STD_LOGIC;
    vsync : in STD_LOGIC;
    address : out STD_LOGIC_VECTOR (18 downto 0);
    address1 : out STD_LOGIC_VECTOR (9 downto 0)
  );  
end address_generator;


architecture Behavioral of address_generator is

  signal addr: STD_LOGIC_VECTOR(address'range) := (others => '0');
  signal addr1: STD_LOGIC_VECTOR(address1'range) := (others => '0');
  
begin

  address <= addr; 
  address1 <= addr1; 

process (clk25) begin
	if rising_edge (clk25) then
		if (enable='1') then
			if (addr < 307200-1) then
				addr <= addr + 1 ;
			else
			addr <= (others => '0');
			end if;
			if (addr1 < 640-1) then
				addr1 <= addr1 + 1 ;
			else
			addr1 <= (others => '0');
			end if;
		else
		addr <= addr;
		addr1 <= addr1;
		end if;
		
		if vsync = '0' then 
			addr <= (others => '0');
			addr1 <= (others => '0');
		end if;
	end if;
end process;    
end Behavioral;
