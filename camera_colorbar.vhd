-------------------------------------------------------------------------------
-- Company:         -
-- Engineer:        ko
--
-- Create Date:     14:56:40 07/10/2022
-- Design Name:     Camera Emulator
-- Module Name:     camera - Behavioral (original)
-- Project Name:    camera_emulator
-- Target Devices:  Not-Synthesizable
-- Tool versions:   Xilinx ISE 14.7
-- Description:     This is probably first version of camera emulator.
--
-- Dependencies:
--
-- Revision:
-- Revision 0.01 - File Created
-- Revision 0.02 - Add ROM memory with one frame to test output
-- Additional Comments:
--
-------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use work.p_constants.all;

-- XXX ov7670 camera emulator vga 640x480 30fps
-- XXX based on datasheet VGA Frame Timing Figure 6 p. 7
entity camera_colorbar is
generic (
constant CLOCK_PERIOD : integer := 42; -- 21/42/100 ns - 10/24/48 MHZ - Min/Typ/Max Unit
constant RAW_RGB : integer := 0; -- 0 - RAW / 1 - RGB
constant ZERO : integer := 0
);
port (
camera_io_scl : inout std_logic;
camera_io_sda : inout std_logic;
camera_o_vs : out std_logic;
camera_o_hs : out std_logic;
camera_o_pclk : out std_logic := '0';
camera_i_xclk : in std_logic;
camera_o_d : out std_logic_vector(7 downto 0);
camera_i_rst : in std_logic;
camera_i_pwdn : in std_logic
);
end camera_colorbar;

architecture Behavioral of camera_colorbar is
	constant CLOCK_PERIOD1 : integer := 21;
	constant CLOCK_PERIOD2 : integer := 42;
	constant CLOCK_PERIOD3 : integer := 100;
	-- 1 or 2 pclk for tp
	constant tp : integer := 2**RAW_RGB;
	-- tline = 784tp = 640tp + 144tp
	constant HREF1 : integer := 640;
	constant CHREF1 : integer := HREF1 * tp; -- HREF 1 pulse time
	constant HREF0 : integer := 144;
	constant CHREF0 : integer := HREF0 * tp; -- HREF 0 pulse time
	constant tline : integer := CHREF1 + CHREF0;
	-- VSYNC pulse have 510tline
	constant CVSYNC1 : integer := 3;
	constant VSYNC1 : integer := CVSYNC1 * tline;
	constant CVSYNC2 : integer := 17;
	constant VSYNC2 : integer := CVSYNC2 * tline;
	constant CVSYNC3 : integer := 480;
	constant VSYNC3 : integer := CVSYNC3 * tline;
	constant CVSYNC4 : integer := 10;
	constant VSYNC4 : integer := CVSYNC4 * tline;
	constant CVSYNCALL : integer := CVSYNC1 + CVSYNC2 + CVSYNC3 + CVSYNC4; -- 510tline
	signal href_time : std_logic;
	signal pixel_time : std_logic;


	signal a,b,c,d,e,f : std_logic;
  signal g : integer;
  signal cam_vs : std_logic;

  constant CDATALENGTH : integer := 5;
  type tdata is array(0 to CDATALENGTH - 1) of std_logic_vector(7 downto 0);
  --constant colorbar : tdata := (x"FF",x"FF",x"FF",x"FF",x"FF");
  --constant enddata : tdata := (x"FF",x"FF",x"FF",x"FF",x"FF");
  --constant odddata : std_logic_vector(7 downto 0) := x"FF";
  --constant evendata : std_logic_vector(7 downto 0) := x"FF";
  signal colorbar : tdata := (x"FE",x"E1",x"DE",x"CE",x"BE");
  type vstates is (svs1,svs2,svs3,svs4);
  signal vstate : vstates;
  type hstates is (s1,s2,s3);
  signal hstate : hstates;
  type hhstates is (swait4vsync,shref1,shref0);
  signal hhstate : hhstates;
		
begin

