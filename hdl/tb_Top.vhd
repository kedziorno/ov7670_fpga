--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   13:21:08 07/23/2022
-- Design Name:   
-- Module Name:   /home/user/workspace/vhdl_projects/camera2/ov7670_vga_Nexys2/tb_Top.vhd
-- Project Name:  ov7670_vga_Nexys2
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: Top
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;

--use work.micron_mem_parameters.all;
--use work.p_constants.all;
use work.p_camera_colorbar.all;

ENTITY tb_top IS
END tb_top;

ARCHITECTURE behavior OF tb_top IS 

--component camera_vga is
--port (
--sio_d    : inout std_logic;
--sio_c    : in    std_logic;
--vsync    : out   std_logic;
--href     : out   std_logic;
--pclk     : out   std_logic;
--d0       : out   std_logic;
--d1       : out   std_logic;
--d2       : out   std_logic;
--d3       : out   std_logic;
--d4       : out   std_logic;
--d5       : out   std_logic;
--d6       : out   std_logic;
--d7       : out   std_logic;
--xclk     : in    std_logic;
--reset_n  : in    std_logic;
--pwdn     : in    std_logic;
---- virtual sensor array (as SDCard with RAW images RGB565)
--sd_cs    : out   std_logic;
--sd_sclk  : out   std_logic;
--sd_mosi  : out   std_logic;
--sd_miso  : in    std_logic;
--clk100   : in    std_logic;
---- RAM module
--Addr     : out   std_logic_vector(c_addr_bits - 1 downto 0);
--Adv_n    : out   std_logic;
--Ce_n     : out   std_logic;
--Clk      : out   std_logic;
--Cre      : out   std_logic;
--Dq       : inout std_logic_vector(c_data_bits - 1 downto 0);
--Lb_n     : out   std_logic;
--Oe_n     : out   std_logic;
--oWait    : in    std_logic; -- Wait is a keyword in HDL
--Ub_n     : out   std_logic;
--We_n     : out   std_logic
--);
--end component camera_vga;

