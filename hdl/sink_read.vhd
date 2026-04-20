----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    21:10:32 04/05/2026 
-- Design Name: 
-- Module Name:    sink_read - Behavioral 
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

entity sink_read is
port (
sink_we : in std_logic;
reset : in std_logic;
sink_addr : in unsigned (9 downto 0);
dq : in std_logic_vector (15 downto 0);
read_buffer_addr : in std_logic_vector (9 downto 0);
read_buffer_data : out std_logic_vector (15 downto 0) := (others => '0');
clk_wr, clk_rd : in std_logic
);
end entity sink_read;

architecture Behavioral of sink_read is

constant ram_width : integer := 16;
constant ram_addr_bits : integer := 10;
type ram_t is array (2**ram_addr_bits - 1 downto 0) of std_logic_vector (ram_width - 1 downto 0);
signal read_buffer : ram_t := (others => (others => '0'));

begin

p0_rb : process (clk_wr) is
begin
  if (rising_edge (clk_wr)) then
    if (sink_we = '1') then
      read_buffer (to_integer (sink_addr)) <= dq;
    end if;
  end if;
end process p0_rb;

p1_rb : process (clk_rd) is
begin
  if (rising_edge (clk_rd)) then
    if (reset = '1') then
    read_buffer_data <= (others => '0');
    else
    read_buffer_data <= read_buffer (to_integer (unsigned (read_buffer_addr)));
  end if;
  end if;
end process p1_rb;

end Behavioral;

