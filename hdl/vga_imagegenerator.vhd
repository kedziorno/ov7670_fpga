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
-- XRRRRRGGGGGBBBBB - 555
-- xxxxRRRRGGGGBBBB - 444
-- RRRRGGGGBBBBxxxx - 444
--RGB_out <= Data_in1(15 downto 13) & Data_in1(12 downto 10) & Data_in1(9 downto 8) when active_area1 = '1' else (others => '0');
--RGB_out <= Data_in1(15-2 downto 13-2) & Data_in1(11-2 downto 9-2) & Data_in1(7-2 downto 6-2) when active_area1 = '1' else (others => '0');
--process (reset,DATA_in1, active_area1) is
--begin
--if (reset = '1') then
--RGB_out <= (others => '0');
--else
--if (active_area1 = '1') then
--RGB_out <= Data_in1(15 downto 13) & Data_in1(11 downto 9) & Data_in1(7 downto 6);
--else
--RGB_out <= (others => '0');
--end if;
--end if;
--end process;
--RGB_out <= Data_in1(11 downto 9) & Data_in1(7 downto 5) & Data_in1(2 downto 1) when active_area1 = '1' else (others => '0'); -- rgb444

--RGB_out <= Data_in1(10 downto 8) & "000" & "00" when active_area1 = '1' else (others => '0'); -- rgb444
--RGB_out <= "000" & Data_in1(6 downto 4) & "00" when active_area1 = '1' else (others => '0'); -- rgb444
--RGB_out <= "000" & "000" & Data_in1(1 downto 0) when active_area1 = '1' else (others => '0'); -- rgb444
--RGB_out <= Data_in1(11 downto 9) & Data_in1(7 downto 5) & Data_in1(3 downto 2) when active_area1 = '1' else (others => '0'); -- rgb444 - less dark blue
RGB_out <= Data_in1(11 downto 9) & Data_in1(7 downto 5) & Data_in1(2 downto 1) when active_area1 = '1' else (others => '0'); -- rgb444 - better dark blue but white with yellow

--RGB_out <= Data_in1(15 downto 13) & Data_in1(11 downto 9) & Data_in1(7 downto 6) when active_area1 = '1' else (others => '0'); -- rgb444
--RGB_out <= Data_in1(15 downto 13) & Data_in1(10 downto 8) & Data_in1(4 downto 3) when active_area1 = '1' else (others => '0'); -- rgb565
--RGB_out <= Data_in1(14 downto 12) & Data_in1(9 downto 7) & Data_in1(4 downto 3) when active_area1 = '1' else (others => '0'); -- rgb555
--RGB_out <= Data_in1(0)&Data_in1(1)&Data_in1(2)&Data_in1(3)&Data_in1(4)&Data_in1(5)&Data_in1(6)&Data_in1(7) when active_area1 = '1' else (others => '0');
--else (others => '0');
--RGB_out <= Data_in1(7 downto 0) when active_area1 = '1' else (others => '0');
-- GRB 422 15,14,13,12|11,10|9,8
-- GRB 422 7,6,5,4|3,2|1,0
--RGB_out <= '0'&Data_in1(11 downto 10) & Data_in1(14 downto 12) & Data_in1(9 downto 8) when active_area1 = '1' else (others => '0'); -- rgb444
--RGB_out <= Data_in1(6 downto 4) & '0'&Data_in1(3 downto 2) & Data_in1(1 downto 0) when active_area1 = '1' else (others => '0'); -- rgb444
end Behavioral;

