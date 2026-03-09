----------------------------------------------------------------------------------
-- OV7670 -- FPGA -- VGA -- Monitor
-- The 1st revision
-- Revision : 
	-- Adjustment several entities so they can fit with the top module.
	-- Generate single clock modificator.
-- Credit:
	-- Thanks to Mike Field for Registers Reference
-- Your design might has diffent pin assignment.
-- Discuss with me by email : Jason Danny Setiawan [jasondannysetiawan@gmail.com]
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
library UNISIM;
use UNISIM.VCOMPONENTS.ALL;

use work.micron_mem_parameters.all;

entity Top_camera_monitoring is
	Port	(	clk50	: in STD_LOGIC; -- Board Crystal Oscilator 50MHz  --B8
	clkcam	: in STD_LOGIC; -- External Crystal Oscilator 23.9616 MHz  --U9
				pb		: in STD_LOGIC;
				sw		: in STD_LOGIC; -- switch camera clock
				led1 : out STD_LOGIC; -- configuration done
				-- OV7670
				ov7670_pclk1 : in  STD_LOGIC;
				ov7670_xclk1 : out STD_LOGIC;
				ov7670_vsync1 : in  STD_LOGIC;
				ov7670_href1 : in  STD_LOGIC;
				ov7670_data1 : in  STD_LOGIC_vector(7 downto 0);
				ov7670_sioc1 : out STD_LOGIC;
				ov7670_siod1 : inout STD_LOGIC;
				ov7670_pwdn1 : out STD_LOGIC;
				ov7670_reset1 : out STD_LOGIC;
        --memory module
        Dq : inout std_logic_vector (c_data_bits - 1 downto 0);
        Addr : in std_logic_vector (c_addr_bits - 1 downto 0);
        Adv_n : in std_logic;
        Ce_n : in std_logic;
        Clk : in std_logic;
        Cre : in std_logic;
        Lb_n : in std_logic;
        Oe_n : in std_logic;
        Ub_n : in std_logic;
        We_n : in std_logic;
        oWait : out std_logic;
				--VGA
        vga_clock : out STD_LOGIC;
        vga_blank : out STD_LOGIC;
				vga_hsync : out STD_LOGIC;
				vga_vsync : out STD_LOGIC;
				vga_rgb	: out STD_LOGIC_VECTOR(7 downto 0)
			 );
end Top_camera_monitoring;

architecture Structural of Top_camera_monitoring is

COMPONENT debounce_circuit
	Port ( clk : in STD_LOGIC;
			 input : in STD_LOGIC;
			 output : out STD_LOGIC);
END COMPONENT;

COMPONENT clk25gen
	Port ( clk50 : in  STD_LOGIC;
          clk25 : out  STD_LOGIC);
END COMPONENT;

COMPONENT ov7670_capture
	Port ( pclk : in  STD_LOGIC;
          vsync : in  STD_LOGIC;
          href : in  STD_LOGIC;
          d : in  STD_LOGIC_VECTOR (7 downto 0);
          addr : out  STD_LOGIC_VECTOR (18 downto 0);
          dout : out  STD_LOGIC_VECTOR (0 downto 0);
          we : out  STD_LOGIC_VECTOR (0 downto 0));
END COMPONENT;

COMPONENT ov7670_controller
	Port ( clk : in  STD_LOGIC;
          reset1 : in  STD_LOGIC;
          resend : in  STD_LOGIC;
          sioc : out  STD_LOGIC;
          siod : inout  STD_LOGIC;
          conf_done : out  STD_LOGIC;
          pwdn : out  STD_LOGIC;
			 reset: out  STD_LOGIC;
			 xclk_in : in  STD_LOGIC;
          xclk_out: out  STD_LOGIC);
END COMPONENT;

COMPONENT frame_buffer
	Port ( clkA : in STD_LOGIC;
			 weA	: in STD_LOGIC_VECTOR(0 downto 0);
			 addrA: in STD_LOGIC_VECTOR(18 downto 0);
			 dinA	: in STD_LOGIC_VECTOR(0 downto 0);
			 clkB : in STD_LOGIC;
			 addrB: in STD_LOGIC_VECTOR(18 downto 0);
			 doutB: out STD_LOGIC_VECTOR(0 downto 0));
END COMPONENT;

COMPONENT vga_imagegenerator
	Port ( Data_in1 : in  STD_LOGIC_VECTOR (0 downto 0);
						active_area1 : in  STD_LOGIC;
           RGB_out : out  STD_LOGIC_VECTOR (7 downto 0));
