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
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;
use work.p_camera_colorbar.all;
use work.p_constants.all;

entity camera_colorbar is
port (
camera_io_scl : inout std_logic;
camera_io_sda : inout std_logic;
camera_o_vs : out std_logic;
camera_o_hs : out std_logic;
camera_o_pclk : out std_logic;
camera_i_xclk : in std_logic;
camera_o_d : out std_logic_vector(7 downto 0);
camera_i_rst : in std_logic;
camera_i_pwdn : in std_logic
);
end camera_colorbar;

architecture behavioral of camera_colorbar is

  type t_vs_states is (cold_start, svs1, svs2, svs3, svs4);
  type t_hs_states is (swait4vsync, shref1, shref0);
  type t_pt_states is (s1, s2, s3);
  signal vs_state : t_vs_states;
  signal hs_state : t_hs_states;
  signal pt_state : t_pt_states;
  signal colorbar : t_colorbar_data := c_colorbar;
  signal colorbar_count : integer range 0 to c_colorbar_length;
  signal href_time : std_logic;
  signal pixel_time : std_logic;
  signal pixel_time_data : std_logic_vector (7 downto 0);
  signal href_i : std_logic;
  signal vsync_i : std_logic;

  constant c_frame_bits : integer := 19;
  constant c_all_frame : integer := 388431;
  signal all_frame : integer range 0 to c_all_frame - 1;
  signal addra : integer range 0 to c_all_frame - 1;
  signal douta : std_logic_vector (7 downto 0) := (others => '0');
  signal reset_rom : std_logic;
--  component frame1
--  port (
--    clka : in std_logic;
--    rsta : in std_logic;
--    ena : in std_logic;
--    wea : in std_logic_vector (0 downto 0);
--    addra : in std_logic_vector (c_frame_bits - 1 downto 0);
--    dina : in std_logic_vector (7 downto 0);
--    douta : out std_logic_vector (7 downto 0)
--  );
--  end component frame1;
component ROM_MUX IS
PORT (
  reset   : IN  STD_LOGIC;
  data    : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);
  address : IN  INTEGER RANGE 0 TO 388431 - 1
);
END component ROM_MUX;

signal reset_dcm1, reset_dcm1_n, speed_clock, clock_adjust_frame, clk1, clk1_fb, clk2, clk2_fb, reset_dcm, reset_dcm_n, camera_i_xlkf_ibuf : std_logic;

type states is (wait_pt, wait_00_pt, wait_ff, wait_wl, wait_count640);
signal state : states := wait_pt;
constant c_count640 : integer := 640;
signal count640 : integer range 0 to c_count640 - 1;

begin

  g_source_frames : if (c_source = t_frames) generate
    reset_rom <= '1', '0' after 1111 ns;
