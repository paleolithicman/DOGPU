-- libraries -------------------------------------------------------------------------------------------{{{
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.all;
use work.FGPU_definitions.all;
---------------------------------------------------------------------------------------------------------}}}
entity CV is  -- {{{
generic(
  cuIdx : integer range 0 to N_CU-1 := 0
);
port(
  -- CU Scheduler signals 
  instr                   : in std_logic_vector(DATA_W-1 downto 0); -- level 0.
  instr_macro             : in std_logic_vector(DATA_W-1 downto 0); -- level 0.
  wf_indx, wf_indx_in_wg  : in natural range 0 to N_WF_CU-1; -- level 0.
  phase                   : in unsigned(PHASE_W-1 downto 0); -- level 0.
  swc_phase               : in std_logic_vector(CV_W-1 downto 0); -- level 0.
  alu_en_divStack         : in std_logic_vector(CV_SIZE-1 downto 0) := (others=>'X'); -- level 2.

  -- RTM signals
  rdAddr_alu_en           : out unsigned(N_WF_CU_W+PHASE_W-1 downto 0) := (others=>'X'); -- level 2.
  rdData_alu_en           : in std_logic_vector(CV_SIZE-1 downto 0) := (others=>'X'); -- level 4.
  rtm_rdAddr              : out unsigned(RTM_ADDR_W-1 downto 0) := (others => 'X'); -- level 13.
  rtm_rdData              : in unsigned(RTM_DATA_W-1 downto 0); -- level 15.
  
  -- gmem signals
  gmem_re, gmem_we        : out std_logic := 'X';     -- level 17.
  mem_op_type             : out std_logic_vector(2 downto 0) := (others=>'X'); --level 17.
  mem_addr                : out GMEM_ADDR_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X'));   -- level 17.
  mem_rd_addr             : out unsigned(FREG_FILE_W downto 0) := (others=>'X'); -- level 17.
  mem_wrData              : out SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X')); --level 17.
  mem_wrData_wide         : out std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0);
  alu_en                  : out std_logic_vector(CV_SIZE-1 downto 0) := (others=>'X'); -- level 17.
  alu_en_pri_enc          : out integer range 0 to CV_SIZE-1 := 0; -- level 17.
  lmem_rqst, lmem_we      : out std_logic := 'X';     -- level 17.
  smem_rqst, smem_we      : out std_logic := 'X';     -- level 17.
  gmem_atomic             : out std_logic := 'X';     -- level 17.
  gmem_simd               : out std_logic := 'X';
  smem_addr               : out GMEM_ADDR_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0'));   -- level 17.
  smem_op_type            : out std_logic_vector(2 downto 0) := (others=>'0'); --level 17.
  smem_rd_addr            : out unsigned(FREG_FILE_W downto 0) := (others=>'0'); -- level 17.
  smem_rd_addr2           : out unsigned(FREG_FILE_W downto 0) := (others=>'0');
  smem_grant              : out std_logic := 'X';
  rreg_ready              : out std_logic;
  vreg_ready              : out std_logic;
  vreg_re_busy            : out std_logic;

  --branch
  wf_is_branching         : out std_logic_vector(N_WF_CU-1 downto 0) := (others=>'X'); -- level 18.
  alu_branch              : out std_logic_vector(CV_SIZE-1 downto 0) := (others=>'X'); -- level 18.
  
  mem_regFile_wrAddr      : in unsigned(FREG_FILE_W downto 0) := (others=>'0'); -- stage -1 (stable for 3 clock cycles)
  mem_regFile_we          : in std_logic_vector(2*CV_SIZE-1 downto 0); -- stage 0 (stable for 2 clock cycles) (level 20. for loads from lmem)
  mem_regFile_wrData      : in SLV32_ARRAY(2*CV_SIZE-1 downto 0) := (others=>(others=>'X')); -- stage 0 (stabel for 2 clock cycles)
  mem_regFile_wrData_wide : in std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'X');
  lmem_regFile_we_p0      : in std_logic := 'X'; -- level 19.

  smem_regFile_wrAddr_p2  : in unsigned(FREG_FILE_W downto 0) := (others=>'0');
  smem_regFile_wrAddr     : in unsigned(FREG_FILE_W downto 0);
  smem_regFile_wrAddr_wide : in unsigned(FREG_FILE_W downto 0);
  smem_regFile_wv         : in std_logic;
  smem_regFile_we         : in std_logic_vector(CV_SIZE-1 downto 0);
  smem_regFile_we_wide    : in std_logic_vector(CV_SIZE-1 downto 0);
  smem_regFile_wv_wide_p1 : in std_logic;
  smem_regFile_wrData     : in SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X'));
  smem_regFile_wrData_wide : in std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'X');
  smem_dot_addr           : in unsigned(FREG_FILE_W downto 0) := (others=>'0');

  nrst                    : in std_logic;
  clk                     : in std_logic
);
  attribute max_fanout of wf_indx : signal is 10;
