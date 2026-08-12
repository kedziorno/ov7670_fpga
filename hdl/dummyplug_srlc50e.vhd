----------------------------------------------------------------------------------
-- Company:         HomeDL
-- Engineer:        ko
--
-- Create Date:     15:23:19 08/09/2026
-- Design Name:     vhdl_primitive
-- Module Name:     dummyplug_srlc32e - Behavioral
-- Project Name:    -
-- Target Devices:  Xilinx Spartan 3E xc3s1200e
-- Tool versions:   ISE 14.7
-- Description:     Make longer SRL32 from twice SRL16
--
-- Dependencies:    -
--
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments: TODO - check INIT order for hi/lo
--
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

use IEEE.NUMERIC_STD.ALL;

library UNISIM;
use UNISIM.VComponents.all;

entity dummyplug_srlc50e is
generic (
INIT : bit_vector (49 downto 0) := (others => '0')
);
port (
Q   : out STD_ULOGIC;
A   : in STD_LOGIC_VECTOR (5 downto 0);
CE  : in STD_ULOGIC;
CLK : in STD_ULOGIC;
D   : in STD_ULOGIC
);
end entity dummyplug_srlc50e;

architecture behavioral of dummyplug_srlc50e is

signal qq1, qq2, qq3 : std_logic;

begin

srlc16e_1_i0 : SRLC16E
generic map (INIT => INIT (15 downto 0))
port map (
  Q   => open,
  Q15 => qq1,
  A0  => a (0), A1 => a (1), A2 => a (2), A3 => a (3),
  CE  => ce,
  CLK => clk,
  D   => d
);

srlc16e_2_i0 : SRLC16E
generic map (INIT => INIT (31 downto 16))
port map (
  Q   => open,
  Q15 => qq2,
  A0  => a (0), A1 => a (1), A2 => a (2), A3 => a (3),
  CE  => ce,
  CLK => clk,
  D   => qq1
);

srlc16e_3_i0 : SRLC16E
generic map (INIT => INIT (47 downto 32))
port map (
  Q   => open,
  Q15 => qq3,
  A0  => a (0), A1 => a (1), A2 => a (2), A3 => a (3),
  CE  => ce,
  CLK => clk,
  D   => qq2
);

srlc16e_4_i0 : SRLC16E
generic map (INIT => "11111111111111"&INIT (49 downto 48))
port map (
  Q   => q,
  Q15 => open,
  A0  => '0', A1 => '0', A2 => '0', A3 => '0',
  CE  => ce,
  CLK => clk,
  D   => qq3
);

end architecture behavioral;
