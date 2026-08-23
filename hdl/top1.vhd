----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    17:15:54 03/12/2026 
-- Design Name: 
-- Module Name:    top - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

library work;
use work.micron_mem_parameters.all;
use work.p_constants.all;

entity top is
  generic (
    constant c_module_mode : module_mode_st := c_module_mode_syn;
    constant c_pb_bits     : integer        := 25 -- xxx set debounce time
  );
  port  (
    i_clock    : in std_logic;
    pb1        : in std_logic;
    pb2        : in std_logic;
    sw         : in std_logic_vector (7 downto 0);
    led1       : out std_logic; -- configuration done
    last_reset : out std_logic; -- last locked DCM
    -- OV7670 camera input
    ov7670_pclk1  : in    std_logic;
    ov7670_vsync1 : in    std_logic;
    ov7670_href1  : in    std_logic;
    ov7670_data1  : in    std_logic_vector (7 downto 0);
    ov7670_xclk1  : out   std_logic;
    ov7670_sioc1  : out   std_logic;
    ov7670_pwdn1  : out   std_logic;
    ov7670_reset1 : out   std_logic;
    ov7670_siod1  : inout std_logic;
    -- Memory module (middleman)
    owait : in    std_logic;
    adv_n : out   std_logic;
    ce_n  : out   std_logic;
    clk   : out   std_logic;
    cre   : out   std_logic;
    lb_n  : out   std_logic;
    oe_n  : out   std_logic;
    ub_n  : out   std_logic;
    we_n  : out   std_logic;
    addr  : out   std_logic_vector (c_addr_bits - 1 downto 0);
    dq    : inout std_logic_vector (c_data_bits - 1 downto 0);
    -- VGA signals output
    vga_clock : out std_logic;
    vga_blank : out std_logic;
    vga_hsync : out std_logic;
    vga_vsync : out std_logic;
    vga_r     : out std_logic_vector (2 downto 0);
    vga_g     : out std_logic_vector (2 downto 0);
    vga_b     : out std_logic_vector (1 downto 0)
  );
end entity top;

architecture behavioral of top is

  component top_camera_monitoring is
  generic (
    constant c_module_mode : module_mode_st := c_module_mode;
    constant c_pb_bits     : integer        := c_pb_bits
  );
  port  (
    i_clock    : in std_logic;
    pb1        : in std_logic;
    pb2        : in std_logic;
    sw         : in std_logic_vector (7 downto 0);
    led1       : out std_logic; -- configuration done
    last_reset : out std_logic; -- last locked DCM
    -- OV7670 camera input
    ov7670_pclk1  : in  std_logic;
    ov7670_vsync1 : in  std_logic;
    ov7670_href1  : in  std_logic;
    ov7670_data1  : in  std_logic_vector(7 downto 0);
    ov7670_sioc1  : out std_logic;
    ov7670_xclk1  : out std_logic;
    ov7670_pwdn1  : out std_logic;
    ov7670_reset1 : out std_logic;
    ov7670_siod1  : inout std_logic;
    -- Memory module (middleman)
    owait : in    std_logic;
    adv_n : out   std_logic;
    ce_n  : out   std_logic;
    clk   : out   std_logic;
    cre   : out   std_logic;
    lb_n  : out   std_logic;
    oe_n  : out   std_logic;
    ub_n  : out   std_logic;
    we_n  : out   std_logic;
    addr  : out   std_logic_vector (c_addr_bits - 1 downto 0);
    dq    : inout std_logic_vector (c_data_bits - 1 downto 0);
    -- VGA signals output
    vga_clock : out std_logic;
    vga_blank : out std_logic;
    vga_hsync : out std_logic;
    vga_vsync : out std_logic;
    vga_r     : out std_logic_vector (2 downto 0);
    vga_g     : out std_logic_vector (2 downto 0);
    vga_b     : out std_logic_vector (1 downto 0)
  );
  end component top_camera_monitoring;
  --for all : top_camera_monitoring use entity work.top_camera_monitoring (raw_signal);
  for all : top_camera_monitoring use entity work.top_camera_monitoring (structural);

begin

  inst_top_camera_monitoring : top_camera_monitoring
  generic map (
    c_module_mode => c_module_mode
  )
  port map (
    i_clock    => i_clock,
    pb1        => pb1,
    pb2        => pb2,
    sw         => sw,
    led1       => led1,
    last_reset => last_reset,
    -- OV7670 camera input
    ov7670_pclk1  => ov7670_pclk1,
    ov7670_xclk1  => ov7670_xclk1,
    ov7670_vsync1 => ov7670_vsync1,
    ov7670_href1  => ov7670_href1,
    ov7670_data1  => ov7670_data1,
    ov7670_sioc1  => ov7670_sioc1,
    ov7670_siod1  => ov7670_siod1,
    ov7670_pwdn1  => ov7670_pwdn1,
    ov7670_reset1 => ov7670_reset1,
    -- Memory module (middleman)
    dq    => dq,
    addr  => addr,
    adv_n => adv_n,
    ce_n  => ce_n,
    clk   => clk,
    cre   => cre,
    lb_n  => lb_n,
    oe_n  => oe_n,
    ub_n  => ub_n,
    we_n  => we_n,
    owait => owait,
    -- VGA signals output
    vga_clock => vga_clock,
    vga_blank => vga_blank,
    vga_hsync => vga_hsync,
    vga_vsync => vga_vsync,
    vga_r     => vga_r,
    vga_g     => vga_g,
    vga_b     => vga_b
  );

end architecture behavioral;

