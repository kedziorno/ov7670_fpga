library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_arith.all;
use ieee.std_logic_unsigned.all;
library work;
use work.p_constants.all;

entity address_generator is
generic (
  c_module_mode : module_mode_st := c_module_mode_syn
);
port (
  clk25   : in std_logic;
  reset   : in std_logic;
  enable  : in std_logic;
  vsync   : in std_logic;
  address : out std_logic_vector (9 downto 0)
);  
end entity address_generator;

architecture behavioral of address_generator is

  signal addr        : std_logic_vector (address'range);
  signal enable_prev : std_logic;

begin

  address <= addr;
  p0_address_generator : process (clk25) begin
    if (rising_edge (clk25)) then
      if (reset = '1') then
        addr        <= (others => '0');
        enable_prev <= '0';
      else
        enable_prev <= enable;
        if (enable = '1') then
          if (addr = 2 ** (address'left + 1) - 1) then
            addr <= (others => '0');
          else
            addr <= addr + 1;
          end if;
        else
          addr <= addr;
        end if;
        if (enable = '1' and enable_prev = '0') then
          addr <= (others => '0');
        end if;
        if (vsync = '0') then
          addr <= (others => '0');
        end if;
      end if;
    end if;
  end process p0_address_generator;

end architecture behavioral;

