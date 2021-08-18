-- libraries -------------------------------------------------------------------------------------------{{{
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.all;
use work.FGPU_definitions.all;
---------------------------------------------------------------------------------------------------------}}}
entity regFile is
  generic (reg_file_block_width : integer := REG_FILE_BLOCK_W;
           reg_file_data_width  : integer := DATA_W);
port(
  rs_addr, rt_addr    : in unsigned(reg_file_block_width-1 downto 0); -- level 2.
  rd_addr             : in unsigned(reg_file_block_width-1 downto 0); -- level 2.
  re                  : in std_logic; -- level 2.

  rs                  : out std_logic_vector(reg_file_data_width-1 downto 0):= (others=>'0'); -- level 7.
  rt                  : out std_logic_vector(reg_file_data_width-1 downto 0):= (others=>'0'); -- level 6.
  rd                  : out std_logic_vector(reg_file_data_width-1 downto 0):= (others=>'0'); -- level 8.

  we                  : in std_logic; -- level 18.
  wrAddr              : in unsigned(reg_file_block_width-1 downto 0); -- level 18.
  wrData              : in std_logic_vector(reg_file_data_width-1 downto 0); -- level 18.

  mrs_addr, mrt_addr  : in unsigned(reg_file_block_width-1 downto 0);
  mrx_addr            : in unsigned(reg_file_block_width-1 downto 0);
  mre                 : in std_logic;

  mrs                 : out std_logic_vector(reg_file_data_width-1 downto 0) := (others=>'0');
  mrt                 : out std_logic_vector(reg_file_data_width-1 downto 0) := (others=>'0');
  mrx                 : out std_logic_vector(reg_file_data_width-1 downto 0) := (others=>'0');

  mwe                 : in std_logic;
  mwrAddr             : in unsigned(reg_file_block_width-1 downto 0);
  mwrData             : in std_logic_vector(reg_file_data_width-1 downto 0);

  clk                 : in std_logic
);
end entity;

architecture Behavioral of regFile is
  component regfile_qp_block is
      port (
          data_a          : in  std_logic_vector(31 downto 0) := (others => 'X'); -- datain_a
          q_a             : out std_logic_vector(31 downto 0);                    -- dataout_a
          data_b          : in  std_logic_vector(31 downto 0) := (others => 'X'); -- datain_b
          q_b             : out std_logic_vector(31 downto 0);                    -- dataout_b
          write_address_a : in  std_logic_vector(8 downto 0)  := (others => 'X'); -- write_address_a
          write_address_b : in  std_logic_vector(8 downto 0)  := (others => 'X'); -- write_address_b
          read_address_a  : in  std_logic_vector(8 downto 0)  := (others => 'X'); -- read_address_a
          read_address_b  : in  std_logic_vector(8 downto 0)  := (others => 'X'); -- read_address_b
          wren_a          : in  std_logic                     := 'X';             -- wren_a
          wren_b          : in  std_logic                     := 'X';             -- wren_b
          clock           : in  std_logic                     := 'X'              -- clk
      );
  end component regfile_qp_block;

  -- signals definitions {{{
  signal regFile_rdAddr                   : unsigned(reg_file_block_width-1 downto 0) := (others=>'0');
  signal regFile_rdAddr_n                 : unsigned(reg_file_block_width-1 downto 0) := (others=>'0');
  signal regFile_outData                  : std_logic_vector(reg_file_data_width-1 downto 0) := (others => '0');
  signal regFile_outData_n                : std_logic_vector(reg_file_data_width-1 downto 0) := (others => '0');
  signal clk_stable_int                   : std_logic;

  --type reg_array is array (natural range <>) of std_logic_vector(reg_file_data_width-1 downto 0);
  --signal regFile512: reg_array(0 to 2**reg_file_block_width-1) := (others => (others => '0'));

  type read_state_type is (prepare_rt_addr, read_rs, read_rt, read_rd);
  signal state, state_n                   : read_state_type := prepare_rt_addr;
  type read_state_vec_type is array (natural range<>) of read_state_type;
  signal state_vec                        : read_state_vec_type(5 downto 0) := (others=>prepare_rt_addr);
  signal rs_n, rt_n, rd_n                 : std_logic_vector(reg_file_data_width-1 downto 0):= (others=>'0');
  signal we_d0                            : std_logic := '0';
  signal wrAddr_clk2x                     : unsigned(reg_file_block_width-1 downto 0) := (others=>'0');
  signal wrData_d0                        : std_logic_vector(reg_file_data_width-1 downto 0) := (others=>'0');
  signal wrAddr_d0                        : unsigned(reg_file_block_width-1 downto 0) := (others=>'0');

  signal regFile_rdAddr2                  : unsigned(reg_file_block_width-1 downto 0) := (others=>'0');
  signal regFile_rdAddr2_n                : unsigned(reg_file_block_width-1 downto 0) := (others=>'0');
  signal regFile_outData2                 : std_logic_vector(reg_file_data_width-1 downto 0) := (others => '0');
  signal regFile_outData2_n               : std_logic_vector(reg_file_data_width-1 downto 0) := (others => '0');
  signal state2, state2_n                 : read_state_type := prepare_rt_addr;
  signal state2_vec                       : read_state_vec_type(5 downto 0) := (others=>prepare_rt_addr);
  signal mrs_n, mrt_n                     : std_logic_vector(reg_file_data_width-1 downto 0):= (others=>'0');
  signal mwe_d0                           : std_logic := '0';
  signal mwrData_d0                       : std_logic_vector(reg_file_data_width-1 downto 0) := (others=>'0');
  signal mwrAddr_d0                       : unsigned(reg_file_block_width-1 downto 0) := (others=>'0');
  -- }}}
