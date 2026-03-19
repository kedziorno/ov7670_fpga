-------------------------------------------------------------------------------
-- Company:         HomeDL
-- Engineer:        ko
--
-- Create Date:     14:56:40 07/10/2022
-- Design Name:     Camera Emulator
-- Module Name:     camera - Behavioral (original)
-- Project Name:    camera_emulator
-- Target Devices:  Not-Synthesizable
-- Tool versions:   Xilinx ISE 14.7
-- Description:     This is probably first version of camera emulator. Probe to
--                  make colorbar pattern for custom resolutions variants.
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - 07/23/2022 - Add ROM memory with one frame to test output
-- Revision 0.03 - 03/19/2026 - Colorbar pattern test (shift-register)
-- Additional Comments: -
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use work.p_camera_colorbar.all;
use work.p_constants.all;

entity camera_colorbar is
port (
camera_io_scl : inout std_logic;
camera_io_sda : inout std_logic;
camera_o_vs : out std_logic;
camera_o_hs : out std_logic;
camera_o_pclk : out std_logic := '0';
camera_i_xclk : in std_logic;
camera_o_d : out std_logic_vector(7 downto 0);
camera_i_rst : in std_logic;
camera_i_pwdn : in std_logic
);
end camera_colorbar;

architecture behavioral of camera_colorbar is

  type t_vs_states is (svs1, svs2, svs3, svs4);
  type t_hs_states is (swait4vsync, shref1, shref0);
  type t_pt_states is (s1, s2, s3);
  signal vs_state : t_vs_states;
  signal hs_state : t_hs_states;
  signal pt_state : t_pt_states;
  signal colorbar : t_colorbar_data := c_colorbar;
  signal href_time : std_logic;
  signal pixel_time : std_logic;
  signal pixel_time_data : std_logic_vector (7 downto 0);
  signal vhref : std_logic;

