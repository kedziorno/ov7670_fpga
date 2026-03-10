----------------------------------------------------------------------------------
-- 'Command' contains the registers address (8 bit) and 
-- the value assigned to those registers (8 bit). Both of them is concantenated.
-- View datasheet page 10 - 19.  
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ov7670_registers is
    Port ( reset, clk : in  STD_LOGIC;
           resend : in  STD_LOGIC;
           advance : in  STD_LOGIC;
           command : out  STD_LOGIC_VECTOR (15 downto 0);
           done : out  STD_LOGIC);
end ov7670_registers;

architecture Behavioral of ov7670_registers is
constant NC : integer := 57;
signal cmd_reg : STD_LOGIC_VECTOR (15 downto 0);
signal sequence : INTEGER range 0 to NC-1 := 0;

type cmd_rom is array (0 to NC-1) of STD_LOGIC_VECTOR (15 downto 0);
constant commandrom : cmd_rom :=(
0 => x"1280", -- COM7   Reset
1 => x"1280", -- COM7   Reset
2 => x"1202", -- COM7   Size & YUV output
3 => x"1100", -- CLKRC  Prescaler - Fin/(1+1)
4 => x"0C00", -- COM3   Lots of stuff, enable scaling, all others off
5 => x"3E00", -- COM14  PCLK scaling off
6 => x"8C00", -- RGB444 Set RGB format,disabled.
7 => x"0400", -- COM1   no CCIR601
8 => x"4002", -- COM15  Full 0-255 output, YUV
9 => x"3a04", -- TSLB   Set UV ordering,  do not auto-reset window
10 => x"1438", -- COM9  - AGC Celling
11 => x"4f40", --x"4fb3", -- MTX1  - colour conversion matrix
12 => x"5034", --x"50b3", -- MTX2  - colour conversion matrix
13 => x"510C", --x"5100", -- MTX3  - colour conversion matrix
14 => x"5217", --x"523d", -- MTX4  - colour conversion matrix
15 => x"5329", --x"53a7", -- MTX5  - colour conversion matrix
16 => x"5440", --x"54e4", -- MTX6  - colour conversion matrix
17 => x"581e", --x"589e", -- MTXS  - Matrix sign and auto contrast
18 => x"3dc0", -- COM13 - Turn on GAMMA and UV Auto adjust
19 => x"1103", -- CLKRC  Prescaler - Fin/(0+1) no scale
20 => x"1711", -- HSTART HREF start (high 8 bits)
21 => x"1861", -- HSTOP  HREF stop (high 8 bits)
22 => x"32A4", -- HREF   Edge offset and low 3 bits of HSTART and HSTOP
23 => x"1903", -- VSTART VSYNC start (high 8 bits)
24 => x"1A7b", -- VSTOP  VSYNC stop (high 8 bits)
25 => x"030a", -- VREF   VSYNC low two bits
26 => x"0e61", -- COM5(0x0E) 0x61
27 => x"0f4b", -- COM6(0x0F) 0x4B
28 => x"1602", --
29 => x"1e37", -- MVFP (0x1E) 0x07  -- FLIP AND MIRROR IMAGE 0x3x
30 => x"2102",
31 => x"2291",
32 => x"2907",
33 => x"330b",
34 => x"350b",
35 => x"371d",
36 => x"3871",
37 => x"392a",
38 => x"3c78", -- COM12 (0x3C) 0x78
39 => x"4d40",
40 => x"4e20",
41 => x"6900", -- GFIX (0x69) 0x00
42 => x"6b0a",-- 6b4a -> 6b0a bypasss mult
43 => x"7410",
44 => x"8d4f",
45 => x"8e00",
46 => x"8f00",
47 => x"9000",
48 => x"9100",
49 => x"9600",
50 => x"9a00",
51 => x"b084",
52 => x"b10c",
53 => x"b20e",
54 => x"b382",
55 => x"b80a",
56 => x"ffff");
begin
command <= cmd_reg;

with cmd_reg select done <= '1' when x"FFFF", '0' when others;

sequence_proc : process (clk, reset) begin
if (reset = '1') then
  sequence <= 0;
  cmd_reg <= (others => '0');
	elsif rising_edge(clk) then
		if resend = '1' then
			sequence <= 0;
		elsif advance = '1' then
			sequence <= sequence + 1;
		end if;

		cmd_reg <= commandrom(sequence);
--		if sequence > 55 then
		if sequence > NC-1 then
			cmd_reg <= x"FFFF";
		end if;
	end if;
end process sequence_proc;
end Behavioral;

