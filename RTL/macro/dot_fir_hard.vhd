-- libraries -------------------------------------------------------------------------------------------{{{
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.all;
use work.FGPU_definitions.all;

library altera_fp_functions_181;
USE altera_fp_functions_181.ALL;
---------------------------------------------------------------------------------------------------------}}}
entity macro_unit is -- {{{
generic(
  cvIdx : integer range 0 to CV_SIZE-1 := 0;
  cuIdx : integer range 0 to N_CU-1 := 0
  );
port(
  family           : in std_logic_vector(FAMILY_W-1 downto 0) := (others=>'X'); -- level 8.
  code             : in std_logic_vector(CODE_W-1 downto 0) := (others=>'X'); -- level 8.
  wf_indx          : in unsigned(N_WF_CU_W-1 downto 0); -- level 8.
  phase            : in unsigned(PHASE_W-1 downto 0); -- level 8.
  vrs_addr         : in std_logic_vector(WI_REG_ADDR_W-1 downto 0); -- level 8.
  vrd_addr         : in std_logic_vector(WI_REG_ADDR_W-1 downto 0); -- level 8.
  imm              : in std_logic_vector(IMM_W-1 downto 0); -- level 8;
  vsmem            : in std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'0');
  vrs              : in std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'0'); -- level 7.
  vrt              : in std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'0'); -- level 8.
  rx               : in std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  rs               : in std_logic_vector(DATA_W-1 downto 0) := (others=>'0'); -- level 8.
  rt               : in std_logic_vector(DATA_W-1 downto 0) := (others=>'0'); -- level 8.
  valid            : in std_logic := '0'; -- level 22.
  wrAddr_in        : in std_logic_vector(FREG_FILE_W-1 downto 0) := (others=>'0'); -- level 22.
  res              : out std_logic_vector(DATA_W-1 downto 0) := (others=>'0'); 
  result_valid_p1  : out std_logic := '0';
  result_valid     : out std_logic := '0';
  vres_out         : out std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'0');
  vwe              : out std_logic_vector(FREG_N_SIMD-1 downto 0) := (others=>'0');
  cross_lane       : out std_logic := '0';
  vres_addr        : out unsigned(REG_FILE_W-1 downto 0) := (others=>'0');
  vres_cvIdx       : out std_logic_vector(2 downto 0) := (others=>'0');
  nrst             : in std_logic;
  clk              : in std_logic
);
end macro_unit; -- }}}
architecture Behavioral of macro_unit is
component float_dot_chain8 is
  port (
    clk          : in std_logic;
    dina0        : in std_logic_vector(31 downto 0);
    dina1        : in std_logic_vector(31 downto 0);
    dinb0        : in std_logic_vector(31 downto 0);
    dinb1        : in std_logic_vector(31 downto 0);
    dinc0        : in std_logic_vector(31 downto 0);
    dinc1        : in std_logic_vector(31 downto 0);
    dind0        : in std_logic_vector(31 downto 0);
    dind1        : in std_logic_vector(31 downto 0);
    dine0        : in std_logic_vector(31 downto 0);
    dine1        : in std_logic_vector(31 downto 0);
    dinf0        : in std_logic_vector(31 downto 0);
    dinf1        : in std_logic_vector(31 downto 0);
    ding0        : in std_logic_vector(31 downto 0);
    ding1        : in std_logic_vector(31 downto 0);
    dinh0        : in std_logic_vector(31 downto 0);
    dinh1        : in std_logic_vector(31 downto 0); 
    dout         : out std_logic_vector(31 downto 0)
  );
end component;

