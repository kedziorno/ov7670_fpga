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
Library UNISIM;
use UNISIM.vcomponents.all;

entity Top is
Generic (
G_PB_BITS : integer := 24;
G_WAIT1 : integer := 20; -- wait for reset dcm and cameras
G_FE_WAIT_BITS : integer := 20 -- sccb wait for cameras
);
	Port	(	clk50	: in STD_LOGIC; -- Crystal Oscilator 50MHz  --B8
	clkcam	: in STD_LOGIC; -- Crystal Oscilator 23.9616 MHz  --U9
				pb		: in STD_LOGIC; -- Push Button --B18
				sw		: in STD_LOGIC; -- Push Button --G18
				led1 : out STD_LOGIC; -- Indicates configuration has been done --J14
				led2 : out STD_LOGIC; -- Indicates configuration has been done --J14
				led3 : out STD_LOGIC; -- Indicates configuration has been done --J14
				led4 : out STD_LOGIC; -- Indicates configuration has been done --J14
			  anode : out std_logic_vector(3 downto 0);
				-- OV7670
				ov7670_reset1,ov7670_reset2,ov7670_reset3,ov7670_reset4  : out  STD_LOGIC;
				ov7670_pwdn1,ov7670_pwdn2,ov7670_pwdn3,ov7670_pwdn4: out  STD_LOGIC;
				ov7670_pclk1,ov7670_pclk2,ov7670_pclk3,ov7670_pclk4  : in  STD_LOGIC; -- Pmod JB8 --R16
				ov7670_xclk1,ov7670_xclk2,ov7670_xclk3,ov7670_xclk4  : out STD_LOGIC; -- Pmod JB2 --R18
				ov7670_vsync1,ov7670_vsync2,ov7670_vsync3,ov7670_vsync4 : in  STD_LOGIC; -- Pmod JB9 --T18
				ov7670_href1,ov7670_href2,ov7670_href3,ov7670_href4  : in  STD_LOGIC; -- Pmod JB3 --R15
				ov7670_data1,ov7670_data2,ov7670_data3,ov7670_data4  : in  STD_LOGIC_vector(7 downto 0);
									-- D0 : Pmod JA2 --K12 			-- D4 : Pmod JA4  --M15
									-- D1 : Pmod JA8 --L16			-- D5 : Pmod JA10 --M16
									-- D2 : Pmod JA3 --L17			-- D6 : Pmod JB1  --M13
									-- D3 : Pmod JA9 --M14			-- D7 : Pmod JB7  --P17
				ov7670_sioc1,ov7670_sioc2,ov7670_sioc3,ov7670_sioc4  : out STD_LOGIC; -- Pmod JB10 --J12
				ov7670_siod1,ov7670_siod2,ov7670_siod3,ov7670_siod4  : inout STD_LOGIC; -- Pmod JB4 --H16
				--VGA
				vga_hsync : out STD_LOGIC; --T4
				vga_vsync : out STD_LOGIC; --U3
				vga_rgb	: out STD_LOGIC_VECTOR(7 downto 0)
				-- R : R9(MSB), T8, R8
				-- G : N8, P8, P6
				-- Bc: U5, U4(LSB) 
			 );
end Top;

architecture Structural of Top is

COMPONENT debounce_circuit
Generic (PB_BITS : integer := G_PB_BITS);
	Port ( clk : in STD_LOGIC;
			 input : in STD_LOGIC;
			 output : out STD_LOGIC);
END COMPONENT;

COMPONENT ov7670_capture
Generic (PIXELS : integer := 307200);
	Port ( reset : in std_logic; pclk : in  STD_LOGIC;
          vsync : in  STD_LOGIC;
          href : in  STD_LOGIC;
          d : in  STD_LOGIC_VECTOR (7 downto 0);
          addr : out  STD_LOGIC_VECTOR (18 downto 0);
          dout : out  STD_LOGIC_VECTOR (0 downto 0);
          we : out  STD_LOGIC_VECTOR (0 downto 0));
END COMPONENT;

component ov7670_registers
	Port ( reset : in std_logic; clk : in  STD_LOGIC;
          resend : in  STD_LOGIC;
          advance : in  STD_LOGIC;
          command : out  STD_LOGIC_VECTOR (15 downto 0);
          done : out  STD_LOGIC);
end component;

component ov7670_SCCB
Generic (FE_WAIT_BITS : integer := G_FE_WAIT_BITS);
	Port ( reset : in std_logic; clk : in  STD_LOGIC;
          reg_value : in  STD_LOGIC_VECTOR (7 downto 0);
          slave_addr : in  STD_LOGIC_VECTOR (7 downto 0);
          addr_reg : in  STD_LOGIC_VECTOR (7 downto 0);
          send : in  STD_LOGIC;
          siod : inout  STD_LOGIC;
          sioc : out  STD_LOGIC;
          taken : out  STD_LOGIC);
