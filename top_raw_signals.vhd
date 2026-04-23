-------------------------------------------------------------------------------
-- Company:       HomeDL
-- Engineer:      ko
-------------------------------------------------------------------------------
-- Create Date:   11:30:19 04/23/2026
-- Design Name:   OV7670 camera monitoring
-- Module Name:   top_raw_signals
-- Project Name:  mlx90640_fpga
-- Target Device: xc3s1200e-fg320-4
-- Tool versions: Xilinx ISE 14.7, XST and ISIM
-- Description:   This is (simple) example where raw signals can be
--                directing flowed from OV7670 camera (with minimal
--                configuration registers set) to 8-bit VGA output used
--                only minimal logic necessary to flip data, hv and clk.
--                Output image is not ideal, have some glitches and
--                sometimes drop the synchronization for a moment.
--                Project default run on 100 MHz clock source and must
--                be resetted several times to get stable VGA image
--                (addition, DCM CLKDV_DIVIDE constant must be set).
--                (Rest is in commented code with XXX)
--
-- Dependencies:
--  - Files: -
--  - Modules: -
--
-- Revision:
--  - Revision 0.01 - File created
--    - Files: -
--    - Modules: -
--    - Processes (Architecture: raw_signal):
--      - p_input_cam_syn - catch raw signals on falling edge clk_mc
--
-- Important objects:
--  - DCM_SP_mc_fx_vga_dv - DCM 1
--    - clk_mc - very fast clock - catch input signals on falling edge
--      (FX must be selected experimentally)
--    - clk_vga - divided clock for VGA (25 MHz)
--  - DCM_SP_cam - DCM 2
--    - clk_cam - 24 MHz standard clock
--  - Constants:
--    - c_synchronisation - on/off synchronise input signals form camera
--    - c_hs_blanking - on/off blanking (can make image better)
--    - c_pb_bits - bits for debounce input reset counter
--
-- Information from the software vendor:
--  - Messeges: -
--  - Bugs: -
--  - Notices: -
--  - Infos: -
--  - Notes: -
--  - Criticals/Failures: -
--
-- Concepts/Milestones: -
--
-- Additional Comments:
--  - ov7670_registers must use raw_signal architecture
--
-- Original comment :
-----------------------------------------------------------------------
-- OV7670 -- FPGA -- VGA -- Monitor
-- The 1st revision
-- Revision : 
--  -- Adjustment several entities so they can fit with the top module.
--  -- Generate single clock modificator.
-- Credit:
--       -- Thanks to Mike Field for Registers Reference
-- Your design might has diffent pin assignment.
-- Discuss with me by email :
--  Jason Danny Setiawan [jasondannysetiawan@gmail.com]
-----------------------------------------------------------------------
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

use work.micron_mem_parameters.all;
use work.p_constants.all;

entity top_raw_signals is
generic (
  constant c_synchronisation  : boolean := true;
  constant c_hs_blanking      : boolean := true;
  constant c_pb_bits          : integer := 25;
  constant c_zero             : integer := 0
);
port (
  i_clock     : in  STD_LOGIC;
  i_clock100  : in  STD_LOGIC;
  pb          : in  STD_LOGIC;
  sw          : in  std_logic_vector (7 downto 0);
  led1        : out STD_LOGIC; -- configuration done
  -- OV7670
  ov7670_pclk1  : in    STD_LOGIC;
  ov7670_xclk1  : out   STD_LOGIC;
  ov7670_vsync1 : in    STD_LOGIC;
  ov7670_href1  : in    STD_LOGIC;
  ov7670_data1  : in    STD_LOGIC_vector(7 downto 0);
  ov7670_sioc1  : out   STD_LOGIC;
  ov7670_siod1  : inout STD_LOGIC;
  ov7670_pwdn1  : out   STD_LOGIC;
  ov7670_reset1 : out   STD_LOGIC;
  -- memory module
  Dq    : inout std_logic_vector (c_data_bits - 1 downto 0);
  Addr  : out   std_logic_vector (c_addr_bits - 1 downto 0);
  Adv_n : out   std_logic := '1';
  Ce_n  : out   std_logic := '1';
  Clk   : out   std_logic := '0';
  Cre   : out   std_logic := '0';
  Lb_n  : out   std_logic := '0';
  Oe_n  : out   std_logic := '1';
  Ub_n  : out   std_logic := '0';
  We_n  : out   std_logic := '1';
  oWait : in    std_logic;
  -- VGA
  vga_clock : out STD_LOGIC;
  vga_blank : out STD_LOGIC;
  vga_hsync : out STD_LOGIC;
  vga_vsync : out STD_LOGIC;
  vga_r     : out STD_LOGIC_VECTOR (2 downto 0);
  vga_g     : out STD_LOGIC_VECTOR (2 downto 0);
  vga_b     : out STD_LOGIC_VECTOR (1 downto 0);
  -- Pins for debug (on JA-JD)
  vga_hsdbg     : out STD_LOGIC;
  vga_vsdbg     : out STD_LOGIC;
  ov7670_data_0 : out std_logic;
  ov7670_data_1 : out std_logic;
  ov7670_data_2 : out std_logic;
  ov7670_data_3 : out std_logic
);
end entity top_raw_signals;

