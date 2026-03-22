library IEEE;
use IEEE.STD_LOGIC_1164.all;

package p_camera_colorbar is
  constant c_zero : integer := 0;
  -- ////////////////////////
  -- // MAIN CONFIGURATION //
  -- ////////////////////////
  -- 0 - RAW, 1 - YUV/RGB for PCLK
  constant c_raw_rgb : integer := 0;
  -- Enable asserts
  constant c_asserts : boolean := false;
  -- Change cbp after each frame
  constant c_slide_colorbar_pattern : boolean := true;
  constant c_colorbar_length : integer := 5;
  type t_colorbar_data is array (0 to c_colorbar_length)
    of std_logic_vector (7 downto 0);
  constant c_colorbar : t_colorbar_data :=
    (x"FE", x"E1", x"DE", x"CE", x"BE", x"00");
  -- p.14 15 COM10 0x00 RW [2] - VSYNC changes on falling edge PCLK
  constant c_com10_02 : boolean := true;

  -- ///////////////////////////////////////
  -- // fCLK (datasheet, page 6, table 4) //
  -- ///////////////////////////////////////
  -- 21/42/100 ns - 10/24/48 MHZ - Min/Typ/Max Unit
  constant c_clock_period_max : integer := 21;
  constant c_clock_period_typ : integer := 42;
  constant c_clock_period_min : integer := 100;
  constant c_clock_period : time := c_clock_period_typ * 1 ns;

  -- //////////////////////////////////////////////////////////////////
  -- // Original values for VGA timing (datasheet, page 7, figure 6) //
  -- //////////////////////////////////////////////////////////////////
  -- 1 (RAW DATA) or 2 (YUV/RGB) - pclk for tp
  constant c_tp : integer := 2 ** c_raw_rgb;
  constant c_pixel_divider : integer := 1 * c_tp;
  -- HREF - tline = 784tp = 640tp + 144tp
  constant c_href1_base : integer := 640; -- 1
  constant c_href0_base : integer := 144; -- 0
  constant c_href1 : integer := c_href1_base * c_tp;
  constant c_href0 : integer := c_href0_base * c_tp;
  constant c_href_all : integer := c_href1 + c_href0;
  constant a_tline : integer := c_href_all;
  -- VSYNC - 510 * tline
  constant c_vsync1_base : integer := 3; -- SYNC
  constant c_vsync2_base : integer := 17; -- BP
  constant c_vsync3_base : integer := 480; -- FRAME
  constant c_vsync4_base : integer := 10; -- FP
  constant c_vsync1 : integer := c_vsync1_base * a_tline;
  constant c_vsync2 : integer := c_vsync2_base * a_tline;
  constant c_vsync3 : integer := c_vsync3_base * a_tline;
  constant c_vsync4 : integer := c_vsync4_base * a_tline;
  constant c_vsync_all : integer := c_vsync1 + c_vsync2 + c_vsync3 + c_vsync4;
  -- HSYNC
  constant c_hsync1_base : integer := 80; -- SYNC
  constant c_hsync2_base : integer := 45; -- FP
  constant c_hsync3_base : integer := 19; -- BP
  constant c_hsync1 : integer := c_hsync1_base * a_tline;
  constant c_hsync2 : integer := c_hsync2_base * a_tline;
  constant c_hsync3 : integer := c_hsync3_base * a_tline;
  constant c_hsync_all : integer := c_hsync1 + c_hsync2 + c_hsync3;

  -- //////////////////////////////////
  -- // Values for QQVGA timing (LA) //
  -- //////////////////////////////////
  -- Pixel have 4 * 42 ns
  constant c_pixel_divider_qq : integer := 4 * c_tp;
  -- HREF
  constant c_href1_base_qq : integer := 640; -- 1
  constant c_href0_base_qq : integer := 2495; -- 0
  constant c_href1_qq : integer := c_href1_base_qq * c_tp;
  constant c_href0_qq : integer := c_href0_base_qq * c_tp;
  constant c_href_qq_all : integer := c_href1_qq + c_href0_qq;
  constant a_tline_qq : integer := c_href_qq_all;
end package p_camera_colorbar;

package body p_camera_colorbar is
end package body p_camera_colorbar;
