----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    15:14:40 04/06/2026 
-- Design Name: 
-- Module Name:    ram_buffer - Behavioral 
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
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity ram_buffer is
port (
clka : in std_logic;
ena : in std_logic;
wea : in std_logic;
addra : in std_logic_vector (10 downto 0);
dina : in std_logic_vector (7 downto 0);
clkb : in std_logic;
addrb : in std_logic_vector (9 downto 0);
doutb : out std_logic_vector (15 downto 0)
);
end entity ram_buffer;

architecture Behavioral of ram_buffer is

constant ram_width : integer := 8;
constant ram_addr_bits : integer := 11;
type ram_t is
  array (2**ram_addr_bits - 1 downto 0) of
  std_logic_vector (ram_width - 1 downto 0);
signal write_buffer : ram_t := (others => (others => '0'));

signal doutb1, doutb2 : std_logic_vector (ram_width - 1 downto 0);

signal addr_t : integer range 0 to 2**(addrb'length+1) - 2;

begin

p0_wb : process (clka) is
begin
  if (rising_edge (clka)) then
    if (ena = '1') then
      if (wea = '1') then
        write_buffer (to_integer (unsigned (addra))) <= dina;
      end if;
    end if;
  end if;
end process p0_wb;

p1_wb : process (clkb) is
  variable vaddr_t : integer range 0 to 2**(addrb'length+1) - 2;
  variable vwb1, vwb2 : std_logic_vector (ram_width - 1 downto 0);
begin
  if (rising_edge (clkb)) then
    vaddr_t := to_integer (unsigned (addrb)) + 1;
    addr_t <= vaddr_t;
    if (vaddr_t = 2**(addrb'length+1) - 2) then
      vaddr_t := 0;
    end if;
    vwb1 := write_buffer (vaddr_t);
    vwb2 := write_buffer (to_integer (unsigned (addrb)));
  end if;
  doutb <= vwb1 & vwb2;
end process p1_wb;

end Behavioral;

