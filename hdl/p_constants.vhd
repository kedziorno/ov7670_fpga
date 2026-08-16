-------------------------------------------------------------------------------
--
--  Package File: p_constants.vhd
--
--  Purpose: This file defines supplemental type,subtype,constant,function ('s)
--    for module : ov7670_camera_emulator.
--
--  Denotes used in all code (only first/last prefix/suffix):
--    - c_   - constants
--    - g_   - generates
--    - i_   - input signals
--    - o_   - output signals
--    - p_   - processes
--    - v_   - variables
--    - io_  - inout signals
--    - lX_  - loops
--    - _i   - internal signals
--    - _iX  - instances
--    - _m   - memories
--    - _p   - packages
--    - _sr  - shift registers
--    - _t   - types
--    - _fe  - falling edge
--    - _re  - rising edge
--    - _dut - Device Under Test
--    - _uut - Unit Under Test
--
-- Additional Comments:
--  - Module is only for simulation.
--  - Module load *.hex data for simulation.
--    Each .hex file is RAW data storing one frame 640x480 with RGB888 color.
--    Is 30 .hex files, so we have 1 second animation (camera have max 30 fps)
--    On this time, only one frame is used:
--      - from file hex_memory_file_frame1.hex
--      - c_hex_rom_files_count = 1
--
-- Dependencies:
--  - Files:
--    - numeric_std.vhd
--      copy of with commented lines 3211-3213 and 3181-3182
--      for boost ISIM simulation, but better is set flag NO_WARNING (line 883)
--    - hex_memory_file_frame*.hex
--      files with RAW data for each frame - store RAW data for VGA 30 fps
--  - Modules:
--    - STD_LOGIC_TEXTIO - for 'hstring' function
--
-- Revision:
--  - Revision 0.01 - File created
--    - Files: -
--    - Modules: -
--    - Functions:
--      - hex - convert std_logic_vector to HEX string
--      - to_string_1 - convert std_logic_vector as raw bits string
--    - Procedures:
--      - readandconvertrom - create ROM memory from files
--
-- Concepts/Milestones:
--  - for captured_frame_mem object, probe to use CONSTANT
--
-- Imporant Subtypes/Types/Signals/Variables/Constants:
--  - c_debug - flag which turn on some debugging on console
--  - c_hex_rom_files_name - ROM file name (each line have '#AABBCC')
--  - c_hex_rom_files_ext - ROM file name suffix (file extension - using .hex)
--  - c_hex_rom_files_count - numer files
--    - For now, in TB we assume import 1 frame.
--  - camera_frame_t - 2d array store 640x480 RGB565 raw pixels
--  - captured_frame_mem - initialized empty memory for camera_frame_t
--
-- Information from the software vendor:
--  - Messeges: -
--  - Bugs:
--    - Sometimes race condition in ISIMGUI 14.7 in readandconvertrom when
--      Restart/Re-launch (console version of .exe file works good). TODO:
--      Check and test wait befor/after load.
--  - Notices: -
--  - Infos: -
--  - Notes: -
--  - Criticals/Failures: -
--
-------------------------------------------------------------------------------

library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_textio.all;
  use ieee.numeric_std.all;
  use std.textio.all;

use work.micron_mem_parameters.all;

package p_constants is

  -- modules have two mode (sim and syn)
  type module_mode_st is (c_module_mode_sim, c_module_mode_syn);

  -- ram interface
  constant c_initialize_wait  :  integer := 16;
  subtype  initialize_wait_st is integer range 0 to c_initialize_wait - 1;
  constant c_select_index          :  integer := 4;
  constant c_select_index_bits     :  integer := 2;
  subtype  select_index_integer_st is integer range 0 to c_select_index - 1;
  subtype  select_index_slv_st     is std_logic_vector (1 downto 0);
  subtype  slv_a is std_logic_vector (c_addr_bits - 1 downto 0);
  constant aZ    :  slv_a := (others => '0');
  constant a0    :  slv_a := (others => '0');
  constant a1    :  slv_a := "000"&x"81d0f"; --"00010001001100000101010";
  constant a2    :  slv_a := "00000000000000000000000";
  subtype  slv_d is std_logic_vector (c_data_bits - 1 downto 0);
  constant dZ    :  slv_d := (others => '0');
  constant d0    :  slv_d := (others => '0');
  constant c_memory_operation_wait_wr : integer := 4;
  constant c_memory_operation_wait_rd : integer := 6;
  subtype  select_slv_st is std_logic_vector (1 downto 0);
  constant select_read   : select_slv_st := "10";
  constant select_write  : select_slv_st := "01";
  constant select_reset  : select_slv_st := "00";
  
  -- Constants from camera datasheet
  constant clock_period  : integer := 21;
  constant raw_rgb       : integer := 1;
  constant zero          : boolean := false;
  constant clock_period1 : integer := clock_period;
  constant clock_period2 : integer := 42;
  constant clock_period3 : integer := 100;
  constant tp            : integer := 2 ** raw_rgb;
  constant href0         : integer := 144;
  constant href1         : integer := 640;
  constant chref0        : integer := href0 * tp;
  constant chref1        : integer := href1 * tp;
  constant tline         : integer := chref1 + chref0;
  constant cvsync1       : integer := 3;
  constant cvsync2       : integer := 17;
  constant cvsync3       : integer := 480;
  constant cvsync4       : integer := 10;
  constant cvsyncall     : integer := cvsync1 + cvsync2 + cvsync3 + cvsync4;
  constant vsync1        : integer := cvsync1 * tline;
  constant vsync2        : integer := cvsync2 * tline;
  constant vsync3        : integer := cvsync3 * tline;
  constant vsync4        : integer := cvsync4 * tline;

  -- tb
  constant camera_i_xclk_period : time := 21 ns; -- camera 48MHz clock
  --constant video_clock_period   : time := 39.80099502487 ns; -- industrial clock 25.175MHz for VGA
  constant video_clock_period   : time := 40 ns;  -- normal clock 25Mhz for VGA
  --constant clk100_clock_period  : time := 10 ns;  -- output BMPs have black pixels
  --constant clk100_clock_period  : time := 7.5 ns;   -- (133Mhz) black screen
  --constant clk100_clock_period  : time := 8 ns;   -- output BMPs have black pixels > 50% (2x diagonals)
  --constant clk100_clock_period  : time := 8.5 ns;   -- output BMPs have black pixels > 50% (diagonals)
  --constant clk100_clock_period  : time := 9 ns;   -- output BMPs have black pixels > 50%
  --constant clk100_clock_period  : time := c_tCLK; -- output BMPs have black pixels
  constant clk100_clock_period  : time := 10 ns;   -- output BMPs have black pixels 50% step by 2 row (the best version)
  --constant clk100_clock_period  : time := 11 ns;   -- output BMPs have black pixels > 50%
  --constant clk100_clock_period  : time := 11.5 ns;   -- output BMPs have black pixels > 50% (diagonals)
  --constant clk100_clock_period  : time := 12 ns;   -- output BMPs have black pixels > 50% (diagonals)
  --constant clk100_clock_period  : time := 12.5 ns;   -- output BMPs have black pixels > 50% (diagonals)
  --constant clk100_clock_period  : time := 13 ns;   -- (76.9230Mhz) output BMPs have black pixels > 75% (diagonals)

  constant c_camera_i2c_address : std_logic_vector(7 downto 0) := x"42";

  constant number_frames_to_catch            : integer := 2; --28 - very slow; -- XXX number frames
  shared variable number_frame               : integer := 0;

  constant c_debug                           : boolean := true;
  constant c_bits_color_rgb888               : integer := 24;
  constant c_bits_color_rgb565               : integer := 16;
  constant c_camera_width                    : integer := 640;
  constant c_camera_height                   : integer := 480;
  constant c_camera_fps                      : integer := 4; --30;
  constant c_camera_frame_memory_data_bits   : integer := 23; -- XXX micron_mem_parameters max
  constant c_camera_color_bits               : integer := c_bits_color_rgb565;
  constant c_camera_frame_length             : integer := c_camera_width * c_camera_height;
  constant c_camera_frame_length_bits        : integer := 19;
  constant c_camera_frame_length_colors      : integer := c_camera_width * c_camera_height * 3;
  constant c_camera_frame_length_colors_bits : integer := 20;
  constant c_hex_rom_files_path              : string  := "ov7670_camera_emulator/";
  constant c_hex_rom_files_name_length       : integer := c_hex_rom_files_path'length;
  constant c_hex_rom_files_name              : string  := "ov7670_camera_emulator/hex_memory_file_frame";
  constant c_hex_rom_files_ext               : string  := "hex";
  constant c_hex_rom_files_count             : integer := number_frames_to_catch;
  constant c_hex_rom_files_data_width        : integer := c_bits_color_rgb888;

  constant c_num_report                      : integer := 2;
  constant c_all_frames                      : integer := c_camera_frame_length * number_frames_to_catch;
  constant c_sdcard_end_address              : integer := c_all_frames - 512;

  --synthesis translate_off
--  type camera_frame_t is
--    array (0 to c_all_frames - 1) of
--      std_logic_vector(c_camera_color_bits - 1 downto 0);
--
--  shared variable captured_frame_m : camera_frame_t;

  function to_string_1 (
    s : std_logic_vector
  ) return string;

  function hex (
    lvec : in std_logic_vector
  ) return string;

  procedure readandconvertrom (
    filename   : in string (1 to 27+c_hex_rom_files_name_length);
    start_addr : in integer range 0 to c_all_frames - 1
  );

  procedure hread888 (
    l     : in  string (1 to 6);
    value : out std_logic_vector (c_bits_color_rgb888 - 1 downto 0);
    good  : out boolean
  );
  --synthesis translate_on

end package p_constants;

package body p_constants is

  --synthesis translate_off
  function to_string_1 (
    s : std_logic_vector
  ) return string is
    variable r : string (s'length downto 1);
  begin
    for i in s'range loop

      r (i + 1) := std_logic'image (s(i)) (2);

    end loop;
    return r;

  end function to_string_1;

  -- https://stackoverflow.com/a/53391980

  function hex (
    lvec : in std_logic_vector
  ) return string is

    subtype  halfbyte is std_logic_vector(4 - 1 downto 0);
    variable text : string (lvec'length / 4 - 1 downto 0);

  begin

    assert lvec'length mod 4 = 0
      report "hex() works only with vectors whose length is a multiple of 4"
      severity FAILURE;
    text := (others => '9');

    for k in text'range loop

      case halfbyte'(lvec(4 * k + 3 downto 4 * k)) is

        when "0000" =>

          text(k) := '0';

        when "0001" =>

          text(k) := '1';

        when "0010" =>

          text(k) := '2';

        when "0011" =>

          text(k) := '3';

        when "0100" =>

          text(k) := '4';

        when "0101" =>

          text(k) := '5';

        when "0110" =>

          text(k) := '6';

        when "0111" =>

          text(k) := '7';

        when "1000" =>

          text(k) := '8';

        when "1001" =>

          text(k) := '9';

        when "1010" =>

          text(k) := 'A';

        when "1011" =>

          text(k) := 'B';

        when "1100" =>

          text(k) := 'C';

        when "1101" =>

          text(k) := 'D';

        when "1110" =>

          text(k) := 'E';

        when "1111" =>

          text(k) := 'F';

        when others =>

          text(k) := '!';

      end case;

    end loop;

    return text;

  end function hex;

  procedure readandconvertrom (

    filename   : in string (1 to 27+c_hex_rom_files_name_length);
    start_addr : in integer range 0 to c_all_frames - 1

  ) is

    -- https://stackoverflow.com/a/32249431
    -- https://stackoverflow.com/a/41847365
    variable rgb888   : std_logic_vector(c_bits_color_rgb888 - 1 downto 0);
    variable rgb565   : std_logic_vector(c_bits_color_rgb565 - 1 downto 0);
    variable rgb565_r : std_logic_vector(4 downto 0);
    variable rgb565_g : std_logic_vector(5 downto 0);
    variable rgb565_b : std_logic_vector(4 downto 0);
    file F                    : text;
    variable fstatus          : file_open_status;
    variable file_line        : line;
    variable line_string      : string (1 to 6);
    variable v_start_address  : integer := 0;
    variable hread_good       : boolean := false;
    variable index            : integer := 1;
    variable flag             : boolean := false;
    variable a : line;
  begin

    v_start_address := start_addr;
    file_open (fstatus, F, filename);

    if (fstatus /= OPEN_OK) then
      report "readandconvertrom: " & file_open_status'image (fstatus) & " status";
      report "readandconvertrom" severity failure;
    end if;

    flag := true;

    while not endfile (F) loop
      readline (F, file_line);
      if (file_line'length > 0) then
        read (file_line, line_string);
        if (line_string'length > 0) then
          a := new string'(line_string);
          -- report time'image(now);
          hread (a, rgb888, hread_good);
          if (hread_good = false) then
            report "readandconvertrom: error at line " & integer'image (index);
            report "readandconvertrom: valI " &
              a(1) & a(2) & a(3) &
              a(4) & a(5) & a(6);
            report "readandconvertrom: valO " & hex (rgb888);
            report "readandconvertrom" severity failure;
          else
            --wait for 1 ps;
            -- XXX strange behaviour, with report works load 3 frames
            --report "readandconvertrom: readed valO " & hex (rgb888);
          end if;
          deallocate (a);
          index := index + 1;

          rgb565_r                             := rgb888 (23 downto 19);
          rgb565_g                             := rgb888 (15 downto 10);
          rgb565_b                             := rgb888 (7 downto 3);
          rgb565                               := rgb565_r & rgb565_g & rgb565_b;
--          captured_frame_m (v_start_address)   := rgb565;
          v_start_address                      := v_start_address + 1;

          if (c_debug = true) then
            if (flag = true) then
              report "rgb888 " & " " & hex (rgb888) & " " & to_string_1 (rgb888);
              report "rgb565 " & " " & hex (rgb565) & " " & to_string_1 (rgb565);
              flag := false;
            end if;
          end if;
          deallocate (file_line);
        end if;
      end if;
    end loop;

    file_close (F);
    report "Done";

  end procedure readandconvertrom;

  procedure hread888 (
    l     : in  string (1 to 6);
    value : out std_logic_vector (c_bits_color_rgb888 - 1 downto 0);
    good  : out boolean
  ) is
    variable nibble : std_logic_vector (3 downto 0);
    variable j : integer range 5 downto -1;
  begin -- 94979b
    j := 5;
    for i in 1 to 6 loop
      case (l (i)) is
        when '0' => nibble := "0000";
        when '1' => nibble := "0001";
        when '2' => nibble := "0010";
        when '3' => nibble := "0011";
        when '4' => nibble := "0100";
        when '5' => nibble := "0101";
        when '6' => nibble := "0110";
        when '7' => nibble := "0111";
        when '8' => nibble := "1000";
        when '9' => nibble := "1001";
        when 'a' => nibble := "1010";
        when 'b' => nibble := "1011";
        when 'c' => nibble := "1100";
        when 'd' => nibble := "1101";
        when 'e' => nibble := "1110";
        when 'f' => nibble := "1111";
        when others =>
          nibble := "XXXX";
          report "Unexpected HEX character : " & l (i) severity warning;
      end case;
      value (((j+1)*4)-1 downto ((j)*4)) := nibble;
      j := j - 1;
    end loop;
  end procedure hread888;
  --synthesis translate_on

end package body p_constants;
