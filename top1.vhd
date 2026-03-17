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
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

use work.micron_mem_parameters.all;

entity top is
Port	(
i_clock	: in STD_LOGIC;
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
Adv_n : out std_logic;
Ce_n : out std_logic;
Clk : out std_logic;
Cre : out std_logic;
Lb_n : out std_logic;
Oe_n : out std_logic;
Ub_n : out std_logic;
We_n : out std_logic;
oWait : in std_logic;
--VGA
vga_clock : out STD_LOGIC;
vga_blank : out STD_LOGIC;
vga_hsync, vga_hsdbg : out STD_LOGIC;
vga_vsync, vga_vsdbg : out STD_LOGIC;
vga_r	: out STD_LOGIC_VECTOR(2 downto 0);
vga_g	: out STD_LOGIC_VECTOR(2 downto 0);
vga_b	: out STD_LOGIC_VECTOR(1 downto 0)
);
end entity top;

architecture Behavioral of top is

component top_camera_monitoring is
Port	(
i_clock	: in STD_LOGIC;
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
Adv_n : out std_logic;
Ce_n : out std_logic;
Clk : out std_logic;
Cre : out std_logic;
Lb_n : out std_logic;
Oe_n : out std_logic;
Ub_n : out std_logic;
We_n : out std_logic;
oWait : in std_logic;
--VGA
vga_clock : out STD_LOGIC;
vga_blank : out STD_LOGIC;
vga_hsync, vga_hsdbg : out STD_LOGIC;
vga_vsync, vga_vsdbg : out STD_LOGIC;
vga_r	: out STD_LOGIC_VECTOR(2 downto 0);
vga_g	: out STD_LOGIC_VECTOR(2 downto 0);
vga_b	: out STD_LOGIC_VECTOR(1 downto 0)
);
end component top_camera_monitoring;
for all : top_camera_monitoring use entity work.top_camera_monitoring (raw_signal);

begin

inst_top_camera_monitoring : top_camera_monitoring
Port map (
i_clock	=> i_clock,
pb	=> pb,
sw => sw,
led1 => led1,
-- OV7670
ov7670_pclk1 => ov7670_pclk1,
ov7670_xclk1 => ov7670_xclk1,
ov7670_vsync1 => ov7670_vsync1,
ov7670_href1 => ov7670_href1,
ov7670_data1 => ov7670_data1,
ov7670_sioc1 => ov7670_sioc1,
ov7670_siod1 => ov7670_siod1,
ov7670_pwdn1 => ov7670_pwdn1,
ov7670_reset1 => ov7670_reset1,
--memory module
Dq => Dq,
Addr => Addr,
Adv_n => Adv_n,
Ce_n => Ce_n,
Clk => Clk,
Cre => Cre,
Lb_n => Lb_n,
Oe_n => Oe_n,
Ub_n => Ub_n,
We_n => We_n,
oWait => oWait,
--VGA
vga_clock => vga_clock,
vga_blank => vga_blank,
vga_hsync => vga_hsync,
vga_vsync => vga_vsync,
vga_hsdbg => vga_hsdbg,
vga_vsdbg => vga_vsdbg,
vga_r	=> vga_r,
vga_g	=> vga_g,
vga_b	=> vga_b
);

end Behavioral;

