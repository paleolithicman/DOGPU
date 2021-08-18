-- libraries -------------------------------------------------------------------------------------------{{{
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use ieee.float_pkg.all;
use IEEE.MATH_REAL.ALL;
library work;
use work.all;
use work.FGPU_definitions.all;
---------------------------------------------------------------------------------------------------------}}}
entity mcr_wrap is -- {{{
generic(
  cuIdx : integer range 0 to N_CU-1 := 0
  );
port(
  family           : in std_logic_vector(FAMILY_W-1 downto 0) := (others=>'0'); -- level 8.
  code             : in std_logic_vector(CODE_W-1 downto 0) := (others=>'0'); -- level 8.
  wf_indx          : in unsigned(N_WF_CU_W-1 downto 0) := (others=>'0'); -- level 8.
  phase            : in unsigned(PHASE_W-1 downto 0) := (others=>'0'); -- level 8.
  vrs_addr         : in std_logic_vector(WI_REG_ADDR_W-1 downto 0);
  vrd_addr         : in std_logic_vector(WI_REG_ADDR_W-1 downto 0);
  imm              : in std_logic_vector(IMM_W-1 downto 0) := (others=>'0'); -- level 8;
  vsmem            : in std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'0');
  vrs              : in SIMD_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0')); -- level 7.
  vrt              : in SIMD_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0')); -- level 8.
  rx               : in SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  rs               : in SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0')); -- level 8.
  rt               : in SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0')); -- level 8.
  valid            : in std_logic_vector(CV_SIZE-1 downto 0) := (others=>'0');
  wrAddr_in        : in std_logic_vector(FREG_FILE_W-1 downto 0);
  res              : out SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0')); 
  result_valid_p1  : out std_logic_vector(CV_SIZE-1 downto 0) := (others=>'0');
  result_valid     : out std_logic_vector(CV_SIZE-1 downto 0) := (others=>'0');
  vres_out         : out SIMD_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0')); -- level MCR_DELAY
  vwe              : out vreg_we_array(CV_SIZE-1 downto 0) := (others=>(others=>'0')); -- level MCR_DELAY
  vres_addr        : out unsigned(REG_FILE_W-1 downto 0) := (others=>'0'); -- level MCR_DELAY
  nrst             : in std_logic;
  clk              : in std_logic
);

end mcr_wrap; -- }}}
architecture Behavioral of mcr_wrap is
constant MCR_DELAY_I   : integer := 12;
signal res_slct        : std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'0');
type vwe_vec_type is array(natural range<>) of vreg_we_array(CV_SIZE-1 downto 0);
signal vwe_vec         : vwe_vec_type(MCR_DELAY-MCR_DELAY_I-2 downto 0) := (others=>(others=>(others=>'0')));
signal vrs_d0          : SIMD_ARRAY(CV_SIZE-1 downto 0);
signal vrs_d1          : SIMD_ARRAY(CV_SIZE-1 downto 0);
type slv3_array is array(natural range<>) of std_logic_vector(2 downto 0);
signal vres_cvIdx      : slv3_array(CV_SIZE-1 downto 0);
signal cross_lane      : std_logic_vector(CV_SIZE-1 downto 0);
signal cross_lane_v    : std_logic;
type imm_array is array (natural range<>) of std_logic_vector(2 downto 0);
signal imm_vec         : imm_array(MCR_DELAY_I-9 downto 0) := (others=>(others=>'0'));
signal vwe_i           : vreg_we_array(CV_SIZE-1 downto 0);
signal vwe_i_d0        : vreg_we_array(CV_SIZE-1 downto 0);
signal vres_out_i      : SIMD_ARRAY(CV_SIZE-1 downto 0);
signal vres_out_i_d0   : SIMD_ARRAY(CV_SIZE-1 downto 0);
type vres_out_array is array(natural range<>) of SIMD_ARRAY(CV_SIZE-1 downto 0);
signal vres_out_vec    : vres_out_array(MCR_DELAY-MCR_DELAY_I-2 downto 0);
signal res_addr_slct   : unsigned(REG_FILE_W-1 downto 0) := (others=>'0');
signal vres_addr_i     : reg_addr_array(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
signal vres_addr_i_d0  : reg_addr_array(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
signal vres_addr_vec   : reg_addr_array(MCR_DELAY-MCR_DELAY_I-2 downto 0) := (others=>(others=>'0'));
signal vwe_slct        : std_logic_vector(FREG_N_SIMD-1 downto 0) := (others=>'0');
signal vwe_en_slct     : std_logic_vector(2 downto 0) := (others=>'0');
begin

  MCRs: for i in 0 to CV_SIZE-1 generate
    mcr_inst: entity macro_unit generic map(cvIdx => i, cuIdx => cuIdx)
    port map(
      family          => family, -- level 8.
      code            => code, -- level 8.
      wf_indx         => wf_indx, -- level 8.
      phase           => phase, -- level 8.
      vrs_addr        => vrs_addr,
      vrd_addr        => vrd_addr,
      imm             => imm, -- level 8,
      vsmem           => vsmem,
      vrs             => vrs(i), -- level 7.
      vrt             => vrt(i), -- level 8.
      rx              => rx(i),
      rs              => rs(i), -- level 8.
      rt              => rt(i), -- level 8.
      valid           => valid(i),
      wrAddr_in       => wrAddr_in,
      res             => res(i),
      result_valid_p1 => result_valid_p1(i),
      result_valid    => result_valid(i),
      vres_out        => vres_out_i(i), -- level 12
      vwe             => vwe_i(i), -- level 12
      cross_lane      => cross_lane(i), -- level 12
      vres_addr       => vres_addr_i(i), -- level 12
      vres_cvIdx      => vres_cvIdx(i), -- level 12
      nrst            => nrst,
      clk             => clk
    );
  end generate;

  process(clk)
  begin
    if rising_edge(clk) then
      cross_lane_v <= or cross_lane;
      -- imm(7 downto 5): select which lane to pick result for cross lane write
      imm_vec(imm_vec'high) <= imm(7 downto 5);
      imm_vec(imm_vec'high-1 downto 0) <= imm_vec(imm_vec'high downto 1);
      vres_out_i_d0 <= vres_out_i;
      vres_addr_i_d0 <= vres_addr_i;
      res_slct <= vres_out_i(to_integer(unsigned(imm_vec(0)))); -- level 13
      res_addr_slct <= vres_addr_i(to_integer(unsigned(imm_vec(0)))); -- level 13
      vwe_i_d0 <= vwe_i; -- level 13
      vwe_slct <= vwe_i(to_integer(unsigned(imm_vec(0)))); -- level 13
      vwe_en_slct <= vres_cvIdx(to_integer(unsigned(imm_vec(0))));
      if CROSSLANE_IMPLEMENT = 1 and cross_lane_v = '1' then
        vres_addr_vec(vres_addr_vec'high) <= res_addr_slct;
      else
        vres_addr_vec(vres_addr_vec'high) <= vres_addr_i_d0(0);
      end if;
      for i in 0 to CV_SIZE-1 loop
        if CROSSLANE_IMPLEMENT = 1 and cross_lane_v = '1' then
          vres_out_vec(vres_out_vec'high)(i) <= res_slct;
          if i = to_integer(unsigned(vwe_en_slct)) then
            vwe_vec(vwe_vec'high)(i) <= vwe_slct;
          else
            vwe_vec(vwe_vec'high)(i) <= (others=>'0');
          end if;
        else
          vres_out_vec(vres_out_vec'high)(i) <= vres_out_i_d0(i);
          vwe_vec(vwe_vec'high)(i) <= vwe_i_d0(i);
        end if;
      end loop;
      vres_out_vec(vres_out_vec'high-1 downto 0) <= vres_out_vec(vres_out_vec'high downto 1);
      vres_addr_vec(vres_addr_vec'high-1 downto 0) <= vres_addr_vec(vres_addr_vec'high downto 1);
      vwe_vec(vwe_vec'high-1 downto 0) <= vwe_vec(vwe_vec'high downto 1);
    end if;
  end process;

  vres_out <= vres_out_vec(0);
  vres_addr <= vres_addr_vec(0);
  vwe <= vwe_vec(0);

end Behavioral;