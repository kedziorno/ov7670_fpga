library ieee;
use ieee.std_logic_1164.all;

-- based on project https://github.com/nmikstas/cmos-camera.git
entity cellular_ram_burst_controller is
port (
  busy : out std_logic;
  clk : in std_logic;
  write : in std_logic;
  data : in std_logic_vector (15 downto 0);
  id : in std_logic_vector (15 downto 0);
  write_buffer_addr : in std_logic_vector (10 downto 0);
  write_buffer_data : in std_logic_vector (7 downto 0);
  write_buffer_clk : in std_logic;
  write_buffer_we : in std_logic;
  read_buffer_addr : in std_logic_vector (9 downto 0);
  read_buffer_data : out std_logic_vector (15 downto 0);
  read_buffer_clk : in std_logic;
  lb : out std_logic := '0';
  ub : out std_logic := '0';
  oe : out std_logic := '1';
  we : out std_logic := '1';
  adv : out std_logic := '1';
  ce : out std_logic := '1';
  cre : out std_logic := '1';
  ram_clk : out std_logic;
  o_wait : in std_logic;
  a : out std_logic_vector (22 downto 0);
  dq : inout std_logic_vector (15 downto 0)
);
end entity cellular_ram_burst_controller;

architecture crbc of cellular_ram_burst_controller is

constant register_select_rcr     : std_logic_vector (1 downto 0) := "00";
constant register_select_bcr     : std_logic_vector (1 downto 0) := "10";
constant register_select_didr    : std_logic_vector (1 downto 0) := "01";
constant op_mode_synchronous     : std_logic := '0';
constant op_mode_asynchronous    : std_logic := '1';
constant initial_access_variable : std_logic := '0';
constant initial_access_fixed    : std_logic := '1';
constant latency_counter_code8   : std_logic_vector (2 downto 0) := "000";
constant latency_counter_code1   : std_logic_vector (2 downto 0) := "001";
constant latency_counter_code2   : std_logic_vector (2 downto 0) := "010";
constant latency_counter_code3   : std_logic_vector (2 downto 0) := "011";
constant latency_counter_code4   : std_logic_vector (2 downto 0) := "100";
constant latency_counter_code5   : std_logic_vector (2 downto 0) := "101";
constant latency_counter_code6   : std_logic_vector (2 downto 0) := "110";
constant latency_counter_code7   : std_logic_vector (2 downto 0) := "111";
constant wait_polarity_low       : std_logic := '0';
constant wait_polarity_high      : std_logic := '0';
constant wait_config_during      : std_logic := '0';
constant wait_config_before      : std_logic := '1';
constant drive_strength_full     : std_logic_vector (1 downto 0) := "00";
constant drive_strength_half     : std_logic_vector (1 downto 0) := "01";
constant drive_strength_quarter  : std_logic_vector (1 downto 0) := "10";
constant burst_wrap_yes          : std_logic := '0';
constant burst_wrap_no           : std_logic := '1';
constant burst_length_4          : std_logic_vector (2 downto 0) := "001";
constant burst_length_8          : std_logic_vector (2 downto 0) := "010";
constant burst_length_16         : std_logic_vector (2 downto 0) := "011";
constant burst_length_32         : std_logic_vector (2 downto 0) := "100";
constant burst_length_cont       : std_logic_vector (2 downto 0) := "111";
constant burst_write             : std_logic_vector (15 downto 0) := "0050";
constant burst_read              : std_logic_vector (15 downto 0) := "0051";
constant write_length            : std_logic_vector (15 downto 0) := "0052";
constant read_length             : std_logic_vector (15 downto 0) := "0053";
constant write_addr_h            : std_logic_vector (15 downto 0) := "0054";
constant write_addr_l            : std_logic_vector (15 downto 0) := "0055";
constant read_addr_h             : std_logic_vector (15 downto 0) := "0056";
constant read_addr_l             : std_logic_vector (15 downto 0) := "0057";
constant set_wb_addr             : std_logic_vector (15 downto 0) := "0058";
constant set_rb_addr             : std_logic_vector (15 downto 0) := "0059";