component float_dot_acc_chain8 is
  port (
    clk          : in std_logic;
    acc          : in std_logic_vector(31 downto 0);
    dina0        : in std_logic_vector(31 downto 0);
    dina1        : in std_logic_vector(31 downto 0);
    dinb0        : in std_logic_vector(31 downto 0);
    dinb1        : in std_logic_vector(31 downto 0);
    dinc0        : in std_logic_vector(31 downto 0);
    dinc1        : in std_logic_vector(31 downto 0);
    dind0        : in std_logic_vector(31 downto 0);
    dind1        : in std_logic_vector(31 downto 0);
    dine0        : in std_logic_vector(31 downto 0);
    dine1        : in std_logic_vector(31 downto 0);
    dinf0        : in std_logic_vector(31 downto 0);
    dinf1        : in std_logic_vector(31 downto 0);
    ding0        : in std_logic_vector(31 downto 0);
    ding1        : in std_logic_vector(31 downto 0);
    dinh0        : in std_logic_vector(31 downto 0);
    dinh1        : in std_logic_vector(31 downto 0); 
    dout         : out std_logic_vector(31 downto 0)
  );
end component float_dot_acc_chain8;

component dot_red is
    port (
        ax     : in  std_logic_vector(31 downto 0) := (others => 'X'); -- ax
        ay     : in  std_logic_vector(31 downto 0) := (others => 'X'); -- ay
        clk0   : in  std_logic                     := 'X';             -- clk
        clr0   : in  std_logic                     := 'X';             -- clr
        ena    : in  std_logic                     := 'X';             -- ena
        result : out std_logic_vector(31 downto 0)                     -- result
    );
end component dot_red;

function mov_vector (a : in SLV32_ARRAY(FREG_N_SIMD-1 downto 0);
  b : in SLV32_ARRAY(FREG_N_SIMD-1 downto 0);
  off : in std_logic_vector(1 downto 0)) return SLV32_ARRAY is
  variable res : SLV32_ARRAY(FREG_N_SIMD-1 downto 0) := (others=>(others=>'0'));
begin
  if off = "00" then
    for i in cvIdx to FREG_N_SIMD-1 loop
      res(i) := a(i-cvIdx);
    end loop;
    for i in 0 to cvIdx-1 loop
      res(i) := a(FREG_N_SIMD-cvIdx+i);
    end loop;
  elsif off = "01" then
    for i in cvIdx+8 to FREG_N_SIMD-1 loop
      res(i) := a(i-cvIdx-8);
    end loop;
    for i in 0 to cvIdx+7 loop
      res(i) := a(FREG_N_SIMD-cvIdx-8+i);
    end loop;
  elsif off = "10" then
    for i in cvIdx+16 to FREG_N_SIMD-1 loop
      res(i) := a(i-cvIdx-16);
    end loop;
    for i in 0 to cvIdx+15 loop
      res(i) := a(FREG_N_SIMD-cvIdx-16+i);
    end loop;
  elsif off = "11" then
    for i in cvIdx+24 to FREG_N_SIMD-1 loop
      res(i) := a(i-cvIdx-24);
    end loop;
    for i in 0 to cvIdx+23 loop
      res(i) := a(FREG_N_SIMD-cvIdx-24+i);
    end loop;
  end if;
  return(res);
end;

function gen_we (off : in std_logic_vector(2 downto 0)) return std_logic_vector is
  variable res : std_logic_vector(FREG_N_SIMD-1 downto 0) := (others=>'0');
begin
  res := (others=>'0');
  if off(2) = '0' then
    if off(1 downto 0) = "00" then
      for i in cvIdx to FREG_N_SIMD-1 loop
        res(i) := '1';
      end loop;
    elsif off(1 downto 0) = "01" then
      for i in cvIdx+8 to FREG_N_SIMD-1 loop
        res(i) := '1';
      end loop;
    elsif off(1 downto 0) = "10" then
      for i in cvIdx+16 to FREG_N_SIMD-1 loop
        res(i) := '1';
      end loop;
    elsif off(1 downto 0) = "11" then
      for i in cvIdx+24 to FREG_N_SIMD-1 loop
        res(i) := '1';
      end loop;
    end if;
  else
    if off(1 downto 0) = "00" then
      for i in 0 to cvIdx-1 loop
        res(i) := '1';
      end loop;
    elsif off(1 downto 0) = "01" then
      for i in 0 to cvIdx+7 loop
        res(i) := '1';
      end loop;
    elsif off(1 downto 0) = "10" then
      for i in 0 to cvIdx+15 loop
        res(i) := '1';
      end loop;
    elsif off(1 downto 0) = "11" then
      for i in 0 to cvIdx+23 loop
        res(i) := '1';
      end loop;
    end if;
  end if;
  return(res);
