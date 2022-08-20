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
	Port	(clkcam	: in STD_LOGIC; -- Crystal Oscilator 23.9616 MHz  --U9
				pb		: in STD_LOGIC; -- Push Button --B18
				sw		: in STD_LOGIC_VECTOR(3 downto 0); -- Push Button --G18
				led1 : out STD_LOGIC; -- Indicates configuration has been done --J14
				led2 : out STD_LOGIC; -- Indicates configuration has been done --J14
				led3 : out STD_LOGIC; -- Indicates configuration has been done --J14
				led4 : out STD_LOGIC; -- Indicates configuration has been done --J14
			  anode : out std_logic_vector(3 downto 0);
				-- OV7670
--				ov7670_reset1,ov7670_reset2,ov7670_reset3,ov7670_reset4  : out  STD_LOGIC;
--				ov7670_pwdn1,ov7670_pwdn2,ov7670_pwdn3,ov7670_pwdn4: out  STD_LOGIC;
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

COMPONENT clockmux_old is port (
	areset           : in std_logic;        -- Asynch Reset
	clk1             : in std_logic;        -- Clock 1
	clk2             : in std_logic;        -- Clock 2
	clk3             : in std_logic;        -- Clock 3
	clk4             : in std_logic;        -- Clock 4
	clk0             : in std_logic;        -- clk main
	sel1             : in std_logic;        -- Clock Select 1
	sel2             : in std_logic;        -- Clock Select 2
	sel3             : in std_logic;        -- Clock Select 3
	sel4             : in std_logic;        -- Clock Select 4
	sel0             : in std_logic;        -- no select
	rxclk            : out std_logic);      -- RX Clock
END COMPONENT clockmux_old;

COMPONENT arbiter is port(
		 txclk:                 in std_logic;   -- TX_CLK
		 areset:                in std_logic;   -- Asynch Reset
		 activity1:             in std_logic;   -- Port Activity 1       
		 activity2:             in std_logic;   -- Port ACtivity 2
		 activity3:             in std_logic;   -- Port ACtivity 3
		 activity4:             in std_logic;   -- Port Activity 4       
		 sel1:                  buffer std_logic;  -- Port Select 1
		 sel2:                  buffer std_logic;  -- Port Select 2
		 sel3:                  buffer std_logic;  -- Port Select 3
		 sel4:                  buffer std_logic;  -- Port Select 4
		 nosel:                 buffer std_logic;  -- No Port Selected
		 carrier:               buffer std_logic;  -- Carrier Detected
		 collision:             buffer std_logic); -- Collision Detected
END COMPONENT arbiter;

constant ADDRESS : integer := 15;
constant BITS : integer := 16;
constant PIXELS : integer := 160*120;

COMPONENT debounce_circuit
Generic (PB_BITS : integer := G_PB_BITS);
	Port ( clk : in STD_LOGIC;
			 input : in STD_LOGIC;
			 output : out STD_LOGIC);
END COMPONENT;

COMPONENT ov7670_capture
Generic (
PIXELS : integer := PIXELS;
ADDRESS1 : integer := ADDRESS;
BITS : integer := BITS
);
	Port ( reset : in std_logic; pclk : in  STD_LOGIC;
          vsync : in  STD_LOGIC;
          href : in  STD_LOGIC;
          d : in  STD_LOGIC_VECTOR (7 downto 0);
          addr : out  STD_LOGIC_VECTOR (ADDRESS1-1 downto 0);
          dout : out  STD_LOGIC_VECTOR (BITS-1 downto 0);
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
			 addrA: in STD_LOGIC_VECTOR(ADDRESS-1 downto 0);
			 dinA	: in STD_LOGIC_VECTOR(BITS-1 downto 0);
			 clkB : in STD_LOGIC;
			 addrB: in STD_LOGIC_VECTOR(ADDRESS-1 downto 0);
			 doutB: out STD_LOGIC_VECTOR(BITS-1 downto 0));
END COMPONENT;

COMPONENT vga_imagegenerator
Generic (BITS : integer := BITS);
	Port ( reset : in std_logic; clk : std_logic; Data_in1 : in  STD_LOGIC_VECTOR (BITS-1 downto 0);
						Data_in2 : in  STD_LOGIC_VECTOR (BITS-1 downto 0);
						Data_in3 : in  STD_LOGIC_VECTOR (BITS-1 downto 0);
						Data_in4 : in  STD_LOGIC_VECTOR (BITS-1 downto 0);
						active_area1 : in  STD_LOGIC;
						active_area2 : in  STD_LOGIC;
						active_area3 : in  STD_LOGIC;
						active_area4 : in  STD_LOGIC;
           RGB_out : out  STD_LOGIC_VECTOR (7 downto 0));
END COMPONENT;

COMPONENT address_generator
Generic (
PIXELS : integer  := PIXELS;
ADDRESS1 : integer := ADDRESS
);
	Port ( reset : in std_logic; clk25 : in STD_LOGIC;
			 enable : in STD_LOGIC;
			 vsync : in STD_LOGIC;
				activeh : in STD_LOGIC;
			 address : out STD_LOGIC_VECTOR (ADDRESS1-1 downto 0));
END COMPONENT;

COMPONENT VGA_timing_synch
    Port ( reset : in std_logic; clk25 : in  STD_LOGIC;
           Hsync : out  STD_LOGIC;
           Vsync : out  STD_LOGIC;
           activeArea1 : out  STD_LOGIC;
           activeArea2 : out  STD_LOGIC;
           activeArea3 : out  STD_LOGIC;
           activeArea4 : out  STD_LOGIC;
					 activehaaddrgen : out STD_LOGIC;
					 activeRender1 : out  STD_LOGIC);
END COMPONENT;

signal clk25 : STD_LOGIC;
signal resend : STD_LOGIC;

-- RAM
signal wren1,wren2,wren3,wren4 : STD_LOGIC_VECTOR(0 downto 0);
signal wr_d1,wr_d2,wr_d3,wr_d4 : STD_LOGIC_VECTOR(BITS-1 downto 0);
signal wr_a1,wr_a2,wr_a3,wr_a4 : STD_LOGIC_VECTOR(ADDRESS-1 downto 0);
signal rd_d1,rd_d2,rd_d3,rd_d4 : STD_LOGIC_VECTOR(BITS-1 downto 0);
signal rd_a1,rd_a2,rd_a3,rd_a4 : STD_LOGIC_VECTOR(ADDRESS-1 downto 0);

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

signal cc4 : std_logic;
signal activeRender1 : std_logic;
signal activehaaddrgen : std_logic;

signal a1,a2,a3,a4 : std_logic;
signal ov7670_pclkbufmux,ov7670_vsyncmux,ov7670_hrefmux : std_logic;
signal ov7670_datamux : std_logic_vector(7 downto 0);

signal sel1, sel2, sel3, sel4, nosel, carrier, collision : std_logic;

begin

--debug(0) <= ov7670_pclk1buf1;
--debug(1) <= ov7670_vsync1;
--debug(2) <= ov7670_href1;
--debug(3) <= ov7670_data1(0);
--debug(4) <= ov7670_data1(7);

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

	led1 <= ov7670_data1(0) and ov7670_data1(1) and ov7670_data1(2) and ov7670_data1(3) and ov7670_data1(4) and ov7670_data1(5) and ov7670_data1(6) and ov7670_data1(7);
	led2 <= ov7670_data2(0) and ov7670_data2(1) and ov7670_data2(2) and ov7670_data2(3) and ov7670_data2(4) and ov7670_data2(5) and ov7670_data2(6) and ov7670_data2(7);
	led3 <= ov7670_data3(0) and ov7670_data3(1) and ov7670_data3(2) and ov7670_data3(3) and ov7670_data3(4) and ov7670_data3(5) and ov7670_data3(6) and ov7670_data3(7);
	led4 <= ov7670_data4(0) and ov7670_data4(1) and ov7670_data4(2) and ov7670_data4(3) and ov7670_data4(4) and ov7670_data4(5) and ov7670_data4(6) and ov7670_data4(7);

--	led1 <= '0';
--	led2 <= '0';
--	led3 <= '0';
--	led4 <= '0';

--	inst_clk25: clk25gen port map(
--		reset => resend,
--		clk50 => clk50buf,
--		clk25 => clk25);

p0mux : process (sw(0),sw(1),sw(2),sw(3),
--ov7670_pclk1buf1,ov7670_pclk2buf1,ov7670_pclk3buf1,ov7670_pclk4buf1,
ov7670_vsync1,ov7670_vsync2,ov7670_vsync3,ov7670_vsync4,
ov7670_href1,ov7670_href2,ov7670_href3,ov7670_href4,
ov7670_data1,ov7670_data2,ov7670_data3,ov7670_data4
) is
begin
	if (sw(0) = '1' and sw(1) = '0' and sw(2) = '0' and sw(3) = '0') then
--	if (sw(0) = '1' and sw(1) = '0' and sw(2) = '0') then
--		ov7670_pclkbufmux <= ov7670_pclk1buf1;
		ov7670_vsyncmux <= ov7670_vsync1;
		ov7670_hrefmux <= ov7670_href1;
		ov7670_datamux <= ov7670_data1;
	elsif (sw(0) = '0' and sw(1) = '1' and sw(2) = '0' and sw(3) = '0') then
--	elsif (sw(0) = '0' and sw(1) = '1' and sw(2) = '0') then
--		ov7670_pclkbufmux <= ov7670_pclk2buf1;
		ov7670_vsyncmux <= ov7670_vsync2;
		ov7670_hrefmux <= ov7670_href2;
		ov7670_datamux <= ov7670_data2;
	elsif (sw(0) = '0' and sw(1) = '0' and sw(2) = '1' and sw(3) = '0') then
--	elsif (sw(0) = '0' and sw(1) = '0' and sw(2) = '1') then
--		ov7670_pclkbufmux <= ov7670_pclk3buf1;
		ov7670_vsyncmux <= ov7670_vsync3;
		ov7670_hrefmux <= ov7670_href3;
		ov7670_datamux <= ov7670_data3;
	elsif (sw(0) = '0' and sw(1) = '0' and sw(2) = '0' and sw(3) = '1') then
--	elsif (sw(0) = '0' and sw(1) = '0' and sw(2) = '0') then
--		ov7670_pclkbufmux <= ov7670_pclk4buf1;
		ov7670_vsyncmux <= ov7670_vsync4;
		ov7670_hrefmux <= ov7670_href4;
		ov7670_datamux <= ov7670_data4;
	else
--		ov7670_pclkbufmux <= '0';
		ov7670_vsyncmux <= '0';
		ov7670_hrefmux <= '0';
		ov7670_datamux <= (others => '0');
	end if;
end process p0mux;

----p0cmpclk : process (resend,ov7670_pclk1buf1,ov7670_pclk2buf1,ov7670_pclk3buf1,ov7670_pclk4buf1) is
--p0cmpclk : process (resend,ov7670_pclk1,ov7670_pclk2,ov7670_pclk3,ov7670_pclk4) is
--begin
--	if (resend = '1') then
--		aaa <= (others => '0');
--	else
----		aaa <= ov7670_pclk1buf1&ov7670_pclk2buf1&ov7670_pclk3buf1&ov7670_pclk4buf1;
--		aaa <= ov7670_pclk1&ov7670_pclk2&ov7670_pclk3&ov7670_pclk4;
--	end if;
--end process;

--aaa <= ov7670_pclk1&ov7670_pclk2&ov7670_pclk3&ov7670_pclk4;
--aaa <= ov7670_pclk1buf1&ov7670_pclk2buf1&ov7670_pclk3buf1;
--bbb <= ov7670_href1&ov7670_href2&ov7670_href3;
--ccc <= ov7670_vsync1&ov7670_vsync2&ov7670_vsync3;
--ddd <= sw(0)&sw(1)&sw(2);

u1: clockmux_old port map
	(resend, 
	ov7670_pclk1buf1, ov7670_pclk2buf1, ov7670_pclk3buf1, ov7670_pclk4buf1, clkcambuf,
	sel1, sel2, sel3, sel4, nosel,
	ov7670_pclkbufmux);

u2: arbiter port map
	(clkcambuf, resend, 
	sw(0), sw(1), sw(2), sw(3),
	sel1, sel2, sel3, sel4,
	nosel, carrier, collision);
	
	inst_debounce: debounce_circuit port map(
		clk => clkcambuf,
		input => pb,
		output => resend);

	inst_ov7670capt1: ov7670_capture port map(
		reset => resend,
		pclk => ov7670_pclkbufmux,
		vsync => ov7670_vsyncmux,
		href => ov7670_hrefmux,
		d => ov7670_datamux,
		addr => wr_a1,
		dout => wr_d1,
		we => wren1);
	
	inst_framebuffer1 : frame_buffer port map(
		weA => wren1,
		clkA => ov7670_pclkbufmux,
		addrA => wr_a1,
		dinA => wr_d1,
--		clkB => clk25,
		clkB => cc4,
		addrB => rd_a1,
		doutB => rd_d1);
	
	inst_addrgen1 : address_generator port map(
		reset => resend,
--		clk25 => clk25,
		clk25 => cc4,
		enable => activeRender1, -- slide
--		enable => active1, -- dont slide
		vsync => vga_vsync_sig,
--		vsync => not ov7670_vsync1,
		address => rd_a1,
		activeh => activehaaddrgen);

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
		activeArea4 => active4,
		activehaaddrgen => activehaaddrgen,
		activeRender1 => activeRender1);

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
					state := sb;
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
ov7670_sioc2 <= sioc when camera2 = '1' else '1';
ov7670_siod2 <= siod when camera2 = '1' else '1';
ov7670_sioc3 <= sioc when camera3 = '1' else '1';
ov7670_siod3 <= siod when camera3 = '1' else '1';
ov7670_sioc4 <= sioc when camera4 = '1' else '1';
ov7670_siod4 <= siod when camera4 = '1' else '1';

