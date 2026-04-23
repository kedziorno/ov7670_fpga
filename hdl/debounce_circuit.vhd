-----------------------------------------------------------------------
-- It is used to prevent bouncing from push button
-- Push button will be used for ov7670 instantiation
-- This design will remove bouncing within 300 ms after trigerring
--  process
-- Also send 10 ticks for reset DCM
-----------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
entity debounce_circuit is
Generic (
  PB_BITS : integer := 2
);
Port (
clk : in  STD_LOGIC;
reset : in  STD_LOGIC;
input : in  STD_LOGIC;
output : out  STD_LOGIC);
end entity debounce_circuit;

architecture Behavioral of debounce_circuit is

constant MAX : unsigned (PB_BITS - 1 downto 0) := (others => '1');
constant MIN : unsigned (PB_BITS - 1 downto 0) := (others => '0');
signal counter : unsigned (PB_BITS-1 downto 0) := (others => '0');

begin

counting_proc : process (clk) is
  type states is (a, b, c);
  variable state : states := a;
  constant c_ticks : integer := 10;
  variable v_ticks : integer range 0 to c_ticks - 1;
begin
  if rising_edge (clk) then
    if (reset = '1') then
      counter <= (others => '0');
      output <= '0';
      state := a;
      v_ticks := 0;
    else
      case (state) is
        when a =>
          if input = '1' then
            state := b;
          end if;
        when b =>
          if (counter = MAX - 1) then 
            -- Counter will count 2^24 * 20ns = ~300ms
            state := c;
            output <= '1';
            counter <= MIN;
          else
            -- Bouncing with high logic below 300ms will not trigger the output
            -- output, this case, pb that reset the camera
            output <= '0';
            counter <= counter + 1;
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

end Behavioral;

