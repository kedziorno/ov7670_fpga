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

entity dummyplug_srlc64e is
generic (
INIT : bit_vector (63 downto 0) := X"0000000000000000"
);
port (
Q   : out STD_ULOGIC;
Q63 : out STD_ULOGIC;
A   : in STD_LOGIC_VECTOR (5 downto 0);
CE  : in STD_ULOGIC;
CLK : in STD_ULOGIC;
D   : in STD_ULOGIC
);
end entity dummyplug_srlc64e;

architecture behavioral of dummyplug_srlc64e is

signal q_hi, q_lo : std_logic;
signal d_hi, d_lo : std_logic;

begin

q <= d_hi when a (5) = '1' else d_lo;
q63 <= q_hi;

dp_srlc32e_hi_i0 : entity work.dummyplug_srlc32e
generic map (INIT => INIT (63 downto 32))
port map (
  Q   => d_hi,
  Q31 => q_hi,
  A(0)  => a (0), A(1) => a (1), A(2) => a (2), A(3) => a (3), A(4) => a (4),
  CE  => ce,
  CLK => clk,
  D   => q_lo
);

dp_srlc32e_lo_i0 : entity work.dummyplug_srlc32e
generic map (INIT => INIT (31 downto 0))
port map (
  Q   => d_lo,
  Q31 => q_lo,
  A(0)  => a (0), A(1) => a (1), A(2) => a (2), A(3) => a (3), A(4) => a (4),
  CE  => ce,
  CLK => clk,
  D   => d
);

end architecture behavioral;
