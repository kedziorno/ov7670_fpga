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

entity Top is
	Generic (G_PB_BITS : integer := 24);
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
				ov7670_pclk1,ov7670_pclk2,ov7670_pclk3,ov7670_pclk4  : in  STD_LOGIC; -- Pmod JB8 --R16
				ov7670_xclk1,ov7670_xclk2,ov7670_xclk3,ov7670_xclk4  : out STD_LOGIC; -- Pmod JB2 --R18
				ov7670_vsync1,ov7670_vsync2,ov7670_vsync3,ov7670_vsync4 : in  STD_LOGIC; -- Pmod JB9 --T18
				ov7670_href1,ov7670_href2,ov7670_href3,ov7670_href4  : in  STD_LOGIC; -- Pmod JB3 --R15
				ov7670_data1,ov7670_data2,ov7670_data3,ov7670_data4  : in  STD_LOGIC_vector(2 downto 0);
									-- D0 : Pmod JA2 --K12 			-- D4 : Pmod JA4  --M15
									-- D1 : Pmod JA8 --L16			-- D5 : Pmod JA10 --M16
									-- D2 : Pmod JA3 --L17			-- D6 : Pmod JB1  --M13
									-- D3 : Pmod JA9 --M14			-- D7 : Pmod JB7  --P17
				ov7670_sioc1,ov7670_sioc2,ov7670_sioc3,ov7670_sioc4  : out STD_LOGIC; -- Pmod JB10 --J12
				ov7670_siod1,ov7670_siod2,ov7670_siod3,ov7670_siod4  : inout STD_LOGIC; -- Pmod JB4 --H16
				ov7670_pwdn1,ov7670_pwdn2,ov7670_pwdn3,ov7670_pwdn4  : out STD_LOGIC; -- Pmod JA1 --L15
				ov7670_reset1,ov7670_reset2,ov7670_reset3,ov7670_reset4 : out STD_LOGIC; -- Pmod JA7 --K13
				
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

COMPONENT clk25gen
	Port ( reset : in std_logic; clk50 : in  STD_LOGIC;
          clk25 : out  STD_LOGIC);
END COMPONENT;

COMPONENT ov7670_capture
Generic (PIXELS : integer := 19200);
	Port ( reset : in std_logic; pclk : in  STD_LOGIC;
          vsync : in  STD_LOGIC;
          href : in  STD_LOGIC;
          d : in  STD_LOGIC_VECTOR (2 downto 0);
          addr : out  STD_LOGIC_VECTOR (14 downto 0);
          dout : out  STD_LOGIC_VECTOR (2 downto 0);
          we : out  STD_LOGIC_VECTOR (0 downto 0));
END COMPONENT;

COMPONENT frame_buffer
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
    clkb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
  );
END COMPONENT;

COMPONENT vga_imagegenerator
	Port ( 		reset : in std_logic; clk : in std_logic; Data_in1 : in  STD_LOGIC_VECTOR (2 downto 0);
						Data_in2 : in  STD_LOGIC_VECTOR (2 downto 0);
						Data_in3 : in  STD_LOGIC_VECTOR (2 downto 0);
						Data_in4 : in  STD_LOGIC_VECTOR (2 downto 0);
						active_area1 : in  STD_LOGIC;
						active_area2 : in  STD_LOGIC;
						active_area3 : in  STD_LOGIC;
						active_area4 : in  STD_LOGIC;
           RGB_out : out  STD_LOGIC_VECTOR (7 downto 0));
END COMPONENT;

COMPONENT address_generator
Generic (PIXELS : integer := 19200);
	Port ( reset : in std_logic; clk25 : in STD_LOGIC;
			 enable : in STD_LOGIC;
			 vsync : in STD_LOGIC;
			 address : out STD_LOGIC_VECTOR (14 downto 0));
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

component ov7670_registers
	Port ( reset : in std_logic; clk : in  STD_LOGIC;
          resend : in  STD_LOGIC;
          advance : in  STD_LOGIC;
          command : out  STD_LOGIC_VECTOR (15 downto 0);
          done : out  STD_LOGIC);
