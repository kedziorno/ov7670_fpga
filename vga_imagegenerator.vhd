---------------------------------------------------------------
-- This entity prepare the color of a pixel which will be sent
---------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vga_imagegenerator is
    Port (	Data_in1 : in  STD_LOGIC_VECTOR (0 downto 0);
						active_area1 : in  STD_LOGIC;
           RGB_out : out  STD_LOGIC_VECTOR (7 downto 0));
end vga_imagegenerator;

architecture Behavioral of vga_imagegenerator is
begin
RGB_out <= Data_in1(0)&"01" & Data_in1(0)&"01" & Data_in1(0)&"1" when active_area1 = '1' else (others => '0');
end Behavioral;

