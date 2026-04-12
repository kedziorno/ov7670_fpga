---------------------------------------------------------
-- This entity synchronize hsync and vsync to vga
-- Thanks to Pong P. Chu for creating basic things.
--------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
library unisim;
use unisim.vcomponents.all;

entity VGA_timing_synch is
    Port ( clk25, rst : in  STD_LOGIC;
           Hsync : out  STD_LOGIC := '0';
           Vsync : out  STD_LOGIC := '0';
           blank : out  STD_LOGIC;
           activeArea1 : out  STD_LOGIC);
end VGA_timing_synch;

-- fastest lsfr
architecture lsfr_1 of VGA_timing_synch is

signal QR1 : std_logic_vector (9 downto 0) := "0000000001";
signal hsync_set, hsync_reset : std_logic := '1';

signal QR2 : std_logic_vector (18 downto 0) := "0000000000000000001";
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
--  variable debug : string (1 to 7) := "DEBUG: ";
--begin
--  if (rising_edge (clk25)) then
--    assert (QR1 /= "0000000001") report debug & "ping on h 1" severity note;
--    assert (QR2 /= "0000000000000000001") report debug & "ping on v 1" severity note;
--  end if;
--end process;
----synthesis translate_on

lsfr_h : process (clk25) is
begin
  if (rising_edge (clk25)) then
    QR1(9)  <= QR1(8);
    QR1(8)  <= QR1(7);
    QR1(7)  <= QR1(6) XOR QR1(9);
    QR1(6)  <= QR1(5);
    QR1(5)  <= QR1(4);
    QR1(4)  <= QR1(3);
    QR1(3)  <= QR1(2);
    QR1(2)  <= QR1(1);
    QR1(1)  <= QR1(0);
    QR1(0)  <= QR1(9);
    if (QR1 = c_hsync_01) then
      QR1 <= "0000000001";
    end if;
  end if;
end process lsfr_h;

lsfr_v : process (clk25) is
begin
  if (rising_edge (clk25)) then
    QR2(18) <= QR2(17) XOR QR2(18);
    QR2(17) <= QR2(16) XOR QR2(18);
    QR2(16) <= QR2(15);
    QR2(15) <= QR2(14);
    QR2(14) <= QR2(13) XOR QR2(18);
    QR2(13) <= QR2(12);
    QR2(12) <= QR2(11);
    QR2(11) <= QR2(10);
    QR2(10) <= QR2(9);
    QR2(9)  <= QR2(8);
    QR2(8)  <= QR2(7);
    QR2(7)  <= QR2(6);
    QR2(6)  <= QR2(5);
    QR2(5)  <= QR2(4);
    QR2(4)  <= QR2(3);
    QR2(3)  <= QR2(2);
    QR2(2)  <= QR2(1);
    QR2(1)  <= QR2(0);
    QR2(0)  <= QR2(18);
    if (QR2 = c_vsync_10) then
      QR2 <= "0000000000000000001";
    end if;
  end if;
end process lsfr_v;

-- better than if/elsif (process) or when/else (latch) in RTL schematic
-- but slowest in syn reports
hsync_gen1 : process (clk25) is
begin
  if (rising_edge (clk25)) then
  case (hs_gen_state) is
    when hs_gen_set =>
      if (QR1 = c_hsync_10) then
        hs_gen_state <= hs_gen_reset;
        hsync_set <= '0';
        hsync_reset <= '1';
      end if;
    when hs_gen_reset =>
      if (QR1 = c_hsync_01) then
        hs_gen_state <= hs_gen_set;
        hsync_set <= '1';
        hsync_reset <= '0';
      end if;
    end case;
  end if;
end process hsync_gen1;

hsync_gen_fdcpe : FDCPE
port map (
  Q   => Hsync,
  CLR => hsync_reset,
  PRE => hsync_set,
  C   => clk25,
  CE  => '0',
  D   => '0'
);

