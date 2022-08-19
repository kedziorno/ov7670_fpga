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
signal va,a1,a0 : std_logic_vector(address'range);
  
begin

--address <= addr;
--addr <= a1 when enable='1' else a0 when enable = '0' else (others => '0');

process (clk25,reset)
constant CMAX1 : integer := 160;
--constant CMAX2 : integer := 3;
variable vmax1 : integer range 0 to CMAX1*3-1;
--variable vmax2 : integer range 0 to CMAX2-1;
variable tva,ta1,ta0 : std_logic_vector(address'range);
begin
if (reset = '1') then
tva := (others => '0');
ta0 := (others => '0');
ta1 := (others => '0');
addr <= (others => '0');
vmax1 := 0;
--vmax2 := 0;
	elsif rising_edge (clk25) then
		if (enable='1') then
			if (to_integer(unsigned(addr)) = PIXELS-1) then
			ta1 := (others => '0');
			else
			ta1 := std_logic_vector(to_unsigned(to_integer(unsigned(ta1))+1,address'left+1));
			end if;
--			report "va : "&integer'image(to_integer(unsigned(va))) severity warning;
			tva := std_logic_vector(to_unsigned(to_integer(unsigned(ta1))-CMAX1,address'left+1));
			addr <= ta1;
			vmax1 := 0;
--		else
--			addr <= addr;
--			va := (others => '0');
--			a1 <= ta1;
va <= tva;
address <= ta1;
end if;
if (enable='0') then
--a0 <= (others => '0');
--						va := std_logic_vector(to_unsigned(to_integer(unsigned(addr))-CMAX1-1,address'left+1));
--addr <= addr;
--			if (vmax2 = CMAX2-1) then
--				vmax2 <= 0;
--			else
--if (vmax2 = CMAX2-1) then
--a0 <= (others => '0');
--vmax2 <= 0;
--vmax1 <= 0;
--va <= (others => '0');
--else
--ta0 := (others => '0');
--vmax2 <= 0;
--vmax1 := 0;
--tva := (others => '0');

				if (vmax1 >= 0 and vmax1 < CMAX1*1) then
--					va := std_logic_vector(to_unsigned(to_integer(unsigned(va))+1,address'left+1));
--					vmax1 <= vmax1 + 1;
vmax1 := vmax1 + 1;				
				ta0 := std_logic_vector(to_unsigned(to_integer(unsigned(tva))+to_integer(unsigned(addr))-CMAX1,address'left+1));
				tva := std_logic_vector(to_unsigned(vmax1,address'left+1));
				end if;
				if (vmax1 >= CMAX1*1 and vmax1 < CMAX1*2) then
----					tva <= std_logic_vector(to_unsigned(to_integer(unsigned(addr))-CMAX1+1,address'left+1));
----					va := (others => '0');
--ta0 := (others => '0');
--vmax2 <= 0;
--vmax1 := 0;
tva := (others => '0');
--				if (vmax1 <= CMAX1*2-1) then
--					va := std_logic_vector(to_unsigned(to_integer(unsigned(va))+1,address'left+1));
--					vmax1 <= vmax1 + 1;
--				va <= std_logic_vector(to_unsigned(vmax1-CMAX1,address'left+1));
--				a0 <= std_logic_vector(to_unsigned(to_integer(unsigned(addr))+to_integer(unsigned(va)),address'left+1));
--				end if;
--				vmax2 <= vmax2 + 1;
					
				end if;
				if (vmax1 >= CMAX1*2 and vmax1 < CMAX1*3-1) then
----					tva <= std_logic_vector(to_unsigned(to_integer(unsigned(addr))-CMAX1+1,address'left+1));
----					va := (others => '0');
--ta0 := (others => '0');
--vmax2 <= 0;
--vmax1 := 0;
tva := addr;
				end if;
va <= tva;
address <= ta0;

		end if;
		if vsync = '0' then -- this V depend from VGA
			addr <= (others => '0');
		end if;
	end if;
--	tva <= va;
end process;    
end Behavioral;



--library IEEE;
--use IEEE.STD_LOGIC_1164.ALL;
--use IEEE.STD_LOGIC_ARITH.ALL;
--use IEEE.STD_LOGIC_UNSIGNED.ALL;
--
--entity address_generator is
--Generic (
--PIXELS : integer := 0;
--ADDRESS1 : integer := 0
--);
--  Port ( 
--    reset : in std_logic;
--		clk25 : in STD_LOGIC;
--    enable : in STD_LOGIC;
--    vsync : in STD_LOGIC;
--    address : out STD_LOGIC_VECTOR (ADDRESS1-1 downto 0)
--  );  
--end address_generator;
--
--
--architecture Behavioral of address_generator is
--
--  signal addr: STD_LOGIC_VECTOR(address'range) := (others => '0');
--  
--begin
--
--  address <= addr; 
--
--process (clk25,reset) begin
--if (reset = '1') then
--addr <= (others => '0');
--	elsif rising_edge (clk25) then
--		if (enable='1') then
--			if (addr = PIXELS-1) then
--			addr <= (others => '0');
--			else
--			addr <= addr + 1 ;
--			end if;
--		else
--		addr <= addr;
--		end if;
--		
--		if vsync = '0' then -- this V depend from VGA
--			addr <= (others => '0');
--		end if;
--	end if;
--end process;    
--end Behavioral;
