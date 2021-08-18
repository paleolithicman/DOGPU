-- libraries -------------------------------------------------------------------------------------------{{{
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.all;
use work.FGPU_definitions.all;
---------------------------------------------------------------------------------------------------------}}}
entity bitonic_bhv is -- {{{
generic(
  cvIdx : integer range 0 to CV_SIZE-1 := 0;
  cuIdx : integer range 0 to N_CU-1 := 0
  );
port(
  family           : in std_logic_vector(FAMILY_W-1 downto 0) := (others=>'X'); -- level 8.
  code             : in std_logic_vector(CODE_W-1 downto 0) := (others=>'X'); -- level 8.
  wf_indx          : in unsigned(N_WF_CU_W-1 downto 0); -- level 8.
  phase            : in unsigned(PHASE_W-1 downto 0); -- level 8.
  vrd_addr         : in std_logic_vector(WI_REG_ADDR_W-1 downto 0);
  imm              : in std_logic_vector(IMM_W-1 downto 0); -- level 8;
  vsmem            : in std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'0');
  vrs              : in std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'0'); -- level 7.
  vrt              : in std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'0'); -- level 8.
  rx               : in std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  rs               : in std_logic_vector(DATA_W-1 downto 0) := (others=>'0'); -- level 8.
  rt               : in std_logic_vector(DATA_W-1 downto 0) := (others=>'0'); -- level 8.
  valid            : in std_logic := '0';
  wrAddr_in        : in std_logic_vector(FREG_FILE_W-1 downto 0);
  res              : out std_logic_vector(DATA_W-1 downto 0) := (others=>'0'); 
  result_valid_p1  : out std_logic := '0';
  result_valid     : out std_logic := '0';
  vres_out         : out std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'0'); --level 17
  vwe              : out std_logic_vector(FREG_N_SIMD-1 downto 0) := (others=>'0');
  cross_lane       : out std_logic := '0';
  vres_addr        : out unsigned(REG_FILE_W-1 downto 0) := (others=>'0');
  vres_cvIdx       : out std_logic_vector(2 downto 0) := (others=>'0');
  nrst             : in std_logic;
  clk              : in std_logic
);
end bitonic_bhv; -- }}}
architecture Behavioral of bitonic_bhv is
constant VEC_W         : integer := 8;
type signed_array is array(natural range <>) of signed(DATA_W-1 downto 0);

function ina(a : in signed_array(31 downto 0);
  c : in std_logic_vector(2 downto 0)) return signed_array is
  variable res: signed_array(31 downto 0) := (others=>(others=>'0'));
  variable idx: unsigned(4 downto 0) := (others=>'0');
  variable idx_map : unsigned(4 downto 0) := (others=>'0');
begin
  case c is
    when "001" =>
      for i in 0 to 31 loop
        idx := to_unsigned(i, 5);
        idx_map := idx(3) & idx(4) & idx(2 downto 0);
        res(i) := a(to_integer(idx_map));
      end loop;
    when "010" =>
      for i in 0 to 31 loop
        idx := to_unsigned(i, 5);
        idx_map := idx(2) & idx(4 downto 3) & idx(1 downto 0);
        res(i) := a(to_integer(idx_map));
      end loop;
    when "011" =>
      for i in 0 to 31 loop
        idx := to_unsigned(i, 5);
        idx_map := idx(1) & idx(4 downto 2) & idx(0);
        res(i) := a(to_integer(idx_map));
      end loop;
    when "100" =>
      for i in 0 to 31 loop
        idx := to_unsigned(i, 5);
        idx_map := idx(0) & idx(4 downto 1);
        res(i) := a(to_integer(idx_map));
      end loop;
    when others=>
      for i in 0 to 31 loop
        res(i) := a(i);
      end loop;
  end case;
  return res;
end function;

function outa(a : in signed_array(31 downto 0);
  c : in std_logic_vector(2 downto 0)) return signed_array is
  variable res: signed_array(31 downto 0) := (others=>(others=>'0'));
  variable idx: unsigned(4 downto 0) := (others=>'0');
  variable idx_map : unsigned(4 downto 0) := (others=>'0');