end component;

component ov7670_SCCB
	Port ( reset : in std_logic; clk : in  STD_LOGIC;
          reg_value : in  STD_LOGIC_VECTOR (7 downto 0);
          slave_addr : in  STD_LOGIC_VECTOR (7 downto 0);
          addr_reg : in  STD_LOGIC_VECTOR (7 downto 0);
          send : in  STD_LOGIC;
          siod : inout  STD_LOGIC;
          sioc : out  STD_LOGIC;
          taken : out  STD_LOGIC);
end component;	

signal clk25 : STD_LOGIC;
signal resend : STD_LOGIC;

-- RAM
signal wren1,wren2,wren3,wren4 : STD_LOGIC_VECTOR(0 downto 0);
signal wr_d1,wr_d2,wr_d3,wr_d4 : STD_LOGIC_VECTOR(2 downto 0);
signal wr_a1,wr_a2,wr_a3,wr_a4 : STD_LOGIC_VECTOR(14 downto 0);
signal rd_d1,rd_d2,rd_d3,rd_d4 : STD_LOGIC_VECTOR(2 downto 0);
signal rd_a1,rd_a2,rd_a3,rd_a4 : STD_LOGIC_VECTOR(14 downto 0);

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

begin
--	led1 <= ov7670_data1(0) or ov7670_data1(1) or ov7670_data1(2) or ov7670_data1(3) or ov7670_data1(4) or ov7670_data1(5) or ov7670_data1(6) or ov7670_data1(7);
--	led2 <= ov7670_data2(0) or ov7670_data2(1) or ov7670_data2(2) or ov7670_data2(3) or ov7670_data2(4) or ov7670_data2(5) or ov7670_data2(6) or ov7670_data2(7);
--	led3 <= ov7670_data3(0) or ov7670_data3(1) or ov7670_data3(2) or ov7670_data3(3) or ov7670_data3(4) or ov7670_data3(5) or ov7670_data3(6) or ov7670_data3(7);
--	led4 <= ov7670_data4(0) or ov7670_data4(1) or ov7670_data4(2) or ov7670_data4(3) or ov7670_data4(4) or ov7670_data4(5) or ov7670_data4(6) or ov7670_data4(7);

	led1 <= ov7670_data1(0) and ov7670_data1(1) and ov7670_data1(2);
	led2 <= ov7670_data2(0) and ov7670_data2(1) and ov7670_data2(2);
	led3 <= ov7670_data3(0) and ov7670_data3(1) and ov7670_data3(2);
	led4 <= ov7670_data4(0) and ov7670_data4(1) and ov7670_data4(2);

