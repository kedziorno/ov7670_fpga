---------------------------------------------------------------
-- This entity prepare the color of a pixel which will be sent
---------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_imagegenerator is
    Port (	Data_in1 : in  STD_LOGIC_VECTOR (15 downto 0);
						active_area1 : in  STD_LOGIC;
           RGB_out : out  STD_LOGIC_VECTOR (7 downto 0));
end vga_imagegenerator;

architecture Behavioral of vga_imagegenerator is
begin
-- camera output
-- RRRRRGGGGGGBBBBB - 565
-- xxxxRRRRGGGGBBBB - 444
RGB_out <= Data_in1(15 downto 13) & Data_in1(11 downto 9) & Data_in1(7 downto 6) when active_area1 = '1' else (others => '0');
--RGB_out <= Data_in1(15-4 downto 13-4) & Data_in1(11-4 downto 9-4) & Data_in1(7-4 downto 6-4) when active_area1 = '1' else (others => '0');
end Behavioral;

