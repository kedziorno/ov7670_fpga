----------------------------------------------------------------------------------
-- OV7670 -- FPGA -- VGA -- Monitor
-- The 1st revision
-- Revision : 
	-- Adjustment several entities so they can fit with the top module.
	-- Generate single clock modificator.
-- Credit:
	-- Thanks to Mike Field for Registers Reference
-- Your design might has diffent pin assignment.
-- Discuss with me by email : Jason Danny Setiawan [jasondannysetiawan@gmail.com]
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.numeric_std.all;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

use work.micron_mem_parameters.all;
use work.p_constants.all;
use work.p_camera_colorbar.all;

entity top_camera_monitoring is
generic (
  constant c_synchronisation : boolean := true;
  constant c_hs_blanking : boolean := true;
  constant c_pb_bits : integer := 1;
  constant c_zero : integer := 0
);
port	(
  i_clock	: in STD_LOGIC;
  i_clock100	: in STD_LOGIC;
  pb		: in STD_LOGIC;
  sw : in std_logic_vector (7 downto 0);
  led1 : out STD_LOGIC; -- configuration done
  -- OV7670
  ov7670_pclk1 : in  STD_LOGIC;
  ov7670_xclk1 : out STD_LOGIC;
  ov7670_vsync1 : in  STD_LOGIC;
  ov7670_href1 : in  STD_LOGIC;
  ov7670_data1 : in  STD_LOGIC_vector(7 downto 0);
  ov7670_sioc1 : out STD_LOGIC;
  ov7670_siod1 : inout STD_LOGIC;
  ov7670_pwdn1 : out STD_LOGIC;
  ov7670_reset1 : out STD_LOGIC;
  --memory module
  Dq : inout std_logic_vector (c_data_bits - 1 downto 0);
  Addr : out std_logic_vector (c_addr_bits - 1 downto 0);
  Adv_n : out std_logic := '1';
  Ce_n : out std_logic := '1';
  Clk : out std_logic := '0';
  Cre : out std_logic := '0';
  Lb_n : out std_logic := '0';
  Oe_n : out std_logic := '1';
  Ub_n : out std_logic := '0';
  We_n : out std_logic := '1';
  oWait : in std_logic;
  --VGA
  vga_clock : out STD_LOGIC;
  vga_blank : out STD_LOGIC;
  vga_hsync, vga_hsdbg : out STD_LOGIC;
  vga_vsync, vga_vsdbg : out STD_LOGIC;
  vga_r	: out STD_LOGIC_VECTOR(2 downto 0);
  vga_g	: out STD_LOGIC_VECTOR(2 downto 0);
  vga_b	: out STD_LOGIC_VECTOR(1 downto 0);
  ov7670_data_0, ov7670_data_1, ov7670_data_2, ov7670_data_3 : out std_logic
);
end top_camera_monitoring;

architecture raw_signal of top_camera_monitoring is

COMPONENT debounce_circuit
	Port ( clk : in STD_LOGIC;
			 input : in STD_LOGIC;
			 output : out STD_LOGIC);
END COMPONENT;

COMPONENT ov7670_capture
	Port ( pclk : in  STD_LOGIC;
          vsync : in  STD_LOGIC;
          href : in  STD_LOGIC;
          d : in  STD_LOGIC_VECTOR (7 downto 0);
          addr : out  STD_LOGIC_VECTOR (18 downto 0);
          dout : out  STD_LOGIC_VECTOR (15 downto 0);
          we : out  STD_LOGIC_VECTOR (0 downto 0));
END COMPONENT;

COMPONENT ov7670_controller
	Port ( clk : in  STD_LOGIC;
          reset1 : in  STD_LOGIC;
          resend : in  STD_LOGIC;
          sioc : out  STD_LOGIC;
          siodi : in  STD_LOGIC;
          siodo : out  STD_LOGIC;
          conf_done : out  STD_LOGIC;
          pwdn : out  STD_LOGIC;
			 reset: out  STD_LOGIC;
			 xclk_in : in  STD_LOGIC;
          xclk_out: out  STD_LOGIC);
END COMPONENT;

COMPONENT vga_imagegenerator
	Port ( Data_in1 : in  STD_LOGIC_VECTOR (15 downto 0);
						active_area1 : in  STD_LOGIC;
           RGB_out : out  STD_LOGIC_VECTOR (7 downto 0));
END COMPONENT;

COMPONENT VGA_timing_synch
	Port ( clk25, rst : in  STD_LOGIC;
           Hsync : out  STD_LOGIC;
           Vsync : out  STD_LOGIC;
           blank : out  STD_LOGIC;
           activeArea1 : out  STD_LOGIC;
           int, fint : out  STD_LOGIC;
           vint : in std_logic);
END COMPONENT;
--for all : VGA_timing_synch use entity work.VGA_timing_synch(lsfr_2);
--for all : VGA_timing_synch use entity work.VGA_timing_synch(lsfr_1);
--for all : VGA_timing_synch use entity work.VGA_timing_synch(jc);
for all : VGA_timing_synch use entity work.VGA_timing_synch(counter);

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

signal vga_rgb : std_logic_vector (7 downto 0);
  
begin

  vga_r <= vga_rgb (7 downto 5);
  vga_g <= vga_rgb (4 downto 2);
  vga_b <= vga_rgb (1 downto 0);

--  grayscale : process (wr_d1, ov7670_hs) is
--    variable rgb : std_logic_vector (2 downto 0);
--  begin
--    rgb (2) := wr_d1 (15);
--    rgb (1) := wr_d1 (10);
--    rgb (0) := wr_d1 (4);
--    case (rgb) is
--      when "001"  => if (ov7670_hs = '1') then vga_rgb <= "00100100"; end if;
--      when "010"  => if (ov7670_hs = '1') then vga_rgb <= "01001001"; end if;
--      when "011"  => if (ov7670_hs = '1') then vga_rgb <= "01101101"; end if;
--      when "100"  => if (ov7670_hs = '1') then vga_rgb <= "10010010"; end if;
--      when "101"  => if (ov7670_hs = '1') then vga_rgb <= "10110110"; end if;
--      when "110"  => if (ov7670_hs = '1') then vga_rgb <= "11011011"; end if;
--      when "111"  => if (ov7670_hs = '1') then vga_rgb <= "11111111"; end if;
--      when others => if (ov7670_hs = '1') then vga_rgb <= "00000000"; end if;
--    end case;
--  end process grayscale;