--    frame1_i0 : frame1
--    port map (
--      clka => camera_i_xclk,
--      rsta => reset_rom,
--      ena => href_i,
--      wea => "0",
--      addra => addra,
--      dina => (others => '0'),
--      douta => douta
--    );
    frame1_i0 : ROM_MUX -- XXX own frame
    port map (
      reset => reset_rom,
      address => addra,
      data => douta
    );

    camera_o_d <= douta;
    p4_frame_out : process (camera_i_xclk) is
    begin
      if (falling_edge (camera_i_xclk)) then
        case (state) is
          when wait_pt =>
            count640 <= 0;
            if (pixel_time = '1') then
              state <= wait_00_pt;
            end if;
          when wait_00_pt =>
            all_frame <= all_frame + 1;
            if (douta /= x"00" or pixel_time = '1') then
              state <= wait_ff;
            end if;
          when wait_ff =>
            all_frame <= all_frame + 1;
            if (douta = x"ff") then
              state <= wait_wl;
            end if;
          when wait_wl =>
            if (vsync_i = '0') then
              all_frame <= 0;
            end if;
            if ((douta = x"ff" or -- pixels when start hsync
                  douta = x"b8" or
                  douta = x"df" or
                  douta = x"78" or
                  douta = x"ce")
              and pixel_time = '1') then
              all_frame <= all_frame + 1;
              state <= wait_count640;
            end if;
          when wait_count640 =>
            if (count640 = c_count640 - 1 or href_i = '0') then
              state <= wait_00_pt;
              count640 <= 0;
            else
              count640 <= count640 + 1;
            end if;
            if (all_frame = c_all_frame - 1) then
              all_frame <= 0;
            else
              all_frame <= all_frame + 1;
            end if;
        end case;
        addra <= all_frame;
      end if;
    end process p4_frame_out;
  end generate g_source_frames;

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
  camera_o_vs <= not vsync_i when c_com10_02 = true else vsync_i;
  p1_vsync : process (camera_i_xclk, camera_i_rst) is
    variable count : integer range 0 to c_vsync_all * a_tline - 1;
    constant c_wait_start : integer := 1234;
    variable wait_start : integer range 0 to c_wait_start - 1;
  begin
    if (camera_i_rst = '0') then
      count := 0;
      vsync_i <= '1'; -- XXX check when startup
      vs_state <= cold_start;
      href_time <= '0';
      wait_start := 0;
    elsif (falling_edge (camera_i_xclk)) then
      case (vs_state) is
        when cold_start => -- shift first vs
          if (wait_start = c_wait_start - 1) then
            wait_start := 0;
            vs_state <= svs1;
          else
            wait_start := wait_start + 1;
          end if;
        when svs1 =>
          vsync_i <= '0';
          href_time <= '0';
          if (count = c_vsync1 - 1) then
            vs_state <= svs2;
            count := 0;
          else
            count := count + 1;
          end if;
        when svs2 =>
          vsync_i <= '1';
          href_time <= '0';
          if (count = c_vsync2 - 1) then
            vs_state <= svs3;
            count := 0;
          else
            count := count + 1;
          end if;
        when svs3 =>
          vsync_i <= '1';
          href_time <= '1';
          if (count = c_vsync3 - 1) then
            vs_state <= svs4;
            count := 0;
          else
            count := count + 1;
          end if;
        when svs4 =>
          vsync_i <= '1';
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
    end if;
  end process p1_vsync;

  -- VGA mode have 26.666667us/6.0us HS output - then give stable image
  g_source_colorbar_hs : if (c_source = t_colorbar or c_source = t_frames) generate
    -- generate href pulse on falling edge pclk - t_colorbar
    camera_o_hs <= href_i;
    pixel_time <= '1' when hs_state = shref1 else '0';
    p2_href_colorbar : process (camera_i_xclk, camera_i_rst) is
      variable count : integer range 0 to c_vsync3 - 1;
      variable counth1 : integer range 0 to c_href1 - 1;
      variable counth0 : integer range 0 to c_href0 - 1;
    begin
      if (camera_i_rst = '0') then
        count := 0;
        counth1 := 0;
        counth0 := 0;
        hs_state <= swait4vsync;
        href_i <= '0';
      elsif (falling_edge (camera_i_xclk)) then
        case (hs_state) is
          when swait4vsync =>
            if (href_time = '1') then
              hs_state <= shref1;
            end if;
          when shref1 =>
            href_i <= '1';
            if (counth1 = c_href1 - 1) then
              hs_state <= shref0;
              counth1 := 0;
            else
              counth1 := counth1 + 1;
            end if;
          when shref0 =>
            href_i <= '0';
            if (counth0 = c_href0 - 1 - 1) then -- minus one cycle
              hs_state <= swait4vsync;
              counth0 := 0;
            else
              counth0 := counth0 + 1;
            end if;
        end case;
      end if;
    end process p2_href_colorbar;
  end generate g_source_colorbar_hs;

  g_source_lines_hs : if (c_source = t_lines) generate
    -- generate href pulse on falling edge pclk - t_lines
    camera_o_hs <= href_i;
    pixel_time <= '1' when hs_state = shref1 else '0';
    p2_href_lines : process (camera_i_xclk, camera_i_rst) is
      variable count : integer range 0 to c_vsync3 - 1;
      variable counth1 : integer range 0 to c_href1 - 1;
      variable counth0 : integer range 0 to c_href0 - 1;
    begin
      if (camera_i_rst = '0') then
        count := 0;
        counth1 := 0;
        counth0 := 0;
        hs_state <= shref1;
        href_i <= '0';
      elsif (falling_edge (camera_i_xclk)) then
        case (hs_state) is
          when shref1 =>
            if (href_time = '1') then
              href_i <= '1';
              if (counth1 = c_href1 - 1) then
                hs_state <= shref0;
                counth1 := 0;
              else
                counth1 := counth1 + 1;
              end if;
            end if;
          when shref0 =>
            href_i <= '0';
            if (counth0 = c_href0 - 1) then
              hs_state <= shref1;
              counth0 := 0;
            else
              counth0 := counth0 + 1;
            end if;
          when others => null;
        end case;
      end if;
    end process p2_href_lines;
  end generate g_source_lines_hs;

  g_source_colorbar : if (c_source = t_colorbar) generate
    -- Show pattern from virtual camera on VGA display on falling edge pclk
    camera_o_d <= pixel_time_data when href_i = '1' else (others => '0');
    p3_pixeltime : process (camera_i_xclk, camera_i_rst) is
      constant c_num_pixels : integer := c_href1 / c_colorbar_length;
      variable count1 : integer range 0 to c_num_pixels - 1;
    begin
      if (camera_i_rst = '0') then
        pixel_time_data <= (others => '0');
        pt_state <= s1;
        colorbar_count <= 0;
        count1 := 0;
      elsif (falling_edge (camera_i_xclk)) then
        case (pt_state) is
          when s1 =>
            if (pixel_time = '1') then
              pt_state <= s2;
              pixel_time_data <= colorbar (colorbar_count);
            else
              pixel_time_data <= (others => '0');
            end if;
          when s2 =>
            pixel_time_data <= colorbar (colorbar_count);
            if (count1 = c_num_pixels - 2) then -- XXX -2 equal send data
              pt_state <= s3;
              count1 := 0;
              colorbar_count <= colorbar_count + 1;
            else
              count1 := count1 + 1;
            end if;
          when s3 =>
            pixel_time_data <= colorbar (colorbar_count);
            if (colorbar_count = c_colorbar_length) then
              pt_state <= s1;
              colorbar_count <= 0;
            else
              pt_state <= s2; -- next color
            end if;
        end case;
      end if;
    end process p3_pixeltime;
  end generate g_source_colorbar;

  g_source_lines : if (c_source = t_lines) generate
    -- Show indexed lines HREF width from virtual camera on VGA display on falling edge pclk
    camera_o_d <= pixel_time_data when href_i = '1' else (others => '0');
    p3_pixeltime : process (camera_i_xclk, camera_i_rst) is
      variable count1 : integer range 0 to c_href1 - 1;
      variable count2 : integer range 0 to c_href0 - 1;
      constant c_vs_index : integer := 256;
      variable vs_index : integer range 0 to c_vs_index - 1;
    begin
      if (camera_i_rst = '0') then
        pixel_time_data <= (others => '0');
        pt_state <= s2;
        count1 := 0;
        count2 := 0;
        vs_index := 1;
      elsif (falling_edge (camera_i_xclk)) then
        case (pt_state) is
          when s2 =>
            if (href_time = '1') then
              if (count1 = c_href1 - 1) then
                pt_state <= s3;
                count1 := 0;
              else
                pixel_time_data <= std_logic_vector (to_unsigned (vs_index, pixel_time_data'left + 1));
                count1 := count1 + 1;
              end if;
            else
              pixel_time_data <= (others => '0');
            end if;
          when s3 =>
            if (count2 = c_href0 - 1) then
              if (vs_index = c_vs_index - 1) then
                pt_state <= s1;
                vs_index := 0;
              else
                vs_index := vs_index + 1;
              end if;
              count2 := 0;
              pt_state <= s2;
            else
              count2 := count2 + 1;
            end if;
          when others => null;
        end case;
      end if;
    end process p3_pixeltime;
  end generate g_source_lines;

  -- only flip source clock
  camera_o_pclk <= camera_i_xclk when (vs_state /= cold_start) else '0';

--  g_source_frames_adjust_clock : if (c_source = t_frames) generate
--  BUFG_cam : BUFG
--  port map (
--  O => clk1_fb, -- Clock buffer output
--  I => clk1 -- Clock buffer input
--  );
--
--  IBUFG_global_clock : IBUFG
--  generic map (
--  IOSTANDARD => "DEFAULT")
--  port map (
--  O => camera_i_xlkf_ibuf, -- Clock buffer output
--  I => camera_i_xclk -- Clock buffer input (connect directly to top-level port)
--  );
--
--  reset_dcm_n <= not reset_dcm;
--  synchro_reset_i0 : SRLC16E
--  port map (
--  D => '1', -- insert input signal
--  CE => '1', -- insert Clock Enable signal (optional)
--  CLK => camera_i_xlkf_ibuf, -- insert Clock signal
--  A0 => '1', -- insert Address 0 signal
--  A1 => '1', -- insert Address 1 signal
--  A2 => '1', -- insert Address 2 signal
--  A3 => '1', -- insert Address 3 signal
--  Q => reset_dcm, -- insert output signal
--  Q15 => open -- insert cascadable output signal
--  );
--
--  reset_dcm1_n <= not reset_dcm1;
--  synchro_reset_i1 : SRLC16E
--  port map (
--  D => reset_dcm, -- insert input signal
--  CE => '1', -- insert Clock Enable signal (optional)
--  CLK => camera_i_xlkf_ibuf, -- insert Clock signal
--  A0 => '1', -- insert Address 0 signal
--  A1 => '1', -- insert Address 1 signal
--  A2 => '1', -- insert Address 2 signal
--  A3 => '1', -- insert Address 3 signal
--  Q => reset_dcm1, -- insert output signal
--  Q15 => open -- insert cascadable output signal
--  );
--
--  DCM_SP_adjust_frame : DCM_SP
--  generic map (
--  CLKFX_MULTIPLY => 5, CLKFX_DIVIDE => 28,
--  CLKIN_PERIOD => 7.462
--  )
--  port map (
--  CLK0 => clk1, -- 0 degree DCM CLK ouptput
--  CLK180 => open, -- 180 degree DCM CLK output
--  CLK270 => open, -- 270 degree DCM CLK output
--  CLK2X => open, -- 2X DCM CLK output
--  CLK2X180 => open, -- 2X, 180 degree DCM CLK out
--  CLK90 => open, -- 90 degree DCM CLK output
--  CLKDV => open, -- Divided DCM CLK out (CLKDV_DIVIDE)
--  CLKFX => clock_adjust_frame, -- DCM CLK synthesis out (M/D)
--  CLKFX180 => open, -- 180 degree CLK synthesis out
--  LOCKED => open, -- DCM LOCK status output
--  PSDONE => open, -- Dynamic phase adjust done output
--  STATUS => open, -- 8-bit DCM status bits output
--  CLKFB => clk1_fb, -- DCM clock feedback
--  CLKIN => speed_clock, -- Clock input (from IBUFG, BUFG or DCM)
--  PSCLK => '0', -- Dynamic phase adjust clock input
--  PSEN => '0', -- Dynamic phase adjust enable input
--  PSINCDEC => '0', -- Dynamic phase adjust increment/decrement
--  RST => reset_dcm1_n -- DCM asynchronous reset input
--  );
--
--  BUFG_cam_speed_clock : BUFG
--  port map (
--  O => clk2_fb, -- Clock buffer output
--  I => clk2 -- Clock buffer input
--  );
--
--  DCM_SP_speed_clock : DCM_SP
--  generic map (
--  CLKFX_MULTIPLY => 28, CLKFX_DIVIDE => 5, -- ~133
--  CLKIN_PERIOD => 41.667
--  )
--  port map (
--  CLK0 => clk2, -- 0 degree DCM CLK ouptput
--  CLK180 => open, -- 180 degree DCM CLK output
--  CLK270 => open, -- 270 degree DCM CLK output
--  CLK2X => open, -- 2X DCM CLK output
--  CLK2X180 => open, -- 2X, 180 degree DCM CLK out
--  CLK90 => open, -- 90 degree DCM CLK output
--  CLKDV => open, -- Divided DCM CLK out (CLKDV_DIVIDE)
--  CLKFX => speed_clock, -- DCM CLK synthesis out (M/D)
--  CLKFX180 => open, -- 180 degree CLK synthesis out
--  LOCKED => open, -- DCM LOCK status output
--  PSDONE => open, -- Dynamic phase adjust done output
--  STATUS => open, -- 8-bit DCM status bits output
--  CLKFB => clk2_fb, -- DCM clock feedback
--  CLKIN => camera_i_xlkf_ibuf, -- Clock input (from IBUFG, BUFG or DCM)
--  PSCLK => '0', -- Dynamic phase adjust clock input
--  PSEN => '0', -- Dynamic phase adjust enable input
--  PSINCDEC => '0', -- Dynamic phase adjust increment/decrement
--  RST => reset_dcm_n -- DCM asynchronous reset input
--  );
--  end generate g_source_frames_adjust_clock;

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

