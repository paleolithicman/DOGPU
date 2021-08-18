-- libraries -------------------------------------------------------------------------------------------{{{
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.all;
use work.FGPU_definitions.all;
---------------------------------------------------------------------------------------------------------}}}
entity compute_unit is
generic (cu_idx : integer range 0 to CV_SIZE-1);
-- ports {{{
port(
  clk                 : in std_logic;

  cram_rdAddr         : out unsigned(CRAM_ADDR_W-1 downto 0) := (others=>'0');
  cram_rdAddr_conf    : in unsigned(CRAM_ADDR_W-1 downto 0) := (others=>'0');
  cram_rdData         : in std_logic_vector(2*DATA_W-1 downto 0);
  cram_rqst           : out std_logic := '0';
  start_addr          : in unsigned(CRAM_ADDR_W-1 downto 0) := (others=>'0');

  sch_rqst_n_wfs_m1   : in unsigned(N_WF_CU_W-1 downto 0);
  wg_info             : in unsigned(DATA_W-1 downto 0); 
  sch_rqst            : in std_logic;
  gsync_reached       : in std_logic;
  
  wf_active           : out std_logic_vector(N_WF_CU-1 downto 0) := (others => '0'); -- active WFs in the CU
  wf_reach_gsync      : out std_logic;
  sch_ack             : out std_logic := '0';
  start_CUs           : in std_logic := '0';
  WGsDispatched       : in std_logic := '0';
  rtm_wrAddr_wg       : in unsigned(RTM_ADDR_W-1 downto 0) := (others => '0');
  rtm_wrData_wg       : in unsigned(RTM_DATA_W-1 downto 0) := (others => '0');
  rtm_we_wg           : in std_logic := '0';
  rdData_alu_en       : in std_logic_vector(CV_SIZE-1 downto 0) := (others=>'0');
  rdAddr_alu_en       : out unsigned(N_WF_CU_W+PHASE_W-1 downto 0) := (others=>'0');

  cache_rdData        : in std_logic_vector(CACHE_N_BANKS*DATA_W-1 downto 0) := (others=>'0');
  cache_rdAck         : in std_logic := '0';
  cache_rdAddr        : in unsigned(GMEM_WORD_ADDR_W-CACHE_N_BANKS_W-1 downto 0) := (others=>'0');
  cache_rdCntrl       : in unsigned(N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  atomic_rdData       : in std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  atomic_rdData_v     : in std_logic := '0';
  atomic_sgntr        : in std_logic_vector(N_CU_STATIONS_W-1 downto 0) := (others=>'0');

  gmem_wrData         : out std_logic_vector(GMEM_WRFIFO_W-1 downto 0) := (others=>'0');
  gmem_valid          : out std_logic := '0';
  gmem_rnw            : out std_logic := '0';
  gmem_op_type        : out std_logic_vector(2 downto 0) := (others=>'0');
  gmem_atomic         : out std_logic := '0';
  gmem_atomic_sgntr   : out std_logic_vector(N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  gmem_rqst_addr      : out std_logic_vector(GMEM_WORD_ADDR_W-CACHE_N_BANKS_W-1 downto 0) := (others=>'0');
  gmem_rqst_cntrl     : out unsigned(N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  gmem_ready          : in std_logic := '0';

  gmem_cntrl_idle     : out std_logic := '0';

  debug_st            : out std_logic_vector(127 downto 0) := (others=>'0');

  nrst                : in std_logic
);
-- ports }}}
end compute_unit;
architecture Behavioral of compute_unit is
  -- signals definitions {{{
  signal nrst_scheduler                   : std_logic := '0';
  signal nrst_mem_cntrl                   : std_logic := '0';
  signal nrst_rtm                         : std_logic := '0';
  signal nrst_smem                        : std_logic := '0';
  signal nrst_cv                          : std_logic := '0';
  signal rtm_wrAddr_cv                    : unsigned(N_WF_CU_W+2-1 downto 0) := (others => '0');
  signal rtm_wrData_cv                    : unsigned(DATA_W-1 downto 0) := (others => '0'); 
  signal rtm_we_cv                        : std_logic := '0';
  
  signal rtm_rdAddr                       : unsigned(RTM_ADDR_W-1 downto 0) := (others => '0');
  signal rtm_rdData                       : unsigned(RTM_DATA_W-1 downto 0) := (others => '0');

  signal instr, instr_out                 : std_logic_vector(DATA_W-1 downto 0) := (others => '0');
  signal instr_macro, instr_macro_out     : std_logic_vector(DATA_W-1 downto 0) := (others => '0');
  signal wf_indx_in_wg, wf_indx           : natural range 0 to N_WF_CU-1;
  signal wf_indx_in_wg_out, wf_indx_out   : natural range 0 to N_WF_CU-1;
  signal phase, phase_out                 : unsigned(PHASE_W-1 downto 0) := (others=>'0');
  signal swc_phase                        : std_logic_vector(CV_W-1 downto 0);

  signal alu_branch                       : std_logic_vector(CV_SIZE-1 downto 0) := (others=>'0'); 
  signal wf_is_branching                  : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal alu_en_divStack                  : std_logic_vector(CV_SIZE-1 downto 0) := (others=>'0');
  
  signal cv_gmem_re, cv_gmem_we           : std_logic := '0';
  signal cv_gmem_atomic                   : std_logic := '0';
  signal cv_mem_wrData                    : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal cv_mem_wrData_wide               : std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0);
  signal cv_op_type                       : std_logic_vector(2 downto 0) := (others=>'0');
  signal cv_smem_op_type                  : std_logic_vector(2 downto 0) := (others=>'0');
  signal cv_lmem_rqst, cv_lmem_we         : std_logic := '0';
  signal cv_smem_rqst, cv_smem_we         : std_logic := '0';
  signal cv_gmem_simd                     : std_logic := '0';
  signal rreg_ready                       : std_logic := '0';
  signal vreg_ready                       : std_logic := '0';
  signal vreg_re_busy                     : std_logic := '0';

  signal cv_mem_addr                      : GMEM_ADDR_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal cv_smem_addr                     : GMEM_ADDR_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal alu_en, alu_en_d0                : std_logic_vector(CV_SIZE-1 downto 0) := (others=>'0');
  signal alu_en_pri_enc                   : integer range 0 to CV_SIZE-1 := 0;
  signal cv_mem_rd_addr                   : unsigned(FREG_FILE_W downto 0) := (others=>'0');
  signal cv_smem_rd_addr                  : unsigned(FREG_FILE_W downto 0) := (others=>'0');
  signal cv_smem_addr2                    : unsigned(FREG_FILE_W downto 0) := (others=>'0');
  signal smem_dot_addr                    : unsigned(FREG_FILE_W downto 0) := (others=>'0');
  signal regFile_wrAddr                   : unsigned(FREG_FILE_W downto 0) := (others=>'0');  
  signal regFile_wrData                   : SLV32_ARRAY(2*CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal regFile_wrData_wide              : std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'0');
  signal regFile_we                       : std_logic_vector(2*CV_SIZE-1 downto 0) := (others=>'0');
  signal regFile_we_lmem_p0               : std_logic := '0';

  signal smem_regFile_wrAddr              : unsigned(FREG_FILE_W downto 0);
  signal smem_regFile_wrAddr_p2           : unsigned(FREG_FILE_W downto 0);
  signal smem_regFile_wrAddr_wide         : unsigned(FREG_FILE_W downto 0);
  signal smem_regFile_wv                  : std_logic := '0';
  signal smem_regFile_wv_wide_p1          : std_logic := '0';
  signal smem_regFile_we                  : std_logic_vector(CV_SIZE-1 downto 0);
  signal smem_regFile_wrData              : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal smem_regFile_we_wide             : std_logic_vector(CV_SIZE-1 downto 0);
  signal smem_regFile_wrData_wide         : std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'0');
  signal smem_grant                       : std_logic := '0';

  signal gmem_finish                      : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal gmem_finish_rd                   : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal gmem_rdAddr                      : wi_vreg_addr_array(N_WF_CU-1 downto 0) := (others=>(others=>'0'));
  signal gmem_alm_full                    : std_logic := '0';
  signal smem_finish                      : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  attribute max_fanout of phase : signal is 10;
  attribute max_fanout of wf_indx : signal is 10;
  -- }}}  
  signal debug_st_i                       : std_logic_vector(127 downto 0);
  signal debug_resume_i                   : std_logic;
  signal debug_start_i                    : std_logic;
begin
  -- RTM -------------------------------------------------------------------------------------- {{{
  RTM_inst: entity RTM port map(
    clk => clk,
    rtm_rdAddr => rtm_rdAddr,
    rtm_rdData => rtm_rdData,
    rtm_wrData_cv => rtm_wrData_cv,
    rtm_wrAddr_cv => rtm_wrAddr_cv,
    rtm_we_cv => rtm_we_cv,
    rtm_wrAddr_wg => rtm_wrAddr_wg,
    rtm_wrData_wg => rtm_wrData_wg,
    rtm_we_wg => rtm_we_wg,
    WGsDispatched => WGsDispatched,
    start_CUs => start_CUs,
    nrst => nrst_rtm
  );
  ------------------------------------------------------------------------------------------------}}}
  -- CU WF Scheduler -----------------------------------------------------------------------------------{{{
  CUS_inst: entity CU_scheduler
  port map(
    clk               => clk,
    wf_active         => wf_active,
    wf_reach_gsync    => wf_reach_gsync,
    sch_ack           => sch_ack,
    sch_rqst          => sch_rqst,
    sch_rqst_n_wfs_m1 => sch_rqst_n_wfs_m1,
    nrst              => nrst_scheduler,
    cram_rdAddr       => cram_rdAddr,      
    cram_rdData       => cram_rdData,
    cram_rqst         => cram_rqst,
    cram_rdAddr_conf  => cram_rdAddr_conf,
    start_addr        => start_addr,
    wg_info           => wg_info,
    gsync_reached     => gsync_reached,
    rtm_wrAddr_cv     => rtm_wrAddr_cv,
    rtm_wrData_cv     => rtm_wrData_cv,
    rtm_we_cv         => rtm_we_cv,

    alu_branch        => alu_branch,  -- level 10
    wf_is_branching   => wf_is_branching, -- level 10
    alu_en            => alu_en_d0, -- level 10
    
    gmem_finish       => gmem_finish,
    gmem_finish_rd    => gmem_finish_rd,
    gmem_rdAddr       => gmem_rdAddr,
    gmem_alm_full     => gmem_alm_full,
    smem_finish       => smem_finish,

    instr             => instr_out,
    instr_macro       => instr_macro_out,
    swc_phase         => swc_phase,
    wf_indx_in_wg     => wf_indx_in_wg_out,
    wf_indx_in_CU     => wf_indx_out,
    alu_en_divStack   => alu_en_divStack,
    phase             => phase_out
  );
  instr_slice_true: if INSTR_READ_SLICE generate
    process(clk)
    begin
      if rising_edge(clk) then
        nrst_scheduler <= nrst;
        nrst_mem_cntrl <= nrst;
        nrst_rtm <= nrst;
        nrst_smem <= nrst;
        nrst_cv <= nrst;
        instr <= instr_out;
        instr_macro <= instr_macro_out;
        wf_indx_in_wg <= wf_indx_in_wg_out;
        wf_indx <= wf_indx_out;
        phase <= phase_out;
        alu_en_d0 <= alu_en;
        debug_st <= debug_st_i;
      end if;
    end process;
  end generate;
  instr_slice_false: if not INSTR_READ_SLICE generate
    instr <= instr_out;
    instr_macro <= instr_macro_out;
    wf_indx_in_wg <= wf_indx_in_wg_out;
    wf_indx <= wf_indx_out;
    phase <= phase_out;
  end generate;

  ------------------------------------------------------------------------------------------------}}}
  -- CV --------------------------------------------------------------------------------------{{{
  CV_inst: entity CV port map(
    clk               => clk,
    nrst              => nrst_cv,
    instr             => instr,
    instr_macro       => instr_macro,
    swc_phase         => swc_phase,
    rdData_alu_en     => rdData_alu_en,
    rdAddr_alu_en     => rdAddr_alu_en,
    rtm_rdAddr        => rtm_rdAddr, -- level 13.
    rtm_rdData        => rtm_rdData, -- level 15.
    wf_indx           => wf_indx,
    wf_indx_in_wg     => wf_indx_in_wg,
    phase             => phase,
    alu_en            => alu_en,
    alu_en_pri_enc    => alu_en_pri_enc,
    alu_en_divStack   => alu_en_divStack,

    -- branch
    alu_branch        => alu_branch,
    wf_is_branching   => wf_is_branching,
    
    gmem_re           => cv_gmem_re,
    gmem_atomic       => cv_gmem_atomic,
    gmem_simd         => cv_gmem_simd,
    gmem_we           => cv_gmem_we,
    mem_op_type       => cv_op_type,
    mem_addr          => cv_mem_addr,
    mem_rd_addr       => cv_mem_rd_addr,
    mem_wrData        => cv_mem_wrData,
    mem_wrData_wide   => cv_mem_wrData_wide,
    lmem_rqst         => cv_lmem_rqst,
    lmem_we           => cv_lmem_we,
    smem_rqst         => cv_smem_rqst,
    smem_we           => cv_smem_we,
    smem_addr         => cv_smem_addr,
    smem_op_type      => cv_smem_op_type,
    smem_rd_addr      => cv_smem_rd_addr,
    smem_rd_addr2     => cv_smem_addr2,
    smem_grant        => smem_grant,
    rreg_ready        => rreg_ready,
    vreg_ready        => vreg_ready,
    vreg_re_busy      => vreg_re_busy,

    mem_regFile_wrAddr => regFile_wrAddr,
    mem_regFile_wrData => regFile_wrData,
    mem_regFile_wrData_wide => regFile_wrData_wide,
    lmem_regFile_we_p0 => regFile_we_lmem_p0,
    mem_regFile_we    => regFile_we,

    smem_regFile_wrAddr_p2  => smem_regFile_wrAddr_p2,
    smem_regFile_wrAddr  => smem_regFile_wrAddr,
    smem_regFile_wv      => smem_regFile_wv,
    smem_regFile_we      => smem_regFile_we,
    smem_regFile_wrData  => smem_regFile_wrData,
    smem_regFile_wrAddr_wide  => smem_regFile_wrAddr_wide,
    smem_regFile_we_wide      => smem_regFile_we_wide,
    smem_regFile_wv_wide_p1   => smem_regFile_wv_wide_p1,
    smem_regFile_wrData_wide => smem_regFile_wrData_wide,
    smem_dot_addr        => smem_dot_addr
  );
  ------------------------------------------------------------------------------------------------}}}
  -- shared mem ----------------------------------------------------------------------------------{{{
  shared_mem_inst: entity smem
  port map(
    clk               => clk,
    rqst              => cv_smem_rqst,
    we                => cv_smem_we,
    cv_alu_en         => alu_en,
    cv_op_type        => cv_smem_op_type,
    wrData            => cv_mem_wrData_wide,
    regFile_wrAddr    => smem_regFile_wrAddr,
    regFile_we        => smem_regFile_we,
    regFile_wrData    => smem_regFile_wrData,
    regFile_wrAddr_wide => smem_regFile_wrAddr_wide,
    regFile_we_wide     => smem_regFile_we_wide,
    regFile_wv_wide_p1  => smem_regFile_wv_wide_p1,
    regFile_wrData_wide => smem_regFile_wrData_wide,
    regFile_wv        => smem_regFile_wv,
    cv_rsp_granted    => smem_grant,
    cv_addr           => cv_smem_addr,
    rd_addr           => cv_smem_rd_addr,
    wf_finish         => smem_finish,
    nrst              => nrst_smem,

    rd_addr2          => cv_smem_addr2,
    dot_addr          => smem_dot_addr,
    regFile_wrAddr_p2 => smem_regFile_wrAddr_p2,
    vreg_busy         => vreg_re_busy,

    debug_st => debug_st_i
  );

  ------------------------------------------------------------------------------------------------}}}
  -- CU mem controller -----------------------------------------------------------------{{{
  CU_mem_cntrl_inst: entity CU_mem_cntrl 
  generic map(
    cu_idx            => cu_idx)
  port map(
    clk               => clk,
    
    cache_rdData      => cache_rdData,
    cache_rdAddr      => cache_rdAddr,
    cache_rdAck       => cache_rdAck,
    cache_rdCntrl     => cache_rdCntrl,
    atomic_rdData     => atomic_rdData,
    atomic_rdData_v   => atomic_rdData_v,
    atomic_sgntr      => atomic_sgntr,

    cv_wrData         => cv_mem_wrData,
    cv_wrData_wide    => cv_mem_wrData_wide,
    cv_addr           => cv_mem_addr,
    cv_gmem_we        => cv_gmem_we,
    cv_gmem_re        => cv_gmem_re,
    cv_gmem_atomic    => cv_gmem_atomic,
    cv_lmem_rqst      => cv_lmem_rqst,
    cv_lmem_we        => cv_lmem_we,
    cv_op_type        => cv_op_type,
    cv_alu_en         => alu_en,
    cv_alu_en_pri_enc => alu_en_pri_enc,
    cv_rd_addr        => cv_mem_rd_addr,
    cv_gmem_simd      => cv_gmem_simd,
    rreg_ready        => rreg_ready,
    vreg_ready        => vreg_ready,
    cv_gsync_reached  => wf_reach_gsync,
    gmem_wrData       => gmem_wrData,
    gmem_valid        => gmem_valid,
    gmem_ready        => gmem_ready,
    gmem_atomic       => gmem_atomic,
    gmem_atomic_sgntr => gmem_atomic_sgntr,
    gmem_rnw          => gmem_rnw,
    gmem_op_type      => gmem_op_type,
    gmem_rqst_addr    => gmem_rqst_addr,
    gmem_rqst_cntrl   => gmem_rqst_cntrl,
    regFile_wrAddr    => regFile_wrAddr,
    regFile_wrData    => regFile_wrData,
    regFile_wrData_wide => regFile_wrData_wide,
    regFile_we        => regFile_we,
    regFile_we_lmem_p0 => regFile_we_lmem_p0,
    wf_finish         => gmem_finish,
    wf_finish_rd      => gmem_finish_rd,
    wf_rdAddr         => gmem_rdAddr,
    cus_alm_full      => gmem_alm_full,
    cntrl_idle        => gmem_cntrl_idle,
    nrst              => nrst_mem_cntrl
  );
  ------------------------------------------------------------------------------------------------}}}
end Behavioral;