--  prio_dec_black_white : process (sw, wr_d1, ov7670_hs) is
--  begin
--    case (sw) is
--      when "1-------" =>
--        if (ov7670_hs = '1') then
--          vga_rgb <=
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
--          vga_rgb <=
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
--          vga_rgb <=
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
--          vga_rgb <=
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
--          vga_rgb <=
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
--          vga_rgb <=
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
--          vga_rgb <=
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
--          vga_rgb <=
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
--          vga_rgb <= wr_d1 (15 downto 13) & wr_d1 (10 downto 8) & wr_d1 (4 downto 3);
--        end if;
--    end case;
--  end process prio_dec_black_white;

  siodi1_n <= not siodi1;
  ov7670_siod1_tri : IOBUF port map (
     O  => (siodi1),
     IO => (ov7670_siod1),
     I  => (siodo1),
     T  => (siodi1_n)
  );

	inst_debounce: debounce_circuit port map(
		clk => i_clock_ib,
		input => pb,
		output => resend
  );

	inst_ov7670contr1: ov7670_controller port map(
		clk => i_clock_ib,
    reset1 => resend,
		resend => resend,
		sioc => ov7670_sioc1,
		siodi => siodi1,
		siodo => siodo1,
		conf_done => led1,
		pwdn => ov7670_pwdn1,
		reset => ov7670_reset1,
		xclk_in => clk_cam,
		xclk_out => ov7670_xclk1
  );

  g_input_cam_syn : if (c_synchronisation = true) generate
    process (clk_mc, resend) is
    begin
      if (resend = '1') then
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
    end process;
  end generate g_input_cam_syn;

  g_input_cam_no_syn : if (c_synchronisation = false) generate
    ov7670_pclk <= ov7670_pclk1;
    ov7670_hs <= ov7670_href1;
    ov7670_vs <= ov7670_vsync1;
    ov7670_d <= ov7670_data1;
  end generate g_input_cam_no_syn;

	inst_ov7670capt1: ov7670_capture port map(
		pclk => ov7670_pclk,
		vsync => ov7670_vs,
		href => ov7670_hs,
		d => ov7670_d,
		addr => open,
		dout => wr_d1,
		we => open
  );

  g_hsync_blanking : if (c_hs_blanking = true) generate
    inst_imagegen_blanking : vga_imagegenerator port map(
      Data_in1 => wr_d1,
      active_area1 => ov7670_hs,
      RGB_out => vga_rgb
    );
  end generate g_hsync_blanking;

  g_hsync_no_blanking : if (c_hs_blanking = false) generate
    inst_imagegen_no_blanking : vga_imagegenerator port map(
      Data_in1 => wr_d1,
      active_area1 => '1',
      RGB_out => vga_rgb
    );
  end generate g_hsync_no_blanking;

  inst_vgatiming : VGA_timing_synch port map(
    clk25 => clk_vga,
    rst => resend,
    Hsync => vga_hsync_i,
    Vsync => vga_vsync_i,
    blank => vga_blank,
    activeArea1 => active1,
    int => open,
    fint => open,
    vint => '0'
  );

  vga_hsync <= ov7670_hs;
  vga_vsync <= ov7670_vs;
  --vga_hsync <= vga_hsync_i;
  --vga_vsync <= vga_vsync_i;
  vga_hsdbg <= vga_hsync_i;
  vga_vsdbg <= vga_vsync_i;

  --vga_clock <= ov7670_pclk;
  --vga_clock <= clk_vga;
  vga_clock <= clk_cam; -- debug camera clock

  BUFG_mc : BUFG
  port map (
    O => clk0_fb,
    I => clk0
  );

  BUFG_cam : BUFG
  port map (
    O => clk1_fb,
    I => clk1
  );

  IBUFG_global_clock : IBUFG
  generic map (
    IOSTANDARD => "DEFAULT")
  port map (
    O => i_clock_ib,
    I => i_clock
  );

  BUFG_clk1 : BUFG
  port map (
    O => clkg1,
    I => i_clock_ib
  );

  BUFG_clk2 : BUFG
  port map (
    O => clkg2,
    I => i_clock_ib
  );

  reset_dcm_n <= not reset_dcm;
  synchro_reset_i0 : SRLC16E
  port map (
    D => '1', -- insert input signal
    CE => '1', -- insert Clock Enable signal (optional)
    CLK => i_clock_ib, -- insert Clock signal
    A0 => '1', -- insert Address 0 signal
    A1 => '1', -- insert Address 1 signal
    A2 => '1', -- insert Address 2 signal
    A3 => '1', -- insert Address 3 signal
    Q => reset_dcm, -- insert output signal
    Q15 => open -- insert cascadable output signal
  );

  DCM_SP_mc_fx_vga_dv : DCM_SP
  generic map (
    --CLKDV_DIVIDE => 2.0, -- 50mhz
    CLKDV_DIVIDE => 4.0, -- 100mhz
    CLKFX_MULTIPLY => 31, -- Can be any integer from 1 to 32
    --CLKFX_DIVIDE => 1, -- dont work
    --CLKFX_DIVIDE => 2, -- glitches, max
    CLKFX_DIVIDE => 3, -- stable
    CLKIN_DIVIDE_BY_2 => FALSE, -- TRUE/FALSE to enable CLKIN divide by two feature
    CLKIN_PERIOD => 10.0, -- Specify period of input clock
    CLKOUT_PHASE_SHIFT => "NONE", -- Specify phase shift of "NONE", "FIXED" or "VARIABLE"
    CLK_FEEDBACK => "1X", -- Specify clock feedback of "NONE", "1X" or "2X"
    DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", -- "SOURCE_SYNCHRONOUS", "SYSTEM_SYNCHRONOUS" or
    -- an integer from 0 to 15
    DLL_FREQUENCY_MODE => "LOW", -- "HIGH" or "LOW" frequency mode for DLL
    DUTY_CYCLE_CORRECTION => TRUE, -- Duty cycle correction, TRUE or FALSE
    PHASE_SHIFT => 0, -- Amount of fixed phase shift from -255 to 255
    STARTUP_WAIT => FALSE) -- Delay configuration DONE until DCM_SP LOCK, TRUE/FALSE
  port map (
    CLK0 => clk0, -- 0 degree DCM CLK ouptput
    CLK180 => open, -- 180 degree DCM CLK output
    CLK270 => open, -- 270 degree DCM CLK output
    CLK2X => open, -- 2X DCM CLK output
    CLK2X180 => open, -- 2X, 180 degree DCM CLK out
    CLK90 => open, -- 90 degree DCM CLK output
    CLKDV => clk_vga, -- Divided DCM CLK out (CLKDV_DIVIDE)
    CLKFX => clk_mc, -- DCM CLK synthesis out (M/D)
    CLKFX180 => open, -- 180 degree CLK synthesis out
    LOCKED => open, -- DCM LOCK status output
    PSDONE => open, -- Dynamic phase adjust done output
    STATUS => open, -- 8-bit DCM status bits output
    CLKFB => clk0_fb, -- DCM clock feedback
    CLKIN => clkg1, -- Clock input (from IBUFG, BUFG or DCM)
    PSCLK => '0', -- Dynamic phase adjust clock input
    PSEN => '0', -- Dynamic phase adjust enable input
    PSINCDEC => '0', -- Dynamic phase adjust increment/decrement
    RST => reset_dcm_n -- DCM asynchronous reset input
  );

  DCM_SP_cam : DCM_SP
  generic map (
    CLKDV_DIVIDE => 2.0, -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
    -- 7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
    --CLKFX_MULTIPLY => 12, CLKFX_DIVIDE => 24, -- 50 -> 25 mhz
    --CLKFX_MULTIPLY => 12, CLKFX_DIVIDE => 25, -- 50 -> 24.0 mhz
    CLKFX_MULTIPLY => 6, CLKFX_DIVIDE => 25, -- 100 -> 24.0 mhz
    --CLKFX_MULTIPLY => 13, CLKFX_DIVIDE => 27, -- 50 -> 24.07407407407407407400 mhz
    --CLKFX_MULTIPLY => 14, CLKFX_DIVIDE => 29, -- 50 -> 24.13793103448275862050 mhz
    --CLKFX_MULTIPLY => 15, CLKFX_DIVIDE => 31, -- 50 -> 24.19354838709677419350 mhz
    --CLKFX_MULTIPLY => 24, CLKFX_DIVIDE => 25, -- 50 -> 48.0 mhz
    CLKIN_DIVIDE_BY_2 => FALSE, -- TRUE/FALSE to enable CLKIN divide by two feature
    CLKIN_PERIOD => 10.0, -- Specify period of input clock
    CLKOUT_PHASE_SHIFT => "NONE", -- Specify phase shift of "NONE", "FIXED" or "VARIABLE"
    CLK_FEEDBACK => "1X", -- Specify clock feedback of "NONE", "1X" or "2X"
    DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", -- "SOURCE_SYNCHRONOUS", "SYSTEM_SYNCHRONOUS" or
    -- an integer from 0 to 15
    DLL_FREQUENCY_MODE => "LOW", -- "HIGH" or "LOW" frequency mode for DLL
    DUTY_CYCLE_CORRECTION => TRUE, -- Duty cycle correction, TRUE or FALSE
    PHASE_SHIFT => 0, -- Amount of fixed phase shift from -255 to 255
    STARTUP_WAIT => FALSE) -- Delay configuration DONE until DCM_SP LOCK, TRUE/FALSE
  port map (
    CLK0 => clk1, -- 0 degree DCM CLK ouptput
    CLK180 => open, -- 180 degree DCM CLK output
    CLK270 => open, -- 270 degree DCM CLK output
    CLK2X => open, -- 2X DCM CLK output
    CLK2X180 => open, -- 2X, 180 degree DCM CLK out
    CLK90 => open, -- 90 degree DCM CLK output
    CLKDV => open, -- Divided DCM CLK out (CLKDV_DIVIDE)
    CLKFX => clk_cam, -- DCM CLK synthesis out (M/D)
    CLKFX180 => open, -- 180 degree CLK synthesis out
    LOCKED => open, -- DCM LOCK status output
    PSDONE => open, -- Dynamic phase adjust done output
    STATUS => open, -- 8-bit DCM status bits output
    CLKFB => clk1_fb, -- DCM clock feedback
    CLKIN => clkg2, -- Clock input (from IBUFG, BUFG or DCM)
    PSCLK => '0', -- Dynamic phase adjust clock input
    PSEN => '0', -- Dynamic phase adjust enable input
    PSINCDEC => '0', -- Dynamic phase adjust increment/decrement
    RST => reset_dcm_n -- DCM asynchronous reset input
  );

