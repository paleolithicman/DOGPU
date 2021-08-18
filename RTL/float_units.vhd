-- libraries -------------------------------------------------------------------------------------------{{{
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.all;
use work.FGPU_definitions.all;
-- library xil_defaultlib; -- necessray for synthesis
-- use xil_defaultlib.all;
---------------------------------------------------------------------------------------------------------}}}
entity float_units is -- {{{
port(
  float_a, float_b    : in SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0')); -- level 9.
  float_c             : in SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0')); -- level 9.
  fsub                : in std_logic := '0';
  res_float           : out SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0')); -- level 10+MAX_FPU_DELAY.
  code                : in std_logic_vector(CODE_W-1 downto 0); -- level 16.

  rst                 : in std_logic;
  clk                 : in std_logic
);
end entity; -- }}}
architecture Behavioral of float_units is
  constant DOT_DELAY                      : integer := 5;
  constant SCALE_FACTOR_W                 : integer := 6;
  constant MAX_DECIMAL                    : unsigned(8-SCALE_FACTOR_W-1 downto 0) := (others=>'1');
  constant PAD                            : std_logic_vector(SCALE_FACTOR_W-1 downto 0) := (others=>'0');
  -- signals definitions {{{
  signal ce                               : std_logic := '0';
  signal fadd_res                         : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal fslt_res                         : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal fmul_res                         : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal fdiv_res                         : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal fsqrt_res                        : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal frsqrt_res                       : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal ffma_res                         : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal uitofp_res                       : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  type p3_type is array (natural range<>) of std_logic_vector(63 downto 0);
  type p2_type is array (natural range<>) of std_logic_vector(37 downto 0);
  type p1_type is array (natural range<>) of std_logic_vector(18 downto 0);
  signal dot_res                          : SLV32_ARRAY(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal dot_res_p0                       : p1_type(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal dot_res_p1                       : p1_type(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal dot_res_p2                       : p2_type(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  signal dot_res_p3                       : p3_type(CV_SIZE-1 downto 0) := (others=>(others=>'0'));
  type res_vec_type is array (natural range<>) of SLV32_ARRAY(CV_SIZE-1 downto 0);
  signal float_c_vec                      : res_vec_type(2 downto 0) := (others=>(others=>(others=>'0')));
  signal fmul_res_vec                     : res_vec_type(max(MAX_FPU_DELAY-FMUL_DELAY,0) downto 0) := (others=>(others=>(others=>'0')));
  signal ffma_res_vec                     : res_vec_type(max(MAX_FPU_DELAY-FFMA_DELAY,0) downto 0) := (others=>(others=>(others=>'0')));
  signal uitofp_res_vec                   : res_vec_type(max(MAX_FPU_DELAY-UITOFP_DELAY, 0) downto 0) := (others=>(others=>(others=>'0')));
  signal fadd_res_vec                     : res_vec_type(max(MAX_FPU_DELAY-FADD_DELAY, 0) downto 0) := (others=>(others=>(others=>'0')));
  signal dot_res_vec                      : res_vec_type(MAX_FPU_DELAY-DOT_DELAY downto 0) := (others=>(others=>(others=>'0')));
  signal fslt_res_vec                     : alu_en_vec_type(MAX_FPU_DELAY-FSLT_DELAY downto 0) := (others=>(others=>'0'));
  signal code_vec                         : code_vec_type(MAX_FPU_DELAY-7 downto 0) := (others=>(others=>'0'));
  attribute max_fanout of code_vec        : signal is 32;
  signal ffma_valid                       : std_logic_vector(CV_SIZE-1 downto 0 ) := (others=>'0');
  signal fmul_valid                       : std_logic_vector(CV_SIZE-1 downto 0 ) := (others=>'0');
  signal fdiv_valid                       : std_logic_vector(CV_SIZE-1 downto 0 ) := (others=>'0');
  signal fsqrt_valid                      : std_logic_vector(CV_SIZE-1 downto 0 ) := (others=>'0');
  -- Operation slave channel signals
  signal operation_tdata                  : std_logic_vector(7 downto 0) := (others=>'0');

  --}}}
begin
  ce <= '1';
  uitofp_res_vec(uitofp_res_vec'high) <= uitofp_res; -- level 14.
  fmul_res_vec(fmul_res_vec'high) <= fmul_res; -- level 17.
  ffma_res_vec(ffma_res_vec'high) <= ffma_res; -- level 17.
  fadd_res_vec(fadd_res_vec'high) <= fadd_res; -- level 20.
  -- dot_res_vec(dot_res_vec'high) <= dot_res; -- level 14.
  fstl_vec: for i in 0 to CV_SIZE-1 generate
    fslt_res_vec(fslt_res_vec'high)(i) <= fslt_res(i)(0); -- level 11.
  end generate;
  process(clk)
  begin
    if rising_edge(clk) then
      -- pipes {{{
      if MAX_FPU_DELAY /= FSLT_DELAY then
        fslt_res_vec(fslt_res_vec'high-1 downto 0) <= fslt_res_vec(fslt_res_vec'high downto 1); -- @ 11.->11+MAX_FPU_DELAY-UITOFP_DELAY-1.
      end if;
      if MAX_FPU_DELAY /= UITOFP_DELAY then
        uitofp_res_vec(uitofp_res_vec'high-1 downto 0) <= uitofp_res_vec(uitofp_res_vec'high downto 1); -- @ 15.->15+MAX_FPU_DELAY-UITOFP_DELAY-1.
      end if;
      if MAX_FPU_DELAY /= FMUL_DELAY then
        fmul_res_vec(fmul_res_vec'high-1 downto 0) <= fmul_res_vec(fmul_res_vec'high downto 1); -- @ 14.->14+MAX_FPU_DELAY-FMUL_DELAY-1.
      end if;
      if MAX_FPU_DELAY /= FFMA_DELAY then
        ffma_res_vec(ffma_res_vec'high-1 downto 0) <= ffma_res_vec(ffma_res_vec'high downto 1); -- @ 17.->17+MAX_FPU_DELAY-FFMA_DELAY-1.
      end if;
      if MAX_FPU_DELAY /= FADD_DELAY then
        fadd_res_vec(max(fadd_res_vec'high-1, 0) downto 0) <= fadd_res_vec(fadd_res_vec'high downto min_int(MAX_FPU_DELAY-FADD_DELAY,1)); -- @ 13.->13+MAX_FPU_DELAY-FADD_DELAY-1.
          -- min and max to avoid warning during simulations
      end if;
      -- dot_res_vec(dot_res_vec'high-1 downto 0) <= dot_res_vec(dot_res_vec'high downto 1); -- @ 16.->16+MAX_FPU_DELAY-DOT_DELAY-1.
      code_vec(code_vec'high) <= code; -- @ 16.
      code_vec(code_vec'high -1 downto 0) <= code_vec(code_vec'high downto 1); -- @ 17.->17+MAX_FPU_DELAY-7-1.
      -- }}}
      for i in 0 to CV_SIZE-1 loop
        case code_vec(0) is -- 9+MAX_FPU_DELAY. (37)
          when X"3" => -- uitofp
            res_float(i) <= uitofp_res_vec(0)(i); -- @ 10+MAX_FPU_DELAY.
          when X"1" => -- fmul
            res_float(i) <= fmul_res_vec(0)(i); -- @ 10+MAX_FPU_DELAY.
          when X"2" => -- fdiv
            res_float(i) <= fdiv_res(i); -- @ 10+MAX_FPU_DELAY.
          when X"4" => -- fsqrt
            res_float(i) <= fsqrt_res(i); -- @ 10+MAX_FPU_DELAY.
          when X"5" => -- frsqrt
            res_float(i) <= frsqrt_res(i); -- @ 10+MAX_FPU_DELAY.
          when X"7" => -- fslt
            res_float(i) <= (others=>'0');
            res_float(i)(0) <= fslt_res_vec(0)(i); -- @ 10+MAX_FPU_DELAY.
          when X"9" => -- ffma
            res_float(i) <= ffma_res_vec(0)(i); -- @ 10+MAX_FPU_DELAY.
          -- when X"A" => -- dot
          --   res_float(i) <= dot_res_vec(0)(i); -- @ 10+MAX_FPU_DELAY
          when others => -- fadd X"0" or fsub X"8"
            if MAX_FPU_DELAY /= FADD_DELAY then
              res_float(i) <= fadd_res_vec(0)(i); -- @ 10+MAX_FPU_DELAY.
            else
              res_float(i) <= fadd_res(i);
            end if;
        end case;
      end loop;
    end if;
  end process;

  fadd_units: for i in 0 to CV_SIZE-1 generate
  begin
    uitofp_if: if UITOFP_IMPLEMENT /= 0 generate -- {{{
      ui_to_float : entity uitofp_wrap
      port map (
        -- Global signals
        aclk                    => clk,
        arst                    => rst,
        -- AXI4-Stream slave channel for operand A
        s_axis_a_tvalid         => ce,
        s_axis_a_tdata          => float_a(i)(DATA_W-1 downto 0), -- level 9.
        -- AXI4-Stream master channel for output result
        m_axis_result_tvalid    => open,
        m_axis_result_tdata     => uitofp_res(i) -- level 9+5=14.
        );
    end generate; -- }}}
    fsqrt_if: if FSQRT_IMPLEMENT /= 0 generate -- {{{
      float_sqrt : entity fsqrt_wrap
      port map (
        -- Global signals
        aclk                    => clk,
        arst                    => rst,
        -- AXI4-Stream slave channel for operand A
        s_axis_a_tvalid         => ce,
        s_axis_a_tdata          => float_a(i)(DATA_W-1 downto 0), -- level 9.
        -- AXI4-Stream master channel for output result
        m_axis_result_tvalid    => fsqrt_valid(i), 
        m_axis_result_tdata     => fsqrt_res(i) -- level 9+28=37.
        );
    end generate; -- }}}
    frsqrt_if: if FRSQRT_IMPLEMENT /= 0 generate -- {{{
      float_rsqrt : entity frsqrt_wrap
      port map (
        -- Global signals
        aclk                    => clk,
        arst                    => rst,
        -- AXI4-Stream slave channel for operand A
        s_axis_a_tvalid         => ce,
        s_axis_a_tdata          => float_a(i)(DATA_W-1 downto 0), -- level 9.
        -- AXI4-Stream master channel for output result
        m_axis_result_tvalid    => open, 
        m_axis_result_tdata     => frsqrt_res(i) -- level 9+28=37.
        );
    end generate; -- }}}
    ffma_if: if FFMA_IMPLEMENT /= 0 generate -- {{{
      float_ffma: entity ffma_wrap
      port map (
        -- Global signals
        aclk                    => clk,
        arst                    => rst,
        -- AXI4-Stream slave channel for operand A
        s_axis_a_tvalid         => ce,
        s_axis_a_tdata          => float_a(i)(DATA_W-1 downto 0), -- level 9.
        -- AXI4-Stream slave channel for operand B
        s_axis_b_tvalid         => ce,
        s_axis_b_tdata          => float_b(i)(DATA_W-1 downto 0), -- level 9.
        -- AXI4-Stream slave channel for operand C
        s_axis_c_tvalid         => ce,
        s_axis_c_tdata          => float_c(i)(DATA_W-1 downto 0), -- level 9.
        -- AXI4-Stream master channel for output result
        m_axis_result_tvalid    => ffma_valid(i), 
        m_axis_result_tdata     => ffma_res(i) -- level 9+8=17.
        );
    end generate; -- }}}
    fdiv_if: if FDIV_IMPLEMENT /= 0 generate -- {{{
      float_div : entity fdiv_wrap
      port map (
        -- Global signals
        aclk                    => clk,
        arst                    => rst,
        -- AXI4-Stream slave channel for operand A
        s_axis_a_tvalid         => ce,
        s_axis_a_tdata          => float_a(i)(DATA_W-1 downto 0), -- level 9.
        -- AXI4-Stream slave channel for operand B
        s_axis_b_tvalid         => ce,
        s_axis_b_tdata          => float_b(i)(DATA_W-1 downto 0), -- level 9.
        -- AXI4-Stream master channel for output result
        m_axis_result_tvalid    => fdiv_valid(i), 
        m_axis_result_tdata     => fdiv_res(i) -- level 9+28=37.
        );
    end generate; -- }}}
    fmul_if: if FMUL_IMPLEMENT /= 0 generate -- {{{
      float_mul : entity fmul_wrap
      port map (
        -- Global signals
        aclk                    => clk,
        arst                    => rst,
        -- AXI4-Stream slave channel for operand A
        s_axis_a_tvalid         => ce,
        s_axis_a_tdata          => float_a(i)(DATA_W-1 downto 0), -- level 9.
        -- AXI4-Stream slave channel for operand B
        s_axis_b_tvalid         => ce,
        s_axis_b_tdata          => float_b(i)(DATA_W-1 downto 0), -- level 9.
        -- AXI4-Stream master channel for output result
        m_axis_result_tvalid    => fmul_valid(i), 
        m_axis_result_tdata     => fmul_res(i) -- level 9+8=17.
        );
    end generate; -- }}}
    fadd_if: if FADD_IMPLEMENT /= 0 generate -- {{{
      operation_tdata(0) <= fsub;
      float_add_sub : entity fadd_fsub_wrap
      port map (
        -- Global signals
        aclk                    => clk,
        arst                    => rst,
        -- AXI4-Stream slave channel for operand A
        s_axis_a_tvalid         => ce,
        s_axis_a_tdata          => float_a(i)(DATA_W-1 downto 0), -- level 9.
        -- AXI4-Stream slave channel for operand B
        s_axis_b_tvalid         => ce,
        s_axis_b_tdata          => float_b(i)(DATA_W-1 downto 0), -- level 9.
        -- AXI4-Stream slave channel for operation control information
        s_axis_operation_tvalid => ce,
        s_axis_operation_tdata  => operation_tdata, -- level 9
        -- AXI4-Stream master channel for output result
        m_axis_result_tvalid    => open, 
        m_axis_result_tdata     => fadd_res(i) -- level 9+11=20.
        );
    end generate; -- }}}
    fslt_if: if FSLT_IMPLEMENT /= 0 generate -- {{{
      float_slt : entity fslt_wrap
      port map (
        -- Global signals
        aclk                    => clk,
        arst                    => rst,
        -- AXI4-Stream slave channel for operand A
        s_axis_a_tvalid         => ce,
        s_axis_a_tdata          => float_a(i)(DATA_W-1 downto 0), -- level 9.
        -- AXI4-Stream slave channel for operand B
        s_axis_b_tvalid         => ce,
        s_axis_b_tdata          => float_b(i)(DATA_W-1 downto 0), -- level 9.
        -- AXI4-Stream master channel for output result
        m_axis_result_tvalid    => open, 
        m_axis_result_tdata     => fslt_res(i)(7 downto 0) -- level 9+2=11.
        );
    end generate; -- }}}
  end generate;
  ---------------------------------------------------------------------------------------------------------}}}
end Behavioral;
