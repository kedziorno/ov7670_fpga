---------------------------------------------------------
-- This entity synchronize hsync and vsync to vga
-- Thanks to Pong P. Chu for creating basic things.
--------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;

entity VGA_timing_synch is
    Port ( reset : in std_logic; clk25 : in  STD_LOGIC;
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
signal ph,pv : std_logic;

signal v120 : std_logic;

begin
clk_vga <= clk25;
count_proc : process(clk_vga,vcnt,hcnt,reset) begin
if (reset = '1') then
hcnt <= 0;
vcnt <= 0;
		elsif rising_edge(clk_vga) then
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

hsync_gen : process(clk_vga,reset) begin
	if (reset = '1') then
		h <= '0';
	elsif rising_edge(clk_vga) then
		if (hcnt <= (HD+HFP) or hcnt >= (HD+HFP+HSP)) then 
			h <= '1';
		else
			h <= '0';
		end if;
	end if;
end process hsync_gen;

vsync_gen : process(clk_vga,reset) begin
if (reset = '1') then
v <= '0';
	elsif rising_edge(clk_vga) then
		if (vcnt <= (VD+VFP) or vcnt >= (VD+VFP+VSP)) then
			v <= '1';
		else
			v <= '0';
		end if;
	end if;
end process vsync_gen;

p1 : process (clk_vga,reset) is
type states is (idle,p0a,p0b);
variable state : states := idle;
constant C1 : integer := 120;
constant C2 : integer := 360;
begin
if (reset = '1') then
state := idle;
v120 <= '0';
	elsif (rising_edge(clk_vga)) then
		pv <= v;
		case (state) is
			when idle =>
				v120 <= '0';
				if (pv = '0' and v = '1') then
					state := p0a;
				else
					state := idle;
				end if;
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
					state := idle;
				else
					state := p0b;
				end if;
		end case;
	end if;
end process p1;

p0 : process (clk_vga,reset) is
type states is (idle,p0a,p0b,p0c,p0d,p0e);
variable state : states := idle;
variable count1 : integer range 0 to 1023 := 0;
begin
if (reset = '1') then
		count1 := 0;
		state := idle;
		activeArea1 <= '0';
		activeArea2 <= '0';
		activeArea3 <= '0';
		activeArea4 <= '0';
	elsif (rising_edge(clk_vga)) then
		activeArea1 <= '0';
		activeArea2 <= '0';
		activeArea3 <= '0';
		activeArea4 <= '0';
		case (state) is
			when idle =>
				if (v120 = '1') then
					if (hcnt = 0) then
						state := p0a;
					else
						state := idle;
					end if;
				else
					state := idle;
				end if;
				activeArea1 <= '0';
				activeArea2 <= '0';
				activeArea3 <= '0';
				activeArea4 <= '0';
				count1 := 0;
			when p0a =>
--				if (v120 = '1') then
					if (count1 = 160-1) then
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
--				end if;
			when p0b =>
--				if (v120 = '1') then
					if (count1 = 160-1) then
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
--				end if;
			when p0c =>
--				if (v120 = '1') then
					if (count1 = 160-1) then
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
--				end if;
			when p0d =>
--				if (v120 = '1') then
					if (count1 = 160-1) then
						count1 := 0;
--						state := p0e;
						state := idle;
					else
						count1 := count1 + 1;
						state := p0d;
					end if;
					activeArea1 <= '0';
					activeArea2 <= '0';
					activeArea3 <= '0';
					activeArea4 <= '1';
--				end if;
			when p0e =>
--				if (v120 = '1') then
					if (count1 = 160-1) then
						count1 := 0;
						state := idle;
					else
						count1 := count1 + 1;
						state := p0e;
					end if;
					activeArea1 <= '0';
					activeArea2 <= '0';
					activeArea3 <= '0';
					activeArea4 <= '0';
--				end if;
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
