library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
use ieee.numeric_std.all;

entity address_generator is
Generic (
PIXELS : integer := 0;
ADDRESS1 : integer := 0
);
  Port ( 
    reset : in std_logic;
		clk25 : in STD_LOGIC;
    enable : in STD_LOGIC;
    vsync : in STD_LOGIC;
    address : out STD_LOGIC_VECTOR (ADDRESS1-1 downto 0)
  );  
end address_generator;


architecture Behavioral of address_generator is

  signal addr: STD_LOGIC_VECTOR(address'range) := (others => '0');
  signal tva: STD_LOGIC_VECTOR(address'range) := (others => '0');
  
begin

--  address <= addr; 

process (clk25,reset)
variable va : std_logic_vector(address'range);
constant CMAX1 : integer := 160;
constant CMAX2 : integer := 3;
variable vmax1 : integer range 0 to CMAX1-1;
variable vmax2 : integer range 0 to CMAX2-1;
variable a,b,c,d : integer;
begin
if (reset = '1') then
addr <= (others => '0');
tva <= (others => '0');
vmax1 := 0;
vmax2 := 0;
	elsif rising_edge (clk25) then
		if (enable='1') then
			if (to_integer(unsigned(addr)) = PIXELS-1) then
			addr <= (others => '0');
			else
			addr <= std_logic_vector(to_unsigned(to_integer(unsigned(addr)) + 1,address'left+1));
			end if;
			report "va : "&integer'image(to_integer(unsigned(va))) severity warning;
			va := std_logic_vector(to_unsigned(to_integer(unsigned(addr))-CMAX1,address'left+1));
			vmax1 := 0;
--		else
--			addr <= addr;
--			va := (others => '0');
			address <= addr;
		end if;
		if (enable='0') then
--						va := std_logic_vector(to_unsigned(to_integer(unsigned(addr))-CMAX1-1,address'left+1));
--addr <= addr;
--			if (vmax2 = CMAX2-1) then
--				vmax2 <= 0;
--			else
				if (vmax1 = CMAX1-1) then
--					tva <= std_logic_vector(to_unsigned(to_integer(unsigned(addr))-CMAX1+1,address'left+1));
					vmax1 := 0;
--					va := (others => '0');
				else
--					va := std_logic_vector(to_unsigned(to_integer(unsigned(va))+1,address'left+1));
					vmax1 := vmax1 + 1;
				end if;
				va := std_logic_vector(to_unsigned(vmax1,address'left+1));
--				vmax2 <= vmax2 + 1;
--			end if;
				address <= std_logic_vector(to_unsigned(to_integer(unsigned(addr))+to_integer(unsigned(va))-CMAX1,address'left+1));
		end if;
		if vsync = '0' then -- this V depend from VGA
			addr <= (others => '0');
		end if;
	end if;
	tva <= va;
end process;    
end Behavioral;
