library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
library unisim;
use unisim.vcomponents.all;

-- based on project https://github.com/nmikstas/cmos-camera.git
entity cellular_ram_burst_controller is
  port (
    -- System
    clk     : in  std_logic;
    reset   : in  std_logic;
    busy    : out std_logic;
    -- Control
    writes : in std_logic;
    id     : in std_logic_vector (15 downto 0);
    data   : in std_logic_vector (15 downto 0);
    -- Input
    write_buffer_clk  : in std_logic;
    write_buffer_we   : in std_logic;
    write_buffer_addr : in std_logic_vector (10 downto 0);
    write_buffer_data : in std_logic_vector (15 downto 0);
    -- Output
    read_buffer_clk  : in  std_logic;
    read_buffer_addr : in  std_logic_vector (9 downto 0);
    read_buffer_data : out std_logic_vector (15 downto 0);
    data_out_enable  : out std_logic_vector (15 downto 0);
    -- Memory interface
    o_wait  : in  std_logic;
    dq_i    : in  std_logic_vector (15 downto 0);
    lb      : out std_logic;
    ub      : out std_logic;
    oe      : out std_logic;
    we      : out std_logic;
    adv     : out std_logic;
    ce      : out std_logic;
    cre     : out std_logic;
    ram_clk : out std_logic;
    a       : out std_logic_vector (22 downto 0);
    dq_o    : out std_logic_vector (15 downto 0)
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
  constant wait_polarity_high      : std_logic := '1';
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
  constant burst_write             : std_logic_vector (15 downto 0) := x"0050";
  constant burst_read              : std_logic_vector (15 downto 0) := x"0051";
  constant write_length            : std_logic_vector (15 downto 0) := x"0052";
  constant read_length             : std_logic_vector (15 downto 0) := x"0053";
  constant write_addr_h            : std_logic_vector (15 downto 0) := x"0054";
  constant write_addr_l            : std_logic_vector (15 downto 0) := x"0055";
  constant read_addr_h             : std_logic_vector (15 downto 0) := x"0056";
  constant read_addr_l             : std_logic_vector (15 downto 0) := x"0057";
  constant set_wb_addr             : std_logic_vector (15 downto 0) := x"0058";
  constant set_rb_addr             : std_logic_vector (15 downto 0) := x"0059";

  signal sink_we          : std_logic;
  signal source_data      : std_logic_vector (15 downto 0);
  signal sink_addr        : unsigned (9 downto 0);
  signal source_addr      : unsigned (9 downto 0);
  signal burst_write_addr : unsigned (22 downto 0);
  signal bytes_to_write   : unsigned (10 downto 0);
  signal this_write_addr  : unsigned (22 downto 0);
  signal write_counter    : unsigned (10 downto 0);
  signal burst_read_addr  : unsigned (22 downto 0);
  signal bytes_to_read    : unsigned (10 downto 0);
  signal this_read_addr   : unsigned (22 downto 0);
  signal read_counter     : unsigned (10 downto 0);
     
  type states is (
    idle,
    config0,
    config1,
    config2,
    config3,
    config4,
    config5,
    config6,
    config7,
    config8,
    config9,
    config10,
    config11,
    write_byte0,
    write_byte1,
    write_byte2,
    write_byte3,
    write_byte4,
    write_rbc0,
    write_rbc1,
    read_byte0,
    read_byte1,
    read_byte2,
    read_byte3,
    read_byte4,
    read_rbc0,
    read_rbc1
  );
  signal state, next_state : states := config0;

  component asym_ram_sdp_read_wider
  port (
    clka  : in  std_logic;
    clkb  : in  std_logic;
    enaa  : in  std_logic;
    wea   : in  std_logic;
    enab  : in  std_logic;
    reset : in  std_logic;
    addra : in  std_logic_vector (10 downto 0);
    addrb : in  std_logic_vector (9 downto 0);
    dia   : in  std_logic_vector (15 downto 0);
    dob   : out std_logic_vector (15 downto 0)
  );
  end component asym_ram_sdp_read_wider;

  signal state_cntr        : unsigned (7 downto 0);
  signal busy_i            : std_logic;
  signal we_i              : std_logic;
  signal sink_read_addrb   : std_logic_vector (9 downto 0);
  signal data_out_enable_i : std_logic_vector (15 downto 0);

begin

  lb              <= '0';
  ub              <= '0';
  we              <= we_i;
  busy            <= busy_i;
  data_out_enable <= data_out_enable_i;
  sink_read_addrb <= read_buffer_addr;
  
  dq_o <=
    source_data when data_out_enable_i = x"ffff" else
    x"0000";
  busy_i <=
    '0' when (state = idle) else
    '1';
  ram_clk <=
    not clk when (
      state = write_byte1 or
      state = write_byte2 or
      state = write_byte3 or 
      state = read_byte1  or
      state = read_byte2  or
      state = read_byte3)
    else '0';

  write_buffer_i0 : asym_ram_sdp_read_wider
  port map (
    reset => reset,
    clka  => write_buffer_clk,
    enaa  => write_buffer_we,
    wea   => write_buffer_we,
    addra => write_buffer_addr,
    dia   => write_buffer_data,
    clkb  => clk,
    enab  => '1',
    addrb => std_logic_vector (source_addr),
    dob   => source_data
  );
  
  read_buffer_i0 : entity work.sink_read_1
    port map (
      clka   => clk,
      wea(0) => sink_we,
      addra  => std_logic_vector (sink_addr),
      dina   => dq_i,
      clkb   => read_buffer_clk,
      addrb  => sink_read_addrb,
      doutb  => read_buffer_data
    );
  
  p2_next_state : process (clk) is
  begin
    if (rising_edge (clk)) then
      if (reset = '1') then
        state <= config0;
      else
        state <= next_state;
        if (
          id = burst_read and
          writes = '1'    and
          busy_i = '0'    and
          bytes_to_read > 0
        ) then
          state <= read_byte0;
          --report "burst read";
        end if;
        if (
          id = burst_write and
          writes = '1'     and
          busy_i = '0'     and
          bytes_to_write > 0
        ) then
          state <= write_byte0;
          --report "burst write";
        end if;
      end if;
    end if;
  end process p2_next_state;
  
  p3_b2w : process (clk) is
  begin
    if (rising_edge (clk)) then
      if (reset = '1') then
        bytes_to_write <= (others => '0');
      else
        if (
          id = write_length and
          writes = '1'      and
          busy_i = '0'
        ) then
          bytes_to_write <= unsigned (data (10 downto 0));
          --report "write length " & integer'image (to_integer (unsigned (data (10 downto 0))));
        end if;
      end if;
    end if;
  end process p3_b2w;
  
  p4_b2r: process (clk) is
  begin
    if (rising_edge (clk)) then
      if (reset = '1') then
        bytes_to_read <= (others => '0');
      else
        if (
          id = read_length and
          writes = '1'     and
          busy_i = '0'
        ) then
          bytes_to_read <= unsigned (data (10 downto 0));
          --report "read length " & integer'image (to_integer (unsigned (data (10 downto 0))));
        end if;
      end if;
    end if;
  end process p4_b2r;
  
  p5_bwah : process (clk) is
  begin
    if (rising_edge (clk)) then
      if (reset = '1') then
        burst_write_addr (22 downto 16) <= (others => '0');
      else
        if (
          id = write_addr_h and
          writes = '1'      and
          busy_i = '0'
        ) then
          burst_write_addr (22 downto 16) <= unsigned (data (6 downto 0));
        end if;
      end if;
    end if;
  end process p5_bwah;
  
  p6_bwal : process (clk) is
  begin
    if (rising_edge (clk)) then
      if (reset = '1') then
        burst_write_addr (15 downto 0) <= (others => '0');
      else
        if (
          id = write_addr_l and
          writes = '1'      and
          busy_i = '0'
        ) then 
          burst_write_addr (15 downto 0) <= unsigned (data);
        end if;
      end if;
    end if;
  end process p6_bwal;
  
  p7_brah : process (clk) is
  begin
    if (rising_edge (clk)) then
      if (reset = '1') then
        burst_read_addr (22 downto 16) <= (others => '0');
      else
        if (
          id = read_addr_h and
          writes = '1'     and
          busy_i = '0'
        ) then
          burst_read_addr (22 downto 16) <= unsigned (data (6 downto 0));
        end if;
      end if;
    end if;
  end process p7_brah;
  
  p8_bral : process (clk) is
  begin
    if (rising_edge (clk)) then
      if (reset = '1') then
        burst_read_addr (15 downto 0) <= (others => '0');
      else
        if (
          id = read_addr_l and
          writes = '1'     and
          busy_i = '0'
        ) then
          burst_read_addr (15 downto 0) <= unsigned (data);
        end if;
      end if;
    end if;
  end process p8_bral;
  
  p9_sink : process (clk) is
  begin
    if (rising_edge (clk)) then
      if (reset = '1') then
        sink_addr <= (others => '0');
        sink_we   <= '0';
      else
        if (
          id = set_rb_addr and
          state = idle     and
          writes = '1'     and
          busy_i = '0'
        ) then
          sink_addr <= unsigned (data (9 downto 0));
          --report "set rb addr";
        end if;
        if (state = read_byte1) then
          sink_we <= '0';
        end if;
        if (state = read_byte2) then
          if (o_wait = '0') then
            sink_we <= '1';
          end if;
        end if;
        if (state = read_byte3) then
          if (o_wait = '0') then
            sink_addr <= sink_addr + 1;
            sink_we   <= '1';
          end if;
        end if;
        if (state = read_byte4) then
           sink_we   <= '0';
           sink_addr <= sink_addr + 1;
        end if;
        if (state = read_rbc0) then
          sink_addr <= sink_addr + 1;
        end if;
      end if;
    end if;
  end process p9_sink;

  p10_run : process (clk) is
  begin
    if (rising_edge (clk)) then
      if (reset = '1') then
        source_addr       <= (others => '0');
        this_read_addr    <= (others => '0');
        this_write_addr   <= (others => '0');
        write_counter     <= (others => '0');
        cre               <= '0';
        adv               <= '1';
        ce                <= '1';
        oe                <= '1';
        we_i              <= '1';
        a                 <= (others => '0');
        state_cntr        <= (others => '0');
        data_out_enable_i <= (others => '1');
      else
        if (
          id = set_wb_addr and
          state = idle     and
          writes = '1'     and
          busy_i = '0'
        ) then
          --report "set wb addr";
          source_addr <= unsigned (data (9 downto 0));
        end if;
        if (state = config0) then
          cre          <= '0';
          adv          <= '1';
          ce           <= '1';
          oe           <= '1';
          we_i         <= '1';
          read_counter <= (others => '0'); -- XXX in reset make damaged image
        end if;
        if (state = config1) then
          cre        <= '1';
          state_cntr <= to_unsigned (2, state_cntr'left+1);
          a          <= "000"       &
            register_select_bcr     &
            "00"                    &
            op_mode_synchronous     &
            initial_access_variable &
            latency_counter_code3   &
            wait_polarity_high      &
            "0"                     &
            wait_config_before      &
            "00"                    &
            drive_strength_full     &
            burst_wrap_no           &
            burst_length_cont;
        end if;
        if (state = config2) then
          state_cntr <= state_cntr - 1;
          adv        <= '0';
          ce         <= '0';
          we_i       <= '0';
        end if;
        if (state = config3) then
          state_cntr <= to_unsigned (5, state_cntr'left+1);
          adv        <= '1';
        end if;
        if (state = config4) then
          state_cntr <= state_cntr - 1;
        end if;
        if (state = config5) then
          ce <= '1';
        end if;
        if (state = config6) then
          a    <= (others => '0');
          we_i <= '1';
        end if;
        if (state = config7) then
          state_cntr <= to_unsigned (1, state_cntr'left+1);
          cre        <= '0';
          adv        <= '0';
          ce         <= '0';
          oe         <= '0';
        end if;
        if (state = config8) then
          state_cntr <= state_cntr - 1;
        end if;
        if (state = config9) then
          state_cntr <= to_unsigned (5, state_cntr'left+1);
          adv        <= '1';
        end if;
        if (state = config10) then
          state_cntr <= state_cntr - 1;
        end if;
        if (state = config11) then
          ce <= '1';
          oe <= '1';
        end if;
        if (state = write_byte0) then
          --report "burst write addr " & integer'image (to_integer (unsigned (burst_write_addr)));
          this_write_addr   <= burst_write_addr;
          write_counter     <= bytes_to_write;
          data_out_enable_i <= (others => '1');
          a                 <= std_logic_vector (burst_write_addr);
          adv               <= '0';
          ce                <= '0';
          we_i              <= '0';
        end if;
        if (state = write_byte1) then
          adv <= '1';
        end if;
        if (state = write_byte2) then
          if (o_wait = '0') then
             write_counter <= write_counter - 1;
             source_addr   <= source_addr + 1;
          end if;
        end if;
        if (state = write_byte3) then
          if (o_wait = '0') then
            write_counter <= write_counter - 1;
            source_addr   <= source_addr + 1;
          end if;
          if (write_counter <= 1) then
            we_i <= '1'; 
          end if;        
        end if;
        if (state = write_byte4) then
          if (o_wait = '0') then
            data_out_enable_i <= (others => '0');
            ce                <= '1';
            we_i              <= '1';
          end if;
        end if;
        if (state = write_rbc0) then
          this_write_addr <= burst_write_addr + (bytes_to_write - write_counter - 1);
          write_counter   <= write_counter + 1;
          source_addr     <= source_addr - 1;
          ce              <= '1';
        end if;
        if (state = write_rbc1) then
          a    <= std_logic_vector (this_write_addr);
          ce   <= '0';
          we_i <= '0';
          adv  <= '0';
        end if; 
        if (state = read_byte0) then
          --report "burst read addr " & integer'image (to_integer (unsigned (burst_read_addr)));
          this_read_addr <= burst_read_addr;
          read_counter   <= bytes_to_read;
          a              <= std_logic_vector (burst_read_addr);
          adv            <= '0';
          ce             <= '0';
          we_i           <= '1';
          oe             <= '0';
        end if;
        if (state = read_byte1) then
          read_counter <= read_counter - 1;
          adv <= '1';  
        end if;
        if (state = read_byte2) then
          if (read_counter = 0 and o_wait = '0') then
            ce <= '1';
            oe <= '1';
          end if;
        end if;
        if (state = read_byte3) then
          if (o_wait = '0') then
            read_counter <= read_counter - 1;
          end if;
          if (read_counter <= 1) then
            ce <= '1';
          end if;
        end if;
        if (state = read_byte4) then
           ce         <= '1';
           oe         <= '1';
        end if;
        if (state = read_rbc0) then
          ce             <= '1';
          this_read_addr <= burst_read_addr + (bytes_to_read - read_counter);
        end if;
        if (state = read_rbc1) then
          a   <= std_logic_vector (this_read_addr);
          ce  <= '0';
          adv <= '0';
        end if;
      end if;
    end if;
  end process p10_run;

  p11_state : process (
    state, state_cntr, o_wait, write_counter, read_counter
  ) is
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
                          if (o_wait = '0' and write_counter = 1) then
                            next_state <= write_byte4;
                          elsif (o_wait = '0') then
                            next_state <= write_byte3;
                          else
                            next_state <= write_byte2;
                          end if;
      when write_byte3 =>
                          if (o_wait = '1') then
                            next_state <= write_rbc0;
                          elsif (write_counter <= 1) then
                            next_state <= write_byte4;
                          else
                            next_state <= write_byte3;
                          end if;
      when write_byte4 =>
                          if (o_wait = '1') then
                            next_state <= write_rbc0;
                          else
                            next_state <= idle;
                          end if;
      when write_rbc0  => next_state <= write_rbc1;
      when write_rbc1  => next_state <= write_byte1;
      when read_byte0  => next_state <= read_byte1;
      when read_byte1  => next_state <= read_byte2;
      when read_byte2  =>
                          if (o_wait = '0' and read_counter = 0) then
                            next_state <= read_byte4;
                          elsif (o_wait = '0') then
                            next_state <= read_byte3;
                          else
                            next_state <= read_byte2;
                          end if;
      when read_byte3  =>
                          if (o_wait = '1') then
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
  end process p11_state;

end architecture crbc;
