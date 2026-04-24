library IEEE;
use IEEE.STD_LOGIC_1164.all;

package p_ov7670_rom is
  constant NC : integer := 48+1;
  type cmd_rom is array (0 to NC-1) of STD_LOGIC_VECTOR (15 downto 0);

  constant ov7670_rom : cmd_rom :=
(
x"1280",
x"1280",
x"1280",
x"1280",
x"1280",
x"1280",
x"1280",
x"fffe",
x"1204", -- scaling
x"1103",
x"6bc0",
x"8c03",
x"0c00", -- scaling
x"3e00", -- scaling
x"0400",
x"40d0",
x"3a04",
x"1418",
x"4fb3",
x"50b3",
x"5100",
x"523d",
x"53a7",
x"54e4",
x"589e",
x"3dc0",
x"1714",
x"1802",
x"3280",
x"1903",
x"1a7b",
x"030a",
x"0f41",
x"1e00",
x"330b",
x"3c78",
x"6900",
x"7400",
x"b084",
x"b10c",
x"b20e",
x"b380",
x"703a", -- ba - pattern
x"7135",
x"7222",
x"73f2",
x"a202",
x"1502",
x"ffff"
);
end package p_ov7670_rom;

package body p_ov7670_rom is
end package body p_ov7670_rom;
