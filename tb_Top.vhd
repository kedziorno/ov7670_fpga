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
 
ENTITY tb_Top IS
END tb_Top;
 
ARCHITECTURE behavior OF tb_Top IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT Top
    PORT(
         clk50 : IN  std_logic;
				 	clkcam	: in STD_LOGIC; -- Crystal Oscilator 23.9616 MHz  --U9

         pb : IN  std_logic;
         sw : IN  std_logic;
         led : OUT  std_logic;
         ov7670_pclk : IN  std_logic;
         ov7670_xclk : OUT  std_logic;
         ov7670_vsync : IN  std_logic;
         ov7670_href : IN  std_logic;
         ov7670_data : IN  std_logic_vector(7 downto 0);
         ov7670_sioc : OUT  std_logic;
         ov7670_siod : INOUT  std_logic;
         ov7670_pwdn : OUT  std_logic;
         ov7670_reset : OUT  std_logic;
         vga_hsync : OUT  std_logic;
         vga_vsync : OUT  std_logic;
         vga_rgb : OUT  std_logic_vector(7 downto 0)
        );
    END COMPONENT;
    

   --Inputs
   signal clk50 : std_logic := '0';
   signal clkcam : std_logic := '0';
   signal pb : std_logic := '0';
   signal ov7670_pclk : std_logic := '0';
   signal ov7670_vsync : std_logic := '0';
   signal ov7670_href : std_logic := '0';
   signal ov7670_data : std_logic_vector(7 downto 0) := (others => '0');

	--BiDirs
   signal ov7670_siod : std_logic;

 	--Outputs
   signal led : std_logic;
   signal ov7670_xclk : std_logic;
   signal ov7670_sioc : std_logic;
   signal ov7670_pwdn : std_logic;
   signal ov7670_reset : std_logic;
   signal vga_hsync : std_logic;
   signal vga_vsync : std_logic;
   signal vga_rgb : std_logic_vector(7 downto 0);

   -- Clock period definitions
   constant clk50_period : time := 20 ns;
 
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
signal camera_i_xclk : std_logic := '0';
signal camera_i_rst : std_logic := '0';
signal camera_i_pwdn : std_logic := '0';
--BiDirs
signal camera_io_scl : std_logic := 'Z';
signal camera_io_sda : std_logic := 'Z';
--Outputs
signal camera_o_vs : std_logic;
signal camera_o_hs : std_logic;
signal camera_o_pclk : std_logic;
signal camera_o_d : std_logic_vector(7 downto 0);
constant camera_i_xclk_period : time := 41.733 ns;

signal xclk : std_logic;
signal sw : std_logic;

BEGIN

sw <= '1';

cam : camera PORT MAP (
camera_io_scl => camera_io_scl,
camera_io_sda => camera_io_sda,
camera_o_vs => camera_o_vs,
camera_o_hs => camera_o_hs,
camera_o_pclk => camera_o_pclk,
camera_i_xclk => camera_i_xclk,
camera_o_d => camera_o_d,
camera_i_rst => camera_i_rst,
camera_i_pwdn => camera_i_pwdn
);

clkcam <= xclk;
camera_i_xclk <= ov7670_xclk; -- cam <- dev
ov7670_pclk <= camera_o_pclk; -- dev <- cam
ov7670_data <= camera_o_d;
ov7670_vsync <= camera_o_vs;
ov7670_href <= camera_o_hs;
 
	-- Instantiate the Unit Under Test (UUT)
   uut: Top PORT MAP (
          clk50 => clk50,
					clkcam => clkcam,
          pb => pb,
          sw => sw,
          led => led,
          ov7670_pclk => ov7670_pclk,
          ov7670_xclk => ov7670_xclk,
          ov7670_vsync => ov7670_vsync,
          ov7670_href => ov7670_href,
          ov7670_data => ov7670_data,
          ov7670_sioc => ov7670_sioc,
          ov7670_siod => ov7670_siod,
          ov7670_pwdn => ov7670_pwdn,
          ov7670_reset => ov7670_reset,
          vga_hsync => vga_hsync,
          vga_vsync => vga_vsync,
          vga_rgb => vga_rgb
        );

   -- Clock process definitions
   clk50_process :process
   begin
		clk50 <= '0';
		wait for clk50_period/2;
		clk50 <= '1';
		wait for clk50_period/2;
   end process;

   camera_i_xclkp :process
   begin
		xclk <= '0';
		wait for camera_i_xclk_period/2;
		xclk <= '1';
		wait for camera_i_xclk_period/2;
   end process;
 
 
-- Stimulus process
stim_proc : process
begin
-- hold reset state for 100 ns.
--i_reset <= '1';
camera_i_rst <= '0';
wait for clk50_period*10;
--i_reset <= '0';
camera_i_rst <= '1';
wait for clk50_period*10;
-- insert stimulus here
wait;
end process;

END;
