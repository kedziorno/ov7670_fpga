-- This design is not completed. It is left as an exercise for
-- the reader to complete this clock multiplexer.
-- from VHDL Language Kevin Skahill CH 6 REPEATER - CLOCKMUX

library ieee;
use ieee.std_logic_1164.all;
library UNISIM;
use UNISIM.VComponents.all;

entity clockmux is port (
	areset           : in std_logic;        -- Asynch Reset
	clk1             : in std_logic;        -- Clock 1
	clk2             : in std_logic;        -- Clock 2
	clk3             : in std_logic;        -- Clock 3
	clk4             : in std_logic;        -- Clock 4
	clk5             : in std_logic;        -- Clock 5
	clk6             : in std_logic;        -- Clock 6
	clk7             : in std_logic;        -- Clock 7
	clk8             : in std_logic;        -- Clock 8
	clk9             : in std_logic;        -- Clock 9
	sel1             : in std_logic;        -- Clock Select 1
	sel2             : in std_logic;        -- Clock Select 2
	sel3             : in std_logic;        -- Clock Select 3
	sel4             : in std_logic;        -- Clock Select 4
	sel5             : in std_logic;        -- Clock Select 5
	sel6             : in std_logic;        -- Clock Select 6
	sel7             : in std_logic;        -- Clock Select 7
	sel8             : in std_logic;        -- Clock Select 8
	sel9             : in std_logic;        -- Clock Select 9
	rxclk            : buffer std_logic);      -- RX Clock
end clockmux;

architecture a1 of clockmux is
	signal t : std_logic_vector(8 downto 0);
	signal o : std_logic;
begin
	p0 : process (areset) is
	begin
		if (areset = '1') then
			rxclk <= '0';
		else
			rxclk <= o;
		end if;
	end process p0;

	t <= sel1 & sel2 & sel3 & sel4 & sel5 & sel6 & sel7 & sel8 & sel9;

	with t select o <=
	clk1 when "000000001",
	clk2 when "000000010",
	clk3 when "000000100",
	clk4 when "000001000",
	clk5 when "000010000",
	clk6 when "000100000",
	clk7 when "001000000",
	clk8 when "010000000",
	clk9 when "100000000",
	'X' when others;
end architecture a1;

architecture a2 of clockmux is

component rdff1b is port (
clk, reset: in std_logic;
d: in std_logic; 
q: buffer std_logic; 
qb: buffer std_logic); 
end component rdff1b;
for all : rdff1b use entity work.rdff1b(archrdff1b);

signal clockp,clockn,t1,t2,t3,andout,sel : std_logic_vector(8 downto 0);

begin

--g0 : for i in 0 to 8 generate
--	u0 : rdff1b port map (clk => clockp(i), reset => areset, d => sel(i), q => t1(i), qb => open);
--	u1 : rdff1b port map (clk => clockn(i), reset => areset, d => t1(i), q => t2(i), qb => t3(i));
--	u2 : AND2 port map (I0 => t2(i), I1 => clockp(i), O => andout(i));
--end generate g0;

g0 : for i in 0 to 8 generate
	u0 : rdff1b port map (clk => clockp(i), reset => areset, d => sel(i), q => t1(i), qb => t3(i));
	u2 : AND2 port map (I0 => t1(i), I1 => clockp(i), O => andout(i));
end generate g0;

sel(0) <= sel1 and t3(1) and t3(2) and t3(3) and t3(4) and t3(5) and t3(6) and t3(7) and t3(8);
sel(1) <= t3(0) and sel2 and t3(2) and t3(3) and t3(4) and t3(5) and t3(6) and t3(7) and t3(8);
sel(2) <= t3(0) and t3(1) and sel3 and t3(3) and t3(4) and t3(5) and t3(6) and t3(7) and t3(8);
sel(3) <= t3(0) and t3(1) and t3(2) and sel4 and t3(4) and t3(5) and t3(6) and t3(7) and t3(8);
sel(4) <= t3(0) and t3(1) and t3(2) and t3(3) and sel5 and t3(5) and t3(6) and t3(7) and t3(8);
sel(5) <= t3(0) and t3(1) and t3(2) and t3(3) and t3(4) and sel6 and t3(6) and t3(7) and t3(8);
sel(6) <= t3(0) and t3(1) and t3(2) and t3(3) and t3(4) and t3(5) and sel7 and t3(7) and t3(8);
sel(7) <= t3(0) and t3(1) and t3(2) and t3(3) and t3(4) and t3(5) and t3(6) and sel8 and t3(8);
sel(8) <= t3(0) and t3(1) and t3(2) and t3(3) and t3(4) and t3(5) and t3(6) and t3(7) and sel9;

rxclk <= andout(0) or andout(1) or andout(2) or andout(3) or andout(4) or andout(5) or andout(6) or andout(7) or andout(8);

clockp(0) <= clk1;
clockp(1) <= clk2;
clockp(2) <= clk3;
clockp(3) <= clk4;
clockp(4) <= clk5;
clockp(5) <= clk6;
clockp(6) <= clk7;
clockp(7) <= clk8;
clockp(8) <= clk9;

clockn(0) <= not clk1;
clockn(1) <= not clk2;
clockn(2) <= not clk3;
clockn(3) <= not clk4;
clockn(4) <= not clk5;
clockn(5) <= not clk6;
clockn(6) <= not clk7;
clockn(7) <= not clk8;
clockn(8) <= not clk9;

end architecture a2;