---------------------------------------------------------------
-- This entity prepare the color of a pixel which will be sent
---------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_imagegenerator is
    Port (	Data_in1 : in  STD_LOGIC_VECTOR (15 downto 0);
						active_area1,reset : in  STD_LOGIC;
           RGB_out : out  STD_LOGIC_VECTOR (7 downto 0));
end vga_imagegenerator;

architecture Behavioral of vga_imagegenerator is
begin
-- camera output
-- RRRRRGGGGGGBBBBB - 565
-- xxxxRRRRGGGGBBBB - 444
-- RRRRGGGGBBBBxxxx - 444
--RGB_out <= Data_in1(15 downto 13) & Data_in1(12 downto 10) & Data_in1(9 downto 8) when active_area1 = '1' else (others => '0');
--RGB_out <= Data_in1(15-2 downto 13-2) & Data_in1(11-2 downto 9-2) & Data_in1(7-2 downto 6-2) when active_area1 = '1' else (others => '0');
process (reset,DATA_in1, active_area1) is
begin
if (reset = '1') then
RGB_out <= (others => '0');
else
if (active_area1 = '1') then
RGB_out <= Data_in1(15 downto 13) & Data_in1(11 downto 9) & Data_in1(7 downto 6);
else
RGB_out <= (others => '0');
end if;
end if;
end process;
--RGB_out <= Data_in1(15 downto 13) & Data_in1(11 downto 9) & Data_in1(7 downto 6);
end Behavioral;

