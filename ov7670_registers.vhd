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
constant NC : integer := 65;
signal cmd_reg : STD_LOGIC_VECTOR (15 downto 0);
signal sequence : INTEGER range 0 to NC-1 := 0;

type cmd_rom is array (0 to NC-1) of STD_LOGIC_VECTOR (15 downto 0);
constant commandrom : cmd_rom :=(
 	0  => x"1280",
 	1  => x"fffe",
 
 	2  => x"1280",
 	3  => x"fffe",
 
	4  => x"12"&"00000100", -- COM7 for rgb
	--4  => x"12"&"00000010", -- pattern
	5  => x"11"&"00000000",
 	6  => x"0c00",
 	7  => x"3e"&"00000000", -- COM14 PCLK div
	8  => x"70"&"00111010", -- XSC 3a
	9  => x"71"&"00110101", -- YSC 35
	--8  => x"70"&"10000000", -- pattern
	--9  => x"71"&"00000000", -- pattern
	10  => x"7211",
	11  => x"73f0",
	12  => x"a202",

	13  => x"8c"&"00000010", -- rgb444 enable
	14  => x"0800",
	15  => x"40"&"11010000", -- COM15 for rgb444
	16  => x"3a"&"00000001", -- TSLB auto window, 00 have pattern
	17  => x"1438",
	18  => x"4f40",
	19  => x"5034",
	20  => x"510c",
	21  => x"5217",
	22  => x"5329",
	23  => x"5440",
	24  => x"581e",
	25  => x"3dc0",

	26  => x"1711", -- HSTART, HSTOP
	27  => x"1870",
	28  => x"32"&"10000000",

	29  => x"1903", -- VSTART, VSTOP
	30  => x"1a7b",
	31  => x"030a",

	32  => x"0761",
	33  => x"0f4b",
	34  => x"1602",
	35  => x"1e05",
	36  => x"2102",
	37  => x"2291",
	38  => x"2907",
	39  => x"330b",
	40  => x"350b",
	41  => x"371d",
	42  => x"3871",
	43  => x"392a",
	44  => x"3c68",
	45  => x"4d40",
	46  => x"4e20",
	47  => x"6900",
	48  => x"6b"&"01000000",
	49  => x"7410",
	50  => x"8d4f",
	51  => x"8e00",
	52  => x"8f00",
	53  => x"9000",
	54  => x"9100",
	55  => x"9600",
	56  => x"9a00",
	57  => x"b10c",
	58  => x"b20e",
	59  => x"b382",
	60  => x"b80a",
	61  => x"b084",
	62  => x"42"&"00000000", -- dsp colorbar enable for testing configuration
	--62  => x"42"&"00001000", -- dsp colorbar enable for testing configuration
  63  => x"1500", -- vsync polarity

	64  => x"ffff");
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
		if sequence > NC then
			cmd_reg <= x"FFFF";
		end if;
	end if;
end process sequence_proc;
end Behavioral;

