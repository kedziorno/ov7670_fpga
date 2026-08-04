library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

use work.micron_mem_parameters.all;
use work.p_constants.all;
use work.p_camera_colorbar.all;

entity top_camera_monitoring is
  generic (
    constant c_module_mode : module_mode_st := c_module_mode_syn;
    constant c_sync        : boolean        := true;
    constant c_hs_blanking : boolean        := true;
    constant c_pb_bits     : integer        := 23;
    constant c_async_owait : boolean        := true;
    constant c_zero        : integer        := 0
  );
  port  (
    i_clock    : in std_logic; -- 100 MHz
    pb         : in std_logic;
    sw         : in std_logic_vector (7 downto 0);
    led1       : out std_logic; -- configuration done
    -- OV7670 camera input
    ov7670_pclk1  : in  std_logic;
    ov7670_vsync1 : in  std_logic;
    ov7670_href1  : in  std_logic;
    ov7670_data1  : in  std_logic_vector(7 downto 0);
    ov7670_sioc1  : out std_logic;
    ov7670_xclk1  : out std_logic;
    ov7670_pwdn1  : out std_logic;
    ov7670_reset1 : out std_logic;
    ov7670_siod1  : inout std_logic;
    -- Memory module (middleman)
    owait : in    std_logic;
    adv_n : out   std_logic;
    ce_n  : out   std_logic;
    clk   : out   std_logic;
    cre   : out   std_logic;
    lb_n  : out   std_logic;
    oe_n  : out   std_logic;
    ub_n  : out   std_logic;
    we_n  : out   std_logic;
    addr  : out   std_logic_vector (c_addr_bits - 1 downto 0);
    dq    : inout std_logic_vector (c_data_bits - 1 downto 0);
    -- VGA signals output
    vga_clock : out std_logic;
    vga_blank : out std_logic;
    vga_hsync : out std_logic;
    vga_vsync : out std_logic;
    vga_r     : out std_logic_vector (2 downto 0);
    vga_g     : out std_logic_vector (2 downto 0);
    vga_b     : out std_logic_vector (1 downto 0)
);
end entity top_camera_monitoring;

architecture structural of top_camera_monitoring is

-- ram fb
signal write_buffer_data : std_logic_vector(15 downto 0);
signal write_buffer_addr : std_logic_vector(10 downto 0);
signal read_buffer_data : std_logic_vector(15 downto 0);
signal read_buffer_addr : std_logic_vector(9 downto 0);

--vga
signal active1 : std_logic;
signal vga_vsync_sig : std_logic := '1';
signal vga_vsync_sig_prev : std_logic := '1';



signal siodo1, siodi1 : std_logic;
signal siodo1_n : std_logic;

signal clk0, clk0_fb : std_logic;
signal clk1, clk1_fb : std_logic;
signal i_clock_ib2 : std_logic;
signal clk_cam, clk_vga : std_logic;
--synthesis translate_off
signal resend : std_logic;
--synthesis translate_on

signal ov7670_pclk : std_logic;
signal ov7670_d : std_logic_vector (7 downto 0);
signal ov7670_hs, ov7670_vs : std_logic;

signal vga_int : std_logic;

signal vga_rgb : std_logic_vector (7 downto 0);

signal reset_dcm_n, reset_dcm : std_logic;



constant clkfx_multiply_mc : integer := 6;
constant clkfx_divide_mc : integer := 25;

signal busy, wrc : std_logic;
signal data, id : std_logic_vector(15 downto 0);

type p_states0 is (
st01, st02, st03, st04, st05, st06, st07, st08, st09
);
type p_states1 is (
st01, st02, st03, st04, st05, st06, st07, st08, st09
);
signal p0_state : p_states0 := st01;
signal p1_state : p_states1 := st01;

constant c_cntr_frame : integer := 307200/2;
constant c_step_w : unsigned (15 downto 0) := to_unsigned (320, 16);
constant c_step_r : unsigned (15 downto 0) := to_unsigned (320, 16);
signal cntr_wr1 : unsigned (17 downto 0) := (others => '0');
signal cntr_rd1 : unsigned (17 downto 0) := (others => '0');
signal ov7670_vs_next : std_logic_vector (1 downto 0) := (others => '0');

signal vga_hsync_i : std_logic := '1';

