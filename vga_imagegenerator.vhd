---------------------------------------------------------------
-- This entity prepare the color of a pixel which will be sent
---------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_imagegenerator is
    Port (	reset : in std_logic; clk : in std_logic; Data_in1 : in  STD_LOGIC_VECTOR (2 downto 0);
						Data_in2 : in  STD_LOGIC_VECTOR (2 downto 0);
						Data_in3 : in  STD_LOGIC_VECTOR (2 downto 0);
						Data_in4 : in  STD_LOGIC_VECTOR (2 downto 0);
						active_area1 : in  STD_LOGIC;
						active_area2 : in  STD_LOGIC;
						active_area3 : in  STD_LOGIC;
						active_area4 : in  STD_LOGIC;
           RGB_out : out  STD_LOGIC_VECTOR (7 downto 0));
end vga_imagegenerator;

architecture Behavioral of vga_imagegenerator is
signal d1,d2,d3,d4,d5,o : std_logic_vector(7 downto 0);
signal c : std_logic_vector(3 downto 0);
begin
	-- Red : 11 downto 8
	-- Green : 7 downto 4
	-- Blue : 3 downto 0
	-- Nexys2 D/A converter supports 3 bits red, 3 bits green, and 2 bits blue. 
--	RGB_out <= Data_in(11 downto 9) & Data_in(7 downto 5) & Data_in(3 downto 2) when active_area = '1' else (others=>'0');
--	RGB_out <= Data_in2(2)&"00" & Data_in2(1)&"00" & Data_in2(0)&"0"
--	when (active_area1 = '0' and active_area2 = '1' and active_area3 = '0' and active_area4 = '0')
--	else (others=>'0');

--p0 : process (clk) is
--begin
--	if (rising_edge(clk)) then
--		if (active_area1 = '1' and active_area2 = '0' and active_area3 = '0' and active_area4 = '0') then
--			o <= Data_in1(2)&"01" & Data_in1(1)&"01" & Data_in1(0)&"1";
--		end if;
--		if (active_area1 = '0' and active_area2 = '1' and active_area3 = '0' and active_area4 = '0') then
--			o <= Data_in2(2)&"01" & Data_in2(1)&"01" & Data_in2(0)&"1";
--		end if;
--		if (active_area1 = '0' and active_area2 = '0' and active_area3 = '1' and active_area4 = '0') then
--			o <= Data_in3(2)&"01" & Data_in3(1)&"01" & Data_in3(0)&"1";
--		end if;
--		if (active_area1 = '0' and active_area2 = '0' and active_area3 = '0' and active_area4 = '1') then
--			o <= Data_in4(2)&"01" & Data_in4(1)&"01" & Data_in4(0)&"1";
--		end if;
--		if (active_area1 = '0' and active_area2 = '0' and active_area3 = '0' and active_area4 = '0') then
--			o <= "00000000";
--		end if;
--		RGB_out <= o;
--	end if;
--end process p0;


--p0 : process (clk) is
--begin
--	if (rising_edge(clk)) then
--		c <= active_area1 & active_area2 & active_area3 & active_area4;
--
--	end if;
--end process p0;

--p0 : process (active_area1,active_area2,active_area3,active_area4,Data_in1,Data_in2,Data_in3,Data_in4) is
--begin
--	c <= active_area1 & active_area2 & active_area3 & active_area4;
--	case (c) is
--		when "0001" =>
--			RGB_out <= Data_in1(2)&"01" & Data_in1(1)&"01" & Data_in1(0)&"1";
--		when "0010" =>
--			RGB_out <= Data_in2(2)&"01" & Data_in2(1)&"01" & Data_in2(0)&"1";
--		when "0100" =>
--			RGB_out <= Data_in3(2)&"01" & Data_in3(1)&"01" & Data_in3(0)&"1";
--		when "1000" =>
--			RGB_out <= Data_in4(2)&"01" & Data_in4(1)&"01" & Data_in4(0)&"1";
--		when others =>
--			RGB_out <= "00000000";
--	end case;
--end process p0;

--c <= active_area1 & active_area2 & active_area3 & active_area4;
--
--RGB_out <= o;
--
--d1 <= Data_in1(2)&"01" & Data_in1(1)&"01" & Data_in1(0)&"1" when c = "0001" else (others => '0');
--d2 <= Data_in2(2)&"01" & Data_in2(1)&"01" & Data_in2(0)&"1" when c = "0010" else (others => '0');
--d3 <= Data_in3(2)&"01" & Data_in3(1)&"01" & Data_in3(0)&"1" when c = "0100" else (others => '0');
--d4 <= Data_in4(2)&"01" & Data_in4(1)&"01" & Data_in4(0)&"1" when c = "1000" else (others => '0');
--d5 <= "00000000" when (c = "0000" or c = "1111") else (others => '0');
--
----o <=
----d1 when (active_area1 = '1' and active_area2 = '0' and active_area3 = '0' and active_area4 = '0') else
----d2 when (active_area1 = '0' and active_area2 = '1' and active_area3 = '0' and active_area4 = '0') else
----d3 when (active_area1 = '0' and active_area2 = '0' and active_area3 = '1' and active_area4 = '0') else
----d4 when (active_area1 = '0' and active_area2 = '0' and active_area3 = '0' and active_area4 = '1');
--
--with c select o <=
--d1 when "0001",
--d2 when "0010",
--d3 when "0100",
--d4 when "1000",
--d5 when others;
--

--p0 : process (clk,reset) is
--begin
--if (reset = '1') then
--c <= (others => '0');
--elsif (rising_edge(clk)) then
--c <= active_area1 & active_area2 & active_area3 & active_area4;
--case (c) is
--when "0001" =>
--RGB_out <= Data_in1(2)&"01" & Data_in1(1)&"01" & Data_in1(0)&"1";
--when "0010" =>
--RGB_out <= Data_in2(2)&"01" & Data_in2(1)&"01" & Data_in2(0)&"1";
--when "0100" =>
--RGB_out <= Data_in3(2)&"01" & Data_in3(1)&"01" & Data_in3(0)&"1";
--when "1000" =>
--RGB_out <= Data_in4(2)&"01" & Data_in4(1)&"01" & Data_in4(0)&"1";
--when others =>
--RGB_out <= "00000000";
--end case;
--end if;
--end process p0;

process (clk,reset) is
begin
if (reset = '1') then
c <= (others => '0');
elsif (rising_edge(clk)) then
c <= active_area1 & active_area2 & active_area3 & active_area4;
d1 <= Data_in1(2)&"00" & Data_in1(1)&"00" & Data_in1(0)&"0";
d2 <= Data_in2(2)&"00" & Data_in2(1)&"00" & Data_in2(0)&"0";
d3 <= Data_in3(2)&"00" & Data_in3(1)&"00" & Data_in3(0)&"0";
d4 <= Data_in4(2)&"00" & Data_in4(1)&"00" & Data_in4(0)&"0";

case (c) is
	when "0001" =>
		RGB_out <= d1;
	when "0010" =>
		RGB_out <= d2;
	when "0100" =>
		RGB_out <= d3;
	when "1000" =>
		RGB_out <= d4;
	when others =>
		RGB_out <= "00000000";
end case;
end if;
end process;

end Behavioral;

