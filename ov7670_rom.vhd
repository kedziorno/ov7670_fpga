library IEEE;
use IEEE.STD_LOGIC_1164.all;

package p_ov7670_rom is
  constant NC : integer := 73+1;
  type cmd_rom is array (0 to NC-1) of STD_LOGIC_VECTOR (15 downto 0);

  constant ov7670_rom : cmd_rom :=
(
x"1280",
x"fffe",
x"1280",
x"fffe",
x"1200", -- COM7 00 (d), 04 (rgb), 02 (colorbar)
x"1101", -- CLKRC
x"6b40", -- DBLV
x"00ff", -- GAIN 00 (d), AGC
x"01ff", -- BLUE 80 (d), AWB blue gain
x"02ff", -- RED 80 (d), AWB red gain
x"2a00", -- EXHCH
x"3000", -- HSYST
x"3100", -- HSYEN
x"0443", -- COM1
x"138f", -- COM8
x"1b00", -- PSHFT
x"0c00", -- COM3
x"3e00", -- COM14 PCLK div
x"7080", -- XSC 3a (d), 80 (pattern)
x"7100", -- YSC 35 (d), 00 (pattern)
x"7211", -- SCALING_DCWCTR
x"7300", -- SCALING_PCLK_DV
x"a202", -- SCALING_PCLK_DELAY
x"8c03", -- RGB444 00 (d), 03 (enable, RGBx)
x"0800", -- RAVE
x"40c0", -- COM15 c0 (d)
x"3a0d", -- TSLB 0d (d)
x"1438", -- COM9
x"4f40", -- MTX1
x"5034", -- MTX2
x"510c", -- MTX3
x"5217", -- MTX4
x"5329", -- MTX5
x"5440", -- MTX6
x"581e", -- MTXS
x"3dc0", -- COM13
x"1700", -- HSTART 11 (d), 00 (dim, fs)
x"1800", -- HSTOP 61 (d), 00 (dim, fs)
x"3200", -- HREF 80 (d), 00 (dim, fs)
x"1900", -- VSTART 03 (d), 00 (dim, fs)
x"1a00", -- VSTOP 7b (d), 00 (dim, fs)
x"0300", -- VREF 00 (d), c0 (AGC[9:8]-3), 00 (dim, fs)
x"0761", -- AECHH
x"0f4b", -- COM6
x"1602", -- RSVD
x"1e05", -- MVFP
x"2102", -- ADCCTR1
x"2291", -- ADCCTR2
x"2907", -- RSVD
x"330b", -- CHLF
x"350b", -- RSVD
x"371d", -- ADC
x"3871", -- ACOM
x"392a", -- OFON
x"3c80", -- COM12 68 (d), 80 (always href)
x"4d40", -- RSVD
x"4e20", -- RSVD
x"6900", -- GFIX
x"7400", -- REG74
x"8d4f", -- RSVD
x"8e00", -- RSVD
x"8f00", -- RSVD
x"9000", -- RSVD
x"9100", -- RSVD
x"9600", -- RSVD
x"9a00", -- RSVD
x"b10c", -- ABLC1
x"b20e", -- RSVD
x"b382", -- THL_ST
x"b80a", -- RSVD
x"1502", -- COM10, 00 (d), 02 (vs neg)
x"4200", -- 00 (d), 04 (colorbar)
x"b084",
x"ffff"
);
end package p_ov7670_rom;

package body p_ov7670_rom is
end package body p_ov7670_rom;