signal data_r, data_w, id_r, id_w : std_logic_vector (15 downto 0) := (others => '0');
signal p0_r, p0_w : std_logic;
signal wrc_r, wrc_w : std_logic;

signal latched_hs, latched_vs : std_logic;

signal read_buffer_clk : std_logic;

signal ov7670_hs_prev : std_logic;




signal owait1 : std_logic;


signal clk_mc, locked_vga : std_logic;

signal cam_pclk, cam_hs, cam_vs, cam_pwdn : std_logic;
signal cam_d : std_logic_vector (7 downto 0);

--attribute keep : string;
--attribute keep of clk_vga : signal is "true";
--attribute keep of ov7670_pclk1 : signal is "true";
--attribute keep : string;
--attribute keep of clk_vga : signal is "true";

signal addr_o : std_logic_vector (22 downto 0);
signal dq_i,dq_ii : std_logic_vector (15 downto 0);
signal dq_o,dq_oo : std_logic_vector (15 downto 0);
signal data_out_enable : std_logic_vector (15 downto 0);
signal data_out_enable_not : std_logic_vector (15 downto 0);
signal oe_n_i, we_n_i, adv_n_i, ce_n_i, cre_i, clk_i : std_logic;


begin

g0_sync_owait : if (c_async_owait = false) generate
  p0_synchronise_owait : process (clk1_fb) is
  begin
    if (rising_edge (clk1_fb)) then
      if (pb = '1') then
        owait1 <= '0';
      else
        owait1 <= owait;
      end if;
    end if;
  end process p0_synchronise_owait;
end generate g0_sync_owait;

g0_async_owait : if (c_async_owait = true) generate
  owait1 <= owait;
end generate g0_async_owait;

clk <= clk_i;
g1_sync_mem_signals : if (c_sync = true) generate
  p1_synchronise_mem_addr_dq_ctrl : process (clk_mc) is
  begin
    if (rising_edge (clk_mc)) then
      if (pb = '1') then
        dq_oo <= (others => '0');
        dq_i  <= (others => '0');
      else
        dq_oo <= dq_o;
        dq_i  <= dq_ii;
        addr  <= addr_o;
        oe_n  <= oe_n_i;
        we_n  <= we_n_i;
        adv_n <= adv_n_i;
        ce_n  <= ce_n_i;
        cre   <= cre_i;
      end if;
    end if;
  end process p1_synchronise_mem_addr_dq_ctrl;
end generate g1_sync_mem_signals;

g1_async_mem_signals : if (c_sync = false) generate
  dq_oo <= dq_o;
  dq_i  <= dq_ii;
  addr  <= addr_o;
  oe_n  <= oe_n_i;
  we_n  <= we_n_i;
  adv_n <= adv_n_i;
  ce_n  <= ce_n_i;
  cre   <= cre_i;
end generate g1_async_mem_signals;

g2_dq_iob_inout : for i in c_data_bits - 1 downto 0 generate
  data_out_enable_not (i) <= not data_out_enable (i);
  iobuf_inst : iobuf
  generic map (
    drive            =>        12,
    ibuf_delay_value =>       "0",
    ifd_delay_value  =>    "AUTO",
    iostandard       => "DEFAULT", -- must be uppercase
    slew             =>    "SLOW"
  )
  port map (
    o  => dq_ii               (i),
    io => dq                  (i),
    i  => dq_oo               (i),
    t  => data_out_enable_not (i)
  );
end generate g2_dq_iob_inout;

-- Switch mux read/write id, data, write control
id <=
  id_w when p0_w = '1' else
  id_r when p0_r = '1' else
  (others => '0');
data <=
  data_w when p0_w = '1' else
  data_r when p0_r = '1' else
  (others => '0');
wrc <=
  wrc_w when p0_w = '1' else
  wrc_r when p0_r = '1' else
  '0';