end;

signal array_a         : SLV32_ARRAY(FREG_N_SIMD-1 downto 0);
signal array_b         : SLV32_ARRAY(FREG_N_SIMD-1 downto 0);
signal result          : unsigned(DATA_W-1 downto 0);
signal ip_result       : std_logic_vector(DATA_W-1 downto 0);
signal res_vec         : SLV32_ARRAY(DOT_DELAY-16 downto 0);
signal valid_vec       : std_logic_vector(DOT_DELAY-1 downto 0);
signal ffma_result     : SLV32_ARRAY(3 downto 0);
signal subresult       : SLV32_ARRAY(1 downto 0);
signal vres_vec        : SIMD_ARRAY(2 downto 0);
signal mov_out         : SLV32_ARRAY(FREG_N_SIMD-1 downto 0);
signal vwe_vec         : vreg_we_array(3 downto 0);
signal vrs_d0          : SLV32_ARRAY(FREG_N_SIMD-1 downto 0) := (others=>(others=>'0'));
signal vrs_d1          : SLV32_ARRAY(FREG_N_SIMD-1 downto 0) := (others=>(others=>'0'));
signal code_vec        : code_vec_type(13 downto 0) := (others=>(others=>'0'));
signal vres_addr_vec   : reg_addr_array(3 downto 0) := (others=>(others=>'0'));
signal acc             : std_logic_vector(DATA_W-1 downto 0) := (others=>'0');