end component;	

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
	Port ( reset : in std_logic; clk : std_logic; Data_in1 : in  STD_LOGIC_VECTOR (0 downto 0);
						Data_in2 : in  STD_LOGIC_VECTOR (0 downto 0);
						Data_in3 : in  STD_LOGIC_VECTOR (0 downto 0);
						Data_in4 : in  STD_LOGIC_VECTOR (0 downto 0);
						active_area1 : in  STD_LOGIC;
						active_area2 : in  STD_LOGIC;
						active_area3 : in  STD_LOGIC;
						active_area4 : in  STD_LOGIC;
           RGB_out : out  STD_LOGIC_VECTOR (7 downto 0));
END COMPONENT;

COMPONENT address_generator
Generic (PIXELS : integer := 307200);
	Port ( reset : in std_logic; clk25 : in STD_LOGIC;
			 enable : in STD_LOGIC;
			 vsync : in STD_LOGIC;
			 address : out STD_LOGIC_VECTOR (18 downto 0));
END COMPONENT;

COMPONENT VGA_timing_synch
	Port ( reset : in std_logic; clk25 : in  STD_LOGIC;
           Hsync : out  STD_LOGIC;
           Vsync : out  STD_LOGIC;
           activeArea1 : out  STD_LOGIC;
           activeArea2 : out  STD_LOGIC;
           activeArea3 : out  STD_LOGIC;
           activeArea4 : out  STD_LOGIC);
END COMPONENT;

signal clk25 : STD_LOGIC;
signal resend : STD_LOGIC;

-- RAM
signal wren1,wren2,wren3,wren4 : STD_LOGIC_VECTOR(0 downto 0);
signal wr_d1,wr_d2,wr_d3,wr_d4 : STD_LOGIC_VECTOR(0 downto 0);
signal wr_a1,wr_a2,wr_a3,wr_a4 : STD_LOGIC_VECTOR(18 downto 0);
signal rd_d1,rd_d2,rd_d3,rd_d4 : STD_LOGIC_VECTOR(0 downto 0);
signal rd_a1,rd_a2,rd_a3,rd_a4 : STD_LOGIC_VECTOR(18 downto 0);

--VGA
signal active1,active2,active3,active4 : STD_LOGIC;
signal vga_vsync_sig : STD_LOGIC;

signal cc : std_logic;

constant camera_address : std_logic_vector(7 downto 0) := x"42"; -- Device write ID, see pg.10. (OV datasheet)

signal camera1,camera2,camera3,camera4 : std_logic;
signal command : std_logic_vector(15 downto 0);
signal sioc,siod : std_logic;
signal send,done,taken : std_logic;
signal resend1,resend2 : std_logic;

signal ov7670_pclk1buf,ov7670_pclk2buf,ov7670_pclk3buf,ov7670_pclk4buf  : std_logic;
signal clkcambuf,clk50buf : std_logic;

signal ov7670_pclk1buf1,ov7670_pclk2buf1,ov7670_pclk3buf1,ov7670_pclk4buf1 : std_logic;

signal clock1a,clock1b,clock2a,clock2b : std_logic;
signal clock3a,clock3b,clock4a,clock4b : std_logic;
signal clock5a,clock5b,clock6a,clock6b : std_logic;

signal resetdcm,resetdcm1 : std_logic;

--attribute IOB : string;
--attribute IOB of ov7670_data1,ov7670_data2,ov7670_data3,ov7670_data4 : signal is "TRUE";
--attribute IOB of ov7670_href1,ov7670_href2,ov7670_href3,ov7670_href4 : signal is "TRUE";
--attribute IOB of ov7670_vsync1,ov7670_vsync2,ov7670_vsync3,ov7670_vsync4: signal is "TRUE";

begin

--	vga_rgb <= (others => '0');
--	vga_hsync <= '0';
--	vga_vsync <= '0';
--	pclk1buf : IBUFG port map (O => ov7670_pclk1buf, I => ov7670_pclk1);
--	pclk2buf : IBUFG port map (O => ov7670_pclk2buf, I => ov7670_pclk2);
--	pclk3buf : IBUFG port map (O => ov7670_pclk3buf, I => ov7670_pclk3);
--	pclk4buf : IBUFG port map (O => ov7670_pclk4buf, I => ov7670_pclk4);
--	pclk1buf : ov7670_pclk1buf <= ov7670_pclk1;
--	pclk2buf : ov7670_pclk2buf <= ov7670_pclk2;
--	pclk3buf : ov7670_pclk3buf <= ov7670_pclk3;
--	pclk4buf : ov7670_pclk4buf <= ov7670_pclk4;

	anode <= "1111";

	led1 <= ov7670_data1(0) or ov7670_data1(1) or ov7670_data1(2) or ov7670_data1(3) or ov7670_data1(4) or ov7670_data1(5) or ov7670_data1(6) or ov7670_data1(7);
	led2 <= wr_a1(17) or wr_a1(16) or wr_a1(15) or wr_a1(14) or wr_a1(13) or wr_a1(12) or wr_a1(11) or wr_a1(10) or wr_a1(9) or wr_a1(8) or 
	wr_a1(7) or wr_a1(6) or wr_a1(5) or wr_a1(4) or wr_a1(3) or wr_a1(2) or wr_a1(1) or wr_a1(0) ;
	led3 <= wr_d1(0);
	led4 <= wren1(0);