END COMPONENT;

COMPONENT address_generator
	Port ( clk25 : in STD_LOGIC;
			 enable : in STD_LOGIC;
			 vsync : in STD_LOGIC;
			 address : out STD_LOGIC_VECTOR (18 downto 0));
END COMPONENT;

COMPONENT VGA_timing_synch
	Port ( clk25 : in  STD_LOGIC;
           Hsync : out  STD_LOGIC;
           Vsync : out  STD_LOGIC;
           blank : out  STD_LOGIC;
           activeArea1 : out  STD_LOGIC);
END COMPONENT;

signal clk25 : STD_LOGIC;
signal resend : STD_LOGIC;

-- RAM FB
signal wren1 : STD_LOGIC_VECTOR(0 downto 0);
signal wr_d1 : STD_LOGIC_VECTOR(0 downto 0);
signal wr_a1 : STD_LOGIC_VECTOR(18 downto 0);
signal rd_d1 : STD_LOGIC_VECTOR(0 downto 0);
signal rd_a1 : STD_LOGIC_VECTOR(18 downto 0);

--VGA
signal active1 : STD_LOGIC;
signal vga_vsync_sig : STD_LOGIC;

signal cc : std_logic;
signal ov7670_pclk1_ibuf : std_logic;
signal ov7670_pclk1_inv : std_logic;

attribute IOB : string;
attribute IOB of ov7670_pclk1 : signal is "TRUE";
attribute KEEP : string;
attribute KEEP of ov7670_pclk1 : signal is "TRUE";
attribute DONT_TOUCH : string;
attribute DONT_TOUCH of ov7670_pclk1 : signal is "TRUE";

begin

	inst_clk25: clk25gen port map(
		clk50 => clk50,
		clk25 => clk25);
	
	inst_debounce: debounce_circuit port map(
		clk => clk50,
		input => pb,
		output => resend);
	
	inst_ov7670contr1: ov7670_controller port map(
		clk => clk50,
    reset1 => resend,
		resend => resend,
		sioc => ov7670_sioc1,
		siod => ov7670_siod1,
		conf_done => led1,
		pwdn => ov7670_pwdn1,
		reset => ov7670_reset1,
		xclk_in => cc,
		xclk_out => ov7670_xclk1);
	
	inst_ov7670capt1: ov7670_capture port map(
		--pclk => ov7670_pclk1_ibuf,
		pclk => ov7670_pclk1,
		vsync => ov7670_vsync1,
		href => ov7670_href1,
		d => ov7670_data1,
		addr => wr_a1,
		dout => wr_d1,
		we => wren1);
	
	inst_framebuffer1 : frame_buffer port map(
		weA => wren1,
		clkA => ov7670_pclk1,
		--clkA => ov7670_pclk1_ibuf,
		addrA => wr_a1,
		dinA => wr_d1,
		clkB => clk25,
		addrB => rd_a1,
		doutB => rd_d1);
	
	inst_addrgen1 : address_generator port map(
		clk25 => clk25,
		enable => active1,
		vsync => vga_vsync_sig,
		address => rd_a1);

	inst_imagegen : vga_imagegenerator port map(
		Data_in1 => rd_d1,
		active_area1 => active1,
		RGB_out => vga_rgb);
	
	inst_vgatiming : VGA_timing_synch port map(
		clk25 => clk25,
		Hsync => vga_hsync,
		Vsync => vga_vsync_sig,
    blank => vga_blank,
		activeArea1 => active1);
    
vga_vsync <= vga_vsync_sig;

cc <= clkcam when sw = '1' else clk25;
vga_clock <= clk25;

--ov7670_pclk1_inv <= not clk50; 

--IDDR2_inst : IDDR2
--port map (
--Q0 => ov7670_pclk1_ibuf,
--Q1 => open,
--C0 => clk50,
--C1 => ov7670_pclk1_inv,
--CE => '1',
--D => ov7670_pclk1,
--R => '0',
--S => '0'
--);
--IBUF_inst : IBUF
--   generic map (
--      IBUF_DELAY_VALUE => "0", -- Specify the amount of added input delay for buffer,
--                               -- "0"-"12" (Spartan-3E)
--      IFD_DELAY_VALUE => "AUTO", -- Specify the amount of added delay for input register,
--                                 -- "AUTO", "0"-"6"
--      IOSTANDARD => "DEFAULT")
--   port map (
--      O => ov7670_pclk1_ibuf,     -- Buffer output
--      I => ov7670_pclk1      -- Buffer input (connect directly to top-level port)
--   );
end Structural;