architecture raw_signal of top_raw_signals is

COMPONENT ov7670_controller
Port (
  clk       : in  STD_LOGIC;
  reset1    : in  STD_LOGIC;
  resend    : in  STD_LOGIC;
  sioc      : out STD_LOGIC;
  siodi     : in  STD_LOGIC;
  siodo     : out STD_LOGIC;
  conf_done : out STD_LOGIC;
  pwdn      : out STD_LOGIC;
  reset     : out STD_LOGIC;
  xclk_in   : in  STD_LOGIC;
  xclk_out  : out STD_LOGIC
);
END COMPONENT ov7670_controller;

COMPONENT VGA_timing_synch
Port (
clk25       : in  STD_LOGIC;
rst         : in  STD_LOGIC;
Hsync       : out STD_LOGIC;
Vsync       : out STD_LOGIC;
blank       : out STD_LOGIC;
activeArea1 : out STD_LOGIC;
int, fint    : out STD_LOGIC;
vint        : in  std_logic
);
END COMPONENT VGA_timing_synch;
--for all : VGA_timing_synch use entity work.VGA_timing_synch (lsfr_2);
--for all : VGA_timing_synch use entity work.VGA_timing_synch (lsfr_1);
--for all : VGA_timing_synch use entity work.VGA_timing_synch (jc);
for all : VGA_timing_synch use entity work.VGA_timing_synch (counter);

signal siodo1, siodi1 : std_logic;

signal clk0, clk0_fb : std_logic;
signal clk1, clk1_fb : std_logic;
signal i_clock_ib : std_logic;
signal clkg1, clkg2 : std_logic;
signal clk_cam, clk_vga, clk_mc : std_logic;
signal resend : std_logic;

signal ov7670_pclk : std_logic;
signal ov7670_d : std_logic_vector (7 downto 0);
signal ov7670_hs, ov7670_vs : std_logic;

signal reset_dcm_n, reset_dcm : std_logic;

signal siodi1_n : std_logic;

signal wr_d1 : std_logic_vector (15 downto 0);

signal active1 : std_logic;
signal vga_hsync_i, vga_vsync_i : std_logic;

signal vga_rgb, vga_rgb_i : std_logic_vector (7 downto 0);

begin

  vga_r <= vga_rgb_i (7 downto 5);
  vga_g <= vga_rgb_i (4 downto 2);
  vga_b <= vga_rgb_i (1 downto 0);

