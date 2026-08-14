library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_arith.all;
library unisim;
use unisim.vcomponents.all;
library work;
use work.p_constants.all;

entity vga_timing is
generic (
  c_module_mode : module_mode_st := c_module_mode_syn
);
port (
  clk25, rst : in  std_logic;
  hsync      : out std_logic;
  vsync      : out std_logic;
  blank      : out std_logic;
  activearea : out std_logic;
  interrupt  : out std_logic
);
end entity vga_timing;

-- fastest lsfr
architecture lsfr_1 of vga_timing is

-- horizontal counter
signal qr1 : std_logic_vector (9 downto 0) := "0000000001";
signal hsync_set, hsync_reset : std_logic := '1';

-- vertical counter
signal qr2 : std_logic_vector (18 downto 0) := "0000000000000000001";
signal vsync_set, vsync_reset : std_logic := '1';

-- horizontal syncing
constant c_hsync_10 : std_logic_vector (9 downto 0) := "0000110100";
constant c_hsync_01 : std_logic_vector (9 downto 0) := "0011110000";
type hs_gen_states is (hs_gen_set, hs_gen_reset);
signal hs_gen_state : hs_gen_states := hs_gen_set;

-- horizontal blanking
constant c_hblank_10 : std_logic_vector (9 downto 0) := "0010011111";
constant c_hblank_01 : std_logic_vector (9 downto 0) := "1111100110";
type hb_gen_states is (hb_gen_set, hb_gen_reset);
signal hb_gen_state : hb_gen_states := hb_gen_set;
signal hblank_set, hblank_reset : std_logic := '0';
signal hblank_not : std_logic := '1';

-- vertical syncing
constant c_vsync_10 : std_logic_vector (18 downto 0) := "1101110011011000011";
constant c_vsync_01 : std_logic_vector (18 downto 0) := "0110010010110010110";
type vs_gen_states is (vs_gen_set, vs_gen_reset);
signal vs_gen_state : vs_gen_states := vs_gen_set;

-- vertical blanking
constant c_vblank_10 : std_logic_vector (18 downto 0) := "1011010100101000100";
constant c_vblank_01 : std_logic_vector (18 downto 0) := "1001000100101110111";
type vb_gen_states is (vb_gen_set, vb_gen_reset);
signal vb_gen_state : vb_gen_states := vb_gen_set;
signal vblank_set, vblank_reset : std_logic := '0';
signal vblank_not : std_logic := '1';

begin

-- lsfr

----synthesis translate_off
--process (clk25) is
--  variable debug : string (1 to 7) := "debug: ";
--begin
--  if (rising_edge (clk25)) then
--    assert (qr1 /= "0000000001") report debug & "ping on h 1" severity note;
--    assert (qr2 /= "0000000000000000001") report debug & "ping on v 1" severity note;
--  end if;
--end process;
----synthesis translate_on

lsfr_h : process (clk25) is
begin
  if (rising_edge (clk25)) then
    qr1(9)  <= qr1(8);
    qr1(8)  <= qr1(7);
    qr1(7)  <= qr1(6) xor qr1(9);
    qr1(6)  <= qr1(5);
    qr1(5)  <= qr1(4);
    qr1(4)  <= qr1(3);
    qr1(3)  <= qr1(2);
    qr1(2)  <= qr1(1);
    qr1(1)  <= qr1(0);
    qr1(0)  <= qr1(9);
    if (qr1 = c_hsync_01) then
      qr1 <= "0000000001";
    end if;
  end if;
end process lsfr_h;

lsfr_v : process (clk25) is
begin
  if (rising_edge (clk25)) then
    qr2(18) <= qr2(17) xor qr2(18);
    qr2(17) <= qr2(16) xor qr2(18);
    qr2(16) <= qr2(15);
    qr2(15) <= qr2(14);
    qr2(14) <= qr2(13) xor qr2(18);
    qr2(13) <= qr2(12);
    qr2(12) <= qr2(11);
    qr2(11) <= qr2(10);
    qr2(10) <= qr2(9);
    qr2(9)  <= qr2(8);
    qr2(8)  <= qr2(7);
    qr2(7)  <= qr2(6);
    qr2(6)  <= qr2(5);
    qr2(5)  <= qr2(4);
    qr2(4)  <= qr2(3);
    qr2(3)  <= qr2(2);
    qr2(2)  <= qr2(1);
    qr2(1)  <= qr2(0);
    qr2(0)  <= qr2(18);
    if (qr2 = c_vsync_10) then
      qr2 <= "0000000000000000001";
    end if;
  end if;
