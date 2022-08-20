--      D-Flip-Flop Library
--
--	Standard and generic sizes:
--	(1, 2, size)
--
--      clk    -- posedge clock input
--      preset  -- asynchronous preset
--      in     -- register input
--      out    -- register output
-----------------------
library ieee;
use ieee.std_logic_1164.all;
entity pdff1 is port (
clk, preset:    in std_logic;
d:              in std_logic; 
q:              buffer std_logic); 
end pdff1;
architecture archpdff1 of pdff1 is
begin
p1: process (preset, clk) begin
if preset = '1' then
q <= '1';
elsif (rising_edge(clk)) then
q <= d;
end if;
end process;
end archpdff1;
-----------------------
library ieee;
use ieee.std_logic_1164.all;
entity pdff2 is port (
clk, preset:    in std_logic;
d:              in std_logic_vector(1 downto 0); 
q:              buffer std_logic_vector(1 downto 0)); 
end pdff2;
architecture archpdff2 of pdff2 is
begin
p1: process (preset, clk) begin
if preset = '1' then
q <= (others => '1');
elsif (rising_edge(clk)) then
q <= d;
end if;
end process;
end archpdff2;
-----------------------
library ieee;
use ieee.std_logic_1164.all;
entity pdff is 
generic (size: integer := 3);
port ( 	clk, preset:    in std_logic;
d:              in std_logic_vector(size-1 downto 0); 
q:              buffer std_logic_vector(size-1 downto 0)); 
end pdff;
architecture archpdff of pdff is
begin
p1: process (preset, clk) begin
if preset = '1' then
q <= (others => '1');
elsif (rising_edge(clk)) then
q <= d;
end if;
end process;
end archpdff;
