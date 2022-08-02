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

constant MAX : integer := 58;

signal cmd_reg : STD_LOGIC_VECTOR (15 downto 0);
signal sequence : INTEGER range 0 to MAX-1 := 0;

type cmd_rom is array (0 to MAX-1) of STD_LOGIC_VECTOR (15 downto 0);
constant commandrom : cmd_rom :=(
	0  => x"1280",
	1  => x"fffe",

	2  => x"1280",
	3  => x"fffe",

	4  => x"1200",
	5  => x"1101",
	6  => x"0c00",
	7  => x"3e00",
	8  => x"8c00",
	9  => x"0800",
	10  => x"40f0",
	11  => x"3a00",
	12  => x"1438",
	13  => x"4f40",
	14  => x"5034",
	15  => x"510c",
	16  => x"5217",
	17  => x"5329",
	18  => x"5440",
	19  => x"581e",
	20  => x"3dc0",
	21  => x"1711",
	22  => x"1861",
	23  => x"32a4",
	24  => x"1903",
	25  => x"1a7b",
	26  => x"030a",
	27  => x"0761",
	28  => x"0f4b",
	29  => x"1602",
	30  => x"1e05",
	31  => x"2102",
	32  => x"2291",
	33  => x"2907",
	34  => x"330b",
	35  => x"350b",
	36  => x"371d",
	37  => x"3871",
	38  => x"392a",
	39  => x"3c68",
	40  => x"4d40",
	41  => x"4e20",
	42  => x"6900",
	43  => x"6b01",
	44  => x"7410",
	45  => x"8d4f",
	46  => x"8e00",
	47  => x"8f00",
	48  => x"9000",
	49  => x"9100",
	50  => x"9600",
	51  => x"9a00",
	52  => x"b084",
	53  => x"b10c",
	54  => x"b20e",
	55  => x"b382",
	56  => x"b80a",
	
	57  => x"ffff");

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

