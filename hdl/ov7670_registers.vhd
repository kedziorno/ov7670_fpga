----------------------------------------------------------------------------------
-- 'Command' contains the registers address (8 bit) and
-- the value assigned to those registers (8 bit). Both of them is concantenated.
-- View datasheet page 10 - 19.
----------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.p_constants.all;
use work.p_ov7670_rom.all;

entity ov7670_registers is
generic (
  c_module_mode : module_mode_st := c_module_mode_syn;
  c_mode        : integer        := 0
);
port (
  i_clock : in  std_logic;
  i_reset : in  std_logic;
  resend  : in  std_logic;
  advance : in  std_logic;
  command : out std_logic_vector (15 downto 0);
  done    : out std_logic
);
end entity ov7670_registers;

architecture raw_signal of ov7670_registers is

  constant c_nc         : integer := 24 + 1;
  constant c_wait_reset : integer := 8193 * 100; -- to next busy_sr(31), wait ~16.5ms for reset
  signal sequence       : integer range 0 to c_nc - 1;
  signal wait_reset     : integer range 0 to c_wait_reset - 1;
  signal cmd_reg        : std_logic_vector (15 downto 0);

begin

  command <= cmd_reg;
  with cmd_reg select done <= '1' when x"ffff", '0' when others;

  p_rom_case : process (sequence) is
  begin
    case (sequence) is
      -- reset, not ideal but works
      when 00 => cmd_reg <= x"1280";
      when 01 => cmd_reg <= x"fffe";
      when 02 => cmd_reg <= x"1280";
      when 03 => cmd_reg <= x"fffe";
      -- configuration registers
      when 04 => cmd_reg <= x"12"&"00000100"; -- clkrc - internal p-s
      when 05 => cmd_reg <= x"6b"&"11000000"; -- dblv - ic x8
      when 06 => cmd_reg <= x"11"&"00000001"; -- com14, 4,2:0 hsync period
      when 07 => cmd_reg <= x"3e"&"00000000"; -- com7 - rgb selection
      when 08 => cmd_reg <= x"3b"&"00000000"; -- com11 - divide vsync
      when 09 => cmd_reg <= x"40"&"11010000"; -- com15 - out ran 255, rgb565
      when 10 => cmd_reg <= x"8c"&"00000010"; -- rgb444 - enable, xrgb
      when 11 => cmd_reg <= x"0c"&"00000100";
      when 12 => cmd_reg <= x"17"&x"14"; -- hstart
      when 13 => cmd_reg <= x"18"&x"02"; -- hstop
      when 14 => cmd_reg <= x"32"&x"80"; -- href
      when 15 => cmd_reg <= x"19"&x"03"; -- vstart
      when 16 => cmd_reg <= x"1a"&x"7b"; -- vstop
      when 17 => cmd_reg <= x"03"&x"3a"; -- vref
      when 18 => cmd_reg <= x"70"&x"3a";
      when 19 => cmd_reg <= x"71"&x"35";
      when 20 => cmd_reg <= x"72"&x"01";
      when 21 => cmd_reg <= x"73"&x"01"; -- scaling_pclk_div
      when 22 => cmd_reg <= x"3a"&"00000001"; -- tslb auto window, 00 have pattern
      when 23 => cmd_reg <= x"15"&"00000010"; -- com10 - negate vsync
      when 24 => cmd_reg <= x"b0"&"10001000";
      when others => cmd_reg <= x"ffff";
    end case;
  end process p_rom_case;

  p_sequence_proc : process (i_clock) begin
    if (rising_edge (i_clock)) then
      if (i_reset = '1') then
        sequence   <= 0;
        wait_reset <= 0;
      else
        if (c_module_mode = c_module_mode_syn) then
          if (cmd_reg = x"fffe") then
            if (wait_reset = c_wait_reset - 1) then
              wait_reset <= 0;
              sequence   <= sequence + 1;
            else
              wait_reset <= wait_reset + 1;
            end if;
          elsif (resend = '1') then
            sequence <= 0;
          elsif (advance = '1') then
            sequence <= sequence + 1;
          end if;
        end if;
      end if;
    end if;
  end process p_sequence_proc;

end architecture raw_signal;

--

architecture behavioral of ov7670_registers is

  constant c_wait_reset : integer := 8193 * 100; -- to next busy_sr(31), wait ~16.5ms for reset
  signal sequence       : integer range 0 to c_nc - 1;
  signal wait_reset     : integer range 0 to c_wait_reset - 1;
  signal cmd_reg        : std_logic_vector (15 downto 0);

begin

  command <= cmd_reg;
  with cmd_reg select done <= '1' when x"ffff", '0' when others;
  cmd_reg <= ov7670_rom (sequence); -- from package p_ov7670_rom

  p_sequence_proc : process (i_clock) begin
    if (rising_edge (i_clock)) then
      if (i_reset = '1') then
        sequence   <= 0;
        wait_reset <= 0;
      else
        if (c_module_mode = c_module_mode_syn) then
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
      end if;
    end if;
  end process p_sequence_proc;

end architecture behavioral;