--  grayscale : process (wr_d1, ov7670_hs) is
--    variable rgb : std_logic_vector (2 downto 0);
--  begin
--    rgb (2) := wr_d1 (15);
--    rgb (1) := wr_d1 (10);
--    rgb (0) := wr_d1 (4);
--    case (rgb) is
--      when "001"  => if (ov7670_hs = '1') then vga_rgb_i <= "00100100"; end if;
--      when "010"  => if (ov7670_hs = '1') then vga_rgb_i <= "01001001"; end if;
--      when "011"  => if (ov7670_hs = '1') then vga_rgb_i <= "01101101"; end if;
--      when "100"  => if (ov7670_hs = '1') then vga_rgb_i <= "10010010"; end if;
--      when "101"  => if (ov7670_hs = '1') then vga_rgb_i <= "10110110"; end if;
--      when "110"  => if (ov7670_hs = '1') then vga_rgb_i <= "11011011"; end if;
--      when "111"  => if (ov7670_hs = '1') then vga_rgb_i <= "11111111"; end if;
--      when others => if (ov7670_hs = '1') then vga_rgb_i <= "00000000"; end if;
--    end case;
--  end process grayscale;

--  prio_dec_black_white : process (sw, wr_d1, ov7670_hs) is
--  begin
--    case (sw) is
--      when "1-------" =>
--        if (ov7670_hs = '1') then
--          vga_rgb_i <=
--            (wr_d1 (15) xor wr_d1 (14)) &
--            (wr_d1 (15) xor wr_d1 (14)) &
--            (wr_d1 (15) xor wr_d1 (14)) &
--            (wr_d1 (15) xor wr_d1 (14)) &
--            (wr_d1 (15) xor wr_d1 (14)) &
--            (wr_d1 (15) xor wr_d1 (14)) &
--            (wr_d1 (15) xor wr_d1 (14)) &
--            (wr_d1 (15) xor wr_d1 (14));
--        end if;
--      when "01------" =>
--        if (ov7670_hs = '1') then
--          vga_rgb_i <=
--            (wr_d1 (13) xor wr_d1 (12)) &
--            (wr_d1 (13) xor wr_d1 (12)) &
--            (wr_d1 (13) xor wr_d1 (12)) &
--            (wr_d1 (13) xor wr_d1 (12)) &
--            (wr_d1 (13) xor wr_d1 (12)) &
--            (wr_d1 (13) xor wr_d1 (12)) &
--            (wr_d1 (13) xor wr_d1 (12)) &
--            (wr_d1 (13) xor wr_d1 (12));
--        end if;
--      when "001-----" =>
--        if (ov7670_hs = '1') then
--          vga_rgb_i <=
--            (wr_d1 (11) xor wr_d1 (10)) &
--            (wr_d1 (11) xor wr_d1 (10)) &
--            (wr_d1 (11) xor wr_d1 (10)) &
--            (wr_d1 (11) xor wr_d1 (10)) &
--            (wr_d1 (11) xor wr_d1 (10)) &
--            (wr_d1 (11) xor wr_d1 (10)) &
--            (wr_d1 (11) xor wr_d1 (10)) &
--            (wr_d1 (11) xor wr_d1 (10));
--        end if;
--      when "0001----" =>
--        if (ov7670_hs = '1') then
--          vga_rgb_i <=
--            (wr_d1 (9) xor wr_d1 (8)) &
--            (wr_d1 (9) xor wr_d1 (8)) &
--            (wr_d1 (9) xor wr_d1 (8)) &
--            (wr_d1 (9) xor wr_d1 (8)) &
--            (wr_d1 (9) xor wr_d1 (8)) &
--            (wr_d1 (9) xor wr_d1 (8)) &
--            (wr_d1 (9) xor wr_d1 (8)) &
--            (wr_d1 (9) xor wr_d1 (8));
--        end if;
--      when "00001---" =>
--        if (ov7670_hs = '1') then
--          vga_rgb_i <=
--            (wr_d1 (7) xor wr_d1 (6)) &
--            (wr_d1 (7) xor wr_d1 (6)) &
--            (wr_d1 (7) xor wr_d1 (6)) &
--            (wr_d1 (7) xor wr_d1 (6)) &
--            (wr_d1 (7) xor wr_d1 (6)) &
--            (wr_d1 (7) xor wr_d1 (6)) &
--            (wr_d1 (7) xor wr_d1 (6)) &
--            (wr_d1 (7) xor wr_d1 (6));
--        end if;
--      when "000001--" =>
--        if (ov7670_hs = '1') then
--          vga_rgb_i <=
--            (wr_d1 (5) xor wr_d1 (4)) &
--            (wr_d1 (5) xor wr_d1 (4)) &
--            (wr_d1 (5) xor wr_d1 (4)) &
--            (wr_d1 (5) xor wr_d1 (4)) &
--            (wr_d1 (5) xor wr_d1 (4)) &
--            (wr_d1 (5) xor wr_d1 (4)) &
--            (wr_d1 (5) xor wr_d1 (4)) &
--            (wr_d1 (5) xor wr_d1 (4));
--        end if;
--      when "0000001-" =>
--        if (ov7670_hs = '1') then
--          vga_rgb_i <=
--            (wr_d1 (3) xor wr_d1 (2)) &
--            (wr_d1 (3) xor wr_d1 (2)) &
--            (wr_d1 (3) xor wr_d1 (2)) &
--            (wr_d1 (3) xor wr_d1 (2)) &
--            (wr_d1 (3) xor wr_d1 (2)) &
--            (wr_d1 (3) xor wr_d1 (2)) &
--            (wr_d1 (3) xor wr_d1 (2)) &
--            (wr_d1 (3) xor wr_d1 (2));
--        end if;
--      when "00000001" =>
--        if (ov7670_hs = '1') then
--          vga_rgb_i <=
--            (wr_d1 (1) xor wr_d1 (0)) &
--            (wr_d1 (1) xor wr_d1 (0)) &
--            (wr_d1 (1) xor wr_d1 (0)) &
--            (wr_d1 (1) xor wr_d1 (0)) &
--            (wr_d1 (1) xor wr_d1 (0)) &
--            (wr_d1 (1) xor wr_d1 (0)) &
--            (wr_d1 (1) xor wr_d1 (0)) &
--            (wr_d1 (1) xor wr_d1 (0));
--        end if;
--      when others =>
--        if (ov7670_hs = '1') then
--          vga_rgb_i <= wr_d1 (15 downto 13) & wr_d1 (10 downto 8) & wr_d1 (4 downto 3);
--        end if;
--    end case;
--  end process prio_dec_black_white;

  siodi1_n <= not siodi1;
  ov7670_siod1_tri : IOBUF
  port map (
    O  => (siodi1),
    IO => (ov7670_siod1),
    I  => (siodo1),
    T  => (siodi1_n)
  );

  inst_debounce : entity work.debounce_circuit (Behavioral)
  generic map (
    pb_bits => c_pb_bits
  )
  port map (
    clk    => i_clock_ib,
    reset  => reset_dcm_n,
    input  => pb,
    output => resend
  );

  inst_ov7670contr1 : ov7670_controller
  port map (
    clk       => i_clock_ib,
    reset1    => resend,
    resend    => resend,
    sioc      => ov7670_sioc1,
    siodi     => siodi1,
    siodo     => siodo1,
    conf_done => led1,
    pwdn      => ov7670_pwdn1,
    reset     => ov7670_reset1,
    xclk_in   => clk_cam,
    xclk_out  => ov7670_xclk1
  );

  inst_ov7670capt1 : entity work.ov7670_capture (Behavioral)
  port map (
    pclk  => ov7670_pclk,
    reset => reset_dcm_n,
    vsync => ov7670_vs,
    href  => ov7670_hs,
    d     => ov7670_d,
    addr  => open,
    dout  => wr_d1,
    we    => open
  );

  g_input_cam_syn : if (c_synchronisation = true) generate
    p_input_cam_syn : process (clk_mc, reset_dcm_n) is
    begin
      if (reset_dcm_n = '1') then
        ov7670_pclk <= '0';
        ov7670_hs <= '0';
        ov7670_vs <= '0';
        ov7670_d <= (others => '0');
      elsif (falling_edge (clk_mc)) then
        ov7670_pclk <= ov7670_pclk1;
        ov7670_hs <= ov7670_href1;
        ov7670_vs <= ov7670_vsync1;
        ov7670_d <= ov7670_data1;
      end if;
    end process p_input_cam_syn;
  end generate g_input_cam_syn;

  g_input_cam_no_syn : if (c_synchronisation = false) generate
    ov7670_pclk <= ov7670_pclk1;
    ov7670_hs   <= ov7670_href1;
    ov7670_vs   <= ov7670_vsync1;
    ov7670_d    <= ov7670_data1;
  end generate g_input_cam_no_syn;

  g_hsync_blanking : if (c_hs_blanking = true) generate
    inst_imagegen_blanking : entity work.vga_imagegenerator (Behavioral)
    port map (
      Data_in1     => wr_d1,
      reset        => reset_dcm_n,
      active_area1 => ov7670_hs,
      RGB_out      => vga_rgb_i
    );
  end generate g_hsync_blanking;

  g_hsync_no_blanking : if (c_hs_blanking = false) generate
    inst_imagegen_no_blanking : entity work.vga_imagegenerator (Behavioral)
    port map (
      Data_in1     => wr_d1,
      reset        => reset_dcm_n,
      active_area1 => '1',
      RGB_out      => vga_rgb_i
    );
  end generate g_hsync_no_blanking;

  inst_vgatiming : VGA_timing_synch
  port map (
    clk25       => clk_vga,
    rst         => resend,
    Hsync       => vga_hsync_i,
    Vsync       => vga_vsync_i,
    blank       => vga_blank,
    activeArea1 => active1,
    int         => open,
    fint         => open,
    vint        => '0'
  );

  vga_hsdbg <= vga_hsync_i;
  vga_vsdbg <= vga_vsync_i;
  vga_hsync <= ov7670_hs;
  vga_vsync <= ov7670_vs;
  --vga_hsync <= vga_hsync_i;
  --vga_vsync <= vga_vsync_i;
  
  vga_clock <= clk_vga;
  --vga_clock <= ov7670_pclk;
  --vga_clock <= clk_cam; -- debug camera clock

  IBUFG_global_clock : IBUFG
  generic map (
    IOSTANDARD => "DEFAULT")
  port map (
    O => i_clock_ib,
    I => i_clock100
  );

  reset_dcm_n <= not reset_dcm;
  synchro_reset_i0 : SRLC16E
  port map (
    D   => '1',
    CE  => '1',
    CLK => i_clock_ib,
    A0  => '1',
    A1  => '1',
    A2  => '1',
    A3  => '1',
    Q   => reset_dcm,
    Q15 => open
  );

  BUFG_clock_source_mc_vga : BUFG
  port map (
    O => clkg1,
    I => i_clock_ib
  );

  BUFG_mc_vga_fb : BUFG
  port map (
    O => clk0_fb,
    I => clk0
  );

  DCM_SP_mc_fx_vga_dv : DCM_SP
  generic map (
    CLKDV_DIVIDE   => 4.0, -- 25 MHz
    CLKFX_MULTIPLY => 31, CLKFX_DIVIDE => 2, -- stable
    CLKIN_PERIOD   => 10.0 -- 100 MHz
  )
  port map (
    CLK0  => clk0,
    CLKDV => clk_vga,
    CLKFX => clk_mc, -- catch signals from camera
    CLKFB => clk0_fb,
    CLKIN => clkg1,
    RST   => resend,
    PSCLK => '0', PSEN => '0', PSINCDEC => '0'
  );

  BUFG_clock_source_cam : BUFG
  port map (
    O => clkg2,
    I => i_clock_ib
  );

  BUFG_cam_fb : BUFG
  port map (
    O => clk1_fb,
    I => clk1
  );

  DCM_SP_cam : DCM_SP
  generic map (
    CLKFX_MULTIPLY => 6, CLKFX_DIVIDE => 25, -- camera xclk 24.0 mhz
    CLKIN_PERIOD   => 10.0 -- 100 MHz
  )
  port map (
    CLK0  => clk1,
    CLKFX => clk_cam,
    CLKFB => clk1_fb,
    CLKIN => clkg2,
    RST   => resend,
    PSCLK => '0', PSEN => '0', PSINCDEC => '0'
  );

end architecture raw_signal;
