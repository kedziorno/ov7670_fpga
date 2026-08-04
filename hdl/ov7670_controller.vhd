---------------------------------------------
-- This entity is needed to setup the camera
-- Thanks to Mike Field for Register Value
---------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library work;
use work.p_constants.all;

entity ov7670_i2c_controller is
generic (
  c_module_mode : module_mode_st := c_module_mode_syn
);
port (
  i_clock   : in  std_logic;
  i_reset   : in  std_logic;
  resend    : in  std_logic; -- from external reset
  sw        : in  std_logic; -- switch as external reset
  sioc      : out std_logic; -- i2c clock
  siodo     : out std_logic; -- i2c data
  conf_done : out std_logic; -- led pin flag
  pwdn      : out std_logic; -- camera PWDN pin
  reset     : out std_logic; -- camera RESET pin
  xclk_in   : in  std_logic; -- camera clock input
  xclk_out  : out std_logic  -- camera clock output
);
end entity ov7670_i2c_controller;

architecture behavioral of ov7670_i2c_controller is

  signal command : std_logic_vector (15 downto 0);
  signal done : std_logic := '0';
  signal taken : std_logic := '0';
  signal send : std_logic;

begin

  conf_done <= done;
  send <= not done;
  pwdn <= sw or resend;
  reset <= not resend;
  xclk_out <= xclk_in;

  -- Strange error when building project
  --error:place:plxil_uapflow1.c:3213:1.176 clk clk_mc
  --process (clk,reset1) is
  --begin
  --if (reset1 = '1') then
  --xclk_out <= '0';
  --elsif (rising_edge (clk)) then
  --xclk_out <= xclk_in;
  --end if;
  --end process;

  --ov7670_registers_i0 : entity work.ov7670_registers (raw_signal)
  ov7670_registers_i0 : entity work.ov7670_registers (behavioral)
  generic map (
    c_module_mode => c_module_mode,
    c_mode => 0
  )
  port map (
    i_clock => i_clock,
    i_reset => i_reset,
    resend  => resend,
    advance => taken,
    command => command,
    done    => done
  );

  ov7670_sccb_i0 : entity work.ov7670_sccb
  generic map (
    c_module_mode => c_module_mode
  )
  port map(
    i_clock    => i_clock,
    i_reset    => i_reset,
    slave_addr => c_camera_i2c_address,
    reg_value  => command (7 downto 0),
    addr_reg   => command (15 downto 8),
    send       => send,
    sioc       => sioc,
    siodo      => siodo,
    taken      => taken
  );

end architecture behavioral;

