-- libraries --------------------------------------------------------------------------------- {{{
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.all;
use work.FGPU_definitions.all;
------------------------------------------------------------------------------------------------- }}}
entity FGPU is
-- Generics & ports {{{
port(
  clk                 : in  std_logic;
  -- Contorl Interface - AXI LITE SLAVE {{{
  s0_awaddr           : in std_logic_vector(INTERFCE_W_ADDR_W-1 downto 0);
  s0_awprot           : in std_logic_vector(2 downto 0);
  s0_awvalid          : in std_logic;
  s0_awready          : out std_logic := '0';

  s0_wdata            : in std_logic_vector(DATA_W-1 downto 0);
  s0_wstrb            : in std_logic_vector((DATA_W/8)-1 downto 0);
  s0_wvalid           : in std_logic;
  s0_wready           : out std_logic := '0';

  s0_bresp            : out std_logic_vector(1 downto 0) := (others=>'0');
  s0_bvalid           : out std_logic := '0';
  s0_bready           : in std_logic;

  s0_araddr           : in std_logic_vector(INTERFCE_W_ADDR_W-1 downto 0);
  s0_arprot           : in std_logic_vector(2 downto 0);
  s0_arvalid          : in std_logic;
  s0_arready          : out std_logic := '0';

  s0_rdata            : out std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  s0_rresp            : out std_logic_vector(1 downto 0) := (others=>'0');
  s0_rvalid           : out std_logic := '0';
  s0_rready           : in std_logic;
  -- }}}
  -- AXI MASTER 0 {{{
  -- ar channel
  m0_araddr           : out std_logic_vector(GMEM_ADDR_W-1 downto 0):= (others=>'0');
  m0_arlen            : out std_logic_vector(7 downto 0):= (others=>'0');
  m0_arsize           : out std_logic_vector(2 downto 0):= (others=>'0');
  m0_arburst          : out std_logic_vector(1 downto 0):= (others=>'0');
  m0_arvalid          : out std_logic := '0';
  m0_arready          : in std_logic;
  m0_arid             : out std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
-- r channel
  m0_rdata            : in std_logic_vector(GMEM_DATA_W-1 downto 0):= (others=>'0');
  m0_rresp            : in std_logic_vector(1 downto 0):= (others=>'0');
  m0_rlast            : in std_logic;
  m0_rvalid           : in std_logic;
  m0_rready           : out std_logic := '0';
  m0_rid              : in std_logic_vector(ID_WIDTH-1 downto 0);
  -- aw channel
  m0_awaddr           : out std_logic_vector(GMEM_ADDR_W-1 downto 0) := (others=>'0');
  m0_awvalid          : out std_logic := '0';
  m0_awready          : in std_logic;
  m0_awlen            : out std_logic_vector(7 downto 0):= (others=>'0');
  m0_awsize           : out std_logic_vector(2 downto 0):= (others=>'0');
  m0_awburst          : out std_logic_vector(1 downto 0):= (others=>'0');
  m0_awid             : out std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- w channel
  m0_wdata            : out std_logic_vector(DATA_W*GMEM_N_BANK-1 downto 0):= (others=>'0');
  m0_wstrb            : out std_logic_vector(DATA_W*GMEM_N_BANK/8-1 downto 0):= (others=>'0');
  m0_wlast            : out std_logic := '0';
  m0_wvalid           : out std_logic := '0';
  m0_wready           : in std_logic;
  -- b channel
  m0_bvalid           : in std_logic;
  m0_bready           : out std_logic := '0';
  m0_bid              : in std_logic_vector(ID_WIDTH-1 downto 0);
  -- }}}}
  -- AXI MASTER 1 {{{
  -- ar channel
  m1_araddr           : out std_logic_vector(GMEM_ADDR_W-1 downto 0):= (others=>'0');
  m1_arlen            : out std_logic_vector(7 downto 0):= (others=>'0');
  m1_arsize           : out std_logic_vector(2 downto 0):= (others=>'0');
  m1_arburst          : out std_logic_vector(1 downto 0):= (others=>'0');
  m1_arvalid          : out std_logic := '0';
  m1_arready          : in std_logic;
  m1_arid             : out std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
-- r channel
  m1_rdata            : in std_logic_vector(GMEM_DATA_W-1 downto 0):= (others=>'0');
  m1_rresp            : in std_logic_vector(1 downto 0):= (others=>'0');
  m1_rlast            : in std_logic;
  m1_rvalid           : in std_logic;
  m1_rready           : out std_logic := '0';
  m1_rid              : in std_logic_vector(ID_WIDTH-1 downto 0);
  -- aw channel
  m1_awaddr           : out std_logic_vector(GMEM_ADDR_W-1 downto 0) := (others=>'0');
  m1_awvalid          : out std_logic := '0';
  m1_awready          : in std_logic;
  m1_awlen            : out std_logic_vector(7 downto 0):= (others=>'0');
  m1_awsize           : out std_logic_vector(2 downto 0):= (others=>'0');
  m1_awburst          : out std_logic_vector(1 downto 0):= (others=>'0');
  m1_awid             : out std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- w channel
  m1_wdata            : out std_logic_vector(DATA_W*GMEM_N_BANK-1 downto 0):= (others=>'0');
  m1_wstrb            : out std_logic_vector(DATA_W*GMEM_N_BANK/8-1 downto 0):= (others=>'0');
  m1_wlast            : out std_logic := '0';
  m1_wvalid           : out std_logic := '0';
  m1_wready           : in std_logic;
  -- b channel
  m1_bvalid           : in std_logic;
  m1_bready           : out std_logic := '0';
  m1_bid              : in std_logic_vector(ID_WIDTH-1 downto 0);
  -- }}}}
  -- AXI MASTER 2 {{{
  -- ar channel
  m2_araddr           : out std_logic_vector(GMEM_ADDR_W-1 downto 0):= (others=>'0');
  m2_arlen            : out std_logic_vector(7 downto 0):= (others=>'0');
  m2_arsize           : out std_logic_vector(2 downto 0):= (others=>'0');
  m2_arburst          : out std_logic_vector(1 downto 0):= (others=>'0');
  m2_arvalid          : out std_logic := '0';
  m2_arready          : in std_logic;
  m2_arid             : out std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
-- r channel
  m2_rdata            : in std_logic_vector(GMEM_DATA_W-1 downto 0):= (others=>'0');
  m2_rresp            : in std_logic_vector(1 downto 0):= (others=>'0');
  m2_rlast            : in std_logic;
  m2_rvalid           : in std_logic;
  m2_rready           : out std_logic := '0';
  m2_rid              : in std_logic_vector(ID_WIDTH-1 downto 0);
  -- aw channel
  m2_awaddr           : out std_logic_vector(GMEM_ADDR_W-1 downto 0) := (others=>'0');
  m2_awvalid          : out std_logic := '0';
  m2_awready          : in std_logic;
  m2_awlen            : out std_logic_vector(7 downto 0):= (others=>'0');
  m2_awsize           : out std_logic_vector(2 downto 0):= (others=>'0');
  m2_awburst          : out std_logic_vector(1 downto 0):= (others=>'0');
  m2_awid             : out std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- w channel
  m2_wdata            : out std_logic_vector(DATA_W*GMEM_N_BANK-1 downto 0):= (others=>'0');
  m2_wstrb            : out std_logic_vector(DATA_W*GMEM_N_BANK/8-1 downto 0):= (others=>'0');
  m2_wlast            : out std_logic := '0';
  m2_wvalid           : out std_logic := '0';
  m2_wready           : in std_logic;
  -- b channel
  m2_bvalid           : in std_logic;
  m2_bready           : out std_logic := '0';
  m2_bid              : in std_logic_vector(ID_WIDTH-1 downto 0);
  -- }}}}
  -- AXI MASTER 3 {{{
  -- ar channel
  m3_araddr           : out std_logic_vector(GMEM_ADDR_W-1 downto 0):= (others=>'0');
  m3_arlen            : out std_logic_vector(7 downto 0):= (others=>'0');
  m3_arsize           : out std_logic_vector(2 downto 0):= (others=>'0');
  m3_arburst          : out std_logic_vector(1 downto 0):= (others=>'0');
  m3_arvalid          : out std_logic := '0';
  m3_arready          : in std_logic;
  m3_arid             : out std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
-- r channel
  m3_rdata            : in std_logic_vector(GMEM_DATA_W-1 downto 0):= (others=>'0');
  m3_rresp            : in std_logic_vector(1 downto 0):= (others=>'0');
  m3_rlast            : in std_logic;
  m3_rvalid           : in std_logic;
  m3_rready           : out std_logic := '0';
  m3_rid              : in std_logic_vector(ID_WIDTH-1 downto 0);
  -- aw channel
  m3_awaddr           : out std_logic_vector(GMEM_ADDR_W-1 downto 0) := (others=>'0');
  m3_awvalid          : out std_logic := '0';
  m3_awready          : in std_logic;
  m3_awlen            : out std_logic_vector(7 downto 0):= (others=>'0');
  m3_awsize           : out std_logic_vector(2 downto 0):= (others=>'0');
  m3_awburst          : out std_logic_vector(1 downto 0):= (others=>'0');
  m3_awid             : out std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- w channel
  m3_wdata            : out std_logic_vector(DATA_W*GMEM_N_BANK-1 downto 0):= (others=>'0');
  m3_wstrb            : out std_logic_vector(DATA_W*GMEM_N_BANK/8-1 downto 0):= (others=>'0');
  m3_wlast            : out std_logic := '0';
  m3_wvalid           : out std_logic := '0';
  m3_wready           : in std_logic;
  -- b channel
  m3_bvalid           : in std_logic;
  m3_bready           : out std_logic := '0';
  m3_bid              : in std_logic_vector(ID_WIDTH-1 downto 0);
  -- }}}}
  nrst              : in  std_logic
);
-- ports }}}
end FGPU;
architecture Behavioral of FGPU is
  component cu_gmem_fifo is
  port (
    data  : in  std_logic_vector(34 downto 0) := (others => 'X'); -- datain
    wrreq : in  std_logic                      := 'X';             -- wrreq
    rdreq : in  std_logic                      := 'X';             -- rdreq
    clock : in  std_logic                      := 'X';             -- clk
    sclr  : in  std_logic                      := 'X';             -- sclr
    q     : out std_logic_vector(34 downto 0);                    -- dataout
    full  : out std_logic;                                         -- full
    empty : out std_logic                                          -- empty
  );
  end component cu_gmem_fifo;
  -- internal signals definitions {{{
  signal s0_awready_i, s0_bvalid_i            : std_logic := '0';
  signal s0_wready_i, s0_arready_i            : std_logic := '0';
  signal nrst_CUs                             : std_logic_vector(N_CU-1 downto 0) := (others=>'0');
  signal nrst_gmem_cntrl                      : std_logic := '0';
  signal nrst_wgDispatcher                    : std_logic := '0';
  -- }}}
  -- slave axi interface {{{
  signal mainProc_we                  : std_logic := '0';
  signal mainProc_wrAddr                : std_logic_vector(INTERFCE_W_ADDR_W-1 downto 0) := (others=>'0');
  signal mainProc_rdAddr                : unsigned(INTERFCE_W_ADDR_W-1 downto 0) := (others=>'0');
  signal s0_rvalid_vec                  : std_logic_vector(3 downto 0) := (others=>'0');
  signal s0_wdata_d0                    : std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  -- }}}
  -- general signals definitions {{{
  signal KRNL_SCHEDULER_RAM               : KRNL_SCHEDULER_RAM_type 
    -- synthesis translate_off
     := init_krnl_ram("../RTL/krnl_ram.mif")
    -- synthesis translate_on
  ;
  -- signal cram_b1                          : CRAM_type := init_CRAM("cram_LUdecomposition.mif", 930);
  signal cram_b1                          : CRAM_type 
    -- synthesis translate_off
     := init_CRAM("../RTL/cram.mif", 512)
    -- synthesis translate_on
  ;

  signal KRNL_SCH_we                      : std_logic := '0';
  signal krnl_sch_rdData                  : std_logic_vector(DATA_W-1 downto 0) := (others => '0');
  signal krnl_sch_rdData_n                : std_logic_vector(DATA_W-1 downto 0) := (others => '0');
  signal krnl_sch_rdAddr                  : unsigned(KRNL_SCH_ADDR_W-1 downto 0) := (others => '0');
  signal krnl_sch_rdAddr_WGD              : std_logic_vector(KRNL_SCH_ADDR_W-1 downto 0) := (others => '0');

  signal CRAM_we                          : std_logic := '0';
  -- signal cram_rdData, cram_rdData_n       : SLV32_ARRAY(CRAM_BLOCKS-1 downto 0) := (others=>(others=>'0'));
  -- signal cram_rdAddr, cram_rdAddr_d0      : CRAM_ADDR_ARRAY(CRAM_BLOCKS-1 downto 0) := (others=>(others=>'0'));
  signal cram_rdData, cram_rdData_n       : std_logic_vector(2*DATA_W-1 downto 0) := (others=>'0');
  signal cram_rdData_vec                  : slv64_array(max(N_CU/2-1, 0) downto 0) := (others=>(others=>'0'));
  signal cram_rdData2, cram_rdData2_n     : std_logic_vector(2*DATA_W-1 downto 0) := (others=>'0');
  signal cram_rdData2_vec                 : slv64_array(max(N_CU/2-1, 0) downto 0) := (others=>(others=>'0'));
  signal cram_rdAddr, cram_rdAddr_d0      : unsigned(CRAM_ADDR_W-1 downto 0) := (others=>'0');
  signal cram_rdAddr_d0_vec               : cram_addr_array(max(N_CU/2-1, 0) downto 0) := (others=>(others=>'0'));
  signal cram_rdAddr2, cram_rdAddr2_d0    : unsigned(CRAM_ADDR_W-1 downto 0) := (others=>'0');
  signal cram_rdAddr2_d0_vec              : cram_addr_array(max(N_CU/2-1, 0) downto 0) := (others=>(others=>'0'));

  signal status_reg                       : std_logic_vector(DATA_W-1 downto 0) := (others => '0');

  signal regFile_we, regFile_we_d0        : std_logic := '0';
  signal Rstat                            : std_logic_vector(NEW_KRNL_MAX_INDX-1 downto 0) := (others => '0');
  signal Rstart                           : std_logic_vector(NEW_KRNL_MAX_INDX-1 downto 0) := (others => '0');
  signal RcleanCache                      : std_logic_vector(NEW_KRNL_MAX_INDX-1 downto 0) := (others=>'0');
  signal RInitiate                        : std_logic_vector(NEW_KRNL_MAX_INDX-1 downto 0) := (others=>'0');

  signal debug_startCU                    : std_logic := '0';
  signal debug_startkernel                : std_logic := '0';
  signal debug_wgdispatched               : std_logic := '0';
  signal debug_wfactived_0                : std_logic := '0';
  signal debug_wfactive_0                 : std_logic_vector(7 downto 0) := (others => '0');

  type WG_dispatcher_state_type is (idle, st1_dispatch);
  signal st_wg_disp, st_wg_disp_n         : WG_dispatcher_state_type := idle;


  signal new_krnl_indx                    : integer range 0 to NEW_KRNL_MAX_INDX-1 := 0;
  signal new_krnl_field                   : std_logic_vector(NEW_KRNL_DESC_W-1 downto 0) := (others =>'0');

  signal start_kernel, clean_cache        : std_logic := '0';
  signal start_CUs, initialize_d0         : std_logic := '0';   -- informs all CUs to start working after initialization phase of the WG_dispatcher is finished
  signal start_CUs_vec                    : std_logic_vector(max(N_CU-1, 0) downto 0) := (others=>'0'); -- to improve timing
  signal finish_exec                      : std_logic_vector(N_AXI-1 downto 0) := (others=>'0');   -- high when execution of a kernel is done
  signal WGsDispatched, WGsDispatched_d   : std_logic := '0';   -- high when WG_Dispatcher has schedules all WGs
  signal WGsDispatched_slow               : std_logic := '0';   -- high when WG_Dispatcher has schedules all WGs
  signal finish_exec_d0                   : std_logic := '0';
  signal finish_krnl_indx                 : integer range 0 to NEW_KRNL_MAX_INDX-1 := 0;
  signal wg_req                           : std_logic_vector(N_CU-1 downto 0) := (others => '0');
  signal wg_ack                           : std_logic_vector(N_CU-1 downto 0) := (others=>'0');
  type wg_req_vec_type is array(natural range <>) of std_logic_vector(N_CU-1 downto 0);
  signal wg_req_vec                       : wg_req_vec_type(max(N_CU-1, 0) downto 0) := (others=>(others=>'0'));
  signal wg_ack_vec                       : wg_req_vec_type(max(N_CU-1, 0) downto 0) := (others=>(others=>'0'));
  signal CU_cram_rqst                     : std_logic_vector(N_CU-1 downto 0) := (others => '0');
  signal sch_rqst_n_WFs_m1                : unsigned(N_WF_CU_W-1 downto 0) := (others=>'0');
  type sch_rqst_n_WFs_m1_vec_type is array (natural range <>) of unsigned(N_WF_CU_W-1 downto 0);
  signal sch_rqst_n_WFs_m1_vec            : sch_rqst_n_WFs_m1_vec_type(max(N_CU-1, 0) downto 0) := (others=>(others=>'0'));
  signal cram_served_CUs                  : std_logic := '0'; -- one-bit-toggle to serve different CUs when fetching instructions

  signal CU_cram_rdAddr                   : CRAM_ADDR_ARRay(N_CU-1 downto 0) := (others =>(others=>'0'));
  signal start_addr                       : unsigned(CRAM_ADDR_W-1 downto 0) := (others=>'0');  -- the address of the first instruction to be fetched
  signal start_addr_vec                   : cram_addr_array(max(N_CU-1, 0) downto 0) := (others=>(others=>'0')); -- just to improve timing


  signal rdData_alu_en                    : alu_en_vec_type(N_CU-1 downto 0) := (others=>(others=>'0'));
  signal rdAddr_alu_en                    : alu_en_rdAddr_type(N_CU-1 downto 0) := (others=>(others=>'0'));

  signal rtm_wrAddr_wg                    : unsigned(RTM_ADDR_W-1 downto 0) := (others => '0');
  type rtm_addr_vec_type is array (natural range<>) of unsigned(RTM_ADDR_W-1 downto 0);
  signal rtm_wrAddr_wg_vec                : rtm_addr_vec_type(max(N_CU-1, 0) downto 0) := (others=>(others=>'0'));
  signal rtm_wrData_wg                    : unsigned(RTM_DATA_W-1 downto 0) := (others => '0');
  signal rtm_wrData_wg_vec                : rtm_ram_type(max(N_CU-1, 0) downto 0) := (others=>(others=>'0'));
  signal rtm_we_wg                        : std_logic := '0';
  signal rtm_we_wg_vec                    : std_logic_vector(max(N_CU-1, 0) downto 0) := (others=>'0');
  signal wg_info                          : unsigned(DATA_W-1 downto 0) := (others=>'0'); 
  signal wg_info_vec                      : slv32_array(max(N_CU-1, 0) downto 0) := (others=>(others=>'0'));
  -- }}}
  constant N_CU_CLUSTER                   : natural := min_int(N_CU, 2);
  constant N_CLUSTER                      : natural := N_CU/N_CU_CLUSTER;
  -- global memory ---------------------------------------------------- {{{
  -- cache signals 
  function distribute_cache_rd_ports_on_CUs (n_cus: integer; n_clus: integer) return nat_array is -- {{{
    variable res: nat_array(n_cus-1 downto 0) := (others=>0);
    -- res(0) will have the maximum distance to the global memory controller
  begin
    for i in 0 to n_cus-1 loop
      -- res(i) := n_cus/2*(i mod 2) + (i/2);
      res(i) := n_clus/2*(i mod 2) + ((i mod n_clus)/2);
    end loop;
    return res;
  end; -- }}}
  constant cache_rd_port_to_CU            : nat_array(N_CU-1 downto 0) := distribute_cache_rd_ports_on_CUs(N_CU, N_CLUSTER);
  type rdData_out_type is array(natural range <>) of std_logic_vector(DATA_W*CACHE_N_BANKS-1 downto 0);
  --signal atomic_rdData_vec                : slv32_array(N_CU-1 downto 0) := (others=>(others=>'0'));
  --signal atomic_rdData_v_vec              : rdData_v_vec_type(N_CU-1 downto 0) := (others=>(others=>'0'));
  --signal atomic_sgntr_vec                 : atomic_sgntr_array(N_CU-1 downto 0) := (others=>(others=>'0'));
  signal cache_rdData_out                 : rdData_out_type(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal cache_rdAddr_out                 : GMEM_ADDR_ARRAY_NO_BANK(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal cache_rdAck_out                  : std_logic_vector(N_CU-1 downto 0) := (others=>'0');
  signal cache_rdCntrl_out                : rd_cntrl_array(N_CU-1 downto 0) := (others=>(others=>'0'));
  signal cache_rdData_in                  : rdData_out_type(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal cache_rdAddr_in                  : GMEM_ADDR_ARRAY_NO_BANK(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal cache_rdAck_in                   : std_logic_vector(N_CU-1 downto 0) := (others=>'0');
  signal cache_rdCntrl_in                 : rd_cntrl_array(N_CU-1 downto 0) := (others=>(others=>'0'));
  type rdData_v_vec_type is array(natural range <>) of std_logic_vector(N_CU-1 downto 0);
  type rdAddr_vec_type is array(natural range <>) of GMEM_ADDR_ARRAY_NO_BANK(N_AXI-1 downto 0);
  type rdCntrl_vec_type is array(natural range <>) of rd_cntrl_array(N_CU-1 downto 0);
  type rdData_vec_type is array (natural range <>) of rdData_out_type(N_AXI-1 downto 0);
  signal cache_rdData_vec                 : rdData_vec_type(1 downto 0) := (others=>(others=>(others=>'0')));
  signal cache_rdAddr_vec                 : rdAddr_vec_type(1 downto 0) := (others=>(others=>(others=>'0')));
  signal cache_rdAck_vec                  : rdData_v_vec_type(1 downto 0) := (others=>(others=>'0'));
  signal cache_rdCntrl_vec                : rdCntrl_vec_type(1 downto 0) := (others=>(others=>(others=>'0')));
  signal st_sync, st_sync_n               : std_logic := '0';

  signal atomic_rdData_in                 : std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  signal atomic_rdData_v_in               : std_logic_vector(N_CU-1 downto 0) := (others=>'0');
  signal atomic_sgntr_in                  : std_logic_vector(N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  signal atomic_rdData                    : std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  signal atomic_rdData_v                  : std_logic_vector(N_CU-1 downto 0) := (others=>'0');
  signal atomic_sgntr                     : std_logic_vector(N_CU_STATIONS_W-1 downto 0) := (others=>'0');
  signal gsync_reached                    : std_logic := '1';
  signal wf_reach_gsync_ltch              : std_logic_vector(N_CU-1 downto 0) := (others=>'0');

  constant FIFO_W                         : integer := GMEM_WORD_ADDR_W-CACHE_N_BANKS_W+N_CU_STATIONS_W+2;
  --constant FIFO_WRDATA_LOW                : integer := 0;
  --constant FIFO_WRDATA_HIGH               : integer := FIFO_WRDATA_LOW+DATA_W-1;
  constant FIFO_ADDR_LOW                  : integer := 0;
  constant FIFO_ADDR_HIGH                 : integer := FIFO_ADDR_LOW+GMEM_WORD_ADDR_W-CACHE_N_BANKS_W-1;
  --constant FIFO_WE_LOW                    : integer := FIFO_ADDR_HIGH+1;
  --constant FIFO_WE_HIGH                   : integer := FIFO_WE_LOW+(DATA_W/8)-1;
  constant FIFO_ATOMIC_POS                : integer := FIFO_ADDR_HIGH+1;
  constant FIFO_SGNTR_LOW                 : integer := FIFO_ATOMIC_POS+1;
  constant FIFO_SGNTR_HIGH                : integer := FIFO_SGNTR_LOW+N_CU_STATIONS_W-1;
  constant FIFO_RNW_POS                   : integer := FIFO_SGNTR_HIGH+1;

  type cu_gmem_fifo_type is array(natural range <>) of std_logic_vector(FIFO_W-1 downto 0);
  type cu_gmem_wrfifo_type is array(natural range <>) of std_logic_vector(GMEM_WRFIFO_W+1 downto 0);
  type cu_gmem_we_array is array(natural range <>) of std_logic_vector(CV_SIZE*DATA_W/8-1 downto 0);
  type cu_gmem_op_type_array is array (natural range <>) of std_logic_vector(2 downto 0);
  type cu_gmem_addr_array is array(natural range <>) of std_logic_vector(GMEM_WORD_ADDR_W-CACHE_N_BANKS_W-1 downto 0);
  type cu_gmem_wrData_array is array(natural range <>) of std_logic_vector(GMEM_WRFIFO_W-1 downto 0);
  signal fifo_in                          : cu_gmem_fifo_type(N_CU-1 downto 0);
  signal fifo_out                         : cu_gmem_fifo_type(N_CU-1 downto 0);
  signal fifo_enq                         : std_logic_vector(N_CU-1 downto 0);
  signal fifo_deq                         : std_logic_vector(N_CU-1 downto 0);
  signal fifo_full                        : std_logic_vector(N_CU-1 downto 0);
  signal fifo_empty                       : std_logic_vector(N_CU-1 downto 0);
  signal wrfifo_in                        : cu_gmem_wrfifo_type(N_CU-1 downto 0);
  signal wrfifo_out                       : cu_gmem_wrfifo_type(N_CU-1 downto 0);
  signal wrfifo_enq                       : std_logic_vector(N_CU-1 downto 0);
  signal wrfifo_deq                       : std_logic_vector(N_CU-1 downto 0);
  signal wrfifo_full                      : std_logic_vector(N_CU-1 downto 0);
  signal wrfifo_empty                     : std_logic_vector(N_CU-1 downto 0);
  signal cu_gmem_valid                    : std_logic_vector(N_CU-1 downto 0);
  signal cu_gmem_req_valid                : std_logic_vector(N_CU-1 downto 0) := (others=>'0');
  signal cu_gmem_rnw, cu_gmem_atomic      : std_logic_vector(N_CU-1 downto 0) := (others=>'0');
  signal cu_gmem_atomic_sgntr             : atomic_sgntr_array(N_CU-1 downto 0) := (others=>(others=>'0'));
  signal cu_rqst_addr                     : cu_gmem_addr_array(N_CU-1 downto 0) := (others=>(others=>'0'));
  signal cu_gmem_op_type                  : cu_gmem_op_type_array(N_CU-1 downto 0) := (others=>(others=>'0'));
  signal cu_rqst_cntrl                    : rd_cntrl_array(N_CU-1 downto 0) := (others=>(others=>'0'));
  signal cu_gmem_wrData                   : cu_gmem_wrData_array(N_CU-1 downto 0) := (others=>(others=>'0'));
  signal cu_gmem_ready                    : std_logic_vector(N_CU-1 downto 0) := (others=>'0');
  signal cu_gmem_valid_out                : std_logic_vector(N_CU-1 downto 0) := (others=>'0');
  signal cu_gmem_ready_out                : std_logic_vector(N_CU-1 downto 0) := (others=>'0');
  signal cu_gmem_we_out                   : be_array(N_CU-1 downto 0) := (others=>(others=>'0'));
  signal cu_gmem_rnw_out                  : std_logic_vector(N_CU-1 downto 0) := (others=>'0');
  signal cu_gmem_atomic_out               : std_logic_vector(N_CU-1 downto 0) := (others=>'0');
  signal cu_gmem_atomic_sgntr_out         : atomic_sgntr_array(N_CU-1 downto 0) := (others=>(others=>'0'));
  signal cu_rqst_addr_out                 : GMEM_WORD_ADDR_ARRAY(N_CU-1 downto 0) := (others=>(others=>'0'));
  signal cu_rqst_cntrl_out                : rd_cntrl_array(N_CU-1 downto 0) := (others=>(others=>'0'));
  type slv2_array is array (natural range <>) of std_logic_vector(1 downto 0);
  type slv3_array is array (natural range <>) of std_logic_vector(2 downto 0);
  type waddr_array is array (natural range <>) of std_logic_vector(GMEM_WORD_ADDR_W-GMEM_WR_N_WORDS_W-1 downto 0);
  type wrdata_array is array (natural range <>) of std_logic_vector(GMEM_WRFIFO_W-GMEM_WORD_ADDR_W+GMEM_WR_N_WORDS_W-516 downto 0);
  type slv512_array is array (natural range <>) of std_logic_vector(511 downto 0);
  signal cu_gmem_wvalid                   : std_logic_vector(N_AXI-1 downto 0) := (others=>'0');
  signal cu_gmem_wready                   : std_logic_vector(N_AXI-1 downto 0) := (others=>'0');
  signal cu_gmem_wcu_en                   : slv2_array(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal cu_gmem_wtype                    : slv3_array(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal cu_gmem_waddr                    : waddr_array(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal cu_gmem_wrData_out               : wrdata_array(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal cu_gmem_wrData_ex                : slv512_array(N_AXI-1 downto 0);

  signal wf_active                        : wf_active_array(N_CU-1 downto 0) := (others=>(others=>'0'));
  signal cu_active                        : std_logic_vector(N_CU-1 downto 0) := (others=>'0');
  --signal debug_st                         : SLV32_ARRAY(N_CU-1 downto 0) := (others=>(others=>'0'));
  signal debug_st                         : std_logic_vector(127 downto 0) := (others=>'0');
  signal debug_st_gmem                    : std_logic_vector(31 downto 0) := (others=>'0');
  signal wf_reach_gsync                   : std_logic_vector(N_CU-1 downto 0) := (others=>'0');
  signal CU_gmem_idle                     : std_logic_vector(N_CU-1 downto 0) := (others=>'0');
  signal CUs_gmem_idle, CUs_gmem_idle_d   : std_logic := '0';
  signal CUs_gmem_idle_slow               : std_logic := '0';
  signal axi_araddr                       : GMEM_ADDR_ARRAY(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal axi_arvalid, axi_arready         : std_logic_vector(N_AXI-1 downto 0) := (others=>'0');
  signal axi_rdata                        : gmem_word_array(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal axi_rlast                        : std_logic_vector(N_AXI-1 downto 0) := (others=>'0');
  signal axi_rvalid, axi_rready           : std_logic_vector(N_AXI-1 downto 0) := (others=>'0');
  signal axi_awaddr                       : GMEM_ADDR_ARRAY(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal axi_awvalid, axi_awready         : std_logic_vector(N_AXI-1 downto 0) := (others=>'0');
  signal axi_wdata                        : gmem_word_array(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal axi_wstrb                        : gmem_be_array(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal axi_wlast                        : std_logic_vector(N_AXI-1 downto 0) := (others=>'0');
  signal axi_wvalid, axi_wready           : std_logic_vector(N_AXI-1 downto 0) := (others=>'0');
  signal axi_bvalid, axi_bready           : std_logic_vector(N_AXI-1 downto 0) := (others=>'0');
  signal axi_arid, axi_rid                : id_array(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal axi_awid, axi_bid                : id_array(N_AXI-1 downto 0) := (others=>(others=>'0'));
  --}}}
begin
  -- asserts -------------------------------------------------------------------------------------------{{{
  assert KRNL_SCH_ADDR_W <= CRAM_ADDR_W severity failure; --Code RAM is the biggest block
  assert CRAM_ADDR_W <= INTERFCE_W_ADDR_W-2 severity failure; --there should be two bits to choose among: HW_sch_RAM, CRAM and the register file
  assert DATA_W >= GMEM_ADDR_W report "the width bus between a gmem_ctrl_CV and gmem_ctrl is GMEM_DATA_W" severity failure;
  assert CV_SIZE = 8 or CV_SIZE = 4 severity failure;
  assert 2**N_CU_STATIONS_W >= N_STATIONS_ALU*CV_SIZE report "increase N_STATIONS_W" severity failure;
  assert N_TAG_MANAGERS_W > 0 report "There should be at least two tag managers" severity failure;
  assert DATA_W = 32;
  -- assert CRAM_BLOCKS = 1 or CRAM_BLOCKS = 2;
  -- assert N_AXI = 1 or N_AXI = 2;
  -- assert N_AXI = 1 or N_AXI = 2;
  ---------------------------------------------------------------------------------------------------------}}}
  -- interal signals assignments --------------------------------------------------------------------------{{{
  s0_awready <= s0_awready_i;
  s0_bvalid <= s0_bvalid_i;
  s0_wready <= s0_wready_i;
  s0_arready <= s0_arready_i;
  ---------------------------------------------------------------------------------------------------------}}}
  process(clk)
  begin
    if rising_edge(clk) then
        if nrst = '0' then
            debug_startkernel <= '0';
            debug_startCU <= '0';
            debug_wgdispatched <= '0';
            debug_wfactived_0 <= '0';
            debug_wfactive_0 <= (others => '0');
        else
            if start_kernel = '1' then
                debug_startkernel <= '1';
            end if;
            if start_CUs = '1' then
                debug_startCU <= '1';
            end if;
            if WGsDispatched = '1' then
                debug_wgdispatched <= '1';
            end if;
            if wf_active(0) = "11111111" then
                debug_wfactived_0 <= '1';
            end if;
            debug_wfactive_0 <= wf_active(0);
        end if;
    end if;
  end process;

  -- slave axi interface ----------------------------------------------------------------------------------{{{
  -- aw & w channels
  process(clk)
  begin
    if rising_edge(clk) then 
      if nrst = '0' then
        s0_awready_i <= '0';
        s0_wready_i <= '0';
        mainProc_we <= '0';
        mainProc_wrAddr <= (others=>'0');
      else
        if s0_awready_i = '0' and s0_awvalid = '1' and s0_wvalid = '1' then
          s0_awready_i <= '1';
          mainProc_wrAddr <= s0_awaddr;
          s0_wready_i <= '1';
          mainProc_we <= '1';
        else
          s0_awready_i <= '0';
          s0_wready_i <= '0';
          mainProc_we <= '0';
        end if;
      end if;
    end if;
  end process;
  -- b channel
  process(clk)
  begin
    if rising_edge(clk) then 
      if nrst = '0' then
        s0_bvalid_i  <= '0';
      else
        if s0_awready_i = '1' and s0_awvalid = '1' and s0_wready_i = '1' and s0_wvalid = '1' and s0_bvalid_i = '0' then
          s0_bvalid_i <= '1';
        elsif s0_bready = '1' and s0_bvalid_i = '1' then
          s0_bvalid_i <= '0';
        end if;
      end if;
    end if;                   
  end process; 
  -- ar channel
  process(clk)
  begin
    if rising_edge(clk) then 
      -- if nrst = '0' then
      --   s_arready_i <= '0';
      --   mainProc_rdAddr  <= (others=>'0'); 
      -- else
        if s0_arready_i = '0' and s0_arvalid = '1' then
          s0_arready_i <= '1';
          mainProc_rdAddr  <= unsigned(s0_araddr); 
        else
          s0_arready_i <= '0';
        end if;
      -- end if;
    end if;                   
  end process; 
  -- r channel
  process(clk)
  begin
    if rising_edge(clk) then
      if nrst = '0' then
        s0_rvalid_vec <= (others=>'0');
        s0_rvalid <= '0';
      else
        s0_rvalid_vec(s0_rvalid_vec'high-1 downto 0) <= s0_rvalid_vec(s0_rvalid_vec'high downto 1);
        if s0_arready_i = '1' and s0_arvalid = '1' and s0_rvalid_vec(s0_rvalid_vec'high) = '0' then
          s0_rvalid_vec(s0_rvalid_vec'high) <= '1';
        else 
          s0_rvalid_vec(s0_rvalid_vec'high) <= '0';
        end if;
        if s0_rvalid_vec(1) = '1' then
          s0_rvalid <= '1';
        end if;
        if s0_rvalid_vec(0) = '1' then
          if s0_rready = '1' then
            s0_rvalid <= '0';
          else
            s0_rvalid_vec(0) <= '1';
          end if;
        end if;            
      end if;
    end if;
  end process;
  process(clk)
  begin
    if rising_edge(clk) then
      if mainProc_rdAddr(INTERFCE_W_ADDR_W-1 downto INTERFCE_W_ADDR_W-2) = "00" then -- HW_scheduler_ram
        s0_rdata <= krnl_sch_rdData;
      elsif mainProc_rdAddr(INTERFCE_W_ADDR_W-1 downto INTERFCE_W_ADDR_W-2) = "01" then -- Code_ram
        s0_rdata <= cram_rdData(DATA_W-1 downto 0);
        -- s0_rdata <= cram_rdData(0);
      else -- "10", register file
        s0_rdata(DATA_W-1 downto NEW_KRNL_MAX_INDX) <= (others=>'0');
        case mainProc_rdAddr(3 downto 0) is
          when "0000" =>
            s0_rdata(NEW_KRNL_MAX_INDX-1 downto 0)  <= Rstat(NEW_KRNL_MAX_INDX-1 downto 0);
          when "0010" =>
            s0_rdata(NEW_KRNL_MAX_INDX-1 downto 0)  <= RcleanCache(NEW_KRNL_MAX_INDX-1 downto 0);
          when "0011" =>
            s0_rdata(NEW_KRNL_MAX_INDX-1 downto 0)  <= RInitiate(NEW_KRNL_MAX_INDX-1 downto 0);
          when "0100" =>
            s0_rdata(NEW_KRNL_MAX_INDX-1 downto 1) <= (others => '0');
            s0_rdata(0) <= debug_startkernel;
          when "0101" =>
            s0_rdata(NEW_KRNL_MAX_INDX-1 downto 1) <= (others => '0');
            s0_rdata(0) <= debug_startCU;
          when "0110" =>
            s0_rdata(NEW_KRNL_MAX_INDX-1 downto 1) <= (others => '0');
            s0_rdata(0) <= debug_wgdispatched;
          when "0111" =>
            s0_rdata(DATA_W-1 downto 8) <= (others => '0');
            s0_rdata(7 downto 0) <= debug_wfactive_0;
          when "1000" =>
            s0_rdata(NEW_KRNL_MAX_INDX-1 downto 1) <= (others => '0');
            s0_rdata(0) <= debug_wfactived_0;
          when "1001" =>
            s0_rdata <= debug_st(31 downto 0);
          when "1010" =>
            s0_rdata <= debug_st(63 downto 32);
          when "1011" =>
            --s0_rdata <= debug_st_gmem;
          when "1100" =>
            s0_rdata <= debug_st(95 downto 64);
          when "1101" =>
            s0_rdata <= debug_st(127 downto 96);
          when others =>

        end case;
      end if;
    end if;
  end process;
  ---------------------------------------------------------------------------------------------------------}}}
  -- fixed signals --------------------------------------------------------------------------------- {{{
  s0_bresp   <= "00";
  s0_rresp  <= "00";
  ------------------------------------------------------------------------------------------------- }}}
  -- HW Scheduler RAM  ----------------------------------------------------------------------------- {{{
  Krnl_Scheduler: process (clk)
  begin
    if rising_edge(clk) then
      krnl_sch_rdData_n <= KRNL_SCHEDULER_RAM(to_integer(krnl_sch_rdAddr));
      krnl_sch_rdData <= krnl_sch_rdData_n;
      if KRNL_SCH_we = '1' then
        KRNL_SCHEDULER_RAM(to_integer(unsigned(mainProc_wrAddr(KRNL_SCH_ADDR_W-1 downto 0)))) <= s0_wdata_d0;
      end if;
    end if;
  end process;

  krnl_sch_rdAddr <= mainProc_rdAddr(KRNL_SCH_ADDR_W-1 downto 0)  when st_wg_disp = idle else unsigned(krnl_sch_rdAddr_WGD);

  KRNL_SCH_we  <= '1' when mainProc_wrAddr(INTERFCE_W_ADDR_W-1 downto INTERFCE_W_ADDR_W-2) = "00" and mainProc_we = '1' else '0';
  ------------------------------------------------------------------------------------------------- }}}
  -- Code RAM -------------------------------------------------------------------------------------- {{{
  CRAM_inst: process (clk)
  begin
    if rising_edge(clk) then
      nrst_wgDispatcher <= nrst;

      -- cram_rdData_n <= cram_b1(to_integer(cram_rdAddr(0)));
      -- cram_rdData_n(0) <= cram_b1(to_integer(cram_rdAddr(0)));
      if CRAM_we = '1' then
        if mainProc_wrAddr(0) = '0' then
          cram_b1(to_integer(unsigned(mainProc_wrAddr(CRAM_ADDR_W downto 1))))(DATA_W-1 downto 0) <= s0_wdata_d0;
        else
          cram_b1(to_integer(unsigned(mainProc_wrAddr(CRAM_ADDR_W downto 1))))(2*DATA_W-1 downto DATA_W) <= s0_wdata_d0;
        end if;
      else
        cram_rdData_n <= cram_b1(to_integer(cram_rdAddr));
        cram_rdData2_n <= cram_b1(to_integer(cram_rdAddr2));
      end if;

      -- if CRAM_BLOCKS > 1 then
      --   cram_rdData_n(CRAM_BLOCKS-1) <= cram_b2(to_integer(cram_rdAddr(CRAM_BLOCKS-1)));
      --   if CRAM_we = '1' then
      --     cram_b2(to_integer(unsigned(mainProc_wrAddr(CRAM_ADDR_W-1 downto 0)))) <= s0_wdata_d0;
      --   end if;
      -- end if;
      
      cram_rdData <= cram_rdData_n;
      cram_rdData2 <= cram_rdData2_n;

    end if;
  end process;
  CRAM_we     <= '1' when mainProc_wrAddr(INTERFCE_W_ADDR_W-1 downto INTERFCE_W_ADDR_W-2) = "01" and mainProc_we = '1' else '0';
  process(clk)
  begin
    if rising_edge(clk) then
      cram_rdAddr_d0 <= cram_rdAddr;
      cram_rdAddr2_d0 <= cram_rdAddr2;
      cram_rdAddr <= mainProc_rdAddr(CRAM_ADDR_W-1 downto 0);
      -- cram_rdAddr(0) <= mainProc_rdAddr(CRAM_ADDR_W-1 downto 0);
      if N_CU = 1 then
        if CU_cram_rqst(0) = '1' then
          cram_rdAddr2 <= CU_cram_rdAddr(0);
        end if;
      elsif N_CU = 2 then
        if CU_cram_rqst(0) = '1' then
          cram_rdAddr <= CU_cram_rdAddr(0);
        end if;
        if CU_cram_rqst(1) = '1' then
          cram_rdAddr2 <= CU_cram_rdAddr(1);
        end if;
      else
        cram_served_CUs <= not cram_served_CUs;
        if cram_served_CUs = '0' then
          for i in 0 to max(N_CU/4-1,0) loop
            if CU_cram_rqst(i) = '1' then
              cram_rdAddr <= CU_cram_rdAddr(i);
            end if;
          end loop;
        else
          for i in N_CU/4 to N_CU/2-1 loop
            if CU_cram_rqst(i) = '1' then
              cram_rdAddr <= CU_cram_rdAddr(i);
            end if;
          end loop;
        end if;
        if cram_served_CUs = '0' then
          for i in 0 to max(N_CU/4*3-1,N_CU/2) loop
            if CU_cram_rqst(i) = '1' then
              cram_rdAddr2 <= CU_cram_rdAddr(i);
            end if;
          end loop;
        else
          for i in N_CU/4*3 to N_CU-1 loop
            if CU_cram_rqst(i) = '1' then
              cram_rdAddr2 <= CU_cram_rdAddr(i);
            end if;
          end loop;
        end if;
      end if;
    end if;
  end process;

  ------------------------------------------------------------------------------------------------- }}}
  -- WG dispatcher -------------------------------------------------------------------------------------- {{{
  WG_dispatcher_inst: entity WG_dispatcher
    port map(
      krnl_indx             => new_krnl_indx, -- in
      start                 => start_kernel, -- in
      initialize_d0         => initialize_d0, -- in
      krnl_sch_rdAddr       => krnl_sch_rdAddr_WGD, -- out
      krnl_sch_rdData       => krnl_sch_rdData, -- in
      finish_krnl_indx      => finish_krnl_indx, -- out

      -- to CUs
      start_exec            => start_CUs,
      req                   => wg_req,
      ack                   => wg_ack,
      rtm_wrAddr            => rtm_wrAddr_wg,
      rtm_wrData            => rtm_wrData_wg,
      rtm_we                => rtm_we_wg,
      sch_rqst_n_WFs_m1     => sch_rqst_n_WFs_m1,
      finish                => WGsDispatched,
      start_addr            => start_addr,
      rdData_alu_en         => rdData_alu_en,
      wg_info               => wg_info,
      -- from CUs
      wf_active             => wf_active,
      rdAddr_alu_en         => rdAddr_alu_en,


      clk                   => clk,
      nrst                  => nrst_wgDispatcher
  );
  ------------------------------------------------------------------------------------------------- }}}
  -- fifos -----------------------------------------------------------------------------------------{{{
  fifos_inst : for i in 0 to N_CU-1 generate
    fifo_inst : component cu_gmem_fifo
    port map (
      data  => fifo_in(i),  --  fifo_input.datain
      wrreq => fifo_enq(i) and (not fifo_full(i)), --            .wrreq
      rdreq => fifo_deq(i), --            .rdreq
      clock => clk, --            .clk
      sclr  => not nrst,  --            .sclr
      q     => fifo_out(i),     -- fifo_output.dataout
      full  => fifo_full(i),  --            .full
      empty => fifo_empty(i)  --            .empty
    );

    process(clk)
    begin
      if rising_edge(clk) then
        if fifo_full(i) = '0' then
          fifo_enq(i) <= '0';
          if cu_gmem_valid(i) = '1' and (cu_gmem_rnw(i) = '1' or wrfifo_full(i) = '0') then
            fifo_enq(i) <= '1';
            fifo_in(i)(FIFO_ADDR_HIGH downto FIFO_ADDR_LOW) <= cu_rqst_addr(i);
            fifo_in(i)(FIFO_SGNTR_HIGH downto FIFO_SGNTR_LOW) <= std_logic_vector(cu_rqst_cntrl(i));
            fifo_in(i)(FIFO_ATOMIC_POS) <= cu_gmem_atomic(i);
            fifo_in(i)(FIFO_RNW_POS) <= cu_gmem_rnw(i);
          end if;
        end if;
      end if;
    end process;
  end generate fifos_inst;

  fifo_chains_inst : for c in 0 to N_AXI-1 generate
    fifo_chain_inst : for i in 0 to 1 generate
      wrfifo_inst : entity fifo2
      generic map (FIFO_WIDTH => GMEM_WRFIFO_W+2)
      port map (
        din   => wrfifo_in(2*c+i),  --  fifo_input.datain
        enq   => wrfifo_enq(2*c+i) and (not wrfifo_full(2*c+i)), --            .wrreq
        deq   => wrfifo_deq(2*c+i), --            .rdreq
        clk   => clk, --            .clk
        nrst  => nrst,  --            .sclr
        dout  => wrfifo_out(2*c+i),     -- fifo_output.dataout
        full  => wrfifo_full(2*c+i),  --            .full
        empty => wrfifo_empty(2*c+i)  --            .empty
      );

      fifo_cntrl0: if i = 0 generate
        cu_gmem_ready_out(2*c+i) <= not (fifo_full(2*c+i) or (not (cu_gmem_rnw(2*c+i)) and wrfifo_full(2*c+i)));
        process(clk)
        begin
          if rising_edge(clk) then
            if wrfifo_full(2*c+i) = '0' then
              wrfifo_enq(2*c+i) <= '0';
              if fifo_full(2*c+i) = '0' and cu_gmem_rnw(2*c+i) = '0' and cu_gmem_valid(2*c+i) = '1' then
                wrfifo_enq(2*c+i) <= '1';
                wrfifo_in(2*c+i)(GMEM_WRFIFO_W-1 downto 0) <= cu_gmem_wrData(2*c+i);
                wrfifo_in(2*c+i)(2+GMEM_WRFIFO_W-1 downto GMEM_WRFIFO_W) <= (others=>'0');
                wrfifo_in(2*c+i)(GMEM_WRFIFO_W+i) <= '1';
              end if;
            end if;
          end if;
        end process;
      end generate fifo_cntrl0;

      fifo_cntrl1: if i /= 0 generate
        cu_gmem_ready_out(2*c+i) <= not (fifo_full(2*c+i) or (not (cu_gmem_rnw(2*c+i)) and wrfifo_full(2*c+i)));
        wrfifo_deq(2*c+i-1) <= '1' when (wrfifo_full(2*c+i) = '0' and wrfifo_empty(2*c+i-1) = '0' and 
          (cu_gmem_valid(2*c+i) = '0' or cu_gmem_rnw(2*c+i) = '1' or fifo_full(2*c+i) = '1')) else '0';
        process(clk)
        begin
          if rising_edge(clk) then
            if wrfifo_full(2*c+i) = '0' then
              wrfifo_enq(2*c+i) <= '0';
              wrfifo_in(2*c+i) <= wrfifo_out(2*c+i-1);
              if fifo_full(2*c+i) = '0' and cu_gmem_rnw(2*c+i) = '0' and cu_gmem_valid(2*c+i) = '1' then
                wrfifo_enq(2*c+i) <= '1';
                wrfifo_in(2*c+i)(GMEM_WRFIFO_W-1 downto 0) <= cu_gmem_wrData(2*c+i);
                wrfifo_in(2*c+i)(2+GMEM_WRFIFO_W-1 downto GMEM_WRFIFO_W) <= (others=>'0');
                wrfifo_in(2*c+i)(GMEM_WRFIFO_W+i) <= '1';
              elsif wrfifo_empty(2*c+i-1) = '0' then
                wrfifo_enq(2*c+i) <= '1';
              end if;
            end if;
          end if;
        end process;
      end generate fifo_cntrl1;
    end generate fifo_chain_inst;
    wrfifo_deq(2*c+1) <= (not wrfifo_empty(2*c+1)) and cu_gmem_wready(c);
    cu_gmem_wvalid(c) <= not wrfifo_empty(2*c+1);
    cu_gmem_wcu_en(c) <= wrfifo_out(2*c+1)(GMEM_WRFIFO_W+1 downto GMEM_WRFIFO_W);
    cu_gmem_wtype(c) <= wrfifo_out(2*c+1)(GMEM_WRFIFO_W-1 downto GMEM_WRFIFO_W-3);
    cu_gmem_waddr(c) <= wrfifo_out(2*c+1)(GMEM_WRFIFO_W-4 downto GMEM_WRFIFO_W-GMEM_WORD_ADDR_W+GMEM_WR_N_WORDS_W-3);
    cu_gmem_wrData_ex(c) <= wrfifo_out(2*c+1)(GMEM_WRFIFO_W-GMEM_WORD_ADDR_W+GMEM_WR_N_WORDS_W-4 downto GMEM_WRFIFO_W-GMEM_WORD_ADDR_W+GMEM_WR_N_WORDS_W-515);
    cu_gmem_wrData_out(c) <= wrfifo_out(2*c+1)(GMEM_WRFIFO_W-GMEM_WORD_ADDR_W+GMEM_WR_N_WORDS_W-516 downto 0);
  end generate fifo_chains_inst;

  fifo_cntrl2: for j in 0 to N_CU-1 generate
    fifo_deq(j) <= (not fifo_empty(j)) and (cu_gmem_ready(j) or (not fifo_out(j)(FIFO_RNW_POS)));
    cu_gmem_valid_out(j) <= not fifo_empty(j);
    cu_gmem_rnw_out(j) <= fifo_out(j)(FIFO_RNW_POS);
    cu_gmem_atomic_out(j) <= fifo_out(j)(FIFO_ATOMIC_POS);
    cu_rqst_addr_out(j)(GMEM_WORD_ADDR_W-1 downto CACHE_N_BANKS_W) <= unsigned(fifo_out(j)(FIFO_ADDR_HIGH downto FIFO_ADDR_LOW));
    cu_rqst_cntrl_out(j) <= unsigned(fifo_out(j)(FIFO_SGNTR_HIGH downto FIFO_SGNTR_LOW));
  end generate fifo_cntrl2;
  ------------------------------------------------------------------------------------------------- }}}
  -- compute units  -------------------------------------------------------------------------------------- {{{
  compute_units_inst: if N_CU > 1 generate
    compute_units_i_low: for i in 0 to N_CU/2-1 generate 
    begin
      compute_unit_inst: entity compute_unit
      generic map (cu_idx => i)
      port map(
        clk                   => clk,
        wf_active             => wf_active(i),
        wf_reach_gsync        => wf_reach_gsync(i),
        WGsDispatched         => WGsDispatched,
        nrst                  => nrst_CUs(i),
        cram_rdAddr           => CU_cram_rdAddr(i),      
        cram_rdData           => cram_rdData_vec(i),
        -- cram_rdData           => cram_rdData(i mod CRAM_BLOCKS),
        cram_rqst             => CU_cram_rqst(i),
        cram_rdAddr_conf      => cram_rdAddr_d0_vec(i),
        -- cram_rdAddr_conf      => cram_rdAddr_d0(i mod CRAM_BLOCKS),
        start_addr            => start_addr_vec(i),
  
        start_CUs             => start_CUs_vec(i),
        sch_rqst_n_wfs_m1     => sch_rqst_n_WFs_m1_vec(i),
        sch_rqst              => wg_req_vec(i)(i),
        sch_ack               => wg_ack(i),
        wg_info               => unsigned(wg_info_vec(i)),
        gsync_reached         => gsync_reached,
        rtm_wrAddr_wg         => rtm_wrAddr_wg_vec(i),
        rtm_wrData_wg         => rtm_wrData_wg_vec(i),
        rtm_we_wg             => rtm_we_wg_vec(i),
        rdData_alu_en         => rdData_alu_en(i),
        rdAddr_alu_en         => rdAddr_alu_en(i),
  
        gmem_valid            => cu_gmem_valid(i),
        gmem_rnw              => cu_gmem_rnw(i),
        gmem_op_type          => cu_gmem_op_type(i),
        gmem_atomic           => cu_gmem_atomic(i),
        gmem_atomic_sgntr     => cu_gmem_atomic_sgntr(i),
        gmem_rqst_addr        => cu_rqst_addr(i),
        gmem_rqst_cntrl       => cu_rqst_cntrl(i),
        gmem_ready            => cu_gmem_ready_out(i),
        gmem_wrData           => cu_gmem_wrData(i),
        --cache read data
        cache_rdAddr          => cache_rdAddr_vec(i mod 2)(i/2),
        cache_rdAck           => cache_rdAck_vec(i mod 2)(i),
        cache_rdData          => cache_rdData_vec(i mod 2)(i/2),
        cache_rdCntrl         => cache_rdCntrl_vec(i mod 2)(i),
        --atomic_rdData         => atomic_rdData_vec(i),
        --atomic_rdData_v       => atomic_rdData_v_vec(i)(i),
        --atomic_sgntr          => atomic_sgntr_vec(i),
  
        gmem_cntrl_idle       => CU_gmem_idle(i)
        -- loc_mem_rdAddr_dummy => loc_mem_rdAddr_dummy(DATA_W*(i+1)-1 downto i*DATA_W)
        );
    end generate;
  end generate;

  compute_units_i_high: for i in N_CU/2 to N_CU-1 generate 
  begin
    compute_unit_inst: entity compute_unit
    generic map (cu_idx => i)
    port map(
      clk                   => clk,
      wf_active             => wf_active(i),
      wf_reach_gsync        => wf_reach_gsync(i),
      WGsDispatched         => WGsDispatched,
      nrst                  => nrst_CUs(i),
      cram_rdAddr           => CU_cram_rdAddr(i),      
      cram_rdData           => cram_rdData2_vec(i-N_CU/2),
      -- cram_rdData           => cram_rdData(i mod CRAM_BLOCKS),
      cram_rqst             => CU_cram_rqst(i),
      cram_rdAddr_conf      => cram_rdAddr2_d0_vec(i-N_CU/2),
      -- cram_rdAddr_conf      => cram_rdAddr_d0(i mod CRAM_BLOCKS),
      start_addr            => start_addr_vec(i),

      start_CUs             => start_CUs_vec(i),
      sch_rqst_n_wfs_m1     => sch_rqst_n_WFs_m1_vec(i),
      sch_rqst              => wg_req_vec(i)(i),
      sch_ack               => wg_ack(i),
      wg_info               => unsigned(wg_info_vec(i)),
      gsync_reached         => gsync_reached,
      rtm_wrAddr_wg         => rtm_wrAddr_wg_vec(i),
      rtm_wrData_wg         => rtm_wrData_wg_vec(i),
      rtm_we_wg             => rtm_we_wg_vec(i),
      rdData_alu_en         => rdData_alu_en(i),
      rdAddr_alu_en         => rdAddr_alu_en(i),

      gmem_valid            => cu_gmem_valid(i),
      gmem_rnw              => cu_gmem_rnw(i),
      gmem_op_type          => cu_gmem_op_type(i),
      gmem_atomic           => cu_gmem_atomic(i),
      gmem_atomic_sgntr     => cu_gmem_atomic_sgntr(i),
      gmem_rqst_addr        => cu_rqst_addr(i),
      gmem_rqst_cntrl       => cu_rqst_cntrl(i),
      gmem_ready            => cu_gmem_ready_out(i),
      gmem_wrData           => cu_gmem_wrData(i),
      --cache read data
      cache_rdAddr          => cache_rdAddr_vec(i mod 2)(i/2),
      cache_rdAck           => cache_rdAck_vec(i mod 2)(i),
      cache_rdData          => cache_rdData_vec(i mod 2)(i/2),
      cache_rdCntrl         => cache_rdCntrl_vec(i mod 2)(i),
      --atomic_rdData         => atomic_rdData_vec(i),
      --atomic_rdData_v       => atomic_rdData_v_vec(i)(i),
      --atomic_sgntr          => atomic_sgntr_vec(i),

      gmem_cntrl_idle       => CU_gmem_idle(i)
      -- loc_mem_rdAddr_dummy => loc_mem_rdAddr_dummy(DATA_W*(i+1)-1 downto i*DATA_W)
      );
  end generate;

  process(clk)
  begin
    if rising_edge(clk) then
      cache_rdAck_vec(cache_rdAck_vec'high) <= cache_rdAck_out;
      cache_rdAck_vec(cache_rdAck_vec'high-1 downto 0) <= cache_rdAck_vec(cache_rdAck_vec'high downto 1);
      cache_rdAddr_vec(cache_rdAddr_vec'high) <= cache_rdAddr_out;
      cache_rdAddr_vec(cache_rdAddr_vec'high-1 downto 0) <= cache_rdAddr_vec(cache_rdAddr_vec'high downto 1);
      cache_rdData_vec(cache_rdData_vec'high) <= cache_rdData_out;
      cache_rdData_vec(cache_rdData_vec'high-1 downto 0) <= cache_rdData_vec(cache_rdData_vec'high downto 1);
      cache_rdCntrl_vec(cache_rdCntrl_vec'high) <= cache_rdCntrl_out;
      cache_rdCntrl_vec(cache_rdCntrl_vec'high-1 downto 0) <= cache_rdCntrl_vec(cache_rdCntrl_vec'high downto 1);
      --atomic_rdData_vec(atomic_rdData_vec'high) <= atomic_rdData;
      --atomic_rdData_vec(atomic_rdData_vec'high-1 downto 0) <= atomic_rdData_vec(atomic_rdData_vec'high downto 1);
      --atomic_rdData_v_vec(atomic_rdData_v_vec'high) <= atomic_rdData_v;
      --atomic_rdData_v_vec(atomic_rdData_vec'high -1 downto 0) <= atomic_rdData_v_vec(atomic_rdData_v_vec'high downto 1);
      --atomic_sgntr_vec(atomic_sgntr_vec'high) <= atomic_sgntr;
      --atomic_sgntr_vec(atomic_sgntr_vec'high-1 downto 0) <= atomic_sgntr_vec(atomic_sgntr_vec'high downto 1);
      start_addr_vec(start_addr_vec'high) <= start_addr;
      if N_CU > 1 then
        start_addr_vec(start_addr_vec'high-1 downto 0) <= start_addr_vec(start_addr_vec'high downto 1);
      end if;
      start_CUs_vec(start_CUs_vec'high) <= start_CUs;
      wg_req_vec(wg_req_vec'high) <= wg_req;
      wg_info_vec(wg_info_vec'high) <= std_logic_vector(wg_info);
      rtm_we_wg_vec(rtm_we_wg_vec'high) <= rtm_we_wg;
      sch_rqst_n_WFs_m1_vec(sch_rqst_n_WFs_m1_vec'high) <= sch_rqst_n_WFs_m1;
      rtm_wrData_wg_vec(rtm_wrData_wg_vec'high) <= rtm_wrData_wg;
      rtm_wrAddr_wg_vec(rtm_wrAddr_wg_vec'high) <= rtm_wrAddr_wg;
      cram_rdData_vec(cram_rdData_vec'high) <= cram_rdData;
      cram_rdAddr_d0_vec(cram_rdAddr_d0_vec'high) <= cram_rdAddr_d0;
      cram_rdData2_vec(cram_rdData2_vec'high) <= cram_rdData2;
      cram_rdAddr2_d0_vec(cram_rdAddr2_d0_vec'high) <= cram_rdAddr2_d0;
      if N_CU > 1 then
        start_CUs_vec(start_CUs_vec'high-1 downto 0) <= start_CUs_vec(start_CUs_vec'high downto 1);
        wg_req_vec(wg_req_vec'high-1 downto 0) <= wg_req_vec(wg_req_vec'high downto 1);
        -- wg_ack_vec(wg_ack_vec'high-1 downto 0) <= wg_ack_vec(wg_ack_vec'high downto 1);
        wg_info_vec(wg_info_vec'high-1 downto 0) <= wg_info_vec(wg_info_vec'high downto 1);
        rtm_wrAddr_wg_vec(rtm_wrAddr_wg_vec'high-1 downto 0) <= rtm_wrAddr_wg_vec(rtm_wrAddr_wg_vec'high downto 1);
        rtm_wrData_wg_vec(rtm_wrData_wg_vec'high-1 downto 0) <= rtm_wrData_wg_vec(rtm_wrData_wg_vec'high downto 1);
        rtm_we_wg_vec(rtm_we_wg_vec'high-1 downto 0) <= rtm_we_wg_vec(rtm_we_wg_vec'high downto 1);
        sch_rqst_n_WFs_m1_vec(sch_rqst_n_WFs_m1_vec'high-1 downto 0) <= sch_rqst_n_WFs_m1_vec(sch_rqst_n_WFs_m1_vec'high downto 1);
        cram_rdData_vec(cram_rdData_vec'high-1 downto 0) <= cram_rdData_vec(cram_rdData_vec'high downto 1);
        cram_rdAddr_d0_vec(cram_rdAddr_d0_vec'high-1 downto 0) <= cram_rdAddr_d0_vec(cram_rdAddr_d0_vec'high downto 1);
        cram_rdData2_vec(cram_rdData2_vec'high-1 downto 0) <= cram_rdData2_vec(cram_rdData_vec'high downto 1);
        cram_rdAddr2_d0_vec(cram_rdAddr2_d0_vec'high-1 downto 0) <= cram_rdAddr2_d0_vec(cram_rdAddr2_d0_vec'high downto 1);
      end if;
      for i in 0 to N_CU-1 loop
        nrst_CUs(i) <= nrst;
      end loop;
    end if;
  end process;
  process(clk)
  begin
    if rising_edge(clk) then
      if to_integer(unsigned(CU_gmem_idle)) = 2**N_CU-1 and (fifo_empty = (fifo_empty'reverse_range=>(0 to CV_SIZE-1=>'1'))) then
        CUs_gmem_idle <= '1';
      else
        CUs_gmem_idle <= '0';
      end if;
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      if nrst = '0' then
        cache_rdAck_out <= (others=>'0');
      else
        cache_rdAck_out <= cache_rdAck_in;
      end if;
      cache_rdCntrl_out <= cache_rdCntrl_in;
      cache_rdData_out <= cache_rdData_in;
      cache_rdAddr_out <= cache_rdAddr_in;
    end if;
  end process;
  -- global memory controller----------------------------------------------------------------------------------- {{{
  gmem_controller_insts: for i in 0 to N_AXI-1 generate
  begin
    gmem_controller_inst: entity gmem_cntrl 
    port map(
      clk               => clk,
      cu_valid          => cu_gmem_valid_out(i*2+1 downto i*2),
      cu_ready          => cu_gmem_ready(i*2+1 downto i*2),
      cu_wready         => cu_gmem_wready(i),
      --cu_we             => cu_gmem_we_out,
      cu_rnw            => cu_gmem_rnw_out(i*2+1 downto i*2),
      --cu_atomic         => cu_gmem_atomic_out(i*2+1 downto i*2),
      --cu_atomic_sgntr   => cu_gmem_atomic_sgntr_out,
      cu_rqst_addr      => cu_rqst_addr_out(i*2+1 downto i*2),
      cu_wvalid         => cu_gmem_wvalid(i),
      cu_wcu_en         => cu_gmem_wcu_en(i),
      cu_wtype          => cu_gmem_wtype(i),
      cu_waddr          => cu_gmem_waddr(i),
      cu_wrData         => cu_gmem_wrData_out(i),
      cu_wrData_ex      => cu_gmem_wrData_ex(i),
      cu_rdCntrl        => cu_rqst_cntrl_out(i*2+1 downto i*2),
      WGsDispatched     => WGsDispatched,
      finish_exec       => finish_exec(i),
      start_kernel      => start_kernel,
      clean_cache       => clean_cache,
      CUs_gmem_idle     => CUs_gmem_idle,

      -- read data from cache
      rdAck             => cache_rdAck_in(i*2+1 downto i*2),
      rdAddr            => cache_rdAddr_in(i),
      rdData            => cache_rdData_in(i),
      rdCntrl           => cache_rdCntrl_in(i*2+1 downto i*2),

      --atomic_rdData     => atomic_rdData_in(i),
      --atomic_rdData_v   => atomic_rdData_v_in(i),
      --atomic_sgntr      => atomic_sgntr_in(i),
      -- read axi bus {{{
      --    ar channel
      axi_araddr        => axi_araddr(i),
      axi_arvalid       => axi_arvalid(i),
      axi_arready       => axi_arready(i),
      axi_arid          => axi_arid(i),
      --    r channel
      axi_rdata         => axi_rdata(i),
      axi_rlast         => axi_rlast(i),
      axi_rvalid        => axi_rvalid(i),
      axi_rready        => axi_rready(i),
      axi_rid           => axi_rid(i),
      --    aw channel
      axi_awaddr        => axi_awaddr(i),
      axi_awvalid       => axi_awvalid(i),
      axi_awready       => axi_awready(i),
      axi_awid          => axi_awid(i),
      --    w channel
      axi_wdata         => axi_wdata(i),
      axi_wstrb         => axi_wstrb(i),
      axi_wlast         => axi_wlast(i),
      axi_wvalid        => axi_wvalid(i),
      axi_wready        => axi_wready(i),
      -- b channel
      axi_bvalid        => axi_bvalid(i),
      axi_bready        => axi_bready(i),
      axi_bid           => axi_bid(i),
      --}}}
      --debug_st          => debug_st_gmem,
      nrst              => nrst_gmem_cntrl
    );
  end generate;
  -- fixed signals assignments {{{
  m0_arlen <= std_logic_vector(to_unsigned(0, m0_arlen'length));
  m0_arsize <= "101"; -- in 2^n bytes,
  m0_arburst  <= "01"; --INCR burst type
  m0_awlen <= std_logic_vector(to_unsigned(0, m0_awlen'length));
  m0_awsize <= "101"; -- in 2^n bytes,
  m0_awburst  <= "01"; --INCR burst type
  --}}}
  -- ar & r assignments {{{
  m0_araddr <= std_logic_vector(axi_araddr(0));
  m0_arvalid <= axi_arvalid(0);
  axi_arready(0) <= m0_arready;
  axi_rdata(0) <= m0_rdata;
  axi_rlast(0) <= m0_rlast;
  axi_rvalid(0) <= m0_rvalid;
  axi_rid(0) <= m0_rid;
  axi_bid(0) <= m0_bid;
  m0_awid <= axi_awid(0);
  m0_rready <= axi_rready(0);
  m0_arid <= axi_arid(0);
  -- }}}
  -- aw, w & b assignments {{{
  m0_awaddr <= std_logic_vector(axi_awaddr(0));
  m0_awvalid <= axi_awvalid(0);
  axi_awready(0) <= m0_awready;
  m0_wdata <= axi_wdata(0);
  m0_wstrb <= axi_wstrb(0);
  m0_wlast <= axi_wlast(0);
  m0_wvalid <= axi_wvalid(0);
  axi_wready(0) <= m0_wready;
  axi_bvalid(0) <= m0_bvalid;
  m0_bready <= axi_bready(0);
  -- }}}
  -- fixed signals assignments {{{
  m1_arlen <= std_logic_vector(to_unsigned(0, m1_arlen'length));
  m1_arsize <= "101"; -- in 2^n bytes,
  m1_arburst  <= "01"; --INCR burst type
  m1_awlen <= std_logic_vector(to_unsigned(0, m1_awlen'length));
  m1_awsize <= "101"; -- in 2^n bytes,
  m1_awburst  <= "01"; --INCR burst type
  --}}}
  -- ar & r assignments {{{
  m1_araddr <= std_logic_vector(axi_araddr(1));
  m1_arvalid <= axi_arvalid(1);
  axi_arready(1) <= m1_arready;
  axi_rdata(1) <= m1_rdata;
  axi_rlast(1) <= m1_rlast;
  axi_rvalid(1) <= m1_rvalid;
  axi_rid(1) <= m1_rid;
  axi_bid(1) <= m1_bid;
  m1_awid <= axi_awid(1);
  m1_rready <= axi_rready(1);
  m1_arid <= axi_arid(1);
  -- }}}
  -- aw, w & b assignments {{{
  m1_awaddr <= std_logic_vector(axi_awaddr(1));
  m1_awvalid <= axi_awvalid(1);
  axi_awready(1) <= m1_awready;
  m1_wdata <= axi_wdata(1);
  m1_wstrb <= axi_wstrb(1);
  m1_wlast <= axi_wlast(1);
  m1_wvalid <= axi_wvalid(1);
  axi_wready(1) <= m1_wready;
  axi_bvalid(1) <= m1_bvalid;
  m1_bready <= axi_bready(1);
  -- }}}
  -- fixed signals assignments {{{
  m2_arlen <= std_logic_vector(to_unsigned(0, m2_arlen'length));
  m2_arsize <= "101"; -- in 2^n bytes,
  m2_arburst  <= "01"; --INCR burst type
  m2_awlen <= std_logic_vector(to_unsigned(0, m2_awlen'length));
  m2_awsize <= "101"; -- in 2^n bytes,
  m2_awburst  <= "01"; --INCR burst type
  --}}}
  -- ar & r assignments {{{
  m2_araddr <= std_logic_vector(axi_araddr(2));
  m2_arvalid <= axi_arvalid(2);
  axi_arready(2) <= m2_arready;
  axi_rdata(2) <= m2_rdata;
  axi_rlast(2) <= m2_rlast;
  axi_rvalid(2) <= m2_rvalid;
  axi_rid(2) <= m2_rid;
  axi_bid(2) <= m2_bid;
  m2_awid <= axi_awid(2);
  m2_rready <= axi_rready(2);
  m2_arid <= axi_arid(2);
  -- }}}
  -- aw, w & b assignments {{{
  m2_awaddr <= std_logic_vector(axi_awaddr(2));
  m2_awvalid <= axi_awvalid(2);
  axi_awready(2) <= m2_awready;
  m2_wdata <= axi_wdata(2);
  m2_wstrb <= axi_wstrb(2);
  m2_wlast <= axi_wlast(2);
  m2_wvalid <= axi_wvalid(2);
  axi_wready(2) <= m2_wready;
  axi_bvalid(2) <= m2_bvalid;
  m2_bready <= axi_bready(2);
  -- }}}
  -- fixed signals assignments {{{
  m3_arlen <= std_logic_vector(to_unsigned(0, m3_arlen'length));
  m3_arsize <= "101"; -- in 2^n bytes,
  m3_arburst  <= "01"; --INCR burst type
  m3_awlen <= std_logic_vector(to_unsigned(0, m3_awlen'length));
  m3_awsize <= "101"; -- in 2^n bytes,
  m3_awburst  <= "01"; --INCR burst type
  --}}}
  -- ar & r assignments {{{
  m3_araddr <= std_logic_vector(axi_araddr(3));
  m3_arvalid <= axi_arvalid(3);
  axi_arready(3) <= m3_arready;
  axi_rdata(3) <= m3_rdata;
  axi_rlast(3) <= m3_rlast;
  axi_rvalid(3) <= m3_rvalid;
  axi_rid(3) <= m3_rid;
  axi_bid(3) <= m3_bid;
  m3_awid <= axi_awid(3);
  m3_rready <= axi_rready(3);
  m3_arid <= axi_arid(3);
  -- }}}
  -- aw, w & b assignments {{{
  m3_awaddr <= std_logic_vector(axi_awaddr(3));
  m3_awvalid <= axi_awvalid(3);
  axi_awready(3) <= m3_awready;
  m3_wdata <= axi_wdata(3);
  m3_wstrb <= axi_wstrb(3);
  m3_wlast <= axi_wlast(3);
  m3_wvalid <= axi_wvalid(3);
  axi_wready(3) <= m3_wready;
  axi_bvalid(3) <= m3_bvalid;
  m3_bready <= axi_bready(3);
  -- }}}
  ------------------------------------------------------------------------------------------------- }}}
  -- WG dispatcher FSM -------------------------------------------------------------------------------------- {{{
  regFile_we <= '1' when mainProc_wrAddr(INTERFCE_W_ADDR_W-1 downto INTERFCE_W_ADDR_W-2) = "10" and mainProc_we = '1' else '0';
  regs_trans: process(clk)
  begin
    if rising_edge(clk) then
      nrst_gmem_cntrl <= nrst;
      if start_kernel = '1' then
        clean_cache <= RcleanCache(new_krnl_indx);
      end if;
      s0_wdata_d0 <= s0_wdata;
      finish_exec_d0 <= and finish_exec;
      
      if nrst = '0' then
        st_wg_disp <= idle;
        Rstat <= (others =>'0');
        RcleanCache <= (others=>'0');
        Rstart <= (others =>'0');
        RInitiate <= (others=>'0');
      else
        st_wg_disp <= st_wg_disp_n;

        -- regFile_we_d0 <= regFile_we;

        if start_kernel = '1' then
          Rstart(new_krnl_indx) <= '0';
        elsif regFile_we = '1' and to_integer(unsigned(mainProc_wrAddr(N_REG_W-1 downto 0))) = Rstart_regFile_addr then
          Rstart <= s0_wdata_d0(NEW_KRNL_MAX_INDX-1 downto 0);
        end if;

        if regFile_we = '1' and to_integer(unsigned(mainProc_wrAddr(N_REG_W-1 downto 0))) = RcleanCache_regFile_addr then
          RcleanCache <= s0_wdata_d0(NEW_KRNL_MAX_INDX-1 downto 0);
        end if;
        if regFile_we = '1' and to_integer(unsigned(mainProc_wrAddr(N_REG_W-1 downto 0))) = RInitiate_regFile_addr then
          RInitiate <= s0_wdata_d0(NEW_KRNL_MAX_INDX-1 downto 0);
        end if;

        if start_kernel = '1' then
          Rstat(new_krnl_indx) <= '0';
        elsif finish_exec = (0 to N_AXI-1=>'1') and finish_exec_d0 = '0' then
          Rstat(finish_krnl_indx) <= '1';
        end if;
      end if;
    end if;
  end process;

  regs_trans_2x: process(clk)
  begin
    if rising_edge(clk) then
      if nrst = '0' then
        gsync_reached <= '1';
        wf_reach_gsync_ltch <= (others=>'0');
        cu_active <= (others=>'0');
      else
        --if wf_reach_gsync = (wf_reach_gsync'reverse_range => '1') then
        --  gsync_reached <= '1';
        --else
        --  gsync_reached <= '0';
        --end if;
        for i in 0 to N_CU-1 loop
          if wf_active(i) /= (0 to N_WF_CU-1=>'0') then
            cu_active(i) <= '1';
          else
            cu_active(i) <= '0';
          end if;
          if cu_active(i) = '1' and wf_reach_gsync(i) = '1' then
            wf_reach_gsync_ltch(i) <= '1';
          elsif (wf_reach_gsync_ltch or (not cu_active)) = (wf_reach_gsync_ltch'reverse_range=>'1') then
            wf_reach_gsync_ltch(i) <= '0';
          end if;
        end loop;
        if (wf_reach_gsync_ltch or (not cu_active)) = (wf_reach_gsync_ltch'reverse_range=>'1') then
          gsync_reached <= '1';
        elsif wf_reach_gsync_ltch /= (wf_reach_gsync_ltch'reverse_range=>'0') then
          gsync_reached <= '0';
        end if;
      end if;
      if start_kernel = '1' then
        initialize_d0 <= RInitiate(new_krnl_indx);
      end if;
    end if;
  end process;

  process(Rstart)
  begin
    new_krnl_indx <= 0;
    for i in NEW_KRNL_MAX_INDX-1 downto 0 loop
      if Rstart(i) = '1' then
        new_krnl_indx <= i;
      end if;
    end loop;
  end process;

  start_kernel <= '1' when st_wg_disp_n = st1_dispatch and st_wg_disp = idle else '0';

  process(st_wg_disp, finish_exec, Rstart)
  begin
    st_wg_disp_n <= st_wg_disp;
    case(st_wg_disp) is
      when idle   =>
        if to_integer(unsigned(Rstart)) /= 0 then --new kernel to start
          st_wg_disp_n <= st1_dispatch;
        end if;
      when st1_dispatch =>
        if finish_exec = (0 to N_AXI-1=>'1') then -- kernel is dispatched
          st_wg_disp_n <= idle;
        end if;
    end case;
  end process;
  ------------------------------------------------------------------------------------------------- }}}
end Behavioral;