-- better than if/elsif (process) or when/else (latch) in RTL schematic
-- but slowest in syn reports
vsync_gen1 : process (clk25) is
begin
  if (rising_edge (clk25)) then
  case (vs_gen_state) is
    when vs_gen_set =>
      if (QR2 = c_vsync_10) then
        vs_gen_state <= vs_gen_reset;
        vsync_set <= '0';
        vsync_reset <= '1';
      end if;
    when vs_gen_reset =>
      if (QR2 = c_vsync_01) then
        vs_gen_state <= vs_gen_set;
        vsync_set <= '1';
        vsync_reset <= '0';
      end if;
    end case;
  end if;
end process vsync_gen1;

vsync_gen_fdcpe : FDCPE
port map (
  Q   => Vsync,
  CLR => vsync_reset,
  PRE => vsync_set,
  C   => clk25,
  CE  => '0',
  D   => '0'
);

end architecture lsfr_1;

-- aggregate lsfr
architecture lsfr_2 of VGA_timing_synch is

signal QR1 : std_logic_vector (9 downto 0) := "0000000001";
signal hsync_set, hsync_reset : std_logic := '1';

signal QR2 : std_logic_vector (9 downto 0) := "0000000001";
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
--  variable debug : string (1 to 7) := "DEBUG: ";
--begin
--  if (rising_edge (clk25)) then
--    assert (QR1 /= "0000000001") report debug & "ping on h 1" severity note;
--    assert (QR2 /= "0000000000000000001") report debug & "ping on v 1" severity note;
--  end if;
--end process;
----synthesis translate_on

lsfr_h : process (clk25) is
begin
  if (rising_edge (clk25)) then
    QR1(9)  <= QR1(8);
    QR1(8)  <= QR1(7);
    QR1(7)  <= QR1(6) XOR QR1(9);
    QR1(6)  <= QR1(5);
    QR1(5)  <= QR1(4);
    QR1(4)  <= QR1(3);
    QR1(3)  <= QR1(2);
    QR1(2)  <= QR1(1);
    QR1(1)  <= QR1(0);
    QR1(0)  <= QR1(9);
    if (QR1 = c_hsync_01) then
      QR1 <= "0000000001";
    end if;
  end if;
end process lsfr_h;

lsfr_v : process (clk25) is
begin
  if (rising_edge (clk25)) then
    if (QR1 <= "0000000001") then
      QR2(9)  <= QR2(8);
      QR2(8)  <= QR2(7);
      QR2(7)  <= QR2(6) XOR QR2(9);
      QR2(6)  <= QR2(5);
      QR2(5)  <= QR2(4);
      QR2(4)  <= QR2(3);
      QR2(3)  <= QR2(2);
      QR2(2)  <= QR2(1);
      QR2(1)  <= QR2(0);
      QR2(0)  <= QR2(9);
      if (QR2 = c_vsync_01) then
        QR2 <= "0000000001";
      end if;
    end if;
  end if;
end process lsfr_v;

-- better than if/elsif (process) or when/else (latch) in RTL schematic
-- but slowest in syn reports
hsync_gen1 : process (clk25) is
begin
  if (rising_edge (clk25)) then
  case (hs_gen_state) is
    when hs_gen_set =>
      if (QR1 = c_hsync_10) then
        hs_gen_state <= hs_gen_reset;
        hsync_set <= '0';
        hsync_reset <= '1';
      end if;
    when hs_gen_reset =>
      if (QR1 = c_hsync_01) then
        hs_gen_state <= hs_gen_set;
        hsync_set <= '1';
        hsync_reset <= '0';
      end if;
    end case;
  end if;
end process hsync_gen1;

hsync_gen_fdcpe : FDCPE
port map (
  Q   => Hsync,
  CLR => hsync_reset,
  PRE => hsync_set,
  C   => clk25,
  CE  => '0',
  D   => '0'
);