camera_o_vs <= cam_vs;

	-- check the clock period
	p0 : process (camera_i_rst) is
	begin
		if (camera_i_rst = '0') then
			assert (CLOCK_PERIOD = CLOCK_PERIOD1 or CLOCK_PERIOD = CLOCK_PERIOD2 or CLOCK_PERIOD = CLOCK_PERIOD3)
			report "-- CLOCK_PERIOD must have " & integer'image(CLOCK_PERIOD1) & "," & integer'image(CLOCK_PERIOD2) & "," & integer'image(CLOCK_PERIOD3) & " --"
			severity failure;
		end if;
	end process p0;

	-- generate sync pulse
	-- p.14 15 COM10 0x00 RW [2] - VSYNC changes on falling edge PCLK
	p1 : process (camera_i_xclk,camera_i_rst) is
		variable count : integer range 0 to CVSYNCALL*tline - 1;
		variable vvsync : std_logic;
	begin
		if (camera_i_rst = '0') then
			count := 0;
			vvsync := '1';
			vstate <= svs1;
			href_time <= '0';
		elsif (falling_edge(camera_i_xclk)) then
			case (vstate) is
				when svs1 =>
					vvsync := '0';
					href_time <= '0';
					if (count = VSYNC1 - 1) then
						vstate <= svs2;
						count := 0;
					else
						vstate <= svs1;
						count := count + 1;
					end if;
				when svs2 =>
					vvsync := '1';
					href_time <= '0';
					if (count = VSYNC2 - 1) then
						vstate <= svs3;
						count := 0;
					else
						vstate <= svs2;
						count := count + 1;
					end if;
				when svs3 =>
					vvsync := '1';
					href_time <= '1';
					if (count = VSYNC3 - 1) then
						vstate <= svs4;
						count := 0;
					else
						vstate <= svs3;
						count := count + 1;
					end if;
				when svs4 =>
					vvsync := '1';
					href_time <= '0';
					if (count = VSYNC4 - 1) then
          --            colorbar(0) <= std_logic_vector(shift_left(unsigned(colorbar(0)), 1));
--            colorbar(1) <= std_logic_vector(shift_left(unsigned(colorbar(1)), 1));
--            colorbar(2) <= std_logic_vector(shift_left(unsigned(colorbar(2)), 1));
--            colorbar(3) <= std_logic_vector(shift_left(unsigned(colorbar(3)), 1));
--            colorbar(4) <= std_logic_vector(shift_left(unsigned(colorbar(4)), 1));
            colorbar(4) <= colorbar(4)(0) & colorbar(4)(7 downto 1);
            colorbar(3) <= colorbar(3)(0) & colorbar(3)(7 downto 1);
            colorbar(2) <= colorbar(2)(0) & colorbar(2)(7 downto 1);
            colorbar(1) <= colorbar(1)(0) & colorbar(1)(7 downto 1);
            colorbar(0) <= colorbar(0)(0) & colorbar(0)(7 downto 1);
						vstate <= svs1;
						count := 0;
					else
						vstate <= svs4;
						count := count + 1;
					end if;
			end case;
			cam_vs <= not vvsync;
		end if;
	end process p1;

	-- generate href pulse
	-- on falling edge
	p2 : process (camera_i_rst,camera_i_xclk,href_time) is
		variable count : integer range 0 to VSYNC3 - 1;
		variable counth1 : integer range 0 to CHREF1 - 1;
		variable counth0 : integer range 0 to CHREF0 - 1;
		variable vhref : std_logic;
	begin
		if (camera_i_rst = '0') then
			count := 0;
			counth1 := 0;
			counth0 := 0;
			hhstate <= swait4vsync;
			vhref := '0';
		elsif (falling_edge(camera_i_xclk)) then
			case (hhstate) is
				when swait4vsync =>
					if (href_time = '1') then
						hhstate <= shref1;
						pixel_time <= '1';
					else
						hhstate <= swait4vsync;
						pixel_time <= '0';
					end if;
				when shref1 =>
					pixel_time <= '1';
					vhref := '1';
					if (counth1 = CHREF1 - 1) then
						pixel_time <= '0';
						hhstate <= shref0;
						counth1 := 0;
					else
						hhstate <= shref1;
						counth1 := counth1 + 1;
					end if;
				when shref0 =>
					pixel_time <= '0';
					vhref := '0';
					if (counth0 = CHREF0 - 1) then
						hhstate <= swait4vsync;
						counth0 := 0;
					else
						hhstate <= shref0;
						counth0 := counth0 + 1;
					end if;
			end case;
