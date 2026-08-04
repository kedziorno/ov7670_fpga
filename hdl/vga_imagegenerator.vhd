---------------------------------------------------------------
-- This entity prepare the color of a pixel which will be sent
---------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.numeric_std.all;

library work;
use work.p_constants.all;

entity vga_imagegenerator is
generic (
  c_module_mode : module_mode_st := c_module_mode_syn
);
port (
  reset        : in  std_logic;
  active_area1 : in  std_logic;
  data_in1     : in  std_logic_vector (15 downto 0);
  rgb_out      : out std_logic_vector (7 downto 0)
);
end entity vga_imagegenerator;

architecture behavioral of vga_imagegenerator is
begin

-- camera output
-- RRRRRGGGGGGBBBBB - 565
-- XRRRRRGGGGGBBBBB - 555
-- xxxxRRRRGGGGBBBB - 444 1
-- RRRRGGGGBBBBxxxx - 444 2

--rgb_out <= data_in1(15 downto 13) & data_in1(12 downto 10) & data_in1(9 downto 8) when active_area1 = '1' else (others => '0');
--rgb_out <= data_in1(15-2 downto 13-2) & data_in1(11-2 downto 9-2) & data_in1(7-2 downto 6-2) when active_area1 = '1' else (others => '0');

--process (reset, data_in1, active_area1) is
--begin
--if (reset = '1') then
--rgb_out <= (others => '0');
--else
--if (active_area1 = '1') then
--rgb_out <= data_in1(15 downto 13) & data_in1(11 downto 9) & data_in1(7 downto 6);
--else
--rgb_out <= (others => '0');
--end if;
--end if;
--end process;

--rgb_out <= data_in1(11 downto 9) & data_in1(7 downto 5) & data_in1(2 downto 1) when active_area1 = '1' else (others => '0'); -- rgb444

--rgb_out <= data_in1(10 downto 8) & "000" & "00" when active_area1 = '1' else (others => '0'); -- rgb444
--rgb_out <= "000" & data_in1(6 downto 4) & "00" when active_area1 = '1' else (others => '0'); -- rgb444
--rgb_out <= "000" & "000" & data_in1(1 downto 0) when active_area1 = '1' else (others => '0'); -- rgb444
rgb_out <= data_in1(11 downto 9) & data_in1(7 downto 5) & data_in1(3 downto 2) when active_area1 = '1' else (others => '0'); -- rgb444 - less dark blue
--rgb_out <= data_in1(11 downto 9) & data_in1(7 downto 5) & data_in1(2 downto 1) when active_area1 = '1' else (others => '0'); -- rgb444 - better dark blue but white with yellow

--rgb_out <= data_in1(15 downto 13) & data_in1(11 downto 9) & data_in1(7 downto 6) when active_area1 = '1' else (others => '0'); -- rgb444
--rgb_out <= data_in1(15 downto 13) & data_in1(10 downto 8) & data_in1(4 downto 3) when active_area1 = '1' else (others => '0'); -- rgb565
--rgb_out <= data_in1(14 downto 12) & data_in1(9 downto 7) & data_in1(4 downto 3) when active_area1 = '1' else (others => '0'); -- rgb555

-- GRB 422 15,14,13,12|11,10|9,8
-- GRB 422 7,6,5,4|3,2|1,0
--rgb_out <= '0'&data_in1(11 downto 10) & data_in1(14 downto 12) & data_in1(9 downto 8) when active_area1 = '1' else (others => '0'); -- rgb444
--rgb_out <= data_in1(6 downto 4) & '0'&data_in1(3 downto 2) & data_in1(1 downto 0) when active_area1 = '1' else (others => '0'); -- rgb444

end architecture behavioral;

