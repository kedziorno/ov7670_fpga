--      Set of D-Type Flip-Flops
--
--      sizes: (1, size)
--
--  clk    -- posedge clock input
--  reset  -- asynchronous reset
--  d      -- register input
--  q    -- register output
----------------------------------------
library ieee;
use ieee.std_logic_1164.all;
entity rdff1 is port (
    clk, reset: in std_logic;
    d:      in std_logic; 
    q:      buffer std_logic); 
end rdff1;

architecture archrdff1 of rdff1 is
begin
p1: process (reset, clk) begin
    if reset = '1' then
        q <= '0';
    elsif (rising_edge(clk)) then
        q <= d;
    end if;
   end process;
end archrdff1;
----------------------------------------
library ieee;
use ieee.std_logic_1164.all;
entity rdff1b is port (
    clk, reset: in std_logic;
    d:      in std_logic; 
    q:      buffer std_logic; 
    qb:     buffer std_logic); 
end rdff1b;

architecture archrdff1b of rdff1b is
begin
p1: process (reset, clk) begin
    if reset = '1' then
        q <= '0';
--				qb <= '1';
    elsif (rising_edge(clk)) then
        q <= d;
    end if;
   end process;
   qb <= not q;
end archrdff1b;
----------------------------------------
library ieee;
use ieee.std_logic_1164.all;
entity rdff is
    generic (size: integer := 2);
    port (  clk, reset: in std_logic;
        d:      in std_logic_vector(size-1 downto 0); 
        q:      buffer std_logic_vector(size-1 downto 0)); 
end rdff;

architecture archrdff of rdff is
begin
p1: process (reset, clk) begin
    if reset = '1' then
        q <= (others => '0');
    elsif (rising_edge(clk)) then
        q <= d;
    end if;
   end process;
end archrdff;
