----------------------------------------------------------------------------------
-- 'Command' contains the registers address (8 bit) and 
-- the value assigned to those registers (8 bit). Both of them is concantenated.
-- View datasheet page 10 - 19.  
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ov7670_registers is
    Port ( reset : in std_logic; clk : in  STD_LOGIC;
           resend : in  STD_LOGIC;
           advance : in  STD_LOGIC;
           command : out  STD_LOGIC_VECTOR (15 downto 0);
           done : out  STD_LOGIC);
end ov7670_registers;

architecture Behavioral of ov7670_registers is

constant MAX : integer := 57;

signal cmd_reg : STD_LOGIC_VECTOR (15 downto 0);
signal sequence : INTEGER range 0 to MAX-1 := 0;

type cmd_rom is array (0 to MAX-1) of STD_LOGIC_VECTOR (15 downto 0);
constant commandrom : cmd_rom :=(
	0  => x"1280", -- COM7 Reset
	1  => x"1280", -- COM7 Reset
	2  => x"11"&"00000001", -- CLKRC Prescaler - F(clkin)/(2), disable double speed pll
	3  => x"12"&"00000000", -- COM7 QIF image with RGB output
	4  => x"0C"&"00000100", -- COM3 enable scaling
	5  => x"3E"&"00011010", -- COM14 PCLK scaling off ,3E19 to div by 2
	6  => x"40"&"10000000", -- COM15 Full 0-255 output, RGB 565
	7  => x"3A"&"00000100", -- TSLB Set UV ordering, do not auto-reset window
	8  => x"8C"&"00000000", -- RGB444 Set RGB format
	9  => x"17"&"00010100", -- HSTART HREF start (high 8 bits)
	10 => x"18"&"00000010", -- HSTOP HREF stop (high 8 bits)
	11 => x"32"&"10100100", -- HREF Edge offset and low 3 bits of HSTART and HSTOP
	12 => x"19"&"00000011", -- VSTART VSYNC start (high 8 bits)
	13 => x"1A"&"01111011", -- VSTOP VSYNC stop (high 8 bits)
	14 => x"03"&"00001010", -- VREF VSYNC low two bits
	15 => x"70"&"00111010", -- SCALING_XSC
	16 => x"71"&"00110101", -- SCALING_YSC
	17 => x"72"&"00100010", -- SCALING_DCWCTR
	18 => x"73"&"11110010", -- SCALING_PCLK_DIV
	19 => x"A2"&"00000010", -- SCALING_PCLK_DELAY PCLK scaling = 4, must match COM14
	20 => x"15"&"00000000", -- COM10 Use HREF not hSYNC
	21 => x"7A"&"00100000", -- SLOP
	22 => x"7B"&"00010000", -- GAM1
	23 => x"7C"&"00011110", -- GAM2
	24 => x"7D"&"00110101", -- GAM3
	25 => x"7E"&"01011010", -- GAM4
	26 => x"7F"&"01101001", -- GAM5
	27 => x"80"&"01110110", -- GAM6
	28 => x"81"&"10000000", -- GAM7
	29 => x"82"&"10001000", -- GAM8
	30 => x"83"&"10001111", -- GAM9
	31 => x"84"&"10010110", -- GAM10
	32 => x"85"&"10100011", -- GAM11
	33 => x"86"&"10101111", -- GAM12
	34 => x"87"&"11000100", -- GAM13
	35 => x"88"&"11010111", -- GAM14
	36 => x"89"&"11101000", -- GAM15
	37 => x"13"&"11100000", -- COM8 - AGC, White balance
	38 => x"00"&"00000000", -- GAIN AGC
	39 => x"10"&"00000000", -- AECH Exposure
	40 => x"0D"&"01000000", -- COMM4 - Window Size
	41 => x"14"&"00011000", -- COMM9 AGC
	42 => x"A5"&"00000101", -- AECGMAX banding filter step
	43 => x"24"&"10010101", -- AEW AGC Stable upper limite
	44 => x"25"&"00110011", -- AEB AGC Stable lower limi
	45 => x"26"&"11100011", -- VPT AGC fast mode limits
	46 => x"9F"&"01111000", -- HRL High reference level
	47 => x"A0"&"01101000", -- LRL low reference level
	48 => x"A1"&"00000011", -- DSPC3 DSP control
	49 => x"A6"&"11011000", -- LPH Lower Prob High
	50 => x"A7"&"11011000", -- UPL Upper Prob Low
	51 => x"A8"&"11110000", -- TPL Total Prob Low
	52 => x"A9"&"10010000", -- TPH Total Prob High
	53 => x"AA"&"10010100", -- NALG AEC Algo select
	54 => x"6b"&"00000001", -- COM8 AGC Settings
	55 => x"13"&"11100101", -- COM8 AGC Settings
	56 => "1111111111111111");-- STOP (using WITH .. SELECT below) 			

begin
command <= cmd_reg;

with cmd_reg select done <= '1' when x"FFFF", '0' when others;

sequence_proc : process (clk,reset) begin
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
		if sequence > MAX-1 then
			cmd_reg <= x"FFFF";
		end if;
	end if;
end process sequence_proc;
end Behavioral;