end architecture raw_signal;

-- ///////////////////////////////////////////////////////////////////////////////
-- ///////////////////////////////////////////////////////////////////////////////
-- ///////////////////////////////////////////////////////////////////////////////

architecture Structural of top_camera_monitoring is

COMPONENT debounce_circuit
Generic (PB_BITS : integer := 1);
	Port ( clk, reset : in STD_LOGIC;
			 input : in STD_LOGIC;
			 output : out STD_LOGIC);
END COMPONENT;

COMPONENT ov7670_capture
	Port ( pclk,reset : in  STD_LOGIC;
          vsync : in  STD_LOGIC;
          href : in  STD_LOGIC;
          d : in  STD_LOGIC_VECTOR (7 downto 0);
          addr : out  STD_LOGIC_VECTOR (9 downto 0);
          dout : out  STD_LOGIC_VECTOR (15 downto 0);
          we : out  STD_LOGIC_VECTOR (0 downto 0);
latched_vs, latched_hs : out std_logic;
int : out std_logic);
END COMPONENT;
signal cint : std_logic;

COMPONENT ov7670_controller
	Port ( clk : in  STD_LOGIC;
          reset1 : in  STD_LOGIC;
          resend : in  STD_LOGIC;
          sioc : out  STD_LOGIC;
          siodi : in  STD_LOGIC;
          siodo : out  STD_LOGIC;
          conf_done : out  STD_LOGIC;
          pwdn : out  STD_LOGIC;
			 reset: out  STD_LOGIC;
			 xclk_in : in  STD_LOGIC;
          xclk_out: out  STD_LOGIC);
