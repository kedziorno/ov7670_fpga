-----------------------------------------------------------------------
-- It is used to prevent bouncing from push button
-- Push button will be used for ov7670 instantiation
-- This design will remove bouncing within 300 ms after trigerring
--  process
-- Also send 10 ticks for reset DCM
-----------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.p_constants.all;

entity debounce_circuit is
generic (
  constant c_module_mode : module_mode_st := c_module_mode_syn;
  constant c_pb_bits_sim : integer        := 2; -- small value for start in sim
  constant c_pb_bits_syn : integer        := 24; -- 2^24 * 20ns = ~300ms
  constant c_ticks       : integer        := 10; -- output ticks
  constant c_zero        : integer        := 0
);
port (
  i_clock : in  std_logic;
  i_reset : in  std_logic;
  input   : in  std_logic;
  output  : out std_logic
);
end entity debounce_circuit;

architecture behavioral of debounce_circuit is

  constant c_max_sim   : unsigned (c_pb_bits_sim - 1 downto 0) := (others => '1');
  constant c_min_sim   : unsigned (c_pb_bits_sim - 1 downto 0) := (others => '0');
  constant c_max_syn   : unsigned (c_pb_bits_syn - 1 downto 0) := (others => '1');
  constant c_min_syn   : unsigned (c_pb_bits_syn - 1 downto 0) := (others => '0');
  signal   counter_sim : unsigned (c_pb_bits_sim - 1 downto 0);
  signal   counter_syn : unsigned (c_pb_bits_syn - 1 downto 0);

begin

  counting_proc : process (i_clock) is
    type states is (a, b, c);
    variable state   : states := a;
    variable v_ticks : integer range 0 to c_ticks - 1;
  begin
    if rising_edge (i_clock) then
      if (i_reset = '1') then
        state   := a;
        v_ticks := 0;
        output  <= '0';
        if (c_module_mode = c_module_mode_sim) then
          counter_sim <= (others => '0');
        end if;
        if (c_module_mode = c_module_mode_syn) then
          counter_syn <= (others => '0');
        end if;
      else
        case (state) is
          when a =>
            if (input = '1') then
              state := b;
            end if;
          when b =>
            if (c_module_mode = c_module_mode_sim) then
              if (counter_sim = c_max_sim - 1) then
                state       := c;
                output      <= '1';
                counter_sim <= c_min_sim;
              else
                output      <= '0';
                counter_sim <= counter_sim + 1;
              end if;
            end if;
            if (c_module_mode = c_module_mode_syn) then
              if (counter_syn = c_max_syn - 1) then
                state       := c;
                output      <= '1';
                counter_syn <= c_min_syn;
              else
                -- bouncing with high logic below 300ms will not trigger the output
                -- output, this case, pb that reset the camera
                output      <= '0';
                counter_syn <= counter_syn + 1;
              end if;
            end if;
          when c =>
            if (v_ticks = c_ticks - 1) then
              state   := a;
              v_ticks := 0;
              output  <= '0';
            else
              v_ticks := v_ticks + 1;
              output  <= '1';
            end if;
        end case;
      end if;
    end if;
  end process counting_proc;

end architecture behavioral;

