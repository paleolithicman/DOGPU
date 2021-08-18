-- libraries -------------------------------------------------------------------------------------------{{{
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.all;
use work.FGPU_definitions.all;
---------------------------------------------------------------------------------------------------------}}}
entity ALU is -- {{{
generic (alu_idx : integer range 0 to CV_SIZE-1);
port(
  rs_addr             : in unsigned(REG_FILE_BLOCK_W-1 downto 0); -- level 1.
  rt_addr             : in unsigned(REG_FILE_BLOCK_W-1 downto 0); -- level 1.
  rd_addr             : in unsigned(REG_FILE_BLOCK_W-1 downto 0); -- level 1.
  regBlock_re         : in std_logic_vector(N_REG_BLOCKS-1 downto 0); -- level 1.
  mrs_addr            : in unsigned(REG_FILE_BLOCK_W-1 downto 0); -- level 1.
  mrt_addr            : in unsigned(REG_FILE_BLOCK_W-1 downto 0); -- level 1.
  mrx_addr            : in unsigned(REG_FILE_W-1 downto 0) := (others=>'0');
  mregBlock_re        : in std_logic_vector(N_REG_BLOCKS-1 downto 0); -- level 1.

  vrx_addr            : in unsigned(FREG_FILE_W-1 downto 0) := (others=>'0');
  vra_addr            : in unsigned(FREG_FILE_BLOCK_W-1 downto 0); -- level 1.
  vrb_addr            : in unsigned(FREG_FILE_BLOCK_W-1 downto 0); -- level 1.
  --csr                 : in std_logic_vector(DATA_W-1 downto 0); -- level 8.
  vregBlock_re        : in std_logic_vector(N_FREG_BLOCKS-1 downto 0); -- level 1.
  vra_re              : in std_logic; -- level 1.

  family              : in std_logic_vector(FAMILY_W-1 downto 0); -- level 1.

  op_arith_shift      : in op_arith_shift_type; -- level 6.
  code                : in std_logic_vector(CODE_W-1 downto 0); -- level 6.
  immediate           : in std_logic_vector(IMM_W-1 downto 0); -- level 6.
  immediate2          : in std_logic_vector(8 downto 0); -- level 6.
  swc_offset          : in std_logic_vector(FREG_N_SIMD_W-CV_W-1 downto 0); -- level 6.

  rd_out              : out std_logic_vector(DATA_W-1 downto 0) := (others=>'0'); -- level 10.
  vrd_out             : out std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'0'); -- level 10
  reg_we_mov          : out std_logic := '0'; -- level 10.
  
  float_a             : out std_logic_vector(DATA_W-1 downto 0) := (others=>'0'); -- level 8.
  float_b             : out std_logic_vector(DATA_W-1 downto 0) := (others=>'0'); -- level 8.
  float_c             : out std_logic_vector(DATA_W-1 downto 0) := (others=>'0'); -- level 9.

  mrs                 : out std_logic_vector(DATA_W-1 downto 0) := (others=>'0'); -- level 8.
  mrt                 : out std_logic_vector(DATA_W-1 downto 0) := (others=>'0'); -- level 8.
  mrx                 : out std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  vrs_out             : out std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'0'); -- level 7.
  vrt_out             : out std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'0'); -- level 8.

  op_vmem_v           : in std_logic; -- level 7
  op_logical_v        : in std_logic := '0'; -- level 14.
  op_activate_v       : in std_logic := '0'; -- level 14.
  res_low             : out std_logic_vector(DATA_W-1 downto 0) := (others=>'0'); -- level 16.
  res_high            : out std_logic_vector(DATA_W-1 downto 0) := (others=>'0'); -- level 16.
  res_sum             : out std_logic_vector(DATA_W-1 downto 0) := (others=>'0'); -- level 16.
  res_sum2            : out std_logic_vector(DATA_W-1 downto 0) := (others=>'0'); -- level 12.
  res_act             : out std_logic_vector(DATA_W-1 downto 0) := (others=>'0'); -- level 17

  reg_wrData          : in slv32_array(N_REG_BLOCKS-1 downto 0) := (others=>(others=>'0'));  -- level 18.
  reg_wrAddr          : in reg_file_block_array(N_REG_BLOCKS-1 downto 0) := (others=>(others=>'0')); -- level 18.
  reg_we              : in std_logic_vector(N_REG_BLOCKS-1 downto 0) := (others=>'0');  -- level 18.

  mreg_wrData         : in slv32_array(N_REG_BLOCKS-1 downto 0) := (others=>(others=>'0'));
  mreg_wrAddr         : in reg_file_block_array(N_REG_BLOCKS-1 downto 0) := (others=>(others=>'0'));
  mreg_we             : in std_logic_vector(N_REG_BLOCKS-1 downto 0) := (others=>'0');

  freg_wrData         : in simd_array(N_FREG_BLOCKS-1 downto 0) := (others=>(others=>'0'));  -- level 18.
  freg_wrAddr         : in freg_file_block_array(N_FREG_BLOCKS-1 downto 0) := (others=>(others=>'0')); -- level 18.
  freg_we             : in vreg_we_array(N_FREG_BLOCKS-1 downto 0) := (others=>(others=>'0'));  -- level 18.

  nrst                : in std_logic;
  clk                 : in std_logic
);
end ALU; -- }}}
architecture Behavioral of ALU is
  constant pad                            : std_logic_vector(FREG_N_SIMD*DATA_W-1 downto DATA_W) := (others=>'0');
  -- signals definitions {{{
  type regBlock_re_vec_type is array(natural range <>) of std_logic_vector(N_REG_BLOCKS-1 downto 0);
  type vregBlock_re_vec_type is array(natural range <>) of std_logic_vector(N_FREG_BLOCKS-1 downto 0);
  signal regBlock_re_vec                  : regBlock_re_vec_type(6 downto 0) := (others=>(others=>'0'));
  signal mregBlock_re_vec                 : regBlock_re_vec_type(6 downto 0) := (others=>(others=>'0'));
  signal vregBlock_re_vec                 : vregBlock_re_vec_type(6 downto 0) := (others=>(others=>'0'));
  -- attribute max_fanout of regBlock_re_vec : signal is 50;
  signal rs_vec, rt_vec, rd_vec           : slv32_array(N_REG_BLOCKS-1 downto 0) := (others=>(others=>'0'));
  signal mrs_vec, mrt_vec, mrx_vec        : slv32_array(N_REG_BLOCKS-1 downto 0) := (others=>(others=>'0'));
  -- signal frs_vec, frt_vec, frd_vec        : simd_array(N_FREG_BLOCKS-1 downto 0) := (others=>(others=>'0'));
  signal vrout_vec                        : simd_array(N_FREG_BLOCKS-1 downto 0) := (others=>(others=>'0'));
  signal vres_vrv, vres_vvv, vres_rv      : std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'0');
  signal vwe_vrv, vwe_vvv, vwe_rv         : std_logic_vector(FREG_N_SIMD-1 downto 0) := (others=>'0');
  signal vrs, vrs_d0                      : std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'0');
  signal vrs_d1                           : slv32_array(FREG_N_SIMD-1 downto 0);
  signal vrt                              : std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others=>'0');
  signal rs_a, rt_a                       : std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  signal rs_b, rt_b                       : std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  signal a, a_p0, c, c_d0                 : std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  signal vec_off                          : std_logic_vector(FREG_N_SIMD_W-1 downto 0);
  signal b, b_shifted                     : std_logic_vector(DATA_W downto 0) := (others=>'0');
  signal sra_sign                         : std_logic_vector(DATA_W downto 0) := (others=>'0');
  signal sra_sign_v                       : std_logic := '0';
  signal rs, rt, rd, rt_p0, rt_d0         : std_logic_vector(DATA_W-1 downto 0) := (others => '0');
  signal mrt_p0                           : std_logic_vector(DATA_W-1 downto 0) := (others => '0');
  signal frs, frt, frd, frt_p0            : std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others => '0');
  signal shift                            : std_logic_vector(5 downto 0) := (others=>'0');
  signal ignore                           : std_logic_vector(47-DATA_W-1 downto 0) := (others=>'0');
  signal sub_op                           : std_logic := '0';
  signal ce                               : std_logic := '0';
  signal res_p0                           : std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  type immediate_vec_type is array(natural range <>) of std_logic_vector(IMM_W-1 downto 0);
  signal immediate_vec                    : immediate_vec_type(3 downto 0) := (others=>(others=>'0'));
  signal immediate2_d0                    : std_logic_vector(8 downto 0);
  signal immediate2_d1                    : std_logic_vector(15 downto 0);
  type swc_offset_array is array (natural range <>) of std_logic_vector(FREG_N_SIMD_W-CV_W-1 downto 0);
  signal swc_offset_vec                   : swc_offset_array(3 downto 0) := (others=>(others=>'0'));
  type op_arith_shift_vec_type is array(natural range <>) of op_arith_shift_type;
  signal op_arith_shift_vec               : op_arith_shift_vec_type(2 downto 0) := (others => op_add);
  signal rs_addr_vec, rt_addr_vec         : reg_file_block_array(3 downto 0) := (others=>(others=>'0'));
  signal mrs_addr_vec, mrt_addr_vec       : reg_file_block_array(3 downto 0) := (others=>(others=>'0'));
  signal rd_addr_vec                      : reg_file_block_array(3 downto 0) := (others=>(others=>'0'));
  signal vra_re_vec                       : std_logic_vector(4 downto 0);
  signal vra_addr_vec                     : freg_file_block_array(1 downto 0) := (others=>(others=>'0'));
  signal vrb_addr_vec                     : freg_file_block_array(1 downto 0) := (others=>(others=>'0'));
  signal vrx_addr_vec                     : freg_file_block_array(1 downto 0) := (others=>(others=>'0'));
  signal frs_addr_vec, frt_addr_vec       : freg_file_block_array(3 downto 0) := (others=>(others=>'0'));
  signal frd_addr_vec                     : freg_file_block_array(3 downto 0) := (others=>(others=>'0'));
  type code_vec_type is array(natural range<>) of std_logic_vector(CODE_W-1 downto 0);
  signal code_vec                         : code_vec_type(2 downto 0) := (others=>(others=>'0'));
  signal res_low_p0                       : std_logic_vector(DATA_W-1 downto 0) := (others=>'0'); -- level 8
  signal res_logical                      : std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  signal res_logical_vec                  : SLV32_ARRAY(4 downto 0) := (others=>(others=>'0'));
  signal op_logical_v_d0                  : std_logic := '0';
  signal op_vmem_v_d0, op_vmem_v_d1       : std_logic;
  signal a_logical, b_logical             : std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  signal res_activate                     : std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  signal res_relu                         : std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  signal res_relu_vec                     : SLV32_ARRAY(3 downto 0) := (others=>(others=>'0'));
  signal sum_ab                           : std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  signal res_sum_vec                      : SLV32_ARRAY(3 downto 0) := (others=>(others=>'0'));
  signal res_sum2_vec                     : SLV32_ARRAY(6 downto 0) := (others=>(others=>'0'));
  signal op_activate_v_d0                 : std_logic := '0';
  signal op_activate_v_d1                 : std_logic := '0';
  signal a_activate, b_activate           : std_logic_vector(DATA_W-1 downto 0) := (others=>'0');
  signal instr_is_slt, instr_is_sltu      : std_logic_vector(5 downto 0) := (others=>'0');
  signal sltu_true                        : std_logic := '0';
  signal rt_zero                          : std_logic := '0';
  signal rs_zero                          : std_logic := '0';

  signal mrx_addr_d1                      : unsigned(REG_FILE_W-1 downto 0);
  signal mrx_addr_d2                      : unsigned(REG_FILE_W-1 downto 0);
  signal mrx_addr_d3                      : unsigned(REG_FILE_W-1 downto 0);
  signal mrx_addr_d4                      : unsigned(REG_FILE_W-1 downto 0);
  signal vrx_addr_d1                      : unsigned(FREG_FILE_W-1 downto 0);
  signal vrx_addr_d2                      : unsigned(FREG_FILE_W-1 downto 0);
  signal vrx_addr_d3                      : unsigned(FREG_FILE_W-1 downto 0);
  signal vrx_addr_d4                      : unsigned(FREG_FILE_W-1 downto 0);

  signal op_vr_v_d0                       : std_logic;
  signal op_vvv_v_d0                      : std_logic;
  signal op_vrv_v_vec                     : std_logic_vector(8 downto 0);
  signal op_rv_v_vec                      : std_logic_vector(8 downto 0);
  signal res_vr                           : std_logic_vector(DATA_W-1 downto 0);
  --}}}
