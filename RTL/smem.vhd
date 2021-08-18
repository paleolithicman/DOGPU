-- libraries -------------------------------------------------------------------------------------------{{{
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.all;
use work.FGPU_definitions.all;
---------------------------------------------------------------------------------------------------------}}}
entity smem is --{{{
port (
  clk                 : in std_logic;
  rqst, we            : in std_logic; -- level 17.
  cv_alu_en           : in std_logic_vector(CV_SIZE-1 downto 0);
  cv_op_type          : in std_logic_vector(2 downto 0); -- level 17.
  wrData              : in std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0);
  regFile_wrAddr      : out unsigned(FREG_FILE_W downto 0) := (others=>'0');
  regFile_we          : out std_logic_vector(CV_SIZE-1 downto 0) := (others=>'0');
  regFile_wrData      : out SLV32_ARRAY(CV_SIZE-1 downto 0);
  regFile_wrAddr_wide : out unsigned(FREG_FILE_W downto 0) := (others=>'0'); -- level 20
  regFile_we_wide     : out std_logic_vector(CV_SIZE-1 downto 0) := (others=>'0'); -- level 20
  regFile_wv_wide_p1  : out std_logic; -- level 18
  regFile_wrData_wide : out std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0); -- level 20
  regFile_wv          : out std_logic;
  cv_rsp_granted      : in std_logic;
  cv_addr             : in gmem_addr_array(CV_SIZE-1 downto 0);
  rd_addr             : in unsigned(FREG_FILE_W downto 0) := (others=>'0');
  wf_finish           : out std_logic_vector(N_WF_CU-1 downto 0) := (others=>'X');
  nrst                : in std_logic;

  -- smem dot
  vreg_busy           : in std_logic;
  rd_addr2            : in unsigned(FREG_FILE_W downto 0) := (others=>'0'); -- level 17.
  dot_addr            : out unsigned(FREG_FILE_W downto 0) := (others=>'0'); -- level 17.
  regFile_wrAddr_p2   : out unsigned(FREG_FILE_W downto 0) := (others=>'0'); -- level 17.

  debug_st            : out std_logic_vector(127 downto 0) := (others=>'0')
);
end smem; --}}}
architecture basic of smem is
signal buf                                  : SIMD_ARRAY(511 downto 0);
signal cv_addr_d0                           : gmem_addr_array(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
signal rqst_d0                              : std_logic;
signal we_d0                                : std_logic;
signal wrData_d0                            : std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0);
signal cv_op_type_d0                        : std_logic_vector(2 downto 0);
signal buf_rdData                           : std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0);
signal rd_addr_d0, rd_addr_d1               : unsigned(FREG_FILE_W downto 0) := (others=>'0');
signal regFile_wv_wide_p0                   : std_logic;
begin
process(clk)
variable idx : integer range 0 to 511;
variable offset : integer range 0 to 3;
begin
  if rising_edge(clk) then
    idx := to_integer(unsigned(cv_addr_d0(0)(15 downto 7)));
    offset := to_integer(unsigned(cv_addr_d0(0)(6 downto 5)));
    cv_addr_d0 <= cv_addr;
    wrData_d0 <= wrData;
    cv_op_type_d0 <= cv_op_type;
    rd_addr_d0 <= rd_addr;
    if nrst = '0' then
      rqst_d0 <= '0';
      we_d0 <= '0';
      regFile_we_wide <= (others=>'0');
      regFile_wv_wide_p1 <= '0';
      regFile_wv_wide_p0 <= '0';
    else
      rqst_d0 <= rqst;
      we_d0 <= we;
      if rqst = '1' and cv_op_type(2) = '0' then
        regFile_wv_wide_p1 <= '1';
      else
        regFile_wv_wide_p1 <= '0';
      end if;
      regFile_wv_wide_p0 <= regFile_wv_wide_p1;
      if regFile_wv_wide_p0 = '1' then
        regFile_we_wide <= (others=>'1');
      else
        regFile_we_wide <= (others=>'0');
      end if;
    end if;
    if rqst_d0 = '1' and we_d0 = '1' then
      buf(idx) <= wrData_d0;
    end if;

    if rqst_d0 = '1' and cv_op_type_d0(2) = '0' then
      buf_rdData <= buf(idx);
      rd_addr_d1 <= rd_addr_d0;
    end if;
    regFile_wrData_wide <= buf_rdData;
    regFile_wrAddr_wide <= rd_addr_d1;
  end if;
end process;
regFile_wrAddr_p2 <= rd_addr;
dot_addr <= rd_addr2;
regFile_wrAddr <= (others=>'0');
regFile_we <= (others=>'0');
regFile_wrData <= (others=>(others=>'0'));
regFile_wv <= '0';
wf_finish <= (others=>'0');
debug_st <= (others=>'0');
end architecture;

