---------------------------------------------------------
-- This entity synchronize hsync and vsync to vga
-- Thanks to Pong P. Chu for creating basic things.
--------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity VGA_timing_synch is
    Port ( clk25 : in  STD_LOGIC;
           Hsync : out  STD_LOGIC;
           Vsync : out  STD_LOGIC;
           activeArea1 : out  STD_LOGIC;
           activeArea2 : out  STD_LOGIC;
           activeArea3 : out  STD_LOGIC;
           activeArea4 : out  STD_LOGIC);
end VGA_timing_synch;

architecture Behavioral of VGA_timing_synch is

constant HD : INTEGER := 639;
constant HFP : INTEGER := 16;
constant HSP : INTEGER := 96;
constant HBP : INTEGER := 48;

constant VD : INTEGER := 479;
constant VFP : INTEGER := 10;
constant VSP : INTEGER := 2;
constant VBP : INTEGER := 33;

signal clk_vga : STD_LOGIC;
signal hcnt,vcnt : INTEGER := 0;

signal h,v : std_logic;

begin
clk_vga <= clk25;
count_proc : process(clk_vga,vcnt,hcnt) begin
		if rising_edge(clk_vga) then
			if (hcnt = (HD+HFP+HSP+HBP)) then
				hcnt <= 0;
				if (vcnt = (VD+VFP+VSP+VBP)) then
					vcnt <= 0;
				else
					vcnt <= vcnt + 1;
				end if;
			else
				hcnt <= hcnt +1;
			end if;
		end if;
end process count_proc;

hsync_gen : process(clk_vga) begin
	if rising_edge(clk_vga) then
		if (hcnt <= (HD+HFP) or hcnt >= (HD+HFP+HSP)) then 
			h <= '1';
		else
			h <= '0';
		end if;
	end if;
end process hsync_gen;

vsync_gen : process(clk_vga) begin
	if rising_edge(clk_vga) then
		if (vcnt <= (VD+VFP) or vcnt >= (VD+VFP+VSP)) then
			v <= '1';
		else
			v <= '0';
		end if;
	end if;
end process vsync_gen;

activeArea1 <= '1' when (hcnt >= 0 and hcnt < 160) and (vcnt < 120) else '0';
activeArea2 <= '1' when (hcnt >= 160 and hcnt < 320) and (vcnt < 120) else '0';
activeArea3 <= '1' when (hcnt >= 320 and hcnt < 480) and (vcnt < 120) else '0';
activeArea4 <= '1' when (hcnt >= 480 and hcnt < 640) and (vcnt < 120) else '0';

Hsync <= h;
Vsync <= v;

end Behavioral;
