----------------------------------------------------------------------------------
-- Engineer: Mike Field <hamster@snap.net.nz>
-- 
-- Description: Captures the pixels coming from the OV7670 camera and 
--              Stores them in block RAM
--
-- The length of href last controls how often pixels are captive - (2 downto 0) stores
-- one pixel every 4 cycles.
--
-- "line" is used to control how often data is captured. In this case every forth 
-- line
----------------------------------------------------------------------------------
-- This is a bit tricky href starts a pixel transfer that takes 3 cycles
         --        Input   | state after clock tick   
         --         href   | wr_hold    d_latch           dout                we address  address_next
         -- cycle -1  x    |    xx      xxxxxxxxxxxxxxxx  xxxxxxxxxxxx  x   xxxx     xxxx
         -- cycle 0   1    |    x1      xxxxxxxxRRRRRGGG  xxxxxxxxxxxx  x   xxxx     addr
         -- cycle 1   0    |    10      RRRRRGGGGGGBBBBB  xxxxxxxxxxxx  x   addr     addr
         -- cycle 2   x    |    0x      GGGBBBBBxxxxxxxx  RRRRGGGGBBBB  1   addr     addr+1
----------------------------------------------------------------------------------
-- This entity controls pixel reading and writing from camera to memory
-- The raw data is 640 x 480 pixels, 
	-- For nexys2, it is recommended to use 160 x 120
	-- href_hold is used to scale the width, it is scale by 8,
		-- because 1 pixel acquirement process needs 40ns from pclk pulse
	-- row is used to scale the vertical pixels. Divided by 4.
-----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
Library UNISIM;
use UNISIM.vcomponents.all;

entity ov7670_capture is
Generic (PIXELS : integer := 0);
    Port ( reset : in std_logic; pclk : in  STD_LOGIC;
           vsync : in  STD_LOGIC;
           href : in  STD_LOGIC;
           d : in  STD_LOGIC_VECTOR (2 downto 0);
           addr : out  STD_LOGIC_VECTOR (14 downto 0);
           dout : out  STD_LOGIC_VECTOR (2 downto 0);
           we : out  STD_LOGIC_VECTOR (0 downto 0));
end ov7670_capture;

architecture Behavioral of ov7670_capture is
   signal d_latch      : std_logic_vector((d'left+1)*2-1 downto 0) := (others => '0');
   signal address      : STD_LOGIC_VECTOR(addr'range) := (others => '0');
   signal row         : std_logic_vector(1 downto 0)  := (others => '0');
   signal href_last    : std_logic_vector(6 downto 0)  := (others => '0');
   signal we_reg       : std_logic := '0';
   signal href_hold    : std_logic := '0';
   signal latched_vsync : STD_LOGIC := '0';
   signal latched_href  : STD_LOGIC := '0';
   signal latched_d     : STD_LOGIC_VECTOR (d'range) := (others => '0');
begin
   addr <= address;
   we(0) <= we_reg;
--	 dout<= d_latch(11 downto 8) & d_latch(7 downto 4) & d_latch(3 downto 0);
--   dout<= d_latch(11) & d_latch(7) & d_latch(3);
   dout<= d_latch(2 downto 0);
	 p1 : KEEPER port map (O => d_latch(3));
	 p2 : KEEPER port map (O => d_latch(4));
	 p3 : KEEPER port map (O => d_latch(5));
--   dout<= d_latch(9) & d_latch(5) & d_latch(1);
--   dout<= d_latch(8) & d_latch(4) & d_latch(0); 
   
capture_process: process(pclk,reset)
   begin
	 if (reset = '1') then
      we_reg <= '0';
			address <= (others => '0');
			href_hold <= '0';
			row <= "00";
			d_latch <= (others => '0');
			href_last <= (others => '0');
			elsif rising_edge(pclk) then
         if we_reg = '1' then
					if (to_integer(unsigned(address)) = PIXELS-1) then
						address <= (others => '0');
					else
            address <= std_logic_vector(unsigned(address)+1);
					end if;
         end if;

         -- detect the rising edge on href - the start of the scan row
         if href_hold = '0' and latched_href = '1' then
            case row is
               when "00"   => row <= "01";
               when "01"   => row <= "10";
               when "10"   => row <= "11";
               when others => row <= "00";
            end case;
         end if;
         href_hold <= latched_href;
         
         -- capturing the data from the camera, 12-bit RGB
         if latched_href = '1' then
            d_latch(d_latch'range) <= d_latch(d'range) & latched_d;
         end if;
         we_reg  <= '0';

         -- Is a new screen about to start (i.e. we have to restart capturing
         if latched_vsync = '1' then 
            address      <= (others => '0');
            href_last    <= (others => '0');
            row         <= (others => '0');
         else
            -- If not, set the write enable whenever we need to capture a pixel
            if href_last(href_last'high) = '1' then
               if row = "10" then
                  we_reg <= '1';
               end if;
               href_last <= (others => '0');
            else
               href_last <= href_last(href_last'high-1 downto 0) & latched_href;
            end if;
         end if;
      end if;
		end process capture_process;
		
		latched_process : process(pclk,reset) is
		begin
			if (reset = '1') then
			latched_href <= '0';
			latched_d <= (others => '0');
			latched_vsync <= '0';
			elsif falling_edge(pclk) then
         latched_d     <= d;
         latched_href  <= href;
         latched_vsync <= vsync;
      end if;
   end process latched_process;
	 
end Behavioral;