END COMPONENT;

COMPONENT vga_imagegenerator
	Port ( Data_in1 : in  STD_LOGIC_VECTOR (15 downto 0);
						active_area1,reset : in  STD_LOGIC;
           RGB_out : out  STD_LOGIC_VECTOR (7 downto 0));
END COMPONENT;

COMPONENT address_generator
	Port ( clk25,reset : in STD_LOGIC;
			 enable : in STD_LOGIC;
			 vsync : in STD_LOGIC;
			 address : out STD_LOGIC_VECTOR (9 downto 0);
			 address1 : out STD_LOGIC_VECTOR (10 downto 0));
END COMPONENT;
signal address1 : STD_LOGIC_VECTOR (10 downto 0);

COMPONENT VGA_timing_synch
	Port ( clk25, rst : in  STD_LOGIC;
           Hsync : out  STD_LOGIC;
           Vsync : out  STD_LOGIC;
           blank : out  STD_LOGIC;
           activeArea1 : out  STD_LOGIC;
           int, fint : out std_logic;
           vint : in std_logic);
END COMPONENT;
--for all : VGA_timing_synch use entity work.VGA_timing_synch(lsfr_2);
--for all : VGA_timing_synch use entity work.VGA_timing_synch(lsfr_1);
--for all : VGA_timing_synch use entity work.VGA_timing_synch(jc);
for all : VGA_timing_synch use entity work.VGA_timing_synch(counter);

-- RAM FB
signal wren1 : STD_LOGIC_VECTOR(0 downto 0);
signal wr_d1 : STD_LOGIC_VECTOR(15 downto 0);
signal wr_a1 : STD_LOGIC_VECTOR(9 downto 0);
signal rd_d1 : STD_LOGIC_VECTOR(15 downto 0);
signal rd_a1 : STD_LOGIC_VECTOR(9 downto 0);

--VGA
signal active1 : STD_LOGIC;
signal vga_vsync_sig : STD_LOGIC := '1';
signal vga_vsync_sig_prev : STD_LOGIC := '1';

signal cc : std_logic;
signal ov7670_pclk1_ibuf : std_logic;
signal ov7670_pclk1_inv : std_logic;

signal we_ni, oe_ni : std_logic;
type mem_switch_states is (a, b, c, d);
signal mem_switch_state : mem_switch_states := a;

signal siodo1, siodi1 : std_logic;
signal siodo1_n : std_logic;

signal clk0, clk0_fb : std_logic;
signal clk1, clk1_fb : std_logic;
signal i_clock_ib1 : std_logic;
signal i_clock_ib2 : std_logic;
signal clk_cam, clk_vga, clk_mc : std_logic;
signal resend : std_logic;

signal ov7670_pclk : std_logic;
signal ov7670_d : std_logic_vector (7 downto 0);
signal ov7670_hs, ov7670_vs : std_logic;

signal rgb444 : std_logic_vector (15 downto 0);
signal rgb565 : std_logic_vector (15 downto 0);
signal datain : std_logic_vector (15 downto 0);

signal vga_rgb : std_logic_vector (7 downto 0);

signal reset_dcm_n, reset_dcm : std_logic;

signal rd_counter : integer range 0 to c_memory_operation_wait_rd - 1;
signal rd_counter1 : integer range 0 to c_memory_operation_wait_rd - 1;
signal wr_counter : integer range 0 to c_memory_operation_wait_wr - 1;
signal wr_counter1 : integer range 0 to c_memory_operation_wait_wr - 1;

signal vga_clock_i : std_logic;
signal vga_clock_p : std_logic;
signal ov7670_pclk_p : std_logic;
signal vga_re, cam_re : std_logic;

constant CLKFX_MULTIPLY_MC : integer := 4;
constant CLKFX_DIVIDE_MC : integer := 2;

COMPONENT cellular_ram_burst_controller
PORT(
busy : OUT  std_logic;
clk : IN  std_logic;
reset : IN  std_logic;
writes : IN  std_logic;
data : IN  std_logic_vector(15 downto 0);
id : IN  std_logic_vector(15 downto 0);

write_buffer_addr : IN  std_logic_vector(9 downto 0);
write_buffer_data : IN  std_logic_vector(15 downto 0);
write_buffer_clk : IN  std_logic;
write_buffer_we : IN  std_logic;

clk25 : in std_logic;
read_buffer_addr : IN  std_logic_vector(9 downto 0);
read_buffer_data : OUT  std_logic_vector(15 downto 0);
read_buffer_clk : IN  std_logic;

lb : OUT  std_logic;
ub : OUT  std_logic;
oe : OUT  std_logic;
we : OUT  std_logic;
adv : OUT  std_logic;
ce : OUT  std_logic;
cre : OUT  std_logic;
ram_clk : OUT  std_logic;
o_wait : IN  std_logic;
a : OUT  std_logic_vector(22 downto 0);
dq : INOUT  std_logic_vector(15 downto 0);
vga_int : in std_logic
);
END COMPONENT cellular_ram_burst_controller;
signal busy, wrc : std_logic;
signal data, id : std_logic_vector(15 downto 0);

type p_states0 is (
a0, a1, a1a, aw, bw, cw, cw1, dw, ew
);
type p_states1 is (
a0, ar1, ar2, a0a, ar, br, cr, dr, er, er1
);
signal p0_state : p_states0 := a0;
signal p1_state : p_states1 := a0;
constant c_w8_bw : integer := 3200/2/2/2/2;
signal w8_bw : integer range 0 to c_w8_bw - 1 := 0;
constant c_w8_br : integer := 3200/2/2/2/2;
signal w8_br : integer range 0 to c_w8_br - 1 := 0;