end CV; -- }}}
architecture Behavioral of CV is
  -- signals definitions -------------------------------------------------------------------------------------- {{{
  -----------------  RTM & Initial ALU enable
  type rtm_rdAddr_vec_type is array (natural range <>) of unsigned(RTM_ADDR_W-1 downto 0);
  signal rtm_rdAddr_vec                   : rtm_rdAddr_vec_type(9 downto 0) := (others=>(others=>'X'));
  signal rdData_alu_en_vec                : alu_en_vec_type(MAX_FPU_DELAY+6 downto 0) := (others=>(others=>'X'));
  signal rtm_rdData_d0                    : unsigned(RTM_DATA_W-1 downto 0);
  signal alu_en_divStack_vec              : alu_en_vec_type(2 downto 0) := (others=>(others=>'X'));
  signal rdAddr_alu_en_p0                 : unsigned(N_WF_CU_W+PHASE_W-1 downto 0) := (others=>'X');

  -----------------  global use
  signal phase_d0, phase_d1               : unsigned( PHASE_W-1 downto 0) := (others=>'0');
  type phase_vec_type is array (natural range <>) of unsigned(PHASE_W-1 downto 0);
  signal phase_vec                        : phase_vec_type(7 downto 0);
  signal op_arith_shift, op_arith_shift_n : op_arith_shift_type := op_add;
  signal nrst_i                           : std_logic := 'X';
  
  ------------------    decoding 
  signal family                           : std_logic_vector(FAMILY_W-1 downto 0) := (others=>'X');
  signal code                             : std_logic_vector(CODE_W-1 downto 0) := (others=>'X');
  signal family2                          : std_logic_vector(FAMILY_W-1 downto 0) := (others=>'X');
  signal code2                            : std_logic_vector(CODE_W-1 downto 0) := (others=>'X');
  signal inst_rd_addr, inst_rs_addr       : std_logic_vector(WI_REG_ADDR_W-1 downto 0) := (others=>'X');
  signal inst_rt_addr                     : std_logic_vector(WI_REG_ADDR_W-1 downto 0) := (others=>'X');
  signal minst_rd_addr                    : std_logic_vector(WI_REG_ADDR_W-1 downto 0) := (others=>'X');
  signal minst_rt_addr, minst_rs_addr     : std_logic_vector(WI_REG_ADDR_W-1 downto 0) := (others=>'X');
  signal finst_rd_addr, finst_rs_addr     : std_logic_vector(WI_FREG_ADDR_W-1 downto 0) := (others=>'X');
  signal finst_rt_addr                    : std_logic_vector(WI_FREG_ADDR_W-1 downto 0) := (others=>'X');
  signal fmem_rt_addr, fmem_rs_addr       : std_logic_vector(WI_REG_ADDR_W-1 downto 0) := (others=>'X');
  signal fmem_rd_addr                     : std_logic_vector(WI_FREG_ADDR_W-1 downto 0) := (others=>'X');
  type dim_vec_type is array (natural range <>) of std_logic_vector(1 downto 0);
  signal dim_vec                          : dim_vec_type(1 downto 0) := (others=>(others=>'X'));
  signal dim                              : std_logic_vector(1 downto 0) := (others=>'X');
  type params_vec_type is array (natural range <>) of std_logic_vector(N_PARAMS_W-1 downto 0);
  signal params_vec                       : params_vec_type(1 downto 0) := (others=>(others=>'X'));
  signal params                           : std_logic_vector(N_PARAMS_W-1 downto 0) := (others=>'X');
  type family_vec_type is array(natural range <>) of std_logic_vector(FAMILY_W-1 downto 0);
  signal family_vec                       : family_vec_type(MAX_FPU_DELAY+10 downto 0) := (others=>(others=>'X'));
  signal family_vec2                      : family_vec_type(MAX_FPU_DELAY+10 downto 0) := (others=>(others=>'X'));
  signal family_vec_at_16                 : std_logic_vector(FAMILY_W-1 downto 0) := (others=>'X'); -- this signal is extracted out of family_vec to dcrease the fanout @family_vec(..@16)
  attribute max_fanout of family_vec_at_16: signal is 40;
  signal branch_on_zero                   : std_logic := 'X';
  signal branch_on_not_zero               : std_logic := 'X';
  signal wf_is_branching_p0               : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'X');
  signal code_vec                         : code_vec_type(15 downto 0) := (others=>(others=>'0'));
  signal code_vec2                         : code_vec_type(15 downto 0) := (others=>(others=>'0'));
  type immediate_vec_type is array(natural range <>) of std_logic_vector(IMM_W-1 downto 0);
  signal immediate_vec                    : immediate_vec_type(7 downto 0) := (others=>(others=>'0'));
  signal immediate2_vec                   : immediate_vec_type(7 downto 0) := (others=>(others=>'0'));
  type macro_slct_vec_type is array(natural range <>) of std_logic_vector(8 downto 0);
  signal macro_slct_vec                   : macro_slct_vec_type(12 downto 0);
  type wf_indx_array is array (natural range <>) of natural range 0 to N_WF_CU-1;
  signal wf_indx_vec                      : wf_indx_array(15 downto 0) := (others=>0);
  signal wf_indx_in_wg_vec                : wf_indx_array(1 downto 0) := (others=>0); 
  ------------------   register file  
  signal rs_addr, rt_addr, rd_addr        : unsigned(REG_FILE_BLOCK_W-1 downto 0) := (others=>'X');
  signal mrs_addr, mrt_addr               : unsigned(REG_FILE_BLOCK_W-1 downto 0) := (others=>'X');
  -- signal frs_addr, frt_addr, frd_addr     : unsigned(FREG_FILE_BLOCK_W-1 downto 0) := (others=>'X');
  signal vra_addr, vrb_addr               : unsigned(FREG_FILE_BLOCK_W-1 downto 0) := (others=>'0');
  type op_arith_shift_vec_type is array(natural range <>) of op_arith_shift_type;
  signal op_arith_shift_vec               : op_arith_shift_vec_type(4 downto 0) := (others => op_add);
  signal op_vmem_v                        : std_logic := 'X';
  signal op_vmem_v_vec                    : std_logic_vector(2 downto 0);
  signal op_logical_v                     : std_logic := 'X';
  signal op_activate_v                    : std_logic := 'X';
  signal vra_re, vra_re_n                 : std_logic := 'X';
  signal regBlock_re                      : std_logic_vector(N_REG_BLOCKS-1 downto 0) := (others=>'X');
  signal mregBlock_re                     : std_logic_vector(N_REG_BLOCKS-1 downto 0) := (others=>'X');
  signal vregBlock_re                     : std_logic_vector(N_FREG_BLOCKS-1 downto 0) := (others=>'X');
  -- attribute max_fanout of regBlock_re    : signal is 10;
  signal regBlocK_re_n                    : std_logic := 'X';
  signal mregBlocK_re_n                   : std_logic := 'X';
  signal vregBlocK_re_n                   : std_logic := 'X';
  signal vregBlocK_re2_n                   : std_logic := 'X';
  signal reg_we_alu, reg_we_alu_n         : std_logic_vector(CV_SIZE-1 downto 0) := (others=>'X');
  signal reg_we_float                     : std_logic_vector(CV_SIZE-1 downto 0) := (others=>'X');
  signal res_alu                          : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X'));
  type rd_out_vec_type is array (natural range <>) of slv32_array(CV_SIZE-1 downto 0);
  signal rd_out                           : slv32_array(CV_SIZE-1 downto 0) := (others=>(others=>'X'));
  signal rd_out_vec_in                    : slv32_array(CV_SIZE-1 downto 0) := (others=>(others=>'X'));
  signal rd_out_vec                       : rd_out_vec_type(4 downto 0) := (others=>(others=>(others=>'X')));
  signal vrd_out                          : simd_array(CV_SIZE-1 downto 0);
  signal vrd_out_vec_in                   : std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0);
  signal vrd_out_vec                      : simd_array(4 downto 0);

  ------------------    global memory
  signal gmem_re_p0, gmem_we_p0           : std_logic := 'X';
  signal gmem_ato_p0                      : std_logic := 'X'; 
  type swc_offset_array is array (natural range <>) of std_logic_vector(CV_W-1 downto 0);
  signal swc_offset_vec                   : swc_offset_array(15 downto 0) := (others=>(others=>'0'));
  -------------------------------------------------------------------------------------}}}
  -- write back into regFiles  {{{
  type regBlock_we_vec_type is array(natural range <>) of std_logic_vector(N_REG_BLOCKS-1 downto 0);
  type fregBlock_we_vec_type is array(natural range <>) of vreg_we_array(N_FREG_BLOCKS-1 downto 0);
  signal regBlock_we                      : regBlock_we_vec_type(CV_SIZE-1 downto 0) := (others=>(others=>'X'));
  signal mregBlock_we                     : regBlock_we_vec_type(CV_SIZE-1 downto 0) := (others=>(others=>'X'));
  signal fregBlock_we                     : fregBlock_we_vec_type(CV_SIZE-1 downto 0) := (others=>(others=>(others=>'X')));
  signal regBlock_we_alu                  : std_logic_vector(N_REG_BLOCKS-1 downto 0) := (others=>'X');
  signal fregBlock_we_alu                 : std_logic_vector(N_FREG_BLOCKS-1 downto 0) := (others=>'X');
  attribute max_fanout of regBlock_we_alu : signal is 50;
  signal regBlock_we_mem                  : std_logic_vector(N_REG_BLOCKS-1 downto 0) := (others=>'X');
  signal fregBlock_we_mem                 : std_logic_vector(N_FREG_BLOCKS-1 downto 0) := (others=>'X');
  signal vrs_addr_vec                     : wi_reg_addr_array(7 downto 0);
  signal vres_addr                        : unsigned(REG_FILE_W-1 downto 0) := (others=>'0');
  signal wrAddr_regFile_vec               : reg_addr_array(LLFU_DELAY+12 downto 0) := (others=>(others=>'0'));
  signal wrAddr_regFile_vec2              : reg_addr_array(LLFU_DELAY+12 downto 0) := (others=>(others=>'0'));
  signal wrAddr_fregFile_vec              : freg_addr_array(MAX_FPU_DELAY+12 downto 0) := (others=>(others=>'X'));
  signal rdAddr_vec                       : freg_addr_array(MAX_FPU_DELAY+12 downto 0) := (others=>(others=>'X'));
  signal regBlock_wrAddr                  : reg_file_block_array(N_REG_BLOCKS-1 downto 0) := (others=>(others=>'X'));
  signal mregBlock_wrAddr                 : reg_file_block_array(N_REG_BLOCKS-1 downto 0) := (others=>(others=>'X'));
  signal fregBlock_wrAddr                 : freg_file_block_array(N_FREG_BLOCKS-1 downto 0) := (others=>(others=>'X'));
  signal wrData_alu                       : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X'));
  type regBlock_wrData_type is array(natural range <>) of slv32_array(N_REG_BLOCKS-1 downto 0);
  type fregBlock_wrData_type is array(natural range <>) of simd_array(N_FREG_BLOCKS-1 downto 0);
  signal regBlock_wrData                  : regBlock_wrData_type(CV_SIZE-1 downto 0) := (others=>(others=>(others=>'X')));
  signal mregBlock_wrData                 : regBlock_wrData_type(CV_SIZE-1 downto 0) := (others=>(others=>(others=>'X')));
  signal fregBlock_wrData                 : fregBlock_wrData_type(CV_SIZE-1 downto 0) := (others=>(others=>(others=>'X')));
  signal rtm_rdData_nlid_vec              : std_logic_vector(3 downto 0) := (others=>'X');
  signal res_low                          : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X')); 
  signal res_alu_clk2x_d0                 : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X')); 
  signal res_high                         : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X')); 
  signal res_sum                          : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X')); 
  signal res_sum2                         : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X')); 
  signal res_act                          : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X')); 
  signal reg_we_mov_vec                   : alu_en_vec_type(6 downto 0) := (others=>(others=>'X'));
  signal mem_regFile_wrAddr_d0            : unsigned(REG_FILE_W downto 0);
  signal mem_regFile_wrAddr_d1            : unsigned(REG_FILE_W-1 downto 0);
  signal mem_regFile_we_d0                : std_logic_vector(2*CV_SIZE-1 downto 0) := (others=>'0');
  signal lmem_regFile_we                  : std_logic := 'X';
  -- }}}
  -- floating point {{{
  signal float_a, float_b, float_c        : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X'));
  signal mrs, mrt                         : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X'));
  signal float_a_d0, float_b_d0           : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X'));
  signal res_float                        : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X'));
  signal res_float_d0                     : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X'));
  signal res_float_d1                     : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X'));
  signal regBlock_we_float_vec            : regBlock_we_vec_type(MAX_FPU_DELAY-7 downto 0) := (others=>(others=>'X'));
  signal regBlock_we_float                : std_logic_vector(N_REG_BLOCKS-1 downto 0) := (others=>'X');
  attribute max_fanout of regBlock_we_float : signal is 50;
  -- }}}
  -- dot product {{{
  signal smem_regFile_wrData_d1           : std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'X');
  signal smem_regFile_wrData_d2           : std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'X');
  signal acc                              : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X'));
  signal vrs_out                          : SIMD_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X'));
  signal vrt_out                          : SIMD_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X'));
  signal vres_out                         : SIMD_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X'));
  signal vwe                              : vreg_we_array(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal dot_valid_in                     : std_logic_vector(CV_SIZE-1 downto 0);
  signal dot_valid_in_d1                  : std_logic_vector(CV_SIZE-1 downto 0);
  signal dot_valid_in_d2                  : std_logic_vector(CV_SIZE-1 downto 0);
  signal dot_wrAddr_vec                   : memreg_addr_array(DOT_DELAY+1 downto 0);
  signal res_dot                          : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'X'));
  signal dot_res_valid                    : std_logic_vector(CV_SIZE-1 downto 0);
  signal dot_res_valid_p1                 : std_logic_vector(CV_SIZE-1 downto 0);
  signal dot_wrAddr                       : unsigned(FREG_FILE_W downto 0);
  signal smem_dot_addr_vec                : freg_addr_array(23 downto 0) := (others=>(others=>'0'));
    -- }}}
  -- large latency function units {{{
  signal sigmoid_valid_in                 : std_logic_vector(CV_SIZE-1 downto 0) := (others=>'X');
  signal sig_res_valid                    : std_logic_vector(CV_SIZE-1 downto 0) := (others=>'X');
  signal sig_res_valid_p1                 : std_logic_vector(CV_SIZE-1 downto 0) := (others=>'X');
  signal sig_res                          : SLV32_ARRAY(CV_SIZE-1 downto 0);
  signal tanh_valid_in                    : std_logic_vector(CV_SIZE-1 downto 0) := (others=>'X');
  signal tanh_res_valid                   : std_logic_vector(CV_SIZE-1 downto 0) := (others=>'X');
  signal tanh_res_valid_p1                : std_logic_vector(CV_SIZE-1 downto 0) := (others=>'X');
  signal tanh_res                         : SLV32_ARRAY(CV_SIZE-1 downto 0);
  signal llfu_valid                       : std_logic := 'X';
  signal llfu_valid_p1                    : std_logic := 'X';
  signal llfu_valid_vec                   : std_logic_vector(CV_SIZE-1 downto 0) := (others=>'X');
  signal llfu_res                         : SLV32_ARRAY(CV_SIZE-1 downto 0);
  signal llfu_wrAddr                      : unsigned(FREG_FILE_W-1 downto 0);
  -- }}}
  -- control status register {{{
  type csr_type is array(natural range <>) of slv32_array(CV_SIZE-1 downto 0);
  signal csr                              : csr_type(N_WF_CU*PHASE_LEN-1 downto 0);
  signal csr_out_n                        : slv32_array(CV_SIZE-1 downto 0);
  signal csr_out_vec                      : csr_type(4 downto 0);
  signal csr_addr                         : unsigned(N_WF_CU_W+PHASE_W-1 downto 0) := (others=>'0');
  signal vreg_re_busy_d0                  : std_logic;
  --}}}