signal sink_we          : std_logic := '0';
signal sink_addr        : std_logic_vector (9 downto 0) := (others => '0');
signal source_addr      : std_logic_vector (9 downto 0) := (others => '0');
signal source_data      : std_logic_vector (15 downto 0) := (others => '0');
signal burst_write_addr : std_logic_vector (22 downto 0) := (others => '0');
signal bytes_to_write   : std_logic_vector (10 downto 0) := (others => '0');
signal this_write_addr  : std_logic_vector (22 downto 0) := (others => '0');
signal write_counter    : std_logic_vector (10 downto 0) := (others => '0');
signal burst_read_addr  : std_logic_vector (22 downto 0) := (others => '0');
signal bytes_to_read    : std_logic_vector (10 downto 0) := (others => '0');
signal this_read_addr   : std_logic_vector (22 downto 0) := (others => '0');
signal read_counter     : std_logic_vector (10 downto 0) := (others => '0');
     
constant ram_width : integer := 16;
constant ram_addr_bits : integer := 10;
type ram_t is array (2**ram_addr_bits - 1 downto 0) of std_logic_vector (ram_width - 1 downto 0);
signal read_buffer : ram_t;

type states is ( config0, config1, config2, config3, config4, config5, config6, config7, config8, config9, config1, config1, write_byte0, write_byte1, write_byte2, write_byte3, write_byte4, write_rbc0, write_rbc1, read_byte0, read_byte1, read_byte2, read_byte3, read_byte4, read_rbc0, read_rbc1);
signal state, next_state : states := idle;

signal state_cntr : unsigned (7 downto 0) := (others => '0');
signal clk_enable : std_logic := '0';

signal data_out_enable : std_logic_vector (15 downto 0) := (others => '0');

component rambuffer
port (
clka : in std_logic;
wea : in std_logic_vector (0 downto 0);
addra : in std_logic_vector (10 downto 0);
dina : in std_logic_vector (7 downto 0);
clkb : in std_logic;
addrb : in std_logic_vector (9 downto 0);
doutb : out std_logic_vector (15 downto 0)
);
end component rambuffer;

begin

rambuffer_i0 : rambuffer
port map (
  clka => write_buf_clk,
  wea => write_buf_we,
  addra => write_buf_addr,
  dina => write_buf_data,
  clkb => clk,
  addrb => source_addr,
  doutb => source_data
);

dq (0)  <= source_data (0)  when data_out_enable (0)  = '1' else 'z';
dq (1)  <= source_data (1)  when data_out_enable (1)  = '1' else 'z';
dq (2)  <= source_data (2)  when data_out_enable (2)  = '1' else 'z';
dq (3)  <= source_data (3)  when data_out_enable (3)  = '1' else 'z';
dq (4)  <= source_data (4)  when data_out_enable (4)  = '1' else 'z';
dq (5)  <= source_data (5)  when data_out_enable (5)  = '1' else 'z';
dq (6)  <= source_data (6)  when data_out_enable (6)  = '1' else 'z';
dq (7)  <= source_data (7)  when data_out_enable (7)  = '1' else 'z';
dq (8)  <= source_data (8)  when data_out_enable (8)  = '1' else 'z';
dq (9)  <= source_data (9)  when data_out_enable (9)  = '1' else 'z';
dq (10) <= source_data (10) when data_out_enable (10) = '1' else 'z';
dq (11) <= source_data (11) when data_out_enable (11) = '1' else 'z';
dq (12) <= source_data (12) when data_out_enable (12) = '1' else 'z';
dq (13) <= source_data (13) when data_out_enable (13) = '1' else 'z';
dq (14) <= source_data (14) when data_out_enable (14) = '1' else 'z';
dq (15) <= source_data (15) when data_out_enable (15) = '1' else 'z';

ram_clk <= clk when clk_enable = '1' else '0';

busy <= '1' when (state = idle) else '0';

p0_rb : process (clk) is
begin
  if (rising_edge (clk)) then
    if (sink_we) then
      read_buffer (sink_addr) <= dq;
    end if;
  end if;
end process p0_rb;

p1_rb : process (read_buf_clk) is
begin
  if (rising_edge (read_buf_clk)) then
    read_buf_data <= read_buffer (read_buf_addr);
  end if;
end process p1_rb;

p1 : process (clk) is
begin
  if (falling_edge (clk)) then
    state <= next_state;
  end if;
end process p1;

p2 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (id = burst_read and write and not busy and bytes_to_read) then
      state <= read_byte0; 
    end if;
  end if;
end process p2;

p3 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (id = burst_write and write and not busy and bytes_to_write) then
      state <= write_byte0; 
    end if;
  end if;
end process p3;

p4 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (id = write_length and write and not busy) then
      bytes_to_write <= data (10 downto 0); 
    end if;
  end if;