begin
  case c is
    when "001" =>
      for i in 0 to 31 loop
        idx := to_unsigned(i, 5);
        idx_map := idx(3) & idx(4) & idx(2 downto 0);
        res(i) := a(to_integer(idx_map));
      end loop;
    when "010" =>
      for i in 0 to 31 loop
        idx := to_unsigned(i, 5);
        idx_map := idx(3 downto 2) & idx(4) &  idx(1 downto 0);
        res(i) := a(to_integer(idx_map));
      end loop;
    when "011" =>
      for i in 0 to 31 loop
        idx := to_unsigned(i, 5);
        idx_map := idx(3 downto 1) & idx(4) &  idx(0);
        res(i) := a(to_integer(idx_map));
      end loop;
    when "100" =>
      for i in 0 to 31 loop
        idx := to_unsigned(i, 5);
        idx_map := idx(3 downto 0) & idx(4);
        res(i) := a(to_integer(idx_map));
      end loop;
    when others=>
      for i in 0 to 31 loop
        res(i) := a(i);
      end loop;
  end case;
  return res;
end function;

function bitonic(a: in signed_array(31 downto 0);
  en : in std_logic;
  flip : in std_logic_vector(15 downto 0);
  c : in std_logic_vector(15 downto 0)) return std_logic_vector is
  variable res_array: signed_array(31 downto 0);
  variable res: std_logic_vector(1023 downto 0);
begin
  -- 0 <-> 32
  for i in 0 to 15 loop
    if (c(i) = '1') xor (en = '1' and (a(i) < a(i+16))) xor (flip(i) = '1') then
      res_array(i) := a(i+16);
      res_array(i+16) := a(i);
    else
      res_array(i) := a(i);
      res_array(i+16) := a(i+16);
    end if;
  end loop;
  for i in 0 to 31 loop
    res((i+1)*32-1 downto i*32) := std_logic_vector(res_array(i));
  end loop;
  return res;
end function;

function get_target(gid: in std_logic_vector(11 downto 0);
  sel: in unsigned(3 downto 0)) return std_logic_vector is
  variable mask: std_logic_vector(11 downto 0);
  variable res: std_logic_vector(11 downto 0);
begin
  case sel is
    when "0000" =>
      mask := X"001";
    when "0001" =>
      mask := X"002";
    when "0010" =>
      mask := X"004";
    when "0011" =>
      mask := X"008";
    when "0100" =>
      mask := X"010";
    when "0101" =>
      mask := X"020";
    when "0110" =>
      mask := X"040";
    when "0111" =>
      mask := X"080";
    when "1000" =>
      mask := X"100";
    when "1001" =>
      mask := X"200";
    when "1010" =>
      mask := X"400";
    when others =>
      mask := X"800";
  end case;
  res := gid xor mask;
  return res;
end function;