constant c_cntr_frame : integer := 307200/2;
constant c_step_w : unsigned (15 downto 0) := to_unsigned (320, 16);
constant c_step_r : unsigned (15 downto 0) := to_unsigned (320, 16);
signal cntr_wr1 : unsigned (17 downto 0) := (others => '0');
signal cntr_wr1_slv : std_logic_vector (17 downto 0) := (others => '0');
signal cntr_rd1 : unsigned (17 downto 0) := (others => '0');
signal cntr_rd1_slv : std_logic_vector (17 downto 0) := (others => '0');
signal ov7670_vs_next : std_logic_vector (1 downto 0) := (others => '0');
signal ov7670_vs_prev : std_logic := '0';
signal start_read : std_logic := '0';

signal vga_hsync_i, vga_hsync_i_prev : std_logic := '1';

signal data_r, data_w, id_r, id_w : std_logic_vector (15 downto 0) := (others => '0');
signal p0_r, p0_w : std_logic;
signal wrc_r, wrc_w : std_logic;

signal latched_hs, latched_vs : std_logic;

signal clk2x_1, clk2x_2 : std_logic;

signal ov7670_hs_prev : std_logic;

signal oe_n_i, we_n_i : std_logic;

signal reset_vga_timing : std_logic := '1';

signal vga_int, vga_fint : std_logic;

signal cints, cint1 : std_logic;

signal owait1 : std_logic;

component camera_colorbar is
generic (
constant c_source : t_source := t_colorbar
);
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
end component camera_colorbar;
signal ov7670_pclkv : STD_LOGIC;
signal ov7670_xclkv : STD_LOGIC;
signal ov7670_vsyncv : STD_LOGIC;
signal ov7670_hrefv : STD_LOGIC;
signal ov7670_datav : STD_LOGIC_vector(7 downto 0);
signal ov7670_siocv : STD_LOGIC;
signal ov7670_siodv : STD_LOGIC;
signal ov7670_pwdnv : STD_LOGIC;
signal ov7670_resetv : STD_LOGIC;

signal vint : std_logic;

signal cam_pclk, cam_hs, cam_vs, cam_pwdn, cam_reset : std_logic;
signal cam_d : std_logic_vector (7 downto 0);

--attribute keep : string;
--attribute keep of clk_vga : signal is "true";
--attribute keep of ov7670_pclk1 : signal is "true";
--attribute keep : string;
--attribute keep of clk_vga : signal is "true";

begin

vint <= '1' when (ov7670_vs_prev = '0' and ov7670_vs = '1') else '0';

virtual_camera : camera_colorbar
port map (
camera_io_scl => open,
camera_io_sda => open,
camera_o_vs => ov7670_vsyncv,
camera_o_hs => ov7670_hrefv,
camera_o_pclk => ov7670_pclkv,
camera_i_xclk => ov7670_xclkv,
camera_o_d => ov7670_datav,
camera_i_rst => ov7670_resetv,
--camera_i_rst => reset_dcm,
camera_i_pwdn => '0'
);

process (clk1) is
begin
  if (rising_edge (clk1)) then
    if (resend = '1') then
      owait1 <= '0';
    else
    if (owait = '1') then
    owait1 <= '1';
    else
    owait1 <= '0';
    end if;
    end if;
  end if;
end process;

oe_n <= oe_n_i;
we_n <= we_n_i;

id <= id_w when p0_w = '1' else id_r when p0_r = '1' else (others => '0');
data <= data_w when p0_w = '1' else data_r when p0_r = '1' else (others => '0');
wrc <= wrc_w when p0_w = '1' else wrc_r when p0_r = '1' else '0';

-- synchro int wr cam
process (clk1) is
begin
if (rising_edge (clk1)) then
if (resend = '1') then
  cints <= '0';
else
  cint1 <= cint;
  cints <= cint1;
end if;
end if;
end process;

-- 3 frames write ok
p0_control_crbc_write : process (clk1) is
begin
  if (rising_edge (clk1)) then
if (resend = '1') then
  wrc_w <= '0';
  ov7670_hs_prev <= '0';
  ov7670_vs_prev <= '0';
  p0_state <= a0;
  p0_w <= '0';
  wrc_w <= '0';
  id_w <= (others => '0');
  data_w <= (others => '0');
  cntr_wr1 <= (others => '0');
  w8_bw <= 0;
else
    wrc_w <= '0';
    ov7670_hs_prev <= ov7670_hs;
    ov7670_vs_prev <= ov7670_vs;
    case (p0_state) is
      when a0 =>
        if (cints = '1') then
        p0_state <= a1;
        end if;
        if (ov7670_vs = '1') then
          p0_w <= '1'; wrc_w <= '1'; id_w <= x"0058"; data_w <= (others => '0');
          p0_state <= a1;
        end if;
      when a1 =>
--        if (ov7670_vs_next /= "11") then
        p0_w <= '0';
--        if (cntr_wr1 >= 153280+160+160+160 or ov7670_vs = '1') then
        if (ov7670_vs_prev = '0' and ov7670_vs = '1') then
          cntr_wr1 <= (others => '0');
        end if;
        if (cints = '1') then -- wr when hs fe
            p0_state <= a1a;
        end if;