--	led1 <= '0';
--	led2 <= '0';
--	led3 <= '0';
--	led4 <= '0';

--	inst_clk25: clk25gen port map(
--		reset => resend,
--		clk50 => clk50buf,
--		clk25 => clk25);
	
	inst_debounce: debounce_circuit port map(
		clk => clkcambuf,
		input => pb,
		output => resend);

--	ov7670_pclk1buf1 <= ov7670_pclk1buf;
--	ov7670_pclk2buf1 <= ov7670_pclk2buf;
--	ov7670_pclk3buf1 <= ov7670_pclk3buf;
--	ov7670_pclk4buf1 <= ov7670_pclk4buf;

	inst_ov7670capt1: ov7670_capture port map(
		reset => resend,
		pclk => ov7670_pclk1buf1,
		vsync => ov7670_vsync1,
		href => ov7670_href1,
		d => ov7670_data1,
		addr => wr_a1,
		dout => wr_d1,
		we => wren1);
--	inst_ov7670capt2: ov7670_capture port map(
--		reset => resend,
--		pclk => ov7670_pclk2buf1,
--		vsync => ov7670_vsync2,
--		href => ov7670_href2,
--		d => ov7670_data2,
--		addr => wr_a2,
--		dout => wr_d2,
--		we => wren2);
--	inst_ov7670capt3: ov7670_capture port map(
--		reset => resend,
--		pclk => ov7670_pclk3buf1,
--		vsync => ov7670_vsync3,
--		href => ov7670_href3,
--		d => ov7670_data3,
--		addr => wr_a3,
--		dout => wr_d3,
--		we => wren3);
--	inst_ov7670capt4: ov7670_capture port map(
--		reset => resend,
--		pclk => ov7670_pclk4buf1,
--		vsync => ov7670_vsync4,
--		href => ov7670_href4,
--		d => ov7670_data4,
--		addr => wr_a4,
--		dout => wr_d4,
--		we => wren4);
	
	inst_framebuffer1 : frame_buffer port map(
		weA => wren1,
		clkA => ov7670_pclk1buf1,
		addrA => wr_a1,
		dinA => wr_d1,
		clkB => clk25,
		addrB => rd_a1,
		doutB => rd_d1);
--	inst_framebuffer2 : frame_buffer port map(
--		weA => wren2,
--		clkA => ov7670_pclk2buf1,
--		addrA => wr_a2,
--		dinA => wr_d2,
--		clkB => clk25,
--		addrB => rd_a2,
--		doutB => rd_d2);
--	inst_framebuffer3 : frame_buffer port map(
--		weA => wren3,
--		clkA => ov7670_pclk3buf1,
--		addrA => wr_a3,
--		dinA => wr_d3,
--		clkB => clk25,
--		addrB => rd_a3,
--		doutB => rd_d3);
--	inst_framebuffer4 : frame_buffer port map(
--		weA => wren4,
--		clkA => ov7670_pclk4buf1,
--		addrA => wr_a4,
--		dinA => wr_d4,
--		clkB => clk25,
--		addrB => rd_a4,
--		doutB => rd_d4);
	
	inst_addrgen1 : address_generator port map(
		reset => resend,
		clk25 => clk25,
		enable => active1,
		vsync => vga_vsync_sig,
		address => rd_a1);
--	inst_addrgen2 : address_generator port map(
--		reset => resend,
--		clk25 => clk25,
--		enable => active2,
--		vsync => vga_vsync_sig,
--		address => rd_a2);
--	inst_addrgen3 : address_generator port map(
--		reset => resend,
--		clk25 => clk25,
--		enable => active3,
--		vsync => vga_vsync_sig,
--		address => rd_a3);
--	inst_addrgen4 : address_generator port map(
--		reset => resend,
--		clk25 => clk25,
--		enable => active4,
--		vsync => vga_vsync_sig,
--		address => rd_a4);

	inst_imagegen : vga_imagegenerator port map(
		reset => resend,
		clk => clk25,
		Data_in1 => rd_d1,
		Data_in2 => rd_d2,
		Data_in3 => rd_d3,
		Data_in4 => rd_d4,
		active_area1 => active1,
		active_area2 => active2,
		active_area3 => active3,
		active_area4 => active4,
		RGB_out => vga_rgb);
	
	inst_vgatiming : VGA_timing_synch port map(
		reset => resend,
		clk25 => clk25,
		Hsync => vga_hsync,
		Vsync => vga_vsync_sig,
		activeArea1 => active1,
		activeArea2 => active2,
		activeArea3 => active3,
		activeArea4 => active4);

vga_vsync <= vga_vsync_sig;

Registers: ov7670_registers port map(
	reset => resend,
	clk => clkcambuf,
	resend => resend1,
	advance => taken,
	command => command,
	done => done);