begin
  process(clk)
  variable mask : unsigned(4 downto 0) := (others=>'0');
  variable mode : std_logic_vector(3 downto 0) := (others=>'0');
  begin
    if rising_edge(clk) then
      code_vec(code_vec'high) <= code; -- @ 9
      code_vec(code_vec'high-1 downto 0) <= code_vec(code_vec'high downto 1); -- @ 10 -> 22
      mask := wrAddr_in(FREG_FILE_W-3) & wrAddr_in(FREG_FILE_W-1) & to_unsigned(cvIdx, 3);
      mode := code_vec(0);
      for i in 0 to FREG_N_SIMD-1 loop
        if ((i >= to_integer(mask)) xor (mode(3) = '1')) or (mode(0) = '1') then
          array_a(i) <= vsmem((i+1)*DATA_W-1 downto i*DATA_W);
        else
          array_a(i) <= (others=>'0');
        end if;
        array_b(i) <= vrs((i+1)*DATA_W-1 downto i*DATA_W);
      end loop;
      if mode(1) = '0' then
        acc <= rx;
      else
        acc <= (others=>'0');
      end if;
    end if;
  end process;
  -- dot_32x_32b_inst : entity dot_32x_32b
  -- port map (
  --     clk     => clk,
  --     valid   => valid,
  --     vec_a   => vector_a,
  --     vec_b   => vector_b,
  --     acc_c   => acc,
  --     result  => ip_result
  -- );
  dot_ffma0_inst: component float_dot_acc_chain8 port map(
      clk       => clk,
      acc       => acc,
      dina0     => array_a(0),
      dina1     => array_b(0),
      dinb0     => array_a(1),
      dinb1     => array_b(1),
      dinc0     => array_a(2),
      dinc1     => array_b(2),
      dind0     => array_a(3),
      dind1     => array_b(3),
      dine0     => array_a(4),
      dine1     => array_b(4),
      dinf0     => array_a(5),
      dinf1     => array_b(5),
      ding0     => array_a(6),
      ding1     => array_b(6),
      dinh0     => array_a(7),
      dinh1     => array_b(7),
      dout      => ffma_result(0)
    );

  dot_ffma_insts: for i in 1 to 3 generate
    dot_ffma_inst: component float_dot_chain8 port map(
      clk       => clk,
      dina0     => array_a(i),
      dina1     => array_b(i),
      dinb0     => array_a(i+1),
      dinb1     => array_b(i+1),
      dinc0     => array_a(i+2),
      dinc1     => array_b(i+2),
      dind0     => array_a(i+3),
      dind1     => array_b(i+3),
      dine0     => array_a(i+4),
      dine1     => array_b(i+4),
      dinf0     => array_a(i+5),
      dinf1     => array_b(i+5),
      ding0     => array_a(i+6),
      ding1     => array_b(i+6),
      dinh0     => array_a(i+7),
      dinh1     => array_b(i+7),
      dout      => ffma_result(i)
    );
  end generate;

  sub_dot_red_inst_0: component dot_red port map(
      ax     => ffma_result(0),
      ay     => ffma_result(1),
      clk0   => clk,
      clr0   => '0',
      ena    => '1',
      result => subresult(0)
  );
  sub_dot_red_inst_1: component dot_red port map(
      ax     => ffma_result(2),
      ay     => ffma_result(3),
      clk0   => clk,
      clr0   => '0',
      ena    => '1',
      result => subresult(1)
  );
  dot_red_inst: component dot_red port map(
      ax     => subresult(0),
      ay     => subresult(1),
      clk0   => clk,
      clr0   => '0',
      ena    => '1',
      result => ip_result
  );

  res <= res_vec(0);

  process (clk)
  begin
    if rising_edge(clk) then
      if nrst = '0' then
        valid_vec <= (others=>'0');
        result_valid <= '0';
        result_valid_p1 <= '0';
      else
        valid_vec(valid_vec'high) <= valid;
        valid_vec(valid_vec'high-1 downto 0) <= valid_vec(valid_vec'high downto 1);
        result_valid <= valid_vec(0);
        result_valid_p1 <= valid_vec(2);
      end if;
      res_vec(res_vec'high) <= ip_result;
      res_vec(res_vec'high-1 downto 0) <= res_vec(res_vec'high downto 1);
    end if;
  end process;

  vres_out <= vres_vec(0);
  vwe <= vwe_vec(0);
  cross_lane <= '0';
  vres_cvIdx <= (others=>'0');
  vres_addr <= vres_addr_vec(0);

  process (clk)
  begin
    if rising_edge(clk) then
      if family = MCR_FAMILY and code = CODE_VRV then
        vwe_vec(vwe_vec'high) <= gen_we(rt(2 downto 0)); -- @ 9
        mov_out <= mov_vector(vrs_d0, vrs_d1, rt(1 downto 0)); -- @ 9
      else
        vwe_vec(vwe_vec'high) <= (others => '0');
      end if;

      for i in 0 to FREG_N_SIMD-1 loop
        vrs_d0(i) <= vrs((i+1)*DATA_W-1 downto i*DATA_W);
      end loop;
      vrs_d1 <= vrs_d0;
      vres_addr_vec(vres_addr_vec'high)(WI_REG_ADDR_W+N_WF_CU_W-1 downto WI_REG_ADDR_W) <= wf_indx; -- @ 9
      vres_addr_vec(vres_addr_vec'high)(WI_REG_ADDR_W+N_WF_CU_W+PHASE_W-2 downto WI_REG_ADDR_W+N_WF_CU_W) <= phase(PHASE_W-1 downto 1); -- @ 9
      vres_addr_vec(vres_addr_vec'high)(WI_REG_ADDR_W+N_WF_CU_W+PHASE_W-1) <= phase(0); -- @ 9
      vres_addr_vec(vres_addr_vec'high)(WI_REG_ADDR_W-1 downto 0) <= unsigned(vrd_addr); -- @ 9
      vres_addr_vec(vres_addr_vec'high-1 downto 0) <= vres_addr_vec(vres_addr_vec'high downto 1); -- @ 10 -> 12
      for i in 0 to FREG_N_SIMD-1 loop
        vres_vec(vres_vec'high)((i+1)*DATA_W-1 downto i*DATA_W) <= mov_out(i); -- @ 10
      end loop;
      vres_vec(vres_vec'high-1 downto 0) <= vres_vec(vres_vec'high downto 1); -- @ 11 -> 12
      vwe_vec(vwe_vec'high-1 downto 0) <= vwe_vec(vwe_vec'high downto 1); -- @ 10 -> 12
    end if;
  end process;

end Behavioral;