end process lsfr_v;

-- better than if/elsif (process) or when/else (latch) in rtl schematic
-- but slowest in syn reports
hsync_gen1 : process (clk25) is
begin
  if (rising_edge (clk25)) then
  case (hs_gen_state) is
    when hs_gen_set =>
      if (qr1 = c_hsync_10) then
        hs_gen_state <= hs_gen_reset;
        hsync_set <= '0';
        hsync_reset <= '1';
      end if;
    when hs_gen_reset =>
      if (qr1 = c_hsync_01) then
        hs_gen_state <= hs_gen_set;
        hsync_set <= '1';
        hsync_reset <= '0';
      end if;
    end case;
  end if;
end process hsync_gen1;

hsync_gen_fdcpe : fdcpe
port map (
  q   => hsync,
  clr => hsync_reset,
  pre => hsync_set,
  c   => clk25,
  ce  => '0',
  d   => '0'
);

hblank_gen1 : process (clk25) is
begin
  if (rising_edge (clk25)) then
  case (hb_gen_state) is
    when hb_gen_set =>
      if (qr1 = c_hblank_10) then
        hb_gen_state <= hb_gen_reset;
        hblank_set <= '0';
        hblank_reset <= '1';
      end if;
    when hb_gen_reset =>
      if (qr1 = c_hblank_01) then
        hb_gen_state <= hb_gen_set;
        hblank_set <= '1';
        hblank_reset <= '0';
      end if;
    end case;
  end if;
end process hblank_gen1;

hblank_gen_fdcpe : fdcpe
port map (
  q   => hblank_not,
  clr => hblank_reset,
  pre => hblank_set,
  c   => clk25,
  ce  => '0',
  d   => '0'
);

blank <= hblank_not when (vsync_set = '1' and vblank_reset = '1') else '1';
activearea <= not hblank_not when (vsync_set = '1' and vblank_reset = '1') else '0';
interrupt <= '1' when qr1 = "1101001101" and vsync_set = '1' and vblank_reset = '1' else '0';

-- better than if/elsif (process) or when/else (latch) in rtl schematic
-- but slowest in syn reports
vsync_gen1 : process (clk25) is
begin
  if (rising_edge (clk25)) then
  case (vs_gen_state) is
    when vs_gen_set =>
      if (qr2 = c_vsync_10) then
        vs_gen_state <= vs_gen_reset;
        vsync_set <= '0';
        vsync_reset <= '1';
      end if;
    when vs_gen_reset =>
      if (qr2 = c_vsync_01) then
        vs_gen_state <= vs_gen_set;
        vsync_set <= '1';
        vsync_reset <= '0';
      end if;
    end case;
  end if;
end process vsync_gen1;

vsync_gen_fdcpe : fdcpe
port map (
  q   => vsync,
  clr => vsync_reset,
  pre => vsync_set,
  c   => clk25,
  ce  => '0',
  d   => '0'
);

vblank_gen1 : process (clk25) is
begin
  if (rising_edge (clk25)) then
  case (vb_gen_state) is
    when vb_gen_set =>
      if (qr2 = c_vblank_10) then
        vb_gen_state <= vb_gen_reset;
        vblank_set <= '0';
        vblank_reset <= '1';
      end if;
    when vb_gen_reset =>
      if (qr2 = c_vblank_01) then
        vb_gen_state <= vb_gen_set;
        vblank_set <= '1';
        vblank_reset <= '0';
      end if;
    end case;
  end if;
end process vblank_gen1;

vblank_gen_fdcpe : fdcpe
port map (
  q   => vblank_not,
  clr => vblank_reset,
  pre => vblank_set,
  c   => clk25,
  ce  => '0',
  d   => '0'
);

end architecture lsfr_1;

-- aggregate lsfr
architecture lsfr_2 of vga_timing is

-- horizontal counter
signal qr1 : std_logic_vector (9 downto 0) := "0000000001";
signal hsync_set, hsync_reset : std_logic := '1';
signal hblank_set, hblank_reset : std_logic := '1';

-- vertical counter
signal qr2 : std_logic_vector (9 downto 0) := "0000000001";
signal vsync_set, vsync_reset : std_logic := '1';
signal vblank_set, vblank_reset : std_logic := '1';

