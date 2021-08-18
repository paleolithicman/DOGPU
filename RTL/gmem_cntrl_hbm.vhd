-- libraries -------------------------------------------------------------------------------------------{{{
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.all;
use work.FGPU_definitions.all;
use ieee.std_logic_textio.all;
use std.textio.all;
---------------------------------------------------------------------------------------------------------}}}
entity gmem_cntrl is -- {{{
port(
  clk                 : in std_logic;
  start_kernel        : in std_logic;
  clean_cache         : in std_logic;
  WGsDispatched       : in std_logic;
  CUs_gmem_idle       : in std_logic;
  finish_exec         : out std_logic := '0';

  cu_valid            : in std_logic_vector(1 downto 0);  
  cu_ready            : out std_logic_vector(1 downto 0) := (others=>'0');
  cu_wready           : out std_logic := '0';
  --cu_we               : in be_array(1 downto 0);
  cu_rnw              : in std_logic_vector(1 downto 0);
  --cu_atomic           : in std_logic_vector(1 downto 0);
  --cu_atomic_sgntr     : in atomic_sgntr_array(1 downto 0);
  cu_rqst_addr        : in GMEM_WORD_ADDR_ARRAY(1 downto 0);
  cu_wvalid           : in std_logic;
  cu_wcu_en           : in std_logic_vector(1 downto 0);
  cu_wtype            : in std_logic_vector(2 downto 0);
  cu_waddr            : in std_logic_vector(GMEM_WORD_ADDR_W-GMEM_WR_N_WORDS_W-1 downto 0);
  cu_wrData           : in std_logic_vector(GMEM_WRFIFO_W-GMEM_WORD_ADDR_W+GMEM_WR_N_WORDS_W-516 downto 0);
  cu_wrData_ex        : in std_logic_vector(511 downto 0);
  cu_rdCntrl          : in rd_cntrl_array(1 downto 0) := (others=>(others=>'0'));

  rdAck               : out std_logic_vector(1 downto 0) := (others=>'0');
  rdAddr              : out unsigned(GMEM_WORD_ADDR_W-1-CACHE_N_BANKS_W downto 0) := (others=>'0');
  rdData              : out std_logic_vector(DATA_W*CACHE_N_BANKS-1 downto 0) := (others => '0');
  rdCntrl             : out rd_cntrl_array(1 downto 0) := (others=>(others=>'0'));
  --atomic_rdData       : out std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  --atomic_rdData_v     : out std_logic_vector(1 downto 0) := (others=>'0');
  --atomic_sgntr        : out std_logic_vector(N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  -- AXI Interface signals {{{
  --Read address channel
  axi_araddr          : out unsigned(GMEM_ADDR_W-1 downto 0) := (others=>'0');
  axi_arvalid         : out std_logic := '0';
  axi_arready         : in std_logic := '0';
  axi_arid            : out std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- Read data channel
  axi_rdata           : in std_logic_vector(DATA_W*GMEM_N_BANK-1 downto 0) := (others=>'0');
  axi_rlast           : in std_logic := '0';
  axi_rvalid          : in std_logic := '0';
  axi_rready          : out std_logic := '0';
  axi_rid             : in std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- write address channel
  axi_awaddr          : out unsigned(GMEM_ADDR_W-1 downto 0) := (others=>'0');
  axi_awvalid         : out std_logic := '0';
  axi_awready         : in std_logic := '0';
  axi_awid            : out std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- write data channel
  axi_wdata           : out std_logic_vector(DATA_W*GMEM_N_BANK-1 downto 0) := (others=>'0');
  axi_wstrb           : out std_logic_vector(GMEM_N_BANK*DATA_W/8-1 downto 0) := (others=>'0');
  axi_wlast           : out std_logic := '0';
  axi_wvalid          : out std_logic := '0';
  axi_wready          : in std_logic := '0';
  -- write response channel
  axi_bvalid          : in std_logic := '0';
  axi_bready          : out std_logic := '0';
  axi_bid             : in std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- }}}
  debug_st            : out std_logic_vector(31 downto 0) := (others=>'0');
  nrst                : in std_logic
);
end gmem_cntrl; --}}}
architecture Behavioral of gmem_cntrl is
  component gmem_metaQ is
      port (
          data  : in  std_logic_vector(42 downto 0) := (others => 'X'); -- datain
          wrreq : in  std_logic                     := 'X';             -- wrreq
          rdreq : in  std_logic                     := 'X';             -- rdreq
          clock : in  std_logic                     := 'X';             -- clk
          q     : out std_logic_vector(42 downto 0);                    -- dataout
          full  : out std_logic;                                        -- full
          empty : out std_logic                                         -- empty
      );
  end component gmem_metaQ;

  -- functions ------------------------------------------------------------------ {{{
  function distribute_rcvs_on_CUs (n_rcvs: integer; n_cus: integer) return nat_array is
    variable res: nat_array(n_rcvs-1 downto 0) := (others=>0);
  begin
    for i in 0 to n_rcvs-1 loop
      for k in 0 to n_cus-1 loop
        if i < (k+1)*(n_rcvs/n_cus) and i >= k*(n_rcvs/n_cus) then
          res(i) := k;
          exit;
        end if;
      end loop;
    end loop;
    return res;
  end;
  -------------------------------------------------------------------------------------}}}
  -- Constants & types -------------------------------------------------------------------------------{{{
  CONSTANT c_rcv_cu_indx                  : nat_array(N_RECEIVERS-1 downto 0) := distribute_rcvs_on_CUs(N_RECEIVERS, 2);
  constant META_W                         : integer := N_CU_STATIONS_W+1;
  constant META_CNTRL_LOW                 : integer := 0; -- 0
  constant META_CNTRL_HIGH                : integer := META_CNTRL_LOW+N_CU_STATIONS_W-1; -- 7
  constant META_VALID_POS                 : integer := META_CNTRL_HIGH+1;
  constant META_ADDR_LOW                  : integer := 2*META_W;
  constant META_ADDR_HIGH                 : integer := 2*META_W+GMEM_WORD_ADDR_W-N-1;
  constant META_TOTAL_W                   : integer := 2*META_W+GMEM_WORD_ADDR_W-N;
  -- internal signals
  signal axi_arvalid_i                    : std_logic := '0';
  signal axi_araddr_i                     : unsigned(GMEM_ADDR_W-1 downto 0) := (others=>'0');
  signal axi_arid_i                       : unsigned(ID_WIDTH-1 downto 0) := (others=>'0');
  signal axi_awid_i                       : unsigned(ID_WIDTH-1 downto 0) := (others=>'0');
  signal cu_ready_i                       : std_logic_vector(1 downto 0) := (others=>'0');
  signal rdData_i, rdData_d0              : std_logic_vector(DATA_W*CACHE_N_BANKS-1 downto 0) := (others => '0');
  signal finish_exec_i                    : std_logic := '0';
  -- CUs' interface{{{
  signal cu_ready_n                       : std_logic_vector(1 downto 0) := (others=>'0');
  signal cuIndx_msb                       : std_logic := '0';
  --signal cu_atomic_ack_p0                 : std_logic_vector(1 downto 0) := (others=>'0');
  -- }}}
  -- axi signals
  signal axi_awvalid_n                    : std_logic := '0';
  signal axi_awaddr_n                     : std_logic_vector(GMEM_ADDR_W-1 downto 0);
  signal axi_wstrb_n                      : std_logic_vector(GMEM_N_BANK*DATA_W/8-1 downto 0);
  signal axi_wvalid_n                     : std_logic := '0';
  -- meta fifo
  signal meta_fifo_in                     : std_logic_vector(META_TOTAL_W-1 downto 0);
  signal meta_fifo_out                    : std_logic_vector(META_TOTAL_W-1 downto 0);
  signal meta_fifo_push                   : std_logic;
  signal meta_fifo_pop                    : std_logic;
  signal meta_fifo_empty                  : std_logic;
  signal meta_fifo_full                   : std_logic;
  -- responder signals
  signal rdAddr_p0, rdAddr_p1             : unsigned(GMEM_WORD_ADDR_W-N-1 downto 0) := (others=>'0');
  constant c_n_priority_classes_w         : natural := 3;
  type rcv_priority_vec is array (natural range <>) of unsigned(RCV_PRIORITY_W-1 downto 0);
  signal rcv_priority, rcv_priority_n     : rcv_priority_vec(N_RECEIVERS-1 downto 0) := (others=>(others=>'0'));
  constant c_served_vec_len               : natural := 7; -- max(CACHE_N_BANKS-1, 2);
  type served_vec is array (natural range <>) of std_logic_vector(c_served_vec_len-1 downto 0);
  signal write_phase                      : unsigned(WRITE_PHASE_W-1 downto 0) := (others=>'0');
  attribute max_fanout of write_phase     : signal is 8;
  type rcv_to_read_priority_vec is array (natural range <>) of integer range 0 to N_RECEIVERS-1;
  --signal rcv_to_write_pri                 : rcv_to_read_priority_vec(2**c_n_priority_classes_w-1 downto 0) := (others=>0);
  --signal rcv_to_write_pri_n               : rcv_to_read_priority_vec(2**c_n_priority_classes_w-1 downto 0) := (others=>0);
  --signal rcv_to_write_pri_v_n             : std_logic_vector(2**c_n_priority_classes_w-1 downto 0) := (others=>'0');
  --signal rcv_to_write_pri_v               : std_logic_vector(2**c_n_priority_classes_w-1 downto 0) := (others=>'0');
  -- write pipeline
  constant WR_W                      : integer := DATA_W+GMEM_WR_N_WORDS_W+2+1;
  constant WR_DATA_LOW               : integer := 0;
  constant WR_DATA_HIGH              : integer := WR_DATA_LOW+DATA_W-1;
  constant WR_ADDR_LOW               : integer := WR_DATA_HIGH+1;
  constant WR_ADDR_HIGH              : integer := WR_ADDR_LOW+GMEM_WR_N_WORDS_W+1;
  constant WR_VALID_POS              : integer := WR_ADDR_HIGH+1;
  type cu_wrData_ltch_type is array (natural range <>) of std_logic_vector(DATA_W+6 downto 0);
  signal cu_wrData_ltch                   : cu_wrData_ltch_type(15 downto 0);
  signal cu_wrData_ex_ltch                : std_logic_vector(511 downto 0);
  signal cu_wrData_ltch_v                 : std_logic_vector(1 downto 0);
  signal cu_waddr_ltch                    : std_logic_vector(GMEM_WORD_ADDR_W-GMEM_WR_N_WORDS_W-1 downto 0);
  signal cu_op_type_ltch                  : std_logic_vector(2 downto 0);
  signal op_type, op_type_p0              : std_logic_vector(2 downto 0);
  type slv4_array is array (natural range <>) of std_logic_vector(3 downto 0);
  signal write_addr_p0                    : std_logic_vector(GMEM_WORD_ADDR_W-GMEM_WR_N_WORDS_W-1 downto 0);
  signal write_word_p0_v                  : std_logic;
  signal write_word_p0                    : SLV32_ARRAY(15 downto 0);
  signal write_offset_p0                  : slv4_array(15 downto 0);
  signal write_be_p0                      : slv4_array(15 downto 0);
  signal write_v                          : std_logic;
  signal write_addr                       : std_logic_vector(GMEM_WORD_ADDR_W-GMEM_WR_N_WORDS_W-1 downto 0);
  signal write_word                       : std_logic_vector(DATA_W*GMEM_WR_N_WORDS-1 downto 0) := (others=>'0');
  signal write_word_ex                    : std_logic_vector(511 downto 0);
  signal write_word_ex_p0                 : std_logic_vector(511 downto 0);
  signal write_be                         : std_logic_vector(DATA_W/8*GMEM_WR_N_WORDS-1 downto 0) := (others=>'0');
  -- read pipeline signals
  signal rcv_rd_done, rcv_rd_done_n       : std_logic_vector(N_RECEIVERS-1 downto 0) := (others=>'0');
  signal rcv_rd_done_ack                  : std_logic_vector(N_RECEIVERS-1 downto 0) := (others=>'0');
  signal read_ack                         : std_logic_vector(N_RECEIVERS-1 downto 0) := (others=>'0');
  signal read_ack_d0                      : std_logic_vector(N_RECEIVERS-1 downto 0) := (others=>'0');
  signal rdAck_n                          : std_logic_vector(1 downto 0) := (others=>'0');
  signal rdCntrl_n                        : rd_cntrl_array(1 downto 0) := (others=>(others=>'0'));
  signal rcv_to_read                      : std_logic_vector(N_RECEIVERS-1 downto 0) := (others=>'0');
  signal rcv_to_read_d0                   : std_logic_vector(N_RECEIVERS-1 downto 0) := (others=>'0');
  signal pri_enc                          : integer range 0 to N_RECEIVERS-1 := 0;
  signal axi_rd_addr                      : unsigned(GMEM_WORD_ADDR_W-N-1 downto 0) := (others=>'0');
  signal axi_rd_addr_d0                   : unsigned(GMEM_WORD_ADDR_W-N-1 downto 0) := (others=>'0');
  signal axi_read_v                       : std_logic := '0';
  -- receivers signals
  type st_rcv_type is ( get_addr, request_write_addr, request_write_data, write_cache, read_cache);
  type st_rcv_array is array (N_RECEIVERS-1 downto 0) of st_rcv_type;
  signal st_rcv, st_rcv_n                 : st_rcv_array := (others=>get_addr);
  signal rcv_idle, rcv_idle_n             : std_logic_vector(N_RECEIVERS-1 downto 0) := (others=>'0');
  signal rcv_all_idle                     : std_logic := '0';
  signal rcv_gmem_addr, rcv_gmem_addr_n   : gmem_word_addr_array(N_RECEIVERS-1 downto 0) := (others=>(others=>'0'));
  signal rcv_gmem_data, rcv_gmem_data_n   : SLV32_ARRAY(N_RECEIVERS-1 downto 0) := (others=>(others=>'0'));
  signal rcv_gmem_cntrl, rcv_gmem_cntrl_n : rd_cntrl_array(N_RECEIVERS-1 downto 0) := (others=>(others=>'0'));
  signal rcv_rnw, rcv_rnw_n               : std_logic_vector(N_RECEIVERS-1 downto 0) := (others=>'0');
  --signal rcv_atomic, rcv_atomic_n         : std_logic_vector(N_RECEIVERS-1 downto 0) := (others=>'0');
  signal rcv_be, rcv_be_n                 : be_array(N_RECEIVERS-1 downto 0) := (others=>(others=>'0'));
  --signal rcv_atomic_sgntr                 : atomic_sgntr_array(N_RECEIVERS-1 downto 0) := (others=>(others=>'0'));
  --signal rcv_atomic_sgntr_n               : atomic_sgntr_array(N_RECEIVERS-1 downto 0) := (others=>(others=>'0'));
  signal rcv_go, rcv_go_n                 : std_logic_vector(N_RECEIVERS-1 downto 0) := (others=>'0');
  --signal rcv_must_read                    : std_logic_vector(N_RECEIVERS-1 downto 0) := (others=>'0');
  --signal rcv_atomic_rqst                  : std_logic_vector(N_RECEIVERS-1 downto 0) := (others=>'0');
  --signal rcv_atomic_rqst_n                : std_logic_vector(N_RECEIVERS-1 downto 0) := (others=>'0');
  --signal rcv_atomic_ack                   : std_logic_vector(N_RECEIVERS-1 downto 0) := (others=>'0');
  --signal rcv_atomic_performed             : std_logic_vector(N_RECEIVERS-1 downto 0) := (others=>'0');
  --signal atomic_sgntr_p0                  : std_logic_vector(N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  --alias  rcv_atomic_type                  : be_array(N_RECEIVERS-1 downto 0) is rcv_be;
  signal cu_rqst_addr_d0                  : gmem_word_addr_array(1 downto 0) := (others=>(others=>'0'));
  signal cu_rdCntrl_d0                    : rd_cntrl_array(1 downto 0) := (others=>(others=>'0'));
  --signal cu_wrData_d0                     : SLV32_ARRAY(1 downto 0) := (others=>(others=>'0'));
  signal cu_rnw_d0, cu_atomic_d0          : std_logic_vector(1 downto 0) := (others=>'0');
  signal cu_we_d0                         : be_array(1 downto 0) := (others=>(others=>'0'));
  type uint4_array is array (natural range <>) of unsigned(3 downto 0);
  signal cu_num_write                     : uint4_array(1 downto 0) := (others=>(others=>'0'));
  --signal cu_atomic_sgntr_d0               : atomic_sgntr_array(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal rcv_perform_read                 : std_logic_vector(N_RECEIVERS-1 downto 0) := (others=>'0');
  signal rcv_perform_read_n               : std_logic_vector(N_RECEIVERS-1 downto 0) := (others=>'0');
  signal rcv_request_write_addr           : std_logic_vector(N_RECEIVERS-1 downto 0) := (others=>'0');
  signal rcv_request_write_addr_n         : std_logic_vector(N_RECEIVERS-1 downto 0) := (others=>'0');
  attribute max_fanout of rcv_request_write_addr : signal is 50;
  signal rcv_request_write_data           : std_logic_vector(N_RECEIVERS-1 downto 0) := (others=>'0');
  signal rcv_request_write_data_n         : std_logic_vector(N_RECEIVERS-1 downto 0) := (others=>'0');
  -- finish signals
  type st_fill_finish_fifo_type is (idle1, idle2, finish);
  signal st_fill_finish_fifo, st_fill_finish_fifo_n  : st_fill_finish_fifo_type := idle1;
  signal finish_exec_masked               : std_logic := '0';
  signal finish_exec_masked_n             : std_logic := '0';
begin
  -- internal & fixed signals assignments -------------------------------------------------------------------------{{{
  axi_arvalid <= axi_arvalid_i;
  axi_araddr <= axi_araddr_i;
  axi_bready <= '1';
  axi_arid <= std_logic_vector(axi_arid_i);
  axi_awid <= std_logic_vector(axi_awid_i);
  cu_ready <= cu_ready_i;
  rdData <= rdData_i;
  finish_exec <= finish_exec_i;
  ---------------------------------------------------------------------------------------------------------}}}
  -- error handling ------------------------------------------------------------------------------------------- {{{
  --assert GMEM_WORD_ADDR_W-BRMEM_ADDR_W-CACHE_N_BANKS_W <= 24;
  --assert CACHE_N_BANKS_W > 0  and CACHE_N_BANKS_W <= 3;
  --assert (N_RECEIVERS/2**N)*2**N = N_RECEIVERS;
  --assert N_AXI = 1;
  --assert BURST_WORDS_W >= CACHE_N_BANKS_W;
  ---------------------------------------------------------------------------------------------------------------}}}
  -- finish ---------------------------------------------------------------------------------------------------- {{{
  process(clk)
  begin
    if rising_edge(clk) then
      finish_exec_i <= '0';
      if finish_exec_masked = '1' then
        if clean_cache = '1' then
          if axi_wvalid = '0' then
            finish_exec_i <= '1';
          end if;
        else
            finish_exec_i <= '1';
        end if;
      end if;
      if start_kernel = '1' then
        finish_exec_i <= '0';
      end if;
      if nrst = '0' then
        st_fill_finish_fifo <= idle1;
        finish_exec_masked <= '0';
      else
        st_fill_finish_fifo <= st_fill_finish_fifo_n;
        finish_exec_masked <= finish_exec_masked_n;
      end if;
    end if;
  end process;
    process(st_fill_finish_fifo, WGsDispatched, start_kernel, CUs_gmem_idle, rcv_all_idle)
  begin
    st_fill_finish_fifo_n <= st_fill_finish_fifo;
    finish_exec_masked_n <= '0';
    case st_fill_finish_fifo is 
      when idle1 =>
        if WGsDispatched = '1' then
          st_fill_finish_fifo_n <= idle2;
        end if;
      when idle2 =>
        if CUs_gmem_idle = '1' and rcv_all_idle = '1' then
          st_fill_finish_fifo_n <= finish;
        end if;
      when finish =>
        finish_exec_masked_n <= '1';
        if start_kernel = '1' then
          st_fill_finish_fifo_n <= idle1;
          finish_exec_masked_n <= '0';
        end if;
    end case;
  end process;
  ---------------------------------------------------------------------------------------------------------------}}}
  -- write pipeline -------------------------------------------------------------------------------------- {{{
  -- stage 1
  process(clk)
  begin
    if rising_edge(clk) then
      if nrst = '0' then
        write_word_p0_v <= '0';
      else
        if axi_wready = '1' then
          write_word_p0_v <= '0';
          if cu_wrData_ltch_v /= (0 to 1=>'0') then
            write_word_p0_v <= '1';
            write_addr_p0 <= cu_waddr_ltch;
            write_word_ex_p0 <= cu_wrData_ex_ltch;
            op_type_p0 <= cu_op_type_ltch;
            if SUB_INTEGER_IMPLEMENT /= 0 then
              for i in 0 to 15 loop
                write_word_p0(i) <= cu_wrData_ltch(i)(DATA_W-1 downto 0);
                write_offset_p0(i) <= cu_wrData_ltch(i)(DATA_W+5 downto DATA_W+2);
                if cu_wrData_ltch(i)(DATA_W+6) = '1' then
                  case cu_op_type_ltch is -- DATA_W+1+DATA_W/8 for atomic bit
                    when "001" => -- byte
                      case cu_wrData_ltch(i)(DATA_W+1 downto DATA_W) is
                        when "00" => -- 1st byte
                          write_be_p0(i) <= "0001";
                        when "01" => -- 2nd byte
                          write_be_p0(i) <= "0010";
                          write_word_p0(i)(2*8-1 downto 8) <= cu_wrData_ltch(i)(7 downto 0);
                        when "10" => -- 3rd byte
                          write_be_p0(i) <= "0100";
                          write_word_p0(i)(3*8-1 downto 2*8) <= cu_wrData_ltch(i)(7 downto 0);
                        when others => -- 4th byte
                          write_be_p0(i) <= "1000";
                          write_word_p0(i)(4*8-1 downto 3*8) <= cu_wrData_ltch(i)(7 downto 0);
                      end case;
                    when "010" => -- half
                      case cu_wrData_ltch(i)(DATA_W+1) is
                        when '0' => -- 1st half
                          write_be_p0(i) <= "0011";
                        when others => -- 2nd half
                          write_be_p0(i) <= "1100";
                          write_word_p0(i)(4*8-1 downto 2*8) <= cu_wrData_ltch(i)(2*8-1 downto 0);
                      end case;
                    when "100" | "111" => -- word
                      write_be_p0(i) <= (others=>'1');
                    when others=>
                  end case;
                else
                  write_be_p0(i) <= (others=>'0');
                end if;
              end loop;
            else
              for i in 0 to 15 loop
                write_word_p0(i) <= cu_wrData_ltch(i)(DATA_W-1 downto 0);
                write_offset_p0(i) <= cu_wrData_ltch(i)(DATA_W+5 downto DATA_W+2);
                if cu_wrData_ltch(i)(DATA_W+6) = '1' then
                  write_be_p0(i) <= (others=>'1');
                else
                  write_be_p0(i) <= (others=>'0');
                end if;
              end loop;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- stage 2
  process(clk)
  begin
    if rising_edge(clk) then
      if nrst = '0' then
        write_v <= '0';
      else
        if axi_wready = '1' then
          write_v <= '0';
          if write_word_p0_v = '1' then
            write_v <= '1';
            write_addr <= write_addr_p0;
            write_word_ex <= write_word_ex_p0;
            op_type <= op_type_p0;
            if SUB_INTEGER_IMPLEMENT /= 0 then
              for i in 0 to GMEM_WR_N_WORDS-1 loop
                for j in 0 to DATA_W/8-1 loop
                  write_be(i*DATA_W/8+j) <= '0';
                  for k in 0 to GMEM_WR_N_WORDS-1 loop
                    if to_integer(unsigned(write_offset_p0(k))) = i and write_be_p0(k)(j) = '1' then
                      write_be(i*DATA_W/8+j) <= '1';
                      write_word(i*DATA_W+j*8+7 downto i*DATA_W+j*8) <= write_word_p0(k)(j*8+7 downto j*8);
                    end if;
                    exit;
                  end loop;
                end loop;
              end loop;
            else
              for i in 0 to GMEM_WR_N_WORDS-1 loop
                write_be(i*DATA_W/8+DATA_W/8-1 downto i*DATA_W/8) <= (others=>'0');
                for j in 0 to GMEM_WR_N_WORDS-1 loop
                  if to_integer(unsigned(write_offset_p0(j))) = i and write_be_p0(j)(0) = '1' then
                    write_be(i*DATA_W/8+DATA_W/8-1 downto i*DATA_W/8) <= (others=>'1');
                    write_word(i*DATA_W+DATA_W-1 downto i*DATA_W) <= write_word_p0(j);
                    exit;
                  end if;
                end loop;
              end loop;
            end if;
          end if;
        end if;
      end if;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      if nrst = '0' then
        axi_awvalid <= '0';
        axi_wvalid <= '0';
        axi_wstrb <= (others=>'0');
        axi_awid_i <= (others=>'0');
      else
        if axi_awready = '1' and axi_wready = '1' then
          axi_awaddr(GMEM_ADDR_W-1 downto CACHE_N_BANKS_W+2) <= unsigned(write_addr(write_addr'high downto 1));
          axi_awaddr(CACHE_N_BANKS_W+1 downto 0) <= (others=>'0');
          axi_awvalid <= write_v;
          axi_wvalid <= write_v;
          axi_wstrb <= (others=>'0');
          if write_v = '1' then
            axi_awid_i <= axi_awid_i + 1;
          end if;
          if write_addr(0) = '0' then
            axi_wstrb(DATA_W/8*GMEM_WR_N_WORDS-1 downto 0) <= write_be;
            axi_wdata(DATA_W*GMEM_WR_N_WORDS-1 downto 0) <= write_word;
          end if;
          if op_type = "111" then
            axi_wstrb(DATA_W/8*GMEM_WR_N_WORDS*2-1 downto DATA_W/8*GMEM_WR_N_WORDS) <= (others=>'1');
            axi_wdata(DATA_W*GMEM_WR_N_WORDS*2-1 downto DATA_W*GMEM_WR_N_WORDS) <= write_word_ex;
          elsif write_addr(0) = '1' then
            axi_wstrb(DATA_W/8*GMEM_WR_N_WORDS*2-1 downto DATA_W/8*GMEM_WR_N_WORDS) <= write_be;
            axi_wdata(DATA_W*GMEM_WR_N_WORDS*2-1 downto DATA_W*GMEM_WR_N_WORDS) <= write_word;
          end if;
        end if;
      end if;
    end if;
  end process;

  axi_wlast <= '1';
  --------------------------------------------------------------------------------------------------------- }}}
  -- responder -------------------------------------------------------------------------------------------{{{
  -- pick reciever read address
  process(clk)
  begin
    if rising_edge(clk) then
      if nrst = '0' then
        pri_enc <= 0;
        axi_rd_addr <= (others=>'0');
        axi_rd_addr_d0 <= (others=>'0');
        axi_read_v <= '0';
        rcv_to_read <= (others=>'1');
        rcv_to_read_d0 <= (others=>'1');
        meta_fifo_push <= '0';
        meta_fifo_in <= (others=>'0');
      else
        if axi_arready = '1' or rcv_perform_read(pri_enc) = '0' then
          if pri_enc = N_RECEIVERS-1 then
            pri_enc <= 0;
          else
            pri_enc <= pri_enc + 1;
          end if;
        end if;
        if axi_arready = '1' then
          axi_read_v <= '0';
          axi_rd_addr_d0 <= axi_rd_addr;
          rcv_to_read <= (others=>'1');
          rcv_to_read_d0 <= rcv_to_read;
          if rcv_perform_read(pri_enc) = '1' and rcv_to_read_d0(pri_enc) = '1' then
            axi_rd_addr <= rcv_gmem_addr(pri_enc)(GMEM_WORD_ADDR_W-1 downto N);
            rcv_to_read(pri_enc) <= '0';
            rcv_to_read_d0(pri_enc) <= '0';
            axi_read_v <= '1';
          else
            for i in N_RECEIVERS-1 downto 0 loop
              if (rcv_perform_read(i) and rcv_to_read_d0(i)) = '1' then
                axi_rd_addr <= rcv_gmem_addr(i)(GMEM_WORD_ADDR_W-1 downto N);
                rcv_to_read(i) <= '0';
                rcv_to_read_d0(i) <= '0';
                axi_read_v <= '1';
                exit;
              end if;
            end loop;
          end if;
        end if;

        --for i in 0 to N_RECEIVERS-1 loop
        --  if (rcv_perform_read(i) and rcv_to_read_d0(i)) = '1' then
        --    axi_rd_addr <= rcv_gmem_addr(i)(GMEM_WORD_ADDR_W-1 downto N);
        --    rcv_to_read(i) <= '0';
        --    rcv_to_read_d0(i) <= '0';
        --    axi_read_v <= '1';
        --    exit;
        --  end if;
        --end loop;

        read_ack <= (others=>'0');
        read_ack_d0 <= read_ack;
        meta_fifo_push <= '0';
        if axi_arready = '1' then
          meta_fifo_push <= axi_read_v;
          meta_fifo_in(META_ADDR_HIGH downto META_ADDR_LOW) <= std_logic_vector(axi_rd_addr);
          for i in 0 to 1 loop
            meta_fifo_in(i*META_W+META_VALID_POS) <= '0';
            for j in 0 to N_RECEIVERS_CU-1 loop
              if axi_read_v = '1' and rcv_gmem_addr(i*N_RECEIVERS_CU+j)(GMEM_WORD_ADDR_W-1 downto N) = axi_rd_addr and rcv_perform_read(i*N_RECEIVERS_CU+j) = '1' and read_ack(i*N_RECEIVERS_CU+j) = '0' then
                read_ack(i*N_RECEIVERS_CU+j) <= '1';
                meta_fifo_in(i*META_W+META_CNTRL_HIGH downto i*META_W+META_CNTRL_LOW) <= std_logic_vector(rcv_gmem_cntrl(i*N_RECEIVERS_CU+j));
                meta_fifo_in(i*META_W+META_VALID_POS) <= '1';
                exit;
              end if;
            end loop;
          end loop;
        end if;
      end if;
    end if;
  end process;

  metaQ_inst : component gmem_metaQ
    port map (
      data  => meta_fifo_in,  --  fifo_input.datain
      wrreq => meta_fifo_push, --            .wrreq
      rdreq => meta_fifo_pop, --            .rdreq
      clock => clk, --            .clk
      q     => meta_fifo_out,     -- fifo_output.dataout
      full  => meta_fifo_full,  --            .full
      empty => meta_fifo_empty  --            .empty
    );


  process(clk)
  begin
    if rising_edge(clk) then
      if nrst = '0' then
        axi_arvalid_i <= '0';
        axi_araddr_i <= (others=>'0');
        axi_arid_i <= (others=>'0');
      else
        -- only use 1 AXI port
        axi_araddr_i(N+1 downto 0) <= (others=>'0');
        if axi_arready = '1' then
          axi_araddr_i(GMEM_ADDR_W-1 downto 2+N) <= axi_rd_addr;
          axi_arvalid_i <= axi_read_v;
          if axi_read_v = '1' then
            axi_arid_i <= axi_arid_i + 1;
          end if;
        end if;
      end if;
    end if;
  end process;

  -- axi_r respond
  axi_rready <= '1';
  meta_fifo_pop <= axi_rvalid;
  process(clk)
  begin
    if rising_edge(clk) then
      if nrst = '0' then
        rdAck <= (others=>'0');
      else
        if axi_rvalid = '1' then
          for i in 0 to 1 loop
            rdAck(i) <= meta_fifo_out(i*META_W+META_VALID_POS);
          end loop;
        else
          rdAck <= (others=>'0');
        end if;
      end if;
      rdData_i <= axi_rdata;
      rdAddr <= unsigned(meta_fifo_out(META_ADDR_HIGH downto META_ADDR_LOW));
      for i in 0 to 1 loop
        rdCntrl(i) <= unsigned(meta_fifo_out(i*META_W+META_CNTRL_HIGH downto i*META_W+META_CNTRL_LOW));
      end loop;
    end if;
  end process;
  --process(clk)
  --begin
  --  if rising_edge(clk) then
  --    rdData_d0 <= axi_rdata(0);
  --    rdData_i <= rdData_d0;
  --    rdCntrl <= rdCntrl_n;
  --    rdAddr_p0 <= unsigned(meta_fifo_out);
  --    rdAddr <= rdAddr_p0;
  --    if nrst = '0' then
  --      rdAck <= (others=>'0');
  --    else
  --      rdAck <= rdAck_n;
  --    end if;
  --  end if;
  --end process;

  --cu_response_8cu: if N_CU = CV_SIZE generate
  --  process(rcv_rd_done, rdCntrl, rcv_gmem_cntrl)
  --  begin
  --    rcv_rd_done_ack <= (others=>'0');
  --    rdAck_n <= (others=>'0');
  --    rdCntrl_n <= rdCntrl;
  --    for i in 0 to N_CU-1 loop
  --      for j in 0 to N_RECEIVERS_CU-1 loop
  --        if rcv_rd_done(i*N_RECEIVERS_CU+j) = '1' then
  --          rcv_rd_done_ack(i*N_RECEIVERS_CU+j) <= '1';
  --          rdAck_n(i) <= '1';
  --          rdCntrl_n(i) <= rcv_gmem_cntrl(i*N_RECEIVERS_CU+j);
  --          exit;
  --        end if;
  --      end loop;
  --    end loop;
  --  end process;
  --end generate;

  --cu_response_4cu: if N_CU /= CV_SIZE generate
  --  process(rcv_rd_done, rdCntrl, rcv_gmem_cntrl)
  --  begin
  --    rcv_rd_done_ack <= (others=>'0');
  --    rdAck_n <= (others=>'0');
  --    rdCntrl_n <= rdCntrl;
  --    for i in 0 to N_CU-1 loop
  --      for j in 0 to N_RECEIVERS_CU*2-1 loop
  --        if rcv_rd_done(i*N_RECEIVERS_CU+(j/N_RECEIVERS_CU)*N_RECEIVERS/2+(j rem N_RECEIVERS_CU)) = '1' then
  --          rcv_rd_done_ack(i*N_RECEIVERS_CU+(j/N_RECEIVERS_CU)*N_RECEIVERS/2+(j rem N_RECEIVERS_CU)) <= '1';
  --          rdAck_n(i) <= '1';
  --          rdCntrl_n(i) <= rcv_gmem_cntrl(i*N_RECEIVERS_CU+(j/N_RECEIVERS_CU)*N_RECEIVERS/2+(j rem N_RECEIVERS_CU));
  --          exit;
  --        end if;
  --      end loop;
  --    end loop;
  --  end process;
  --end generate;


  rcv_comb: for i in 0 to N_RECEIVERS-1 generate
  begin
    rcv_com: process  (st_rcv(i), rcv_gmem_addr(i), cu_rqst_addr_d0(c_rcv_cu_indx(i)), rcv_be(i), rcv_rnw(i), rcv_idle(i),   -- {{{
                      rcv_go(i), cu_rnw_d0(c_rcv_cu_indx(i)), axi_rd_addr, 
                      rcv_perform_read(i), rcv_gmem_data(i), rcv_priority(i),
                      cu_rdCntrl_d0(c_rcv_cu_indx(i)), rcv_gmem_cntrl(i), read_ack(i))
      variable li          : line; -- }}}
    begin
      -- assignments {{{
      st_rcv_n(i) <= st_rcv(i); 
      rcv_gmem_addr_n(i) <= rcv_gmem_addr(i);
      rcv_gmem_data_n(i) <= rcv_gmem_data(i);
      rcv_gmem_cntrl_n(i) <= rcv_gmem_cntrl(i);
      --if ATOMIC_IMPLEMENT /= 0 then
      --  rcv_atomic_rqst_n(i) <= rcv_atomic_rqst(i);
      --end if;
      rcv_rnw_n(i) <= rcv_rnw(i);
      --rcv_atomic_n(i) <= rcv_atomic(i);
      rcv_perform_read_n(i) <= rcv_perform_read(i);
      rcv_request_write_addr_n(i) <= rcv_request_write_addr(i);
      rcv_request_write_data_n(i) <= rcv_request_write_data(i);
      rcv_be_n(i) <= rcv_be(i);
      --rcv_atomic_sgntr_n(i) <= rcv_atomic_sgntr(i);
      rcv_idle_n(i) <= rcv_idle(i);
      rcv_priority_n(i) <= rcv_priority(i);
      rcv_rd_done_n(i) <= '0';
      --write_addr_match_n(i) <= write_addr_match(i);
      --}}}
      case st_rcv(i) is
        when get_addr => -- {{{
          -- rcv_be_n(i) <= (others=>'0');
          rcv_idle_n(i) <= '1';
          --rcv_wait_1st_cycle_n(i) <= '0';
          rcv_request_write_data_n(i) <= '0';
          rcv_rnw_n(i) <= cu_rnw_d0(c_rcv_cu_indx(i));
          if rcv_go(i) = '1' then
            rcv_gmem_addr_n(i) <= unsigned(cu_rqst_addr_d0(c_rcv_cu_indx(i)));
            --rcv_be_n(i) <= cu_we_d0(c_rcv_cu_indx(i));
            --rcv_atomic_sgntr_n(i) <= cu_atomic_sgntr_d0(c_rcv_cu_indx(i));
            --rcv_gmem_data_n(i) <= cu_wrData_d0(c_rcv_cu_indx(i));
            rcv_gmem_cntrl_n(i) <= cu_rdCntrl_d0(c_rcv_cu_indx(i));
            --rcv_atomic_n(i) <= cu_atomic_d0(c_rcv_cu_indx(i));
            -- assert to_integer(unsigned(cu_rqst_addr_d0(c_rcv_cu_indx(i)))) = 792 or cu_rnw_d0(c_rcv_cu_indx(i)) = '1' severity failure;
            --if cu_atomic_d0(c_rcv_cu_indx(i)) = '0' then
            --  st_rcv_n(i) <= get_read_tag_ticket;
            --  rcv_read_tag_n(i) <= '1';
            --else
            --  st_rcv_n(i) <= requesting_atomic;
            --  if ATOMIC_IMPLEMENT /= 0 then
            --    rcv_atomic_rqst_n(i) <= '1';
            --  end if;
            --end if;
            if cu_rnw_d0(c_rcv_cu_indx(i)) = '1' then
              st_rcv_n(i) <= read_cache;
              rcv_perform_read_n(i) <= '1';
            else
              st_rcv_n(i) <= request_write_addr;
              rcv_request_write_addr_n(i) <= '1';
              rcv_request_write_data_n(i) <= '1';
            end if;
            rcv_idle_n(i) <= '0';
          end if; -- }}}
        --when requesting_atomic => -- {{{
        --  if ATOMIC_IMPLEMENT /= 0 then 
        --    rcv_priority_n(i) <= rcv_priority(i) + 1;
        --    if rcv_priority(i) = (rcv_priority(i)'reverse_range=>'1') then
        --      rcv_atomic_rqst_n(i) <= '1';
        --    end if;
        --    if rcv_atomic_ack(i) = '1' then
        --      rcv_atomic_rqst_n(i) <= '0';
        --    end if;
        --    if rcv_must_read(i) = '1' then  -- rcv_must_read & rcv_atomic_performed cann't be at 1 simultaneously
        --      rcv_atomic_rqst_n(i) <= '0';
        --      rcv_rnw_n(i) <= '1';
        --      st_rcv_n(i) <= get_read_tag_ticket;
        --      rcv_read_tag_n(i) <= '1';
        --    end if;
        --    if rcv_atomic_performed(i) = '1' then
        --      rcv_atomic_rqst_n(i) <= '0';
        --      st_rcv_n(i) <= get_addr;
        --    end if;
        --  end if; 
          -- }}}
        when read_cache => -- {{{
          --if (meta_fifo_out = std_logic_vector(rcv_gmem_addr(i)(GMEM_WORD_ADDR_W-1 downto N))) and axi_rvalid(0) = '1' then
          --  rcv_perform_read_n(i) <= '0';
          --  st_rcv_n(i) <= read_done;
          --  rcv_rd_done_n(i) <= '1';
          --elsif (axi_rd_addr_d0 = rcv_gmem_addr(i)(GMEM_WORD_ADDR_W-1 downto N)) and axi_arready(0) = '1' and axi_arvalid_i(0) = '1' then
          --  rcv_perform_read_n(i) <= '0';
          --  --if ATOMIC_IMPLEMENT /= 0 and rcv_atomic(i) = '1' then
          --  --  rcv_atomic_rqst_n(i) <= '1';
          --  --  st_rcv_n(i) <= requesting_atomic;
          --  --else
          --    st_rcv_n(i) <= wait_respond;
          --    -- rcv_idle_n(i) <= '1';
          --  --end if;
          --end if; -- }}}
          if read_ack(i) = '1' then
            st_rcv_n(i) <= get_addr;
            rcv_perform_read_n(i) <= '0';
          end if;
        when others=>
      end case;
    end process;
  end generate;

  ---------------------------------------------------------------------------------------------------------}}}
  ---- atomics ----------------------------------------------------------------------------------------------{{{
  --atomics_if: if ATOMIC_IMPLEMENT /=0 generate
  --  atomics_inst: entity gmem_atomics port map(
  --    clk               => clk,
  --    rcv_atomic_rqst   => rcv_atomic_rqst,
  --    rcv_atomic_ack    => rcv_atomic_ack,
  --    rcv_atomic_type   => rcv_atomic_type,
  --    rcv_gmem_addr     => rcv_gmem_addr,
  --    rcv_must_read     => rcv_must_read,
  --    rcv_gmem_data     => rcv_gmem_data,
  --    gmem_rdAddr_p0    => rdAddr_p0,
  --    gmem_rdData       => rdData_i,
  --    gmem_rdData_v_p0  => cache_read_v_d0,
  --    rcv_retire        => rcv_atomic_performed,
  --    atomic_rdData     => atomic_rdData,
  --    flush_ack         => flush_ack,
  --    flush_done        => flush_done,
  --    flush_v           => flush_v,
  --    flush_gmem_addr   => flush_gmem_addr,
  --    flush_data        => flush_data,
  --    finish            => finish_exec_i,
  --    atomic_can_finish => atomic_can_finish,
  --    WGsDispatched     => WGsDispatched,
  --    nrst              => nrst
  --  );
  --end generate;
  -----------------------------------------------------------------------------------------------------------}}}
  -- receivers -------------------------------------------------------------------------------------------{{{
  receivers_trans: process(clk) -- {{{
  begin
    if rising_edge(clk) then
      rcv_gmem_addr <= rcv_gmem_addr_n;
      rcv_gmem_data <= rcv_gmem_data_n;
      rcv_gmem_cntrl <= rcv_gmem_cntrl_n;
      rcv_be <= rcv_be_n;
      rcv_rnw <= rcv_rnw_n;

      cu_rnw_d0 <= cu_rnw;
      --cu_we_d0 <= cu_we;
      cu_rqst_addr_d0 <= cu_rqst_addr;
      --cu_wrData_d0 <= cu_wrData;
      cu_rdCntrl_d0 <= cu_rdCntrl;

      --if ATOMIC_IMPLEMENT /= 0 then
      --  rcv_atomic_sgntr <= rcv_atomic_sgntr_n;
      --  rcv_atomic <= rcv_atomic_n;
      --  cu_atomic_d0 <= cu_atomic;
      --  cu_atomic_sgntr_d0 <= cu_atomic_sgntr;
      --  cu_atomic_ack_p0 <= (others=>'0');
      --  if flush_ack = '1' then
      --    cu_atomic_d0(0) <= '0';
      --    cu_rqst_addr_d0(0) <= flush_gmem_addr;
      --    cu_wrData_d0(0) <= flush_data;
      --    cu_we_d0(0) <= (others=>'1');
      --    cu_rnw_d0(0) <= '0';
      --  end if;
      --  for i in 0 to N_RECEIVERS-1 loop
      --    if rcv_atomic_performed(i) = '1' then
      --      cu_atomic_ack_p0(c_rcv_cu_indx(i)) <= '1';
      --    end if;
      --  end loop;
      --  atomic_rdData_v <= cu_atomic_ack_p0(N_CU-1 downto 0);

      --  for i in 0 to N_RECEIVERS-1 loop
      --    if rcv_atomic_performed(i) = '1' then
      --      atomic_sgntr_p0 <= rcv_atomic_sgntr(i);
      --    end if;
      --  end loop;
      --  atomic_sgntr <= atomic_sgntr_p0;
      --end if;

      if rcv_idle = (rcv_idle'reverse_range => '1') then
        rcv_all_idle <= '1';
      else
        rcv_all_idle <= '0';
      end if;
      rcv_priority <= rcv_priority_n;
      rcv_go <= rcv_go_n;
      rcv_request_write_data <= rcv_request_write_data_n;
      rcv_rd_done <= rcv_rd_done_n;
      if nrst = '0' then
        st_rcv <= (others=>get_addr);
        rcv_idle <= (others=>'0');
        --if ATOMIC_IMPLEMENT /= 0 then
        --  rcv_atomic_rqst <= (others=>'0');
        --end if;
        rcv_perform_read <= (others=>'0');
        rcv_request_write_addr <= (others=>'0');
        --write_addr_match <= (others=>'0');
      else
        st_rcv <= st_rcv_n;
        rcv_idle <= rcv_idle_n;
        --if ATOMIC_IMPLEMENT /= 0 then
        --  rcv_atomic_rqst <= rcv_atomic_rqst_n;
        --end if;
        rcv_perform_read <= rcv_perform_read_n;
        rcv_request_write_addr <= rcv_request_write_addr_n;
        --write_addr_match <= write_addr_match_n;
      end if;
    end if;
  end process; -- }}}
  -- interface to CUs ----------------------------------------------------------------------------------------{{{
  process(clk)
  begin
    if rising_edge(clk) then
      --cu_ready_i <= cu_ready_n;
      cuIndx_msb <= not cuIndx_msb;
      --if ATOMIC_IMPLEMENT /= 0 then
      --  flush_ack <= flush_ack_n;
      --  flush_rcv_index <= flush_rcv_index_n;
      --  flush_done <= rcv_idle(flush_rcv_index);
      --end if;
    end if;
  end process;

  -- write
  process(axi_wready, rcv_idle, cu_wcu_en)
  begin
    cu_wready <= axi_wready;
    for i in 0 to 1 loop
      if cu_wcu_en(i) = '1' then
        if rcv_idle(N_RECEIVERS_CU*i+N_RECEIVERS_CU-1 downto N_RECEIVERS_CU*i) /= (0 to N_RECEIVERS_CU-1=>'1') then
          cu_wready <= '0';
        end if;
        exit;
      end if;
    end loop;
  end process;
  process(clk)
  begin
    if rising_edge(clk) then
      if nrst = '0' then
        cu_wrData_ltch_v <= (others=>'0');
        cu_num_write <= (others=>(others=>'0'));
      else
        if cu_wvalid = '1' and cu_wready = '1' then
          cu_waddr_ltch <= cu_waddr;
          cu_op_type_ltch <= cu_wtype;
          cu_wrData_ltch_v <= cu_wcu_en;
          for i in 0 to 15 loop
            cu_wrData_ltch(i) <= cu_wrData(i*WR_W+WR_W-1 downto i*WR_W);
          end loop;
          cu_wrData_ex_ltch <= cu_wrData_ex;
        else
          cu_wrData_ltch_v <= (others=>'0');
        end if;

        for i in 0 to 1 loop
          if cu_valid(i) = '1' and cu_rnw(i) = '0' and cu_wrData_ltch_v(i) = '0' then
            cu_num_write(i) <= cu_num_write(i) + 1;
          elsif (cu_valid(i) = '0' or cu_rnw(i) = '1') and cu_wrData_ltch_v(i) = '1' then
            cu_num_write(i) <= cu_num_write(i) - 1;
          end if;
        end loop;
      end if;
    end if;
  end process;

  process(cu_valid, cu_rnw, cu_ready_i, rcv_idle, cuIndx_msb, rcv_go, cu_num_write) --, flush_v, flush_ack, flush_rcv_index)
    variable rcvIndx: unsigned(N_RECEIVERS_W-1 downto 0) := (others=>'0');
  begin
    rcv_go_n <= (others=>'0');
    -- setting ready signal for CU0
    --cu_ready_n <= '0';
    cu_ready_i(0) <= '0';
    --flush_ack_n <= '0';
    -- if ATOMIC_IMPLEMENT /= 0 then
      --flush_rcv_index_n <= flush_rcv_index;
    -- end if;
    --for j in N_RECEIVERS_CU/2-1 downto 0 loop
    --  rcvIndx(N_RECEIVERS_W-1 downto N_RECEIVERS_W-max(CV_W, 1)) := to_unsigned(0, max(1, CV_W));
    --  rcvIndx(N_RECEIVERS_CU_W-1) := not cuIndx_msb;
    --  rcvIndx(N_RECEIVERS_CU_W-2 downto 0) := to_unsigned(j, N_RECEIVERS_CU_W-1);
    --  if rcv_idle_n(to_integer(rcvIndx)) = '1' then
    --    --if ATOMIC_IMPLEMENT /= 0 and flush_v = '1' and flush_ack = '0' then
    --    --  flush_ack_n <= '1';
    --    --  cu_ready_n(0) <= '0';
    --    --else
    --      --flush_ack_n <= '0';
    --      cu_ready_n(0) <= '1';
    --    --end if;
    --  end if;
    --end loop;

    -- starting receviers for CU0
    --if (cu_valid(0) = '1' and cu_ready_i(0) = '1') then -- or (ATOMIC_IMPLEMENT /= 0 and flush_v = '1' and flush_ack = '1' ) then
    --  for j in N_RECEIVERS_CU/2-1 downto 0 loop
    --    rcvIndx(N_RECEIVERS_W-1 downto N_RECEIVERS_W-max(1,CV_W)) := to_unsigned(0, max(1, CV_W));
    --    rcvIndx(N_RECEIVERS_CU_W-1) := cuIndx_msb;
    --    rcvIndx(N_RECEIVERS_CU_W-2 downto 0) := to_unsigned(j, N_RECEIVERS_CU_W-1);
    --    if rcv_idle(to_integer(rcvIndx)) = '1' then
    --      rcv_go_n(to_integer(rcvIndx)) <= '1';
    --      --flush_rcv_index_n <= to_integer(rcvIndx);
    --      exit;
    --    end if;
    --  end loop;
    --end if;

    for j in N_RECEIVERS_CU-1 downto 0 loop
      rcvIndx(N_RECEIVERS_W-1 downto N_RECEIVERS_W-1) := to_unsigned(0, 1);
      rcvIndx(N_RECEIVERS_CU_W-1 downto 0) := to_unsigned(j, N_RECEIVERS_CU_W);
      if (rcv_idle(to_integer(rcvIndx)) = '1') and (rcv_go(to_integer(rcvIndx)) = '0') then
          cu_ready_i(0) <= '1';
      end if;
    end loop;
    if cu_num_write(0) /= "0000" then
      cu_ready_i(0) <= '0';
    end if;

    -- starting receviers for CU0
    if cu_valid(0) = '1' and cu_rnw(0) = '1' and cu_num_write(0) = "0000" then -- or (ATOMIC_IMPLEMENT /= 0 and flush_v = '1' and flush_ack = '1' ) then
      for j in N_RECEIVERS_CU-1 downto 0 loop
        rcvIndx(N_RECEIVERS_W-1 downto N_RECEIVERS_W-1) := to_unsigned(0, 1);
        rcvIndx(N_RECEIVERS_CU_W-1 downto 0) := to_unsigned(j, N_RECEIVERS_CU_W);
        if rcv_idle(to_integer(rcvIndx)) = '1' and rcv_go(to_integer(rcvIndx)) = '0' then
          rcv_go_n(to_integer(rcvIndx)) <= '1';
          --flush_rcv_index_n <= to_integer(rcvIndx);
          exit;
        end if;
      end loop;
    end if;
    
    -- other receivers
    if N_CU > 1 then
      for i in 1 to 1 loop
        -- starting receviers
        --if cu_valid(i) = '1' and cu_ready_i(i) = '1' then
        --  for j in N_RECEIVERS_CU/2-1 downto 0 loop
        --    rcvIndx(N_RECEIVERS_W-1 downto N_RECEIVERS_W-max(1,CV_W)) := to_unsigned(i, max(1, CV_W));
        --    rcvIndx(N_RECEIVERS_CU_W-1) := cuIndx_msb;
        --    rcvIndx(N_RECEIVERS_CU_W-2 downto 0) := to_unsigned(j, N_RECEIVERS_CU_W-1);
        --    if rcv_idle(to_integer(rcvIndx)) = '1' then
        --      rcv_go_n(to_integer(rcvIndx)) <= '1';
        --      exit;
        --    end if;
        --  end loop;
        --end if;
        ---- setting ready signal
        --cu_ready_n(i) <= '0';
        --for j in N_RECEIVERS_CU/2-1 downto 0 loop
        --  rcvIndx(N_RECEIVERS_W-1 downto N_RECEIVERS_W-max(CV_W, 1)) := to_unsigned(i, max(1, CV_W));
        --  rcvIndx(N_RECEIVERS_CU_W-1) := not cuIndx_msb;
        --  rcvIndx(N_RECEIVERS_CU_W-2 downto 0) := to_unsigned(j, N_RECEIVERS_CU_W-1);
        --  if rcv_idle_n(to_integer(rcvIndx)) = '1' then
        --    cu_ready_n(c_rcv_cu_indx(to_integer(rcvIndx))) <= '1';
        --  end if;
        --end loop;

        if cu_valid(i) = '1' and cu_rnw(i) = '1' and cu_num_write(i) = "0000" then
          for j in N_RECEIVERS_CU-1 downto 0 loop
            rcvIndx(N_RECEIVERS_W-1 downto N_RECEIVERS_W-1) := to_unsigned(i, 1);
            rcvIndx(N_RECEIVERS_CU_W-1 downto 0) := to_unsigned(j, N_RECEIVERS_CU_W);
            if rcv_idle(to_integer(rcvIndx)) = '1' and rcv_go(to_integer(rcvIndx)) = '0' then
              rcv_go_n(to_integer(rcvIndx)) <= '1';
              exit;
            end if;
          end loop;
        end if;
        -- setting ready signal
        --cu_ready_n(i) <= '0';
        cu_ready_i(i) <= '0';
        for j in N_RECEIVERS_CU-1 downto 0 loop
          rcvIndx(N_RECEIVERS_W-1 downto N_RECEIVERS_W-1) := to_unsigned(i, 1);
          rcvIndx(N_RECEIVERS_CU_W-1 downto 0) := to_unsigned(j, N_RECEIVERS_CU_W);
          if (rcv_idle(to_integer(rcvIndx)) = '1') and (rcv_go(to_integer(rcvIndx)) = '0') then
            cu_ready_i(c_rcv_cu_indx(to_integer(rcvIndx))) <= '1';
          end if;
        end loop;
        if cu_num_write(i) /= "0000" then
          cu_ready_i(i) <= '0';
        end if;
      end loop;
    end if;
  end process;
  ---------------------------------------------------------------------------------------------------------}}}
end Behavioral;