begin
  -- port 1
  process(state, re, rs_addr, rt_addr, rd_addr, regFile_rdAddr)
  begin
    state_n <= state;
    regFile_rdAddr_n <= regFile_rdAddr;
    case state is
      when prepare_rt_addr => 
        if re = '1' then -- level 2.
          state_n <= read_rt;
          regFile_rdAddr_n <= rt_addr;
        end if;
      when read_rt => -- level 3.
        regFile_rdAddr_n <= rs_addr;
        state_n <= read_rs;
      when read_rs => -- level 4.
        regFile_rdAddr_n <= rd_addr;
        state_n <= read_rd;
      when read_rd => -- level 5
        state_n <= prepare_rt_addr;
    end case;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      state <= state_n; -- @ 3. reset not necesary since the FSM will go always to the first state and waits until re = '1'
      state_vec(state_vec'high-1 downto 0) <= state_vec(state_vec'high downto 1); -- @ 5.->8.
      state_vec(state_vec'high) <= state; -- @ 4.
      regFile_rdAddr <= regFile_rdAddr_n; -- rt @ 3., rs @ 4., rd @ 5.

      we_d0 <= we; -- @ 19.
      wrData_d0 <= wrData; -- @ 19.
      wrAddr_d0 <= wrAddr; -- @ 19.
      case state_vec(state_vec'high-1) is -- level 5.
        when prepare_rt_addr =>
        when read_rt =>
          rt <= regFile_outData; -- @ 6.
        when read_rs =>
          rs <= regFile_outData; -- @ 7.
        when read_rd =>
          rd <= regFile_outData; -- @ 8.
      end case;
    end if;
  end process;

  -- port 2
  process(state2, mre, mrs_addr, mrt_addr, mrx_addr, regFile_rdAddr2)
  begin
    state2_n <= state2;
    regFile_rdAddr2_n <= regFile_rdAddr2;
    case state2 is
      when prepare_rt_addr => 
        if mre = '1' then -- level 2.
          state2_n <= read_rt;
          regFile_rdAddr2_n <= mrt_addr;
        else
          regFile_rdAddr2_n <= mrx_addr;
        end if;
      when read_rt => -- level 3.
        regFile_rdAddr2_n <= mrs_addr;
        state2_n <= read_rs;
      when read_rs => -- level 4.
        regFile_rdAddr2_n <= mrx_addr;
        state2_n <= prepare_rt_addr;
      when read_rd =>
    end case;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      state2 <= state2_n; -- @ 3. reset not necesary since the FSM will go always to the first state and waits until re = '1'
      state2_vec(state2_vec'high-1 downto 0) <= state2_vec(state2_vec'high downto 1); -- @ 5.->8.
      state2_vec(state2_vec'high) <= state2; -- @ 4.
      regFile_rdAddr2 <= regFile_rdAddr2_n;

      mwe_d0 <= mwe; -- @ 19.
      mwrData_d0 <= mwrData; -- @ 19.
      mwrAddr_d0 <= mwrAddr; -- @ 19.
      mrx <= regFile_outData2;
      case state2_vec(state2_vec'high-1) is -- level 5.
        when prepare_rt_addr =>
        when read_rt =>
          mrt <= regFile_outData2; -- @ 6.
        when read_rs =>
          mrs <= regFile_outData2; -- @ 7.
        when read_rd =>
      end case;
    end if;
  end process;

  --regFile_Instance: process (clk)
  --begin
  --  if (clk'event and clk = '1') then
  --    regFile_rdAddr <= regFile_rdAddr_n; -- rt @ 3., rs @ 4., rd @ 5.
  --    if we_d0 = '1' then -- level 19.
  --      regFile512(to_integer(wrAddr_d0)) <= wrData_d0; -- @ 20.
  --    end if;
  --    regFile_outData_n <= regFile512(to_integer(regFile_rdAddr)); -- rt @ 4., rs @ 5., rd @ 6.
  --    regFile_outData <= regFile_outData_n; -- rt @ 5., rs @ 6., rd @ 7.
  --  end if;
  --end process;
  
  regFile_inst : component regfile_qp_block
      port map (
          data_a          => wrData_d0,          --          data_a.datain_a
          q_a             => regFile_outData,             --             q_a.dataout_a
          data_b          => mwrData_d0,          --          data_b.datain_b
          q_b             => regFile_outData2,             --             q_b.dataout_b
          write_address_a => std_logic_vector(wrAddr_d0), -- write_address_a.write_address_a
          write_address_b => std_logic_vector(mwrAddr_d0), -- write_address_b.write_address_b
          read_address_a  => std_logic_vector(regFile_rdAddr),  --  read_address_a.read_address_a
          read_address_b  => std_logic_vector(regFile_rdAddr2),  --  read_address_b.read_address_b
          wren_a          => we_d0,          --          wren_a.wren_a
          wren_b          => mwe_d0,          --          wren_b.wren_b
          clock           => clk            --           clock.clk
      );

end Behavioral;