OBUF_xclk1 : OBUF port map (O => ov7670_xclk1, I => cc);
OBUF_xclk2 : OBUF port map (O => ov7670_xclk2, I => cc);
OBUF_xclk3 : OBUF port map (O => ov7670_xclk3, I => cc);
OBUF_xclk4 : OBUF port map (O => ov7670_xclk4, I => cc);

--ov7670_reset1 <= '0' when resetdcm = '1' else '1';
--ov7670_reset2 <= '0' when resetdcm = '1' else '1';
--ov7670_reset3 <= '0' when resetdcm = '1' else '1';
--ov7670_reset4 <= '0' when resetdcm = '1' else '1';

--ov7670_pwdn1 <= '1' when resetdcm = '1' else '0';
--ov7670_pwdn2 <= '1' when resetdcm = '1' else '0';
--ov7670_pwdn3 <= '1' when resetdcm = '1' else '0';
--ov7670_pwdn4 <= '1' when resetdcm = '1' else '0';

p0 : process (resend,clk25) is
	constant CMAX : integer := 2;
--	constant CMAX : integer := 4;
	variable vmax : integer range 0 to CMAX-1;
begin
	if (resend = '1') then
		cc4 <= '0';
		vmax := 0;
	elsif (rising_edge(clk25)) then
		if (vmax = CMAX-1) then
