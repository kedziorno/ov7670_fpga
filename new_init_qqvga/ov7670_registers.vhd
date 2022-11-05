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

--constant MAX : integer := 63;
constant MAX : integer := 73;
signal cmd_reg : STD_LOGIC_VECTOR (15 downto 0);
signal sequence : INTEGER range 0 to MAX-1 := 0;

-- XXX https://github.com/westonb/OV7670-Verilog/blob/master/src/OV7670_config_rom.v
type cmd_rom is array (0 to MAX-1) of STD_LOGIC_VECTOR (15 downto 0);
constant commandrom : cmd_rom :=(
	0  => x"1280",
	1  => x"1280",
	2  => x"1280",
	3  => x"1280",
	4  => x"1280",
	5  => x"1280",
	6  => x"fffe",

	7   => x"1204",
	8   => x"8c00",
	9   => x"1101",
	10  => x"6b01",
	11  => x"0c04",
	12  => x"3e1a",
	13  => x"0400",
	14  => x"40d0",--rgb565
	15  => x"3a04",
	16  => x"1418",
	17  => x"4fb3",
	18  => x"50b3",
	19  => x"5100",
	20  => x"523d",
	21  => x"53a7",
	22  => x"54e4",
	23  => x"589e",
	24  => x"3dc0",
	25  => x"1714",
	26  => x"1802",
	27  => x"3280",
	28  => x"1903",
	29  => x"1a7b",
	30  => x"030a",
	31  => x"0f41",
	32  => x"1e00",
	33  => x"330b",
	34  => x"3c78",
	35  => x"6900",
	36  => x"7400",
	37  => x"b084",
	38  => x"b10c",
	39  => x"b20e",
	40  => x"b380",
	41  => x"703a",
	42  => x"7135",
	43  => x"7222",
	44  => x"73f2",
	45  => x"a202",
	46  => x"ffff");

--	13  => x"8c00",
--	14  => x"0800",
--	15  => x"40f0",
--	16  => x"3a00",
--	17  => x"1438",
--	18  => x"4f40",
--	19  => x"5034",
--	20  => x"510c",
--	21  => x"5217",
--	22  => x"5329",
--	23  => x"5440",
--	24  => x"581e",
--	25  => x"3dc0",
--	26  => x"1711",
--	27  => x"1861",
--	28  => x"32a4",
--	29  => x"1903",
--	30  => x"1a7b",
--	31  => x"030a",
--	32  => x"0761",
--	33  => x"0f4b",
--	34  => x"1602",
--	35  => x"1e05",
--	36  => x"2102",
--	37  => x"2291",
--	38  => x"2907",
--	39  => x"330b",
--	40  => x"350b",
--	41  => x"371d",
--	42  => x"3871",
--	43  => x"392a",
--	44  => x"3c68",
--	45  => x"4d40",
--	46  => x"4e20",
--	47  => x"6900",
--	48  => x"6b00",
--	49  => x"7410",
--	50  => x"8d4f",
--	51  => x"8e00",
--	52  => x"8f00",
--	53  => x"9000",
--	54  => x"9100",
--	55  => x"9600",
--	56  => x"9a00",
--	57  => x"b084",
--	58  => x"b10c",
--	59  => x"b20e",
--	60  => x"b382",
--	61  => x"b80a",

--	62  => x"ffff");

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

		if sequence = C_CMD-1 then
--			cmd_reg <= x"FFFF";
sequence <= 0;
		end if;

		cmd_reg <= commandrom(sequence);
		if sequence > MAX-1 then
			cmd_reg <= x"FFFF";
		end if;
	end if;

end process sequence_proc;
end Behavioral;

