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

entity top_camera_monitoring is
	Port	(	clk50	: in STD_LOGIC; -- Board Crystal Oscilator 50MHz  --B8
	--clkcam	: in STD_LOGIC; -- External Crystal Oscilator 23.9616 MHz  --U9
				pb		: in STD_LOGIC;
				--sw		: in STD_LOGIC; -- switch camera clock
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
        Addr : out std_logic_vector (c_addr_bits - 1 downto 0);
        Adv_n : out std_logic;
        Ce_n : out std_logic;
        Clk : out std_logic;
        Cre : out std_logic;
        Lb_n : out std_logic;
        Oe_n : out std_logic;
        Ub_n : out std_logic;
        We_n : out std_logic;
        oWait : in std_logic;
				--VGA
        vga_clock : out STD_LOGIC;
        vga_blank : out STD_LOGIC;
				vga_hsync : out STD_LOGIC;
				vga_vsync : out STD_LOGIC;
				vga_rgb	: out STD_LOGIC_VECTOR(7 downto 0)
			 );
end top_camera_monitoring;

architecture Structural of top_camera_monitoring is

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
          dout : out  STD_LOGIC_VECTOR (15 downto 0);
          we : out  STD_LOGIC_VECTOR (0 downto 0));
END COMPONENT;

COMPONENT ov7670_controller
	Port ( clk : in  STD_LOGIC;
          reset1 : in  STD_LOGIC;
          resend : in  STD_LOGIC;
          sioc : out  STD_LOGIC;
          siodi : in  STD_LOGIC;
          siodo : out  STD_LOGIC;
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
	Port ( Data_in1 : in  STD_LOGIC_VECTOR (15 downto 0);
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

COMPONENT ram_interface
PORT( i_clk	:	IN	STD_LOGIC;
      oe_n	:	OUT	STD_LOGIC;
      lb_n	:	OUT	STD_LOGIC;
      dq_out	:	OUT	STD_LOGIC_VECTOR (15 DOWNTO 0);
      cre	:	OUT	STD_LOGIC;
      clk	:	OUT	STD_LOGIC;
      ce_n	:	OUT	STD_LOGIC;
      adv_n	:	OUT	STD_LOGIC;
      addr	:	OUT	STD_LOGIC_VECTOR (22 DOWNTO 0);
      i_rd	:	IN	STD_LOGIC;
      i_wr	:	IN	STD_LOGIC;
      i_rst_n	:	IN	STD_LOGIC;
      addr_rd	:	IN	STD_LOGIC_VECTOR (22 DOWNTO 0);
      addr_wr	:	IN	STD_LOGIC_VECTOR (22 DOWNTO 0);
      data_wr	:	IN	STD_LOGIC_VECTOR (15 DOWNTO 0);
      dq_in	:	IN	STD_LOGIC_VECTOR (15 DOWNTO 0);
      data_rd	:	OUT	STD_LOGIC_VECTOR (15 DOWNTO 0);
      ub_n	:	OUT	STD_LOGIC;
      we_n	:	OUT	STD_LOGIC;
      owait	:	IN	STD_LOGIC);
END COMPONENT;
signal ri_ard : std_logic_vector (22 downto 0);
signal ri_awr : std_logic_vector (22 downto 0);
signal ri_drd : std_logic_vector (15 downto 0);
signal ri_dwr : std_logic_vector (15 downto 0);
signal dqi, dqo : std_logic_vector (15 downto 0);
signal ri_rd, ri_wr : std_logic;

-- RAM FB
signal wren1 : STD_LOGIC_VECTOR(0 downto 0);
signal wr_d1 : STD_LOGIC_VECTOR(15 downto 0);
signal wr_a1 : STD_LOGIC_VECTOR(18 downto 0);
signal rd_d1 : STD_LOGIC_VECTOR(15 downto 0);
signal rd_a1 : STD_LOGIC_VECTOR(18 downto 0);

--VGA
signal active1 : STD_LOGIC;
signal vga_vsync_sig : STD_LOGIC;

signal cc : std_logic;
signal ov7670_pclk1_ibuf : std_logic;
signal ov7670_pclk1_inv : std_logic;

signal we_ni, oe_ni : std_logic;
type mem_switch_states is (a, b, c, d);
signal mem_switch_state : mem_switch_states := a;

signal siodo1, siodi1 : std_logic;
signal siodo1_n : std_logic;

signal clk0, clk0_fb, clk50_ib : std_logic;
signal clk25, clk125 : std_logic;
signal resend : std_logic;

signal ov7670_pclk, pclk_i1, pclk_i2 : std_logic;
signal ov7670_d : std_logic_vector (7 downto 0);
signal ov7670_hs, ov7670_vs : std_logic;

begin

siodo1_n <= not siodi1;
   ov7670_siod1_tri : IOBUF port map (
      O => (siodi1),     -- Buffer output
      IO=> (ov7670_siod1),   -- Buffer inout port (connect directly to top-level port)
      I=> (siodo1),     -- Buffer input
      T=> (siodo1_n)      -- 3-state enable input, high=input, low=output
   );

we_n <= we_ni;
oe_n <= oe_ni;

--	inst_clk25: clk25gen port map(
--		clk50 => clk50,
--		clk25 => clk25);

	inst_debounce: debounce_circuit port map(
		clk => clk50_ib,
		input => pb,
		output => resend);
	
	inst_ov7670contr1: ov7670_controller port map(
		clk => clk25,
    reset1 => resend,
		resend => resend,
		sioc => ov7670_sioc1,
		siodi => siodi1,
		siodo => siodo1,
		conf_done => led1,
		pwdn => ov7670_pwdn1,
		reset => ov7670_reset1,
		xclk_in => clk50_ib,
		xclk_out => ov7670_xclk1);

  ri_awr <= "0000" & wr_a1;
  ri_dwr <= wr_d1;
  --ri_dwr <= "0000" & wr_d1;
  --ri_wr <= wren1(0);

--ov7670_pclk <= ov7670_pclk1;
  process (clk125, resend) is
  begin
    if (resend = '1') then
      pclk_i1 <= '0';
      pclk_i2 <= '0';
    elsif (rising_edge (clk125)) then
      ov7670_pclk <= ov7670_pclk1;
      ov7670_hs <= ov7670_href1;
      ov7670_vs <= ov7670_vsync1;
      ov7670_d <= ov7670_data1;
    end if;
  end process;

	inst_ov7670capt1: ov7670_capture port map(
		--pclk => ov7670_pclk1_ibuf,
		pclk => ov7670_pclk,
		vsync => ov7670_vs,
		href => ov7670_hs,
		d => ov7670_d,
		addr => wr_a1,
		dout => wr_d1,
		we => wren1);

  p_mem_switch : process (clk125, resend) is
  begin
    if (resend = '1') then
      mem_switch_state <= a;
    elsif (rising_edge (clk125)) then
      case (mem_switch_state) is
        when a =>
          mem_switch_state <= b;
          ri_wr <= '1'; ri_rd <= '0';
        when b =>
          mem_switch_state <= c;
          ri_wr <= '0'; ri_rd <= '0';
        when c =>
          mem_switch_state <= d;
          ri_wr <= '0'; ri_rd <= '1';
        when d =>
          mem_switch_state <= a;
          ri_wr <= '0'; ri_rd <= '0';
      end case;
    end if;
  end process p_mem_switch;

  dq  <= dqo   when (we_ni = '0' and oe_ni = '1') else (others => 'Z');
  dqi <= dq;

  fb_1 : ram_interface PORT MAP(
		i_clk => clk125,
		oe_n => oe_ni,
	  lb_n => lb_n,
		dq_out => dqo,
		cre => cre,
		clk => clk,
		ce_n => ce_n,
		adv_n => adv_n,
	  addr => addr,
		i_rd => ri_rd,
		i_wr => ri_wr,
		i_rst_n => not pb,
		addr_rd => ri_ard,
		addr_wr => ri_awr,
		data_wr => ri_dwr,
		dq_in => dqi,
		data_rd => ri_drd,
		ub_n => ub_n,
		we_n => we_ni,
		owait => owait
   );

	--inst_framebuffer1 : frame_buffer port map(
	--	weA => wren1,
	--	clkA => ov7670_pclk1,
	--	--clkA => ov7670_pclk1_ibuf,
	--	addrA => wr_a1,
	--	dinA => wr_d1,
	--	clkB => clk25,
	--	addrB => rd_a1,
	--	doutB => rd_d1);

  --ri_rd <= active1;
  ri_ard <= "0000" & rd_a1;
	inst_addrgen1 : address_generator port map(
		clk25 => clk25,
		enable => active1,
		vsync => vga_vsync_sig,
		address => rd_a1);

  rd_d1 <= ri_drd;
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

--cc <= clkcam when sw = '1' else clk25;
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

BUFG_inst : BUFG
port map (
O => clk0_fb, -- Clock buffer output
I => clk0 -- Clock buffer input
);

IBUFG_inst : IBUFG
generic map (
IOSTANDARD => "DEFAULT")
port map (
O => clk50_ib, -- Clock buffer output
I => clk50 -- Clock buffer input (connect directly to top-level port)
);

DCM_SP_inst : DCM_SP
generic map (
CLKDV_DIVIDE => 2.0, -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5
-- 7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
CLKFX_DIVIDE => 4, -- Can be any interger from 1 to 32
CLKFX_MULTIPLY => 32, -- Can be any integer from 1 to 32
CLKIN_DIVIDE_BY_2 => FALSE, -- TRUE/FALSE to enable CLKIN divide by two feature
CLKIN_PERIOD => 20.0, -- Specify period of input clock
CLKOUT_PHASE_SHIFT => "NONE", -- Specify phase shift of "NONE", "FIXED" or "VARIABLE"
CLK_FEEDBACK => "1X", -- Specify clock feedback of "NONE", "1X" or "2X"
DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", -- "SOURCE_SYNCHRONOUS", "SYSTEM_SYNCHRONOUS" or
-- an integer from 0 to 15
DLL_FREQUENCY_MODE => "LOW", -- "HIGH" or "LOW" frequency mode for DLL
DUTY_CYCLE_CORRECTION => TRUE, -- Duty cycle correction, TRUE or FALSE
PHASE_SHIFT => 0, -- Amount of fixed phase shift from -255 to 255
STARTUP_WAIT => FALSE) -- Delay configuration DONE until DCM_SP LOCK, TRUE/FALSE
port map (
CLK0 => clk0, -- 0 degree DCM CLK ouptput
CLK180 => open, -- 180 degree DCM CLK output
CLK270 => open, -- 270 degree DCM CLK output
CLK2X => open, -- 2X DCM CLK output
CLK2X180 => open, -- 2X, 180 degree DCM CLK out
CLK90 => open, -- 90 degree DCM CLK output
CLKDV => clk25, -- Divided DCM CLK out (CLKDV_DIVIDE)
CLKFX => clk125, -- DCM CLK synthesis out (M/D)
CLKFX180 => open, -- 180 degree CLK synthesis out
LOCKED => open, -- DCM LOCK status output
PSDONE => open, -- Dynamic phase adjust done output
STATUS => open, -- 8-bit DCM status bits output
CLKFB => clk0_fb, -- DCM clock feedback
CLKIN => clk50_ib, -- Clock input (from IBUFG, BUFG or DCM)
PSCLK => '0', -- Dynamic phase adjust clock input
PSEN => '0', -- Dynamic phase adjust enable input
PSINCDEC => '0', -- Dynamic phase adjust increment/decrement
RST => resend -- DCM asynchronous reset input
);

end Structural;
