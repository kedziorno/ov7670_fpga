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

entity debounce_circuit is
generic (
  constant c_syn         : string (1 to 1) := "y";
  constant c_pb_bits_sim : integer := 2; -- small value for start in sim
  constant c_pb_bits_syn : integer := 24; -- 2^24 * 20ns = ~300ms
  constant c_ticks       : integer := 10; -- output ticks
  constant c_zero        : integer := 0
);
port (
  i_clock : in  std_logic;
  i_reset : in  std_logic;
  input   : in  std_logic;
  output  : out std_logic
);
end entity debounce_circuit;

architecture behavioral of debounce_circuit is

  constant c_max_sim   : unsigned (c_pb_bits_sim - 1 downto 0);
  constant c_min_sim   : unsigned (c_pb_bits_sim - 1 downto 0);
  constant c_max_syn   : unsigned (c_pb_bits_syn - 1 downto 0);
  constant c_min_syn   : unsigned (c_pb_bits_syn - 1 downto 0);
  signal   counter_sim : unsigned (c_pb_bits_sim - 1 downto 0);
  signal   counter_syn : unsigned (c_pb_bits_syn - 1 downto 0);

begin

  counting_proc : process (i_clock) is
    type states is (a, b, c);
    variable state : states := a;
    variable v_ticks : integer range 0 to c_ticks - 1;
  begin
    if rising_edge (i_clock) then
      if (i_reset = '1') then
        state   := a;
        v_ticks := 0;
        output  <= '0';
        if (c_syn = "n") then
          counter_sim <= (others => '0');
        end if;
        if (c_syn = "y") then
          counter_syn <= (others => '0');
        end if;
      else
        case (state) is
          when a =>
            if (input = '1') then
              state := b;
            end if;
          when b =>
            if (c_syn = "n") then
              if (counter_sim = c_max_sim - 1) then
                state := c;
                output <= '1';
                counter_sim <= c_min_sim;
              else
                output <= '0';
                counter_sim <= counter_sim + 1;
              end if;
            end if;
            if (c_syn = "y") then
              if (counter_syn = c_max_syn - 1) then
                state := c;
                output <= '1';
                counter_syn <= c_min_syn;
              else
                -- bouncing with high logic below 300ms will not trigger the output
                -- output, this case, pb that reset the camera
                output <= '0';
                counter_syn <= counter_syn + 1;
              end if;
            end if;
          when c =>
            if (v_ticks = c_ticks - 1) then
              state := a;
              output <= '0';
              v_ticks := 0;
            else
              output <= '1';
              v_ticks := v_ticks + 1;
            end if;
        end case;
      end if;
    end if;
  end process counting_proc;

end architecture behavioral;