signal result                     : std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0);
signal a_array_in                 : signed_array(31 downto 0) := (others=>(others=>'0'));
signal a_array                    : signed_array(31 downto 0) := (others=>(others=>'0'));
signal wf_indx_d0                 : unsigned(N_WF_CU_W-1 downto 0);
signal phase_d0                   : unsigned(PHASE_W-1 downto 0);
signal vrs_d0                     : std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0);
signal valid_in                   : std_logic := '0';
type imm_array is array (natural range<>) of std_logic_vector(IMM_W-1 downto 0);
signal imm_d0                     : std_logic_vector(IMM_W-1 downto 0);
signal rt_d0                      : std_logic_vector(DATA_W-1 downto 0);
signal dir                        : std_logic_vector(15 downto 0);
signal flip                       : std_logic_vector(15 downto 0);
type vres_cvIdx_type is array (natural range<>) of std_logic_vector(2 downto 0);
signal gid_d0                     : std_logic_vector(11 downto 0) := (others=>'0');
signal target_idx                 : std_logic_vector(11 downto 0) := (others=>'0');
signal family_d0                  : std_logic_vector(FAMILY_W-1 downto 0);
signal vrd_addr_d0                : std_logic_vector(WI_REG_ADDR_W-1 downto 0);
signal res_vec                    : SIMD_ARRAY(2 downto 0);
signal vwe_vec                    : vreg_we_array(2 downto 0);
signal vres_addr_vec              : reg_addr_array(2 downto 0);
signal vres_cvIdx_vec             : vres_cvIdx_type(2 downto 0);
signal cross_lane_vec             : std_logic_vector(2 downto 0);
begin
    -- prepare input arrays
  result_valid <= '0';
  result_valid_p1 <= '0';

  process(vrs_d0)
  begin
    for i in 0 to 31 loop
      a_array_in(i) <= signed(vrs_d0((i+1)*DATA_W-1 downto i*DATA_W));
    end loop;
  end process;

  process (clk)
  variable gid : std_logic_vector(11 downto 0) := (others=>'0');
  variable gid_mapped : std_logic_vector(11 downto 0) := (others=>'0');
  begin
    if rising_edge(clk) then
      valid_in <= '0';
      -- delay
      vrs_d0 <= vrs;
      wf_indx_d0 <= wf_indx;
      phase_d0 <= phase;
      imm_d0 <= imm;
      vrd_addr_d0 <= vrd_addr;
      family_d0 <= family;
      -- global tid
      gid := std_logic_vector(to_unsigned(cuIdx, 3)) & std_logic_vector(to_unsigned(cvIdx, 3)) & std_logic_vector(wf_indx) & std_logic_vector(phase);
      gid_mapped := rt(27 downto 16);
      -------------------------------------------------
      -- stage 0, level 9
      -------------------------------------------------
      gid_d0 <= gid;
      rt_d0 <= rt;
      if (family = MCR_FAMILY) and (code = CODE_VRV) then
        -- imm(2 downto 0), swap index within 1 vreg
        -- imm(6 downto 3), stage index within 1 vreg
        a_array <= ina(a_array_in, imm(2 downto 0)); -- level 9
        valid_in <= '1';
        case imm(6 downto 3) is
          when "0000" =>
            flip <= X"5555";
          when "0001" =>
            flip <= X"3333";
          when "0010" =>
            flip <= X"0F0F";
          when "0011" =>
            flip <= X"00FF";
          when "1000" =>
            flip <= X"FFFF";
          when others =>
            flip <= X"0000";
        end case;
        -- rt(3 downto 0), stage index
        -- rt(27 downto 16), mapped tid
        -- rt(31), direction
        -- direction
        if rt(31) = '1' xor gid_mapped(to_integer(unsigned(rt(3 downto 0)))) = '1' then
          dir <= (others=>'1');
        else
          dir <= (others=>'0');
        end if;
        -- position
        --pos <= gid(to_integer(unsigned(rt(3 downto 0))));
        --buf(to_integer(wf_indx & phase)) <= unsigned(rt(3 downto 0));
      elsif (family = "0001") then
        -- copy swap
        -- rt(3 downto 0), swap index
        valid_in <= '0';
        dir <=(others=>'0');
        target_idx <= get_target(gid, rt(3 downto 0));
        a_array <= ina(a_array_in, "000");
        --swap_idx <= buf(to_integer(wf_indx & phase));
        -- imm(0) 0: copy, 1: copy-flip
        -- imm(1) 0: intra-thread, 1: inter-thread
        -- imm(2) 0: store vreg, 1: store half vreg
        -- imm(3) 0: vwe determined
        --     imm(4) 0: store low half, 1: store high half
        -- imm(3) 1: vwe depends on thread id
        --     imm(4) 0: even tid store low/odd tid store high, 1: even tid store high/odd tid store low
        if imm(0) = '0' then
          flip <= (others=>'0');
        else
          flip <= (others=>'1');
        end if;
      end if;

      -------------------------------------------------
      -- stage 1, level 10
      -------------------------------------------------
      -- vres_addr
      if (family_d0 = MCR_FAMILY) then
        -- bitonic swap
        vres_addr_vec(vres_addr_vec'high)(WI_REG_ADDR_W+N_WF_CU_W-1 downto WI_REG_ADDR_W) <= wf_indx_d0;
        vres_addr_vec(vres_addr_vec'high)(WI_REG_ADDR_W+N_WF_CU_W+PHASE_W-2 downto WI_REG_ADDR_W+N_WF_CU_W) <= phase_d0(PHASE_W-1 downto 1);
        vres_addr_vec(vres_addr_vec'high)(WI_REG_ADDR_W+N_WF_CU_W+PHASE_W-1) <= phase_d0(0);
        vres_addr_vec(vres_addr_vec'high)(WI_REG_ADDR_W-1 downto 0) <= unsigned(vrd_addr_d0);
      elsif (family_d0 = "0001") then
        -- copy swap
        if imm_d0(1) = '1' then
          -- cross thread write
          vres_addr_vec(vres_addr_vec'high)(WI_REG_ADDR_W+N_WF_CU_W-1 downto WI_REG_ADDR_W) <= unsigned(target_idx(5 downto 3));
          vres_addr_vec(vres_addr_vec'high)(WI_REG_ADDR_W+N_WF_CU_W+PHASE_W-2 downto WI_REG_ADDR_W+N_WF_CU_W) <= target_idx(2 downto 1);
          vres_addr_vec(vres_addr_vec'high)(WI_REG_ADDR_W+N_WF_CU_W+PHASE_W-1) <= target_idx(0);
          vres_addr_vec(vres_addr_vec'high)(WI_REG_ADDR_W-1 downto 0) <= unsigned(vrd_addr_d0);
        else
          -- write local register
          vres_addr_vec(vres_addr_vec'high)(WI_REG_ADDR_W+N_WF_CU_W-1 downto WI_REG_ADDR_W) <= wf_indx_d0;
          vres_addr_vec(vres_addr_vec'high)(WI_REG_ADDR_W+N_WF_CU_W+PHASE_W-2 downto WI_REG_ADDR_W+N_WF_CU_W) <= phase_d0(PHASE_W-1 downto 1);
          vres_addr_vec(vres_addr_vec'high)(WI_REG_ADDR_W+N_WF_CU_W+PHASE_W-1) <= phase_d0(0);
          vres_addr_vec(vres_addr_vec'high)(WI_REG_ADDR_W-1 downto 0) <= unsigned(vrd_addr_d0);
        end if;
      end if;

      -- vwe
      vwe_vec(vwe_vec'high) <= (others=>'0');
      if (family_d0 = MCR_FAMILY) then
        vwe_vec(vwe_vec'high) <= (others=>'1');
      elsif family_d0 = "0001" then
        if imm_d0(2) = '0' then
          -- store full vreg
          vwe_vec(vwe_vec'high) <= (others=>'1');
        else
          -- store half vreg
          if imm_d0(3) = '0' then
            -- vwe determined
            if imm_d0(4) = '0' then
              -- store low half
              vwe_vec(vwe_vec'high)(FREG_N_SIMD/2-1 downto 0) <= (others=>'1');
              vwe_vec(vwe_vec'high)(FREG_N_SIMD-1 downto FREG_N_SIMD/2) <= (others=>'0');
            else
              -- store high half
              vwe_vec(vwe_vec'high)(FREG_N_SIMD/2-1 downto 0) <= (others=>'0');
              vwe_vec(vwe_vec'high)(FREG_N_SIMD-1 downto FREG_N_SIMD/2) <= (others=>'1');
            end if;
          else
            -- vwe depends on thread id
            if (imm_d0(4) = '0') xor (gid_d0(to_integer(unsigned(rt_d0(3 downto 0)))) = '1') then
              -- store low half
              vwe_vec(vwe_vec'high)(FREG_N_SIMD/2-1 downto 0) <= (others=>'1');
              vwe_vec(vwe_vec'high)(FREG_N_SIMD-1 downto FREG_N_SIMD/2) <= (others=>'0');
            else
              -- store high half
              vwe_vec(vwe_vec'high)(FREG_N_SIMD/2-1 downto 0) <= (others=>'0');
              vwe_vec(vwe_vec'high)(FREG_N_SIMD-1 downto FREG_N_SIMD/2) <= (others=>'1');
            end if;
          end if;
        end if;
      end if;

      -- bitonic swap
      res_vec(res_vec'high) <= bitonic(a_array, valid_in, flip, dir); -- level 10

      -- crosslane address
      cross_lane_vec(cross_lane_vec'high) <= '0';
      vres_cvIdx_vec(vres_cvIdx_vec'high) <= cvIdx;
      if family_d0 = "0001" and imm_d0(1) = '1' then
        if unsigned(rt_d0(3 downto 0)) > 5 then
          -- cross lane
          vres_cvIdx_vec(vres_cvIdx_vec'high) <= target_idx(8 downto 6);
          cross_lane_vec(cross_lane_vec'high) <= '1';
        end if;
      end if;

      -------------------------------------------------
      -- level 11 -> level 12
      -------------------------------------------------
      res_vec(res_vec'high-1 downto 0) <= res_vec(res_vec'high downto 1);
      vres_addr_vec(vres_addr_vec'high-1 downto 0) <= vres_addr_vec(vres_addr_vec'high downto 1);
      cross_lane_vec(cross_lane_vec'high-1 downto 0) <= cross_lane_vec(cross_lane_vec'high downto 1);
      vres_cvIdx_vec(vres_cvIdx_vec'high-1 downto 0) <= vres_cvIdx_vec(vres_cvIdx_vec'high downto 1);
      vwe_vec(vwe_vec'high-1 downto 0) <= vwe_vec(vwe_vec'high downto 1);
    end if;
  end process;

  vwe <= vwe_vec(0);
  vres_out <= res_vec(0);
  vres_addr <= vres_addr_vec(0);
  cross_lane <= cross_lane_vec(0);
  vres_cvIdx <= vres_cvIdx_vec(0);
end Behavioral;