begin
  -- regFiles -------------------------------------------------------------------------------------------{{{
  reg_blocks: for i in 0 to N_REG_BLOCKS-1 generate
  begin
    reg_file: entity regFile generic map (reg_file_block_width => REG_FILE_BLOCK_W, reg_file_data_width => DATA_W) 
    port map (
      rs_addr => rs_addr_vec(rs_addr_vec'high-i), -- level i+2.
      rt_addr  => rt_addr_vec(rt_addr_vec'high-i), -- level i+2.
      rd_addr  => rd_addr_vec(rd_addr_vec'high-i), -- level i+2.
      re => regBlock_re_vec(regBlock_re_vec'high)(i), -- level i+2.

      rs => rs_vec(i), -- level i+7.
      rt => rt_vec(i), -- level i+6.
      rd => rd_vec(i), -- level i+8.

      we => reg_we(i), -- level 18.
      wrAddr => reg_wrAddr(i), --  level 18.
      wrData => reg_wrData(i), -- level 18.

      mrs_addr  => mrs_addr_vec(mrs_addr_vec'high-i), -- level i+2.
      mrt_addr  => mrt_addr_vec(mrt_addr_vec'high-i), -- level i+2.
      mrx_addr  => mrx_addr(REG_FILE_BLOCK_W-1 downto 0),
      mre       => mregBlock_re_vec(mregBlock_re_vec'high)(i),

      mrs => mrs_vec(i), -- level i+7.
      mrt => mrt_vec(i), -- level i+6.
      mrx => mrx_vec(i),

      mwe => mreg_we(i),
      mwrAddr => mreg_wrAddr(i),
      mwrData => mreg_wrData(i),

      clk => clk
    );
  end generate;

  freg_blocks: for i in 0 to N_FREG_BLOCKS-1 generate
    begin
    freg_file: entity regFile_dp
    port map (
      rx_addr => vrx_addr_vec(vra_addr_vec'high-i)(9 downto 5) & vrx_addr_vec(vra_addr_vec'high-i)(3 downto 0),
      rb_addr => vrb_addr_vec(vrb_addr_vec'high-i)(9 downto 5) & vrb_addr_vec(vrb_addr_vec'high-i)(3 downto 0),
      rout    => vrout_vec(i),
      re      => vregBlock_re_vec(vregBlock_re_vec'high)(i), -- level i+2

      we      => freg_we(i),
      wrAddr  => freg_wrAddr(i)(9 downto 5) & freg_wrAddr(i)(3 downto 0),
      wrData  => freg_wrData(i),

      clk     => clk
    );
  end generate;

  ---------------------------------------------------------------------------------------------------------}}}
  -- logical  -------------------------------------------------------------------------------------------{{{
  process(clk)
  begin
    if rising_edge(clk) then
      res_logical_vec(res_logical_vec'high) <= res_logical; -- @ 11.
      res_logical_vec(res_logical_vec'high-1 downto 0) <= res_logical_vec(res_logical_vec'high downto 1); -- @ 12.->15.
      op_logical_v_d0 <= op_logical_v; -- @ 15.

      a_logical <= rs; --@ 9.
      if code_vec(code_vec'high-1)(0) = '1' then -- level 8.
        b_logical(DATA_W-1 downto IMM_ARITH_W) <= (others=>'0'); -- @ 9.
        b_logical(IMM_ARITH_W-1 downto 0) <= immediate_vec(immediate_vec'high-1)(IMM_ARITH_W-1 downto 0); -- @ 9.
      else
        b_logical <= rt; -- @ 9.
      end if;

      res_logical <= a_logical and b_logical; -- @ 10.
      if code_vec(code_vec'high-2)(1) = '1' then -- level 9.
        res_logical <= a_logical or b_logical; -- @ 10.
      end if;
      if code_vec(code_vec'high-2)(2) = '1' then
        res_logical <= a_logical xor b_logical; -- @ 10.
      end if;
      if code_vec(code_vec'high-2)(3) = '1' then
        res_logical <= a_logical nor b_logical; -- @ 10.
      end if;
    end if;
  end process;
  ---------------------------------------------------------------------------------------------------------}}}
  -- activation -------------------------------------------------------------------------------------------{{{
  process(clk)
  begin
    if rising_edge(clk) then
    -- relu ----------------------------------------------------------------------------------------------{{{{
      res_relu_vec(res_relu_vec'high) <= res_relu; -- @ 11.
      res_relu_vec(res_relu_vec'high-1 downto 0) <= res_relu_vec(res_relu_vec'high downto 1); -- @ 12.->14.
      op_activate_v_d0 <= op_activate_v; -- @ 15.
      op_activate_v_d1 <= op_activate_v_d0; -- @ 16.

      a_activate <= rs; --@ 9.

      if a_activate(a_activate'high) = '0' then-- level 9.
        res_relu <= a_activate; -- @ 10.
      else
        res_relu <= (others=>'0'); -- @ 10.
      end if;
    ------------------------------------------------------------------------------------------------------}}}}

      res_activate <= res_relu_vec(0); -- @ 15.
    end if;
  end process;      
  ---------------------------------------------------------------------------------------------------------}}}
  -- output mux -------------------------------------------------------------------------------------------{{{
  process(clk)
  begin
    if rising_edge(clk) then
      --op_vr_v_d0 <= op_vr_v;
      if op_logical_v_d0 = '1' then -- level 15.
        res_low <= res_logical_vec(0); -- @ 16.
      elsif op_activate_v_d0 = '1' then
        res_low <= res_activate;
      --elsif VR_IMPLEMENT /= 0 and op_vr_v_d0 = '1' then
      --  res_low <= res_vr;
      else
        if instr_is_slt(0) = '1' then -- level 15.
          res_low <= (others=>'0'); 
          res_low(0) <= res_low_p0(res_low_p0'high); -- @ 16.
        elsif instr_is_sltu(0) = '1' then -- level 15.
          res_low <= (others=>'0');
          res_low(0) <= sltu_true; -- @ 16.
        else
          res_low <= res_low_p0; -- @ 16.
        end if;
      end if;

      -- if op_activate_v_d1 = '1' then -- level 16.
      --   res_act <= res_activate; -- @ 17.
      -- end if;
    end if;
  end process;
  ---------------------------------------------------------------------------------------------------------}}}
  -- pipelines & muxes ------------------------------------------------------------------------------------{{{
  vrs_out <= vrs;
  vrt_out <= vrt;
  float_a <= rs; -- @ 8.
  float_b <= rt; -- @ 8.
  process(vra_re_vec, vra_addr_vec, vrx_addr)
  begin
    for i in 0 to N_FREG_BLOCKS-1 loop
      if vra_re_vec(vra_re_vec'high-i) = '1' then
        vrx_addr_vec(vrx_addr_vec'high-i) <= vra_addr_vec(vra_addr_vec'high-i);
      else
        vrx_addr_vec(vrx_addr_vec'high-i) <= vrx_addr(FREG_FILE_BLOCK_W-1 downto 0);
      end if;
    end loop;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      -- pipes {{{
      rs_addr_vec(rs_addr_vec'high-1 downto 0) <= rs_addr_vec(rs_addr_vec'high downto 1); -- @ 1.->2.
      rt_addr_vec(rt_addr_vec'high-1 downto 0) <= rt_addr_vec(rt_addr_vec'high downto 1); -- @ 1.->2.
      rd_addr_vec(rd_addr_vec'high-1 downto 0) <= rd_addr_vec(rd_addr_vec'high downto 1); -- @ 1.->2.
      rs_addr_vec(rs_addr_vec'high) <= rs_addr; -- @ 2.
      rt_addr_vec(rt_addr_vec'high) <= rt_addr; -- @ 2.
      rd_addr_vec(rd_addr_vec'high) <= rd_addr; -- @ 2.

      mrs_addr_vec(mrs_addr_vec'high-1 downto 0) <= mrs_addr_vec(mrs_addr_vec'high downto 1); -- @ 1.->2.
      mrt_addr_vec(mrt_addr_vec'high-1 downto 0) <= mrt_addr_vec(mrt_addr_vec'high downto 1); -- @ 1.->2.
      mrs_addr_vec(mrs_addr_vec'high) <= mrs_addr; -- @ 2.
      mrt_addr_vec(mrt_addr_vec'high) <= mrt_addr; -- @ 2.

      vrb_addr_vec(vrb_addr_vec'high-1 downto 0) <= vrb_addr_vec(vrb_addr_vec'high downto 1); -- @ 1.->2.

      vra_addr_vec(vra_addr_vec'high-1 downto 0) <= vra_addr_vec(vra_addr_vec'high downto 1); -- @ 1.->2.
      vra_addr_vec(vra_addr_vec'high) <= vra_addr; -- @ 2.
      vrb_addr_vec(vrb_addr_vec'high) <= vrb_addr; -- @ 2.
      vra_re_vec(vra_re_vec'high-1 downto 0) <= vra_re_vec(vra_re_vec'high downto 1);
      vra_re_vec(vra_re_vec'high) <= vra_re;

      op_arith_shift_vec(op_arith_shift_vec'high-1 downto 0) <= op_arith_shift_vec(op_arith_shift_vec'high downto 1); -- @ 8.->9.
      op_arith_shift_vec(op_arith_shift_vec'high) <= op_arith_shift; -- @ 7.
      code_vec(code_vec'high-1 downto 0) <= code_vec(code_vec'high downto 1); -- @ 8.->9.
      code_vec(code_vec'high) <= code; -- @ 7.
      immediate_vec(immediate_vec'high-1 downto 0) <= immediate_vec(immediate_vec'high downto 1);  -- @ 8.->10.
      immediate_vec(immediate_vec'high) <= immediate; -- @ 7
      swc_offset_vec(swc_offset_vec'high-1 downto 0) <= swc_offset_vec(swc_offset_vec'high downto 1); -- @ 8.->10.
      swc_offset_vec(swc_offset_vec'high) <= swc_offset; -- @ 7
      regBlock_re_vec(regBlock_re_vec'high-1 downto 0) <= regBlock_re_vec(regBlock_re_vec'high downto 1); --@ 3.->8.
      regBlock_re_vec(regBlock_re_vec'high) <= regBlock_re; -- @ 2.
      mregBlock_re_vec(mregBlock_re_vec'high-1 downto 0) <= mregBlock_re_vec(mregBlock_re_vec'high downto 1); --@ 3.->8.
      mregBlock_re_vec(mregBlock_re_vec'high) <= mregBlock_re; -- @ 2.

      vregBlock_re_vec(vregBlock_re_vec'high-1 downto 0) <= vregBlock_re_vec(vregBlock_re_vec'high downto 1); --@ 3.->8.
      vregBlock_re_vec(vregBlock_re_vec'high) <= vregBlock_re; -- @ 2.

      mrx_addr_d1 <= mrx_addr;
      mrx_addr_d2 <= mrx_addr_d1;
      mrx_addr_d3 <= mrx_addr_d2;
      mrx_addr_d4 <= mrx_addr_d3;
      vrx_addr_d1 <= vrx_addr;
      vrx_addr_d2 <= vrx_addr_d1;
      vrx_addr_d3 <= vrx_addr_d2;
      vrx_addr_d4 <= vrx_addr_d3;
      --}}}
      -- @ 7 {{{
      vrs <= vrout_vec(0); -- @ 7 (vrb)
      if vregBlock_re_vec(2)(1) = '1' or (vra_re_vec(0) = '0' and vrx_addr_d4(FREG_FILE_W-1) = '1') then
        vrs <= vrout_vec(1); -- @ 7
      end if;
      vrs_d0 <= vrs; -- @ 8
      for i in 0 to FREG_N_SIMD-1 loop
        vrs_d1(i) <= vrs_d0(DATA_W*(i+1)-1 downto DATA_W*i); -- @ 9
      end loop;

      vrt <= vrout_vec(0); -- @ 8 (vra)
      if vregBlock_re_vec(1)(1) = '1' then
        vrt <= vrout_vec(1);
      end if;

      rt_p0 <= rt_vec(0);  -- @ 7.
      -- frt_p0 <= frt_vec(0);  -- @ 7.
      for i in 1 to N_REG_BLOCKS-1 loop
        if regBlock_re_vec(2)(i) = '1' then
          rt_p0 <= rt_vec(i); -- @ i+7.
        end if;
        -- if fregBlock_re_vec(2)(i) = '1' then
        --   frt_p0 <= frt_vec(i); -- @ i+7
        -- end if;
      end loop;
      -- }}}
      -- @ 8 {{{
      rt <= rt_p0; -- @ 8.
      rs <= rs_vec(0); -- @ 8.
      -- frt <= frt_p0; -- @ 8.
      -- frs <= frs_vec(0); -- @8.
      for i in 1 to N_REG_BLOCKS-1 loop
        if regBlock_re_vec(1)(i) = '1' then -- level 7.
          rs <= rs_vec(i);  -- @ i+8.
        end if;
        -- if fregBlock_re_vec(1)(i) = '1' then -- level 7.
        --   frs <= frs_vec(i);  -- @ i+8.
        -- end if;
      end loop;

      mrx <= mrx_vec(to_integer(mrx_addr_d4(REG_FILE_W-1 downto REG_FILE_BLOCK_W)));
      -- @ 7 {{{
      mrt_p0 <= mrt_vec(0);  -- @ 7.
      for i in 1 to N_REG_BLOCKS-1 loop
        if mregBlock_re_vec(2)(i) = '1' then
          mrt_p0 <= mrt_vec(i); -- @ i+7.
        end if;
      end loop;
      -- }}}
      -- @ 8 {{{
      mrt <= mrt_p0; -- @ 8.
      mrs <= mrs_vec(0); -- @ 8.
      for i in 1 to N_REG_BLOCKS-1 loop
        if mregBlock_re_vec(1)(i) = '1' then -- level 7.
          mrs <= mrs_vec(i);  -- @ i+8.
        end if;
      end loop;
      -- }}}

      if code_vec(code_vec'high)(CODE_W-1) = '0' then -- level 7.
        shift(5) <= '0'; -- @ 8.
        if code_vec(code_vec'high)(0) = '0' then -- level 7.
          shift(4 downto 0) <= rt_p0(4 downto 0); -- sll @8.
        else
          shift(4 downto 0) <= immediate_vec(immediate_vec'high)(4 downto 0); --slli -- @ 8.
        end if;
      else
        if code_vec(code_vec'high)(0) = '0' then -- shift right -- level 7
          -- the width of port b of the mutiplier needs to be extended to 33, or the high part to 17 to enable a shift right logical with zero
          shift(5 downto 0) <= std_logic_vector("100000" - resize(unsigned(rt_p0(4 downto 0)), 6)); --srl & sra -- @ 8.
        else
          shift(5 downto 0) <= std_logic_vector("100000" - resize(unsigned(immediate_vec(immediate_vec'high)(4 downto 0)), 6)); -- srli & srai -- @ 8.
        end if;
      end if;
      -- }}}
      -- @ 9 {{{
      rt_d0 <= rt; -- @ 9.
      rt_zero <= '0'; -- @ 9.
      if rt = (rt'reverse_range=>'0') then -- level 8.
        rt_zero <= '1'; -- @ 9.
      end if;

      rs_zero <= '0'; -- @ 9.
      if rs = (rs'reverse_range=>'0') then -- level 8.
        rs_zero <= '1'; -- @ 9.
      end if;

      b_shifted <= (others=>'0'); -- @ 9.
      b_shifted(to_integer(unsigned(shift))) <= '1'; -- @ 9.
      
      a_p0 <= rs; -- @ 9.
      
      rd <= rd_vec(0); -- @ 9.
      float_c <= rd_vec(0); -- @9.
      -- frd <= frd_vec(0);
      for i in 1 to N_REG_BLOCKS-1 loop
        if regBlock_re_vec(0)(i) = '1' then -- level 8.
          rd <= rd_vec(i);  -- @ i+9.
          float_c <= rd_vec(i);
        end if;
        -- if fregBlock_re_vec(0)(i) = '1' then -- level 8.
        --   frd <= frd_vec(i);  -- @ i+9.
        -- end if;
      end loop;
      --vec_off <= std_logic_vector(to_unsigned(alu_idx, CV_W) + unsigned(immediate_vec(immediate_vec'high-1)(FREG_N_SIMD_W-1 downto 0))); -- @ 9.
      -- }}}
      op_vmem_v_d0 <= op_vmem_v; -- @ 8
      op_vmem_v_d1 <= op_vmem_v_d0; -- @ 9
      -- @ 10 {{{
      --if op_vmem_v_d1 = '1' then
      --  for i in 0 to CV_SIZE-1 loop
      --    rd_out(i) <= vrs_d1(to_integer(unsigned(swc_offset_vec(swc_offset_vec'high-2)))*CV_SIZE+i);
      --  end loop;
      --else
      for i in 0 to FREG_N_SIMD-1 loop
        vrd_out((i+1)*DATA_W-1 downto i*DATA_W) <= vrs_d1(i); -- @ 10.
      end loop;
      --vrd_out <= vrs_d1; -- @ 10.
      rd_out <= rd; -- @ 10.
      --end if;
      -- end if;
      if op_arith_shift_vec(0) = op_cls then
        a <= (others=>'0'); -- @ 10.
      elsif op_arith_shift_vec(0) = op_lw then
        if code_vec(code_vec'high-2)(2 downto 1) = "11" then
          a(FREG_N_SIMD_W+1 downto 0) <= (others=>'0');
          a(DATA_W-1 downto FREG_N_SIMD_W+2) <= a_p0(DATA_W-FREG_N_SIMD_W-3 downto 0); -- @ 10.
        --elsif code_vec(code_vec'high-2)(3 downto 1) = "111" then
        --  a(1 downto 0) <= (others=>'0');
        --  a(DATA_W-1 downto 2) <= a_p0(DATA_W-3 downto 0); -- @ 10.
        else
          a <= a_p0;
        end if;
      elsif op_arith_shift_vec(0) = op_smem then
        if code_vec(code_vec'high-2)(2 downto 1) = "10" then
          --a(1 downto 0) <= (others=>'0');
          --a(DATA_W-1 downto 2) <= a_p0(DATA_W-3 downto 0); -- @ 10.
          a <= a_p0;
        elsif code_vec(code_vec'high-2)(3 downto 2) = "00" then
          a <= (others=>'0');
        else
          a(FREG_N_SIMD_W+1 downto 0) <= (others=>'0');
          a(DATA_W-1 downto FREG_N_SIMD_W+2) <= a_p0(DATA_W-FREG_N_SIMD_W-3 downto 0); -- @ 10.
        end if;
      else
        a <= a_p0; -- @ 10.
      end if;
      if op_arith_shift_vec(0) = op_mov then
        reg_we_mov <= rt_zero; -- movz, @10.
        if code_vec(code_vec'high-2)(CODE_W-1) = '0' then -- movn, level 9.
          reg_we_mov <= not rt_zero; -- @ 10.
        end if;
      elsif op_arith_shift_vec(0) = op_cls then -- level 9.
        reg_we_mov <= rs_zero; -- movz, @10.
        if code_vec(code_vec'high-2)(0) = '0' then -- movn, level 9.
          reg_we_mov <= not rs_zero; -- @ 10.
        end if;
      end if;

      case op_arith_shift_vec(0) is -- level 9.
        when op_shift =>
          if code_vec(code_vec'high-2)(CODE_W-1) = '1' and code_vec(code_vec'high-2)(CODE_W-2) = '1' and a_p0(DATA_W-1) = '1' then  -- level 9.
                -- CODE_W-1 for right shift & CODE_W-2 for arithmetic & a_p0(DATA_W-1) for negative
            sra_sign <= b_shifted; -- @ 10.
            sra_sign_v <= '1';    -- @ 10.
          else
            sra_sign <= (others=>'0'); -- @ 10.
            sra_sign_v <= '0'; -- @ 10.
          end if;
        when others =>
          sra_sign <= (others=>'0'); -- @ 10.
          sra_sign_v <= '0'; -- @ 10.
      end case;
      -- b {{{
      case op_arith_shift_vec(0) is -- level 9.
        when op_lw =>
          if code_vec(code_vec'high-2)(2 downto 1) = "11" then -- load/store vector
            b(FREG_N_SIMD_W+1 downto 0) <= (others=>'0');
            b(DATA_W downto FREG_N_SIMD_W+2) <= std_logic_vector(resize(signed(immediate_vec(immediate_vec'high-2)(8 downto 0)), DATA_W-FREG_N_SIMD_W-1)); -- @ 10.
          --elsif code_vec(code_vec'high-2)(3 downto 1) = "111" then -- store vector
          --  b(DATA_W downto FREG_N_SIMD_W+2) <= std_logic_vector(resize(signed(immediate_vec(immediate_vec'high-2)(8 downto 0)), DATA_W-FREG_N_SIMD_W-1));
          --  b(CV_W+1 downto 0) <= (others=>'0');
          --  b(FREG_N_SIMD_W+1 downto CV_W+2) <= swc_offset_vec(swc_offset_vec'high-2); -- @ 10.
          else 
            b(DATA_W downto 3) <= (others=>'0');
            b(2 downto 0) <= code_vec(code_vec'high-2)(2 downto 0); -- @ 10.
          end if;
        when op_mult =>
          b(DATA_W) <= '0';
          b(rt_d0'range) <= rt_d0; -- @ 10.
        when op_shift =>
          b <= b_shifted; -- @ 10.
        when op_smem =>
          if code_vec(code_vec'high-2)(2 downto 1) = "10" then
            b(1 downto 0) <= (others=>'0');
            b(DATA_W downto 2) <= std_logic_vector(resize(signed(immediate_vec(immediate_vec'high-2)(8 downto 0)), DATA_W-1)); -- @ 10.
          --elsif code_vec(code_vec'high-2)(3 downto 1) = "111" then -- store vector
          --  b(DATA_W downto FREG_N_SIMD_W+2) <= std_logic_vector(resize(signed(immediate_vec(immediate_vec'high-2)(8 downto 0)), DATA_W-FREG_N_SIMD_W-1)); -- @ 10.
          --  b(CV_W+1 downto 0) <= (others=>'0');
          --  b(FREG_N_SIMD_W+1 downto CV_W+2) <= swc_offset_vec(swc_offset_vec'high-2); -- @ 10.
            --b(FREG_N_SIMD_W+1 downto 2) <= vec_off; -- @ 10.
          else
            b(FREG_N_SIMD_W+1 downto 0) <= (others=>'0');
            b(DATA_W downto FREG_N_SIMD_W+2) <= std_logic_vector(resize(signed(immediate_vec(immediate_vec'high-2)(8 downto 0)), DATA_W-FREG_N_SIMD_W-1)); -- @ 10.
          end if;
        when op_cls =>
          if code_vec(code_vec'high-2)(2) = '0' then
            b <= std_logic_vector(resize(signed(immediate_vec(immediate_vec'high-2)(8 downto 0)), DATA_W+1)); -- @ 10.
          elsif code_vec(code_vec'high-2)(3) = '0' or code_vec(code_vec'high-2)(1) = '1' then
            b(FREG_N_SIMD_W+1 downto 0) <= (others=>'0');
            b(DATA_W downto FREG_N_SIMD_W+2) <= std_logic_vector(resize(signed(immediate_vec(immediate_vec'high-2)(8 downto 0)), DATA_W-FREG_N_SIMD_W-1)); -- @ 10.
          else
            b(1 downto 0) <= (others=>'0');
            b(DATA_W downto 2) <= std_logic_vector(resize(signed(immediate_vec(immediate_vec'high-2)(8 downto 0)), DATA_W-1)); -- @ 10.
          end if;
        when others =>
          b <= (0=>'1', others=>'0'); -- @ 10.
      end case;
      -- }}}
      -- c {{{
      case op_arith_shift_vec(0) is -- level 9.
        when op_add | op_slt =>
          if code_vec(code_vec'high-2)(0) = '0' then -- "use immediate"-bit not set, level 9.
            c <= rt_d0; -- @ 10.
          elsif code_vec(code_vec'high-2)(CODE_W-1) = '0' then -- addi, slti, sltiu -- level 9.
            c <= std_logic_vector(resize(signed(immediate_vec(immediate_vec'high-2)(IMM_ARITH_W-1 downto 0)), DATA_W)); -- @ 10.
          elsif code_vec(code_vec'high-2)(CODE_W-2) = '0' then -- li  -- level 4 & 4.5
            c <= std_logic_vector(resize(signed(immediate_vec(immediate_vec'high-2)(IMM_W-1 downto 0)), DATA_W)); -- @ 10.
          else --lui
            c(DATA_W-1 downto DATA_W-IMM_W) <= immediate_vec(immediate_vec'high-2)(IMM_W-1 downto 0); -- @ 10.
            c(DATA_W-IMM_W-1 downto 0) <= rd(DATA_W-IMM_W-1 downto 0); -- @ 10.
          end if;
        when op_lw | op_ato | op_smem | op_cls =>
          c <= rt_d0;
        when op_lmem =>
          c <= std_logic_vector(resize(signed(immediate_vec(immediate_vec'high-2)(IMM_ARITH_W-1 downto 0)), DATA_W)); -- @ 10.
        when op_mult =>
          if code_vec(code_vec'high-2)(CODE_W-1) = '1' then -- macc -- level 9
            c <= rd; -- @ 10.
          else
            c <= (others=>'0'); -- @ 10.
          end if;
        when op_bra =>
          c <= rd; -- @ 10.
        when others => -- when op_shift | op_mov | nop
          c <= (others=>'0'); -- @ 10.
      end case;
      -- }}}
      -- slt & sltu {{{
      instr_is_slt(instr_is_slt'high) <= '0'; -- @ 10.
      instr_is_sltu(instr_is_sltu'high) <= '0'; -- @ 10.
      if op_arith_shift_vec(0) = op_slt then -- level 9
        if code_vec(code_vec'high-2)(2) = '0' then -- slt & slti, level 9
          instr_is_slt(instr_is_slt'high) <= '1'; -- @ 10.
        else --sltu & sltiu
          instr_is_sltu(instr_is_sltu'high) <= '1'; -- @ 10.
        end if;
      end if;
      instr_is_slt(instr_is_slt'high-1 downto 0) <= instr_is_slt(instr_is_slt'high downto 1); -- @ 11.->15.
      instr_is_sltu(instr_is_sltu'high-1 downto 0) <= instr_is_sltu(instr_is_sltu'high downto 1); -- @ 11.->15.
      -- }}}
      sub_op <= '0'; -- @ 10.
      case op_arith_shift_vec(0) is -- level 9.
        when op_add | op_bra | op_slt =>
          sub_op <= code_vec(code_vec'high-2)(1); -- @ 10.
        when op_lmem | op_lw | op_mult | op_shift | op_mov | op_ato | op_mcr | op_smem | op_cls=>
      end case;
      -- }}}
    end if;
  end process;
  ---------------------------------------------------------------------------------------------------------}}}
  -- mult_add_sub {{{
  ce <= '1';
  mult_adder: entity mult_add_sub port map (
    clk         => clk,
    ce          => ce,
    sub         => sub_op, -- level 10.
    a           => unsigned(a), -- level 10.
    b           => unsigned(b), -- level 10.
    c           => unsigned(c), -- level 10.
    sra_sign    => unsigned(sra_sign), -- 10.
    sra_sign_v  => sra_sign_v, -- level 10.

    res_low_p0  => res_low_p0, -- level 15.
    sltu_true_p0=> sltu_true, --level 15.
    res_high    => res_high -- level 16.
  );
  -- }}}
  -- add_add {{{
  process (clk)
  begin
    if rising_edge(clk) then
      sum_ab <= std_logic_vector(unsigned(a) + unsigned(b(DATA_W-1 downto 0))); -- @ 11.
      c_d0 <= c; -- @11.
      res_sum_vec(res_sum_vec'high) <= std_logic_vector(unsigned(sum_ab) + unsigned(c_d0)); -- @ 12.
      res_sum_vec(res_sum_vec'high-1 downto 0) <= res_sum_vec(res_sum_vec'high downto 1); -- @ 13.->15
      res_sum <= res_sum_vec(0); -- @ 16.
    end if;
  end process;

  process(clk)
  begin
    if rising_edge(clk) then
      immediate2_d0 <= immediate2; -- @ 7
      immediate2_d1 <= immediate2_d0 & "0000000"; -- @ 8
      res_sum2_vec(res_sum2_vec'high) <= std_logic_vector(unsigned(mrt) + resize(unsigned(immediate2_d1), DATA_W)); -- @ 9
      res_sum2_vec(res_sum2_vec'high-1 downto 0) <= res_sum2_vec(res_sum2_vec'high downto 1); -- @ 10.->15
      res_sum2 <= res_sum2_vec(0); -- @ 16.
    end if;
  end process;
  -- }}}
end Behavioral;