--        end if;
      when a1a =>
        if (busy = '0') then
          p0_w <= '1'; wrc_w <= '1'; id_w <= x"0058"; data_w <= (others => '0');
          p0_state <= aw;
        end if;
      when aw => if (busy = '0') then p0_w <= '1'; p0_state <= bw; wrc_w <= '1'; id_w <= x"0055"; data_w <= std_logic_vector (cntr_wr1 (15 downto 0)); end if;
      when bw => if (busy = '0') then p0_w <= '1'; p0_state <= cw; wrc_w <= '1'; id_w <= x"0054"; data_w <= "00000000000000" & std_logic_vector (cntr_wr1 (17 downto 16)); end if;
      when cw => if (busy = '0') then p0_w <= '1'; p0_state <= cw1; wrc_w <= '1'; id_w <= x"0052"; data_w <= std_logic_vector (c_step_w); end if;
      when cw1 => if (busy = '0') then p0_w <= '1'; p0_state <= dw; wrc_w <= '1'; id_w <= x"0058"; data_w <= x"0000"; end if;
      when dw => if (busy = '0') then p0_w <= '1'; p0_state <= ew; wrc_w <= '1'; id_w <= x"0050"; data_w <= x"0000"; end if;
      when ew =>
        p0_w <= '0';
            p0_w <= '1'; wrc_w <= '1'; id_w <= x"0058"; data_w <= (others => '0');
          if (ov7670_vs = '1') then
            p0_state <= a0;
          else
            p0_state <= a1;
          end if;
          w8_bw <= 0;
            if (cntr_wr1 = to_unsigned (c_cntr_frame, cntr_wr1'left+1)) then
              cntr_wr1 <= (others => '0');
            else
              cntr_wr1 <= cntr_wr1 + c_step_w;
            end if;
      when others => p0_state <= a0;
    end case;
end if;
  end if;
end process p0_control_crbc_write;

p1_control_crbc_read : process (clk1) is
  variable flag : boolean := false;
  variable w8 : integer range 0 to 1023 := 0;
begin
  if (rising_edge (clk1)) then
if (resend = '1') then
  wrc_r <= '0';
  vga_hsync_i_prev <= '0';
  vga_vsync_sig_prev <= '0';
  p1_state <= a0;
  ov7670_vs_next <= (others => '0');
  p0_r <= '0';
  id_r <= (others => '0');
  data_r <= (others => '0');
  cntr_rd1 <= (others => '0');
else
    wrc_r <= '0';
    vga_hsync_i_prev <= vga_hsync_i;
    vga_vsync_sig_prev <= vga_vsync_sig;
    case (p1_state) is
      when a0 =>
--        if (vint = '1') then -- XXX here
--        if (vga_hsync_i = '0') then
        p0_r <= '1'; wrc_r <= '1'; id_r <= x"0059"; data_r <= (others => '0');
--        end if;
        if (vga_vsync_sig_prev = '0' and vga_vsync_sig = '1') then -- XXX here
          ov7670_vs_next <= ov7670_vs_next (0) & '1';
          p0_r <= '1'; wrc_r <= '1'; id_r <= x"0059"; data_r <= (others => '0');
        end if;
        if (ov7670_vs_next = "11") then -- from vs cam
          if (busy = '0') then
              p1_state <= a0a;
          end if;
        end if;
      when a0a =>
--        if (cntr_rd1 >= 153280+160+160+160+160+160 or vga_vsync_sig = '0') then
--        if (cntr_rd1 >= 153280+160+160+160+160+160) then
--        if (cntr_rd1 >= 153280+160+160) then
        if (vga_vsync_sig_prev = '1' and vga_vsync_sig = '0') then
          cntr_rd1 <= (others => '0');
        end if;
        if (vga_int = '1') then
          p1_state <= ar1;
        end if;
      when ar1 =>
        if (busy = '0') then
          p1_state <= ar2;
        end if;
      when ar2 =>
--        if (vga_hsync_i = '0') then
--          p0_r <= '1'; wrc_r <= '1'; id_r <= x"0059"; data_r <= (others => '0');
          p1_state <= ar;
--        end if;
      when ar =>
        if (busy = '0') then
          p0_r <= '1'; p1_state <= br; wrc_r <= '1'; id_r <= x"0057"; data_r <= std_logic_vector (cntr_rd1 (15 downto 0));
        end if;
      when br =>
        if (busy = '0') then
          p0_r <= '1'; p1_state <= cr; wrc_r <= '1'; id_r <= x"0056"; data_r <= "00000000000000" & std_logic_vector (cntr_rd1 (17 downto 16));
        end if;
      when cr =>
        if (busy = '0') then
          p0_r <= '1'; p1_state <= dr; wrc_r <= '1'; id_r <= x"0053"; data_r <= std_logic_vector (c_step_r);
        end if;
      when dr =>
        if (busy = '0') then
          p0_r <= '1'; p1_state <= er; wrc_r <= '1'; id_r <= x"0051"; data_r <= x"0000";
        end if;
      when er =>
        if (busy = '0') then
          p1_state <= er1;
          w8 := w8 + 160;
        end if;
      when er1 =>
        p0_r <= '0';
          if (busy = '0') then -- vs cam 1
            p1_state <= a0;
          else
            w8 := 0;
            p1_state <= a0;
          end if;
          w8_br <= 0;
            if (cntr_rd1 = to_unsigned (c_cntr_frame, cntr_rd1'left+1)) then
              cntr_rd1 <= (others => '0');
            else
              cntr_rd1 <= cntr_rd1 + c_step_r;
            end if;
      when others => p1_state <= a0;
    end case;
  end if;
  end if;
end process p1_control_crbc_read;

crbc_i0 : cellular_ram_burst_controller
PORT MAP (
busy => busy,
clk => clk1,
reset => resend,
writes => wrc,
data => data,
id => id,

write_buffer_addr => wr_a1,
--write_buffer_data => wr_d1 (15 downto 8),
--write_buffer_data => wr_d1 (7 downto 0),
write_buffer_data => wr_d1,
--write_buffer_data => wr_d1 (7 downto 0),
write_buffer_clk => ov7670_pclk,
--write_buffer_clk => wren1(0),
write_buffer_we => ov7670_hs,
--write_buffer_we => latched_hs,
--write_buffer_we => wren1 (0),

clk25 => clk_vga,
read_buffer_addr => rd_a1,
--read_buffer_addr => address1,
read_buffer_data => rd_d1,
--read_buffer_clk => clk_vga,
read_buffer_clk => clk2x_2,

lb => lb_n,
ub => ub_n,
oe => oe_n_i,
we => we_n_i,
adv => adv_n,
ce => ce_n,
cre => cre,
ram_clk => clk,
--o_wait => owait,
o_wait => owait1,
a => addr,
dq => dq,
vga_int => vga_int
);

vga_r <= vga_rgb (7 downto 5);
vga_g <= vga_rgb (4 downto 2);
vga_b <= vga_rgb (1 downto 0);

siodo1_n <= not siodi1;
ov7670_siod1_tri : IOBUF port map (
O => (siodi1),
IO=> (ov7670_siod1),
I=> (siodo1),
T=> (siodo1_n)
);

inst_debounce: debounce_circuit
generic map (
PB_BITS => c_pb_bits
)
port map(
clk => clk1,
reset => '0',
input => pb,
output => resend);

ov7670_xclk1 <= clk_cam;
ov7670_xclkv <= clk_cam;
ov7670_pwdn1 <= cam_pwdn;
ov7670_pwdnv <= cam_pwdn;
ov7670_reset1 <= cam_reset;
ov7670_resetv <= cam_reset;

inst_ov7670contr1: ov7670_controller port map(
clk => clk1,
reset1 => resend,
resend => resend,
sioc => ov7670_sioc1,
siodi => siodi1,
siodo => siodo1,
conf_done => led1,
pwdn => cam_pwdn,
reset => cam_reset,
xclk_in => '0',
xclk_out => open);

--process (i_clock_ib) is
--process (clk_mc, resend) is begin
--if (resend = '1') then
--ov7670_pclk <= '0';
--ov7670_hs <= '0';
--ov7670_vs <= '0';
--ov7670_d <= (others => '0');
--elsif (falling_edge (clk_mc)) then
--elsif (falling_edge (i_clock_ib)) then
--end if;
--end process;
ov7670_d <= ov7670_data1;
ov7670_pclk <= ov7670_pclk1;
ov7670_hs <= ov7670_href1;
ov7670_vs <= ov7670_vsync1;

cam_pclk <= ov7670_pclkv when sw(0) = '1' else ov7670_pclk;
cam_d <= ov7670_datav when sw(0) = '1' else ov7670_d;
cam_hs <= ov7670_hrefv when sw(0) = '1' else ov7670_hs;
cam_vs <= ov7670_vsyncv when sw(0) = '1' else ov7670_vs;

inst_ov7670capt1: ov7670_capture port map(
pclk => cam_pclk,
reset => resend,
vsync => cam_vs,
href => cam_hs,
d => cam_d,
addr => wr_a1,
dout => wr_d1,
we => wren1,
latched_vs => latched_vs,
latched_hs => latched_hs,
int => cint
);

--ri_ard <= "0000" & rd_a1;
inst_addrgen1 : address_generator port map(
--clk25 => clk_vga,
clk25 => clk2x_2,
--reset => reset_dcm,
reset => resend,
enable => active1,
vsync => vga_vsync_sig,
address => rd_a1,
address1 => address1);

datain <= rd_d1 ;
inst_imagegen : vga_imagegenerator port map(
Data_in1  => datain,
reset => resend,
--Data_in1 => x"55aa", -- test output bmp
active_area1 => active1,
RGB_out => vga_rgb);

vga_hsync <= vga_hsync_i;
inst_vgatiming : VGA_timing_synch port map(
clk25 => clk_vga,
--rst => reset_vga_timing,
--rst => reset_dcm,
rst => resend,
Hsync => vga_hsync_i,
Vsync => vga_vsync_sig,
blank => vga_blank,
activeArea1 => active1,
int => vga_int,
fint => vga_fint,
vint => '0');

vga_vsync <= vga_vsync_sig;

vga_clock_i <= clk_vga;
vga_clock <= vga_clock_i;

reset_dcm <= not reset_dcm_n;
synchro_reset_i0 : SRLC16E
port map (
D => '1', -- insert input signal
CE => '1', -- insert Clock Enable signal (optional)
CLK => i_clock_ib2, -- insert Clock signal
A0 => '1', -- insert Address 0 signal
A1 => '1', -- insert Address 1 signal
A2 => '1', -- insert Address 2 signal
A3 => '1', -- insert Address 3 signal
Q => reset_dcm_n, -- insert output signal
Q15 => open -- insert cascadable output signal
);

--synthesis translate_off
p0_assert_1 : process (resend) is
begin
  if (resend = '1') then
    assert (
      not (CLKFX_MULTIPLY_MC = 32 and CLKFX_DIVIDE_MC = 1)
    ) report
      "forbidden mc CLKFX_MULTIPLY " & integer'image (CLKFX_MULTIPLY_MC) &
      " CLKFX_DIVIDE " & integer'image (CLKFX_DIVIDE_MC)
      severity failure;
  end if;
end process p0_assert_1;
--synthesis translate_on

BUFG_mc : BUFG
port map (
O => clk0_fb, -- Clock buffer output
I => clk0 -- Clock buffer input
);

IBUFG_global_clock1 : IBUF
port map (
O => i_clock_ib1, -- Clock buffer output
I => i_clock100 -- Clock buffer input (connect directly to top-level port)
);

DCM_SP_mc_fx_vga_dv : DCM_SP
generic map (
--CLKDV_DIVIDE => 2.0, -- 50mhz
CLKDV_DIVIDE => 4.0, -- 100mhz
CLKFX_MULTIPLY => CLKFX_MULTIPLY_MC, -- Can be any integer from 1 to 32
CLKFX_DIVIDE => CLKFX_DIVIDE_MC, -- Can be any interger from 1 to 32
CLKIN_DIVIDE_BY_2 => FALSE, -- TRUE/FALSE to enable CLKIN divide by two feature
--CLKIN_PERIOD => 20.0, -- Specify period of input clock
CLKIN_PERIOD => 10.0, -- Specify period of input clock
CLKOUT_PHASE_SHIFT => "NONE", -- Specify phase shift of "NONE", "FIXED" or "VARIABLE"
CLK_FEEDBACK => "1X", -- Specify clock feedback of "NONE", "1X" or "2X"
DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", -- "SOURCE_SYNCHRONOUS", "SYSTEM_SYNCHRONOUS" or
-- an integer from 0 to 15
DLL_FREQUENCY_MODE => "LOW", -- "HIGH" or "LOW" frequency mode for DLL
DUTY_CYCLE_CORRECTION => TRUE, -- Duty cycle correction, TRUE or FALSE
PHASE_SHIFT => 0, -- Amount of fixed phase shift from -255 to 255
STARTUP_WAIT => FALSE) -- Delay configuration DONE until DCM_SP LOCK, TRUE/FALSE
port map (
CLK0 => clk0, -- 0 degree DCM CLK ouptput
CLK180 => open, -- 180 degree DCM CLK output
CLK270 => open, -- 270 degree DCM CLK output
CLK2X => open, -- 2X DCM CLK output
CLK2X180 => open, -- 2X, 180 degree DCM CLK out
CLK90 => open, -- 90 degree DCM CLK output
CLKDV => clk_vga, -- Divided DCM CLK out (CLKDV_DIVIDE)
CLKFX => clk_mc, -- DCM CLK synthesis out (M/D)
CLKFX180 => open, -- 180 degree CLK synthesis out
LOCKED => open, -- DCM LOCK status output
PSDONE => open, -- Dynamic phase adjust done output
STATUS => open, -- 8-bit DCM status bits output
CLKFB => clk0_fb, -- DCM clock feedback
CLKIN => i_clock_ib1, -- Clock input (from IBUFG, BUFG or DCM)
PSCLK => '0', -- Dynamic phase adjust clock input
PSEN => '0', -- Dynamic phase adjust enable input
PSINCDEC => '0', -- Dynamic phase adjust increment/decrement
RST => reset_dcm -- DCM asynchronous reset input
);

BUFG_cam : BUFG
port map (
O => clk1_fb, -- Clock buffer output
I => clk1 -- Clock buffer input
);

IBUFG_global_clock2 : IBUFG
generic map (
IOSTANDARD => "DEFAULT")
port map (
O => i_clock_ib2, -- Clock buffer output
I => i_clock -- Clock buffer input (connect directly to top-level port)
);

DCM_SP_cam : DCM_SP
generic map (
--CLKDV_DIVIDE => 8.0, -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
CLKDV_DIVIDE => 4.0, -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
--CLKDV_DIVIDE => 2.0, -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
-- 7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
--CLKFX_MULTIPLY => 12, CLKFX_DIVIDE => 24, -- 50 -> 25 mhz

--CLKFX_MULTIPLY => 24, CLKFX_DIVIDE => 25, -- 25 -> 24.0 mhz
CLKFX_MULTIPLY => 12, CLKFX_DIVIDE => 25, -- 50 -> 24.0 mhz

--CLKFX_MULTIPLY => 13, CLKFX_DIVIDE => 27, -- 50 -> 24.07407407407407407400 mhz
--CLKFX_MULTIPLY => 14, CLKFX_DIVIDE => 29, -- 50 -> 24.13793103448275862050 mhz
--CLKFX_MULTIPLY => 15, CLKFX_DIVIDE => 31, -- 50 -> 24.19354838709677419350 mhz
--CLKFX_MULTIPLY => 24, CLKFX_DIVIDE => 25, -- 50 -> 48.0 mhz
--CLKFX_MULTIPLY => 12, CLKFX_DIVIDE => 24, -- 50 -> 25 mhz

--CLKFX_MULTIPLY => 6, CLKFX_DIVIDE => 25, -- 100 -> 24.0 mhz

--CLKFX_MULTIPLY => 5, CLKFX_DIVIDE => 21, -- 100 -> 23.8 mhz (sim)
--CLKFX_MULTIPLY => 13, CLKFX_DIVIDE => 27, -- 50 -> 24.07407407407407407400 mhz
--CLKFX_MULTIPLY => 14, CLKFX_DIVIDE => 29, -- 50 -> 24.13793103448275862050 mhz
--CLKFX_MULTIPLY => 15, CLKFX_DIVIDE => 31, -- 50 -> 24.19354838709677419350 mhz
--CLKFX_MULTIPLY => 24, CLKFX_DIVIDE => 25, -- 50 -> 48.0 mhz
--CLKIN_PERIOD => 20.0, CLKFX_MULTIPLY => 13, CLKFX_DIVIDE => 28 (23.21428571428571428550)
--CLKFX_MULTIPLY => 13, CLKFX_DIVIDE => 28,
CLKIN_DIVIDE_BY_2 => FALSE, -- TRUE/FALSE to enable CLKIN divide by two feature
CLKIN_PERIOD => 20.0, -- Specify period of input clock
--CLKIN_PERIOD => 10.0, -- Specify period of input clock
CLKOUT_PHASE_SHIFT => "NONE", -- Specify phase shift of "NONE", "FIXED" or "VARIABLE"
CLK_FEEDBACK => "1X", -- Specify clock feedback of "NONE", "1X" or "2X"
DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", -- "SOURCE_SYNCHRONOUS", "SYSTEM_SYNCHRONOUS" or
-- an integer from 0 to 15
DLL_FREQUENCY_MODE => "LOW", -- "HIGH" or "LOW" frequency mode for DLL
DUTY_CYCLE_CORRECTION => TRUE, -- Duty cycle correction, TRUE or FALSE
PHASE_SHIFT => 0, -- Amount of fixed phase shift from -255 to 255
STARTUP_WAIT => FALSE) -- Delay configuration DONE until DCM_SP LOCK, TRUE/FALSE
port map (
CLK0 => clk1, -- 0 degree DCM CLK ouptput
CLK180 => open, -- 180 degree DCM CLK output
CLK270 => open, -- 270 degree DCM CLK output
CLK2X => open, -- 2X DCM CLK output
CLK2X180 => open, -- 2X, 180 degree DCM CLK out
CLK90 => open, -- 90 degree DCM CLK output
CLKDV => clk2x_2, -- Divided DCM CLK out (CLKDV_DIVIDE)
CLKFX => clk_cam, -- DCM CLK synthesis out (M/D)
CLKFX180 => open, -- 180 degree CLK synthesis out
LOCKED => open, -- DCM LOCK status output
PSDONE => open, -- Dynamic phase adjust done output
STATUS => open, -- 8-bit DCM status bits output
CLKFB => clk1_fb, -- DCM clock feedback
CLKIN => i_clock_ib2, -- Clock input (from IBUFG, BUFG or DCM)
PSCLK => '0', -- Dynamic phase adjust clock input
PSEN => '0', -- Dynamic phase adjust enable input
PSINCDEC => '0', -- Dynamic phase adjust increment/decrement
RST => reset_dcm -- DCM asynchronous reset input
);

end Structural;
