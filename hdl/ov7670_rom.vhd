library ieee;
use ieee.std_logic_1164.all;

package p_ov7670_rom is
  constant c_nc : integer := 56 - 10 + 1; -- line number with x"ffff"
  type cmd_rom is array (0 to c_nc - 1) of std_logic_vector (15 downto 0);

  constant ov7670_rom : cmd_rom :=
  (
    x"1280", -- COM7   Reset -- Do it twice to make sure its wiped
    x"1280", -- COM7   Reset -- choose output format.
    x"fffe", -- PASUE
    x"12"&"00000100", -- COM7 2 - RGB
    x"11"&"10000001", -- CLKRC 7 - reserved
    x"6b"&"01000000", -- DBLV
    x"8c"&"00000010", -- RGB444 xRGB
    x"0c"&"00000000", -- COM3
    x"3e"&"00010001", -- COM14 4 - DCW and scaling PCLK, 20 - Divided by 2
    x"04"&"00000000", -- COM1
    x"40"&"11011000", -- COM15 76 - FF, 54 - RGB555
    x"13"&"00011111", -- COM8 43 - reserved, 2 - AGC, 1 - AWB, 0 - AEC
    x"41"&"00001000", -- COM16 3 - AWB gain
    x"3a"&"00000001", -- TSLB 2 - reserved
    x"14"&"00011000", -- COM9 4 - AGC 4x, 3 - reserved
    x"4fb3", -- MTX1
    x"50b3", -- MTX2
    x"5100", -- MTX3
    x"523d", -- MTX4
    x"53a7", -- MTX5
    x"54e4", -- MTX6
    x"58"&"10011110", -- MTXS 7 - autocontrast center enable
    x"1500", -- COM10
    x"3d"&"11000000", -- COM13 7 - gamma enable, 6 - UV sat lvl
    x"1711", -- HSTART
    x"1861", -- HSTOP
    x"3280", -- HREF
    x"1903", -- VSTRT
    x"1a7b", -- VSTOP
    x"00"&"01100000", -- GAIN
    x"03"&"00000000", -- VREF
    x"0f"&"01000001", -- COM6 6 - reserved, 1 - reserved
    x"1e"&"00000000", -- MVFP - 5 - mirror, 4 - flip
    x"33"&"00001011", -- CHLF 70 - reserved
    x"3c"&"01000000", -- COM12 - 60 - reserved
    x"6900", -- GFIX
    x"7400", -- REG74
    x"703a", -- SCALING_XSC 60 - horizontal scale factor
    x"7135", -- SCALING_YSC 60 - vertical scale factor
    x"72"&"00100010", -- SCALING_DCWCTR 54 - v down sample 4, 10 - h down sample 4
    x"73"&"11110010", -- SCALING_PCLK_DIV 74 - reserved, 20 - clk dv dsp by 4
    x"a2"&"00000010", -- SCALING_PCLK_DELAY 60 - scaling output delay
    x"b0"&"10000100", -- RSVD
    x"b1"&"00001100", -- ABLC1 73 - reserved, 2 - ABLC enable, 10 - reserved
    x"b2"&"00001110", -- RSVD XX
    x"b3"&"10000000", -- THL_ST ABLC target
    x"ffff" -- END
  );
end package p_ov7670_rom;

package body p_ov7670_rom is
end package body p_ov7670_rom;

