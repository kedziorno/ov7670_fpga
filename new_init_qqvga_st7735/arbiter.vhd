----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    19:34:57 08/16/2022 
-- Design Name: 
-- Module Name:    arbiter - Behavioral 
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

library ieee;
use ieee.std_logic_1164.all;
--use work.regs_pkg.all;
--use work.synch_pkg.all;
--use work.counters_pkg.all;
-- The following lines are added for Warp to find entities in the
-- basic library.
--use basic.rdff1; use basic.pdff1;

-- from VHDL Language Kevin Skahill CH 6 REPEATER - ARBITRER
entity arbiter is port(
		 txclk:                 in std_logic;   -- TX_CLK
		 areset:                in std_logic;   -- Asynch Reset
		 activity1:             in std_logic;   -- Port Activity 1       
		 activity2:             in std_logic;   -- Port ACtivity 2
		 activity3:             in std_logic;   -- Port ACtivity 3
		 activity4:             in std_logic;   -- Port Activity 4       
		 sel1:                  buffer std_logic;  -- Port Select 1
		 sel2:                  buffer std_logic;  -- Port Select 2
		 sel3:                  buffer std_logic;  -- Port Select 3
		 sel4:                  buffer std_logic;  -- Port Select 4
		 nosel:                 buffer std_logic;  -- No Port Selected
		 carrier:               buffer std_logic;  -- Carrier Detected
		 collision:             buffer std_logic); -- Collision Detected
end arbiter;

architecture archarbiter of arbiter is
--      Signals

signal  colin, carin: std_logic;
signal  activityin1, activityin2, activityin3, activityin4: std_logic;
signal  activityin5, activityin6, activityin7, activityin8: std_logic;
signal  noactivity: std_logic;

component rdff1 is port (
    clk, reset: in std_logic;
    d:      in std_logic; 
    q:      buffer std_logic); 
end component rdff1;
for all : rdff1 use entity work.rdff1(archrdff1);

component pdff1 is port (
	clk, preset:    in std_logic;
	d:              in std_logic; 
	q:              buffer std_logic); 
end component pdff1;
for all : pdff1 use entity work.pdff1(archpdff1);

begin
--      Components

u1: rdff1 port map  (txclk, areset, activityin1, sel1);
u2: rdff1 port map  (txclk, areset, activityin2, sel2);
u3: rdff1 port map  (txclk, areset, activityin3, sel3);
u4: rdff1 port map  (txclk, areset, activityin4, sel4);

u9: pdff1 port map  (txclk, areset, noactivity, nosel);

u10: rdff1 port map (txclk, areset, colin, collision);
u11: rdff1 port map (txclk, areset, carin, carrier);

--      Arstd_logicration Select Logic
	activityin1  <= activity1;

	activityin2  <= activity2 
		       AND NOT activity1;

	activityin3  <= activity3 
		       AND NOT(activity1 OR activity2);
		   
	activityin4  <= activity4
		       AND NOT(activity1 OR activity2 OR activity3);

	noactivity   <= NOT(activity1 OR activity2 OR activity3 OR activity4);
 
-- inserted parenthesis around each group for (a * (b + c + ...)) OR (...
	colin        <= (activity1 AND (activity2 OR activity3 OR activity4)) OR

		       (activity2 AND (activity1 OR activity3 OR activity4)) OR

		       (activity3 AND (activity1 OR activity2 OR activity4)) OR

		       (activity4 AND (activity1 OR activity2 OR activity3));

  
	carin        <= activity1 OR activity2 OR activity3 OR activity4;
end archarbiter;        
