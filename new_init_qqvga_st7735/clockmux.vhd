----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    13:34:24 08/16/2022 
-- Design Name: 
-- Module Name:    clockmux - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

-- This design is not completed. It is left as an exercise for
-- the reader to complete this clock multiplexer.
-- from VHDL Language Kevin Skahill CH 6 REPEATER - CLOCKMUX

library UNISIM;
use UNISIM.VComponents.all;

entity clockmux is
generic (N : integer := 4);
port (
	i_reset : in std_logic; -- Asynch Resets
	i_clk : in std_logic_vector(N-1 downto 0); -- Clock 1-N
	i_sel : in std_logic_vector(N-1 downto 0); -- Clock Select Mux N
	o_clk : buffer std_logic -- out
);
end clockmux;

architecture a1 of clockmux is

component rdff1b is port (
clk, reset: in std_logic;
d: in std_logic; 
q: buffer std_logic; 
qb: buffer std_logic); 
end component rdff1b;
for all : rdff1b use entity work.rdff1b(archrdff1b);

signal clockp,clockn,t1,t2,t3,andout,sel : std_logic_vector(N-1 downto 0);

signal vor : std_logic_vector(N-1 downto 0) := (others => '0');
--signal vand : std_logic := '1';

type ta is array (0 to N-1) of std_logic_vector(N-1 downto 0);
signal a : ta;

begin

--vor <= '0' when i_reset = '1' else vor;
--vand <= '1' when i_reset = '1' else vand;

--g0 : for i in 0 to N-1 generate
--	u0 : rdff1b port map (clk => clockp(i), reset => i_reset, d => sel(i), q => t1(i), qb => open);
--	u1 : rdff1b port map (clk => clockn(i), reset => i_reset, d => t1(i), q => t2(i), qb => t3(i));
--	u2 : AND2 port map (I0 => t2(i), I1 => clockp(i), O => andout(i));
--end generate g0;

g0 : for i in 0 to N-1 generate
	u0 : rdff1b port map (clk => clockp(i), reset => i_reset, d => sel(i), q => t1(i), qb => t3(i));
	u2 : AND2 port map (I0 => t1(i), I1 => clockp(i), O => andout(i));
end generate g0;

--sel(0) <= i_sel(0) and t3(1) and t3(2) and t3(3);
--sel(1) <= t3(0) and i_sel(1) and t3(2) and t3(3);
--sel(2) <= t3(0) and t3(1) and i_sel(2) and t3(3);
--sel(3) <= t3(0) and t3(1) and t3(2) and i_sel(3);

--g5 : for i in 0 to N-1 generate
--	g5a : for j in 0 to N-1 generate
--		g5b : if (i=j) generate
--		a(i)(j) <= '1';
--		end generate g5b;
--		g5c : if (i/=j) generate
--			a(i)(j) <= '0';
--		end generate g5c;
--	end generate g5a;
--end generate g5;

g2 : process (i_reset,i_sel,t3,a) is
variable vand : std_logic;
begin
	if (i_reset = '1') then
	vand := '1';
	sel <= (others => '0');
	else
	l0 : for i in 0 to N-1 loop
		vand := '1';
	l1 : for j in 0 to N-1 loop
	if (i=j) then
--		a1 : AND2 port map (I0 => vand, I1 => i_sel(i), O => vand);
		a1 : vand := i_sel(i) and vand;
	elsif (i/=j) then
--		a2 : AND2 port map (I0 => vand, I1 => t3(i), O => vand);
		a2 : vand := t3(i) and vand;
	else
		a3 : vand := '1';
	end if;
	end loop l1;
	sel(i) <= vand;
	end loop l0;
	end if;
end process g2;

--g2 : for i in 0 to N-1 generate
--g2a : for j in 0 to N-1 generate
--begin
--	g2b : if (a(i)(j)='1') generate
--		g2bb : AND2 port map (I0 => vand, I1 => i_sel(i), O => vand);
--	end generate g2b;
--	g2c : if (a(i)(j)='0') generate
--		g2cc : AND2 port map (I0 => vand, I1 => t3(i), O => vand);
--	end generate g2c;
--	sel(i) <= vand;
--end generate g2a;
--end generate g2;

g1 : process (i_reset,andout) is
	variable vor : std_logic;
begin
	if (i_reset = '1') then
		vor := '0';
		o_clk <= '0';
	else
		vor := '0';
		l0 : for i in 0 to N-1 loop
			vor := andout(i) or vor;
		end loop l0;
	end if;
	o_clk <= vor;
end process g1;

--g1 : for i in 0 to N-1 generate
----	shared variable v : std_logic_vector(N-1 downto 0) := (others => '0');
--begin
--	g1c : if (i=0) generate
--		vor(i) <= andout(i);
----		g1aa : OR2 port map (I0 => vor(i), I1 => andout(i), O => vor(i));
--	end generate g1c;
--	g1a : if (i>0 and i<N-1) generate
----		g1aa : OR2 port map (I0 => vor(i-1), I1 => andout(i), O => vor(i));
--		vor(i) <= andout(i) or vor(i-1);
--	end generate g1a;
--	g1b : if (i=N-1) generate
----		g1bb : OR2 port map (I0 => vor(i-1), I1 => andout(i), O => vor(i));
--			vor(i) <= andout(i) or vor(i-1);
--			o_clk <= vor(i);
--	end generate g1b;
--end generate g1;

g3 : for i in 0 to N-1 generate
	g3a : clockp(i) <= i_clk(i);
end generate g3;

g4 : for i in 0 to N-1 generate
	g4a : clockn(i) <= not i_clk(i);
end generate g4;

end architecture a1;