end process p4;

p5 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (id = read_length and write and not busy) then
      bytes_to_read <= data (10 downto 0); 
    end if;
  end if;
end process p5;

p6 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (id = write_addr_h and write and not busy) then
      burst_write_addr (22 downto 16) <= data (6 downto 0);  
    end if;
  end if;
end process p6;

p7 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (id = write_addr_l and write and not busy) then 
      burst_write_addr (15 downto 0) <= data;
    end if;
  end if;
end process p7;

p8 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (id = read_addr_h and write and not busy) then
      burst_read_addr (22 downto 16) <= data (6 downto 0);  
    end if;
  end if;
end process p8;

p9 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (id = read_addr_l and write and not busy) then
      burst_read_addr (15 downto 0) <= data; 
    end if;
  end if;
end process p9;

p10 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (id = set_wb_addr and write and not busy) then
      source_addr <= data (9 downto 0);
    end if;
  end if;
end process p10;

p11 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (id = set_rb_addr and write and not busy) then
      sink_addr <= data (9 downto 0);
    end if;
  end if;
end process p11;

p12 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = config0) then
      clk_enable <= 0;
      cre <= 0;
      adv <= 1;
      ce <= 1;
      oe <= 1;
      we <= 1;              
    end if;
  end if;
end process p12;

p12 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = config1) then
      a <= "000" & register_select_bcr & "00" & op_mode_synchronous &
      initial_access_variable & latency_counter_code3 & wait_polarity_high &
      "0" & wait_config_before & "00" & drive_strength_full &
      burst_wrap_no & burst_length_cont;
      state_cntr <= 2;
      cre <= 1;
    end if;
  end if;
end process p12;

p13 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = config2) then
      state_cntr <= state_cntr - 1;         
      adv <= '0';
      ce <= '0';
      we <= '0';
    end if;
  end if;
end process p13;

p14 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = config3) then
      state_cntr <= 5;
      adv <= '1';
    end if;
  end if;
end process p14;

p15 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = config4) then
      state_cntr <= state_cntr - 1;         
    end if;
  end if;
end process p15;

p16 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = config5) then
      ce <= '1';
    end if;
  end if;
end process p16;

p17 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = config6) then
      a <= (others => '0');
      we <= '1';
    end if;
  end if;
end process p17;

p18 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = config7) then
      state_cntr <= '1';
      cre <= '0';
      adv <= '0';
      ce <= '0';
      oe <= '0';
    end if;
  end if;
end process p18;

p19 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = config8) then
      state_cntr <= state_cntr - 1;             
    end if;
  end if;
end process p19;

p20 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = config9) then
      state_cntr <= 5;          
      adv <= '1';
    end if;
  end if;
end process p20;

p21 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = config10) then
      state_cntr <= state_cntr - 1;         
    end if;
  end if;
end process p21;

p22 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = config11) then
      ce <= '1';
      oe <= '1';
    end if;   
  end if;
end process p22;

p23 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = write_byte0) then
      this_write_addr <= burst_write_addr;
      write_counter <= bytes_to_write;
      data_out_enable <= (others => '1');
      clk_enable <= '1';
      a <= burst_write_addr;
      adv <= '0';
      ce <= '0';
      we <= '0';
    end if;
  end if;
end process p23;

p24 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = write_byte1) then
      adv <= '1';             
    end if;
  end if;
end process p24;

p25 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = write_byte2) then
      if (not o_wait) then
         write_counter <= write_counter - 1;
         source_addr <= source_addr + 1;
      end if;
    end if;
  end if;
end process p25;

p26 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = write_byte3) then
      if (not o_wait) then
        write_counter <= write_counter - 1;         
        source_addr <= source_addr + 1;
      end if;
      if (writecounter <= 1) then
        we <= '1'; 
      end if;        
    end if;
  end if;
end process p26;

p27 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = write_byte4) then
      if (not o_wait) then
        data_out_enable <= (others => '0');
        clk_enable <= '0';
        ce <= '1';
        we <= '1';
      end if;
    end if;
  end if;
end process p27;

p28 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = write_rbc0) then
      this_write_addr <= burst_write_addr + (bytes_to_write - write_counter - 1);
      write_counter <= write_counter + 1;
      source_addr <= source_addr - 1;
      ce <= '1';
    end if;
  end if;
end process p28;