-- horizontal syncing
constant c_hsync_10 : std_logic_vector (9 downto 0) := "0000110100";
constant c_hsync_01 : std_logic_vector (9 downto 0) := "0011110000";
type hs_gen_states is (hs_gen_set, hs_gen_reset);
signal hs_gen_state : hs_gen_states := hs_gen_set;

-- horizontal blanking
constant c_hblank_10 : std_logic_vector (9 downto 0) := "0010011111";
constant c_hblank_01 : std_logic_vector (9 downto 0) := "1111100110";
type hb_gen_states is (hb_gen_set, hb_gen_reset);
signal hb_gen_state : hb_gen_states := hb_gen_set;
signal hblank_not : std_logic := '1';

-- vertical syncing
constant c_vsync_10 : std_logic_vector (9 downto 0) := "1000010000";
constant c_vsync_01 : std_logic_vector (9 downto 0) := "0101000010";
type vs_gen_states is (vs_gen_set, vs_gen_reset);
signal vs_gen_state : vs_gen_states := vs_gen_set;

-- vertical blanking
constant c_vblank_10 : std_logic_vector (9 downto 0) := "1001010010";
constant c_vblank_01 : std_logic_vector (9 downto 0) := "1101010111";
type vb_gen_states is (vb_gen_set, vb_gen_reset);
signal vb_gen_state : vb_gen_states := vb_gen_set;
signal vblank_not : std_logic := '1';

begin

-- lsfr

----synthesis translate_off
--process (clk25) is
--  variable debug : string (1 to 7) := "debug: ";
--begin
--  if (rising_edge (clk25)) then
--    assert (qr1 /= "0000000001") report debug & "ping on h 1" severity note;
--    assert (qr2 /= "0000000000000000001") report debug & "ping on v 1" severity note;
--  end if;
--end process;
----synthesis translate_on

lsfr_h : process (clk25) is
begin
  if (rising_edge (clk25)) then
    qr1(9)  <= qr1(8);
    qr1(8)  <= qr1(7);
    qr1(7)  <= qr1(6) xor qr1(9);
    qr1(6)  <= qr1(5);
    qr1(5)  <= qr1(4);
    qr1(4)  <= qr1(3);
    qr1(3)  <= qr1(2);
    qr1(2)  <= qr1(1);
    qr1(1)  <= qr1(0);
    qr1(0)  <= qr1(9);
    if (qr1 = c_hsync_01) then
      qr1 <= "0000000001";
    end if;
  end if;
end process lsfr_h;

lsfr_v : process (clk25) is
begin
  if (rising_edge (clk25)) then
    if (qr1 <= "0000000001") then
      qr2(9)  <= qr2(8);
      qr2(8)  <= qr2(7);
      qr2(7)  <= qr2(6) xor qr2(9);
      qr2(6)  <= qr2(5);
      qr2(5)  <= qr2(4);
      qr2(4)  <= qr2(3);
      qr2(3)  <= qr2(2);
      qr2(2)  <= qr2(1);
      qr2(1)  <= qr2(0);
      qr2(0)  <= qr2(9);
      if (qr2 = c_vsync_01) then
        qr2 <= "0000000001";
      end if;
    end if;
  end if;
end process lsfr_v;

-- better than if/elsif (process) or when/else (latch) in rtl schematic
-- but slowest in syn reports
hsync_gen1 : process (clk25) is
begin
  if (rising_edge (clk25)) then
  case (hs_gen_state) is
    when hs_gen_set =>
      if (qr1 = c_hsync_10) then
        hs_gen_state <= hs_gen_reset;
        hsync_set <= '0';
        hsync_reset <= '1';
      end if;
    when hs_gen_reset =>
      if (qr1 = c_hsync_01) then
        hs_gen_state <= hs_gen_set;
        hsync_set <= '1';
        hsync_reset <= '0';
      end if;
    end case;
  end if;
end process hsync_gen1;

hsync_gen_fdcpe : fdcpe
port map (
  q   => hsync,
  clr => hsync_reset,
  pre => hsync_set,
  c   => clk25,
  ce  => '0',
  d   => '0'
);