SCCB : ov7670_SCCB port map(
	reset => resend,
	clk => clkcambuf,
	reg_value => command (7 downto 0),
	slave_addr => camera_address,
	addr_reg => command (15 downto 8),
	send => send,
	sioc => sioc,
	siod => siod,
	taken => taken);

resend1 <= resend or resend2;

p0initcam : process(clkcambuf,resend) is
	type states is (idle,wait4dcm,wait4dcmpclk,sa,sa1,sb,sb1,sc,sc1,sd,sd1,se);
	variable state : states := idle;
	constant C_MAX : integer := 8192; -- XXX wait between cameras
	variable counter : integer range 0 to C_MAX-1;
	constant C_W4DCM : integer := 2**G_WAIT1;
	variable w4dcmcnt : integer range 0 to C_W4DCM-1;
begin
	if (resend = '1') then
		state := idle;
		send <= '0';
		resend2 <= '0';
		counter := 0;
		resetdcm <= '0';
		resetdcm1 <= '0';
		w4dcmcnt := 0;
	elsif (rising_edge(clkcambuf)) then
		case (state) is
			when idle =>
--				if (resend = '1') then
					state := wait4dcm;
--				else
--					state := idle;
--					send <= '0';
--					resend2 <= '0';
--				end if;
				camera1 <= '0';
				camera2 <= '0';
				camera3 <= '0';
				camera4 <= '0';
				counter := 0;
				w4dcmcnt := 0;
				resetdcm <= '0';
				resetdcm1 <= '0';
			when wait4dcm =>
				if (w4dcmcnt = C_W4DCM-1) then
					resetdcm <= '0';
					w4dcmcnt := 0;
					state := sa;
				else
					resetdcm <= '1';
					w4dcmcnt := w4dcmcnt + 1;
					state := wait4dcm;
				end if;
			when sa =>
				resetdcm <= '0';
				resetdcm1 <= '0';
				counter := 0;
				if (done = '1') then
					state := sa1;
					send <= '0';
					resend2 <= '1';
				else
					state := sa;
					send <= '1';
					resend2 <= '0';
				end if;
				camera1 <= '1';
				camera2 <= '0';
				camera3 <= '0';
				camera4 <= '0';
			when sa1 =>
				if (counter = C_MAX-1) then
--					state := sb;
					state := wait4dcmpclk ;
					counter := 0;
					resend2 <= '1';
				else
					state := sa1;
					counter := counter + 1;
					resend2 <= '0';
				end if;
			when wait4dcmpclk =>
				if (w4dcmcnt = C_W4DCM-1) then
					resetdcm1 <= '0';
					w4dcmcnt := 0;
					state := se;
					send <= '0';
					resend2 <= '1';
				else
					resetdcm1 <= '1';
					w4dcmcnt := w4dcmcnt + 1;
					state := wait4dcmpclk;
				end if;
			when sb =>
				if (done = '1') then
					state := sb1;
					send <= '0';
					resend2 <= '1';
				else
					state := sb;
					send <= '1';
					resend2 <= '0';
				end if;
				camera1 <= '0';
				camera2 <= '1';
				camera3 <= '0';
				camera4 <= '0';
			when sb1 =>
				if (counter = C_MAX-1) then
					state := sc;
					counter := 0;
					resend2 <= '1';
				else
					state := sb1;
					counter := counter + 1;
					resend2 <= '0';
				end if;
			when sc =>
				if (done = '1') then
					state := sc1;
					send <= '0';
					resend2 <= '1';
				else
					state := sc;
					send <= '1';
					resend2 <= '0';
				end if;
				camera1 <= '0';
				camera2 <= '0';
				camera3 <= '1';
				camera4 <= '0';
			when sc1 =>
				if (counter = C_MAX-1) then
					state := sd;
					counter := 0;
					resend2 <= '1';
				else
					state := sc1;
					counter := counter + 1;
					resend2 <= '0';
				end if;
			when sd =>
				if (done = '1') then
					state := sd1;
					send <= '0';
					resend2 <= '1';
				else
					state := sd;
					send <= '1';
					resend2 <= '0';
				end if;
				camera1 <= '0';
				camera2 <= '0';
				camera3 <= '0';
				camera4 <= '1';
			when sd1 =>
				if (counter = C_MAX-1) then
					state := se;
					counter := 0;
					resend2 <= '1';
				else
					state := sd1;
					counter := counter + 1;
					resend2 <= '0';
				end if;
			when se =>
				state := se;
				camera1 <= '0';
				camera2 <= '0';
				camera3 <= '0';
				camera4 <= '0';
				send <= '0';
				resend2 <= '0';
			when others =>
				state := idle;
		end case;
	end if;
end process p0initcam;

