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
USE WORK.st7735r_p_package.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;

ENTITY tb_Top IS
END tb_Top;

ARCHITECTURE behavior OF tb_Top IS 

component Top is
Generic (
G_PB_BITS : integer := 6;
G_WAIT1 : integer := 7; -- wait for reset dcm and cameras
G_FE_WAIT_BITS : integer := 9; -- sccb wait for cameras
SPI_SPEED_MODE : integer := C_CLOCK_COUNTER_MF
);
Port (
clk50	: in STD_LOGIC; -- Crystal Oscilator 50MHz  --B8
clkcam	: in STD_LOGIC; -- Crystal Oscilator 23.9616 MHz  --U9
pb		: in STD_LOGIC; -- Push Button --B18
sw		: in STD_LOGIC; -- Push Button --G18
led1 : out STD_LOGIC; -- Indicates configuration has been done --J14
led2 : out STD_LOGIC; -- Indicates configuration has been done --J14
led3 : out STD_LOGIC; -- Indicates configuration has been done --J14
led4 : out STD_LOGIC; -- Indicates configuration has been done --J14
anode : out std_logic_vector(3 downto 0);
ov7670_reset1,ov7670_reset2,ov7670_reset3,ov7670_reset4  : out  STD_LOGIC;
ov7670_pclk1,ov7670_pclk2,ov7670_pclk3,ov7670_pclk4  : in  STD_LOGIC; -- Pmod JB8 --R16
ov7670_xclk1,ov7670_xclk2,ov7670_xclk3,ov7670_xclk4  : out STD_LOGIC; -- Pmod JB2 --R18
ov7670_vsync1,ov7670_vsync2,ov7670_vsync3,ov7670_vsync4 : in  STD_LOGIC; -- Pmod JB9 --T18
ov7670_href1,ov7670_href2,ov7670_href3,ov7670_href4  : in  STD_LOGIC; -- Pmod JB3 --R15
ov7670_data1,ov7670_data2,ov7670_data3,ov7670_data4  : in  STD_LOGIC_vector(7 downto 0);
ov7670_sioc1,ov7670_sioc2,ov7670_sioc3,ov7670_sioc4  : out STD_LOGIC; -- Pmod JB10 --J12
ov7670_siod1,ov7670_siod2,ov7670_siod3,ov7670_siod4  : inout STD_LOGIC; -- Pmod JB4 --H16
vga_hsync : out STD_LOGIC; --T4
vga_vsync : out STD_LOGIC; --U3
vga_rgb	: out STD_LOGIC_VECTOR(7 downto 0);
o_cs : out STD_LOGIC;
o_do : out STD_LOGIC;
o_ck : out STD_LOGIC;
o_reset : out STD_LOGIC;
o_rs : out STD_LOGIC
);
end component Top;

--Inputs
signal clkcam : std_logic := '0';
signal pb : std_logic := '0';
signal ov7670_pclk1,ov7670_pclk2,ov7670_pclk3,ov7670_pclk4 : std_logic := '0';
signal ov7670_vsync1,ov7670_vsync2,ov7670_vsync3,ov7670_vsync4 : std_logic := '0';
signal ov7670_href1,ov7670_href2,ov7670_href3,ov7670_href4 : std_logic := '0';
signal ov7670_data1,ov7670_data2,ov7670_data3,ov7670_data4 : std_logic_vector(7 downto 0) := (others => '0');

--BiDirs
signal ov7670_siod1,ov7670_siod2,ov7670_siod3,ov7670_siod4 : std_logic;

--Outputs
signal led1,led2,led3,led4 : std_logic;
signal ov7670_xclk1,ov7670_xclk2,ov7670_xclk3,ov7670_xclk4 : std_logic;
signal ov7670_sioc1,ov7670_sioc2,ov7670_sioc3,ov7670_sioc4 : std_logic;
signal ov7670_pwdn1,ov7670_pwdn2,ov7670_pwdn3,ov7670_pwdn4 : std_logic;
signal ov7670_reset1,ov7670_reset2,ov7670_reset3,ov7670_reset4 : std_logic;
signal vga_hsync : std_logic;
signal vga_vsync : std_logic;
signal vga_rgb : std_logic_vector(7 downto 0);
signal o_cs : STD_LOGIC;
signal o_do : STD_LOGIC;
signal o_ck : STD_LOGIC;
signal o_reset : STD_LOGIC;
signal o_rs : STD_LOGIC;

-- Constants and Clock period definitions
constant clk50_period : time := 20 ns; -- 50mhz
constant clkcam_period : time := 10 ns; -- 100mhz
constant vga_25dot175 : time := 39.7219464 ns; -- 25.175mhz
constant camera_i_xclk_period1 : time := 41.733 ns; -- 23.9616mhz
constant camera_i_xclk_period2 : time := 41.667 ns; -- 24mhz
constant camera_i_xclk_period3 : time := 1000.000 ns; -- 1mhz
constant camera_i_xclk_period4 : time := 667.297 ns; -- 1.498583mhz
constant USE_OUT_CLOCK : std_logic := '1'; -- XXX use outcoming signal clock to camera
signal camera_i_xclk : std_logic := '0';
constant camera_i_xclk_period : time := camera_i_xclk_period4;

COMPONENT camera_qqvga
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

signal anode : std_logic_vector (3 downto 0);

BEGIN

cam1 : camera_qqvga PORT MAP (
camera_io_scl => camera_io_scl1,
camera_io_sda => camera_io_sda1,
camera_o_vs => camera_o_vs1,
camera_o_hs => camera_o_hs1,
camera_o_pclk => camera_o_pclk1,
camera_i_xclk => camera_i_xclk1,
camera_o_d => camera_o_d1,
camera_i_rst => camera_i_rst1,
camera_i_pwdn => camera_i_pwdn1
);