--			if (a = '1') then
				camera_o_hs <= vhref;
--			else
--				camera_o_hs <= '0';
--			end if;
		end if;
	end process p2;

-- Show pattern from virtual camera on VGA display
	p3 : process (camera_i_rst,camera_i_xclk,pixel_time) is
    constant CDATALENGTH : integer := 5;
    constant CNUMPIXELS : integer := CHREF1 / CDATALENGTH;
    variable count : integer range 0 to CDATALENGTH - 1;
    variable count1 : integer range 0 to CNUMPIXELS - 1;
    variable vd : std_logic_vector(7 downto 0);
	begin
		if (camera_i_rst = '0') then
			vd := (others => '0');
			hstate <= s2;
			count := 0;
      count1 := 0;
		elsif (falling_edge(camera_i_xclk)) then
       -- if (count = CDATALENGTH - 1) then
       --   count := 0;
       -- else
       --   count := count + 1;
       -- end if;
       --   if (count1 = CNUMPIXELS - 1) then
       --     count1 := 0;
       --   else
       --     vd := colorbar(count);
       --     count1 := count1 + 1;
       --   end if;
				case (hstate) is
					when s1 =>
				--		vd := colorbar(count);
				--		if (count = CDATALENGTH - 1) then
				--			count := 0;
			if (pixel_time = '1') then
							hstate <= s2;
						else
				vd := (others => '0');
        end if;
				--			count := count + 1;
				--			hstate <= s1;
				--		end if;
					when s2 =>
              vd := colorbar(count);
						if (count1 = CNUMPIXELS - 1-1) then
							hstate <= s3;
							count1 := 0;
						else
           --   if (count = CDATALENGTH-1) then
							hstate <= s2;
              count1 := count1 + 1;
          --    if (count = CDATALENGTH-1) then
          --      count := 0;
          --    else
          --      count := count + 1;
          --    end if;
						end if;
					when s3 =>
						--vd := colorbar(count);
						if (count = CDATALENGTH - 1) then
							count := 0;
							hstate <= s1;
						else
							count := count + 1;
							hstate <= s2;
						end if;
				end case;
			camera_o_d <= vd;
		end if;
	end process p3;

camera_o_pclk <= camera_i_xclk;

end Behavioral;
	-- emulate qqvga
--	pa1 : process(camera_i_rst,camera_i_xclk) is
--		constant C_MAX1 : integer := 1*tline;
--		constant C_MAX2 : integer := 3*tline;
--		variable counter1 : integer range 0 to C_MAX1 - 1;
--		variable counter2 : integer range 0 to C_MAX2 - 1;
--		type states is (sa,sb,sc);
--		variable state : states;
--	begin
--		if (camera_i_rst = '0') then
--			a <= '0';
--			counter1 := 0;
--			counter2 := 0;
--			state := sa;
--		elsif (falling_edge(camera_i_xclk)) then
--			case (state) is
--				when sa =>
--					if (pixel_time = '1') then
--						state := sb;
--					else
--						state := sa;
--					end if;
--				when sb =>
--					if (counter1 = C_MAX1 - 1) then
--						counter1 := 0;
--						state := sc;
--						a <= '0';
--					else
--						counter1 := counter1 + 1;
--						state := sb;
--						a <= '1';
--					end if;
--				when sc =>
--					a <= '0';
--					if (counter2 = C_MAX2 - 1) then
--						counter2 := 0;
--						state := sa;
--					else
--						counter2 := counter2 + 1;
--						state := sc;
--					end if;
--			end case;
--		end if;
--	end process pa1;

