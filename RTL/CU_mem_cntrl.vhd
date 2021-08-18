-- libraries -------------------------------------------------------------------------------------------{{{
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.all;
use work.FGPU_definitions.all;
library cumem_metaQ;
library cumem_rqstQ;
---------------------------------------------------------------------------------------------------------}}}
entity CU_mem_cntrl is --{{{
generic (cu_idx : integer range 0 to CV_SIZE-1);
port(
  clk                     : in std_logic;
  -- from the CV
  cv_wrData               : in SLV32_ARRAY(CV_SIZE-1 downto 0); -- level 17.
  cv_wrData_wide          : in std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0);
  cv_addr                 : in GMEM_ADDR_ARRAY(CV_SIZE-1 downto 0); -- level 17.
  cv_gmem_we              : in std_logic;
  cv_gmem_re              : in std_logic;
  cv_gmem_atomic          : in std_logic;
  cv_lmem_rqst            : in std_logic; --  level 17.
  cv_lmem_we              : in std_logic;
  cv_op_type              : in std_logic_vector(2 downto 0); -- level 17.
  cv_alu_en               : in std_logic_vector(CV_SIZE-1 downto 0);
  cv_alu_en_pri_enc       : in integer range 0 to CV_SIZE-1 := 0;
  cv_rd_addr              : in unsigned(FREG_FILE_W downto 0);
  cv_gmem_simd            : in std_logic := 'X';
  rreg_ready              : in std_logic := 'X';
  vreg_ready              : in std_logic := 'X';
  cv_gsync_reached        : in std_logic := 'X';
  -- to the CV
  regFile_wrAddr          : out unsigned(FREG_FILE_W downto 0) := (others=>'0'); -- stage -1 (stable for 3 clock cycles)
  regFile_we              : out std_logic_vector(2*CV_SIZE-1 downto 0) := (others=>'X'); -- stage 0 (stable for 2 clock cycles) (level 20. for loads from lmem)
  regFile_wrData          : out SLV32_ARRAY(2*CV_SIZE-1 downto 0) := (others=>(others=>'X')); -- stage 0 (stable for 2 clock cycles)
  regFile_wrData_wide     : out std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'X'); -- stage 1 (stable for 2 clock cycles)
  regFile_we_lmem_p0      : out std_logic := 'X'; -- level 19.
  
  -- interface to the global memory controller
  cache_rdAck             : in std_logic := 'X';
  cache_rdAddr            : in unsigned(GMEM_WORD_ADDR_W-CACHE_N_BANKS_W-1 downto 0);
  cache_rdData            : in std_logic_vector(DATA_W*CACHE_N_BANKS-1 downto 0);
  cache_rdCntrl           : in unsigned(N_CU_STATIONS_W-1 downto 0);
  atomic_rdData           : in std_logic_vector(DATA_W-1 downto 0) := (others=>'X');
  atomic_rdData_v         : in std_logic := 'X';
  atomic_sgntr            : in std_logic_vector(N_CU_STATIONS_W-1 downto 0) := (others=>'X');
  gmem_wrData             : out std_logic_vector(GMEM_WRFIFO_W-1 downto 0) := (others=>'X');
  gmem_valid              : out std_logic := 'X';
  gmem_rnw                : out std_logic := 'X';
  gmem_op_type            : out std_logic_vector(2 downto 0) := (others=>'X');
  gmem_atomic             : out std_logic := 'X';
  gmem_atomic_sgntr       : out std_logic_vector(N_CU_STATIONS_W-1 downto 0) := (others=>'X');
  gmem_ready              : in std_logic;
  gmem_rqst_addr          : out std_logic_vector(GMEM_WORD_ADDR_W-CACHE_N_BANKS_W-1 downto 0) := (others=>'X');
  gmem_rqst_cntrl         : out unsigned(N_CU_STATIONS_W-1 downto 0) := (others => 'X');

  -- to CU scheduler
  wf_finish               : out std_logic_vector(N_WF_CU-1 downto 0) := (others=>'X');
  wf_finish_rd            : out std_logic_vector(N_WF_CU-1 downto 0) := (others=>'X');
  wf_rdAddr               : out wi_vreg_addr_array(N_WF_CU-1 downto 0) := (others=>(others=>'0'));
  cus_alm_full            : out std_logic;
  
  finish_exec             : in std_logic := 'X';
  cntrl_idle              : out std_logic := 'X';

  nrst                    : in std_logic
);
end entity; --}}}
architecture Behavioral of CU_mem_cntrl is 
  component reorder_validQ is
    generic (ADDR_WIDTH: integer);
    port (
      wrdata     : in std_logic := '0';
      wraddr     : in std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
      rdaddr     : in std_logic_vector(ADDR_WIDTH-1 downto 0) := (others => '0');
      we_a       : in std_logic := '0';
      q_a        : out std_logic := '0';
      nrst       : in std_logic := '0';
      clock      : in std_logic := '0'
    );
  end component reorder_validQ;

  component cumem_metaQ is
    port (
      data        : in  std_logic_vector(556 downto 0) := (others => 'X'); -- datain
      wrreq       : in  std_logic                      := 'X';             -- wrreq
      rdreq       : in  std_logic                      := 'X';             -- rdreq
      clock       : in  std_logic                      := 'X';             -- clk
      sclr        : in  std_logic                      := 'X';             -- sclr
      q           : out std_logic_vector(556 downto 0);                    -- dataout
      empty       : out std_logic;                                         -- empty
      almost_full : out std_logic                                          -- almost_full
    );
  end component cumem_metaQ;

  component cumem_rqstQ is
    port (
      data  : in  std_logic_vector(1074 downto 0) := (others => 'X'); -- datain
      wrreq : in  std_logic                      := 'X';             -- wrreq
      rdreq : in  std_logic                      := 'X';             -- rdreq
      clock : in  std_logic                      := 'X';             -- clk
      sclr  : in  std_logic                      := 'X';             -- sclr
      q     : out std_logic_vector(1074 downto 0);                    -- dataout
      usedw : out std_logic_vector(8 downto 0);                      -- usedw
      full  : out std_logic;                                         -- full
      empty : out std_logic                                          -- empty
    );
  end component cumem_rqstQ;

  -- signals definitions ---------------------------------------------------------------------{{{
  -- internal signals definitions {{{
  signal gmem_valid_i                     : std_logic := '0';  
  signal regFile_wrAddr_i                 : unsigned(FREG_FILE_W downto 0) := (others=>'0');  
  signal cntrl_idle_i                     : std_logic := '0';
  signal cv_gsync_reached_i               : std_logic := '0';
  -- }}}
  -- constants & functions {{{
  constant N_STATIONS                     : natural := 2**(N_CU_STATIONS_W);
  --- }}}
  -- finish signals {{{
  type st_finish_type is (idle, serving, finished);
  type st_finish_array_type is array (natural range<>) of st_finish_type;
  signal st_finish, st_finish_n           : st_finish_array_type(N_WF_CU-1 downto 0) := (others=>idle);
  signal check_finish                     : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal check_finish_n                   : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal check_wr, check_wr_n             : std_logic := '0';
  signal wf_finish_n                      : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal wfs_served                       : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal wfs_served_n                     : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  -- }}}
  -- memory requests buffer {{{
  -- 0..31: DATA, 32:63: ADDR, 64:re, 65:atomic, 66..68: op_type, 69:alu_en, 70:simd, 71..85: rd_addr
  constant MEM_RQST_W                     : integer := DATA_W+GMEM_ADDR_W+1+1+3+1+1+FREG_FILE_W+1; 
  constant MEM_RQST_DATA_LOW              : integer := 0;
  constant MEM_RQST_DATA_HIGH             : integer := MEM_RQST_DATA_LOW+DATA_W-1; -- 31
  constant MEM_RQST_ADDR_LOW              : integer := MEM_RQST_DATA_HIGH+1; -- 32
  constant MEM_RQST_ADDR_HIGH             : integer := MEM_RQST_ADDR_LOW+GMEM_ADDR_W-1; -- 63
  constant MEM_RQST_RE_POS                : integer := MEM_RQST_ADDR_HIGH+1; -- 64
  constant MEM_RQST_ATOMIC_POS            : integer := MEM_RQST_RE_POS+1; -- 65
  constant MEM_RQST_OP_TYPE_LOW           : integer := MEM_RQST_ATOMIC_POS+1; -- 66
  constant MEM_RQST_OP_TYPE_HIGH          : integer := MEM_RQST_OP_TYPE_LOW+2; -- 68
  constant MEM_RQST_ALU_EN_POS            : integer := MEM_RQST_OP_TYPE_HIGH+1; -- 69
  constant MEM_RQST_SIMD_POS              : integer := MEM_RQST_ALU_EN_POS+1; -- 70
  constant MEM_RQST_RD_ADDR_LOW           : integer := MEM_RQST_SIMD_POS+1; -- 71
  constant MEM_RQST_RD_ADDR_HIGH          : integer := MEM_RQST_RD_ADDR_LOW+FREG_FILE_W; -- 85

  type mem_rqsts_buffer_type is array(natural range <>) of std_logic_vector(CV_SIZE*MEM_RQST_W-1 downto 0);
  signal mem_rqsts                        : mem_rqsts_buffer_type(N_WF_CU*2**(PHASE_W)-1 downto 0) := (others=>(others=>'0'));
  signal mem_rqsts_rdAddr                 : unsigned(N_WF_CU_W+PHASE_W-1 downto 0) := (others=>'0');
  signal mem_rqsts_rdAddr_n               : unsigned(N_WF_CU_W+PHASE_W-1 downto 0) := (others=>'0');
  signal mem_rqsts_rdAddr_inc_n           : std_logic := '0';
  signal mem_rqsts_wrAddr                 : unsigned(N_WF_CU_W+PHASE_W-1 downto 0) := (others=>'0');
  type mem_rqsts_array is array(natural range <>) of std_logic_vector(MEM_RQST_W-1 downto 0);
  --signal mem_rqsts_rdData                 : std_logic_vector(CV_SIZE*MEM_RQST_W-1 downto 0) := (others=>'0');
  --signal mem_rqsts_wrData                 : std_logic_vector(CV_SIZE*MEM_RQST_W-1 downto 0) := (others=>'0');
  signal mem_rqsts_rdData                 : std_logic_vector(1074 downto 0) := (others=>'0');
  signal mem_rqsts_wrData                 : std_logic_vector(1074 downto 0) := (others=>'0');
  signal mem_rqsts_we                     : std_logic := '0';
  signal mem_rqst_waiting                 : std_logic := '0';
  signal mem_rqst_full                    : std_logic := '0';
  signal mem_rqst_usedw                   : std_logic_vector(8 downto 0) := (others=>'0');
  signal mem_rqst_empty                   : std_logic := '1';
  -- }}}
  -- CV side signals {{{
  type st_fill_type is (fill_buf0, fill_buf1, fill_wr_wide);
  type st_cv_side_type is (get_addr, send_rd_rqst, send_wr_rqst, get_wr_addr, send_wr_wide);
  signal st_cv_side, st_cv_side_n         : st_cv_side_type := get_addr;
  signal st_fill, st_fill_n               : st_fill_type := fill_buf0;
  signal mem_rqsts_buf_in                 : mem_rqsts_array(2*CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal mem_rqsts_buf_out                : mem_rqsts_array(2*CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal mem_rqsts_buf_enq                : std_logic_vector(2*CV_SIZE-1 downto 0) := (others=>'0');
  signal mem_rqsts_buf_deq                : std_logic_vector(2*CV_SIZE-1 downto 0) := (others=>'0');
  signal mem_rqsts_buf_full               : std_logic_vector(2*CV_SIZE-1 downto 0) := (others=>'0');
  signal mem_rqsts_buf_empty              : std_logic_vector(2*CV_SIZE-1 downto 0) := (others=>'0');
  -- }}}
  -- signals of send request pipes {{{
  signal mem_rqsts_nserved                : std_logic_vector(CV_SIZE*2-1 downto 0) := (others=>'0');
  signal mem_rqsts_nserved_n              : std_logic_vector(CV_SIZE*2-1 downto 0) := (others=>'0');
  signal mem_rqsts_valid                  : std_logic;
  signal mem_rqsts_valid_n                : std_logic;
  signal mem_rqsts_slctd_addr             : unsigned(GMEM_ADDR_W-1 downto 0) := (others=>'0');
  signal mem_rqsts_slctd_addr_n           : unsigned(GMEM_ADDR_W-1 downto 0) := (others=>'0');
  signal mem_rqsts_slctd_addr3            : unsigned(GMEM_ADDR_W-1 downto 0) := (others=>'0');
  signal mem_rqsts_slctd_addr3_n          : unsigned(GMEM_ADDR_W-1 downto 0) := (others=>'0');
  signal mem_rqsts_cntrl                  : unsigned(N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  signal mem_rqsts_cntrl_n                : unsigned(N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  signal mem_atomic_sgn                   : unsigned(N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  signal mem_atomic_sgn_n                 : unsigned(N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  signal mem_rqsts_rnw, mem_rqsts_rnw_n   : std_logic;
  signal mem_rqsts_simd, mem_rqsts_simd_n : std_logic;
  signal mem_rqsts_op_type                : std_logic_vector(2 downto 0);
  signal mem_rqsts_op_type_n              : std_logic_vector(2 downto 0);
  signal mem_rqsts_match                  : std_logic_vector(CV_SIZE*2-1 downto 0);
  signal mem_rqsts_match_n                : std_logic_vector(CV_SIZE*2-1 downto 0);
  signal last_rd_addr_v                   : std_logic := '0';
  signal last_rd_addr_v_n                 : std_logic := '0';
  signal wrData, wrData_n                 : SLV32_ARRAY(CV_SIZE*2-1 downto 0);
  signal wrData_ex, wrData_ex_n           : std_logic_vector(511 downto 0);
  type wrAddr_array is array(natural range <>) of std_logic_vector(GMEM_WR_N_WORDS_W+1 downto 0);
  signal wrAddr, wrAddr_n                 : wrAddr_array(CV_SIZE*2-1 downto 0);
  -- }}}
  -- meta data queue {{{
  -- 0..31: ADDR, 32:re, 33:atomic, 34..36: op_type, 37:alu_en, 38:simd, 39..50: rd_addr
  constant META_W                         : integer := GMEM_ADDR_W+1;
  constant META_ADDR_LOW                  : integer := 0; -- 32
  constant META_ADDR_HIGH                 : integer := META_ADDR_LOW+GMEM_ADDR_W-1; -- 63
  constant META_ALU_EN_POS                : integer := META_ADDR_HIGH+1; -- 69
  constant META_RD_ADDR_LOW               : integer := META_W*2*CV_SIZE; -- 71
  constant META_RD_ADDR_HIGH              : integer := META_RD_ADDR_LOW+FREG_FILE_W; -- 85
  constant META_RE_POS                    : integer := META_RD_ADDR_HIGH+1; -- 64
  constant META_ATOMIC_POS                : integer := META_RE_POS+1; -- 65
  constant META_OP_TYPE_LOW               : integer := META_ATOMIC_POS+1; -- 66
  constant META_OP_TYPE_HIGH              : integer := META_OP_TYPE_LOW+2; -- 68
  constant META_SIMD_POS                  : integer := META_OP_TYPE_HIGH+1; -- 70
  constant META_PHASE_LOW                 : integer := META_SIMD_POS+1;
  constant META_PHASE_HIGH                : integer := META_PHASE_LOW+2;
  constant META_WF_LOW                    : integer := META_PHASE_HIGH+1;
  constant META_WF_HIGH                   : integer := META_WF_LOW+7;
  constant META_TOTAL_W                   : integer := 2*CV_SIZE*META_W+FREG_FILE_W+1+17;
  constant META_DEPTH_W                   : integer := 5; -- half the total number of phases
  constant META_DEPTH                     : integer := 2**META_DEPTH_W;

  type meta_buffer_type is array(natural range <>) of std_logic_vector(META_TOTAL_W-1 downto 0);
  --signal metaQ                            : meta_buffer_type(META_DEPTH-1 downto 0) := (others=>(others=>'0'));
  signal metaQ_empty                      : std_logic := '1';
  signal metaQ_notEmpty                   : std_logic := '0';
  signal metaQ_full                       : std_logic := '0';
  signal metaQ_almfull                    : std_logic := '0';
  signal metaQ_re                         : std_logic := '0';
  signal metaQ_enq                        : std_logic := '0';
  signal metaQ_enq_n                      : std_logic := '0';
  signal metaQ_deq                        : std_logic := '0';
  signal metaQ_waiting                    : std_logic := '0';
  signal metaQ_rdData_n                   : std_logic_vector(META_TOTAL_W-1 downto 0) := (others=>'0');
  signal metaQ_rdData                     : std_logic_vector(META_TOTAL_W-1 downto 0) := (others=>'0');
  signal metaQ_wrData                     : std_logic_vector(META_TOTAL_W-1 downto 0) := (others=>'0');
  signal metaQ_usedw                      : std_logic_vector(META_DEPTH_W-1 downto 0) := (others=>'0');
  --signal metaQ_rdAddr                     : unsigned(META_DEPTH_W-1 downto 0) := (others=>'0');
  --signal metaQ_wrAddr                     : unsigned(META_DEPTH_W-1 downto 0) := (others=>'0');
  --signal metaQ_count                      : unsigned(META_DEPTH_W downto 0) := (others=>'0');
  -- }}}
  -- regFile signals {{{
  type regFile_interface_type is (compare_addr, update, update_simd);
  signal st_regFile_int, st_regFile_int_n : regFile_interface_type := compare_addr;
  signal regFile_we_n                     : std_logic_vector(2*CV_SIZE-1 downto 0) := (others=>'0');
  signal regFile_we_latch                 : std_logic := '0';
  signal regFile_we_latch_n               : std_logic := '0';
  signal regFile_wrAddr_n                 : unsigned(FREG_FILE_W downto 0) := (others=>'0');
  signal write_back                       : std_logic_vector(2*CV_SIZE-1 downto 0) := (others=>'0');
  signal write_back_n                     : std_logic_vector(2*CV_SIZE-1 downto 0) := (others=>'0');
  signal write_atomic_back                : std_logic_vector(2*CV_SIZE-1 downto 0) := (others=>'0');
  signal write_atomic_back_n              : std_logic_vector(2*CV_SIZE-1 downto 0) := (others=>'0');
  signal write_back_simd                  : std_logic_vector(1 downto 0) := (others=>'0');
  signal write_back_simd_n                : std_logic_vector(1 downto 0) := (others=>'0');
  signal regFile_wrData_v                 : std_logic;
  signal regFile_wrData_v_n               : std_logic;
  signal addr_ltch, addr_ltch_n           : std_logic_vector(GMEM_WORD_ADDR_W-CACHE_N_BANKS_W-1 downto 0);
  signal regFile_wrData_ltch              : std_logic_vector(DATA_W*CACHE_N_BANKS-1 downto 0);
  signal regFile_wrData_ltch_n            : std_logic_vector(DATA_W*CACHE_N_BANKS-1 downto 0);
  signal data_received                    : std_logic_vector(2*CV_SIZE-1 downto 0) := (others=>'0');
  signal data_received_n                  : std_logic_vector(2*CV_SIZE-1 downto 0) := (others=>'0');
  signal data_serverd                     : std_logic_vector(2*CV_SIZE-1 downto 0) := (others=>'0');
  signal data_serverd_n                   : std_logic_vector(2*CV_SIZE-1 downto 0) := (others=>'0');
  signal regFile_wrData_i                 : SLV32_ARRAY(2*CV_SIZE-1 downto 0);
  signal regFile_wrData_l                 : SLV32_ARRAY(2*CV_SIZE-1 downto 0);
  -- }}}
  -- signals of the request waiting to be processed {{{
  type st_waiting_type is (free, one_serve_zero_wait, one_serve_one_wait, zero_serve_one_wait);
  type cv_wrData_waiting_type is array(natural range <>) of SLV32_ARRAY(CV_SIZE-1 downto 0);
  type cv_addr_waiting_type is array(natural range <>) of GMEM_ADDR_ARRAY(CV_SIZE-1 downto 0);
  -- }}}
  -- mem interface {{{
  -- fifo line
  -- station_sgntr     atomic     rnw      we         valid      data
  -- N_CU_STATIONS_W   1          1        DATA_W/8   CV_SIZE    CV_SIZE*DATA_W
  constant DOUT_W                         : integer := GMEM_WORD_ADDR_W+N_CU_STATIONS_W;
  constant DOUT_ADDR_LOW                  : integer := 0;
  constant DOUT_ADDR_HIGH                 : integer := DOUT_ADDR_LOW+GMEM_WORD_ADDR_W-CACHE_N_BANKS_W-1;
  constant DOUT_RNW_POS                   : integer := DOUT_ADDR_HIGH+1;
  --constant DOUT_ATOMIC_POS                : integer := DOUT_RNW_POS+1;
  constant DOUT_OP_TYPE_LOW               : integer := DOUT_RNW_POS+1;
  constant DOUT_OP_TYPE_HIGH              : integer := DOUT_OP_TYPE_LOW+2;
  constant DOUT_SGNTR_LOW                 : integer := DOUT_OP_TYPE_HIGH+1;
  constant DOUT_SGNTR_HIGH                : integer := DOUT_SGNTR_LOW+N_CU_STATIONS_W-1;
  signal doutQ_empty                      : std_logic := '1';
  signal doutQ_full                       : std_logic := '0';
  signal doutQ_enq                        : std_logic := '0';
  signal doutQ_deq                        : std_logic := '0';
  signal doutQ_rdData                     : std_logic_vector(DOUT_W-1 downto 0) := (others=>'0');
  signal doutQ_wrData                     : std_logic_vector(DOUT_W-1 downto 0) := (others=>'0');
  constant DOUT_WR_W                      : integer := DATA_W+GMEM_WR_N_WORDS_W+2+1;
  constant DOUT_WR_DATA_LOW               : integer := 0;
  constant DOUT_WR_DATA_HIGH              : integer := DOUT_WR_DATA_LOW+DATA_W-1;
  constant DOUT_WR_ADDR_LOW               : integer := DOUT_WR_DATA_HIGH+1;
  constant DOUT_WR_ADDR_HIGH              : integer := DOUT_WR_ADDR_LOW+GMEM_WR_N_WORDS_W+1;
  constant DOUT_WR_VALID_POS              : integer := DOUT_WR_ADDR_HIGH+1;
  constant DOUT_WR_DATA_EX_LOW            : integer := DOUT_WR_W*GMEM_WR_N_WORDS;
  constant DOUT_WR_DATA_EX_HIGH           : integer := DOUT_WR_DATA_EX_LOW+511;
  constant DOUT_WR_TOTAL_ADDR_LOW         : integer := DOUT_WR_DATA_EX_HIGH+1;
  constant DOUT_WR_TOTAL_ADDR_HIGH        : integer := DOUT_WR_TOTAL_ADDR_LOW+GMEM_WORD_ADDR_W-GMEM_WR_N_WORDS_W-1;
  constant DOUT_WR_OP_TYPE_LOW            : integer := DOUT_WR_TOTAL_ADDR_HIGH+1;
  constant DOUT_WR_OP_TYPE_HIGH           : integer := DOUT_WR_OP_TYPE_LOW+2;
  constant DOUT_WR_TOTAL_W                : integer := DOUT_WR_W*GMEM_WR_N_WORDS+GMEM_WORD_ADDR_W-GMEM_WR_N_WORDS_W+3+512;
  constant CV_TO_CACHE_SLICE_W            : integer := 2;
  signal dout_wrQ_empty                   : std_logic := '1';
  signal dout_wrQ_full                    : std_logic := '0';
  signal dout_wrQ_enq                     : std_logic := '0';
  signal dout_wrQ_deq                     : std_logic := '0';
  signal dout_wrQ_rdData                  : std_logic_vector(DOUT_WR_TOTAL_W-1 downto 0) := (others=>'0');
  signal dout_wrQ_wrData                  : std_logic_vector(DOUT_WR_TOTAL_W-1 downto 0) := (others=>'0');
  type fifo_type is array (natural range <>) of std_logic_vector(DOUT_W-1 downto 0);
  type fifo_addr_type is array (natural range <>) of std_logic_vector(CV_SIZE*GMEM_ADDR_W-1 downto 0);
  signal fifo_cnt                         : unsigned(CV_TO_CACHE_SLICE_W-1 downto 0);
  signal fifo                             : fifo_type(2**FIFO_ADDR_W-1 downto 0) := (others=>(others=>'0'));
  signal fifo_addr                        : fifo_addr_type(2**FIFO_ADDR_W-1 downto 0) := (others=>(others=>'0'));
  signal fifo_wrAddr, fifo_rdAddr         : unsigned(FIFO_ADDR_W-1 downto 0) := (others=>'0');
  signal fifo_wrAddr_n, fifo_rdAddr_n     : unsigned(FIFO_ADDR_W-1 downto 0) := (others=>'0');
  signal push, push_d0                    : std_logic := '0';
  signal push_rqst_fifo_n                 : std_logic := '0';
  signal fifo_full                        : std_logic := '0';
  signal pop                              : std_logic := '0';
  signal din_rqst_fifo, din_rqst_fifo_d0  : std_logic_vector(DOUT_W-1 downto 0) := (others=>'0');
  signal din_rqst_fifo_addr               : std_logic_vector(CV_SIZE*GMEM_ADDR_W-1 downto 0) := (others=>'0');
  signal din_rqst_fifo_addr_n             : std_logic_vector(CV_SIZE*GMEM_ADDR_W-1 downto 0) := (others=>'0');
  signal din_rqst_fifo_addr_d0            : std_logic_vector(CV_SIZE*GMEM_ADDR_W-1 downto 0) := (others=>'0');
  constant c_rqst_fifo_addr_valid_len     : natural := 3;
  signal din_rqst_fifo_addr_d0_v          : unsigned(c_rqst_fifo_addr_valid_len-1 downto 0) := (others=>'0');
  signal dout_ready                       : std_logic;
  signal fifo_dout                        : fifo_type(CV_TO_CACHE_SLICE-1 downto 0) := (others=>(others=>'0'));
  signal fifo_addr_dout                   : fifo_addr_type(CV_TO_CACHE_SLICE-1 downto 0) := (others=>(others=>'0'));
  signal pop_vec                          : std_logic_vector(CV_TO_CACHE_SLICE-1 downto 0) := (others=>'0');
  signal lmem_rdData                      : SLV32_ARRAY(2*CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal lmem_rdData_d0                   : SLV32_ARRAY(2*CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal lmem_rdData_v                    : std_logic := '0';
  signal lmem_rdData_v_d0                 : std_logic := '0';
  signal lmem_rdData_v_p0                 : std_logic := '0';
  signal lmem_rdData_alu_en               : std_logic_vector(2*CV_SIZE-1 downto 0) := (others=>'0');
  signal lmem_rdData_rd_addr              : unsigned(REG_FILE_W-1 downto 0) := (others=>'0');
  signal sp                               : unsigned(LMEM_ADDR_W-N_WF_CU_W-PHASE_W-1 downto 0) := (others=>'0');
  signal lmem_rdAddr                      : unsigned(REG_FILE_W-1 downto 0) := (others=>'0');
  -- }}}
  -- read cache buffer signals ----------------------------------------------------------------------------{{{
  type data_buffer_type is array(natural range <>) of std_logic_vector(DATA_W*CACHE_N_BANKS-1 downto 0);
  type addr_buffer_type is array(natural range <>) of std_logic_vector(GMEM_WORD_ADDR_W-CACHE_N_BANKS_W-1 downto 0);
  signal dataQ                            : data_buffer_type(2**N_CU_STATIONS_W-1 downto 0) := (others=>(others=>'0'));
  signal addrQ                            : addr_buffer_type(2**N_CU_STATIONS_W-1 downto 0) := (others=>(others=>'0'));
  -- signal validQ                           : std_logic_vector(2**N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  signal valid_value                      : std_logic := '1';
  signal write_value                      : std_logic := '1';
  signal dataQ_notEmpty                   : std_logic := '0';
  signal dataQ_notEmpty_i                 : std_logic := '0';
  signal dataQ_notEmpty_i_n               : std_logic := '0';
  signal dataQ_rne                        : std_logic := '0';
  signal dataQ_re                         : std_logic := '0';
  signal dataQ_re_d0                      : std_logic := '0';
  signal dataQ_deq                        : std_logic := '0';
  signal dataQ_valid                      : std_logic := '0';
  signal dataQ_valid_i                    : std_logic := '0';
  signal dataQ_rdData_d0                  : std_logic_vector(DATA_W*CACHE_N_BANKS-1 downto 0) := (others=>'0');
  signal dataQ_rdData                     : std_logic_vector(DATA_W*CACHE_N_BANKS-1 downto 0) := (others=>'0');
  signal dataQ_rdData_n                   : std_logic_vector(DATA_W*CACHE_N_BANKS-1 downto 0) := (others=>'0');
  signal addrQ_rdData                     : std_logic_vector(GMEM_WORD_ADDR_W-CACHE_N_BANKS_W-1 downto 0) := (others=>'0');
  signal addrQ_rdData_n                   : std_logic_vector(GMEM_WORD_ADDR_W-CACHE_N_BANKS_W-1 downto 0) := (others=>'0');
  signal dataQ_clrAddr                    : unsigned(N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  signal dataQ_rdAddr_p0                  : unsigned(N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  signal dataQ_rdAddr                     : unsigned(N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  signal dataQ_rdAddr_n                   : unsigned(N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  signal dataQ_wrAddr                     : unsigned(N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  ---------------------------------------------------------------------------------------------------------}}}
  -- atomic cache buffer signals --------------------------------------------------------------------------{{{
  signal atomicQ                          : SLV32_ARRAY(2**N_CU_STATIONS_W-1 downto 0) := (others=>(others=>'0'));
  signal atomicQ_valid_value              : std_logic := '1';
  signal atomicQ_write_value              : std_logic := '1';
  signal atomicQ_notEmpty                 : std_logic := '0';
  signal atomicQ_re                       : std_logic := '0';
  signal atomicQ_deq                      : std_logic := '0';
  signal atomicQ_valid                    : std_logic := '0';
  signal atomicQ_rdData                   : std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  signal atomicQ_clrAddr                  : unsigned(N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  signal atomicQ_rdAddr_p0                : unsigned(N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  signal atomicQ_rdAddr                   : unsigned(N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  signal atomicQ_rdAddr_n                 : unsigned(N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  signal atomicQ_wrAddr                   : unsigned(N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  -- }}}
  ------------------------------------------------------------------------------------------------}}}
begin
  -- internal signals assignments -------------------------------------------------------------------------{{{
  regFile_wrAddr <= regFile_wrAddr_i;
  assert CV_TO_CACHE_SLICE > 0 severity failure;
  cntrl_idle <= cntrl_idle_i;
  ---------------------------------------------------------------------------------------------------------}}}
  -- meta queue -------------------------------------------------------------------------------------------{{{
  process(clk)
  begin
    if rising_edge(clk) then
      if st_fill = fill_buf0 then
        for i in 0 to CV_SIZE-1 loop
          metaQ_wrData(i*META_W+META_ADDR_HIGH downto i*META_W+META_ADDR_LOW) <= mem_rqsts_rdData(i*MEM_RQST_W+MEM_RQST_ADDR_HIGH downto i*MEM_RQST_W+MEM_RQST_ADDR_LOW);
          metaQ_wrData(i*META_W+META_ALU_EN_POS) <= mem_rqsts_rdData(i*MEM_RQST_W+MEM_RQST_ALU_EN_POS);
        end loop;
      else
        for i in CV_SIZE to 2*CV_SIZE-1 loop
          metaQ_wrData(i*META_W+META_ADDR_HIGH downto i*META_W+META_ADDR_LOW) <= mem_rqsts_rdData((i-CV_SIZE)*MEM_RQST_W+MEM_RQST_ADDR_HIGH downto (i-CV_SIZE)*MEM_RQST_W+MEM_RQST_ADDR_LOW);
          metaQ_wrData(i*META_W+META_ALU_EN_POS) <= mem_rqsts_rdData((i-CV_SIZE)*MEM_RQST_W+MEM_RQST_ALU_EN_POS);
        end loop;
      end if;
      metaQ_wrData(META_RD_ADDR_HIGH downto META_RD_ADDR_LOW) <= mem_rqsts_rdData(MEM_RQST_RD_ADDR_HIGH downto MEM_RQST_RD_ADDR_LOW);
      metaQ_wrData(META_RE_POS) <= mem_rqsts_rdData(MEM_RQST_RE_POS);
      if ATOMIC_IMPLEMENT /= 0 then 
        metaQ_wrData(META_ATOMIC_POS) <= mem_rqsts_rdData(MEM_RQST_ATOMIC_POS);
      end if;
      metaQ_wrData(META_OP_TYPE_HIGH downto META_OP_TYPE_LOW) <= mem_rqsts_rdData(MEM_RQST_OP_TYPE_HIGH downto MEM_RQST_OP_TYPE_LOW);
      metaQ_wrData(META_SIMD_POS) <= mem_rqsts_rdData(MEM_RQST_SIMD_POS);
      metaQ_wrData(META_PHASE_HIGH downto META_PHASE_LOW) <= mem_rqsts_rdData(MEM_RQST_RD_ADDR_HIGH-3) & mem_rqsts_rdData(MEM_RQST_RD_ADDR_HIGH-1 downto MEM_RQST_RD_ADDR_HIGH-2);
      metaQ_wrData(META_WF_HIGH downto META_WF_LOW) <= (others=>'0');
      metaQ_wrData(META_WF_LOW+to_integer(unsigned(
                          mem_rqsts_rdData(MEM_RQST_RD_ADDR_LOW+WI_FREG_ADDR_W+N_WF_CU_W-1 downto MEM_RQST_RD_ADDR_LOW+WI_FREG_ADDR_W)))) <= '1';

    end if;
  end process;
  metaQ_inst : component cumem_metaQ
    port map (
      data        => metaQ_wrData,  --  fifo_input.datain
      wrreq       => metaQ_enq, --            .wrreq
      rdreq       => metaQ_deq, --            .rdreq
      clock       => clk, --            .clk
      sclr        => not nrst,
      q           => metaQ_rdData,     -- fifo_output.dataout
      empty       => metaQ_empty,  --            .full
      almost_full => metaQ_almfull  --            .empty
    );
  ---------------------------------------------------------------------------------------------------------}}}
  -- CV interface (get requests) -------------------------------------------------------------------------------{{{
  mem_rqst_waiting <= not mem_rqst_empty;
  process(clk)
  begin
    if rising_edge(clk) then
      mem_rqsts_we <= '0';
      if cv_gmem_re = '1' or cv_gmem_we = '1' or (ATOMIC_IMPLEMENT /= 0 and cv_gmem_atomic = '1') then
        mem_rqsts_we <= '1';
      end if;

      mem_rqsts_wrData(MEM_RQST_ADDR_HIGH downto MEM_RQST_ADDR_LOW) <= std_logic_vector(cv_addr(0));
      mem_rqsts_wrData(MEM_RQST_RE_POS) <= cv_gmem_re;
      if ATOMIC_IMPLEMENT /= 0 then 
        mem_rqsts_wrData(MEM_RQST_ATOMIC_POS) <= cv_gmem_atomic;
      end if;
      mem_rqsts_wrData(MEM_RQST_OP_TYPE_HIGH downto MEM_RQST_OP_TYPE_LOW) <= cv_op_type;
      mem_rqsts_wrData(MEM_RQST_ALU_EN_POS) <= cv_alu_en(0);
      mem_rqsts_wrData(MEM_RQST_SIMD_POS) <= cv_gmem_simd;
      mem_rqsts_wrData(MEM_RQST_RD_ADDR_HIGH downto MEM_RQST_RD_ADDR_LOW) <= std_logic_vector(cv_rd_addr);

      if cv_gmem_simd = '0' or cv_gmem_we = '0' then
        mem_rqsts_wrData(MEM_RQST_DATA_HIGH downto MEM_RQST_DATA_LOW) <= cv_wrData(0);
        for i in 1 to CV_SIZE-1 loop
          mem_rqsts_wrData(i*MEM_RQST_W+MEM_RQST_DATA_HIGH downto i*MEM_RQST_W+MEM_RQST_DATA_LOW) <= cv_wrData(i);
          mem_rqsts_wrData(i*MEM_RQST_W+MEM_RQST_ADDR_HIGH downto i*MEM_RQST_W+MEM_RQST_ADDR_LOW) <= std_logic_vector(cv_addr(i));
          mem_rqsts_wrData(i*MEM_RQST_W+MEM_RQST_RE_POS) <= cv_gmem_re;
          if ATOMIC_IMPLEMENT /= 0 then 
            mem_rqsts_wrData(i*MEM_RQST_W+MEM_RQST_ATOMIC_POS) <= cv_gmem_atomic;
          end if;
          mem_rqsts_wrData(i*MEM_RQST_W+MEM_RQST_OP_TYPE_HIGH downto i*MEM_RQST_W+MEM_RQST_OP_TYPE_LOW) <= cv_op_type;
          mem_rqsts_wrData(i*MEM_RQST_W+MEM_RQST_ALU_EN_POS) <= cv_alu_en(i);
          mem_rqsts_wrData(i*MEM_RQST_W+MEM_RQST_SIMD_POS) <= cv_gmem_simd;
          mem_rqsts_wrData(i*MEM_RQST_W+MEM_RQST_RD_ADDR_HIGH downto i*MEM_RQST_W+MEM_RQST_RD_ADDR_LOW) <= std_logic_vector(cv_rd_addr);
        end loop;
      else
        mem_rqsts_wrData(MEM_RQST_DATA_HIGH downto MEM_RQST_DATA_LOW) <= cv_wrData_wide(DATA_W-1 downto 0);
        for i in 1 to CV_SIZE-1 loop
          mem_rqsts_wrData(i*MEM_RQST_W+MEM_RQST_DATA_HIGH downto i*MEM_RQST_W+MEM_RQST_DATA_LOW) <= cv_wrData_wide((i+1)*DATA_W-1 downto i*DATA_W);
          mem_rqsts_wrData((i+1)*MEM_RQST_W-1 downto i*MEM_RQST_W+DATA_W) <= 
            cv_wrData_wide(2*CV_SIZE*DATA_W+i*(MEM_RQST_W-DATA_W)-1 downto 2*CV_SIZE*DATA_W+(i-1)*(MEM_RQST_W-DATA_W));
        end loop;
        for i in 0 to CV_SIZE-1 loop
          mem_rqsts_wrData(CV_SIZE*MEM_RQST_W+(i+1)*DATA_W-1 downto CV_SIZE*MEM_RQST_W+i*DATA_W) <= cv_wrData_wide((i+CV_SIZE+1)*DATA_W-1 downto (i+CV_SIZE)*DATA_W);
        end loop;
        mem_rqsts_wrData(MEM_RQST_W+1024-32-1 downto CV_SIZE*MEM_RQST_W+CV_SIZE*DATA_W) <= cv_wrData_wide(1023 downto (CV_SIZE-1)*MEM_RQST_W+DATA_W*(CV_SIZE+1));
      end if;
    end if;
  end process;

  mem_rqsts_inst : component cumem_rqstQ
  port map (
    data  => mem_rqsts_wrData,  --  fifo_input.datain
    wrreq => mem_rqsts_we, --            .wrreq
    rdreq => mem_rqsts_rdAddr_inc_n, --            .rdreq
    clock => clk, --            .clk
    sclr  => not nrst,
    q     => mem_rqsts_rdData,     -- fifo_output.dataout
    full  => mem_rqst_full,  --            .full
    usedw => mem_rqst_usedw,
    empty => mem_rqst_empty  --            .empty
  );
  ---------------------------------------------------------------------------------------------------------}}}
  -- CV interface (schedule requests) -------------------------------------------------------------------{{{
  cv_fill_trans: process(clk)
  begin
    if rising_edge(clk) then
      if nrst = '0' then
        st_fill <= fill_buf0;
        metaQ_enq <= '0';
        check_finish <= (others=>'0');
        check_wr <= '0';
      else
        st_fill <= st_fill_n;
        metaQ_enq <= metaQ_enq_n;
        check_finish <= check_finish_n;
        check_wr <= check_wr_n;
      end if;
    end if;
  end process;

  mem_rqsts_bufs_inst : for i in 0 to CV_SIZE*2-1 generate
    mem_rqsts_buf_inst : entity fifo2
    generic map (FIFO_WIDTH => MEM_RQST_W)
    port map (
      din   => mem_rqsts_buf_in(i),  --  fifo_input.datain
      enq   => mem_rqsts_buf_enq(i), --            .wrreq
      deq   => mem_rqsts_buf_deq(i), --            .rdreq
      clk   => clk, --            .clk
      nrst  => nrst,  --            .sclr
      dout  => mem_rqsts_buf_out(i),     -- fifo_output.dataout
      full  => mem_rqsts_buf_full(i),  --            .full
      empty => mem_rqsts_buf_empty(i)  --            .empty
    );
  end generate mem_rqsts_bufs_inst;

  cv_fill_comb: process(st_fill, mem_rqsts_rdData, mem_rqsts_nserved, metaQ_almfull, check_finish,
    mem_rqst_waiting, check_wr, mem_rqsts_buf_empty, mem_rqsts_buf_full)
  begin
    st_fill_n <= st_fill;
    mem_rqsts_rdAddr_inc_n <= '0';
    metaQ_enq_n <= '0';
    check_finish_n <= (others=>'0');
    check_wr_n <= check_wr;
    mem_rqsts_buf_enq <= (others=>'0');
    for i in 0 to CV_SIZE-1 loop
      mem_rqsts_buf_in(i) <= mem_rqsts_rdData((i+1)*MEM_RQST_W-1 downto i*MEM_RQST_W);
      mem_rqsts_buf_in(i+CV_SIZE) <= mem_rqsts_rdData((i+1)*MEM_RQST_W-1 downto i*MEM_RQST_W);
    end loop;
    case st_fill is
      when fill_buf0 =>
        if mem_rqst_waiting = '1' and mem_rqsts_rdData(MEM_RQST_SIMD_POS) = '1' and mem_rqsts_rdData(MEM_RQST_RE_POS) = '0' then
          if mem_rqsts_buf_empty = (0 to 2*CV_SIZE-1=>'1') then
            st_fill_n <= fill_wr_wide;
          end if;
        elsif mem_rqst_waiting = '1' and metaQ_almfull = '0' and mem_rqsts_buf_full(CV_SIZE-1 downto 0) = (0 to CV_SIZE-1=>'0') then
          for i in 0 to CV_SIZE-1 loop
            mem_rqsts_buf_enq(i) <= '1';
          end loop;
          mem_rqsts_rdAddr_inc_n <= '1';
          st_fill_n <= fill_buf1;
        end if;

      when fill_buf1 =>
        if mem_rqsts_buf_full(2*CV_SIZE-1 downto CV_SIZE) = (0 to CV_SIZE-1=>'0') then
          for i in 0 to CV_SIZE-1 loop
            mem_rqsts_buf_enq(i+CV_SIZE) <= '1';
          end loop;
          mem_rqsts_rdAddr_inc_n <= '1';
          metaQ_enq_n <= mem_rqsts_rdData(MEM_RQST_RE_POS);
          if mem_rqsts_rdData(MEM_RQST_RD_ADDR_HIGH-1 downto MEM_RQST_RD_ADDR_HIGH-3) = "111" then
            check_finish_n(to_integer(unsigned(mem_rqsts_rdData(MEM_RQST_RD_ADDR_LOW+WI_REG_ADDR_W+N_WF_CU_W-1 downto MEM_RQST_RD_ADDR_LOW+WI_REG_ADDR_W)))) <= '1';
            check_wr_n <= not mem_rqsts_rdData(MEM_RQST_RE_POS);
          end if;
          st_fill_n <= fill_buf0;
        end if;

      when fill_wr_wide =>
        if mem_rqst_waiting = '1' then
          if mem_rqsts_rdData(MEM_RQST_SIMD_POS) = '1' and mem_rqsts_rdData(MEM_RQST_RE_POS) = '0' then
            if mem_rqsts_buf_full(0) = '0' then
              for i in 0 to CV_SIZE-1 loop
                mem_rqsts_buf_in(i+CV_SIZE)(MEM_RQST_DATA_HIGH downto MEM_RQST_DATA_LOW) <= mem_rqsts_rdData(CV_SIZE*MEM_RQST_W+(i+1)*DATA_W-1 downto CV_SIZE*MEM_RQST_W+i*DATA_W);
              end loop;
              mem_rqsts_buf_in(8)(MEM_RQST_W-1 downto DATA_W) <= mem_rqsts_rdData(970 downto 920);
              mem_rqsts_buf_in(9)(MEM_RQST_W-1 downto DATA_W) <= mem_rqsts_rdData(1021 downto 971);
              mem_rqsts_buf_in(10)(MEM_RQST_W-1 downto DATA_W) <= mem_rqsts_rdData(1072 downto 1022);
              mem_rqsts_buf_in(11)(DATA_W+1 downto DATA_W) <= mem_rqsts_rdData(1074 downto 1073);
              for i in 0 to 2*CV_SIZE-1 loop
                mem_rqsts_buf_enq(i) <= '1';
              end loop;
              mem_rqsts_rdAddr_inc_n <= '1';
              if mem_rqsts_rdData(MEM_RQST_RD_ADDR_HIGH-1 downto MEM_RQST_RD_ADDR_HIGH-3) = "111" then
                check_finish_n(to_integer(unsigned(mem_rqsts_rdData(MEM_RQST_RD_ADDR_LOW+WI_REG_ADDR_W+N_WF_CU_W-1 downto MEM_RQST_RD_ADDR_LOW+WI_REG_ADDR_W)))) <= '1';
                check_wr_n <= not mem_rqsts_rdData(MEM_RQST_RE_POS);
              end if;
            end if;
          else
            st_fill_n <= fill_buf0;
          end if;
        end if;
    end case;
  end process;

  cv_side_trans: process(clk)
  begin
    if rising_edge(clk) then
      if nrst = '0' then
        st_cv_side <= get_addr;
        mem_rqsts_cntrl <= (others=>'0');
        mem_rqsts_nserved <= (others=>'0');
        mem_rqsts_valid <= '0';
        mem_rqsts_match <= (others=>'0');
      else
        st_cv_side <= st_cv_side_n;
        mem_rqsts_cntrl <= mem_rqsts_cntrl_n;
        mem_rqsts_nserved <= mem_rqsts_nserved_n;
        mem_rqsts_valid <= mem_rqsts_valid_n;
        mem_rqsts_match <= mem_rqsts_match_n;
        if cv_gsync_reached_i = '1' or
          (mem_rqst_waiting = '1' and (mem_rqsts_rdData(MEM_RQST_RE_POS) = '0')) then
          last_rd_addr_v <= '0';
        else
          last_rd_addr_v <= last_rd_addr_v_n;
        end if;
      end if;
      cv_gsync_reached_i <= cv_gsync_reached;
      mem_rqsts_slctd_addr <= mem_rqsts_slctd_addr_n;
      mem_rqsts_slctd_addr3 <= mem_rqsts_slctd_addr3_n;
      wrData <= wrData_n;
      wrAddr <= wrAddr_n;
      wrData_ex <= wrData_ex_n;
      mem_rqsts_op_type <= mem_rqsts_op_type_n;
      mem_rqsts_rnw <= mem_rqsts_rnw_n;
      mem_rqsts_simd <= mem_rqsts_simd_n;
    end if;
  end process;

  cv_side_comb: process(st_cv_side, mem_rqsts_cntrl, mem_rqsts_nserved, mem_rqsts_slctd_addr3, mem_rqsts_op_type, mem_rqsts_rnw, wrData, wrAddr, 
    mem_rqsts_valid, mem_rqsts_match, mem_rqsts_buf_out, mem_rqsts_slctd_addr, doutQ_full, dout_wrQ_full, last_rd_addr_v, wrData_ex, 
    mem_rqsts_simd, mem_rqsts_buf_empty)
  begin
    st_cv_side_n <= st_cv_side;
    mem_rqsts_cntrl_n <= mem_rqsts_cntrl;
    mem_rqsts_nserved_n <= mem_rqsts_nserved;
    mem_rqsts_slctd_addr3_n <= mem_rqsts_slctd_addr3;
    mem_rqsts_slctd_addr_n <= mem_rqsts_slctd_addr;
    last_rd_addr_v_n <= last_rd_addr_v;
    mem_rqsts_op_type_n <= mem_rqsts_op_type;
    mem_rqsts_valid_n <= mem_rqsts_valid;
    mem_rqsts_simd_n <= mem_rqsts_simd;
    mem_rqsts_match_n <= mem_rqsts_match;
    mem_rqsts_rnw_n <= mem_rqsts_rnw;
    doutQ_enq <= '0';
    dout_wrQ_enq <= '0';
    mem_rqsts_buf_deq <= (others=>'0');
    wrData_n <= wrData;
    wrAddr_n <= wrAddr;
    wrData_ex_n <= wrData_ex;
    doutQ_wrData(DOUT_ADDR_HIGH downto DOUT_ADDR_LOW) <= std_logic_vector(mem_rqsts_slctd_addr(GMEM_ADDR_W-1 downto CACHE_N_BANKS_W+2));
    doutQ_wrData(DOUT_RNW_POS) <= mem_rqsts_rnw;
    doutQ_wrData(DOUT_OP_TYPE_HIGH downto DOUT_OP_TYPE_LOW) <= mem_rqsts_op_type;
    doutQ_wrData(DOUT_SGNTR_HIGH downto DOUT_SGNTR_LOW) <= std_logic_vector(mem_rqsts_cntrl);
    for i in 0 to 2*CV_SIZE-1 loop
      dout_wrQ_wrData(i*DOUT_WR_W+DOUT_WR_DATA_HIGH downto i*DOUT_WR_W+DOUT_WR_DATA_LOW) <= wrData(i);
      dout_wrQ_wrData(i*DOUT_WR_W+DOUT_WR_ADDR_HIGH downto i*DOUT_WR_W+DOUT_WR_ADDR_LOW) <= wrAddr(i);
      dout_wrQ_wrData(i*DOUT_WR_W+DOUT_WR_VALID_POS) <= mem_rqsts_match(i);
    end loop;
    dout_wrQ_wrData(DOUT_WR_TOTAL_ADDR_HIGH downto DOUT_WR_TOTAL_ADDR_LOW) <= std_logic_vector(mem_rqsts_slctd_addr(GMEM_ADDR_W-1 downto GMEM_WR_N_WORDS_W+2));
    dout_wrQ_wrData(DOUT_WR_OP_TYPE_HIGH downto DOUT_WR_OP_TYPE_LOW) <= mem_rqsts_op_type;
    dout_wrQ_wrData(DOUT_WR_DATA_EX_HIGH downto DOUT_WR_DATA_EX_LOW) <= wrData_ex;
    case st_cv_side is
      when get_addr =>
        mem_rqsts_valid_n <= '0';
        --if mem_rqsts_nserved = (0 to 2*CV_SIZE-1=>'0') then
        --  mem_rqsts_nserved_n <= (others=>'1');
        --end if;
        for i in 0 to 2*CV_SIZE-1 loop
          if mem_rqsts_buf_empty(i) = '0' and mem_rqsts_buf_out(i)(MEM_RQST_ALU_EN_POS) = '1' and 
            ((mem_rqsts_nserved(i) = '1' and mem_rqsts_nserved /= (0 to 2*CV_SIZE-1=>'0')) or mem_rqsts_nserved = (0 to 2*CV_SIZE-1=>'0')) then
            mem_rqsts_slctd_addr_n <= unsigned(mem_rqsts_buf_out(i)(MEM_RQST_ADDR_HIGH downto MEM_RQST_ADDR_LOW));
            mem_rqsts_op_type_n <= mem_rqsts_buf_out(i)(MEM_RQST_OP_TYPE_HIGH downto MEM_RQST_OP_TYPE_LOW);
            mem_rqsts_rnw_n <= mem_rqsts_buf_out(i)(MEM_RQST_RE_POS);
            mem_rqsts_simd_n <= mem_rqsts_buf_out(i)(MEM_RQST_SIMD_POS);
            mem_rqsts_valid_n <= '1';
            exit;
          end if;
        end loop;
        if mem_rqsts_buf_empty(0) = '0' and mem_rqsts_buf_out(0)(MEM_RQST_SIMD_POS) = '1' and mem_rqsts_buf_out(0)(MEM_RQST_RE_POS) = '0' then
          for i in 0 to 2*CV_SIZE-1 loop
            mem_rqsts_match_n(i) <= '1';
            wrData_n(i) <= mem_rqsts_buf_out(i)(MEM_RQST_DATA_HIGH downto MEM_RQST_DATA_LOW);
            wrAddr_n(i) <= std_logic_vector(to_unsigned(i*4, GMEM_WR_N_WORDS_W+2));
            mem_rqsts_buf_deq(i) <= '1';
          end loop;
          for i in 0 to 9 loop
            wrData_ex_n((i+1)*(MEM_RQST_W-DATA_W)-1 downto i*(MEM_RQST_W-DATA_W)) <= mem_rqsts_buf_out(i+1)(MEM_RQST_W-1 downto DATA_W);
          end loop;
          wrData_ex_n(511 downto 510) <= mem_rqsts_buf_out(11)(DATA_W+1 downto DATA_W);
          st_cv_side_n <= send_wr_wide;
        elsif mem_rqsts_buf_empty = (0 to 2*CV_SIZE-1=>'0') or mem_rqsts_nserved /= (0 to 2*CV_SIZE-1=>'0') then
          if mem_rqsts_buf_out(0)(MEM_RQST_RE_POS) = '1' or mem_rqsts_nserved /= (0 to 2*CV_SIZE-1=>'0') then
            if mem_rqsts_nserved = (0 to 2*CV_SIZE-1=>'0') then
              mem_rqsts_nserved_n <= (others=>'1');
            end if;
            st_cv_side_n <= send_rd_rqst;
          else
            last_rd_addr_v_n <= '0';
            st_cv_side_n <= send_wr_rqst;
          end if;
        end if;

      when send_rd_rqst =>
        if doutQ_full = '0' then
          if mem_rqsts_valid = '0' or (mem_rqsts_slctd_addr(GMEM_ADDR_W-1 downto CACHE_N_BANKS_W+2) = mem_rqsts_slctd_addr3(GMEM_ADDR_W-1 downto CACHE_N_BANKS_W+2) and
            last_rd_addr_v = '1') then
            doutQ_enq <= '0';
          else
            doutQ_enq <= '1';
            mem_rqsts_cntrl_n <= mem_rqsts_cntrl+1;
            mem_rqsts_slctd_addr3_n <= mem_rqsts_slctd_addr;
            last_rd_addr_v_n <= '1';
          end if;
          st_cv_side_n <= get_addr;
          for i in 2*CV_SIZE-1 downto 0 loop
            if mem_rqsts_buf_out(i)(MEM_RQST_ALU_EN_POS) = '0' or 
              (mem_rqsts_buf_out(i)(MEM_RQST_ADDR_HIGH downto MEM_RQST_ADDR_LOW+CACHE_N_BANKS_W+2) = std_logic_vector(mem_rqsts_slctd_addr(GMEM_ADDR_W-1 downto CACHE_N_BANKS_W+2))) then
              mem_rqsts_nserved_n(i) <= '0';
              mem_rqsts_buf_deq(i) <= mem_rqsts_nserved(i);
            end if;
          end loop;
        end if;

      --when send_rd_rqst2 =>
      --  if doutQ_full = '0' then
      --    doutQ_enq <= '1';
      --    doutQ_wrData(DOUT_ADDR_LOW) <= '1';
      --    mem_rqsts_slctd_addr3_n <= mem_rqsts_slctd_addr;
      --    mem_rqsts_slctd_addr3_n(CACHE_N_BANKS_W+2) <= '1';
      --    mem_rqsts_cntrl_n <= mem_rqsts_cntrl+1;

      --    mem_rqsts_valid_n <= '0';
      --    if mem_rqsts_nserved = (0 to 2*CV_SIZE-1=>'0') then
      --      mem_rqsts_nserved_n <= (others=>'1');
      --    end if;
      --    for i in 0 to 2*CV_SIZE-1 loop
      --      if mem_rqsts_buf_empty(i) = '0' and mem_rqsts_buf_out(i)(MEM_RQST_ALU_EN_POS) = '1' and (mem_rqsts_nserved(i) = '1' or mem_rqsts_nserved = (0 to 2*CV_SIZE-1=>'0')) then
      --        mem_rqsts_slctd_addr_n <= unsigned(mem_rqsts_buf_out(i)(MEM_RQST_ADDR_HIGH downto MEM_RQST_ADDR_LOW));
      --        mem_rqsts_op_type_n <= mem_rqsts_buf_out(i)(MEM_RQST_OP_TYPE_HIGH downto MEM_RQST_OP_TYPE_LOW);
      --        mem_rqsts_rnw_n <= mem_rqsts_buf_out(i)(MEM_RQST_RE_POS);
      --        mem_rqsts_simd_n <= mem_rqsts_buf_out(i)(MEM_RQST_SIMD_POS);
      --        mem_rqsts_valid_n <= '1';
      --        exit;
      --      end if;
      --    end loop;
      --    if mem_rqsts_buf_empty = (0 to 2*CV_SIZE-1=>'0') or mem_rqsts_nserved /= (0 to 2*CV_SIZE-1=>'0') then
      --      if mem_rqsts_buf_out(0)(MEM_RQST_RE_POS) = '1' then
      --        st_cv_side_n <= send_rd_rqst;
      --      else
      --        st_cv_side_n <= send_wr_rqst;
      --      end if;
      --    else
      --      st_cv_side_n <= get_addr;
      --    end if;
      --  end if;

      when send_wr_rqst =>
        mem_rqsts_match_n <= (others=>'0');
        for i in 2*CV_SIZE-1 downto 0 loop
          if mem_rqsts_buf_empty(i) = '0' and mem_rqsts_buf_out(i)(MEM_RQST_RE_POS) = '0' and mem_rqsts_buf_out(i)(MEM_RQST_ALU_EN_POS) = '1' and 
            (mem_rqsts_buf_out(i)(MEM_RQST_ADDR_HIGH downto MEM_RQST_ADDR_LOW+GMEM_WR_N_WORDS_W+2) = std_logic_vector(mem_rqsts_slctd_addr(GMEM_ADDR_W-1 downto GMEM_WR_N_WORDS_W+2))) then
            mem_rqsts_match_n(i) <= '1';
            wrData_n(i) <= mem_rqsts_buf_out(i)(MEM_RQST_DATA_HIGH downto MEM_RQST_DATA_LOW);
            wrAddr_n(i) <= mem_rqsts_buf_out(i)(MEM_RQST_ADDR_LOW+GMEM_WR_N_WORDS_W+1 downto MEM_RQST_ADDR_LOW);
            mem_rqsts_buf_deq(i) <= '1';
          elsif mem_rqsts_buf_out(i)(MEM_RQST_ALU_EN_POS) = '0' then
            mem_rqsts_buf_deq(i) <= '1';
          end if;
        end loop;
        if mem_rqsts_valid = '1' then
          st_cv_side_n <= get_wr_addr;
        else
          st_cv_side_n <= get_addr;
        end if;

      when get_wr_addr =>
        if doutQ_full = '0' and dout_wrQ_full = '0' then
          doutQ_enq <= '1';
          dout_wrQ_enq <= '1';
          mem_rqsts_valid_n <= '0';
          for i in 0 to 2*CV_SIZE-1 loop
            if mem_rqsts_buf_empty(i) = '0' and mem_rqsts_buf_out(i)(MEM_RQST_ALU_EN_POS) = '1' and mem_rqsts_buf_out(i)(MEM_RQST_RE_POS) = '0' then
              mem_rqsts_slctd_addr_n <= unsigned(mem_rqsts_buf_out(i)(MEM_RQST_ADDR_HIGH downto MEM_RQST_ADDR_LOW));
              mem_rqsts_op_type_n <= mem_rqsts_buf_out(i)(MEM_RQST_OP_TYPE_HIGH downto MEM_RQST_OP_TYPE_LOW);
              mem_rqsts_rnw_n <= '0';
              mem_rqsts_valid_n <= '1';
              exit;
            end if;
          end loop;
          st_cv_side_n <= send_wr_rqst;
        end if;

      when send_wr_wide =>
        if doutQ_full = '0' and dout_wrQ_full = '0' then
          doutQ_enq <= '1';
          dout_wrQ_enq <= '1';
          mem_rqsts_valid_n <= '0';
          st_cv_side_n <= get_addr;
        end if;
    end case;
  end process;

  doutQ_inst : entity fifo2
    generic map (FIFO_WIDTH => DOUT_W)
    port map (
      din   => doutQ_wrData,  --  fifo_input.datain
      enq   => doutQ_enq, --            .wrreq
      deq   => doutQ_deq, --            .rdreq
      clk   => clk, --            .clk
      nrst  => nrst,
      dout  => doutQ_rdData,     -- fifo_output.dataout
      full  => doutQ_full,  --            .full
      empty => doutQ_empty  --            .empty
    );

  dout_wrQ_inst : entity fifo2
    generic map (FIFO_WIDTH => DOUT_WR_TOTAL_W)
    port map (
      din   => dout_wrQ_wrData,  --  fifo_input.datain
      enq   => dout_wrQ_enq, --            .wrreq
      deq   => dout_wrQ_deq, --            .rdreq
      clk   => clk, --            .clk
      nrst  => nrst,
      dout  => dout_wrQ_rdData,     -- fifo_output.dataout
      full  => dout_wrQ_full,  --            .full
      empty => dout_wrQ_empty  --            .empty
    );

  -- gmem controller interface -------------------------------------------------------------------------------------------{{{
  doutQ_deq <= gmem_ready and gmem_valid;
  dout_wrQ_deq <= gmem_ready and (not gmem_rnw) and gmem_valid;
  gmem_valid <= not doutQ_empty;
  gmem_rnw <= doutQ_rdData(DOUT_RNW_POS);
  gmem_rqst_addr <= doutQ_rdData(DOUT_ADDR_HIGH downto DOUT_ADDR_LOW);
  gmem_rqst_cntrl <= unsigned(doutQ_rdData(DOUT_SGNTR_HIGH downto DOUT_SGNTR_LOW));
  gmem_wrData <= dout_wrQ_rdData;
  gmem_op_type <= doutQ_rdData(DOUT_OP_TYPE_HIGH downto DOUT_OP_TYPE_LOW);

  -- regFile interface ---------------------------------------------------------------------------------------{{{
  -- regFile comb process stage 1 ----------------------------------------------------------------------------{{{
  process(st_regFile_int, regFile_wrAddr, data_serverd, metaQ_rdData, addrQ_rdData, data_received, regFile_wrData_ltch, dataQ_rdData, write_back_simd,
    dataQ_valid, rreg_ready, vreg_ready, metaQ_empty, cv_gsync_reached_i, write_back, lmem_rdData_v_p0, addr_ltch, regFile_wrData_v, regFile_we_latch)
  variable meta_alu_en : std_logic_vector(2*CV_SIZE-1 downto 0) := (others=>'0');
  begin
    st_regFile_int_n <= st_regFile_int;
    regFile_wrAddr_n <= regFile_wrAddr;
    regFile_we_n <= (others=>'0');
    regFile_we_latch_n <= '0';
    metaQ_deq <= '0';
    dataQ_deq <= '0';
    atomicQ_deq <= '0';
    write_back_n <= (others=>'0');
    regFile_wrData_ltch_n <= regFile_wrData_ltch;
    write_atomic_back_n <= (others=>'0');
    write_back_simd_n <= "00";
    data_received_n <= data_received;
    data_serverd_n <= data_serverd;
    wfs_served_n <= (others=>'0');
    addr_ltch_n <= addr_ltch;
    if cv_gsync_reached_i = '1' or metaQ_rdData(META_RE_POS) = '0' then
      regFile_wrData_v_n <= '0';
    else
      regFile_wrData_v_n <= regFile_wrData_v;
    end if;
    case st_regFile_int is
      when compare_addr =>
        data_received_n <= (others=>'0');
        if metaQ_empty = '0' then
          regFile_wrAddr_n <= unsigned(metaQ_rdData(META_RD_ADDR_HIGH downto META_RD_ADDR_LOW));
          if dataQ_valid = '1' or regFile_wrData_v = '1' then
            for i in 0 to 2*CV_SIZE-1 loop
              data_serverd_n(i) <= (not metaQ_rdData(i*META_W+META_ALU_EN_POS)) or data_serverd(i);
            end loop;
            if regFile_wrData_v = '1' then
              for i in 0 to 2*CV_SIZE-1 loop
                if metaQ_rdData(i*META_W+META_ADDR_HIGH downto i*META_W+META_ADDR_LOW+CACHE_N_BANKS_W+2) = addr_ltch and metaQ_rdData(i*META_W+META_ALU_EN_POS) = '1' and
                  regFile_wrData_v = '1' and data_serverd(i) = '0' then
                  write_back_n(i) <= '1';
                  write_back_simd_n(0) <= '1';
                end if;
              end loop;
            end if;
            if dataQ_valid = '1' then
              for i in 0 to 2*CV_SIZE-1 loop
                if metaQ_rdData(i*META_W+META_ADDR_HIGH downto i*META_W+META_ADDR_LOW+CACHE_N_BANKS_W+2) = addrQ_rdData then
                  data_received_n(i) <= '1';
                  write_back_simd_n(1) <= '1';
                end if;
              end loop;
            end if;
            if metaQ_rdData(META_SIMD_POS) = '0' then
              if rreg_ready = '1' and lmem_rdData_v_p0 = '0' then
                st_regFile_int_n <= update;
              end if;
            elsif vreg_ready = '1' then
              st_regFile_int_n <= update_simd;
            end if;
          end if;
        end if;

      when update =>
        write_back_n <= write_back;
        if rreg_ready = '1' then
          if (write_back or data_serverd) /= (data_serverd'reverse_range => '1') and dataQ_valid = '1' then
            regFile_wrData_ltch_n <= dataQ_rdData;
            addr_ltch_n <= addrQ_rdData;
            regFile_wrData_v_n <= '1';
            dataQ_deq <= '1';
          end if;
          if (data_serverd or data_received or write_back) = (data_serverd'reverse_range => '1') then
            write_back_n <= (others=>'0');
            data_received_n <= (others=>'0');
            metaQ_deq <= '1';
            data_serverd_n <= (others=>'0');
            for i in 0 to 2*CV_SIZE-1 loop
              regFile_we_n(i) <= metaQ_rdData(i*META_W+META_ALU_EN_POS);
            end loop;
            regFile_we_latch_n <= '1';
            if metaQ_rdData(META_PHASE_HIGH downto META_PHASE_LOW) = (0 to PHASE_W-1=>'1') then
              wfs_served_n <= metaQ_rdData(META_WF_HIGH downto META_WF_LOW);
            end if;
            st_regFile_int_n <= compare_addr;
          elsif dataQ_valid = '1' then
            write_back_n <= (others=>'0');
            data_received_n <= (others=>'0');
            data_serverd_n <= data_serverd or data_received or write_back;
            st_regFile_int_n <= compare_addr;
          end if;
        end if;

      when update_simd=>
        regFile_wrAddr_n <= unsigned(metaQ_rdData(META_RD_ADDR_HIGH downto META_RD_ADDR_LOW));
        data_received_n <= (others=>'0');
        st_regFile_int_n <= compare_addr;
        if (write_back or data_serverd) /= (data_serverd'reverse_range => '1') then
          regFile_wrData_v_n <= '0';
          if dataQ_valid = '1' then
            regFile_wrData_ltch_n <= dataQ_rdData;
            addr_ltch_n <= addrQ_rdData;
            regFile_wrData_v_n <= '1';
            dataQ_deq <= '1';
          end if;
        end if;
        if ((data_serverd or write_back) = (data_serverd'reverse_range => '1')) or 
          ((data_serverd or data_received) = (data_serverd'reverse_range => '1')) then
          metaQ_deq <= '1';
          data_serverd_n <= (others=>'0');
          for i in 0 to 2*CV_SIZE-1 loop
            regFile_we_n(i) <= not data_serverd(i);
          end loop;
          regFile_we_latch_n <= '1';
          if metaQ_rdData(META_PHASE_HIGH downto META_PHASE_LOW) = (0 to PHASE_W-1=>'1') then
            wfs_served_n <= metaQ_rdData(META_WF_HIGH downto META_WF_LOW);
          end if;
        elsif write_back_simd(0) = '1' then
          regFile_we_latch_n <= '1';
          data_serverd_n <= data_serverd or write_back;
          regFile_we_n <= (not data_serverd) and write_back;
        elsif write_back_simd(1) = '1' then
          regFile_we_latch_n <= '1';
          data_serverd_n <= data_serverd or data_received;
          regFile_we_n <= (not data_serverd) and data_received;
        end if;
    end case;
  end process;
  ---------------------------------------------------------------------------------------------------------}}}
  -- regFile trans process --------------------------------------------------------------------------------{{{
  regFile_we_lmem_p0 <= lmem_rdData_v; -- @ level 19.
  regFile_wrData <= regFile_wrData_l when lmem_rdData_v_d0 = '1' else regFile_wrData_i;
  regFile_side_trans: process(clk)
    variable rdIndx : integer range 0 to RD_CACHE_N_WORDS-1 := 0;
  begin
    if rising_edge(clk) then
      regFile_we_latch <= regFile_we_latch_n;
      regFile_wrAddr_i <= regFile_wrAddr_n;
      write_back <= write_back_n;
      write_atomic_back <= write_atomic_back_n;
      if regFile_we_latch = '0' then
        regFile_we <= regFile_we_n;
      end if;
      lmem_rdData_d0 <= lmem_rdData; -- @ 20.
      if LMEM_IMPLEMENT /= 0 and lmem_rdData_v = '1' then -- level 19.
        regFile_we <= lmem_rdData_alu_en; -- @ 20.
      end if;
      if LMEM_IMPLEMENT /= 0 and lmem_rdData_v_p0 = '1' then
        regFile_wrAddr_i <= "0" & lmem_rdData_rd_addr; -- @ 20.
      end if;
      -- Plan A
      --for i in 0 to CV_SIZE-1 loop
      --  if LMEM_IMPLEMENT /= 0 and lmem_rdData_v = '1' then
      --    regFile_wrData(i) <= lmem_rdData(i); -- @ 20.
      --  elsif ATOMIC_IMPLEMENT /= 0 and write_atomic_back(i) = '1' then
      --    regFile_wrData(i) <= atomicQ_rdData;
      --  elsif write_back(i) = '1' then
      --    rdIndx := to_integer(unsigned(metaQ_rdData(i*META_W+META_ADDR_LOW+CACHE_N_BANKS_W+1 downto i*META_W+META_ADDR_LOW+2)));
      --    regFile_wrData(i) <= dataQ_rdData((rdIndx+1)*DATA_W-1 downto rdIndx*DATA_W);
      --  else
      --    regFile_wrData(i) <= regFile_wrData_i(i);
      --  end if;
      --end loop;
      -- Plan B
      lmem_rdData_v_d0 <= lmem_rdData_v;
      if LMEM_IMPLEMENT /= 0 and lmem_rdData_v = '1' then
        for i in 0 to 2*CV_SIZE-1 loop
          regFile_wrData_l(i) <= lmem_rdData(i); -- @ 20.
        end loop;
      end if;
      for i in 0 to 2*CV_SIZE-1 loop
        --if ATOMIC_IMPLEMENT /= 0 and write_atomic_back(i) = '1' then
        --  regFile_wrData_i(i) <= atomicQ_rdData;
        rdIndx := to_integer(unsigned(metaQ_rdData(i*META_W+META_ADDR_LOW+CACHE_N_BANKS_W+1 downto i*META_W+META_ADDR_LOW+2)));
        if write_back(i) = '1' then
          regFile_wrData_i(i) <= regFile_wrData_ltch((rdIndx+1)*DATA_W-1 downto rdIndx*DATA_W);
        elsif data_received(i) = '1' then
          regFile_wrData_i(i) <= dataQ_rdData((rdIndx+1)*DATA_W-1 downto rdIndx*DATA_W);
        end if;
      end loop;
      if write_back_simd(0) = '1' then
        regFile_wrData_wide <= regFile_wrData_ltch;
      elsif write_back_simd(1) = '1' then
        regFile_wrData_wide <= dataQ_rdData;
      end if;

      addr_ltch <= addr_ltch_n;
      regFile_wrData_ltch <= regFile_wrData_ltch_n;
        
      if nrst = '0' then
        st_regFile_int <= compare_addr;
        data_serverd <= (others=>'0');
        wfs_served <= (others=>'0');
        data_received <= (others=>'0');
        write_back_simd <= "00";
        regFile_wrData_v <= '0';
      else
        st_regFile_int <= st_regFile_int_n;
        data_serverd <= data_serverd_n;
        wfs_served <= wfs_served_n;
        data_received <= data_received_n;
        write_back_simd <= write_back_simd_n;
        regFile_wrData_v <= regFile_wrData_v_n;
      end if;
    end if;
  end process;
  ---------------------------------------------------------------------------------------------------------}}}
  -----------------------------------------------------------------------------------}}}
  -- gmem finished -------------------------------------------------------{{{
  process(clk)
    variable wf_busy_indices  : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  begin
    if rising_edge(clk) then
      if nrst = '0' then
        st_finish <= (others=>idle);
        wf_finish <= (others=>'0');
        wf_rdAddr <= (others=>(others=>'0'));
        cus_alm_full <= '0';
        wf_finish_rd <= (others=>'0');
      else
        st_finish <= st_finish_n;
        wf_finish <= wf_finish_n;
        cus_alm_full <= mem_rqst_usedw(8);
        wf_finish_rd <= (others=>'0');
        for i in 0 to N_WF_CU-1 loop
          if wfs_served(i) = '1' then
            wf_rdAddr(i) <= std_logic_vector(regFile_wrAddr_i(FREG_FILE_W) & regFile_wrAddr_i(WI_REG_ADDR_W-1 downto 0));
            wf_finish_rd(i) <= '1';
          end if;
        end loop;
      end if;
    end if;
  end process;

  st_finish_array: for i in 0 to N_WF_CU-1 generate
  begin
    process(st_finish(i), check_finish(i), wfs_served(i), check_wr)
    begin
      st_finish_n(i) <= st_finish(i);
      wf_finish_n(i) <= '0';
      case st_finish(i) is
        when idle =>
          if check_finish(i) = '1' then
            if check_wr = '1' then
               --or (ATOMIC_IMPLEMENT /= 0 and mem_rqsts_rdData_ltchd(0)(MEM_RQST_ATOMIC_POS) = '1') then
              st_finish_n(i) <= finished;
            end if;
          end if;
        when serving =>
          if wfs_served(i) = '1' then
            st_finish_n(i) <= finished;
          end if;
        when finished =>
          wf_finish_n(i) <= '1';
          st_finish_n(i) <= idle;
      end case;
    end process;
  end generate;
  ---------------------------------------------------------------------------------------------------------}}}
  -- controller idle -------------------------------------------------------------------------------------{{{
  process(clk)
  begin
    if rising_edge(clk) then
      if nrst = '0' then
        cntrl_idle_i <= '1';
      else
        if (metaQ_empty = '1') and mem_rqst_waiting = '0' and doutQ_empty = '1' and mem_rqsts_buf_empty = (0 to 2*CV_SIZE-1=>'1') then
          cntrl_idle_i <= '1';
        else
          cntrl_idle_i <= '0';
        end if;
      end if;
    end if;
  end process;
  ---------------------------------------------------------------------------------------------------------}}}
  -- cache read fifo -------------------------------------------------------------------------------------------{{{
    -- cu_mem_cntrl <- port A (myram) port B -> cache
  -- dataQ_notEmpty <= validQ(to_integer(dataQ_rdAddr));
  dataQ_re <= (dataQ_notEmpty xnor valid_value) and ((not dataQ_valid) or dataQ_deq);
  dataQ_rdAddr_n <= (dataQ_rdAddr+1) when dataQ_re = '1' else dataQ_rdAddr;
  dataQ_rdAddr_p0 <= (dataQ_rdAddr+1) when (dataQ_notEmpty = valid_value) else dataQ_rdAddr;
  write_value <= valid_value when (cache_rdCntrl >= dataQ_rdAddr) else (not valid_value);
  process(clk)
  begin
    if rising_edge(clk) then
      if cache_rdAck = '1' then
        dataQ(to_integer(cache_rdCntrl)) <= cache_rdData;
        addrQ(to_integer(cache_rdCntrl)) <= std_logic_vector(cache_rdAddr);
      end if;
      if dataQ_re = '1' then
        dataQ_rdData_n <= dataQ(to_integer(dataQ_rdAddr));
        addrQ_rdData_n <= addrQ(to_integer(dataQ_rdAddr));
      end if;
      if dataQ_deq = '1' or dataQ_valid = '0' then
        dataQ_rdData <= dataQ_rdData_n;
        addrQ_rdData <= addrQ_rdData_n;
      end if;

      if nrst = '0' then
        dataQ_rdAddr <= (others=>'0');
        dataQ_clrAddr <= (others=>'0');
        dataQ_valid <= '0';
        dataQ_valid_i <= '0';
        valid_value <= '1';
      else
        if dataQ_deq = '1' or dataQ_valid = '0' then
          dataQ_valid <= dataQ_valid_i;
        end if;
        if dataQ_re = '1' then
          dataQ_rdAddr <= dataQ_rdAddr_n;
          dataQ_clrAddr <= dataQ_rdAddr;
          dataQ_valid_i <= '1';
        elsif dataQ_deq = '1' or dataQ_valid = '0' then
          dataQ_valid_i <= '0';
        end if;
        if dataQ_re = '1' and (dataQ_rdAddr = (0 to N_CU_STATIONS_W-1=>'1')) then
          valid_value <= not valid_value;
        end if;
      end if;
    end if;
  end process;
  validQ_inst : component reorder_validQ
  generic map(ADDR_WIDTH => N_CU_STATIONS_W)
  port map(
    wrdata     => write_value,
    wraddr     => std_logic_vector(cache_rdCntrl),
    rdaddr     => std_logic_vector(dataQ_rdAddr_p0),
    we_a       => cache_rdAck,
    q_a        => dataQ_notEmpty,
    nrst       => nrst,
    clock      => clk
  );
  ---------------------------------------------------------------------------------------------------------}}}
  -- atomic -----------------------------------------------------------------------------------------------{{{
  atomic_queue_inst: if ATOMIC_IMPLEMENT /= 0 generate
    atomicQ_re <= atomicQ_notEmpty and ((not atomicQ_valid) or atomicQ_deq);
    atomicQ_rdAddr_n <= (atomicQ_rdAddr+1) when atomicQ_re = '1' else atomicQ_rdAddr;
    atomicQ_rdAddr_p0 <= (atomicQ_rdAddr+1) when atomicQ_notEmpty = '1' else atomicQ_rdAddr;
    atomicQ_write_value <= atomicQ_valid_value when (unsigned(atomic_sgntr) >= atomicQ_rdAddr) else (not atomicQ_valid_value);
    process(clk)
    begin
      if rising_edge(clk) then
        if atomic_rdData_v = '1' then
          atomicQ(to_integer(unsigned(atomic_sgntr))) <= atomic_rdData;
        end if;
        if atomicQ_re = '1' then
          atomicQ_rdData <= atomicQ(to_integer(atomicQ_rdAddr));
        end if;

        if nrst = '0' then
          atomicQ_rdAddr <= (others=>'0');
          atomicQ_clrAddr <= (others=>'0');
          atomicQ_valid_value <= '1';
        else
          if atomicQ_re = '1' then
            atomicQ_rdAddr <= atomicQ_rdAddr_n;
            atomicQ_clrAddr <= atomicQ_rdAddr;
            atomicQ_valid <= '1';
          elsif atomicQ_deq then
            atomicQ_valid <= '0';
          end if;
          if atomicQ_re = '1' and (atomicQ_rdAddr = (0 to N_CU_STATIONS_W-1=>'1')) then
            atomicQ_valid_value <= not atomicQ_valid_value;
          end if;
        end if;
      end if;
    end process;
    atomic_validQ_inst : component reorder_validQ
    generic map(ADDR_WIDTH => N_CU_STATIONS_W)
    port map(
      wrdata     => atomicQ_write_value,
      wraddr     => std_logic_vector(atomic_sgntr),
      rdaddr     => std_logic_vector(atomicQ_rdAddr_p0),
      we_a       => atomic_rdData_v,
      q_a        => atomicQ_notEmpty,
      nrst       => nrst,
      clock      => clk
    );
  end generate;
  -- }}}
  -- lmem -------------------------------------------------------------------------------------------------{{{
  local_memory_inst: if LMEM_IMPLEMENT /= 0 generate
  begin
    sp <= cv_addr(cv_alu_en_pri_enc)(LMEM_ADDR_W-N_WF_CU_W-PHASE_W-1 downto 0);
    lmem_rdAddr <= cv_rd_addr(FREG_FILE_W-1 downto WI_FREG_ADDR_W) & cv_rd_addr(WI_REG_ADDR_W-1 downto 0);
    local_memory: entity lmem
    port map(
      clk               => clk,
      rqst              => cv_lmem_rqst, -- level 17.
      we                => cv_lmem_we,
      alu_en            => cv_alu_en,
      wrData            => cv_wrData,
      rdData            => lmem_rdData, -- level 19.
      rdData_rd_addr    => lmem_rdData_rd_addr, -- level 19.
      rdData_v          => lmem_rdData_v, -- level 19.
      rdData_v_p0       => lmem_rdData_v_p0, -- level 19.
      rdData_alu_en     => lmem_rdData_alu_en, -- level 19.
      -- connect all of cv_addr; you have 8 SPs!!
      sp                => sp,
      rd_addr           => lmem_rdAddr,
      nrst              => nrst
    );
  end generate;
  ---------------------------------------------------------------------------------------------------------}}}
end architecture;