--			cc4 <= '1';
			cc4 <= not cc4;
			vmax := 0;
		else
--			cc4 <= '0';
			cc4 <= cc4;
			vmax := vmax + 1;
		end if;
	end if;
end process p0;

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

cam_buf1a : IBUFG generic map (IOSTANDARD => "DEFAULT") port map (O => a1, I => ov7670_pclk1);
cam_buf1b : BUFG port map (O => ov7670_pclk1buf1, I => a1);
cam_buf2a : IBUFG generic map (IOSTANDARD => "DEFAULT") port map (O => a2, I => ov7670_pclk2);
cam_buf2b : BUFG port map (O => ov7670_pclk2buf1, I => a2);
cam_buf3a : IBUFG generic map (IOSTANDARD => "DEFAULT") port map (O => a3, I => ov7670_pclk3);
cam_buf3b : BUFG port map (O => ov7670_pclk3buf1, I => a3);
cam_buf4a : IBUFG generic map (IOSTANDARD => "DEFAULT") port map (O => a4, I => ov7670_pclk4);
cam_buf4b : BUFG port map (O => ov7670_pclk4buf1, I => a4);

--DCM_pclk1 : DCM
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
--CLK0 => clock3a, -- 0 degree DCM CLK ouptput
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
--CLKFB => clock3b, -- DCM clock feedback
--CLKIN => ov7670_pclk1buf, -- Clock input (from IBUFG, BUFG or DCM)
--PSCLK => '0', -- Dynamic phase adjust clock input
--PSEN => '0', -- Dynamic phase adjust enable input
--PSINCDEC => '0', -- Dynamic phase adjust increment/decrement
--RST => resetdcm1 -- DCM asynchronous reset input
--);
--pclk1_bufa : IBUFG generic map (IOSTANDARD => "DEFAULT") port map (O => ov7670_pclk1buf, I => ov7670_pclk1);
--pclk1_buf : BUFG port map (O => clock3b, I => clock3a);
--ov7670_pclk1buf1 <= clock3b;
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
