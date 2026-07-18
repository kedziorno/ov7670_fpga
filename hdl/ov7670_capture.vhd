library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity ov7670_capture is
  port (
    reset : in  std_logic;
    -- Camera input
    pclk  : in std_logic;
    vsync : in std_logic;
    href  : in std_logic;
    d     : in std_logic_vector (7 downto 0);
    -- System output
    addr       : out std_logic_vector (10 downto 0);
    dout       : out std_logic_vector (15 downto 0);
    latched_hs : out std_logic;
    latched_vs : out std_logic
  );
end entity ov7670_capture;

architecture behavioral of ov7670_capture is
  constant c_one_row_ticks : integer := 640;
  signal d_latch       : std_logic_vector (15 downto 0);
  signal address       : std_logic_vector (10 downto 0);
  signal latched_vsync : std_logic;
  signal latched_href  : std_logic;
  signal latched_d     : std_logic_vector (7 downto 0);
begin
  addr <= address;
  dout <= d_latch;

  capture_process: process (pclk) is
  begin
    if (rising_edge (pclk)) then
      if (vsync = '1') then
        address <= (others => '0');
        d_latch <= (others => '0');
      else
        d_latch <= d_latch (7 downto 0) & latched_d;
        if (latched_href = '1') then
          if (to_integer (unsigned (address)) = c_one_row_ticks * 1 - 1) then
            address <= (others => '0');
          else
            address <= std_logic_vector (unsigned (address) + 1);
          end if;
        end if;
        if (latched_vsync = '1') then
          address <= (others => '0');
        end if;
      end if;
    end if;
  end process capture_process;

  latched_hs <= latched_href;
  latched_vs <= latched_vsync;
  latched_process : process (pclk, reset) is
  begin
    if (reset = '1') then
      latched_d     <= (others => '0');
      latched_href  <= '0';
      latched_vsync <= '0';
    elsif (rising_edge (pclk)) then
      latched_d     <= d;
      latched_href  <= href;
      latched_vsync <= vsync;
    end if;
  end process latched_process;
end architecture behavioral;