ov7670_sioc1 <= sioc when camera1 = '1' else '1';
ov7670_siod1 <= siod when camera1 = '1' else '1';
ov7670_sioc2 <= '0';
ov7670_siod2 <= '0';
ov7670_sioc3 <= '0';
ov7670_siod3 <= '0';
ov7670_sioc4 <= '0';
ov7670_siod4 <= '0';
--ov7670_sioc2 <= sioc when camera2 = '1' else '1';
--ov7670_siod2 <= siod when camera2 = '1' else '1';
--ov7670_sioc3 <= sioc when camera3 = '1' else '1';
--ov7670_siod3 <= siod when camera3 = '1' else '1';
--ov7670_sioc4 <= sioc when camera4 = '1' else '1';
--ov7670_siod4 <= siod when camera4 = '1' else '1';

OBUF_xclk1 : OBUF port map (O => ov7670_xclk1, I => cc);
OBUF_xclk2 : ov7670_xclk2 <= '0';
OBUF_xclk3 : ov7670_xclk3 <= '0';
OBUF_xclk4 : ov7670_xclk4 <= '0';
--OBUF_xclk2 : OBUF port map (O => ov7670_xclk2, I => cc);
--OBUF_xclk3 : OBUF port map (O => ov7670_xclk3, I => cc);
--OBUF_xclk4 : OBUF port map (O => ov7670_xclk4, I => cc);

ov7670_reset1 <= '0' when resetdcm = '1' else '1';
ov7670_reset2 <= '1';
ov7670_reset3 <= '1';
ov7670_reset4 <= '1';
--ov7670_reset2 <= '0' when resetdcm = '1' else '1';
--ov7670_reset3 <= '0' when resetdcm = '1' else '1';
--ov7670_reset4 <= '0' when resetdcm = '1' else '1';

ov7670_pwdn1 <= '1' when resetdcm = '1' else '0';
ov7670_pwdn2 <= '0';
ov7670_pwdn3 <= '0';
ov7670_pwdn4 <= '0';
--ov7670_pwdn2 <= '1' when resetdcm = '1' else '0';
--ov7670_pwdn3 <= '1' when resetdcm = '1' else '0';
--ov7670_pwdn4 <= '1' when resetdcm = '1' else '0';

--cc <= clkcambuf when sw = '1' else clk25;

DCM_vga : DCM
generic map (
CLKDV_DIVIDE => 4.0, -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5,7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
CLKFX_DIVIDE => 32, -- Can be any interger from 1 to 32
CLKFX_MULTIPLY => 32, -- Can be any integer from 1 to 32
CLKIN_DIVIDE_BY_2 => FALSE, -- TRUE/FALSE to enable CLKIN divide by two feature
CLKIN_PERIOD => 10.0, -- Specify period of input clock
CLKOUT_PHASE_SHIFT => "NONE", -- Specify phase shift of NONE, FIXED or VARIABLE
CLK_FEEDBACK => "1X", -- Specify clock feedback of NONE, 1X or 2X
DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", -- SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or an integer from 0 to 15
DFS_FREQUENCY_MODE => "LOW", -- HIGH or LOW frequency mode for frequency synthesis
DLL_FREQUENCY_MODE => "LOW", -- HIGH or LOW frequency mode for DLL
DUTY_CYCLE_CORRECTION => TRUE, -- Duty cycle correction, TRUE or FALSE
FACTORY_JF => X"C080", -- FACTORY JF Values
PHASE_SHIFT => 0, -- Amount of fixed phase shift from -255 to 255
SIM_MODE => "SAFE", -- Simulation: "SAFE" vs "FAST", see "Synthesis and Simulation
STARTUP_WAIT => FALSE) -- Delay configuration DONE until DCM LOCK, TRUE/FALSE
port map (
CLK0 => clock1a, -- 0 degree DCM CLK ouptput
CLK180 => open, -- 180 degree DCM CLK output
CLK270 => open, -- 270 degree DCM CLK output
CLK2X => open, -- 2X DCM CLK output
CLK2X180 => open, -- 2X, 180 degree DCM CLK out
CLK90 => open, -- 90 degree DCM CLK output
CLKDV => clk25, -- Divided DCM CLK out (CLKDV_DIVIDE)
CLKFX => open, -- DCM CLK synthesis out (M/D)
CLKFX180 => open, -- 180 degree CLK synthesis out
LOCKED => open, -- DCM LOCK status output
PSDONE => open, -- Dynamic phase adjust done output
STATUS => open, -- 8-bit DCM status bits output
CLKFB => clock1b, -- DCM clock feedback
CLKIN => clkcambuf, -- Clock input (from IBUFG, BUFG or DCM)
PSCLK => '0', -- Dynamic phase adjust clock input
PSEN => '0', -- Dynamic phase adjust enable input
PSINCDEC => '0', -- Dynamic phase adjust increment/decrement
RST => resetdcm -- DCM asynchronous reset input
);
vga_bufa : IBUFG generic map (IOSTANDARD => "DEFAULT") port map (O => clkcambuf, I => clkcam);
vga_bufb : BUFG port map (O => clock1b, I => clock1a);

