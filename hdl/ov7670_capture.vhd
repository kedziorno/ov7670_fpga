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

entity ov7670_capture is
    Port ( reset,pclk : in  STD_LOGIC;
           vsync : in  STD_LOGIC;
           href : in  STD_LOGIC;
           d : in  STD_LOGIC_VECTOR (7 downto 0);
           addr : out  STD_LOGIC_VECTOR (10 downto 0);
           dout : out  STD_LOGIC_VECTOR (15 downto 0);
           we : out  STD_LOGIC_VECTOR (0 downto 0);
           latched_vs, latched_hs : out std_logic;
           int : out std_logic := '0');
end ov7670_capture;

architecture Behavioral of ov7670_capture is
   signal d_latch      : std_logic_vector(15 downto 0) := (others => '0');
   signal address      : STD_LOGIC_VECTOR(10 downto 0) := (others => '0');
   signal row         : std_logic_vector(1 downto 0)  := (others => '0');
   signal href_last    : std_logic_vector(0 downto 0)  := (others => '0');
   signal we_reg       : std_logic := '1';
   signal href_hold    : std_logic := '0';
   signal latched_vsync : STD_LOGIC := '0';
   signal latched_href  : STD_LOGIC := '0';
   signal latched_d     : STD_LOGIC_VECTOR (7 downto 0) := (others => '0');
   signal addr1 : unsigned (9 downto 0) := (others => '0');
begin
   addr <= address;
   we(0) <= we_reg;
dout  <= d_latch;
--dout (0) <= d_latch(0);
--   dout(0)<=
--d_latch(15 )  xnor
--d_latch(14 )  xnor
--d_latch(13 )  xnor
--d_latch(12 )  xnor
--d_latch(11 )  xnor
--d_latch(10 )  xnor
--d_latch(9 )  xnor
--d_latch(8 )  xnor
--d_latch(7 )  xnor
--d_latch(6 )  xnor
--d_latch(5 )  xnor
--d_latch(4 )  xnor
--d_latch(3 )  xnor
--d_latch(2 )  xnor
--d_latch(1 )  xnor
--d_latch(0 ); 
--	 dout<= d_latch(11 downto 8) & d_latch(7 downto 4) & d_latch(3 downto 0);
--   dout<= d_latch(11) & d_latch(7) & d_latch(3);
--   dout<= d_latch(10) & d_latch(6) & d_latch(2);
--   dout<= d_latch(9) & d_latch(5) & d_latch(1);
--   dout<= d_latch(8) & d_latch(4) & d_latch(0); 
--write_process : process (pclk) is
--type states is (a, b, c);
--variable state : states := a;
--begin
--  if (falling_edge (pclk)) then
--    case (state) is
--      when a =>
--        addr1 <= (others => '0');
--        int <= '0';
--        if (latched_href = '0' and href = '1') then
--          state := b;
--        end if;
--      when b =>
--         if (addr1 = 319) then
--            addr1 <= (others => '0');
--            state := c;
--            int <= '1';
--          else
--            addr1 <= addr1 + 1;
--            int <= '0';
--          end if;
--         if (latched_vsync = '1') then
--           addr1 <= (others => '0');
--         end if;
--       when c =>
--         if (addr1 = 319) then
--            addr1 <= (others => '0');
--            state := a;
--            int <= '1';
--          else
--            addr1 <= addr1 + 1;
--            int <= '0';
--          end if;
--         if (latched_vsync = '1') then
--           addr1 <= (others => '0');
--         end if;
--    end case;
--  end if;
--end process write_process;

--int <= '1' when (addr1 = 639 or addr1 = 318-72) else '0';
--int <= '1' when (addr1 = 639 or addr1 = 318-72) else '0';
int <= '1' when (addr1 = 639) else '0';
--int <= '1' when (addr1 = 1) else '0';
capture_process: process(pclk)
   begin
      if rising_edge(pclk) then
      if (reset = '1') then
      href_hold <= '0';
      addr1 <= (others => '0');
      href_last <= (others => '0');
      row <= (others => '0');
              address <= (others => '0');

--      d_latch <= (others => '0');
      we_reg <= '0';
      else

         -- detect the rising edge on href - the start of the scan row
--         if href_hold = '0' and latched_href = '1' then
--            case row is
--               when "00"   => row <= "01";
--               when "01"   => row <= "10";
--               when "10"   => row <= "11";
--               when others => row <= "00";
--            end case;
--         end if;
         href_hold <= latched_href;
         -- capturing the data from the camera, 12-bit RGB
         if latched_href = '1' then
					if (to_integer(unsigned(address)) = 640*2-1) then
						address <= (others => '0');
					else
            address <= std_logic_vector(unsigned(address)+1);
					end if;
--         if href = '1' then
         if (addr1 = 639) then
            addr1 <= (others => '0');
          else
            addr1 <= addr1 + 1;
          end if;
         end if;
            d_latch <= d_latch(7 downto 0) & latched_d;
         we_reg  <= '0';
         if (latched_vsync = '1') then
           address      <= (others => '0');
         end if;

         -- Is a new screen about to start (i.e. we have to restart capturing
         if latched_vsync = '1' then 
--         if vsync = '1' then 
            href_last    <= (others => '0');
            row         <= (others => '0');
         else
            -- If not, set the write enable whenever we need to capture a pixel
--            if href_last(href_last'high) = '1' then
--               if row = "10" then
                  we_reg <= not we_reg;
--               end if;
--               href_last <= (others => '0');
--            else
--               href_last <= href_last(href_last'high-1 downto 0) & latched_href;
--            end if;
         end if;
         end if;
      end if;
   end process;

   latched_hs <= latched_href;
   latched_vs <= latched_vsync;
   latched_process: process (pclk) is
   begin
      if rising_edge(pclk) then
      if (reset = '1') then
--        latched_d <= (others => '0');
        latched_href <= '0';
        latched_vsync <= '0';
      else
         if href_hold = '1' then
--         if href = '1' then
--					if (to_integer(unsigned(address)) = 307200-1) then
--					if (to_integer(unsigned(address)) = 2**(address'left+1)-1) then
         end if;
         latched_d     <= d;
         latched_href  <= href;
         latched_vsync <= vsync;
      end if;
      end if;
   end process;
end Behavioral;
