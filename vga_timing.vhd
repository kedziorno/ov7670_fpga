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

signal ph,pv : std_logic;

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
		if (hcnt >= (HD+HFP) and hcnt <= (HD+HFP+HSP)) then 
			h <= '0';
		else
			h <= '1';
		end if;
	end if;
end process hsync_gen;

vsync_gen : process(clk_vga) begin
	if rising_edge(clk_vga) then
		if (vcnt >= (VD+VFP) and vcnt <= (VD+VFP+VSP)) then
			v <= '0';
		else
			v <= '1';
		end if;
	end if;
end process vsync_gen;

p1 : process (clk_vga) is
type states is (idle,p0a,p0b);
variable state : states := idle;
constant C1 : integer := 120-VFP-VBP; --(VD-VFP-VSP-VBP)/4;
constant C2 : integer := 480; --VD;
begin
if (rising_edge(clk_vga)) then
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

p0 : process (clk_vga) is
type states is (idle,idle1a,p0a,p0b,p0c,p0d,p0e);
variable state : states := idle;
variable count1 : integer range 0 to 1023 := 0;
variable counter2 : integer range 0 to HBP-1 := 0;
begin
if (rising_edge(clk_vga)) then
	ph <= h;
		case (state) is
			when idle =>
				if (v120 = '1') then
					if (ph = '0' and h = '1') then
						state := idle1a;
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
			when idle1a =>
				if (counter2 = HBP-1) then
					state := p0a;
					counter2 := 0;
				else
					state := idle1a;
					counter2 := counter2 + 1;
				end if;
			when p0a =>
				if (v120 = '1') then
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
				end if;
			when p0b =>
				if (v120 = '1') then
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
				end if;
			when p0c =>
				if (v120 = '1') then
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
				end if;
			when p0d =>
				if (v120 = '1') then
					if (count1 = 160-1) then
						count1 := 0;
						state := p0e;
--						state := idle;
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
					if (count1 = HFP-1) then
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
				end if;
		end case;
	end if;
end process p0;

--aaproc : process(clk_vga) is
--begin
--if (rising_edge(clk_vga)) then
--if ((hcnt >= 0 and hcnt < 160) and (vcnt < 120)) then
--activeArea1 <= '1';
--activeArea2 <= '0';
--activeArea3 <= '0';
--activeArea4 <= '0';
--end if;
--if ((hcnt >= 160 and hcnt < 320) and (vcnt < 120)) then
--activeArea2 <= '1';
--activeArea1 <= '0';
--activeArea3 <= '0';
--activeArea4 <= '0';
--end if;
--if ((hcnt >= 320 and hcnt < 480) and (vcnt < 120)) then
--activeArea3 <= '1';
--activeArea1 <= '0';
--activeArea2 <= '0';
--activeArea4 <= '0';
--end if;
--if ((hcnt >= 480 and hcnt < 640) and (vcnt < 120)) then
--activeArea4 <= '1';
--activeArea1 <= '0';
--activeArea2 <= '0';
--activeArea3 <= '0';
--end if;
--end if;
--end process;

--activeArea1 <= '1' when (hcnt >= 0 and hcnt < 160) and (vcnt >= 0 and vcnt < 120) else '0';
--activeArea2 <= '1' when (hcnt >= 160 and hcnt < 320) and (vcnt >= 0 and vcnt < 120) else '0';
--activeArea3 <= '1' when (hcnt >= 320 and hcnt < 480) and (vcnt >= 0 and vcnt < 120) else '0';
--activeArea4 <= '1' when (hcnt >= 480 and hcnt < 640) and (vcnt >= 0 and vcnt < 120) else '0';

Hsync <= h;
Vsync <= v;

end Behavioral;