-- better than if/elsif (process) or when/else (latch) in RTL schematic
-- but slowest in syn reports
vsync_gen1 : process (clk25) is
begin
  if (rising_edge (clk25)) then
  case (vs_gen_state) is
    when vs_gen_set =>
      if (QR2 = c_vsync_10) then
        vs_gen_state <= vs_gen_reset;
        vsync_set <= '0';
        vsync_reset <= '1';
      end if;
    when vs_gen_reset =>
      if (QR2 = c_vsync_01) then
        vs_gen_state <= vs_gen_set;
        vsync_set <= '1';
        vsync_reset <= '0';
      end if;
    end case;
  end if;
end process vsync_gen1;

vsync_gen_fdcpe : FDCPE
port map (
  Q   => Vsync,
  CLR => vsync_reset,
  PRE => vsync_set,
  C   => clk25,
  CE  => '0',
  D   => '0'
);

end architecture lsfr_2;

-- johnson counter
architecture jc of VGA_timing_synch is

signal jc_1 : std_logic_vector (799 downto 0) := '0'& (798 downto 0 => '1');
signal jc_2 : std_logic_vector (524 downto 0) := '0'& (523 downto 0 => '1');
signal clk_vga, Hsync1, Vsync1, activeArea1_sig1, blank1 : std_logic := '1';

begin

-- big JC counting 800/525

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
      Hsync <= '1';
		elsif (jc_1(656) = '0') then
			Hsync <= '0';
		end if;
	end if;
end process hsync_gen1;

vsync_gen1 : process(clk25) begin
	if rising_edge(clk25) then
    if (jc_2(492) = '0') then
      Vsync <= '1';
		elsif (jc_2(490) = '0') then
			Vsync <= '0';
		end if;
	end if;
end process vsync_gen1;

active_area_jc : process(clk_vga) begin
	if rising_edge(clk_vga) then
    if (jc_1(639) = '0') then
      activeArea1 <= '0';
    elsif (jc_1(799) = '0') then
      activeArea1 <= '1';
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
architecture counter of VGA_timing_synch is

constant HD : INTEGER := 640;
constant HF : INTEGER := 16;
constant HB : INTEGER := 48;
constant HR : INTEGER := 96;
constant HP : INTEGER := HD + HF + HB + HR - 1;
constant VD : INTEGER := 480;
constant VF : INTEGER := 11;
constant VB : INTEGER := 31;
constant VR : INTEGER := 2;
constant VP : INTEGER := VD + VF + VB + VR - 1;

signal clk_vga : STD_LOGIC;
signal hcnt,vcnt : INTEGER range 0 to 1023 := 0;

signal activeArea1_sig : std_logic;

begin

clk_vga <= clk25;

count_proc : process(clk_vga,vcnt,hcnt) begin
		if rising_edge(clk_vga) then
      if (rst = '1') then
        hcnt <= 0;
        vcnt <= 0;
      else
        if (hcnt = HP) then
          hcnt <= 0;
          if (vcnt = VP) then
            vcnt <= 0;
          else
            vcnt <= vcnt + 1;
          end if;
        else
          hcnt <= hcnt +1;
        end if;
      end if;
		end if;
end process count_proc;

hsync_gen : process(clk_vga) begin
	if rising_edge(clk_vga) then
    if (rst = '1') then
      Hsync <= '1';
    else
      if (hcnt >= (HD+HF) and hcnt <= (HD+HF+HR-1)) then
        Hsync <= '0';
      else
        Hsync <= '1';
      end if;
    end if;
	end if;
end process hsync_gen;

vsync_gen : process(clk_vga) begin
	if rising_edge(clk_vga) then
    if (rst = '1') then
      Vsync <= '1';
    else
      if (vcnt >= (VD + VF) and vcnt <= (VD + VF + VR - 1)) then
        Vsync <= '0';
      else
        Vsync <= '1';
      end if;
    end if;
	end if;
end process vsync_gen;

activeArea1_sig <= '1' when (hcnt < HD) and (vcnt < VD) else '0';
activeArea1 <= activeArea1_sig;
blank <= '1' when ((hcnt >= HD) or (vcnt >= VD)) else '0';
--blank <= not activeArea1_sig;

end architecture counter;