begin

  g_assert1 : if (c_asserts = true) generate
    p0_assert_1 : process (camera_i_rst) is
    begin
      if (camera_i_rst = '0') then
        assert (
          c_clock_period = c_clock_period_min * 1 ns or
          c_clock_period = c_clock_period_typ * 1 ns or
          c_clock_period = c_clock_period_max * 1 ns
        ) report "-- Check Clock period, " & time'image (c_clock_period)
          severity failure;
      end if;
    end process p0_assert_1;
  end generate g_assert1;

  -- generate sync pulse on falling edge pclk
  p1_vsync : process (camera_i_xclk, camera_i_rst) is
    variable count : integer range 0 to c_vsync_all * a_tline - 1;
    variable vvsync : std_logic;
  begin
    if (camera_i_rst = '0') then
      count := 0;
      vvsync := '1';
      vs_state <= svs1;
      href_time <= '0';
    elsif (falling_edge (camera_i_xclk)) then
      case (vs_state) is
        when svs1 =>
          vvsync := '0';
          href_time <= '0';
          if (count = c_vsync1 - 1) then
            vs_state <= svs2;
            count := 0;
          else
            count := count + 1;
          end if;
        when svs2 =>
          vvsync := '1';
          href_time <= '0';
          if (count = c_vsync2 - 1) then
            vs_state <= svs3;
            count := 0;
          else
            count := count + 1;
          end if;
        when svs3 =>
          vvsync := '1';
          href_time <= '1';
          if (count = c_vsync3 - 1) then
            vs_state <= svs4;
            count := 0;
          else
            count := count + 1;
          end if;
        when svs4 =>
          vvsync := '1';
          href_time <= '0';
          if (count = c_vsync4 - 1) then
            if (c_slide_colorbar_pattern = true) then
              colorbar(4) <= colorbar(4)(0) & colorbar(4)(7 downto 1);
              colorbar(3) <= colorbar(3)(0) & colorbar(3)(7 downto 1);
              colorbar(2) <= colorbar(2)(0) & colorbar(2)(7 downto 1);
              colorbar(1) <= colorbar(1)(0) & colorbar(1)(7 downto 1);
              colorbar(0) <= colorbar(0)(0) & colorbar(0)(7 downto 1);
            end if;
            vs_state <= svs1;
            count := 0;
          else
            count := count + 1;
          end if;
      end case;
      camera_o_vs <= vvsync;
    end if;
  end process p1_vsync;

  -- generate href pulse on falling edge pclk
  camera_o_hs <= vhref;
  pixel_time <= '1' when hs_state = shref1 else '0';
  p2_href : process (camera_i_xclk, camera_i_rst) is
    variable count : integer range 0 to c_vsync3 - 1;
    variable counth1 : integer range 0 to c_href1 - 1;
    variable counth0 : integer range 0 to c_href0 - 1;
  begin
    if (camera_i_rst = '0') then
      count := 0;
      counth1 := 0;
      counth0 := 0;
      hs_state <= swait4vsync;
      vhref <= '0';
    elsif (falling_edge (camera_i_xclk)) then
      case (hs_state) is
        when swait4vsync =>
          if (href_time = '1') then
            hs_state <= shref1;
          end if;
        when shref1 =>
          vhref <= '1';
          if (counth1 = c_href1 - 1) then
            hs_state <= shref0;
            counth1 := 0;
          else
            counth1 := counth1 + 1;
          end if;
        when shref0 =>
          vhref <= '0';
          if (counth0 = c_href0 - 1) then
            hs_state <= swait4vsync;
            counth0 := 0;
          else
            counth0 := counth0 + 1;
          end if;
      end case;
    end if;
  end process p2_href;

  -- Show pattern from virtual camera on VGA display on falling edge pclk
  camera_o_d <= pixel_time_data when vhref = '1' else (others => '0');
  p3_pixeltime : process (camera_i_xclk, camera_i_rst) is
    constant c_num_pixels : integer := c_href1 / c_colorbar_length;
    variable count1 : integer range 0 to c_num_pixels - 1;
    variable count : integer range 0 to c_colorbar_length - 1;
  begin
    if (camera_i_rst = '0') then
      pixel_time_data <= (others => '0');
      pt_state <= s1;
      count := 0;
      count1 := 0;
    elsif (falling_edge (camera_i_xclk)) then
      case (pt_state) is
        when s1 =>
          if (pixel_time = '1') then
            pt_state <= s2;
          else
            pixel_time_data <= (others => '0');
          end if;
        when s2 =>
          pixel_time_data <= colorbar (count);
          if (count1 = c_num_pixels - 1-1) then
            pt_state <= s3;
            count1 := 0;
          else
            count1 := count1 + 1;
          end if;
        when s3 =>
          if (count = c_colorbar_length - 1) then
            pt_state <= s1;
            count := 0;
          else
            pt_state <= s2; -- next color
            count := count + 1;
          end if;
        end case;
    end if;
  end process p3_pixeltime;

  -- only flip source clock
  camera_o_pclk <= camera_i_xclk;

end architecture behavioral;

  -- emulate qqvga
--  pa1 : process(camera_i_rst,camera_i_xclk) is
--    constant C_MAX1 : integer := 1*tline;
--    constant C_MAX2 : integer := 3*tline;
--    variable counter1 : integer range 0 to C_MAX1 - 1;
--    variable counter2 : integer range 0 to C_MAX2 - 1;
--    type states is (sa,sb,sc);
--    variable state : states;
--  begin
--    if (camera_i_rst = '0') then
--      a <= '0';
--      counter1 := 0;
--      counter2 := 0;
--      state := sa;
--    elsif (falling_edge(camera_i_xclk)) then
--      case (state) is
--        when sa =>
--          if (pixel_time = '1') then
--            state := sb;
--          else
--            state := sa;
--          end if;
--        when sb =>
--          if (counter1 = C_MAX1 - 1) then
--            counter1 := 0;
--            state := sc;
--            a <= '0';
--          else
--            counter1 := counter1 + 1;
--            state := sb;
--            a <= '1';
--          end if;
--        when sc =>
--          a <= '0';
--          if (counter2 = C_MAX2 - 1) then
--            counter2 := 0;
--            state := sa;
--          else
--            counter2 := counter2 + 1;
--            state := sc;
--          end if;
--      end case;
--    end if;
--  end process pa1;