DCM_cam : DCM
generic map (
CLKDV_DIVIDE => 2.0, -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5,7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
CLKFX_DIVIDE => 25, -- Can be any interger from 1 to 32
--CLKFX_MULTIPLY => 6, -- Can be any integer from 1 to 32 -- 24mhz
CLKFX_MULTIPLY => 12, -- Can be any integer from 1 to 32 -- 48mhz
CLKIN_DIVIDE_BY_2 => FALSE, -- TRUE/FALSE to enable CLKIN divide by two feature
CLKIN_PERIOD => 10.0, -- Specify period of input clock
CLKOUT_PHASE_SHIFT => "NONE", -- Specify phase shift of NONE, FIXED or VARIABLE
CLK_FEEDBACK => "1X", -- Specify clock feedback of NONE, 1X or 2X
DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", -- SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or an integer from 0 to 15
DFS_FREQUENCY_MODE => "LOW", -- HIGH or LOW frequency mode for frequency synthesis
DLL_FREQUENCY_MODE => "LOW", -- HIGH or LOW frequency mode for DLL
DUTY_CYCLE_CORRECTION => TRUE, -- Duty cycle correction, TRUE or FALSE
FACTORY_JF => X"C080", -- FACTORY JF Values
PHASE_SHIFT => 0, -- Amount of fixed phase shift from -255 to 255
SIM_MODE => "SAFE", -- Simulation: "SAFE" vs "FAST", see "Synthesis and Simulation
STARTUP_WAIT => FALSE) -- Delay configuration DONE until DCM LOCK, TRUE/FALSE
port map (
CLK0 => clock2a, -- 0 degree DCM CLK ouptput
CLK180 => open, -- 180 degree DCM CLK output
CLK270 => open, -- 270 degree DCM CLK output
CLK2X => open, -- 2X DCM CLK output
CLK2X180 => open, -- 2X, 180 degree DCM CLK out
CLK90 => open, -- 90 degree DCM CLK output
CLKDV => open, -- Divided DCM CLK out (CLKDV_DIVIDE)
CLKFX => cc, -- DCM CLK synthesis out (M/D)
CLKFX180 => open, -- 180 degree CLK synthesis out
LOCKED => open, -- DCM LOCK status output
PSDONE => open, -- Dynamic phase adjust done output
STATUS => open, -- 8-bit DCM status bits output
CLKFB => clock2b, -- DCM clock feedback
CLKIN => clk50buf, -- Clock input (from IBUFG, BUFG or DCM)
PSCLK => '0', -- Dynamic phase adjust clock input
PSEN => '0', -- Dynamic phase adjust enable input
PSINCDEC => '0', -- Dynamic phase adjust increment/decrement
RST => resetdcm -- DCM asynchronous reset input
);
cam_bufa : BUFG port map (O => clk50buf, I => clkcambuf);
cam_bufb : BUFG port map (O => clock2b, I => clock2a);