p2_control_crbc_write : process (clk_mc) is
begin
  if (rising_edge (clk_mc)) then
    if (pb = '1') then
      p0_state <= st01;
      p0_w <= '0';
      wrc_w <= '0';
      ov7670_hs_prev <= '0';
      id_w <= (others => '0');
      data_w <= (others => '0');
      cntr_wr1 <= (others => '0');
    else
      wrc_w <= '0';
      ov7670_hs_prev <= latched_hs;
      case (p0_state) is
        when st01 =>
          if (ov7670_hs_prev = '1' and latched_hs = '0') then
            p0_state <= st02;
          end if;
          if (latched_vs = '1') then
            p0_state <= st02;
            p0_w <= '1'; wrc_w <= '1'; id_w <= x"0058"; data_w <= (others => '0');
          end if;
        when st02 =>
          p0_w <= '0';
          if (latched_vs = '1') then
            cntr_wr1 <= (others => '0');
          end if;
          if (ov7670_hs_prev = '1' and latched_hs = '0') then -- wr when hs fe
            p0_state <= st03;
          end if;
        when st03 =>
          if (busy = '0') then
            p0_state <= st04;
            p0_w <= '1'; wrc_w <= '1'; id_w <= x"0058"; data_w <= (others => '0');
          end if;
        when st04 =>
          if (busy = '0') then
            p0_state <= st05;
            p0_w <= '1'; wrc_w <= '1'; id_w <= x"0055"; data_w <= std_logic_vector (cntr_wr1 (15 downto 0));
          end if;
        when st05 =>
          if (busy = '0') then
            p0_state <= st06;
            p0_w <= '1'; wrc_w <= '1'; id_w <= x"0054"; data_w <= "00000000000000" & std_logic_vector (cntr_wr1 (17 downto 16));
          end if;
        when st06 =>
          if (busy = '0') then
            p0_state <= st07;
            p0_w <= '1'; wrc_w <= '1'; id_w <= x"0052"; data_w <= std_logic_vector (c_step_w);
          end if;
        when st07 =>
          if (busy = '0') then
            p0_state <= st08;
            p0_w <= '1'; wrc_w <= '1'; id_w <= x"0058"; data_w <= x"0000";
          end if;
        when st08 =>
          if (busy = '0') then
            p0_state <= st09;
            p0_w <= '1'; wrc_w <= '1'; id_w <= x"0050"; data_w <= x"0000";
          end if;
        when st09 =>
          p0_w <= '0';
          p0_w <= '1'; wrc_w <= '1'; id_w <= x"0058"; data_w <= (others => '0');
          if (latched_vs = '1') then
            p0_state <= st01;
          else
            p0_state <= st02;
          end if;
          if (cntr_wr1 = to_unsigned (c_cntr_frame, cntr_wr1'left + 1)) then
            cntr_wr1 <= (others => '0');
          else
            cntr_wr1 <= cntr_wr1 + c_step_w;
          end if;
        when others => p0_state <= st01;
      end case;
    end if;
  end if;
end process p2_control_crbc_write;

p3_control_crbc_read : process (clk_mc) is
  variable flag : boolean := false;
begin
  if (rising_edge (clk_mc)) then
    if (pb = '1') then
      wrc_r <= '0';
      vga_vsync_sig_prev <= '0';
      p1_state <= st01;
      ov7670_vs_next <= (others => '0');
      p0_r <= '0';
      id_r <= (others => '0');
      data_r <= (others => '0');
      cntr_rd1 <= (others => '0');
    else
      wrc_r <= '0';
      vga_vsync_sig_prev <= vga_vsync_sig;
      case (p1_state) is
        when st01 =>
          p0_r <= '1'; wrc_r <= '1'; id_r <= x"0059"; data_r <= (others => '0');
          if (vga_vsync_sig_prev = '0' and vga_vsync_sig = '1') then -- xxx here
            ov7670_vs_next <= ov7670_vs_next (0) & '1';
            p0_r <= '1'; wrc_r <= '1'; id_r <= x"0059"; data_r <= (others => '0');
          end if;
          if (ov7670_vs_next = "11") then -- from vs cam
            if (busy = '0') then
              p1_state <= st02;
            end if;
          end if;
        when st02 =>
          if (vga_vsync_sig_prev = '1' and vga_vsync_sig = '0') then
            cntr_rd1 <= (others => '0');
          end if;
          if (vga_int = '1') then
            p1_state <= st03;
          end if;
        when st03 =>
          if (busy = '0') then
            p1_state <= st04;
          end if;
        when st04 =>
          if (busy = '0') then
            p1_state <= st05;
            p0_r <= '1'; wrc_r <= '1'; id_r <= x"0057"; data_r <= std_logic_vector (cntr_rd1 (15 downto 0));
          end if;
        when st05 =>
          if (busy = '0') then
            p1_state <= st06;
            p0_r <= '1'; wrc_r <= '1'; id_r <= x"0056"; data_r <= "00000000000000" & std_logic_vector (cntr_rd1 (17 downto 16));
          end if;
        when st06 =>
          if (busy = '0') then
            p1_state <= st07;
            p0_r <= '1'; wrc_r <= '1'; id_r <= x"0053"; data_r <= std_logic_vector (c_step_r);
          end if;
        when st07 =>
          if (busy = '0') then
            p1_state <= st08;
            p0_r <= '1'; wrc_r <= '1'; id_r <= x"0051"; data_r <= x"0000";
          end if;
        when st08 =>
          if (busy = '0') then
            p1_state <= st09;
          end if;
        when st09 =>
          p0_r <= '0';
          p1_state <= st01;
          if (cntr_rd1 = to_unsigned (c_cntr_frame, cntr_rd1'left+1)) then
            cntr_rd1 <= (others => '0');
          else
            cntr_rd1 <= cntr_rd1 + c_step_r;
          end if;
        when others => p1_state <= st01;
      end case;
    end if;
  end if;
end process p3_control_crbc_read;

crbc_i0 : entity work.cellular_ram_burst_controller
port map (
  busy => busy,
  clk => clk_mc,
  reset => pb,
  --reset => reset_dcm,
  writes => wrc,
  data => data,
  id => id,

  write_buffer_addr => write_buffer_addr,
  write_buffer_data => write_buffer_data,
  write_buffer_clk => ov7670_pclk1,
--  write_buffer_we => ov7670_hs,
  write_buffer_we => latched_hs,

  read_buffer_addr => read_buffer_addr,
  read_buffer_data => read_buffer_data,
  --read_buffer_clk => clk_vga,
  read_buffer_clk => read_buffer_clk,
  data_out_enable => data_out_enable,

  lb => lb_n,
  ub => ub_n,
  oe => oe_n_i,
  we => we_n_i,

  adv => adv_n_i,
  ce => ce_n_i,
  cre => cre_i,
  ram_clk => clk_i,

  o_wait => owait1,

  a => addr_o,
  dq_i => dq_i,
  dq_o => dq_o
);

vga_r <= vga_rgb (7 downto 5);
vga_g <= vga_rgb (4 downto 2);
vga_b <= vga_rgb (1 downto 0);

ov7670_siod1_tri : iobuf
port map (
  o => open,
  io=> ov7670_siod1,
  i=> siodo1,
  t=> '0'
);

debounce_circuit_i0 : entity work.debounce_circuit
generic map (
  c_module_mode => c_module_mode,
  c_pb_bits_syn => c_pb_bits
)
port map (
  i_clock => '0',
  i_reset => reset_dcm,
  --i_reset => '0',
  input => pb,
  --output => resend
  output => open
);

ov7670_xclk1 <= clk_cam;
--ov7670_xclkv <= clk_cam;
ov7670_pwdn1 <= cam_pwdn;
--ov7670_pwdnv <= cam_pwdn;
ov7670_reset1 <= not pb;

ov7670_i2c_controller_i0 : entity work.ov7670_i2c_controller
generic map (
  c_module_mode => c_module_mode
)
port map (
  i_clock => clk_mc,
  i_reset => pb,
  resend => sw(1),
  sw => sw (0),
  sioc => ov7670_sioc1,
  siodo => siodo1,
  conf_done => led1,
  pwdn => cam_pwdn,
  reset => open,
  xclk_in => '0',
  xclk_out => open
);

ov7670_capture_i0 : entity work.ov7670_capture
generic map (
  c_module_mode => c_module_mode
)
port map (
  reset => pb,
  pclk => ov7670_pclk1,
  vsync => ov7670_vsync1,
  href => ov7670_href1,
  d => ov7670_data1,
  addr => write_buffer_addr,
  dout => write_buffer_data,
  latched_vs => latched_vs,
  latched_hs => latched_hs
);

address_generator_i0 : entity work.address_generator
generic map (
  c_module_mode => c_module_mode
)
port map (
  --clk25 => clk_vga,
  clk25 => read_buffer_clk,
  --reset => reset_dcm,
  reset => pb,
  enable => active1,
  vsync => vga_vsync_sig,
  address => read_buffer_addr
  );

inst_imagegen : entity work.vga_imagegenerator
generic map (
  c_module_mode => c_module_mode
)
port map (
  data_in1 => read_buffer_data,
  reset => pb,
  --data_in1 => x"55aa", -- test output bmp
  active_area1 => active1,
  rgb_out => vga_rgb
);

vga_hsync <= vga_hsync_i;
vga_vsync <= vga_vsync_sig;
vga_clock <= clk_vga;
vga_timing_i0 : entity work.vga_timing (counter) -- jc, lsfr_1, lsfr_2
generic map (
  c_module_mode => c_module_mode
)
port map (
  rst => pb,
  clk25 => clk_vga,
  hsync => vga_hsync_i,
  vsync => vga_vsync_sig,
  blank => vga_blank,
  activearea => active1,
  interrupt => vga_int
);

reset_dcm <= not reset_dcm_n;
synchro_reset_i0 : srlc16e
port map (
  d => '1',
  ce => '1',
  clk => clk1_fb,
  a0 => '1',
  a1 => '1',
  a2 => '1',
  a3 => '1',
  q => reset_dcm_n,
  q15 => open
);

--synthesis translate_off
p0_assert_1 : process (resend) is
begin
  if (resend = '1') then
    assert (
      not (clkfx_multiply_mc = 32 and clkfx_divide_mc = 1)
    ) report
      "forbidden mc clkfx_multiply " & integer'image (clkfx_multiply_mc) &
      " clkfx_divide " & integer'image (clkfx_divide_mc)
      severity failure;
  end if;
end process p0_assert_1;
--synthesis translate_on

--p2_vga_clk : process (clk1_fb) is
--  constant c_vga : integer := 4;
--  variable vga : integer range 0 to c_vga - 1;
--begin
--  if (rising_edge (clk1_fb)) then
--    if (pb = '1') then
--      clk_vga <= '0';
--      vga := 0;
--    else
--      if (vga = c_vga - 1) then
--        clk_vga <= '1';
--        vga := 0;
--      else
--        clk_vga <= '0';
--        vga := vga + 1;
--      end if;
--    end if;
--  end if;
--end process p2_vga_clk;

p3_read_buffer_clk : process (clk_vga) is
  constant c_vga_read : integer := 2;
  variable vga_read : integer range 0 to c_vga_read - 1;
begin
  if (rising_edge (clk_vga)) then
    if (locked_vga = '0') then
      read_buffer_clk <= '0';
      vga_read := 0;
    else
      if (vga_read = c_vga_read - 1) then
        read_buffer_clk <= '1';
        vga_read := 0;
      else
        read_buffer_clk <= '0';
        vga_read := vga_read + 1;
      end if;
    end if;
  end if;
end process p3_read_buffer_clk;

bufg_cam : bufg
port map (
  o => clk0_fb,
  i => clk0
);

dcm_sp_vga : dcm_sp
generic map (
  clkdv_divide => 4.0,
  clkfx_multiply => 3, clkfx_divide => 5,
  clkin_period => 10.0,
  startup_wait => true
)
port map (
  clk0 => clk0,
  clkfx => clk_mc,
  clkdv => clk_vga,
  clkfb => clk0_fb,
  clkin => clk1,
  rst => reset_dcm,
  locked => locked_vga,
  psclk => '0', psen => '0', psincdec => '0'
);

bufg_cam50 : bufg
port map (
  o => clk1_fb,
  i => clk1
);

ibufg_global_clock50 : ibufg
generic map (
  iostandard => "DEFAULT")
port map (
  o => i_clock_ib2,
  i => i_clock
);

dcm_sp_cam : dcm_sp
generic map (
  clkfx_multiply => 2, clkfx_divide => 14,
  clkin_period => 10.0,
  startup_wait => true
)
port map (
  clk0 => clk1,
  clkfx => clk_cam,
  clkfb => clk1_fb,
  clkin => i_clock_ib2,
  rst => pb,
  locked => open,
  psclk => '0', psen => '0', psincdec => '0'
);

end architecture structural;