p29 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = write_rbc1) then
      a <= this_write_addr;
      ce <= '0';
      we <= '0';
      adv <= '0';
    end if; 
  end if;
end process p29;

p30 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = read_byte0) then
      this_read_addr <= burst_read_addr;
      read_counter <= bytes_to_read;
      clk_enable <= '1';
      a <= burst_read_addr;
      adv <= '0';
      ce <= '0';
      we <= '1';
      oe <= '0';
    end if;
  end if;
end process p30;

p31 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = read_byte1) then
      read_counter <= read_counter - 1;
      sink_we <= '0';
      adv <= '1';  
    end if;
  end if;
end process p31;

p32 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = read_byte2) then
      if (not o_wait) then
        sink_we <= '1';
      end if;
      if (not readcounter and not o_wait) then
        ce <= '1';
        oe <= '1';
      end if;
    end if;
  end if;
end process p32;

p33 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = read_byte3) then
      if (not o_wait) then
        read_counter <= read_counter - 1;
        sink_addr <= sink_addr + 1;
        sink_we <= 1;
      end if;
      if (read_counter <= 1) then
        ce <= 1;
      end if;
    end if;
  end if;
end process p33;

p34 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = read_byte4) then
       clk_enable <= '0';
       sink_we <= '0';
       ce <= '1';
       oe <= '1';
       sink_addr <= sink_addr + 1;
    end if;
  end if;
end process p34;

p35 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = read_rbc0) then
      this_read_addr <= burst_read_addr + (bytes_to_read - read_counter);
      sink_addr <= sink_addr + 1;
      ce <= 1;
    end if;
  end if;
end process p35;

p36 : process (clk) is
begin
  if (rising_edge (clk)) then
    if (state = read_rbc1) then
      a <= this_read_addr;
      ce <= '0';
      adv <= '0';
    end if;
  end if;
end process p36;

p37 : process (state, state_cntr) is
begin
  case (state) is
    when config0     => next_state <= config1;
    when config1     => next_state <= config2;
    when config2     =>
                        if (state_cntr = 0) then
                          next_state <= config3;
                        else
                          next_state <= config2;
                        end if;
    when config3     => next_state <= config4;
    when config4     =>
                        if (state_cntr = 0) then
                          next_state <= config5;
                        else
                          next_state <= config4;
                        end if;
    when config5     => next_state <= config6;
    when config6     => next_state <= config7;
    when config7     => next_state <= config8;
    when config8     =>
                        if (state_cntr = 0) then
                          next_state <= config9;
                        else
                          next_state <= config8;
                        end if;
    when config9     => next_state <= config10;
    when config10    =>
                        if (state_cntr = 0) then
                          next_state <= config11;
                        else
                          next_state <= config10;
                        end if;
    when config11    => next_state <= idle;
    when write_byte0 => next_state <= write_byte1;
    when write_byte1 => next_state <= write_byte2;
    when write_byte2 =>
                        if (not o_wait and write_counter = 1) then
                          next_state <= write_byte4;
                        elsif (not o_wait) then
                          next_state <= write_byte3;
                        else
                          next_state <= write_byte2;
                        end if;
    when write_byte3 =>
                        if (o_wait) then
                          next_state <= write_rbc0;
                        elsif (write_counter <= 1) then
                          next_state <= write_byte4;
                        else
                          next_state <= write_byte3;
                        end if;
    when write_byte4 =>
                        if (o_wait) then
                          next_state <= write_rbc0;
                        else
                          next_state <= idle;
                        end if;
    when write_rbc0  => next_state <= write_rbc1;
    when write_rbc1  => next_state <= write_byte1;
    when read_byte0  => next_state <= read_byte1;
    when read_byte1  => next_state <= read_byte2;
    when read_byte2  =>
                        if (o_wait = 0 and read_counter = 0) then
                          next_state <= read_byte4;
                        elsif (o_wait = 0) then
                          next_state <= read_byte3;
                        else
                          next_state <= read_byte2;
                        end if;
    when read_byte3  =>
                        if (o_wait) then
                          next_state <= read_rbc0;
                        elsif (read_counter <= 1) then
                          next_state <= read_byte4;
                        else
                          next_state <= read_byte3;
                        end if;
    when read_byte4  => next_state <= idle;
    when read_rbc0   => next_state <= read_rbc1;
    when read_rbc1   => next_state <= read_byte1;
    when others => next_state <= idle;
  end case;
end process p37; 

end architecture crbc;