DCM_pclk1 : DCM
generic map (
CLKDV_DIVIDE => 2.0, -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5,7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
CLKFX_DIVIDE => 2, -- Can be any interger from 1 to 32
CLKFX_MULTIPLY => 2, -- Can be any integer from 1 to 32
CLKIN_DIVIDE_BY_2 => FALSE, -- TRUE/FALSE to enable CLKIN divide by two feature
CLKIN_PERIOD => 41.667, -- Specify period of input clock
CLKOUT_PHASE_SHIFT => "NONE", -- Specify phase shift of NONE, FIXED or VARIABLE
CLK_FEEDBACK => "1X", -- Specify clock feedback of NONE, 1X or 2X
DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", -- SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or an integer from 0 to 15
DFS_FREQUENCY_MODE => "LOW", -- HIGH or LOW frequency mode for frequency synthesis
DLL_FREQUENCY_MODE => "LOW", -- HIGH or LOW frequency mode for DLL
DUTY_CYCLE_CORRECTION => TRUE, -- Duty cycle correction, TRUE or FALSE
FACTORY_JF => X"C080", -- FACTORY JF Values
PHASE_SHIFT => 0, -- Amount of fixed phase shift from -255 to 255
SIM_MODE => "SAFE", -- Simulation: "SAFE" vs "FAST", see "Synthesis and Simulation
STARTUP_WAIT => TRUE) -- Delay configuration DONE until DCM LOCK, TRUE/FALSE
port map (
CLK0 => clock3a, -- 0 degree DCM CLK ouptput
CLK180 => open, -- 180 degree DCM CLK output
CLK270 => open, -- 270 degree DCM CLK output
CLK2X => open, -- 2X DCM CLK output
CLK2X180 => open, -- 2X, 180 degree DCM CLK out
CLK90 => open, -- 90 degree DCM CLK output
CLKDV => open, -- Divided DCM CLK out (CLKDV_DIVIDE)
CLKFX => open, -- DCM CLK synthesis out (M/D)
CLKFX180 => open, -- 180 degree CLK synthesis out
LOCKED => open, -- DCM LOCK status output
PSDONE => open, -- Dynamic phase adjust done output
STATUS => open, -- 8-bit DCM status bits output
CLKFB => clock3b, -- DCM clock feedback
CLKIN => ov7670_pclk1buf, -- Clock input (from IBUFG, BUFG or DCM)
PSCLK => '0', -- Dynamic phase adjust clock input
PSEN => '0', -- Dynamic phase adjust enable input
PSINCDEC => '0', -- Dynamic phase adjust increment/decrement
RST => resetdcm1 -- DCM asynchronous reset input
);
pclk1_bufa : IBUFG generic map (IOSTANDARD => "DEFAULT") port map (O => ov7670_pclk1buf, I => ov7670_pclk1);
pclk1_buf : BUFG port map (O => clock3b, I => clock3a);
ov7670_pclk1buf1 <= clock3b;
--	
--DCM_pclk2 : DCM
--generic map (
--CLKDV_DIVIDE => 2.0, -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5,7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
--CLKFX_DIVIDE => 2, -- Can be any interger from 1 to 32
--CLKFX_MULTIPLY => 2, -- Can be any integer from 1 to 32
--CLKIN_DIVIDE_BY_2 => FALSE, -- TRUE/FALSE to enable CLKIN divide by two feature
--CLKIN_PERIOD => 41.667, -- Specify period of input clock
--CLKOUT_PHASE_SHIFT => "NONE", -- Specify phase shift of NONE, FIXED or VARIABLE
--CLK_FEEDBACK => "1X", -- Specify clock feedback of NONE, 1X or 2X
--DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", -- SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or an integer from 0 to 15
--DFS_FREQUENCY_MODE => "LOW", -- HIGH or LOW frequency mode for frequency synthesis
--DLL_FREQUENCY_MODE => "LOW", -- HIGH or LOW frequency mode for DLL
--DUTY_CYCLE_CORRECTION => TRUE, -- Duty cycle correction, TRUE or FALSE
--FACTORY_JF => X"C080", -- FACTORY JF Values
--PHASE_SHIFT => 0, -- Amount of fixed phase shift from -255 to 255
--SIM_MODE => "SAFE", -- Simulation: "SAFE" vs "FAST", see "Synthesis and Simulation
--STARTUP_WAIT => TRUE) -- Delay configuration DONE until DCM LOCK, TRUE/FALSE
--port map (
--CLK0 => clock4a, -- 0 degree DCM CLK ouptput
--CLK180 => open, -- 180 degree DCM CLK output
--CLK270 => open, -- 270 degree DCM CLK output
--CLK2X => open, -- 2X DCM CLK output
--CLK2X180 => open, -- 2X, 180 degree DCM CLK out
--CLK90 => open, -- 90 degree DCM CLK output
--CLKDV => open, -- Divided DCM CLK out (CLKDV_DIVIDE)
--CLKFX => open, -- DCM CLK synthesis out (M/D)
--CLKFX180 => open, -- 180 degree CLK synthesis out
--LOCKED => open, -- DCM LOCK status output
--PSDONE => open, -- Dynamic phase adjust done output
--STATUS => open, -- 8-bit DCM status bits output
--CLKFB => clock4b, -- DCM clock feedback
--CLKIN => ov7670_pclk2buf, -- Clock input (from IBUFG, BUFG or DCM)
--PSCLK => '0', -- Dynamic phase adjust clock input
--PSEN => '0', -- Dynamic phase adjust enable input
--PSINCDEC => '0', -- Dynamic phase adjust increment/decrement
--RST => resetdcm1 -- DCM asynchronous reset input
--);
--pclk2_bufa : IBUFG generic map (IOSTANDARD => "DEFAULT") port map (O => ov7670_pclk2buf, I => ov7670_pclk2);
--pclk2_buf : BUFG port map (O => clock4b, I => clock4a);
--ov7670_pclk2buf1 <= clock4b;
--
--DCM_pclk3 : DCM
--generic map (
--CLKDV_DIVIDE => 2.0, -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5,7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
--CLKFX_DIVIDE => 2, -- Can be any interger from 1 to 32
--CLKFX_MULTIPLY => 2, -- Can be any integer from 1 to 32
--CLKIN_DIVIDE_BY_2 => FALSE, -- TRUE/FALSE to enable CLKIN divide by two feature
--CLKIN_PERIOD => 41.667, -- Specify period of input clock
--CLKOUT_PHASE_SHIFT => "NONE", -- Specify phase shift of NONE, FIXED or VARIABLE
--CLK_FEEDBACK => "1X", -- Specify clock feedback of NONE, 1X or 2X
--DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", -- SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or an integer from 0 to 15
--DFS_FREQUENCY_MODE => "LOW", -- HIGH or LOW frequency mode for frequency synthesis
--DLL_FREQUENCY_MODE => "LOW", -- HIGH or LOW frequency mode for DLL
--DUTY_CYCLE_CORRECTION => TRUE, -- Duty cycle correction, TRUE or FALSE
--FACTORY_JF => X"C080", -- FACTORY JF Values
--PHASE_SHIFT => 0, -- Amount of fixed phase shift from -255 to 255
--SIM_MODE => "SAFE", -- Simulation: "SAFE" vs "FAST", see "Synthesis and Simulation
--STARTUP_WAIT => TRUE) -- Delay configuration DONE until DCM LOCK, TRUE/FALSE
--port map (
--CLK0 => clock5a, -- 0 degree DCM CLK ouptput
--CLK180 => open, -- 180 degree DCM CLK output
--CLK270 => open, -- 270 degree DCM CLK output
--CLK2X => open, -- 2X DCM CLK output
--CLK2X180 => open, -- 2X, 180 degree DCM CLK out
--CLK90 => open, -- 90 degree DCM CLK output
--CLKDV => open, -- Divided DCM CLK out (CLKDV_DIVIDE)
--CLKFX => open, -- DCM CLK synthesis out (M/D)
--CLKFX180 => open, -- 180 degree CLK synthesis out
--LOCKED => open, -- DCM LOCK status output
--PSDONE => open, -- Dynamic phase adjust done output
--STATUS => open, -- 8-bit DCM status bits output
--CLKFB => clock5b, -- DCM clock feedback
--CLKIN => ov7670_pclk3buf, -- Clock input (from IBUFG, BUFG or DCM)
--PSCLK => '0', -- Dynamic phase adjust clock input
--PSEN => '0', -- Dynamic phase adjust enable input
--PSINCDEC => '0', -- Dynamic phase adjust increment/decrement
--RST => resetdcm1 -- DCM asynchronous reset input
--);
--pclk3_bufa : IBUFG generic map (IOSTANDARD => "DEFAULT") port map (O => ov7670_pclk3buf, I => ov7670_pclk3);
--pclk3_buf : BUFG port map (O => clock5b, I => clock5a);
--ov7670_pclk3buf1 <= clock5b;
--
--DCM_pclk4 : DCM
--generic map (
--CLKDV_DIVIDE => 2.0, -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5,7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
--CLKFX_DIVIDE => 2, -- Can be any interger from 1 to 32
--CLKFX_MULTIPLY => 2, -- Can be any integer from 1 to 32
--CLKIN_DIVIDE_BY_2 => FALSE, -- TRUE/FALSE to enable CLKIN divide by two feature
--CLKIN_PERIOD => 41.667, -- Specify period of input clock
--CLKOUT_PHASE_SHIFT => "NONE", -- Specify phase shift of NONE, FIXED or VARIABLE
--CLK_FEEDBACK => "1X", -- Specify clock feedback of NONE, 1X or 2X
--DESKEW_ADJUST => "SYSTEM_SYNCHRONOUS", -- SOURCE_SYNCHRONOUS, SYSTEM_SYNCHRONOUS or an integer from 0 to 15
--DFS_FREQUENCY_MODE => "LOW", -- HIGH or LOW frequency mode for frequency synthesis
--DLL_FREQUENCY_MODE => "LOW", -- HIGH or LOW frequency mode for DLL
--DUTY_CYCLE_CORRECTION => TRUE, -- Duty cycle correction, TRUE or FALSE
--FACTORY_JF => X"C080", -- FACTORY JF Values
--PHASE_SHIFT => 0, -- Amount of fixed phase shift from -255 to 255
--SIM_MODE => "SAFE", -- Simulation: "SAFE" vs "FAST", see "Synthesis and Simulation
--STARTUP_WAIT => TRUE) -- Delay configuration DONE until DCM LOCK, TRUE/FALSE
--port map (
--CLK0 => clock6a, -- 0 degree DCM CLK ouptput
--CLK180 => open, -- 180 degree DCM CLK output
--CLK270 => open, -- 270 degree DCM CLK output
--CLK2X => open, -- 2X DCM CLK output
--CLK2X180 => open, -- 2X, 180 degree DCM CLK out
--CLK90 => open, -- 90 degree DCM CLK output
--CLKDV => open, -- Divided DCM CLK out (CLKDV_DIVIDE)
--CLKFX => open, -- DCM CLK synthesis out (M/D)
--CLKFX180 => open, -- 180 degree CLK synthesis out
--LOCKED => open, -- DCM LOCK status output
--PSDONE => open, -- Dynamic phase adjust done output
--STATUS => open, -- 8-bit DCM status bits output
--CLKFB => clock6b, -- DCM clock feedback
--CLKIN => ov7670_pclk4buf, -- Clock input (from IBUFG, BUFG or DCM)
--PSCLK => '0', -- Dynamic phase adjust clock input
--PSEN => '0', -- Dynamic phase adjust enable input
--PSINCDEC => '0', -- Dynamic phase adjust increment/decrement
--RST => resetdcm1 -- DCM asynchronous reset input
--);
--pclk4_bufa : IBUFG generic map (IOSTANDARD => "DEFAULT") port map (O => ov7670_pclk4buf, I => ov7670_pclk4);
--pclk4_buf : BUFG port map (O => clock6b, I => clock6a);
--ov7670_pclk4buf1 <= clock6b;

end Structural;