hblank_gen1 : process (clk25) is
begin
  if (rising_edge (clk25)) then
  case (hb_gen_state) is
    when hb_gen_set =>
      if (qr1 = c_hblank_10) then
        hb_gen_state <= hb_gen_reset;
        hblank_set <= '0';
        hblank_reset <= '1';
      end if;
    when hb_gen_reset =>
      if (qr1 = c_hblank_01) then
        hb_gen_state <= hb_gen_set;
        hblank_set <= '1';
        hblank_reset <= '0';
      end if;
    end case;
  end if;
end process hblank_gen1;

hblank_gen_fdcpe : fdcpe
port map (
  q   => hblank_not,
  clr => hblank_reset,
  pre => hblank_set,
  c   => clk25,
  ce  => '0',
  d   => '0'
);

blank <= hblank_not when (vsync_set = '1' and vblank_reset = '0') else '1';
activearea <= not hblank_not when (vsync_set = '1' and vblank_reset = '0') else '0';
interrupt <= '1' when qr1 = "1101001101" and vsync_set = '1' and vblank_reset = '0' else '0';

-- better than if/elsif (process) or when/else (latch) in rtl schematic
-- but slowest in syn reports
vsync_gen1 : process (clk25) is
begin
  if (rising_edge (clk25)) then
  case (vs_gen_state) is
    when vs_gen_set =>
      if (qr2 = c_vsync_10) then
        vs_gen_state <= vs_gen_reset;
        vsync_set <= '0';
        vsync_reset <= '1';
      end if;
    when vs_gen_reset =>
      if (qr2 = c_vsync_01) then
        vs_gen_state <= vs_gen_set;
        vsync_set <= '1';
        vsync_reset <= '0';
      end if;
    end case;
  end if;
end process vsync_gen1;

vsync_gen_fdcpe : fdcpe
port map (
  q   => vsync,
  clr => vsync_reset,
  pre => vsync_set,
  c   => clk25,
  ce  => '0',
  d   => '0'
);

vblank_gen1 : process (clk25) is
begin
  if (rising_edge (clk25)) then
  case (vb_gen_state) is
    when vb_gen_set =>
      if (qr2 = c_vblank_10) then
        vb_gen_state <= vb_gen_reset;
        vblank_set <= '0';
        vblank_reset <= '1';
      end if;
    when vb_gen_reset =>
      if (qr2 = c_vblank_01) then
        vb_gen_state <= vb_gen_set;
        vblank_set <= '1';
        vblank_reset <= '0';
      end if;
    end case;
  end if;
end process vblank_gen1;

vblank_gen_fdcpe : fdcpe
port map (
  q   => vblank_not,
  clr => vblank_reset,
  pre => vblank_set,
  c   => clk25,
  ce  => '0',
  d   => '0'
);

end architecture lsfr_2;

-- johnson counter
architecture jc of vga_timing is

signal jc_1 : std_logic_vector (799 downto 0) := '0'& (798 downto 0 => '1');
signal jc_2 : std_logic_vector (524 downto 0) := '0'& (523 downto 0 => '1');
signal clk_vga, hsync1, vsync1, activearea_sig1, blank1 : std_logic := '1';

begin

-- big jc counting 800/525

jc_sr_h : process (clk25) is
begin
  if (rising_edge (clk25)) then
  for i in 0 to 798 loop
    jc_1 (i +1) <= jc_1 (i);
  end loop;
  jc_1 (0) <= jc_1 (799);
  end if;
end process jc_sr_h;

jc_sr_v : process (jc_1(799)) is
begin
  if (falling_edge (jc_1(799))) then
  for i in 0 to 523 loop
    jc_2 (i +1) <= jc_2 (i);
  end loop;
  jc_2 (0) <= jc_2 (524);
  end if;
end process jc_sr_v;

hsync_gen1 : process(clk25) begin
  if rising_edge(clk25) then
    if (jc_1(752) = '0') then
      hsync <= '1';
    elsif (jc_1(656) = '0') then
      hsync <= '0';
    end if;
  end if;
end process hsync_gen1;

vsync_gen1 : process(clk25) begin
  if rising_edge(clk25) then
    if (jc_2(492) = '0') then
      vsync <= '1';
    elsif (jc_2(490) = '0') then
      vsync <= '0';
    end if;
  end if;
end process vsync_gen1;

active_area_jc : process(clk_vga) begin
  if rising_edge(clk_vga) then
    if (jc_1(639) = '0') then
      activearea <= '0';
    elsif (jc_1(799) = '0') then
      activearea <= '1';
    end if;
  end if;
end process active_area_jc;

