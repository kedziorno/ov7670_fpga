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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.numeric_std.all;

Library UNISIM;
use UNISIM.vcomponents.all;

use WORK.st7735r_p_package.ALL;
use WORK.st7735r_p_screen.ALL;

entity Top is
Generic (
G_PB_BITS : integer := 24;
G_WAIT1 : integer := 20; -- wait for reset dcm and cameras
G_FE_WAIT_BITS : integer := 20; -- sccb wait for cameras
SPI_SPEED_MODE : integer := C_CLOCK_COUNTER_EF
);
	Port	(	clk50	: in STD_LOGIC; -- Crystal Oscilator 50MHz  --B8
	clkcam	: in STD_LOGIC; -- Crystal Oscilator 23.9616 MHz  --U9
				pb		: in STD_LOGIC; -- Push Button --B18
				sw		: in STD_LOGIC_VECTOR(3 downto 0);
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
				o_cs : out STD_LOGIC;
				o_do : out STD_LOGIC;
				o_ck : out STD_LOGIC;
				o_reset : out STD_LOGIC;
				o_rs : out STD_LOGIC;
				o_jc : out std_logic_vector(7 downto 0)
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
Generic (PIXELS : integer := 19200);
	Port ( reset : in std_logic; pclk : in  STD_LOGIC;
          vsync : in  STD_LOGIC;
          href : in  STD_LOGIC;
          d : in  STD_LOGIC_VECTOR (7 downto 0);
          addr : out  STD_LOGIC_VECTOR (14 downto 0);
          dout : out  STD_LOGIC_VECTOR (15 downto 0);
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
  PORT (
    clka : IN STD_LOGIC;
    wea : IN STD_LOGIC_VECTOR(0 DOWNTO 0);
    addra : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
    dina : IN STD_LOGIC_VECTOR(15 DOWNTO 0);
    clkb : IN STD_LOGIC;
    addrb : IN STD_LOGIC_VECTOR(14 DOWNTO 0);
    doutb : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
  );
END COMPONENT;

signal clk25 : STD_LOGIC;
signal resend : STD_LOGIC;

-- RAM
signal wren1,wren2,wren3,wren4 : STD_LOGIC_VECTOR(0 downto 0);
signal wr_d1,wr_d2,wr_d3,wr_d4 : STD_LOGIC_VECTOR(15 downto 0);
signal wr_a1,wr_a2,wr_a3,wr_a4 : STD_LOGIC_VECTOR(14 downto 0);
signal rd_d1,rd_d2,rd_d3,rd_d4 : STD_LOGIC_VECTOR(15 downto 0);
signal rd_a1,rd_a2,rd_a3,rd_a4 : STD_LOGIC_VECTOR(14 downto 0);

--VGA
signal active1,active2,active3,active4 : STD_LOGIC;
signal vga_vsync_sig,vga_hsync_sig : STD_LOGIC;

signal cc : std_logic;

constant camera_address : std_logic_vector(7 downto 0) := x"42"; -- Device write ID, see pg.10. (OV datasheet)

signal camera1,camera2,camera3,camera4 : std_logic;
signal command : std_logic_vector(15 downto 0);
signal sioc,siod : std_logic;
signal send,done,taken : std_logic;
signal resend1,resend2 : std_logic;

--signal ov7670_pclk1buf2,ov7670_pclk1buf3,ov7670_pclk1buf4 : std_logic;
signal ov7670_pclk1buf,ov7670_pclk2buf,ov7670_pclk3buf,ov7670_pclk4buf  : std_logic;
signal clkcambuf,clk50buf : std_logic;

signal ov7670_pclk1buf1,ov7670_pclk2buf1,ov7670_pclk3buf1,ov7670_pclk4buf1 : std_logic;

signal clock1a,clock1b,clock2a,clock2b : std_logic;
signal clock3a,clock3b,clock4a,clock4b : std_logic;
signal clock5a,clock5b,clock6a,clock6b : std_logic;

signal resetdcm,resetdcm1 : std_logic;

component my_spi is
generic (
C_CLOCK_COUNTER : integer
);
port (
i_clock : in std_logic;
i_reset : in std_logic;
i_enable : in std_logic;
i_data_byte : in BYTE_TYPE;
o_cs : out std_logic;
o_do : out std_logic;
o_ck : out std_logic;
o_sended : out std_logic
);
end component my_spi;

component st7735r_initialize is
generic (
C_CLOCK_COUNTER : integer
);
port (
i_clock : in std_logic;
i_reset : in std_logic;
i_run : in std_logic;
i_color : in COLOR_TYPE;
i_sended : in std_logic;
o_initialized : out std_logic;
o_enable : out std_logic;
o_data_byte : out BYTE_TYPE;
o_reset : out std_logic;
o_rs : out std_logic;
o_cs : out std_logic
);
end component st7735r_initialize;

signal spi_enable,spi_cs,spi_do,spi_ck,spi_sended : std_logic;
signal spi_data_byte : BYTE_TYPE;

signal initialize_run,initialize_sended : std_logic;
signal initialize_initialized,initialize_enable,initialize_reset,initialize_rs,initialize_cs : std_logic;
signal initialize_color : COLOR_TYPE;
signal initialize_data_byte : BYTE_TYPE;

signal spi_enable_data,spi_data,spi_rs_data : std_logic;
signal spi_data_byte_data : BYTE_TYPE;

signal pvs : std_logic;

signal fifo_empty,fifo_full,fifo_rd,fifo_wr : std_logic;

signal pstop_capture,stop_capture,send_pixels,done_pixels : std_logic;

signal ov7670_pclkbufmux,ov7670_vsyncmux,ov7670_hrefmux : std_logic;
signal ov7670_datamux : std_logic_vector(7 downto 0);
signal a1,b1,a2,b2,a3,b3,a4,b4 : std_logic;
	
begin

o_jc(0) <= ov7670_pclkbufmux;
o_jc(1) <= ov7670_vsyncmux;
o_jc(2) <= ov7670_hrefmux;
o_jc(3) <= ov7670_datamux(0);
--o_jc(4) <= '0';
--o_jc(5) <= '0';
--o_jc(6) <= '0';
--o_jc(7) <= '0';

anode <= "1111";

led1 <= ov7670_data1(0) or ov7670_data1(1) or ov7670_data1(2) or ov7670_data1(3) or ov7670_data1(4) or ov7670_data1(5) or ov7670_data1(6) or ov7670_data1(7);
led2 <= ov7670_data2(0) or ov7670_data2(1) or ov7670_data2(2) or ov7670_data2(3) or ov7670_data2(4) or ov7670_data2(5) or ov7670_data2(6) or ov7670_data2(7);
led3 <= ov7670_data3(0) or ov7670_data3(1) or ov7670_data3(2) or ov7670_data3(3) or ov7670_data3(4) or ov7670_data3(5) or ov7670_data3(6) or ov7670_data3(7);
led4 <= ov7670_data4(0) or ov7670_data4(1) or ov7670_data4(2) or ov7670_data4(3) or ov7670_data4(4) or ov7670_data4(5) or ov7670_data4(6) or ov7670_data4(7);

o_cs <= spi_cs when initialize_run = '1' or (send_pixels = '1' and stop_capture = '1') else '1';
o_do <= spi_do when initialize_run = '1' or (send_pixels = '1' and stop_capture = '1') else '0';
o_ck <= spi_ck when initialize_run = '1' or (send_pixels = '1' and stop_capture = '1') else '0';
o_reset <= initialize_reset when initialize_run = '1' else '1';
o_rs <= initialize_rs when initialize_run = '1' else spi_rs_data when (send_pixels = '1' and stop_capture = '1') else '1';

spi_data_byte <= initialize_data_byte when initialize_run = '1' else spi_data_byte_data when spi_data = '1' else (others => '0');
spi_enable <= initialize_enable when initialize_run = '1' else spi_enable_data when spi_data = '1' else '0';
initialize_sended <= spi_sended when initialize_run = '1' else '0';

c0 : my_spi
generic map (
C_CLOCK_COUNTER => SPI_SPEED_MODE
)
port map (
	i_clock => clkcambuf,
	i_reset => resend,
	i_enable => spi_enable,
	i_data_byte => spi_data_byte,
	o_cs => spi_cs,
	o_do => spi_do,
	o_ck => spi_ck,
	o_sended => spi_sended
);

c1 : st7735r_initialize
generic map (
C_CLOCK_COUNTER => SPI_SPEED_MODE
)
port map (
	i_clock => clkcambuf,
	i_reset => resend,
	i_run => initialize_run,
	i_color => initialize_color,
	i_sended => initialize_sended,
	o_initialized => initialize_initialized,
	o_cs => initialize_cs,
	o_reset => initialize_reset,
	o_rs => initialize_rs,
	o_enable => initialize_enable,
	o_data_byte => initialize_data_byte
);

fsm1 : process (clkcambuf,resend) is
	type states is (a,b,c,d);
	variable state : states;
	constant MAX_RD : std_logic_vector(14 downto 0) := std_logic_vector(to_unsigned(19200,15));
begin
	if (resend = '1') then
		state := a;
		stop_capture <= '0';
		pstop_capture <= '0';
		pvs <= '0';
		send_pixels <= '0';
		done_pixels <= '0';
	elsif (rising_edge(clkcambuf)) then
		pvs <= ov7670_vsyncmux;
		pstop_capture <= stop_capture;
		case (state) is
			when a =>
				send_pixels <= '0';
				done_pixels <= '0';
				if (pvs = '0' and ov7670_vsyncmux = '1') then
					stop_capture <= not stop_capture;
					state := b;
				else
					stop_capture <= stop_capture;
					state := a;
				end if;
			when b =>
				if (pstop_capture = '0' and stop_capture = '1') then
					state := c;
				else
					state := a;
				end if;
			when c =>
				done_pixels <= '0';
				if  (rd_a1 = MAX_RD-1) then
					state := d;
					send_pixels <= '0';
				else
					state := c;
					send_pixels <= '1';
				end if;
			when d =>
				state := a;
				done_pixels <= '1';
		end case;
	end if;
end process fsm1;

poled : process(clkcambuf,resend) is
	type states is (idle,
	a1,b1,c1,d1,
	a2,b2,c2,d2,
	a3,b3,c3,d3,
	a4,b4,c4,d4,
	a5,b5,c5,d5,
	a6,b6,c6,d6,
	a7,b7,c7,d7,
	a8,b8,c8,d8,
	a9,b9,c9,d9,
	a10,b10,c10,d10,
	a11,b11,c11,d11,
	a12,b12,c12,d12,
	a13,b13,c13,d13
	);
	variable state : states;
	variable w0_index : integer range 0 to SPI_SPEED_MODE-1;
	constant MAX_PIXELS : integer := 19200;
	variable w1_index : integer range 0 to MAX_PIXELS-1;
begin
	if (resend = '1') then
		state := idle;
		spi_enable_data <= '0';
		spi_data_byte_data <= (others => '0');
		w0_index := 0;
		w1_index := 0;
		rd_a1 <= (others => '0');
	elsif (rising_edge(clkcambuf)) then
		case (state) is
			when idle =>
				w0_index := 0;
				if (send_pixels = '1') then
					state := a1;
					w1_index := 0;
				else
					state := idle;
					w1_index := w1_index;
				end if;

			-- raset
			when a1 =>
				spi_enable_data <= '1';
				spi_rs_data <= '0';
				spi_data_byte_data <= x"2b";
				if (spi_sended = '1') then
					state := b1;
				else
					state := a1;
				end if;
			when b1 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := c1;
					w0_index := 0;
					spi_enable_data <= '0';
				else
					state := b1;
					w0_index := w0_index + 1;
				end if;				
			when c1 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := d1;
					w0_index := 0;
				else
					state := c1;
					w0_index := w0_index + 1;
				end if;
			when d1 =>
				state := a2;

			-- xs0
			when a2 =>
				spi_enable_data <= '1';
				spi_rs_data <= '1';
				spi_data_byte_data <= x"00";
				if (spi_sended = '1') then
					state := b2;
				else
					state := a2;
				end if;
			when b2 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := c2;
					w0_index := 0;
					spi_enable_data <= '0';
				else
					state := b2;
					w0_index := w0_index + 1;
				end if;				
			when c2 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := d2;
					w0_index := 0;
				else
					state := c2;
					w0_index := w0_index + 1;
				end if;
			when d2 =>
				state := a3;

			-- xs1
			when a3 =>
				spi_enable_data <= '1';
				spi_rs_data <= '1';
				spi_data_byte_data <= x"00";
				if (spi_sended = '1') then
					state := b3;
				else
					state := a3;
				end if;
			when b3 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := c3;
					w0_index := 0;
					spi_enable_data <= '0';
				else
					state := b3;
					w0_index := w0_index + 1;
				end if;				
			when c3 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := d3;
					w0_index := 0;
				else
					state := c3;
					w0_index := w0_index + 1;
				end if;
			when d3 =>
				state := a4;

			-- xe0
			when a4 =>
				spi_enable_data <= '1';
				spi_rs_data <= '1';
				spi_data_byte_data <= x"00";
				if (spi_sended = '1') then
					state := b4;
				else
					state := a4;
				end if;
			when b4 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := c4;
					w0_index := 0;
					spi_enable_data <= '0';
				else
					state := b4;
					w0_index := w0_index + 1;
				end if;				
			when c4 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := d4;
					w0_index := 0;
				else
					state := c4;
					w0_index := w0_index + 1;
				end if;
			when d4 =>
				state := a5;

			-- xe1
			when a5 =>
				spi_enable_data <= '1';
				spi_rs_data <= '1';
				spi_data_byte_data <= x"7f";
				if (spi_sended = '1') then
					state := b5;
				else
					state := a5;
				end if;
			when b5 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := c5;
					w0_index := 0;
					spi_enable_data <= '0';
				else
					state := b5;
					w0_index := w0_index + 1;
				end if;				
			when c5 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := d5;
					w0_index := 0;
				else
					state := c5;
					w0_index := w0_index + 1;
				end if;
			when d5 =>
				state := a6;

			-- caset
			when a6 =>
				spi_enable_data <= '1';
				spi_rs_data <= '0';
				spi_data_byte_data <= x"2a";
				if (spi_sended = '1') then
					state := b6;
				else
					state := a6;
				end if;
			when b6 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := c6;
					w0_index := 0;
					spi_enable_data <= '0';
				else
					state := b6;
					w0_index := w0_index + 1;
				end if;				
			when c6 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := d6;
					w0_index := 0;
				else
					state := c6;
					w0_index := w0_index + 1;
				end if;
			when d6 =>
				state := a7;

			-- xs0
			when a7 =>
				spi_enable_data <= '1';
				spi_rs_data <= '1';
				spi_data_byte_data <= x"00";
				if (spi_sended = '1') then
					state := b7;
				else
					state := a7;
				end if;
			when b7 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := c7;
					w0_index := 0;
					spi_enable_data <= '0';
				else
					state := b7;
					w0_index := w0_index + 1;
				end if;				
			when c7 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := d7;
					w0_index := 0;
				else
					state := c7;
					w0_index := w0_index + 1;
				end if;
			when d7 =>
				state := a8;

			-- xs1
			when a8 =>
				spi_enable_data <= '1';
				spi_rs_data <= '1';
				spi_data_byte_data <= x"00";
				if (spi_sended = '1') then
					state := b8;
				else
					state := a8;
				end if;
			when b8 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := c8;
					w0_index := 0;
					spi_enable_data <= '0';
				else
					state := b8;
					w0_index := w0_index + 1;
				end if;				
			when c8 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := d8;
					w0_index := 0;
				else
					state := c8;
					w0_index := w0_index + 1;
				end if;
			when d8 =>
				state := a9;

			-- xe0
			when a9 =>
				spi_enable_data <= '1';
				spi_rs_data <= '1';
				spi_data_byte_data <= x"00";
				if (spi_sended = '1') then
					state := b9;
				else
					state := a9;
				end if;
			when b9 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := c9;
					w0_index := 0;
					spi_enable_data <= '0';
				else
					state := b9;
					w0_index := w0_index + 1;
				end if;				
			when c9 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := d9;
					w0_index := 0;
				else
					state := c9;
					w0_index := w0_index + 1;
				end if;
			when d9 =>
				state := a10;

			-- xe1
			when a10 =>
				spi_enable_data <= '1';
				spi_rs_data <= '1';
				spi_data_byte_data <= x"9f";
				if (spi_sended = '1') then
					state := b10;
				else
					state := a10;
				end if;
			when b10 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := c10;
					w0_index := 0;
					spi_enable_data <= '0';
				else
					state := b10;
					w0_index := w0_index + 1;
				end if;				
			when c10 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := d10;
					w0_index := 0;
				else
					state := c10;
					w0_index := w0_index + 1;
				end if;
			when d10 =>
				state := a11;

			-- memwr
			when a11 =>
				spi_enable_data <= '1';
				spi_rs_data <= '0';
				spi_data_byte_data <= x"2c";
				if (spi_sended = '1') then
					state := b11;
				else
					state := a11;
				end if;
			when b11 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := c11;
					w0_index := 0;
					spi_enable_data <= '0';
				else
					state := b11;
					w0_index := w0_index + 1;
				end if;				
			when c11 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := d11;
					w0_index := 0;
				else
					state := c11;
					w0_index := w0_index + 1;
				end if;
			when d11 =>
				state := a12;

			when a12 =>
				spi_enable_data <= '1';
				spi_rs_data <= '1';
				spi_data_byte_data <= rd_d1(7 downto 0);
				if (spi_sended = '1') then
					state := b12;
				else
					state := a12;
				end if;
			when b12 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := c12;
					w0_index := 0;
					spi_enable_data <= '0';
				else
					state := b12;
					w0_index := w0_index + 1;
				end if;				
			when c12 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := d12;
					w0_index := 0;
				else
					state := c12;
					w0_index := w0_index + 1;
				end if;
			when d12 =>
				state := a13;

			when a13 =>
				spi_enable_data <= '1';
				spi_rs_data <= '1';
				spi_data_byte_data <= rd_d1(15 downto 8);
				if (spi_sended = '1') then
					state := b13;
				else
					state := a13;
				end if;
			when b13 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := c13;
					w0_index := 0;
					spi_enable_data <= '0';
				else
					state := b13;
					w0_index := w0_index + 1;
				end if;				
			when c13 =>
				if (w0_index = SPI_SPEED_MODE - 1) then
					state := d13;
					w0_index := 0;
				else
					state := c13;
					w0_index := w0_index + 1;
				end if;
			when d13 =>
				if (done_pixels = '1') then
					state := idle;
					w1_index := 0;
				else
					if (w1_index = MAX_PIXELS-1) then
						state := idle;
						w1_index := 0;
					else
						state := a12;
						w1_index := w1_index + 1;
					end if;
				end if;
				rd_a1 <= std_logic_vector(to_unsigned(w1_index,15));
			end case;
	end if;
end process poled;

p0mux : process (sw(0),sw(1),sw(2),sw(3),
ov7670_pclk1buf1,ov7670_pclk2buf1,ov7670_pclk3buf1,ov7670_pclk4buf1,
ov7670_vsync1,ov7670_vsync2,ov7670_vsync3,ov7670_vsync4,
ov7670_href1,ov7670_href2,ov7670_href3,ov7670_href4,
ov7670_data1,ov7670_data2,ov7670_data3,ov7670_data4
) is
begin
	if (sw(0) = '1' and sw(1) = '0' and sw(2) = '0' and sw(3) = '0') then
		ov7670_pclkbufmux <= ov7670_pclk1buf1;
		ov7670_vsyncmux <= ov7670_vsync1;
		ov7670_hrefmux <= ov7670_href1;
		ov7670_datamux <= ov7670_data1;
	elsif (sw(0) = '0' and sw(1) = '1' and sw(2) = '0' and sw(3) = '0') then
		ov7670_pclkbufmux <= ov7670_pclk2buf1;
		ov7670_vsyncmux <= ov7670_vsync2;
		ov7670_hrefmux <= ov7670_href2;
		ov7670_datamux <= ov7670_data2;
	elsif (sw(0) = '0' and sw(1) = '0' and sw(2) = '1' and sw(3) = '0') then
		ov7670_pclkbufmux <= ov7670_pclk3buf1;
		ov7670_vsyncmux <= ov7670_vsync3;
		ov7670_hrefmux <= ov7670_href3;
		ov7670_datamux <= ov7670_data3;
	elsif (sw(0) = '0' and sw(1) = '0' and sw(2) = '0' and sw(3) = '1') then
		ov7670_pclkbufmux <= ov7670_pclk4buf1;
		ov7670_vsyncmux <= ov7670_vsync4;
		ov7670_hrefmux <= ov7670_href4;
		ov7670_datamux <= ov7670_data4;
	else
		ov7670_pclkbufmux <= '0';
		ov7670_vsyncmux <= '0';
		ov7670_hrefmux <= '0';
		ov7670_datamux <= (others => '0');
	end if;
end process p0mux;

	inst_debounce: debounce_circuit port map(
		clk => clkcambuf,
		input => pb,
		output => resend);

	inst_ov7670capt1: ov7670_capture port map(
		reset => stop_capture,
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
		clkB => cc,
		addrB => rd_a1,
		doutB => rd_d1);

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
	type states is (idle,wait4dcm,wait4dcmpclk,sa,sa1,sb,sb1,sc,sc1,sd,sd1,se,display_initialize,display_is_initialize,display_done);
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
		initialize_run <= '0';
		spi_data <= '0';
	elsif (rising_edge(clkcambuf)) then
		case (state) is
			when idle =>
				state := wait4dcm;
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
					state := sb;
					counter := 0;
					send <= '0';
					resend2 <= '1';
				else
					state := sa1;
					counter := counter + 1;
					resend2 <= '0';
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
				state := wait4dcmpclk;
				camera1 <= '0';
				camera2 <= '0';
				camera3 <= '0';
				camera4 <= '0';
				send <= '0';
				resend2 <= '0';
			when wait4dcmpclk =>
				if (w4dcmcnt = C_W4DCM-1) then
					resetdcm1 <= '0';
					w4dcmcnt := 0;
					state := display_initialize;
				else
					resetdcm1 <= '1';
					w4dcmcnt := w4dcmcnt + 1;
					state := wait4dcmpclk;
				end if;
			when display_initialize =>
				initialize_run <= '1';
				initialize_color <= SCREEN_BLACK;
				state := display_is_initialize;
			when display_is_initialize =>
				if (initialize_initialized = '1') then
					state := display_done;
				else
					state := display_is_initialize;
				end if;
			when display_done =>
				initialize_run <= '0';
				state := display_done;
				spi_data <= '1';
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

ov7670_reset1 <= '0' when resetdcm = '1' else '1';
ov7670_reset2 <= '0' when resetdcm = '1' else '1';
ov7670_reset3 <= '0' when resetdcm = '1' else '1';
ov7670_reset4 <= '0' when resetdcm = '1' else '1';

ov7670_pwdn1 <= '1' when resetdcm = '1' else '0';
ov7670_pwdn2 <= '1' when resetdcm = '1' else '0';
ov7670_pwdn3 <= '1' when resetdcm = '1' else '0';
ov7670_pwdn4 <= '1' when resetdcm = '1' else '0';

DCM_xcam : DCM
generic map (
CLKDV_DIVIDE => 2.0, -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5,7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
CLKFX_DIVIDE => 25, -- Can be any interger from 1 to 32
--CLKFX_MULTIPLY => 4, -- Can be any integer from 1 to 32 -- 16mhz
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
CLKIN => clkcambuf, -- Clock input (from IBUFG, BUFG or DCM)
PSCLK => '0', -- Dynamic phase adjust clock input
PSEN => '0', -- Dynamic phase adjust enable input
PSINCDEC => '0', -- Dynamic phase adjust increment/decrement
RST => resetdcm1 -- DCM asynchronous reset input
);
xcam_bufb : BUFG port map (O => clock2b, I => clock2a);

xcam_bufa : IBUFG generic map (IOSTANDARD => "DEFAULT") port map (O => clkcambuf, I => clkcam);
--xcam_bufb : BUFG port map (O => clk50buf, I => clkcambuf);

--pdiv_cam : process (clk50buf,resetdcm) is
--	constant C_MAX : integer := 2;
--	variable i : integer range 0 to C_MAX-1;
--begin
--	if (resetdcm = '1') then
--		i := 0;
--		cc <= '0';
--	elsif (rising_edge(clk50buf)) then
--		if (i = C_MAX-1) then
----			cc <= not cc;
--			cc <= '1';
--			i := 0;
--		else
----			cc <= cc;
--			cc <= '0';
--			i := i + 1;
--		end if;
--	end if;
--end process pdiv_cam;

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
----CLKIN_PERIOD => 20.833, -- Specify period of input clock
----CLKIN_PERIOD => 41.667, -- Specify period of input clock
----CLKIN_PERIOD => 42.333, -- Specify period of input clock
--CLKIN_PERIOD => 62.5, -- Specify period of input clock
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
--CLK0 => clock1a, -- 0 degree DCM CLK ouptput
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
--CLKFB => clock1b, -- DCM clock feedback
--CLKIN => a1, -- Clock input (from IBUFG, BUFG or DCM)
--PSCLK => '0', -- Dynamic phase adjust clock input
--PSEN => '0', -- Dynamic phase adjust enable input
--PSINCDEC => '0', -- Dynamic phase adjust increment/decrement
--RST => resetdcm1 -- DCM asynchronous reset input
--);
--pclk1_bufa : IBUFG generic map (IOSTANDARD => "DEFAULT") port map (O => a1, I => ov7670_pclk1);
--pclk1_bufb : BUFG port map (O => clock1b, I => clock1a);
--ov7670_pclk1buf1 <= clock1b;
--
--DCM_pclk2 : DCM
--generic map (
--CLKDV_DIVIDE => 2.0, -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5,7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
--CLKFX_DIVIDE => 2, -- Can be any interger from 1 to 32
--CLKFX_MULTIPLY => 2, -- Can be any integer from 1 to 32
--CLKIN_DIVIDE_BY_2 => FALSE, -- TRUE/FALSE to enable CLKIN divide by two feature
----CLKIN_PERIOD => 20.833, -- Specify period of input clock
----CLKIN_PERIOD => 41.667, -- Specify period of input clock
----CLKIN_PERIOD => 42.333, -- Specify period of input clock
--CLKIN_PERIOD => 62.5, -- Specify period of input clock
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
--CLK0 => clock2a, -- 0 degree DCM CLK ouptput
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
--CLKFB => clock2b, -- DCM clock feedback
--CLKIN => a2, -- Clock input (from IBUFG, BUFG or DCM)
--PSCLK => '0', -- Dynamic phase adjust clock input
--PSEN => '0', -- Dynamic phase adjust enable input
--PSINCDEC => '0', -- Dynamic phase adjust increment/decrement
--RST => resetdcm1 -- DCM asynchronous reset input
--);
--pclk2_bufa : IBUFG generic map (IOSTANDARD => "DEFAULT") port map (O => a2, I => ov7670_pclk2);
--pclk2_bufb : BUFG port map (O => clock2b, I => clock2a);
--ov7670_pclk2buf1 <= clock2b;
--
--DCM_pclk3 : DCM
--generic map (
--CLKDV_DIVIDE => 2.0, -- Divide by: 1.5,2.0,2.5,3.0,3.5,4.0,4.5,5.0,5.5,6.0,6.5,7.0,7.5,8.0,9.0,10.0,11.0,12.0,13.0,14.0,15.0 or 16.0
--CLKFX_DIVIDE => 2, -- Can be any interger from 1 to 32
--CLKFX_MULTIPLY => 2, -- Can be any integer from 1 to 32
--CLKIN_DIVIDE_BY_2 => FALSE, -- TRUE/FALSE to enable CLKIN divide by two feature
----CLKIN_PERIOD => 20.833, -- Specify period of input clock
----CLKIN_PERIOD => 41.667, -- Specify period of input clock
----CLKIN_PERIOD => 42.333, -- Specify period of input clock
--CLKIN_PERIOD => 62.5, -- Specify period of input clock
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
--CLKIN => a3, -- Clock input (from IBUFG, BUFG or DCM)
--PSCLK => '0', -- Dynamic phase adjust clock input
--PSEN => '0', -- Dynamic phase adjust enable input
--PSINCDEC => '0', -- Dynamic phase adjust increment/decrement
--RST => resetdcm1 -- DCM asynchronous reset input
--);
--pclk3_bufa : IBUFG generic map (IOSTANDARD => "DEFAULT") port map (O => a3, I => ov7670_pclk3);
--pclk3_bufb : BUFG port map (O => clock3b, I => clock3a);
--ov7670_pclk3buf1 <= clock3b;

end Structural;