component camera_colorbar is
generic (
constant c_source : t_source := t_colorbar
--constant c_source : t_source := t_frames
--constant c_source : t_source := t_lines
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

component sdcard_emulator is
port (
sd_cs    : in   std_logic;
sd_clk   : in   std_logic;
sd_mosi  : in   std_logic;
sd_miso  : out  std_logic
);
end component sdcard_emulator;
signal sd_cs_1    : std_logic;
signal sd_cs_2    : std_logic;
signal sd_cs_3    : std_logic;
signal sd_cs_4    : std_logic;
signal sd_sclk_1  : std_logic;
signal sd_sclk_2  : std_logic;
signal sd_sclk_3  : std_logic;
signal sd_sclk_4  : std_logic;
signal sd_mosi_1  : std_logic;
signal sd_mosi_2  : std_logic;
signal sd_mosi_3  : std_logic;
signal sd_mosi_4  : std_logic;
signal sd_miso_1  : std_logic;
signal sd_miso_2  : std_logic;
signal sd_miso_3  : std_logic;
signal sd_miso_4  : std_logic;

signal sdcard_clock   : std_logic := '0';
signal mem_done : std_logic := '0';

component mt45w8mw16bgx is
port (
Addr  : in    std_logic_vector(23 - 1 downto 0);
Adv_n : in    std_logic;
Ce_n  : in    std_logic;
Clk   : in    std_logic;
Cre   : in    std_logic;
Dq    : inout std_logic_vector(16 - 1 downto 0);
Lb_n  : in    std_logic;
Oe_n  : in    std_logic;
oWait : out   std_logic; -- Wait is a keyword in HDL
Ub_n  : in    std_logic;
We_n  : in    std_logic
);
end component mt45w8mw16bgx;
signal mt45w8mw16bgx_Addr_1  : std_logic_vector(23 - 1 downto 0);
signal mt45w8mw16bgx_Addr_2  : std_logic_vector(23 - 1 downto 0);
signal mt45w8mw16bgx_Addr_3  : std_logic_vector(23 - 1 downto 0);
signal mt45w8mw16bgx_Addr_4  : std_logic_vector(23 - 1 downto 0);
signal mt45w8mw16bgx_Adv_n_1 : std_logic;
signal mt45w8mw16bgx_Adv_n_2 : std_logic;
signal mt45w8mw16bgx_Adv_n_3 : std_logic;
signal mt45w8mw16bgx_Adv_n_4 : std_logic;
signal mt45w8mw16bgx_Ce_n_1  : std_logic;
signal mt45w8mw16bgx_Ce_n_2  : std_logic;
signal mt45w8mw16bgx_Ce_n_3  : std_logic;
signal mt45w8mw16bgx_Ce_n_4  : std_logic;
signal mt45w8mw16bgx_Clk_1   : std_logic;
signal mt45w8mw16bgx_Clk_2   : std_logic;
signal mt45w8mw16bgx_Clk_3   : std_logic;
signal mt45w8mw16bgx_Clk_4   : std_logic;
signal mt45w8mw16bgx_Cre_1   : std_logic;
signal mt45w8mw16bgx_Cre_2   : std_logic;
signal mt45w8mw16bgx_Cre_3   : std_logic;
signal mt45w8mw16bgx_Cre_4   : std_logic;
signal mt45w8mw16bgx_Dq_1    : std_logic_vector(16 - 1 downto 0);
signal mt45w8mw16bgx_Dq_2    : std_logic_vector(16 - 1 downto 0);
signal mt45w8mw16bgx_Dq_3    : std_logic_vector(16 - 1 downto 0);
signal mt45w8mw16bgx_Dq_4    : std_logic_vector(16 - 1 downto 0);
signal mt45w8mw16bgx_Lb_n_1  : std_logic;
signal mt45w8mw16bgx_Lb_n_2  : std_logic;
signal mt45w8mw16bgx_Lb_n_3  : std_logic;
signal mt45w8mw16bgx_Lb_n_4  : std_logic;
signal mt45w8mw16bgx_Oe_n_1  : std_logic;
signal mt45w8mw16bgx_Oe_n_2  : std_logic;
signal mt45w8mw16bgx_Oe_n_3  : std_logic;
signal mt45w8mw16bgx_Oe_n_4  : std_logic;
signal mt45w8mw16bgx_oWait_1 : std_logic; -- Wait is a keyword in HDL
signal mt45w8mw16bgx_oWait_2 : std_logic; -- Wait is a keyword in HDL
signal mt45w8mw16bgx_oWait_3 : std_logic; -- Wait is a keyword in HDL
signal mt45w8mw16bgx_oWait_4 : std_logic; -- Wait is a keyword in HDL
signal mt45w8mw16bgx_Ub_n_1  : std_logic;
signal mt45w8mw16bgx_Ub_n_2  : std_logic;
signal mt45w8mw16bgx_Ub_n_3  : std_logic;
signal mt45w8mw16bgx_Ub_n_4  : std_logic;
signal mt45w8mw16bgx_We_n_1  : std_logic;
signal mt45w8mw16bgx_We_n_2  : std_logic;
signal mt45w8mw16bgx_We_n_3  : std_logic;
signal mt45w8mw16bgx_We_n_4  : std_logic;

signal vga_blank : std_logic;
signal vga_clock : std_logic;
signal video_data_1                  : std_logic_vector(16 - 1 downto 0);
signal video_data_2                  : std_logic_vector(16 - 1 downto 0);
signal video_data_3                  : std_logic_vector(16 - 1 downto 0);
signal video_data_4                  : std_logic_vector(16 - 1 downto 0);
signal video_blank_1                 : std_logic := '0';
signal video_blank_2                 : std_logic := '0';
signal video_blank_3                 : std_logic := '0';
signal video_blank_4                 : std_logic := '0';
signal video_hsync_1                 : std_logic := '0';
signal video_hsync_2                 : std_logic := '0';
signal video_hsync_3                 : std_logic := '0';
signal video_hsync_4                 : std_logic := '0';
signal video_vsync_1                 : std_logic := '0';
signal video_vsync_2                 : std_logic := '0';
signal video_vsync_3                 : std_logic := '0';
signal video_vsync_4                 : std_logic := '0';

component top is
generic (
constant c_pb_bits : integer := 1 -- XXX set debounce time
);
Port (
i_clock	: in STD_LOGIC; -- Crystal Oscilator 50MHz  --B8
--clkcam	: in STD_LOGIC; -- Crystal Oscilator 23.9616 MHz  --U9
pb		: in STD_LOGIC; -- Push Button --B18
sw : in std_logic_vector (7 downto 0);
--sw		: in STD_LOGIC; -- Push Button --G18
led1 : out STD_LOGIC; -- Indicates configuration has been done --J14
ov7670_pclk1: in  STD_LOGIC; -- Pmod JB8 --R16
ov7670_xclk1: out STD_LOGIC; -- Pmod JB2 --R18
ov7670_vsync1: in  STD_LOGIC; -- Pmod JB9 --T18
ov7670_href1: in  STD_LOGIC; -- Pmod JB3 --R15
ov7670_data1: in  STD_LOGIC_vector(7 downto 0);
ov7670_sioc1: out STD_LOGIC; -- Pmod JB10 --J12
ov7670_siod1: inout STD_LOGIC; -- Pmod JB4 --H16
ov7670_pwdn1: out STD_LOGIC; -- Pmod JA1 --L15
ov7670_reset1: out STD_LOGIC; -- Pmod JA7 --K13
--memory module
Dq : inout std_logic_vector (16 - 1 downto 0);
Addr : out std_logic_vector (23 - 1 downto 0);
Adv_n : out std_logic;
Ce_n : out std_logic;
Clk : out std_logic;
Cre : out std_logic;
Lb_n : out std_logic;
Oe_n : out std_logic;
Ub_n : out std_logic;
We_n : out std_logic;
oWait : in std_logic;
vga_clock : out STD_LOGIC;
vga_blank : out STD_LOGIC;
vga_hsync : out STD_LOGIC; --T4
vga_vsync : out STD_LOGIC; --U3
vga_r	: out STD_LOGIC_VECTOR(2 downto 0);
vga_g	: out STD_LOGIC_VECTOR(2 downto 0);
vga_b	: out STD_LOGIC_VECTOR(1 downto 0)
);
end component top;

signal vga_r	: STD_LOGIC_VECTOR(2 downto 0);
signal vga_g	: STD_LOGIC_VECTOR(2 downto 0);
signal vga_b	: STD_LOGIC_VECTOR(1 downto 0);

component vga_bmp_sink is
generic (
filename : string
);
port (
clk_i        : in    std_logic;
rst_i        : in    std_logic;
active_vid_i : in    std_logic;
h_sync_i     : in    std_logic;
v_sync_i     : in    std_logic;
dat_i        : in    std_logic_vector(23 downto 0)
);
end component vga_bmp_sink;

--Inputs
signal clk50 : std_logic := '0';
signal clk100 : std_logic := '0';
signal clkcam : std_logic := '0';
signal pb : std_logic := '0';
signal ov7670_pclk1: std_logic := '0';
signal ov7670_vsync1: std_logic := '0';
signal ov7670_href1: std_logic := '0';
signal ov7670_data1: std_logic_vector(7 downto 0) := (others => '0');

--BiDirs
signal ov7670_siod1: std_logic;

--Outputs
signal led1: std_logic;
signal ov7670_xclk1: std_logic;
signal ov7670_sioc1: std_logic;
signal ov7670_pwdn1: std_logic;
signal ov7670_reset1: std_logic;
signal vga_hsync : std_logic;
signal vga_vsync : std_logic;
signal vga_rgb : std_logic_vector(7 downto 0);

-- Clock period definitions
constant clk50_period : time := 20 ns; -- 50mhz
constant clk100_period : time := 10 ns; -- 100mhz
--constant clk50_period : time := 41.667 ns; -- 24mhz
--constant sdcard_clock_period : time := 10 ns;
constant camera_i_xclk_period : time := 41.733 ns; -- ~24mhz
--constant camera_i_xclk_period : time := 21 ns; -- to camera ~50mhz

COMPONENT camera
GENERIC(
constant CLOCK_PERIOD : integer := 42; -- 21/42/100 ns - 10/24/48 MHZ - Min/Typ/Max Unit
constant RAW_RGB : integer := 0; -- 0 - RAW / 1 - RGB
constant ZERO : integer := 0
);
PORT(
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
END COMPONENT;

--Inputs
signal camera_i_xclk1,camera_i_xclk2,camera_i_xclk3,camera_i_xclk4 : std_logic := '0';
signal camera_i_rst1,camera_i_rst2,camera_i_rst3,camera_i_rst4 : std_logic := '0';
signal camera_i_pwdn1,camera_i_pwdn2,camera_i_pwdn3,camera_i_pwdn4 : std_logic := '0';
--BiDirs
signal camera_io_scl1,camera_io_scl2,camera_io_scl3,camera_io_scl4 : std_logic := 'Z';
signal camera_io_sda1,camera_io_sda2,camera_io_sda3,camera_io_sda4 : std_logic := 'Z';
--Outputs
signal camera_o_vs1,camera_o_vs2,camera_o_vs3,camera_o_vs4 : std_logic;
signal camera_o_hs1,camera_o_hs2,camera_o_hs3,camera_o_hs4 : std_logic;
signal camera_o_pclk1,camera_o_pclk2,camera_o_pclk3,camera_o_pclk4 : std_logic;
signal camera_o_d1,camera_o_d2,camera_o_d3,camera_o_d4 : std_logic_vector(7 downto 0);

signal xclk : std_logic;
signal sw : std_logic_vector (7 downto 0);

signal anode : std_logic_vector (3 downto 0);

--camera
signal reset_n : std_logic;
signal clkcambuf : std_logic;
signal sioc,siod : std_logic;
signal ov7670_pclkbuf_mux_1,ov7670_vsync_mux_1,ov7670_href_mux_1 : std_logic;
signal ov7670_pclkbuf_mux_2,ov7670_vsync_mux_2,ov7670_href_mux_2 : std_logic;
signal ov7670_pclkbuf_mux_3,ov7670_vsync_mux_3,ov7670_href_mux_3 : std_logic;
signal ov7670_pclkbuf_mux_4,ov7670_vsync_mux_4,ov7670_href_mux_4 : std_logic;
signal ov7670_data_mux_1 : std_logic_vector(7 downto 0);
signal ov7670_data_mux_2 : std_logic_vector(7 downto 0);
signal ov7670_data_mux_3 : std_logic_vector(7 downto 0);
signal ov7670_data_mux_4 : std_logic_vector(7 downto 0);

signal Addr : std_logic_vector(22 downto 0) := (others => '0');
signal Adv_n : std_logic := '0';
signal Ce_n : std_logic := '0';
signal Clk : std_logic := '0';
signal Cre : std_logic := '0';
signal Lb_n : std_logic := '0';
signal Oe_n : std_logic := '0';
signal Ub_n : std_logic := '0';
signal We_n : std_logic := '0';
signal Dq : std_logic_vector(15 downto 0);
signal oWait : std_logic := '0';

signal test_isimgui_32bit : real;
signal vga_blank_n : std_logic := '1';

signal tb_reset : std_logic := '1';
signal tb_reset_bmp : std_logic := '1';

BEGIN
--synthesis translate_off

p_isim_cmd_ping : process is
begin
  report "ping on isim cmd";
  wait for 1 ms;
end process p_isim_cmd_ping;

reset_n <= '1', '0' after 475 ns;
vga_blank_n <= '0', vga_blank after 475 ns;

--tb_reset_bmp <= '1', '0' after 6.3353 us;
tb_reset_bmp <= '1', '0' after 5 us;
vga_bmp_i1 : component vga_bmp_sink
generic map (
filename => "vga_memory_module_1.bmp"
)
port map (
clk_i        => vga_clock,
rst_i        => tb_reset_bmp,
dat_i        =>
vga_r &"00000"&
vga_g &"00000" &
vga_b &"000000",
active_vid_i => not vga_blank,
h_sync_i     => vga_hsync,
v_sync_i     => vga_vsync
);

--camera_vga_i1 : camera_vga
--port map (
--sio_d    => sioc,
--sio_c    => siod,
--vsync    => ov7670_vsync_mux_1,
--href     => ov7670_href_mux_1,
--pclk     => ov7670_pclkbuf_mux_1,
--d0       => ov7670_data_mux_1 (0),
--d1       => ov7670_data_mux_1 (1),
--d2       => ov7670_data_mux_1 (2),
--d3       => ov7670_data_mux_1 (3),
--d4       => ov7670_data_mux_1 (4),
--d5       => ov7670_data_mux_1 (5),
--d6       => ov7670_data_mux_1 (6),
--d7       => ov7670_data_mux_1 (7),
--xclk     => xclk,
--reset_n  => reset_n,
--pwdn     => '0',
---- virtual sensor array (as SDCard with RAW images RGB565)
--sd_cs    => sd_cs_1,
--sd_sclk  => sd_sclk_1,
--sd_mosi  => sd_mosi_1,
--sd_miso  => sd_miso_1,
--clk100   => sdcard_clock,
---- RAM module
--Addr     => mt45w8mw16bgx_Addr_1,
--Adv_n    => mt45w8mw16bgx_Adv_n_1,
--Ce_n     => mt45w8mw16bgx_Ce_n_1,
--Clk      => mt45w8mw16bgx_Clk_1,
--Cre      => mt45w8mw16bgx_Cre_1,
--Dq       => mt45w8mw16bgx_Dq_1,
--Lb_n     => mt45w8mw16bgx_Lb_n_1,
--Oe_n     => mt45w8mw16bgx_Oe_n_1,
--oWait    => mt45w8mw16bgx_oWait_1,
--Ub_n     => mt45w8mw16bgx_Ub_n_1,
--We_n     => mt45w8mw16bgx_We_n_1
--);

camera_cb_inst : camera_colorbar
port map (
camera_io_scl => open,
camera_io_sda => open,
camera_o_vs => ov7670_vsync_mux_1,
camera_o_hs => ov7670_href_mux_1,
camera_o_pclk => ov7670_pclk1,
camera_i_xclk => ov7670_xclk1,
camera_o_d => ov7670_data_mux_1,
camera_i_rst => ov7670_reset1 xnor tb_reset,
camera_i_pwdn => '0'
);

--ram_camera : component mt45w8mw16bgx
--port map (
--Dq    => mt45w8mw16bgx_Dq_1,
--oWait => mt45w8mw16bgx_oWait_1, -- Wait is a keyword in HDL
--Clk   => mt45w8mw16bgx_Clk_1,
--Addr  => mt45w8mw16bgx_Addr_1,
--Ce_n  => mt45w8mw16bgx_Ce_n_1,
--We_n  => mt45w8mw16bgx_We_n_1,
--Adv_n => mt45w8mw16bgx_Adv_n_1,
--Oe_n  => mt45w8mw16bgx_Oe_n_1,
--Cre   => mt45w8mw16bgx_Cre_1,
--Ub_n  => mt45w8mw16bgx_Ub_n_1,
--Lb_n  => mt45w8mw16bgx_Lb_n_1
--);

ram_board : component mt45w8mw16bgx
port map (
Dq    => mt45w8mw16bgx_Dq_2,
oWait => mt45w8mw16bgx_oWait_2, -- Wait is a keyword in HDL
Clk   => mt45w8mw16bgx_Clk_2,
Addr  => mt45w8mw16bgx_Addr_2,
Ce_n  => mt45w8mw16bgx_Ce_n_2,
We_n  => mt45w8mw16bgx_We_n_2,
Adv_n => mt45w8mw16bgx_Adv_n_2,
Oe_n  => mt45w8mw16bgx_Oe_n_2,
Cre   => mt45w8mw16bgx_Cre_2,
Ub_n  => mt45w8mw16bgx_Ub_n_2,
Lb_n  => mt45w8mw16bgx_Lb_n_2
);

--sdcard_i1 : sdcard_emulator
--port map (
--sd_cs    => sd_cs_1,
--sd_clk   => sd_sclk_1,
--sd_mosi  => sd_mosi_1,
--sd_miso  => sd_miso_1
--);

--camera_i_xclk => camera_i_xclk2,
--camera_o_d => camera_o_d2,
--camera_i_rst => camera_i_rst2,
--camera_i_pwdn => camera_i_pwdn2
--);
--
--cam3 : camera PORT MAP (
--camera_io_scl => camera_io_scl3,
--camera_io_sda => camera_io_sda3,
--camera_o_vs => camera_o_vs3,
--camera_o_hs => camera_o_hs3,
--camera_o_pclk => camera_o_pclk3,
--camera_i_xclk => camera_i_xclk3,
--camera_o_d => camera_o_d3,
--camera_i_rst => camera_i_rst3,
--camera_i_pwdn => camera_i_pwdn3
--);
--
--cam4 : camera PORT MAP (
--camera_io_scl => camera_io_scl4,
--camera_io_sda => camera_io_sda4,
--camera_o_vs => camera_o_vs4,
--camera_o_hs => camera_o_hs4,
--camera_o_pclk => camera_o_pclk4,
--camera_i_xclk => camera_i_xclk4,
--camera_o_d => camera_o_d4,
--camera_i_rst => camera_i_rst4,
--camera_i_pwdn => camera_i_pwdn4
--);

camera_i_xclk1 <= ov7670_xclk1; -- cam <- dev
--ov7670_pclk1 <= ov7670_pclkbuf_mux_1; -- dev <- cam
--ov7670_pclk1 <= ov7670_pclkbuf_mux_1; -- dev <- cam
ov7670_data1 <= ov7670_data_mux_1;
ov7670_vsync1 <= ov7670_vsync_mux_1;
ov7670_href1 <= ov7670_href_mux_1;

-- Instantiate the Unit Under Test (UUT)
top_uut : top PORT MAP (
i_clock => clk100,
--clkcam => clkcam,
sw => sw,
pb => pb,
--sw => sw,
led1 => led1,
ov7670_pclk1 => ov7670_pclk1,
ov7670_xclk1 => ov7670_xclk1,
ov7670_vsync1 => ov7670_vsync1,
ov7670_href1 => ov7670_href1,
ov7670_data1 => ov7670_data1,
ov7670_sioc1 => ov7670_sioc1,
ov7670_siod1 => ov7670_siod1,
ov7670_pwdn1 => ov7670_pwdn1,
ov7670_reset1 => ov7670_reset1,
Dq => mt45w8mw16bgx_Dq_2,
Addr => mt45w8mw16bgx_Addr_2,
Adv_n => mt45w8mw16bgx_Adv_n_2,
Ce_n => mt45w8mw16bgx_Ce_n_2,
Clk => mt45w8mw16bgx_Clk_2,
Cre => mt45w8mw16bgx_Cre_2,
Lb_n => mt45w8mw16bgx_Lb_n_2,
Oe_n => mt45w8mw16bgx_Oe_n_2,
Ub_n => mt45w8mw16bgx_Ub_n_2,
We_n => mt45w8mw16bgx_We_n_2,
oWait => mt45w8mw16bgx_oWait_2,
vga_blank => vga_blank,
vga_clock => vga_clock,
vga_hsync => vga_hsync,
vga_vsync => vga_vsync,
vga_r	=> vga_r,
vga_g	=> vga_g,
vga_b	=> vga_b
);
--clkcam <= xclk;

-- Clock process definitions
clk50_process :process
begin
clk50 <= '0';
wait for clk50_period/2;
clk50 <= '1';
wait for clk50_period/2;
end process;

clk100_process :process
begin
clk100 <= '0';
wait for clk100_period/2;
clk100 <= '1';
wait for clk100_period/2;
end process;

--sdcard_clock_process :process
--begin
--sdcard_clock <= '0';
--wait for sdcard_clock_period/2;
--sdcard_clock <= '1';
--wait for sdcard_clock_period/2;
--end process;

--camera_i_xclkp :process
--begin
--xclk <= '0';
--wait for camera_i_xclk_period/2;
--xclk <= '1';
--wait for camera_i_xclk_period/2;
--end process;

load_memory_from_files : process is
--variable start_addr : integer;
--variable file_name  : string (1 to 27+c_hex_rom_files_name_length);
begin
---- XXX RC when load
--mem_done <= '0';
--wait for 90 ns;
--for i in 1 to c_hex_rom_files_count - 1 loop
wait for 100 ns;
--start_addr := c_camera_frame_length * (i - 1);
--if (i < 10) then
--file_name := c_hex_rom_files_name & "0" & integer'image(i) & "." & c_hex_rom_files_ext;
--else
--file_name := c_hex_rom_files_name & integer'image(i) & "." & c_hex_rom_files_ext;
--end if;
--report "readandconvertrom " & file_name;
----readandconvertrom(file_name, start_addr);
--wait for 100 ns;
--end loop;
--wait for 100 ns;
----readandconvertrom("hex_memory_file_frame01.hex", 0, c1);
mem_done <= '1';
report "images loaded";
wait;
end process load_memory_from_files;

-- Stimulus process
stim_proc : process
begin
sw <= (others => '0');
wait until mem_done = '1';
-- hold reset state for 100 ns.
--i_reset <= '1';
camera_i_rst1 <= '0';
camera_i_rst2 <= '0';
camera_i_rst3 <= '0';
camera_i_rst4 <= '0';
--sw <= "00000000"; -- x00 frames
--sw <= "00000001"; -- x01 colorbar
pb <= '1';
wait for clk50_period*15; -- min to reset
--i_reset <= '0';
camera_i_rst1 <= '1';
camera_i_rst2 <= '1';
camera_i_rst3 <= '1';
camera_i_rst4 <= '1';
pb <= '0';
wait for 300 ns;
tb_reset <= '0';
wait for clk50_period*15;
tb_reset <= '1';
wait for clk50_period*10;
wait for 35 ms;
sw (1) <= '1';
wait for clk50_period;
sw (1) <= '0';
-- insert stimulus here
wait;
end process;

--synthesis translate_on
END;