cam2 : camera_qqvga PORT MAP (
camera_io_scl => camera_io_scl2,
camera_io_sda => camera_io_sda2,
camera_o_vs => camera_o_vs2,
camera_o_hs => camera_o_hs2,
camera_o_pclk => camera_o_pclk2,
camera_i_xclk => camera_i_xclk2,
camera_o_d => camera_o_d2,
camera_i_rst => camera_i_rst2,
camera_i_pwdn => camera_i_pwdn2
);

cam3 : camera_qqvga PORT MAP (
camera_io_scl => camera_io_scl3,
camera_io_sda => camera_io_sda3,
camera_o_vs => camera_o_vs3,
camera_o_hs => camera_o_hs3,
camera_o_pclk => camera_o_pclk3,
camera_i_xclk => camera_i_xclk3,
camera_o_d => camera_o_d3,
camera_i_rst => camera_i_rst3,
camera_i_pwdn => camera_i_pwdn3
);

cam4 : camera_qqvga PORT MAP (
camera_io_scl => camera_io_scl4,
camera_io_sda => camera_io_sda4,
camera_o_vs => camera_o_vs4,
camera_o_hs => camera_o_hs4,
camera_o_pclk => camera_o_pclk4,
camera_i_xclk => camera_i_xclk4,
camera_o_d => camera_o_d4,
camera_i_rst => camera_i_rst4,
camera_i_pwdn => camera_i_pwdn4
);

camera_i_xclk1 <= ov7670_xclk1 when USE_OUT_CLOCK = '0' else camera_i_xclk; -- cam <- dev
ov7670_pclk1 <= camera_o_pclk1; -- dev <- cam
ov7670_data1 <= camera_o_d1;
ov7670_vsync1 <= camera_o_vs1;
ov7670_href1 <= camera_o_hs1;

camera_i_xclk2 <= ov7670_xclk2 when USE_OUT_CLOCK = '0' else camera_i_xclk; -- cam <- dev
ov7670_pclk2 <= camera_o_pclk2; -- dev <- cam
ov7670_data2 <= camera_o_d2;
ov7670_vsync2 <= camera_o_vs2;
ov7670_href2 <= camera_o_hs2;

camera_i_xclk3 <= ov7670_xclk3 when USE_OUT_CLOCK = '0' else camera_i_xclk; -- cam <- dev
ov7670_pclk3 <= camera_o_pclk3; -- dev <- cam
ov7670_data3 <= camera_o_d3;
ov7670_vsync3 <= camera_o_vs3;
ov7670_href3 <= camera_o_hs3;

camera_i_xclk4 <= ov7670_xclk4 when USE_OUT_CLOCK = '0' else camera_i_xclk; -- cam <- dev
ov7670_pclk4 <= camera_o_pclk4; -- dev <- cam
ov7670_data4 <= camera_o_d4;
ov7670_vsync4 <= camera_o_vs4;
ov7670_href4 <= camera_o_hs4;

-- Instantiate the Unit Under Test (UUT)
uut: Top PORT MAP (
clk50 => '0',
clkcam => clkcam,
pb => pb,
sw => '0',
led1 => led1,
led2 => led2,
led3 => led3,
led4 => led4,
anode => anode,
ov7670_reset1 => camera_i_rst1,
ov7670_reset2 => camera_i_rst2,
ov7670_reset3 => camera_i_rst3,
ov7670_reset4 => camera_i_rst4,
ov7670_pclk1 => ov7670_pclk1,
ov7670_pclk2 => ov7670_pclk2,
ov7670_pclk3 => ov7670_pclk3,
ov7670_pclk4 => ov7670_pclk4,
ov7670_xclk1 => ov7670_xclk1,
ov7670_xclk2 => ov7670_xclk2,
ov7670_xclk3 => ov7670_xclk3,
ov7670_xclk4 => ov7670_xclk4,
ov7670_vsync1 => ov7670_vsync1,
ov7670_vsync2 => ov7670_vsync2,
ov7670_vsync3 => ov7670_vsync3,
ov7670_vsync4 => ov7670_vsync4,
ov7670_href1 => ov7670_href1,
ov7670_href2 => ov7670_href2,
ov7670_href3 => ov7670_href3,
ov7670_href4 => ov7670_href4,
ov7670_data1 => ov7670_data1,
ov7670_data2 => ov7670_data2,
ov7670_data3 => ov7670_data3,
ov7670_data4 => ov7670_data4,
ov7670_sioc1 => ov7670_sioc1,
ov7670_sioc2 => ov7670_sioc2,
ov7670_sioc3 => ov7670_sioc3,
ov7670_sioc4 => ov7670_sioc4,
ov7670_siod1 => ov7670_siod1,
ov7670_siod2 => ov7670_siod2,
ov7670_siod3 => ov7670_siod3,
ov7670_siod4 => ov7670_siod4,
vga_hsync => vga_hsync,
vga_vsync => vga_vsync,
vga_rgb => vga_rgb,
o_cs => o_cs,
o_do => o_do,
o_ck => o_ck,
o_reset => o_reset,
o_rs => o_rs
);

camera_xclk_process :process
begin
camera_i_xclk <= '0';
wait for camera_i_xclk_period/2;
camera_i_xclk <= '1';
wait for camera_i_xclk_period/2;
end process;

clkcam_process :process
begin
clkcam <= '0';
wait for clkcam_period/2;
clkcam <= '1';
wait for clkcam_period/2;
end process;

-- Stimulus process
stim_proc : process
begin
-- hold reset state for 100 ns.
pb <= '1';
wait for 2500 ns;
--wait for 500 ns;
pb <= '0';
wait for clkcam_period*10;
-- insert stimulus here
wait;
end process;

END;