blank_jc : process(clk_vga) begin
  if rising_edge(clk_vga) then
    if (jc_1(639) = '0') then
      blank <= '1';
    elsif (jc_1(799) = '0') then
      blank <= '0';
    end if;
  end if;
end process blank_jc;

end architecture jc;

-- normal counting
architecture counter of vga_timing is

  constant hd    : integer := 640;
  constant hf    : integer := 16;
  constant hb    : integer := 48;
  constant hr    : integer := 96;
  constant hp    : integer := hd + hf + hb + hr;
  constant vd    : integer := 480;
  constant vf    : integer := 10;
  constant vb    : integer := 33;
  constant vr    : integer := 2;
  constant vp    : integer := vd + vf + vb + vr;
  signal vcnt    : integer range 0 to 1023 := 0;
  signal hcnt    : integer range 0 to 1023 := 0;
  signal blank_i : std_logic;
  signal hsync_i : std_logic;

begin

  p0_count_hv : process (clk25) is
  begin
    if (rising_edge (clk25)) then
      if (rst = '1') then
        hcnt <= 0;
        vcnt <= 0;
      else
        if (hcnt = hp - 1) then
          hcnt <= 0;
          if (vcnt = vp - 1) then
            vcnt <= 0;
          else
            vcnt <= vcnt + 1;
          end if;
        else
          hcnt <= hcnt +1;
        end if;
      end if;
    end if;
  end process p0_count_hv;

  p1_hsync_gen : process (clk25) is
  begin
    if (rising_edge (clk25)) then
      if (rst = '1') then
        hsync_i <= '1';
      else
        if (hcnt >= (hd + hf) and hcnt <= (hd + hf + hr - 1)) then
          hsync_i <= '0';
        else
          hsync_i <= '1';
        end if;
      end if;
    end if;
  end process p1_hsync_gen;

  p2_vsync_gen : process (clk25) is
  begin
    if (rising_edge (clk25)) then
      if (rst = '1') then
        vsync <= '1';
      else
        if (vcnt >= (vd + vf) and vcnt <= (vd + vf + vr - 1)) then
          vsync <= '0';
        else
          vsync <= '1';
        end if;
      end if;
    end if;
  end process p2_vsync_gen;

  activearea <=
    '1' when ((hcnt < hd) and (vcnt < vd)) else
    '0';
  blank_i <=
    '1' when rst = '1' else
    '1' when ((hcnt >= hd) or (vcnt >= vd)) else
    '0';
  interrupt <=
    '1' when ((vcnt < vd-1 or vcnt = 524) and (hcnt = 640)) else
    '0';
  blank <= blank_i;

  hsync <= hsync_i;
  --process (clk_vga) is
  --begin
  --  if (rising_edge (clk_vga)) then
  --    if (rst = '1') then
  --      hsync <= '1';
  --    else
  --      if (blank_i = '1') then
  --        hsync <= '0';
  --      else
  --        hsync <= hsync_i;
  --      end if;
  --    end if;
  --  end if;
  --end process;

end architecture counter;

architecture vga_7slices of vga_timing is

signal a, b, c, d, e, en, f, fn, g, gn, h, hn : std_logic;
signal tmp1, tmp2 : std_logic;
signal tmp3 : std_logic;
signal tmp4 : std_logic;
signal tmp5 : std_logic;
signal tmp5a : std_logic;
signal tmp6 : std_logic;
signal t7,t8,t9,t10,t11,t12,t13,t14,t15,t16,t17,t18,t19,t20 : std_logic;

begin

div99_7bit : SRL16E
generic map (INIT => x"0001")
port map (
  Q   => a,
  A0  => '0', A1 => '1', A2 => '1', A3 => '0',
  CE  => '1',
  CLK => clk25,
  D   => a
);

div99_14bit : SRL16E
generic map (INIT => x"0001")
port map (
  Q   => b,
  A0  => '1', A1 => '0', A2 => '1', A3 => '1',
  CE  => '1',
  CLK => a,
  D   => b
);

move_next_i0 : FDCPE
generic map (INIT => '0')
port map (
  Q => tmp5,
  C => '0',
  CE => '1',
  CLR => '0',
  PRE => t9,
  D => '0'
);

vsync_fill : entity work.dummyplug_srlc50e
--generic map (INIT => "1111111111100111111111111111111111111111111111000000000000000000")
generic map (INIT => "00000000000000000000000000000000000000000000000000")
port map (
  Q   => tmp6,
  A(0)  => '1', A(1) => '1', A(2) => '1', A(3) => '1', A(4) => '1', A(5) => '1',
  CE  => tmp5,
  CLK => tmp4,
  D   => tmp6
);

