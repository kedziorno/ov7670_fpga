library IEEE;
use IEEE.STD_LOGIC_1164.all;

package p_ov7670_rom is
  constant NC : integer := 67-10+1;
  type cmd_rom is array (0 to NC-1) of STD_LOGIC_VECTOR (15 downto 0);

  constant ov7670_rom : cmd_rom :=
(
x"1280", -- COM7   Reset
x"1280", -- COM7   Reset
x"fffe",
x"1204", -- COM7   Size & RGB output
x"1100", -- CLKRC  Prescaler - Fin/(1+1)
x"0C00", -- COM3   Lots of stuff, enable scaling, all others off
x"3E00", -- COM14  PCLK scaling off
x"8C00", -- RGB444 Set RGB format
x"0400", -- COM1   no CCIR601
x"4010", -- COM15  Full 0-255 output, RGB 565
x"3a04", -- TSLB   Set UV ordering,  do not auto-reset window
x"1438", -- COM9  - AGC Celling
x"4f40", --x"4fb3", -- MTX1  - colour conversion matrix
x"5034", --x"50b3", -- MTX2  - colour conversion matrix
x"510C", --x"5100", -- MTX3  - colour conversion matrix
x"5217", --x"523d", -- MTX4  - colour conversion matrix
x"5329", --x"53a7", -- MTX5  - colour conversion matrix
x"5440", --x"54e4", -- MTX6  - colour conversion matrix
x"581e", --x"589e", -- MTXS  - Matrix sign and auto contrast
x"3dc0", -- COM13 - Turn on GAMMA and UV Auto adjust
x"1100", -- CLKRC  Prescaler - Fin/(1+1)
x"1711", -- HSTART HREF start (high 8 bits)
x"1861", -- HSTOP  HREF stop (high 8 bits)
x"32A4", -- HREF   Edge offset and low 3 bits of HSTART and HSTOP
x"1903", -- VSTART VSYNC start (high 8 bits)
x"1A7b", -- VSTOP  VSYNC stop (high 8 bits) 
x"030a", -- VREF   VSYNC low two bits
x"0e61", -- COM5(0x0E) 0x61
x"0f4b", -- COM6(0x0F) 0x4B 
x"1602", --
x"1e37", -- MVFP (0x1E) 0x07  -- FLIP AND MIRROR IMAGE 0x3x
x"2102",
x"2291",
x"2907",
x"330b",
x"350b",
x"371d",
x"3871",
x"392a",
x"3c78", -- COM12 (0x3C) 0x78
x"4d40", 
x"4e20",
x"6900", -- GFIX (0x69) 0x00
x"6b4a",
x"7410",
x"8d4f",
x"8e00",
x"8f00",
x"9000",
x"9100",
x"9600",
x"9a00",
x"b084",
x"b10c",
x"b20e",
x"b382",
x"b80a",
x"ffff"
);
end package p_ov7670_rom;

package body p_ov7670_rom is
end package body p_ov7670_rom;
