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

signal qr1 : std_logic_vector (9 downto 0) := "0000000001";
signal hsync_set, hsync_reset : std_logic := '1';

signal qr2 : std_logic_vector (18 downto 0) := "0000000000000000001";
signal vsync_set, vsync_reset : std_logic := '1';

constant c_hsync_10 : std_logic_vector (9 downto 0) := "0000110100";
constant c_hsync_01 : std_logic_vector (9 downto 0) := "0011110000";
type hs_gen_states is (hs_gen_set, hs_gen_reset);
signal hs_gen_state : hs_gen_states := hs_gen_set;

constant c_vsync_10 : std_logic_vector (18 downto 0) := "1101110011011000011";
constant c_vsync_01 : std_logic_vector (18 downto 0) := "0110010010110010110";
type vs_gen_states is (vs_gen_set, vs_gen_reset);
signal vs_gen_state : vs_gen_states := vs_gen_set;

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

end architecture lsfr_1;

-- aggregate lsfr
architecture lsfr_2 of vga_timing is

signal qr1 : std_logic_vector (9 downto 0) := "0000000001";
signal hsync_set, hsync_reset : std_logic := '1';

signal qr2 : std_logic_vector (9 downto 0) := "0000000001";
signal vsync_set, vsync_reset : std_logic := '1';

constant c_hsync_10 : std_logic_vector (9 downto 0) := "0000110100";
constant c_hsync_01 : std_logic_vector (9 downto 0) := "0011110000";
type hs_gen_states is (hs_gen_set, hs_gen_reset);
signal hs_gen_state : hs_gen_states := hs_gen_set;

constant c_vsync_10 : std_logic_vector (9 downto 0) := "1000010000";
constant c_vsync_01 : std_logic_vector (9 downto 0) := "0101000010";
type vs_gen_states is (vs_gen_set, vs_gen_reset);
signal vs_gen_state : vs_gen_states := vs_gen_set;

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

