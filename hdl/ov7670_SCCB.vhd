--------------------------------------------------------
-- Read Datasheet for further knowledge.
-- Thanks to Mike Field for the design
--------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library work;
use work.p_constants.all;

entity ov7670_sccb is
generic (
  c_module_mode : module_mode_st := c_module_mode_syn
);
port (
  i_clock    : in  std_logic;
  i_reset    : in  std_logic;
  reg_value  : in  std_logic_vector (7 downto 0);
  slave_addr : in  std_logic_vector (7 downto 0);
  addr_reg   : in  std_logic_vector (7 downto 0);
  send       : in  std_logic;
  siodo      : out std_logic;
  sioc       : out std_logic;
  taken      : out std_logic
);
end entity ov7670_sccb;

architecture behavioral of ov7670_sccb is 

  -- Scaler is being used to manipulate the siod and sioc timing based on 50MHz clock,
  -- See datasheet for timing.(View Tcyc (SCCB app.note) and Taa & Tdh (OV7670/7671 datasheet). 
  -- Status Register is adjusted from pg. 10 SCCB app. note
  signal scaler  : unsigned (7 downto 0) := x"01";
  signal busy_sr : std_logic_vector(31 downto 0) := (others => '0');
  signal data_sr : std_logic_vector(31 downto 0) := (others => '1');
  signal sioc_i  : std_logic;
  signal taken_i : std_logic;
  signal addr_reg_prev, reg_value_prev : std_logic_vector (7 downto 0);

begin

  taken <= taken_i;

  process (i_clock) is
  begin
    if (rising_edge (i_clock)) then
      if (taken_i = '1') then
        addr_reg_prev  <= addr_reg;
        reg_value_prev <= reg_value;
      end if;
    end if;
  end process;

  process (busy_sr, data_sr (31), addr_reg, reg_value) is
  begin
    if (
      busy_sr (11 downto 10) = "10" or 
      busy_sr (20 downto 19) = "10" or
      busy_sr (29 downto 28) = "10"
    ) then
      siodo <= '1'; -- don't care bit, see pg.10 and pg.13.
    else
      if (addr_reg /= x"ff" and reg_value /= x"fe") then 
        siodo <= data_sr (31); -- serial (i2c like)
      else
        siodo <= '1'; -- wait
      end if;
    end if;
  end process;

  process (addr_reg, reg_value, sioc_i) is
  begin
    if (addr_reg /= x"ff" and reg_value /= x"fe") then
      sioc <= sioc_i;
    else
      sioc <= '1'; -- wait
    end if;
  end process;

  process (i_clock) begin
    if (rising_edge (i_clock)) then
      taken_i <= '0';
      if (busy_sr(31) = '0') then
        sioc_i <= '1';
        if (send = '1') then
          if (scaler = "00000000") then
            data_sr <= "100" & slave_addr & '0' & addr_reg_prev & '0' & reg_value_prev & '1' & "01"; -- see pg.10
            busy_sr <= "111" & "11111111" & "1" & "11111111"    & "1" & "11111111"     & "1" & "11";
            if (addr_reg /= x"ff" and reg_value /= x"fe") then
              taken_i <= '1';
            end if;
          else
            scaler <= scaler + 1; -- this only happens once each cycle
          end if;
        end if;
      else
        case (busy_sr (31 downto 29) & busy_sr (2 downto 0)) is
          when "111" & "111" => -- start seq #1
            sioc_i <= '1';
          when "111" & "110" => -- start seq #2
            sioc_i <= '1';
          when "111" & "100" => -- start seq #3
            sioc_i <= '0';
          when "110" & "000" => -- end seq #1
            case (scaler (7 downto 6)) is
              when "00"   => sioc_i <= '0';
              when "01"   => sioc_i <= '1';
              when "10"   => sioc_i <= '1';
              when others => sioc_i <= '1';
            end case;
          when "100" & "000" => -- end seq #2
            case (scaler (7 downto 6)) is
              when "00"   => sioc_i <= '1';
              when "01"   => sioc_i <= '1';
              when "10"   => sioc_i <= '1';
              when others => sioc_i <= '1';
            end case;
          when "000" & "000" => -- idle
            case (scaler (7 downto 6)) is
              when "00"   => sioc_i <= '1';
              when "01"   => sioc_i <= '1';
              when "10"   => sioc_i <= '1';
              when others => sioc_i <= '1';
            end case;
          when others => -- normal waveform, adjusted with taa and tdh. see pg.11-13
            case (scaler (7 downto 6)) is
              when "00"   => sioc_i <= '0';
              when "01"   => sioc_i <= '1';
              when "10"   => sioc_i <= '1';
              when others => sioc_i <= '0';
            end case;
        end case;
        if (scaler = "11111111") then
          busy_sr <= busy_sr (30 downto 0) & '0'; -- shift with 0
          data_sr <= data_sr (30 downto 0) & '1'; -- shift with 1
          scaler  <= (others => '0');
        else
          scaler <= scaler + 1;
        end if;
      end if;
    end if;
  end process;

end architecture behavioral;

