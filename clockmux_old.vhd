-- This design is not completed. It is left as an exercise for
-- the reader to complete this clock multiplexer.
-- from VHDL Language Kevin Skahill CH 6 REPEATER - CLOCKMUX

library ieee;
use ieee.std_logic_1164.all;
library UNISIM;
use UNISIM.VComponents.all;

entity clockmux_old is port (
	areset           : in std_logic;        -- Asynch Reset
	clk1             : in std_logic;        -- Clock 1
	clk2             : in std_logic;        -- Clock 2
	clk3             : in std_logic;        -- Clock 3
	clk4             : in std_logic;        -- Clock 4
	clk0             : in std_logic;        -- clk main
	sel1             : in std_logic;        -- Clock Select 1
	sel2             : in std_logic;        -- Clock Select 2
	sel3             : in std_logic;        -- Clock Select 3
	sel4             : in std_logic;        -- Clock Select 4
	sel0             : in std_logic;        -- no select
	rxclk            : out std_logic);      -- RX Clock
end clockmux_old;

architecture a2 of clockmux_old is

component rdff1b is port (
clk, reset: in std_logic;
d: in std_logic; 
q: out std_logic; 
qb: out std_logic); 
end component rdff1b;
for all : rdff1b use entity work.rdff1b(archrdff1b);

signal clockp,clockn,t1,t2,t3,andout,sel : std_logic_vector(4 downto 0);

begin

--g0 : for i in 0 to 4 generate
--	u0 : rdff1b port map (clk => clockp(i), reset => areset, d => sel(i), q => t1(i), qb => open);
--	u1 : rdff1b port map (clk => clockn(i), reset => areset, d => t1(i), q => t2(i), qb => t3(i));
--	u2 : AND2 port map (I0 => t2(i), I1 => clockp(i), O => andout(i));
--end generate g0;

g0 : for i in 0 to 4 generate
	u0 : rdff1b port map (clk => clockp(i), reset => areset, d => sel(i), q => t1(i), qb => t3(i));
	u2 : AND2 port map (I0 => t1(i), I1 => clockp(i), O => andout(i));
end generate g0;

--p4 : process (areset) is
--begin
--if (areset = '1') then
--t1 <= (others => '0');
--t2 <= (others => '0');
--t3 <= (others => '0');
--andout <= (others => '0');
--end if;
--end process p4;

p3 : process (areset,andout) is
begin
if (areset = '1') then
rxclk <= '0';
else
rxclk <= andout(0) or andout(1) or andout(2) or andout(3) or andout(4);
end if;
end process p3;


--p2 : process (areset,sel1,sel2,sel3,sel4,sel0,t3) is
--begin
--if (areset = '1') then
--sel <= (others => '0');
--end if;
--end process p2;

sel(0) <= sel1 and t3(1) and t3(2) and t3(3) and t3(4);
sel(1) <= t3(0) and sel2 and t3(2) and t3(3) and t3(4);
sel(2) <= t3(0) and t3(1) and sel3 and t3(3) and t3(4);
sel(3) <= t3(0) and t3(1) and t3(2) and sel4 and t3(4);
sel(4) <= t3(0) and t3(1) and t3(2) and t3(3) and sel0;

p0 : process (areset,clk0) is
begin
if (areset = '1') then
clockp(3 downto 0) <= (others => '0');
elsif (rising_edge(clk0)) then
--if (rising_edge(clk0)) then
clockp(0) <= clk1;
clockp(1) <= clk2;
clockp(2) <= clk3;
clockp(3) <= clk4;
--clockp(4) <= clk0;
end if;
end process p0;

--p5 : process (areset) is
--begin
--if (areset = '1') then
--clockp(4) <= '0';
--clockn(4) <= '1';
--else
clockp(4) <= clk0;
clockn(4) <= not clk0;
--end if;
--end process p5;

p1 : process (areset,clk0) is
begin
if (areset = '1') then
clockn(3 downto 0) <= (others => '1');
elsif (rising_edge(clk0)) then
--if (rising_edge(clk0)) then
clockn(0) <= not clk1;
clockn(1) <= not clk2;
clockn(2) <= not clk3;
clockn(3) <= not clk4;
--clockn(4) <= not clk0;
end if;
end process p1;

end architecture a2;
