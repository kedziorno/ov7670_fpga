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
signal hcnt,vcnt : INTEGER range 0 to 1023 := 0;

signal h,v : std_logic;
signal hp,vp : std_logic;

signal v120 : std_logic;

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

--vsync_gen : process(clk_vga)
--constant C1 : integer := VD+VFP;
--constant C2 : integer := VD+VFP+VSP;
--variable count1 : integer range 0 to 1023 := 0;
--variable count2 : integer range 0 to 1023 := 0;
--type states is (sa,sb,sc,sd);
--variable state : states := sa;
--begin
--	if rising_edge(clk_vga) then
--		case (state) is
--			when sa =>
--				v <= '1';
--				if (vcnt = VD) then
--					state := sb;
--				else
--					state := sa;
--				end if;
--			when sb =>
--				v <= '1';
--				if (vcnt = VFP) then
--					state := sc;
--				else
--					state := sb;
--				end if;
--			when sc =>
--				v <= '0';
--				if (vcnt = VSP) then
--					state := sd;
--				else
--					state := sc;
--				end if;
--			when sd =>
--				v <= '1';
--				if (vcnt = VBP) then
--					state := sa;
--				else
--					state := sd;
--				end if;
--		end case;
--	end if;
--end process vsync_gen;

vsync_gen : process(clk_vga) begin
	if rising_edge(clk_vga) then
		if (vcnt <= (VD+VFP) or vcnt >= (VD+VFP+VSP)) then
			v <= '1';
		else
			v <= '0';
		end if;
	end if;
end process vsync_gen;

p1 : process (clk_vga) is
type states is (p0a,p0b);
variable state : states := p0a;
constant C1 : integer := 120;
constant C2 : integer := 480;
begin
	if (rising_edge(clk_vga)) then
		case (state) is
			when p0a =>
				v120 <= '1';
				if (vcnt = C1-1) then
					state := p0b;
				else
					state := p0a;
				end if;
			when p0b =>
				v120 <= '0';
				if (vcnt = C2-1) then
					state := p0a;
				else
					state := p0b;
				end if;
		end case;
	end if;
end process p1;

p0 : process (clk_vga) is
type states is (p0a,p0b,p0c,p0d,p0e);
variable state : states := p0a;
variable count1 : integer range 0 to 1023 := 0;
begin
	if (rising_edge(clk_vga)) then
		activeArea1 <= '0';
		activeArea2 <= '0';
		activeArea3 <= '0';
		activeArea4 <= '0';
		case (state) is
			when p0a =>
				if (v120 = '1') then
					if (hcnt = 160-1) then
						count1 := 0;
						state := p0b;
					else
						count1 := count1 + 1;
						state := p0a;
					end if;
					activeArea1 <= '1';
					activeArea2 <= '0';
					activeArea3 <= '0';
					activeArea4 <= '0';
				end if;
			when p0b =>
				if (v120 = '1') then
					if (hcnt = 320-1) then
						count1 := 0;
						state := p0c;
					else
						count1 := count1 + 1;
						state := p0b;
					end if;
					activeArea1 <= '0';
					activeArea2 <= '1';
					activeArea3 <= '0';
					activeArea4 <= '0';
				end if;
			when p0c =>
				if (v120 = '1') then
					if (hcnt = 480-1) then
						count1 := 0;
						state := p0d;
					else
						count1 := count1 + 1;
						state := p0c;
					end if;
					activeArea1 <= '0';
					activeArea2 <= '0';
					activeArea3 <= '1';
					activeArea4 <= '0';
				end if;
			when p0d =>
				if (v120 = '1') then
					if (hcnt = 640-1) then
						count1 := 0;
						state := p0e;
					else
						count1 := count1 + 1;
						state := p0d;
					end if;
					activeArea1 <= '0';
					activeArea2 <= '0';
					activeArea3 <= '0';
					activeArea4 <= '1';
				end if;
			when p0e =>
				if (v120 = '1') then
					if (hcnt = 800-1) then
						count1 := 0;
						state := p0a;
					else
						count1 := count1 + 1;
						state := p0e;
					end if;
					activeArea1 <= '0';
					activeArea2 <= '0';
					activeArea3 <= '0';
					activeArea4 <= '0';
				end if;
		end case;
	end if;
end process p0;

--activeArea1 <= '1' when (hcnt >= 0 and hcnt < 160) and (vcnt < 120) else '0';
--activeArea2 <= '1' when (hcnt >= 160 and hcnt < 320) and (vcnt < 120) else '0';
--activeArea3 <= '1' when (hcnt >= 320 and hcnt < 480) and (vcnt < 120) else '0';
--activeArea4 <= '1' when (hcnt >= 480 and hcnt < 640) and (vcnt < 120) else '0';

Hsync <= h;
Vsync <= v;

end Behavioral;
