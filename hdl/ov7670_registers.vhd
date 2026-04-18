----------------------------------------------------------------------------------
-- 'Command' contains the registers address (8 bit) and 
-- the value assigned to those registers (8 bit). Both of them is concantenated.
-- View datasheet page 10 - 19.  
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

use work.p_ov7670_rom.all;

entity ov7670_registers is
generic (constant MODE : integer := 0);
    Port ( reset, clk : in  STD_LOGIC;
           resend : in  STD_LOGIC;
           advance : in  STD_LOGIC;
           command : out  STD_LOGIC_VECTOR (15 downto 0);
           done : out  STD_LOGIC);
end ov7670_registers;

architecture raw_signal of ov7670_registers is

  constant NC : integer := 24+1;
  signal sequence : INTEGER range 0 to NC-1 := 0;
  constant c_wait_reset : integer := 8193*100; -- to next busy_sr(31), wait ~16.5ms for reset
  signal wait_reset : integer range 0 to c_wait_reset - 1;
  signal cmd_reg : STD_LOGIC_VECTOR (15 downto 0);

begin

  command <= cmd_reg;
  with cmd_reg select done <= '1' when x"FFFF", '0' when others;

  rom_case : process (sequence) is
  begin
    case (sequence) is
      -- reset, not ideal but works
      when 0 => cmd_reg <= x"1280";
      when 1 => cmd_reg <= x"fffe";
      when 2 => cmd_reg <= x"1280";
      when 3 => cmd_reg <= x"fffe";
      -- configuration registers
      when 4 => cmd_reg <= x"12"&"00000000"; -- CLKRC - internal p-s
      when 5 => cmd_reg <= x"6b"&"11000000"; -- DBLV - ic x8
      when 6 => cmd_reg <= x"11"&"00000001"; -- COM14, 4,2:0 hsync period
      when 7 => cmd_reg <= x"3e"&"00000000"; -- COM7 - RGB selection
      when 8 => cmd_reg <= x"3b"&"00000000"; -- COM11 - divide vsync
      when 9 => cmd_reg <= x"40"&"11010000"; -- COM15 - out ran 255, RGB565
      when 10 => cmd_reg <= x"8c"&"00000010"; -- RGB444 - enable, xRGB
      when 11 => cmd_reg <= x"15"&"00000010"; -- COM10 - negate VSYNC
      when 12 => cmd_reg <= x"17"&"00000000"; -- HSTART
      when 13 => cmd_reg <= x"18"&"00000000"; -- HSTOP
      when 14 => cmd_reg <= x"32"&"00000000"; -- HREF
      when 15 => cmd_reg <= x"19"&"00000000"; -- VSTART
      when 16 => cmd_reg <= x"1a"&"00000000"; -- VSTOP
      when 17 => cmd_reg <= x"03"&"00000000"; -- VREF
      when 18 => cmd_reg <= x"70"&"00000000";
      when 19 => cmd_reg <= x"71"&"00000000";
      when 20 => cmd_reg <= x"72"&"00000000";
      when 21 => cmd_reg <= x"73"&"00000000"; -- SCALING_PCLK_DIV
      when 22 => cmd_reg <= x"3a"&"00000001"; -- TSLB auto window, 00 have pattern
      when 23 => cmd_reg <= x"0c"&"00000100";
      when 24 => cmd_reg <= x"b0"&"10001000";
      when others => cmd_reg <= x"ffff";
    end case;
  end process rom_case;

  sequence_proc : process (clk, reset) begin
    if (reset = '1') then
      sequence <= 0;
      wait_reset <= 0;
    elsif rising_edge(clk) then
      if (cmd_reg = x"fffe") then
        if (wait_reset = c_wait_reset - 1) then
          wait_reset <= 0;
          sequence <= sequence + 1;
        else
          wait_reset <= wait_reset + 1;
        end if;
      elsif resend = '1' then
        sequence <= 0;
      elsif advance = '1' then
        sequence <= sequence + 1;
      else
      end if;
    end if;
  end process sequence_proc;

end architecture raw_signal;

--

architecture Behavioral of ov7670_registers is
  signal cmd_reg : STD_LOGIC_VECTOR (15 downto 0);
  signal sequence : INTEGER range 0 to NC-1 := 0;
  constant c_wait_reset : integer := 8193*100; -- to next busy_sr(31), wait ~16.5ms for reset
  signal wait_reset : integer range 0 to c_wait_reset - 1;
begin
  command <= cmd_reg;
  with cmd_reg select done <= '1' when x"FFFF", '0' when others;
  cmd_reg <= ov7670_rom (sequence);
  sequence_proc : process (clk, reset) begin
    if (reset = '1') then
      sequence <= 0;
      wait_reset <= 0;
    elsif rising_edge(clk) then
      if (cmd_reg = x"fffe") then
        if (wait_reset = c_wait_reset - 1) then
          wait_reset <= 0;
          sequence <= sequence + 1;
        else
          wait_reset <= wait_reset + 1;
        end if;
      elsif resend = '1' then
        sequence <= 0;
      elsif advance = '1' then
        sequence <= sequence + 1;
      end if;
    end if;
  end process sequence_proc;

end Behavioral;