begin
  -- internal signals and asserts -------------------------------------------------------------------------{{{
  process(clk)
  begin
    if rising_edge(clk) then
      nrst_i <= nrst;
    end if;
  end process;
  ---------------------------------------------------------------------------------------------------------}}}
  -- RTM contorl & ALU enable -------------------------------------------------------------------- {{{
  process(clk)
  begin
    if rising_edge(clk) then
      -- rtm {{{
      rtm_rdData_d0 <= rtm_rdData; -- @ 16.
      if nrst = '0' then
        rtm_rdAddr_vec <= (others=>(others=>'0'));
        rtm_rdAddr <= (others=>'0');
      else
        if family_vec(family_vec'high-1) = RTM_FAMILY then -- level 2.
          case code_vec(code_vec'high-1) is -- level 2.
            when LID =>
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(RTM_ADDR_W-1) <= '0'; -- @ 3.
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(RTM_ADDR_W-2 downto RTM_ADDR_W-3) <= unsigned(dim_vec(dim_vec'high-1)); --dimension
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(N_WF_CU_W+PHASE_W-1 downto PHASE_W) <= to_unsigned(wf_indx_in_wg_vec(wf_indx_in_wg_vec'high-1), N_WF_CU_W);
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(PHASE_W-1 downto 0) <= phase_d1;
            when WGOFF =>
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(RTM_ADDR_W-1) <= '1'; -- @ 3.
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(RTM_ADDR_W-2 downto RTM_ADDR_W-3) <= unsigned(dim_vec(dim_vec'high-1)); --dimension  
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(N_WF_CU_W+PHASE_W-1 downto PHASE_W) <= to_unsigned(wf_indx_vec(wf_indx_vec'high-1), N_WF_CU_W);
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(PHASE_W-1 downto 0) <= (others=>'0');
            when SIZE =>
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(RTM_ADDR_W-1) <= '1'; -- @ 3.
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(RTM_ADDR_W-2 downto RTM_ADDR_W-3) <= (others=>'1');
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(N_WF_CU_W+PHASE_W-1 downto PHASE_W) <= (PHASE_W+2=>'0', others=>'1'); 
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(PHASE_W-1) <= '0';
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(PHASE_W-2 downto 0) <= unsigned(dim_vec(dim_vec'high-1));
            when WGID =>
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(RTM_ADDR_W-1) <= '1'; -- @ 3.
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(RTM_ADDR_W-2 downto RTM_ADDR_W-3) <= (others=>'1');
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(N_WF_CU_W+PHASE_W-1 downto PHASE_W) <= (PHASE_W+1=>'1', others=>'0'); 
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(PHASE_W-1) <= '0';
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(PHASE_W-2 downto 0) <= unsigned(dim_vec(dim_vec'high-1));
            when WGSIZE =>
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(RTM_ADDR_W-1) <= '1'; -- @ 3.
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(RTM_ADDR_W-2 downto RTM_ADDR_W-3) <= (others=>'1');
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(N_WF_CU_W+PHASE_W-1 downto PHASE_W) <= (PHASE_W+1=>'1', others=>'0'); 
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(PHASE_W-1) <= '0';
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(PHASE_W-2 downto 0) <= unsigned(dim_vec(dim_vec'high-1));
            when LP =>
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(RTM_ADDR_W-1) <= '1'; -- @ 3.
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(RTM_ADDR_W-2 downto RTM_ADDR_W-3) <= "11"; --dimension  
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(N_WF_CU_W+PHASE_W-1 downto N_PARAMS_W) <= (others=>'0'); -- wf_indx is zero, except its LSB, 
              rtm_rdAddr_vec(rtm_rdAddr_vec'high)(N_PARAMS_W-1 downto 0) <= unsigned(params_vec(params_vec'high-1)); -- @ 2.

            when others =>
          end case;
        end if;
        rtm_rdAddr_vec(rtm_rdAddr_vec'high-1 downto 0) <= rtm_rdAddr_vec(rtm_rdAddr_vec'high downto 1); -- @ 4.->12.
        rtm_rdAddr <= rtm_rdAddr_vec(0); -- @ 13.
      end if;
      rtm_rdData_nlid_vec(rtm_rdData_nlid_vec'high-1 downto 0) <= rtm_rdData_nlid_vec(rtm_rdData_nlid_vec'high downto 1); -- @ 14.->16.
      rtm_rdData_nlid_vec(rtm_rdData_nlid_vec'high) <= rtm_rdAddr_vec(0)(RTM_ADDR_W-1); -- @ 13.
      -- }}}
      -- ALU enable {{{
      rdAddr_alu_en_p0(PHASE_W-1 downto 0) <= phase; --@ 1.
      rdAddr_alu_en_p0(N_WF_CU_W+PHASE_W-1 downto PHASE_W) <= to_unsigned(wf_indx_in_wg, N_WF_CU_W); --@ 1.
      rdAddr_alu_en <= rdAddr_alu_en_p0; -- @ 2.
      
      alu_en_divStack_vec(alu_en_divStack_vec'high) <= alu_en_divStack; -- @ 3.
      alu_en_divStack_vec(alu_en_divStack_vec'high-1 downto 0) <= alu_en_divStack_vec(alu_en_divStack_vec'high downto 1); -- @ 4.->5.

      rdData_alu_en_vec(rdData_alu_en_vec'high) <= rdData_alu_en; -- @ 5.
      rdData_alu_en_vec(rdData_alu_en_vec'high-1) <= rdData_alu_en_vec(rdData_alu_en_vec'high) and not alu_en_divStack_vec(0); -- @ 6.
      rdData_alu_en_vec(rdData_alu_en_vec'high-2 downto 0) <= rdData_alu_en_vec(rdData_alu_en_vec'high-1 downto 1); -- @ 7.->7+MAX_FPU_DELAY+4.

      -- for gmem operations
      if family_vec(family_vec'high-15) = CLS_FAMILY then
        alu_en <= rdData_alu_en_vec(rdData_alu_en_vec'high-11) and reg_we_mov_vec(0); -- @ 17.
      else
        alu_en <= rdData_alu_en_vec(rdData_alu_en_vec'high-11); -- @ 17.
      end if;
      alu_en_pri_enc <= 0; -- @ 17.
      for i in CV_SIZE-1 downto 0 loop
        if rdData_alu_en_vec(rdData_alu_en_vec'high-11)(i) = '1' then -- level 16.
          alu_en_pri_enc <= i; -- @ 17.
        end if;
      end loop;
      -- }}}
    end if;
  end process;
  ----------------------------------------------------------------------------------------------}}}
  -- decoding logic --------------------------------------------------------------------{{{
  family <= instr(FAMILY_POS+FAMILY_W-1 downto FAMILY_POS);    -- alias
  code <= instr(CODE_POS+CODE_W-1 downto CODE_POS); -- alias
  family2 <= instr_macro(FAMILY_POS+FAMILY_W-1 downto FAMILY_POS);    -- alias
  code2 <= instr_macro(CODE_POS+CODE_W-1 downto CODE_POS); -- alias
  inst_rd_addr <= instr(RD_POS+WI_REG_ADDR_W-1 downto RD_POS); -- alias
  inst_rs_addr <= instr(RS_POS+WI_REG_ADDR_W-1 downto RS_POS); -- alias
  inst_rt_addr <= instr(RT_POS+WI_REG_ADDR_W-1 downto RT_POS); -- alias
  minst_rd_addr <= instr_macro(FRD_POS+WI_FREG_ADDR_W-1 downto FRD_POS); -- alias
  minst_rs_addr <= instr_macro(RS_POS+WI_REG_ADDR_W-1 downto RS_POS); -- alias
  minst_rt_addr <= instr_macro(RT_POS+WI_REG_ADDR_W-1 downto RT_POS); -- alias
  finst_rd_addr <= instr(FRD_POS+WI_FREG_ADDR_W-1 downto FRD_POS); -- alias
  finst_rs_addr <= instr(FRS_POS+WI_FREG_ADDR_W-1 downto FRS_POS); -- alias
  finst_rt_addr <= instr(FRT_POS+WI_FREG_ADDR_W-1 downto FRT_POS); -- alias
  fmem_rd_addr <= instr(4 downto 0); -- alias
  fmem_rs_addr <= instr(9 downto 5); -- alias
  fmem_rt_addr <= instr(14 downto 10); -- alias
  dim <= instr(DIM_POS+1 downto DIM_POS);
  params <= instr(PARAM_POS+N_PARAMS_W-1 downto PARAM_POS);
  
  process(clk)
  begin
    if rising_edge(clk) then
      if nrst = '0' then
        code_vec <= (others=>(others=>'0'));
        code_vec2 <= (others=>(others=>'0'));
        family_vec <= (others=>(others=>'0'));
        family_vec2 <= (others=>(others=>'0'));
        dim_vec <= (others=>(others=>'0'));
        params_vec <= (others=>(others=>'0'));
        macro_slct_vec <= (others=>(others=>'0'));
      else
        family_vec(family_vec'high-1 downto 0) <= family_vec(family_vec'high downto 1); -- @ 2.->2+MAX_FPU_DELAY+9.
        family_vec(family_vec'high) <= family; -- @ 1.
        family_vec2(family_vec2'high-1 downto 0) <= family_vec2(family_vec2'high downto 1); -- @ 2.->2+MAX_FPU_DELAY+9.
        family_vec2(family_vec2'high) <= family2; -- @ 1.
        family_vec_at_16 <= family_vec(family_vec'high-14); -- @ 16.
        dim_vec(dim_vec'high-1 downto 0) <= dim_vec(dim_vec'high downto 1); -- @ 2
        dim_vec(dim_vec'high) <= dim; -- @ 1.
        code_vec(code_vec'high-1 downto 0) <= code_vec(code_vec'high downto 1); -- @ 2.->16.
        code_vec(code_vec'high) <= code; -- @ 1.
        code_vec2(code_vec2'high-1 downto 0) <= code_vec2(code_vec2'high downto 1); -- @ 2.->16.
        code_vec2(code_vec2'high) <= code2; -- @ 1.
        params_vec(params_vec'high-1 downto 0) <= params_vec(params_vec'high downto 1); -- @ 2.->2.
        params_vec(params_vec'high) <= params; -- @ 1.
        macro_slct_vec(macro_slct_vec'high-1 downto 0) <= macro_slct_vec(macro_slct_vec'high downto 1);
        macro_slct_vec(macro_slct_vec'high) <= instr(23 downto 15);
      end if; 

      -- pipes {{{
      immediate_vec(immediate_vec'high-1 downto 0) <= immediate_vec(immediate_vec'high downto 1); -- @ 2.->6.
      if (family = GLS_FAMILY and code(2 downto 0) = "111") or (family = LSI_FAMILY and code(0) = '1') 
          or (family = CLS_FAMILY) then -- level 0.
        immediate_vec(immediate_vec'high)(IMM_W-1 downto 0) <= "0000000" & instr(23 downto 15); -- @ 1.
      else
        immediate_vec(immediate_vec'high)(IMM_ARITH_W-1 downto 0) <= instr(IMM_POS+IMM_ARITH_W-1 downto IMM_POS); -- @ 1.
        immediate_vec(immediate_vec'high)(IMM_W-1 downto IMM_ARITH_W) <= instr(RS_POS+IMM_W-IMM_ARITH_W-1 downto RS_POS); -- @ 1.
      end if;
      immediate2_vec(immediate2_vec'high-1 downto 0) <= immediate2_vec(immediate2_vec'high downto 1);
      if (family2 /= "0000") then
        immediate2_vec(immediate2_vec'high)(IMM_W-1 downto 0) <= "0000000" & instr_macro(23 downto 15); -- @ 1.
      end if;
      swc_offset_vec(swc_offset_vec'high-1 downto 0) <= swc_offset_vec(swc_offset_vec'high downto 1); -- @ 2. -> 17.
      swc_offset_vec(swc_offset_vec'high) <= swc_phase;
      wf_indx_vec(wf_indx_vec'high-1 downto 0) <= wf_indx_vec(wf_indx_vec'high downto 1); -- @ 2.->16.
      wf_indx_vec(wf_indx_vec'high) <= wf_indx; -- @ 1.
      wf_indx_in_wg_vec(wf_indx_in_wg_vec'high-1 downto 0) <= wf_indx_in_wg_vec(wf_indx_in_wg_vec'high downto 1); -- @ 2.->2.
      wf_indx_in_wg_vec(wf_indx_in_wg_vec'high) <= wf_indx_in_wg; -- @ 1.
      regBlock_re(0) <= regBlock_re_n; -- @ 1.
      regBlock_re(regBlock_re'high downto 1) <= regBlock_re(regBlock_re'high-1 downto 0); -- @ 2.->4.
      mregBlock_re(0) <= mregBlock_re_n; -- @ 1.
      mregBlock_re(mregBlock_re'high downto 1) <= mregBlock_re(mregBlock_re'high-1 downto 0); -- @ 2.->4.
      vregBlock_re(0) <= vregBlock_re_n or vregBlock_re2_n; -- @ 1.
      vregBlock_re(vregBlock_re'high downto 1) <= vregBlock_re(vregBlock_re'high-1 downto 0); -- @ 2.->4.

      vra_re <= vra_re_n; -- @ 1.
      op_arith_shift <= op_arith_shift_n;   -- @ 1.
      op_arith_shift_vec(op_arith_shift_vec'high-1 downto 0) <= op_arith_shift_vec(op_arith_shift_vec'high downto 1); -- @ 3.->6.
      op_arith_shift_vec(op_arith_shift_vec'high) <= op_arith_shift; -- @ 2.
      phase_vec(phase_vec'high) <= phase;
      phase_vec(phase_vec'high-1 downto 0) <= phase_vec(phase_vec'high downto 1);
      phase_d0 <= phase; -- @ 1.
      phase_d1 <= phase_d0; -- @ 2.
      -- }}}
      -- Rs, Rt & Rd addresses {{{
      rs_addr(REG_FILE_BLOCK_W-1) <= phase(PHASE_W-1); -- @1.
      rs_addr(WI_REG_ADDR_W+N_WF_CU_W-1 downto WI_REG_ADDR_W) <= to_unsigned(wf_indx, N_WF_CU_W); -- @1.
      if family = ADD_FAMILY and code(3) = '1'then -- level 0.
        rs_addr(WI_REG_ADDR_W-1 downto 0) <= (others=>'0'); -- @1. -- for li & lui
      elsif (family = GLS_FAMILY and code(2 downto 0) = "111") or (family = LSI_FAMILY and code(0) = '1') then -- level 0.
        rs_addr(WI_REG_ADDR_W-1 downto 0) <= unsigned(fmem_rs_addr); -- @1.
      else
        rs_addr(WI_REG_ADDR_W-1 downto 0) <= unsigned(inst_rs_addr); -- @1.
      end if;

      rt_addr(REG_FILE_BLOCK_W-1) <= phase(PHASE_W-1); -- @1.
      rt_addr(WI_REG_ADDR_W+N_WF_CU_W-1 downto WI_REG_ADDR_W) <= to_unsigned(wf_indx, N_WF_CU_W); -- @1.
      if (family = GLS_FAMILY and code(2 downto 0) = "111") or (family = LSI_FAMILY and code(0) = '1') then -- level 0.
        rt_addr(WI_REG_ADDR_W-1 downto 0) <= unsigned(fmem_rt_addr); -- @1.
      else
        rt_addr(WI_REG_ADDR_W-1 downto 0) <= unsigned(inst_rt_addr); -- @1.
      end if;

      rd_addr <= wrAddr_regFile_vec(wrAddr_regFile_vec'high)(REG_FILE_BLOCK_W-1 downto 0); -- @1.

      mrs_addr(REG_FILE_BLOCK_W-1) <= phase(PHASE_W-1); -- @1.
      mrs_addr(WI_REG_ADDR_W+N_WF_CU_W-1 downto WI_REG_ADDR_W) <= to_unsigned(wf_indx, N_WF_CU_W); -- @1.
      mrs_addr(WI_REG_ADDR_W-1 downto 0) <= unsigned(minst_rs_addr); -- @1.
      mrt_addr(REG_FILE_BLOCK_W-1) <= phase(PHASE_W-1); -- @1.
      mrt_addr(WI_REG_ADDR_W+N_WF_CU_W-1 downto WI_REG_ADDR_W) <= to_unsigned(wf_indx, N_WF_CU_W); -- @1.
      mrt_addr(WI_REG_ADDR_W-1 downto 0) <= unsigned(minst_rt_addr); -- @1.
      -- }}}
      -- vra, vrb address {{{
      vra_addr(FREG_FILE_BLOCK_W-1 downto FREG_FILE_BLOCK_W-2) <= phase(PHASE_W-1 downto PHASE_W-2);
      vra_addr(WI_FREG_ADDR_W+N_WF_CU_W-1 downto WI_FREG_ADDR_W) <= to_unsigned(wf_indx, N_WF_CU_W);
      if (family2 /= "0000") then
        if code(2 downto 0) = "110" then
          vra_addr(WI_FREG_ADDR_W-1 downto 0) <= unsigned(minst_rd_addr);
        else
          vra_addr(WI_FREG_ADDR_W-1 downto 0) <= unsigned(minst_rt_addr);
        end if;
      end if;

      vrb_addr(FREG_FILE_BLOCK_W-1 downto FREG_FILE_BLOCK_W-2) <= phase(PHASE_W-1 downto PHASE_W-2);
      vrb_addr(WI_FREG_ADDR_W+N_WF_CU_W-1 downto WI_FREG_ADDR_W) <= to_unsigned(wf_indx, N_WF_CU_W);
      if (family = GLS_FAMILY or family = LSI_FAMILY or family = CLS_FAMILY) and (code(3) = '1' and code(1 downto 0) = "11") then -- level 0.
        vrb_addr(WI_FREG_ADDR_W-1 downto 0) <= unsigned(finst_rd_addr);
      else
        vrb_addr(WI_FREG_ADDR_W-1 downto 0) <= unsigned(minst_rs_addr);
      end if;

      vrs_addr_vec(vrs_addr_vec'high) <= minst_rs_addr;
      vrs_addr_vec(vrs_addr_vec'high-1 downto 0) <= vrs_addr_vec(vrs_addr_vec'high downto 1);

      -- }}}
      -- set operation type {{{
      op_logical_v <= '0'; -- @ 14.
      op_activate_v <= '0'; -- @ 14.
      op_vmem_v <= '0';
      if family_vec(family_vec'high-12) = LGK_FAMILY then -- level 13.
        op_logical_v <= '1'; -- @ 14.
      elsif family_vec(family_vec'high-12) = MCR_FAMILY then -- level 13.
        if code_vec(code_vec'high-12) = CODE_ACT and macro_slct_vec(0)(1 downto 0) = ACT_RELU then
          op_activate_v <= '1'; -- @ 14.
        end if;
      end if;
      if (family_vec(family_vec'high-5) = GLS_FAMILY or family_vec(family_vec'high-5) = LSI_FAMILY or family_vec(family_vec'high-5) = CLS_FAMILY) and
        (code_vec(code_vec'high-5)(3) = '1' and code_vec(code_vec'high-5)(1 downto 0) = "11") then
        op_vmem_v <= '1';
      end if;
      op_vmem_v_vec(op_vmem_v_vec'high) <= op_vmem_v;
      op_vmem_v_vec(op_vmem_v_vec'high-1 downto 0) <= op_vmem_v_vec(op_vmem_v_vec'high downto 1);
      -- }}}
    end if;
  end process;
  -- memory accesses {{{
  process(clk)
  begin
    if rising_edge(clk) then
      if nrst_i = '0' then
          vreg_ready <= '1';
          vreg_re_busy <= '0';
      else
        if family_vec2(family_vec2'high-15) = MCR_FAMILY and code_vec2(code_vec2'high-15)(3) = '1' and
          smem_regFile_wv_wide_p1 = '1' then -- level 16. vreg write port busy
          vreg_ready <= '0'; -- @ 17.
        else
          vreg_ready <= '1';
        end if;
        if family_vec2(family_vec2'high) = MCR_FAMILY and code_vec2(code_vec2'high)(1 downto 0) = "10" then
          vreg_re_busy <= '1'; -- @ 2.
        else
          vreg_re_busy <= '0';
        end if;
      end if;
    end if;
  end process;
  process(clk)
  begin
    if rising_edge(clk) then
      -- pipes {{{
      vrd_out_vec_in <= vrd_out(to_integer(unsigned(swc_offset_vec(swc_offset_vec'high-9)))); -- level 10.
      vrd_out_vec(vrd_out_vec'high) <= vrd_out_vec_in; -- level 11.
      vrd_out_vec(vrd_out_vec'high-1 downto 0) <= vrd_out_vec(vrd_out_vec'high downto 1); -- @ 12.->16.
      rd_out_vec_in <= rd_out;
      rd_out_vec(rd_out_vec'high) <= rd_out_vec_in; -- level 11.
      rd_out_vec(rd_out_vec'high-1 downto 0) <= rd_out_vec(rd_out_vec'high downto 1); -- @ 12.->16.
      -- }}}
      -- @ 16 {{{
      gmem_re_p0 <= '0'; -- @ 16.
      gmem_we_p0 <= '0'; -- @ 16.
      if family_vec(family_vec'high-14) = GLS_FAMILY or family_vec(family_vec'high-14) = CLS_FAMILY then -- level 15.
        if code_vec(1)(3) = '1' then -- level 15.
          gmem_re_p0 <= '0'; -- store @ 16.
          gmem_we_p0 <= '1';
        else
          gmem_re_p0 <= '1'; -- load @ 16.
          gmem_we_p0 <= '0';
        end if;
      end if;

      
      if ATOMIC_IMPLEMENT /= 0 then
        gmem_ato_p0 <= '0';
        if family_vec(family_vec'high-14) = ATO_FAMILY then -- level 15.
          gmem_ato_p0 <= '1'; -- @ 16.
        end if;
      end if;
      -- }}}
      -- @ 17 {{{
      gmem_we <= gmem_we_p0; -- @ 17.
      gmem_re <= gmem_re_p0; -- @ 17.
      if ATOMIC_IMPLEMENT /= 0 then
        gmem_atomic <= gmem_ato_p0; -- @ 17.
      end if;

      if LMEM_IMPLEMENT /= 0 then
        lmem_rqst <= '0'; -- @ 17.
        lmem_we <= '0'; -- @ 17.
        if family_vec(family_vec'high-15) = LSI_FAMILY and code_vec(0)(0) /= '1' then -- level 16.
          lmem_rqst <= '1'; -- @ 17.
          if code_vec(0)(3) =  '1' then -- level 16.
            lmem_we <= '1'; -- @ 17.
          else
            lmem_we <= '0'; -- @ 17.
          end if;
        end if;
      end if;

      smem_rqst <= '0'; -- @ 17.
      smem_we <= '0'; -- @ 17.
      if family_vec(family_vec'high-15) = LSI_FAMILY and code_vec(0)(0) = '1' then -- level 16.
        smem_rqst <= '1'; -- @ 17.
        if code_vec(0)(3) =  '1' then -- level 16.
          smem_we <= '1'; -- @ 17.
        else
          smem_we <= '0'; -- @ 17.
        end if;
      elsif family_vec2(family_vec2'high-15) = LSI_FAMILY then
        smem_rqst <= '1';
      end if;

      --if VMRR_IMPLEMENT /= 0 and dot_res_valid_p1 /= (dot_res_valid_p1'reverse_range => '0') then
      --  smem_grant <= '0';
      --else
      --  smem_grant <= '1';
      --end if;
      smem_grant <= '1';

      mem_wrData <= rd_out_vec(0); -- @ 17.
      mem_wrData_wide <= vrd_out_vec(0); -- @ 17
      if family_vec(family_vec'high-15) = LSI_FAMILY then -- level 16
        gmem_simd <= '0';
        smem_op_type <= code_vec(0)(2 downto 0); -- @ 17.
        if code_vec(0)(1) = '1' and code_vec(0)(2) = '1' then
          smem_rd_addr <= '1' & wrAddr_fregFile_vec(wrAddr_fregFile_vec'high-16); -- @ 17.
        else
          smem_rd_addr <= "0" & wrAddr_regFile_vec(wrAddr_regFile_vec'high-16)(REG_FILE_W-1 downto WI_REG_ADDR_W)  
                & wrAddr_regFile_vec(wrAddr_regFile_vec'high-16)(WI_REG_ADDR_W-1 downto 0); -- @ 17.
        end if;

        for i in 0 to CV_SIZE-1 loop
          if code_vec(0)(0) = '1' then
            if code_vec(0)(3 downto 1) = "111" then
              --smem_addr(i) <= unsigned(res_sum(to_integer(unsigned(swc_offset_vec(0)(FREG_N_SIMD_W-1 downto FREG_N_SIMD_W-CV_W))))(GMEM_ADDR_W-1 downto CV_W+2)) & to_unsigned(i, CV_W) & "00"; -- @ 17.
              smem_addr(i) <= unsigned(res_sum(to_integer(unsigned(swc_offset_vec(0))))(GMEM_ADDR_W-1 downto FREG_N_SIMD_W+2)) & "0000000"; -- @ 17.
            else
              smem_addr(i) <= unsigned(res_sum(i)(GMEM_ADDR_W-1 downto 0)); -- @ 17.
            end if;
          end if;
        end loop;
      elsif family_vec2(family_vec2'high-15) = LSI_FAMILY then
        smem_op_type <= "001";
        smem_rd_addr <= "0" & wrAddr_regFile_vec2(wrAddr_regFile_vec2'high-16)(REG_FILE_W-1 downto 0);
        smem_rd_addr2 <= '1' & rdAddr_vec(rdAddr_vec'high-16);
        for i in 0 to CV_SIZE-1 loop
          smem_addr(i) <= unsigned(res_sum2(i)(GMEM_ADDR_W-1 downto 0)); -- @ 17.
        end loop;
      end if;

      if family_vec(family_vec'high-15) = LSI_FAMILY and code_vec(0)(0) = '0' then -- level 16
        gmem_simd <= '0';
        mem_op_type <= code_vec(0)(2 downto 0); -- @ 17.
        mem_rd_addr <= "0" & wrAddr_regFile_vec(wrAddr_regFile_vec'high-16)(REG_FILE_W-1 downto WI_REG_ADDR_W)  
              & wrAddr_regFile_vec(wrAddr_regFile_vec'high-16)(WI_REG_ADDR_W-1 downto 0); -- @ 17.
        for i in 0 to CV_SIZE-1 loop
          mem_addr(i) <= unsigned(res_low(i)(GMEM_ADDR_W-1 downto 0)); -- @ 17.
        end loop;
      elsif family_vec(family_vec'high-15) = CLS_FAMILY then
        for i in 0 to CV_SIZE-1 loop
          mem_addr(i) <= unsigned(res_sum(i)(GMEM_ADDR_W-1 downto 0)); -- @ 17.
        end loop;
        if code_vec(0)(1) = '1' then
          gmem_simd <= not code_vec(0)(3);
          mem_rd_addr <= '1' & wrAddr_fregFile_vec(wrAddr_fregFile_vec'high-16); -- @ 17.
        else
          gmem_simd <= '0';
          mem_rd_addr <= "0" & wrAddr_regFile_vec(wrAddr_regFile_vec'high-16)(REG_FILE_W-1 downto WI_REG_ADDR_W)  
                & wrAddr_regFile_vec(wrAddr_regFile_vec'high-16)(WI_REG_ADDR_W-1 downto 0); -- @ 17.
        end if;
        if code_vec(0)(2) = '1' then
          mem_op_type <= "100";
        else
          mem_op_type <= "001";
        end if;
      else -- level 16
        if code_vec(0)(2 downto 0) = "111" then
          mem_rd_addr <= '1' & wrAddr_fregFile_vec(wrAddr_fregFile_vec'high-16); -- @ 17.
          mem_op_type <= "100"; -- @ 17.
          gmem_simd <= '1';

          for i in 0 to CV_SIZE-1 loop
            if code_vec(0)(3) = '1' then
              --mem_addr(i) <= unsigned(res_sum(to_integer(unsigned(swc_offset_vec(0)(FREG_N_SIMD_W-1 downto FREG_N_SIMD_W-CV_W)))) (GMEM_ADDR_W-1 downto CV_W+2)) & "0000000"; -- @ 17.
              mem_op_type <= "111"; -- @ 17.
              mem_addr(i) <= unsigned(res_sum(to_integer(unsigned(swc_offset_vec(0))))(GMEM_ADDR_W-1 downto FREG_N_SIMD_W+2)) & "0000000"; -- @ 17.
            else
              mem_addr(i) <= unsigned(res_sum(i)(GMEM_ADDR_W-1 downto 0)); -- @ 17.
            end if;
          end loop;
        else
          mem_rd_addr <= "0" & wrAddr_regFile_vec(wrAddr_regFile_vec'high-16)(REG_FILE_W-1 downto WI_REG_ADDR_W)  
                          & wrAddr_regFile_vec(wrAddr_regFile_vec'high-16)(WI_REG_ADDR_W-1 downto 0); -- @ 17.
          mem_op_type <= code_vec(0)(2 downto 0); -- @ 17.
          gmem_simd <= '0';
          for i in 0 to CV_SIZE-1 loop
            mem_addr(i) <= unsigned(res_low(i)(GMEM_ADDR_W-1 downto 0)); -- @ 17.
          end loop;
        end if;
      end if;

      -- }}}
    end if;
  end process;
  -- }}}

  ------------------------------------------------------------------------------------------------}}}
  -- ALUs ----------------------------------------------------------------------------------------- {{{
  ALUs: for i in 0 to CV_SIZE-1 generate
  begin
    -- the calculation begins @ level 3 in the pipeline
    alu_inst: entity ALU 
    generic map( alu_idx => i)
    port map(
      rs_addr => rs_addr, --level 1.
      rt_addr => rt_addr, -- level 1.
      rd_addr => rd_addr, -- level 1.
      regBlock_re => regBlock_re, -- level 1.
      mrs_addr => mrs_addr,
      mrt_addr => mrt_addr,
      mrx_addr => (smem_regFile_wrAddr_p2(FREG_FILE_W-1 downto WI_FREG_ADDR_W) & smem_regFile_wrAddr_p2(WI_REG_ADDR_W-1 downto 0)),
      mregBlock_re => mregBlock_re,

      -- frs_addr => frs_addr, --level 1.
      -- frt_addr => frt_addr, -- level 1.
      -- frd_addr => frd_addr, -- level 1.
      --vrx_addr => smem_dot_addr_vec(0)(FREG_FILE_W-1 downto 0),
      vrx_addr => smem_dot_addr(FREG_FILE_W-1 downto 0),
      vra_addr => vra_addr,
      vrb_addr => vrb_addr,
      --csr => csr_out_vec(csr_out_vec'high-4)(i),
      vregBlock_re => vregBlock_re, -- level 1.
      vra_re => vra_re,

      family => family_vec(family_vec'high), -- level 1.

      op_arith_shift => op_arith_shift_vec(0), -- level 6.
      code => code_vec(code_vec'high-5),  -- level 6.
      immediate => immediate_vec(2), -- level 6.
      immediate2 => immediate2_vec(2)(8 downto 0), -- level 6.
      swc_offset => swc_offset_vec(swc_offset_vec'high-5)(FREG_N_SIMD_W-CV_W-1 downto 0), -- level 6.
      
      rd_out => rd_out(i), -- level 10.
      vrd_out => vrd_out(i),
      reg_we_mov => reg_we_mov_vec(reg_we_mov_vec'high)(i), -- level 10.

      float_a => float_a(i), -- level 8.
      float_b => float_b(i), -- level 8.
      float_c => float_c(i), -- level 9.

      mrs     => mrs(i),
      mrt     => mrt(i),
      mrx     => acc(i),
      vrs_out => vrs_out(i), -- level 7.
      vrt_out => vrt_out(i), -- level 8.
      --vrx_out => vrx_out(i),
      --vres_out => vres_out(i),
      --vwe     => vwe(i),
      
      op_vmem_v => op_vmem_v, -- level 7.
      op_logical_v => op_logical_v, -- level 14.
      op_activate_v => op_activate_v, -- level 14.
      res_low => res_low(i), -- level 16.
      res_high => res_high(i), -- level 16.
      res_sum => res_sum(i), -- level 16.
      res_sum2 => res_sum2(i), -- level 16.
      res_act => res_act(i), -- level 17.
      
      reg_wrData => regBlock_wrData(i), -- level 18. (level 21. for loads from lmem)
      reg_wrAddr => regBlock_wrAddr, -- level 18. (level 21. for loads from lmem)
      reg_we => regBlock_we(i), -- level 18. (level 21. for loads from lmem)

      mreg_wrData => mregBlock_wrData(i),
      mreg_wrAddr => mregBlock_wrAddr,
      mreg_we => mregBlock_we(i),

      freg_wrData => fregBlock_wrData(i),
      freg_wrAddr => fregBlock_wrAddr,
      freg_we => fregBlock_we(i),

      nrst   => nrst_i,
      clk    => clk
      );
  end generate;
  -- set register files read enables {{{
  set_register_re:process(phase(0), family, code) -- this process executes in level 0. 
  begin
    regBlock_re_n <= '0'; -- level 0.
    vregBlock_re_n <= '0'; -- level 0.
    case family is -- level 0.
      when ADD_FAMILY | MUL_FAMILY | BRA_FAMILY | SHF_FAMILY | LGK_FAMILY | CND_FAMILY | ATO_FAMILY=>
        if phase(PHASE_W-2 downto 0) = (0 to PHASE_W-2=>'0') then -- phase = 0 or 4
          regBlock_re_n <= '1';
        end if;
      when MOV_FAMILY=>
        if phase(PHASE_W-2 downto 0) = (0 to PHASE_W-2=>'0') then -- phase = 0 or 4
          regBlocK_re_n <= '1';
        end if;
      when FLT_FAMILY=>
        if phase(PHASE_W-2 downto 0) = (0 to PHASE_W-2=>'0') then -- phase = 0 or 4
          regBlock_re_n <= '1';
        end if;
      when GLS_FAMILY | LSI_FAMILY | CLS_FAMILY=>
        if phase(PHASE_W-2 downto 0) = (0 to PHASE_W-2=>'0') then -- phase = 0 or 4
          regBlock_re_n <= '1';
        end if;
        if code(3) = '1' and code(1 downto 0) = "11" and phase(0) = '0' then
          vregBlock_re_n <= '1';
        end if;
      when MCR_FAMILY=>
        --if code(2) = '1' and phase(PHASE_W-2 downto 0) = (0 to PHASE_W-2=>'0') then -- phase = 0 or 4
        --if phase(PHASE_W-2 downto 0) = (0 to PHASE_W-2=>'0') then -- phase = 0 or 4
        --  regBlock_re_n <= '1';
        --end if;
        --if code(1 downto 0) /= "00" and phase(0) = '0' then
        --  vregBlock_re_n <= '1';
        --end if;
        --if code(1 downto 0) = "10" then
        --  vra_re_n <= '1';
        --end if;
      when others =>
    end case; -- }}}
    -- set opertion type {{{
    op_arith_shift_n <= op_add; -- level 0.
    case family is -- level 0.
      when ADD_FAMILY =>
        op_arith_shift_n <= op_add;
      when MUL_FAMILY =>
        op_arith_shift_n <= op_mult;
      when GLS_FAMILY =>
        op_arith_shift_n <= op_lw;
      when LSI_FAMILY =>
        if code(0) = '0' then
          op_arith_shift_n <= op_lmem;
        else
          op_arith_shift_n <= op_smem;
        end if;
      when ATO_FAMILY =>
        op_arith_shift_n <= op_ato;
      when BRA_FAMILY =>
        op_arith_shift_n <= op_bra;
      when SHF_FAMILY =>
        op_arith_shift_n <= op_shift;
      when CND_FAMILY =>
        op_arith_shift_n <= op_slt;
      when MOV_FAMILY =>
        op_arith_shift_n <= op_mov;
      when MCR_FAMILY =>
        op_arith_shift_n <= op_mcr;
      when CLS_FAMILY =>
        op_arith_shift_n <= op_cls;
      when others =>
    end case;
  end process;

  set_register_mre:process(phase(0), family2, code2)
  begin
    mregBlock_re_n <= '0'; -- level 0
    vra_re_n <= '0';
    vregBlock_re2_n <= '0'; -- level 0.
    if family2 = MCR_FAMILY or family2 = LSI_FAMILY then
      if phase(PHASE_W-2 downto 0) = (0 to PHASE_W-2=>'0') then -- phase = 0 or 4
        mregBlock_re_n <= '1';
      end if;
    end if;
    if family2 = MCR_FAMILY then
      if code2(1 downto 0) /= "00" and phase(0) = '0' then
        vregBlock_re2_n <= '1';
      end if;
      if code2(1) = '1' then
        vra_re_n <= '1';
      end if;
    end if;
  end process;
  -- }}}
  ---------------------------------------------------------------------------------------}}}
  -- large fixed latency function units -------------------------------------------------{{{
  process(clk)
  begin
    if rising_edge(clk) then
      for i in 0 to CV_SIZE-1 loop
        if family_vec(family_vec'high-7) = MCR_FAMILY and code_vec(8) = CODE_ACT and macro_slct_vec(macro_slct_vec'high-7)(1 downto 0) = "01" then -- level 8
          sigmoid_valid_in <= rdData_alu_en_vec(rdData_alu_en_vec'high-3); -- level 9
        else
          sigmoid_valid_in <= (others=>'0');
        end if;
        if family_vec(family_vec'high-7) = MCR_FAMILY and code_vec(8) = CODE_ACT and macro_slct_vec(macro_slct_vec'high-7)(1 downto 0) = "10" then -- level 8
          tanh_valid_in <= rdData_alu_en_vec(rdData_alu_en_vec'high-3); -- level 9
        else
          tanh_valid_in <= (others=>'0');
        end if;        
      end loop;
    end if;
  end process;
  --sigmoid_gen: if SIGMOID_IMPLEMENT /= 0 generate
  --  SIGMOIDs: for i in 0 to CV_SIZE-1 generate
  --    sigmoid_inst: entity sigmoid port map(
  --      valid_a      => sigmoid_valid_in(i),
  --      a            => float_a_d0(i), -- level 9
  --      res_valid    => sig_res_valid(i),
  --      res_valid_p1 => sig_res_valid_p1(i),
  --      res          => sig_res(i),
  --      clk          => clk,
  --      rst          => not nrst_i
  --    );
  --  end generate;
  --end generate;
  --tanh_gen: if TANH_IMPLEMENT /= 0 generate
  --  TANHs: for i in 0 to CV_SIZE-1 generate
  --    tanh_inst: entity tanh port map(
  --      valid_a      => tanh_valid_in(i),
  --      a            => float_a_d0(i), -- level 9
  --      res_valid    => tanh_res_valid(i),
  --      res_valid_p1 => tanh_res_valid_p1(i),
  --      res          => tanh_res(i),
  --      clk          => clk,
  --      rst          => not nrst_i
  --    );
  --  end generate;
  --end generate;

  process (clk)
  begin
    if rising_edge(clk) then
      if (SIGMOID_IMPLEMENT = 1 and sig_res_valid_p1 /= (sig_res_valid_p1'reverse_range => '0'))
        or (TANH_IMPLEMENT = 1 and tanh_res_valid_p1 /= (tanh_res_valid_p1'reverse_range => '0')) then
        llfu_valid_p1 <= '1';
      else
        llfu_valid_p1 <= '0';
      end if;

      rreg_ready <= not llfu_valid_p1;

      if sig_res_valid /= (sig_res_valid'reverse_range => '0') or tanh_res_valid /= (tanh_res_valid'reverse_range => '0') then
        llfu_valid <= '1';
        llfu_wrAddr <= wrAddr_regFile_vec(wrAddr_regFile_vec'high-LLFU_DELAY-9); --level 28
      else
        llfu_valid <= '0';
      end if;

      if sig_res_valid /= (sig_res_valid'reverse_range => '0') then
        llfu_valid_vec <= sig_res_valid;
        for i in 0 to CV_SIZE-1 loop
          llfu_res(i) <= sig_res(i);
        end loop;
      elsif tanh_res_valid /= (tanh_res_valid'reverse_range => '0') then
        llfu_valid_vec <= tanh_res_valid;
        for i in 0 to CV_SIZE-1 loop
          llfu_res(i) <= tanh_res(i);
        end loop;
      end if;               
    end if;
  end process;
  ---------------------------------------------------------------------------------------}}}
  -- floating point ---------------------------------------------------------------------------------------{{{
  float_units_inst: if FLOAT_IMPLEMENT /= 0 generate
    float_inst: entity float_units port map(
        float_a => float_a_d0, -- level 9.
        float_b => float_b_d0, -- level 9.
        float_c => float_c, -- level 9.
        fsub => code_vec(7)(CODE_W-1), -- level 9.
        code => code_vec(1),  -- level 15.

        res_float => res_float, -- level MAX_FPU_DELAY+10. (38 if fdiv, 17 if ffma)
        rst    => not nrst_i,
        clk    => clk
    );
    process(clk)
    begin
      if rising_edge(clk) then
        float_a_d0 <= float_a;
        float_b_d0 <= float_b;
        res_float_d0 <= res_float; -- @ MAX_FPU_DELAY+11 (39 if fdiv, 22 if fadd)
        res_float_d1 <= res_float_d0; -- @ MAX_FPU_DELAY+12 (40 if fdiv, 23 if fadd)
        -- float_ce <= '0';
        -- for i in 0 to N_REG_BLOCKS-1 loop
        --   if regBlock_re_vec(1)(i) = '1' then
        --     float_ce <= '1';
        --   end if;
        -- end loop;
      end if;
    end process;
  end generate;
  ---------------------------------------------------------------------------------------------------------}}}
  -- macro unit generate ----------------------------------------------------------------------------------{{{
  macro_gen: if MCR_IMPLEMENT /= 0 generate
    mcr_inst: entity mcr_wrap generic map (cuIdx => cuIdx)
    port map(
      family          => family_vec2(family_vec2'high-7), -- level 8.
      code            => code_vec2(code_vec2'high-7), -- level 8.
      wf_indx         => to_unsigned(wf_indx_vec(wf_indx_vec'high-7), N_WF_CU_W), -- level 8.
      phase           => phase_vec(0), -- level 8.
      vrs_addr        => vrs_addr_vec(vrs_addr_vec'high-7), -- level 8
      vrd_addr        => std_logic_vector(wrAddr_regFile_vec2(wrAddr_regFile_vec2'high-8)(WI_REG_ADDR_W-1 downto 0)), -- level 8
      imm             => immediate2_vec(0), -- level 8.
      vsmem           => smem_regFile_wrData_d2, -- level 22.
      vrs             => vrs_out, -- level 7.
      vrt             => vrt_out, -- level 8.
      rx              => acc,
      rs              => mrs, -- level 8.
      rt              => mrt, -- level 8.
      valid           => dot_valid_in_d2, -- level 22.
      wrAddr_in       => std_logic_vector(smem_dot_addr_vec(smem_dot_addr_vec'high-4)), -- level 22
      res             => res_dot,
      result_valid_p1 => dot_res_valid_p1,
      result_valid    => dot_res_valid,
      vres_out        => vres_out,
      vwe             => vwe,
      vres_addr       => vres_addr,
      nrst            => nrst,
      clk             => clk
    );

    dot_valid_in <= smem_regFile_we_wide when smem_regFile_wrAddr_wide(FREG_FILE_W) = '0' else (others=>'0'); -- level 20
    process(clk)
    begin
      if rising_edge(clk) then
        smem_dot_addr_vec(smem_dot_addr_vec'high) <= smem_dot_addr(FREG_FILE_W-1 downto 0); -- @ 18
        smem_dot_addr_vec(smem_dot_addr_vec'high-1 downto 0) <= smem_dot_addr_vec(smem_dot_addr_vec'high downto 1);
        smem_regFile_wrData_d1 <= smem_regFile_wrData_wide; -- @ 21
        smem_regFile_wrData_d2 <= smem_regFile_wrData_d1; -- @ 22
        dot_wrAddr_vec(dot_wrAddr_vec'high) <= smem_regFile_wrAddr_wide;
        dot_wrAddr_vec(dot_wrAddr_vec'high-1 downto 0) <= dot_wrAddr_vec(dot_wrAddr_vec'high downto 1);
        dot_wrAddr <= dot_wrAddr_vec(0);
        --dot_wrAddr <= '0' & wrAddr_regFile_vec2(wrAddr_regFile_vec2'high-18); -- 19.
        dot_valid_in_d1 <= dot_valid_in; -- @ 21
        dot_valid_in_d2 <= dot_valid_in_d1; -- @ 22
      end if;
    end process;
  end generate;
  ---------------------------------------------------------------------------------------------------------}}}
  -- branch control ---------------------------------------------------------------------------------------{{{
  process(clk)
  begin
    if rising_edge(clk) then
      -- @ 17 {{{
      res_alu <= res_low; -- @ 17.
      branch_on_zero <= '0'; -- @ 17.
      branch_on_not_zero <= '0'; -- @ 17.
      wf_is_branching_p0 <= (others=>'0');
      if family_vec(family_vec'high-15) = BRA_FAMILY then  -- level 16.
        wf_is_branching_p0(wf_indx_vec(0)) <= '1'; -- @ 17.
        case code_vec(0) is -- level 16.
          when BEQ =>
            branch_on_zero <= '1';   -- @ 17.
          when BNE =>
            branch_on_not_zero <= '1';  -- @ 17.
          when others=>
        end case;
      end if;
      -- }}}
      -- @ 18 {{{
      wf_is_branching <= wf_is_branching_p0;          -- @ 18.
      alu_branch <= (others=>'0'); -- @ 18.
      for i in 0 to CV_SIZE-1 loop
        if res_alu(i) = (res_alu(i)'reverse_range=>'0') then    -- level 17.
          if branch_on_zero = '1' then -- level 17.
            alu_branch(i) <= '1'; -- @ 18.
          end if;
        else
          if branch_on_not_zero = '1' then  -- level 17.
            alu_branch(i) <= '1'; -- @ 18.
          end if;
        end if;
      end loop;
      -- }}}
    end if;
  end process;
  ---------------------------------------------------------------------------------------------------------}}}
  -- write back into regFiles ----------------------------------------------------------------------------------{{{
  -- register file -----------------------------------------------------------------------
  -- bits    10:9         8      7:5        4:0
  --      phase(1:0)  phase(2)  wf_indx    instr_rd_addr
  wrAddr_regFile_vec(wrAddr_regFile_vec'high)(REG_FILE_W-1 downto REG_FILE_W-2) <= phase(1 downto 0); -- level 0.
  wrAddr_regFile_vec(wrAddr_regFile_vec'high)(REG_FILE_W-3) <= phase(PHASE_W-1); -- level 0.
  wrAddr_regFile_vec(wrAddr_regFile_vec'high)(WI_REG_ADDR_W+N_WF_CU_W-1 downto WI_REG_ADDR_W) <= to_unsigned(wf_indx, N_WF_CU_W); -- level 0.
  wrAddr_regFile_vec(wrAddr_regFile_vec'high)(WI_REG_ADDR_W-1 downto 0) <= unsigned(inst_rd_addr); -- level 0.
  wrAddr_regFile_vec2(wrAddr_regFile_vec2'high)(REG_FILE_W-1 downto REG_FILE_W-2) <= phase(1 downto 0); -- level 0.
  wrAddr_regFile_vec2(wrAddr_regFile_vec2'high)(REG_FILE_W-3) <= phase(PHASE_W-1); -- level 0.
  wrAddr_regFile_vec2(wrAddr_regFile_vec2'high)(WI_REG_ADDR_W+N_WF_CU_W-1 downto WI_REG_ADDR_W) <= to_unsigned(wf_indx, N_WF_CU_W); -- level 0.
  wrAddr_regFile_vec2(wrAddr_regFile_vec2'high)(WI_REG_ADDR_W-1 downto 0) <= unsigned(minst_rd_addr); -- level 0.
  wrAddr_fregFile_vec(wrAddr_fregFile_vec'high)(FREG_FILE_W-1) <= phase(0); -- level 0.
  wrAddr_fregFile_vec(wrAddr_fregFile_vec'high)(FREG_FILE_W-2 downto FREG_FILE_W-3) <= phase(PHASE_W-1 downto PHASE_W-2); -- level 0.
  wrAddr_fregFile_vec(wrAddr_fregFile_vec'high)(WI_FREG_ADDR_W+N_WF_CU_W-1 downto WI_FREG_ADDR_W) <= to_unsigned(wf_indx, N_WF_CU_W); -- level 0.
  rdAddr_vec(rdAddr_vec'high)(FREG_FILE_W-2 downto FREG_FILE_W-3) <= phase(2 downto 1); -- level 0.
  rdAddr_vec(rdAddr_vec'high)(FREG_FILE_W-1) <= phase(0); -- level 0.
  rdAddr_vec(rdAddr_vec'high)(WI_FREG_ADDR_W+N_WF_CU_W-1 downto WI_FREG_ADDR_W) <= to_unsigned(wf_indx, N_WF_CU_W); -- level 0.  
  rdAddr_vec(rdAddr_vec'high)(WI_FREG_ADDR_W-1 downto 0) <= unsigned(minst_rs_addr); -- level 0.

  fpu_wb_addr: process(family, code, fmem_rd_addr, finst_rd_addr, finst_rs_addr, family2, code2, minst_rs_addr, minst_rd_addr)
  begin
    --if (family = GLS_FAMILY or family = LSI_FAMILY) and code(2 downto 0) = "111" then
      wrAddr_fregFile_vec(wrAddr_fregFile_vec'high)(WI_FREG_ADDR_W-1 downto 0) <= unsigned(fmem_rd_addr); -- level 0.
    --end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      for i in 0 to CV_SIZE-1 loop
        for j in 0 to N_REG_BLOCKS-1 loop
          -- mregBlock_wrData {{{
          if dot_res_valid /= (dot_res_valid'reverse_range => '0') and
                dot_wrAddr(FREG_FILE_W-1 downto REG_FILE_BLOCK_W) = to_unsigned(j, N_REG_BLOCKS_W) then
            mregBlock_wrData(i)(j) <= res_dot(i);
          end if;
          -- }}}
          -- mregBlock_we {{{
          if dot_res_valid /= (dot_res_valid'reverse_range => '0') and 
                dot_wrAddr(FREG_FILE_W-1 downto REG_FILE_BLOCK_W) = to_unsigned(j, N_REG_BLOCKS_W) then
            mregBlock_we(i)(j) <= dot_res_valid(i);
          else
            mregBlock_we(i)(j) <= '0';
          end if;
          -- }}}
        end loop;
      end loop;
      -- mregBlock_wrAddr {{{
      for j in 0 to N_REG_BLOCKS-1 loop
        if dot_res_valid /= (dot_res_valid'reverse_range => '0') and 
              dot_wrAddr(FREG_FILE_W-1 downto REG_FILE_BLOCK_W) = to_unsigned(j, N_REG_BLOCKS_W) then
          mregBlock_wrAddr(j) <= dot_wrAddr(REG_FILE_BLOCK_W-1 downto 0);
        end if;
      end loop;
      -- }}}
    end if;
  end process;

  write_alu_res_back: process(family_vec(family_vec'high-15), rdData_alu_en_vec(rdData_alu_en_vec'high-11), reg_we_mov_vec(0), code_vec(0))
  begin
    reg_we_alu_n <= (others=>'0'); -- level 16.
    case family_vec(family_vec'high-15) is -- level 16.
      when RTM_FAMILY | ADD_FAMILY | MUL_FAMILY | SHF_FAMILY | LGK_FAMILY | CND_FAMILY | FLT_FAMILY =>
        reg_we_alu_n <= rdData_alu_en_vec(rdData_alu_en_vec'high-11); -- level 16.
      when MOV_FAMILY =>
        reg_we_alu_n <= rdData_alu_en_vec(rdData_alu_en_vec'high-11) and reg_we_mov_vec(0); -- level 16.
      when MCR_FAMILY =>
        --if code_vec(0)(3) = '0' and code_vec(0)(2 downto 0) /= "000" then
        --  reg_we_alu_n <= rdData_alu_en_vec(rdData_alu_en_vec'high-11); -- level 16.
        --end if;
      when others=>
    end case;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      wrAddr_regFile_vec(wrAddr_regFile_vec'high-1 downto 0) <= wrAddr_regFile_vec(wrAddr_regFile_vec'high downto 1); -- @ 1.->MAX_FPU_DELAY+12.
      wrAddr_regFile_vec2(wrAddr_regFile_vec2'high-1 downto 0) <= wrAddr_regFile_vec2(wrAddr_regFile_vec2'high downto 1); -- @ 1.->MAX_FPU_DELAY+12.
      wrAddr_fregFile_vec(wrAddr_fregFile_vec'high-1 downto 0) <= wrAddr_fregFile_vec(wrAddr_fregFile_vec'high downto 1); -- @ 1.->MAX_FPU_DELAY+12.
      rdAddr_vec(rdAddr_vec'high-1 downto 0) <= rdAddr_vec(rdAddr_vec'high downto 1); -- @ 1.->MAX_FPU_DELAY+12.
      reg_we_mov_vec(reg_we_mov_vec'high-1 downto 0) <= reg_we_mov_vec(reg_we_mov_vec'high downto 1); -- @ 11.->16.
      lmem_regFile_we <= lmem_regFile_we_p0;
      
      reg_we_alu <= reg_we_alu_n; -- @ 17.
      reg_we_float <= (others=>'0'); -- @ 23.
      case MAX_FPU_DELAY is
        when FDIV_DELAY => -- fsqrt of fdiv has the maximum delay
          if family_vec(1) = FLT_FAMILY then -- level 38. if fdiv
            reg_we_float <= rdData_alu_en_vec(1); -- @ 39. if fdiv
          end if;
        when others => -- ffma has the maximum delay
          if family_vec(2) = FLT_FAMILY then -- level 16. if ffma
            reg_we_float <= rdData_alu_en_vec(2); -- @ 17. if ffma
          end if;
      end case;
      wrData_alu <= (others=>(others=>'0')); -- @ 17.
      case family_vec_at_16 is -- level 16.
        when RTM_FAMILY =>
          if rtm_rdData_nlid_vec(0) = '0' then -- level 16.
            for i in 0 to CV_SIZE-1 loop
              wrData_alu(i)(WG_SIZE_W-1 downto 0) <=  std_logic_vector(rtm_rdData_d0((i+1)*WG_SIZE_W-1 downto i*WG_SIZE_W)); -- @ 17.
            end loop;
          else
            for i in 0 to CV_SIZE-1 loop
              wrData_alu(i) <= std_logic_vector(rtm_rdData_d0(DATA_W-1 downto 0)); -- @ 17.
            end loop;
          end if;
        when ADD_FAMILY | MUL_FAMILY | CND_FAMILY | MOV_FAMILY | MCR_FAMILY =>
          wrData_alu <= res_low; -- @ 17.
        when SHF_FAMILY =>
          if code_vec(0)(CODE_W-1) = '0' then  -- level 16.
            wrData_alu <= res_low; -- @ 17.
          else
            wrData_alu <= res_high;
          end if;
        when LGK_FAMILY =>
          wrData_alu <= res_low; -- @ 17.
        when GLS_FAMILY =>
        when others =>
      end case;

      regBlock_we_alu <= (others=>'0'); -- @ 17.
      regBlock_we_alu(to_integer(wrAddr_regFile_vec(wrAddr_regFile_vec'high-16)(REG_FILE_W-1 downto REG_FILE_BLOCK_W))) <= '1'; -- @ 17.+N_REG_BLOCKS*i
      --fregBlock_we_alu <= (others=>'0'); -- @ 17.
      --fregBlock_we_alu(to_integer(wrAddr_fregFile_vec2(wrAddr_fregFile_vec2'high-MCR_DELAY+1)(FREG_FILE_W-1 downto FREG_FILE_BLOCK_W))) <= '1'; -- @ 17.+N_REG_BLOCKS*i
      -- regBlock_we_float {{{
      -- case MAX_FPU_DELAY is
      --   when FDIV_DELAY => -- fsqrt of fdiv has the maximum delay
      --     regBlock_we_float_vec(regBlock_we_float_vec'high) <= fregBlock_we_alu; -- @ 18.+N_REG_BLOCKS*i
      --     regBlock_we_float_vec(regBlock_we_float_vec'high-1 downto 0) <= 
      --                   regBlock_we_float_vec(regBlock_we_float_vec'high downto 1); -- @ 19.->19+MAX_FPU_DELAY-7-1 (39. if fdiv, 22. if fadd)
      --     regBlock_we_float <= regBlock_we_float_vec(1); -- @ MAX_FPU_DELAY+11 (39. if fadd)
      --   when others => -- ffma has the maximum delay
      --     -- regBlock_we_float <= regBlock_we_float_vec(0); -- @ MAX_FPU_DELAY+12 (18. if ffma)
      -- end case;
      -- }}}
      -- the register block that will be written from global and local memory reads will be selected {{{
      --if LMEM_IMPLEMENT = 0 or lmem_regFile_we_p0 = '0' then 
        -- if no read of lmem content is comming, prepare the we of the register block according to the current address sent from CU_mem_cntrl
      regBlock_we_mem <= (others=>'0'); -- stage 0
      if mem_regFile_wrAddr(FREG_FILE_W) = '0' then
        for i in 0 to N_REG_BLOCKS/2-1 loop
          regBlock_we_mem(2*to_integer(mem_regFile_wrAddr(FREG_FILE_W-1 downto FREG_FILE_W-1))) <= '1'; -- (@ 22. for lmem reads)
          regBlock_we_mem(2*to_integer(mem_regFile_wrAddr(FREG_FILE_W-1 downto FREG_FILE_W-1))+1) <= '1'; -- (@ 22. for lmem reads)
        end loop;
      end if;
      --elsif lmem_regFile_we = '0' or regBlock_we_mem(N_REG_BLOCKS-1) = '1' then 
      --  -- there will be a read from lmem or a half of the read data burst is over. Set the we of the first register block!
      --  regBlock_we_mem(N_REG_BLOCKS-1 downto 1) <= (others=>'0'); -- stage 0
      --  regBlock_we_mem(0) <= '1';
      --else -- lmem is being read. Shift left for regBlock_we_mem!
      --  regBlock_we_mem(N_REG_BLOCKS-1 downto 1) <= regBlock_we_mem(N_REG_BLOCKS-2 downto 0);
      --  regBlock_we_mem(0) <= '0';
      --end if;
      fregBlock_we_mem <= (others=>'0'); -- stage 0
      if mem_regFile_wrAddr_d0(FREG_FILE_W) = '1' then
        --fregBlock_we_mem(to_integer(mem_regFile_wrAddr_d0(FREG_FILE_W-1 downto FREG_FILE_BLOCK_W))) <= '1';
        fregBlock_we_mem <= (others=>'1');
      end if;
      mem_regFile_wrAddr_d0 <= mem_regFile_wrAddr; -- stage 1
      mem_regFile_wrAddr_d1 <= mem_regFile_wrAddr_d0(REG_FILE_W-1 downto 0); -- stage 2
      mem_regFile_we_d0 <= mem_regFile_we;
      -- }}}
      -- regBlock_wrAddr {{{
      for j in 0 to N_REG_BLOCKS-1 loop
        if regBlock_we_alu(j) = '1' then -- level 17.+j
          regBlock_wrAddr(j) <= wrAddr_regFile_vec(wrAddr_regFile_vec'high-17)(REG_FILE_BLOCK_W-1 downto 0); -- @ 18.+j
        elsif LLFU_IMPLEMENT = 1 and llfu_valid = '1' and llfu_wrAddr(FREG_FILE_W-1 downto REG_FILE_BLOCK_W) = to_unsigned(j, N_REG_BLOCKS_W) then
          regBlock_wrAddr(j) <= llfu_wrAddr(REG_FILE_BLOCK_W-1 downto 0);
        elsif smem_regFile_wv = '1' and smem_regFile_wrAddr(FREG_FILE_W) = '0' and
              smem_regFile_wrAddr(FREG_FILE_W-1 downto REG_FILE_BLOCK_W) = to_unsigned(j, N_REG_BLOCKS_W) then
          regBlock_wrAddr(j) <= smem_regFile_wrAddr(REG_FILE_BLOCK_W-1 downto 0);
        else
          regBlock_wrAddr(j) <= mem_regFile_wrAddr_d0(REG_FILE_BLOCK_W-1 downto 0); -- stage 1. or 2.
        end if;
      end loop;
      -- }}}
      -- fregBlock_wrAddr {{{
      for j in 0 to N_FREG_BLOCKS-1 loop
        if FLOAT_IMPLEMENT /= 0 then
          if vres_addr(FREG_FILE_W-1 downto FREG_FILE_W-1) = to_unsigned(j, 1) then
            fregBlock_wrAddr(j) <= vres_addr(FREG_FILE_BLOCK_W-1 downto 0);
          --if fregBlock_we_alu(j) = '1' then -- level 17.+j
            --fregBlock_wrAddr(j) <= wrAddr_fregFile_vec2(wrAddr_fregFile_vec2'high-MCR_DELAY)(FREG_FILE_BLOCK_W-1 downto 0); -- @ 18.+j if ffma
          --elsif smem_regFile_we_wide /= (0 to CV_SIZE-1=>'0') and smem_regFile_wrAddr_wide(FREG_FILE_W) = '1' and
          --      smem_regFile_wrAddr_wide(FREG_FILE_W-1 downto FREG_FILE_BLOCK_W) = to_unsigned(j, N_REG_BLOCKS_W) then
          --  fregBlock_wrAddr(j) <= smem_regFile_wrAddr_wide(FREG_FILE_BLOCK_W-1 downto 0);
          else
            fregBlock_wrAddr(j) <= mem_regFile_wrAddr_d0(FREG_FILE_BLOCK_W-1 downto 0); -- stage 1. or 2.
          end if;
        end if;
      end loop;
      -- }}}
      for i in 0 to CV_SIZE-1 loop
        for j in 0 to N_REG_BLOCKS-1 loop
          -- regBlock_wrData {{{
          if regBlock_we_alu(j) = '1' then -- level 17.
            -- write by alu operations
            if family_vec(family_vec'high-16) = FLT_FAMILY then
              regBlock_wrData(i)(j) <= res_float(i);
            else
              regBlock_wrData(i)(j) <= wrData_alu(i); -- @ 18.
            end if;
          elsif LLFU_IMPLEMENT = 1 and llfu_valid = '1' and llfu_wrAddr(FREG_FILE_W-1 downto REG_FILE_BLOCK_W) = to_unsigned(j, N_REG_BLOCKS_W) then
            regBlock_wrData(i)(j) <= llfu_res(i);
          elsif smem_regFile_wv = '1' and smem_regFile_wrAddr(FREG_FILE_W) = '0' and
                smem_regFile_wrAddr(FREG_FILE_W-1 downto REG_FILE_BLOCK_W) = to_unsigned(j, N_REG_BLOCKS_W) then
            regBlock_wrData(i)(j) <= smem_regFile_wrData(i)(DATA_W-1 downto 0);
          else
            -- write by memory reads
            if (j mod 2) = 0 then
              regBlock_wrData(i)(j) <= mem_regFile_wrData(i); -- @ 1. or 2.
            else
              regBlock_wrData(i)(j) <= mem_regFile_wrData(i+CV_SIZE);
            end if;
          end if;

          -- regBlock_we {{{
          if regBlock_we_alu(j) = '1' then -- level 17.+j
            regBlock_we(i)(j) <= reg_we_alu(i); -- @ 18.+j
          elsif LLFU_IMPLEMENT = 1 and llfu_valid = '1' and llfu_wrAddr(FREG_FILE_W-1 downto REG_FILE_BLOCK_W) = to_unsigned(j, N_REG_BLOCKS_W) then
            regBlock_we(i)(j) <= llfu_valid_vec(i);
          elsif smem_regFile_wv = '1' and
                smem_regFile_wrAddr(FREG_FILE_W-1 downto REG_FILE_BLOCK_W) = to_unsigned(j, N_REG_BLOCKS_W) then
            regBlock_we(i)(j) <= smem_regFile_we(i);
          elsif regBlock_we_mem(j) = '1' then -- (level 22 for lmem reads; no conflict with 17+N_REG_BLOCKS*i)
            if (j mod 2) = 0 then
              regBlock_we(i)(j) <= mem_regFile_we(i); -- @ 1. or 2. (@23. for loads from lmem)
            else
              regBlock_we(i)(j) <= mem_regFile_we(i+CV_SIZE); -- @ 1. or 2. (@23. for loads from lmem)
            end if;
          else
            regBlock_we(i)(j) <= '0';
          end if;
          -- }}}
        end loop;
          -- }}}
        for j in 0 to N_FREG_BLOCKS-1 loop
          -- fregBlock_wrData {{{
          if FLOAT_IMPLEMENT /= 0 then -- level 23. if fadd, 39. if fdiv
            -- write by floating point units
            if vres_addr(FREG_FILE_W-1 downto FREG_FILE_W-1) = to_unsigned(j, 1) then
              fregBlock_wrData(i)(j) <= vres_out(i); -- @ 18.+j
            --elsif smem_regFile_we_wide /= (0 to CV_SIZE-1=>'0') and smem_regFile_wrAddr_wide(FREG_FILE_W) = '1' and
            --      smem_regFile_wrAddr_wide(FREG_FILE_W-1 downto FREG_FILE_BLOCK_W) = to_unsigned(j, N_REG_BLOCKS_W) then
            --  fregBlock_wrData(i)(j) <= smem_regFile_wrData_wide;
            else
              -- write by memory reads
              fregBlock_wrData(i)(j) <= mem_regFile_wrData_wide; -- @ 1. or 2.
            end if;
          end if;
          -- }}}
          -- fregBlock_we {{{
          if FLOAT_IMPLEMENT /= 0 then
            -- if (MAX_FPU_DELAY /= FDIV_DELAY and fregBlock_we_alu(j) = '1') or regBlock_we_float(j) = '1' then -- level 17.+j if ffma, 39.+j uf fdiv
            --   fregBlock_we(i)(j) <= reg_we_float(i); -- @ 18.+j if ffma, 40.+j if fdiv
            if vres_addr(FREG_FILE_W-1 downto FREG_FILE_W-1) = to_unsigned(j, 1) and rdData_alu_en_vec(rdData_alu_en_vec'high-MCR_DELAY+5)(i) = '1' then
              fregBlock_we(i)(j) <= vwe(i);
            --elsif smem_regFile_we_wide /= (0 to CV_SIZE-1=>'0') and smem_regFile_wrAddr_wide(FREG_FILE_W) = '1' and
            --      smem_regFile_wrAddr_wide(FREG_FILE_W-1 downto FREG_FILE_BLOCK_W) = to_unsigned(j, N_REG_BLOCKS_W) and
            --      smem_regFile_we_wide(i) = '1' then
            --  fregBlock_we(i)(j) <= (others => '1');
            else
              if j = 0 then
                if mem_regFile_we(i) = '1' then
                  fregBlock_we(i)(j) <= (others=>'1'); -- @ 1. or 2. (@23. for loads from lmem)
                else
                  fregBlock_we(i)(j) <= (others=>'0'); -- @ 1. or 2. (@23. for loads from lmem)
                end if;
              else
                if mem_regFile_we(i+CV_SIZE) = '1' then
                  fregBlock_we(i)(j) <= (others=>'1'); -- @ 1. or 2. (@23. for loads from lmem)
                else
                  fregBlock_we(i)(j) <= (others=>'0'); -- @ 1. or 2. (@23. for loads from lmem)
                end if;
              end if;
            --else
            --  fregBlock_we(i)(j) <= (others => '0');
            end if;
          end if;
          -- }}}
        end loop;
      end loop;
    end if;
  end process;
  ---------------------------------------------------------------------------------------------------------}}}
end Behavioral;

