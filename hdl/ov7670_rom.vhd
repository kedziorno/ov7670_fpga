library IEEE;
use IEEE.STD_LOGIC_1164.all;

package p_ov7670_rom is
  constant NC : integer := 56-10+1;
  type cmd_rom is array (0 to NC-1) of STD_LOGIC_VECTOR (15 downto 0);

  constant ov7670_rom : cmd_rom :=
(
x"1280", -- COM7   Reset -- Do it twice to make sure its wiped
x"1280", -- COM7   Reset -- choose output format. 
x"fffe",
x"1204", -- scaling
x"11"&"10000000",
x"6b"&"00000000",
x"1b01",
x"8c00",
x"0c00", -- scaling
x"3e00", -- scaling
x"0400",
x"40d8", -- COM15
x"138f",
x"4108",
x"3a04",
x"1418",
x"4fb3",
x"1500",
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
x"3c40",
x"6900",
x"7400",
x"703a", -- ba - pattern
x"7135",
x"7222",
x"73f2",
x"a202",
x"b084",
x"b10c",
x"b20e",
x"b380",
x"ffff"
);
end package p_ov7670_rom;

package body p_ov7670_rom is
end package body p_ov7670_rom;