--	led1 <= '0';
--	led2 <= '0';
--	led3 <= '0';
--	led4 <= '0';

	anode <= "1111";

	inst_clk25: clk25gen port map(
		reset => resend,
		clk50 => clk50,
		clk25 => clk25);
	
	inst_debounce: debounce_circuit port map(
		clk => clk50,
		input => pb,
		output => resend);

	inst_ov7670capt1: ov7670_capture port map(
		reset => resend,
		pclk => ov7670_pclk1,
		vsync => ov7670_vsync1,
		href => ov7670_href1,
		d => ov7670_data1,
		addr => wr_a1,
		dout => wr_d1,
		we => wren1);
	inst_ov7670capt2: ov7670_capture port map(
		reset => resend,
		pclk => ov7670_pclk2,
		vsync => ov7670_vsync2,
		href => ov7670_href2,
		d => ov7670_data2,
		addr => wr_a2,
		dout => wr_d2,
		we => wren2);
	inst_ov7670capt3: ov7670_capture port map(
		reset => resend,
		pclk => ov7670_pclk3,
		vsync => ov7670_vsync3,
		href => ov7670_href3,
		d => ov7670_data3,
		addr => wr_a3,
		dout => wr_d3,
		we => wren3);
	inst_ov7670capt4: ov7670_capture port map(
		reset => resend,
		pclk => ov7670_pclk4,
		vsync => ov7670_vsync4,
		href => ov7670_href4,
		d => ov7670_data4,
		addr => wr_a4,
		dout => wr_d4,
		we => wren4);
	
	inst_framebuffer1 : frame_buffer port map(
		weA => wren1,
		clkA => ov7670_pclk1,
		addrA => wr_a1,
		dinA => wr_d1,
		clkB => clk25,
		addrB => rd_a1,
		doutB => rd_d1);
	inst_framebuffer2 : frame_buffer port map(
		weA => wren2,
		clkA => ov7670_pclk2,
		addrA => wr_a2,
		dinA => wr_d2,
		clkB => clk25,
		addrB => rd_a2,
		doutB => rd_d2);
	inst_framebuffer3 : frame_buffer port map(
		weA => wren3,
		clkA => ov7670_pclk3,
		addrA => wr_a3,
		dinA => wr_d3,
		clkB => clk25,
		addrB => rd_a3,
		doutB => rd_d3);
	inst_framebuffer4 : frame_buffer port map(
		weA => wren4,
		clkA => ov7670_pclk4,
		addrA => wr_a4,
		dinA => wr_d4,
		clkB => clk25,
		addrB => rd_a4,
		doutB => rd_d4);
	
	inst_addrgen1 : address_generator port map(
		reset => resend,
		clk25 => clk25,
		enable => active1,
		vsync => vga_vsync_sig,
		address => rd_a1);
	inst_addrgen2 : address_generator port map(
		reset => resend,
		clk25 => clk25,
		enable => active2,
		vsync => vga_vsync_sig,
		address => rd_a2);
	inst_addrgen3 : address_generator port map(
		reset => resend,
		clk25 => clk25,
		enable => active3,
		vsync => vga_vsync_sig,
		address => rd_a3);
	inst_addrgen4 : address_generator port map(
		reset => resend,
		clk25 => clk25,
		enable => active4,
		vsync => vga_vsync_sig,
		address => rd_a4);

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

cc <= clkcam when sw = '1' else clk25;

Registers: ov7670_registers port map(
	reset => resend,
	clk => cc,
	resend => resend1,
	advance => taken,
	command => command,
	done => done);

SCCB : ov7670_SCCB port map(
	reset => resend,
	clk => cc,
	reg_value => command (7 downto 0),
	slave_addr => camera_address,
	addr_reg => command (15 downto 8),
	send => send,
	sioc => sioc,
	siod => siod,
	taken => taken);

resend1 <= resend or resend2;

p0initcam : process(cc,resend) is
	type states is (idle,sa,sb,sc,sd,se);
	variable state : states := idle;
begin
	if (resend = '1') then
		state := idle;
		send <= '0';
		resend2 <= '0';
	elsif (rising_edge(cc)) then
		case (state) is
			when idle =>
--				if (resend = '1') then
					state := sa;
					send <= '0';
					resend2 <= '0';
--				else
--					state := idle;
--					send <= '0';
--					resend2 <= '0';
--				end if;
				camera1 <= '0';
				camera2 <= '0';
				camera3 <= '0';
				camera4 <= '0';
			when sa =>
				if (done = '1') then
					state := sb;
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
			when sb =>
				if (done = '1') then
					state := sc;
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
			when sc =>
				if (done = '1') then
					state := sd;
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
			when sd =>
				if (done = '1') then
					state := se;
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
			when se =>
				state := se;
				camera1 <= '0';
				camera2 <= '0';
				camera3 <= '0';
				camera4 <= '0';
				send <= '0';
				resend2 <= '0';
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

ov7670_pwdn1 <= '0';
ov7670_pwdn2 <= '0';
ov7670_pwdn3 <= '0';
ov7670_pwdn4 <= '0';
ov7670_reset1 <= '1';
ov7670_reset2 <= '1';
ov7670_reset3 <= '1';
ov7670_reset4 <= '1';
ov7670_xclk1 <= cc;
ov7670_xclk2 <= cc;
ov7670_xclk3 <= cc;
ov7670_xclk4 <= cc;

end Structural;