tmp4 <= '1' when tmp3 = '1' and c = '0' else '0';
process (clk25) is
begin
  if (rising_edge (clk25)) then
    tmp3 <= c;
  end if;
end process;
--vsync_left : SRLC16E
--generic map (INIT => "1111111111111110")
----generic map (INIT => "1111000000000000")
--port map (
--  Q   => t7,
--  Q15 => tmp5,
--  A0  => '1', A1 => '1', A2 => '0', A3 => '1',
--  CE  => tmp4,
--  CLK => clk25,
--  D   => tmp5a
--);

--move_next_i0 : FDCE
--generic map (INIT => '0')
--port map (
--  Q => tmp5a,
--  C => clk25,
--  CE => '1',
--  CLR => t7,
--  D => tmp5
--);

--tmp6 <= tmp5a;
--vsync_right : entity work.dummyplug_srlc33e
--generic map (INIT => "111111111111111111111111111111110")
--port map (
--  Q   => tmp6,
--  Q32 => open,
--  A(0)  => '1', A(1) => '1', A(2) => '1', A(3) => '1', A(4) => '1', A(5) => '1',
--  CE  => tmp4,
--  CLK => clk25,
--  D   => tmp5a
--);

hsync <= not c;
hs : entity work.dummyplug_srlc32e
generic map (INIT => "01111000000000000000000000000000")
port map (
  Q     => open,
  Q31   => c,
  A(0)  => '1', A(1) => '1', A(2) => '0', A(3) => '1', A(4) => '0',
  CE    => '1',
  CLK   => b,
  D     => c
);

--interrupt <= h;
--int_srlc32e_i0 : entity work.dummyplug_srlc32e
--generic map (INIT => "10000000000000000000000000000000")
--port map (
--  Q     => open,
--  Q31   => h,
--  A(0)  => '1', A(1) => '1', A(2) => '0', A(3) => '1', A(4) => '0',
--  CE    => '1',
--  CLK   => b,
--  D     => h
--);
bufg_cam : bufg
port map (
  o => tmp2,
  i => d
);
interrupt <= '1' when (tmp1 = '1' and tmp2 = '0') and gn = '1' else '0';
process (clk25) is
begin
  if (rising_edge (clk25)) then
    tmp1 <= d;
  end if;
end process;

blank <= d when gn = '1' else '1';
activearea <= not d when gn = '1' else '0';
hb : entity work.dummyplug_srlc32e
generic map (INIT => "01111110000000000000000000000000")
port map (
  Q     => open,
  Q31   => d,
  A(0)  => '0', A(1) => '0', A(2) => '0', A(3) => '0', A(4) => '0',
  CE    => '1',
  CLK   => b,
  D     => d
);

e <= not en;
vga_15dot84us : entity work.dummyplug_srlc32e
generic map (INIT => "00000000000000000111111111111111")
port map (
  Q     => en,
  Q31   => open,
  A(0)  => '1', A(1) => '1', A(2) => '1', A(3) => '1', A(4) => '0',
  CE    => '1',
  CLK   => b,
  D     => en
);

f <= not fn;
vga_522dot72us : entity work.dummyplug_srlc33e
generic map (INIT => "011111111111111111111111111111111")
port map (
  Q     => fn,
  Q32   => open,
  A(0)  => '1', A(1) => '1', A(2) => '1', A(3) => '1', A(4) => '1', A(5) => '1',
  CE    => '1',
  CLK   => en,
  D     => fn
);

vsync <= gn or tmp6;
--o_vb <= g;
g <= not gn;
t9 <= '1' when t8 = '1' and gn = '0' else '0';
process (clk25) is
begin
  if (rising_edge (clk25)) then
    t8 <= gn;
  end if;
end process;
vga_16727dot04us : entity work.dummyplug_srlc32e
--generic map (INIT => "00011111111111111111111111111111")
generic map (INIT => "01111111111111111111111111111111")
port map (
  Q     => gn,
  Q31   => open,
  A(0)  => '1', A(1) => '1', A(2) => '1', A(3) => '1', A(4) => '1',
  CE    => '1',
  CLK   => fn,
  D     => gn
);

end architecture vga_7slices;
