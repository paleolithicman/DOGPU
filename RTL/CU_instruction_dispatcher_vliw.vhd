-- libraries -------------------------------------------------------------------------------------------{{{
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.all;
use work.FGPU_definitions.all;
---------------------------------------------------------------------------------------------------------}}}
entity CU_instruction_dispatcher is --{{{
port(
  clk, nrst           : in std_logic;

  cram_rqst           : out std_logic := '0';
  cram_rdAddr         : out unsigned(CRAM_ADDR_W-1 downto 0) := (others=>'0');
  cram_rdAddr_conf    : in unsigned(CRAM_ADDR_W-1 downto 0) := (others=>'0');
  cram_rdData         : in std_logic_vector(2*DATA_W-1 downto 0); -- cram_rdData is delayed by 1 clock cycle to cram_rdAddr_conf
  
  PC_indx             : in integer range 0 to N_WF_CU-1;             --response in two clk cycles
  wf_active           : in std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  pc_updated          : in std_logic_vector(N_WF_CU-1 downto 0);
  PCs                 : in CRAM_ADDR_ARRAY(N_WF_CU-1 downto 0);
  pc_rdy              : out std_logic_vector(N_WF_CU-1 downto 0) := (others => '0');
  instr               : out std_logic_vector(DATA_W-1 downto 0) := (others => '0'); -- 1 clock cycle delayed after pc_rdy
  instr_gmem_op       : out std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  instr_scratchpad_ld : out std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  instr_sharedmem_ld  : out std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  instr_gmem_read     : out std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  instr_branch        : out std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  instr_jump          : out std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  instr_fpu           : out std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  instr_sync          : out std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  instr_gsync         : out std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  instr_swc           : out std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  instr_dot           : out std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  rd_out              : out wi_reg_addr_array(N_WF_CU-1 downto 0) := (others=>(others=>'0'));
  reg_v               : out slv32_array(N_WF_CU-1 downto 0) := (others=>(others=>'0'));
  vrs_v               : out slv16_array(N_WF_CU-1 downto 0);
  branch_distance     : out branch_distance_vec(0 to N_WF_CU-1) := (others=>(others=>'0'));

  instr_macro         : out std_logic_vector(DATA_W-1 downto 0) := (others=>'0');

  wf_retired          : out std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0')
);
end CU_instruction_dispatcher; -- }}}
architecture Behavioral of CU_instruction_dispatcher is
  -- internal signals definitions {{{
  signal cram_rdAddr_i                    : unsigned(CRAM_ADDR_W-1 downto 0) := (others=>'0');
  signal pc_rdy_i                         : std_logic_vector(N_WF_CU-1 downto 0) := (others => '0');
  signal wf_retired_i                     : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal instr_gmem_op_i                  : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal instr_scratchpad_ld_i            : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal instr_sharedmem_ld_i             : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal instr_branch_i                   : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal instr_jump_i                     : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal instr_fpu_i                      : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal instr_sync_i                     : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal instr_gsync_i                    : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal instr_swc_i                      : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal instr_dot_i                      : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal instr_gmem_read_i                : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal branch_distance_i                : branch_distance_vec(0 to N_WF_CU-1) := (others=>(others=>'0'));
  -- }}}
  -- signals definitions {{{
  type st_cram_type is (request, wait_resp, check);
  type instr_vec_type is array (N_WF_CU-1 downto 0) of std_logic_vector(DATA_W-1 downto 0);  

  -- global FSM signals 
  signal instr_vec, instr_vec_n           : instr_vec_type := (others=>(others=>'0'));
  signal instr_macro_vec                  : instr_vec_type := (others=>(others=>'0'));
  signal instr_macro_vec_n                : instr_vec_type := (others=>(others=>'0'));

  signal st_cram, st_cram_n               : st_cram_type := check;

  signal cram_ack                         : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  
  -- next signals
  signal cram_rdAddr_n                    : unsigned(CRAM_ADDR_W-1 downto 0) := (others=>'0');
  
  signal pc_rdy_n                         : std_logic_vector(N_WF_CU-1 downto 0) := (others => '0');

  signal cram_rdData_gmem_op              : std_logic := '0';
  signal instr_gmem_op_n                  : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal instr_scratchpad_ld_n            : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal instr_sharedmem_ld_n             : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal instr_branch_n                   : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal instr_jump_n                     : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal instr_fpu_n                      : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal instr_sync_n                     : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal instr_gsync_n                    : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal instr_swc_n                      : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal instr_dot_n                      : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal instr_gmem_read_n                : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal wf_retired_n                     : std_logic_vector(N_WF_CU-1 downto 0) := (others=>'0');
  signal cram_toggle, cram_toggle_n       : unsigned(1 downto 0) := (others=>'0');

  constant rt_v_vec                       : std_logic_vector(255 downto 0) 
    := "1010101010101010" & "0000000000000000" & "1010000010100011" & "0000001110000111" & "0000000001000100" & "0000000000000000" & "0000000000000000" & "0000000000000110"
      & "1001011010010110" & "0000000000000000" & "0000000100000010" & "0000000100000001" & "0000000100010101" & "0001000100000001" & "0000000000000101" & "0000000000000000";
  signal rd_out_n                         : wi_reg_addr_array(N_WF_CU-1 downto 0);
  signal rd_v, rd_v_n                     : slv32_array(N_WF_CU-1 downto 0);
  signal rs_v, rs_v_n                     : slv32_array(N_WF_CU-1 downto 0);
  signal rt_v, rt_v_n                     : slv32_array(N_WF_CU-1 downto 0);
  signal rt2_v, rt2_v_n                   : slv32_array(N_WF_CU-1 downto 0);
  signal rd2_v, rd2_v_n                   : slv32_array(N_WF_CU-1 downto 0);
  signal vrs_v_n                          : slv16_array(N_WF_CU-1 downto 0);

  signal branch_distance_n                : branch_distance_vec(0 to N_WF_CU-1) := (others=>(others=>'0'));
  -- }}}
begin
  -- internal signals -------------------------------------------------------------------------------------{{{
  pc_rdy <= pc_rdy_i;
  cram_rdAddr <= cram_rdAddr_i;
  wf_retired <= wf_retired_i;
  instr_gmem_op <= instr_gmem_op_i;
  instr_scratchpad_ld <= instr_scratchpad_ld_i;
  instr_sharedmem_ld <= instr_sharedmem_ld_i;
  instr_gmem_read <= instr_gmem_read_i;
  instr_branch <= instr_branch_i;
  instr_jump <= instr_jump_i;
  instr_fpu <= instr_fpu_i;
  instr_sync <= instr_sync_i;
  instr_gsync <= instr_gsync_i;
  instr_swc <= instr_swc_i;
  instr_dot <= instr_dot_i;
  branch_distance <= branch_distance_i;
  ---------------------------------------------------------------------------------------------------------}}}
  -- cram FSM -----------------------------------------------------------------------------------  {{{
  process(clk)
  begin
    if rising_edge(clk) then
      if nrst = '0' then
        st_cram <= check;
        instr_gmem_op_i <= (others=>'0');
        instr_scratchpad_ld_i <= (others=>'0');
        instr_sharedmem_ld_i <= (others=>'0');
        instr_branch_i <= (others=>'0');
        instr_jump_i <= (others=>'0');
        instr_fpu_i <= (others=>'0');
        instr_sync_i <= (others=>'0');
        instr_gsync_i <= (others=>'0');
        instr_swc_i <= (others=>'0');
        instr_dot_i <= (others=>'0');
        branch_distance_i <= (others=>(others=>'0'));
        instr_gmem_read_i <= (others=>'0');
        wf_retired_i <= (others=>'0');
        pc_rdy_i <= (others=>'0');
        cram_rdAddr_i <= (others=>'0');
        instr_vec <= (others=>(others=>'0'));
        instr_macro_vec <= (others=>(others=>'0'));
        instr <= (others=>'0');
        instr_macro <= (others=>'0');
        rd_v <= (others=>(others=>'0'));
        rs_v <= (others=>(others=>'0'));
        rt_v <= (others=>(others=>'0'));
        rt2_v <= (others=>(others=>'0'));
        rd2_v <= (others=>(others=>'0'));
        reg_v <= (others=>(others=>'0'));
        vrs_v <= (others=>(others=>'0'));
      else
        cram_toggle <= cram_toggle_n;
        st_cram <= st_cram_n;
        pc_rdy_i <= pc_rdy_n;
        cram_rdAddr_i <= cram_rdAddr_n;
        instr_vec <= instr_vec_n;      
        instr_macro_vec <= instr_macro_vec_n;
        instr_macro <= instr_macro_vec(PC_indx);
        instr <= instr_vec(PC_indx);
        instr_gmem_op_i <= instr_gmem_op_n;
        instr_scratchpad_ld_i <= instr_scratchpad_ld_n;
        instr_sharedmem_ld_i <= instr_sharedmem_ld_n;
        branch_distance_i <= branch_distance_n;
        instr_branch_i <= instr_branch_n;
        instr_jump_i <= instr_jump_n;
        instr_fpu_i <= instr_fpu_n;
        instr_sync_i <= instr_sync_n;
        instr_gsync_i <= instr_gsync_n;
        instr_swc_i <= instr_swc_n;
        instr_dot_i <= instr_dot_n;
        instr_gmem_read_i <= instr_gmem_read_n;
        wf_retired_i <= wf_retired_n;
        rd_v <= rd_v_n;
        rs_v <= rs_v_n;
        rt_v <= rt_v_n;
        rt2_v <= rt2_v_n;
        rd2_v <= rd2_v_n;
        vrs_v <= vrs_v_n;
        cram_ack <= (others=>'0');
        for i in 0 to N_WF_CU-1 loop
          reg_v(i) <= rd_v(i) or rs_v(i) or rt_v(i) or rt2_v(i) or rd2_v(i);
          if pc_rdy_i(i) = '0' and pc_updated(i) = '0' and PCs(i) = cram_rdAddr_conf and wf_active(i) = '1' then
            cram_ack(i) <= '1';
          end if;
        end loop;
        -- for i in 0 to N_WF_CU-1 loop
        --   if wf_activate(i) = '1' then
        --     wf_active(i) <= '1';
        --   elsif wf_retired_i(i) = '1' then
        --     wf_active(i) <= '0';
        --   end if;
        -- end loop;
      end if;
      rd_out <= rd_out_n;
    end if;
  end process;
  

  WFs_bufs: for i in 0 to N_WF_CU-1 generate
  begin
    WF_buf: process(pc_updated(i), pc_rdy_i(i), cram_rdData, instr_vec(i), instr_macro_vec(i), wf_retired_i(i), instr_gmem_op_i(i), instr_branch_i(i),
                    instr_gmem_read_i(i), branch_distance_i(i), cram_ack(i), instr_jump_i(i), instr_fpu_i(i), instr_scratchpad_ld_i(i), instr_dot_i(i),
                    instr_sharedmem_ld_i(i), instr_sync_i(i), instr_gsync_i(i), instr_swc_i(i), rd_out(i), rd_v(i), rs_v(i), rt_v(i), rt2_v(i), rd2_v(i), vrs_v(i))
      variable rs, rt, rd, rs2, rt2, rd2 : integer range 0 to 31 := 0;
      variable vrs2, vrt2, vrd2 : integer range 0 to 15 := 0;
    begin
      pc_rdy_n(i) <= pc_rdy_i(i);
      instr_vec_n(i) <= instr_vec(i);
      instr_macro_vec_n(i) <= instr_macro_vec(i);
      wf_retired_n(i) <= wf_retired_i(i);
      instr_gmem_op_n(i) <= instr_gmem_op_i(i);
      instr_scratchpad_ld_n(i) <= instr_scratchpad_ld_i(i);
      instr_sharedmem_ld_n(i) <= instr_sharedmem_ld_i(i);
      branch_distance_n(i) <= branch_distance_i(i);
      instr_branch_n(i) <= instr_branch_i(i);
      instr_jump_n(i) <= instr_jump_i(i);
      instr_fpu_n(i) <= instr_fpu_i(i);
      instr_gmem_read_n(i) <= instr_gmem_read_i(i);
      instr_sync_n(i) <= instr_sync_i(i);
      instr_gsync_n(i) <= instr_gsync_i(i);
      instr_swc_n(i) <= instr_swc_i(i);
      instr_dot_n(i) <= instr_dot_i(i);
      rd_v_n(i) <= rd_v(i);
      rd_out_n(i) <= rd_out(i);
      rs_v_n(i) <= rs_v(i);
      rt_v_n(i) <= rt_v(i);
      rt2_v_n(i) <= rt2_v(i);
      rd2_v_n(i) <= rd2_v(i);
      vrs_v_n(i) <= vrs_v(i);
      -- if wf_active(i) = '0' then
      --   wf_retired_n(i) <= '0';
      -- end if;
      if pc_updated(i) = '1' then
        pc_rdy_n(i) <= '0';
      elsif cram_ack(i) = '1' then
        instr_vec_n(i) <= cram_rdData(DATA_W-1 downto 0);
        instr_macro_vec_n(i) <= cram_rdData(2*DATA_W-1 downto DATA_W);
        instr_gmem_op_n(i) <= '0';
        instr_gmem_read_n(i) <= '0';
        instr_branch_n(i) <= '0';
        instr_jump_n(i) <= '0';
        instr_fpu_n(i) <= '0';
        instr_sync_n(i) <= '0';
        instr_gsync_n(i) <= '0';
        instr_swc_n(i) <= '0';
        instr_dot_n(i) <= '0';
        pc_rdy_n(i) <= '1';
        wf_retired_n(i) <= '0';
        instr_scratchpad_ld_n(i) <= '0';
        instr_sharedmem_ld_n(i) <= '0';
        rs := to_integer(unsigned(cram_rdData(RS_POS+WI_REG_ADDR_W-1 downto RS_POS)));
        rt := to_integer(unsigned(cram_rdData(RT_POS+WI_REG_ADDR_W-1 downto RT_POS)));
        rd := to_integer(unsigned(cram_rdData(RD_POS+WI_REG_ADDR_W-1 downto RD_POS)));
        rs2 := to_integer(unsigned(cram_rdData(DATA_W+RS_POS+WI_REG_ADDR_W-1 downto DATA_W+RS_POS)));
        rt2 := to_integer(unsigned(cram_rdData(DATA_W+RT_POS+WI_REG_ADDR_W-1 downto DATA_W+RT_POS)));
        rd2 := to_integer(unsigned(cram_rdData(DATA_W+RD_POS+WI_REG_ADDR_W-1 downto DATA_W+RD_POS)));
        vrs2 := to_integer(unsigned(cram_rdData(DATA_W+RS_POS+WI_REG_ADDR_W-2 downto DATA_W+RS_POS)));
        vrt2 := to_integer(unsigned(cram_rdData(DATA_W+RT_POS+WI_REG_ADDR_W-2 downto DATA_W+RT_POS)));
        vrd2 := to_integer(unsigned(cram_rdData(RD_POS+WI_REG_ADDR_W-2 downto RD_POS)));
        rd_out_n(i) <= cram_rdData(RD_POS+WI_REG_ADDR_W-1 downto RD_POS);
        rt_v_n(i) <= (others=>'0');
        if rt_v_vec(to_integer(unsigned(cram_rdData(DATA_W-1 downto CODE_POS)))) then
          rt_v_n(i)(rt) <= '1';
        end if;

        rs_v_n(i) <= (others=>'0');
        rs_v_n(i)(rs) <= '1';
        
        rd_v_n(i) <= (others=>'0');
        
        rt2_v_n(i) <= (others=>'0');
        rd2_v_n(i) <= (others=>'0');
        vrs_v_n(i) <= (others=>'0');
        if cram_rdData(DATA_W+FAMILY_POS+FAMILY_W-1 downto DATA_W+FAMILY_POS) = LSI_FAMILY then
          instr_dot_n(i) <= '1';
          vrs_v_n(i)(vrs2) <= '1';
          rd2_v_n(i)(rd2) <= '1';
          rt2_v_n(i)(rt2) <= '1';
        elsif cram_rdData(DATA_W+FAMILY_POS+FAMILY_W-1 downto DATA_W+FAMILY_POS) /= "0000" then
          instr_fpu_n(i) <= '1';
          vrs_v_n(i)(vrs2) <= '1';
          if cram_rdData(DATA_W+CODE_POS+1) = '1' then -- read 2 vregs
            vrs_v_n(i)(vrt2) <= '1';
          end if;
          if cram_rdData(DATA_W+CODE_POS+2) = '1' then -- read greg
            rt2_v_n(i)(rt2) <= '1';
          end if;
        end if;
        case cram_rdData(FAMILY_POS+FAMILY_W-1 downto FAMILY_POS) is
          when GLS_FAMILY | CLS_FAMILY =>
            instr_gmem_op_n(i) <= '1';
            instr_gmem_read_n(i) <= not cram_rdData(CODE_POS+CODE_W-1);
            if cram_rdData(CODE_POS+CODE_W-2 downto CODE_POS) = "111" then
              instr_swc_n(i) <= '1';
              vrs_v_n(i)(vrd2) <= cram_rdData(CODE_POS+CODE_W-1);
            else
              --rd_v_n(i) <= cram_rdData(CODE_POS+CODE_W-1);
              if cram_rdData(CODE_POS+CODE_W-1) then
                rd_v_n(i)(rd) <= '1';
              end if;
            end if;
          when ATO_FAMILY =>
            instr_gmem_op_n(i) <= '1';
            instr_gmem_read_n(i) <= '1';
          when BRA_FAMILY =>
            if cram_rdData(CODE_POS+CODE_W-1 downto CODE_POS) = JSUB then
              --rs_v_n(i) <= '0';
              rs_v_n(i)(rs) <= '0';
              instr_jump_n(i) <= '1';
            else
              instr_branch_n(i) <= '1';
            end if;
            branch_distance_n(i) <= unsigned(cram_rdData(BRANCH_ADDR_POS+BRANCH_ADDR_W-1 downto BRANCH_ADDR_POS));
          when CTL_FAMILY =>
            --rs_v_n(i) <= '0';
            rs_v_n(i)(rs) <= '0';
            if cram_rdData(CODE_POS+CODE_W-1 downto CODE_POS) = RET then
              wf_retired_n(i) <= '1';
            elsif cram_rdData(CODE_POS+CODE_W-1 downto CODE_POS) = SYNC then
              instr_sync_n(i) <= '1';
            elsif cram_rdData(CODE_POS+CODE_W-1 downto CODE_POS) = GSYNC then
              instr_gsync_n(i) <= '1';
            end if;
          when LSI_FAMILY =>
            --rd_v_n(i) <= cram_rdData(CODE_POS+CODE_W-1);
            if cram_rdData(CODE_POS+CODE_W-1) then
              rd_v_n(i)(rd) <= '1';
            end if;
            if cram_rdData(CODE_POS) = '1' then
              instr_sharedmem_ld_n(i) <= not cram_rdData(CODE_POS+CODE_W-1);
              if cram_rdData(CODE_POS+CODE_W-1 downto CODE_POS+1) = "111" then
                vrs_v_n(i)(vrd2) <= cram_rdData(CODE_POS+CODE_W-1);
                instr_swc_n(i) <= '1';
                rd_v_n(i)(rd) <= '0';
              end if;
              --if cram_rdData(CODE_POS+CODE_W-1 downto CODE_POS+1) = "000" then -- vdot
              --  rs_v_n(i) <= '0';
              --end if;
            else
              instr_scratchpad_ld_n(i) <= not cram_rdData(CODE_POS+CODE_W-1);
            end if;
          when FLT_FAMILY =>
            if cram_rdData(CODE_POS+CODE_W-1 downto CODE_POS) = FDIV or 
              cram_rdData(CODE_POS+CODE_W-1 downto CODE_POS) = FSQRT or
              cram_rdData(CODE_POS+CODE_W-1 downto CODE_POS) = FRSQRT then
              instr_fpu_n(i) <= '1';
            end if;
          when MCR_FAMILY =>
            --rs_v_n(i) <= '0';
            if cram_rdData(CODE_POS+CODE_W-1 downto CODE_POS) = CODE_ACT then
              instr_fpu_n(i) <= '1';
            end if;
          when RTM_FAMILY =>
            --rs_v_n(i) <= '0';
            rs_v_n(i)(rs) <= '0';
          when ADD_FAMILY =>
            if cram_rdData(CODE_POS+CODE_W-1 downto CODE_POS) = LUI or cram_rdData(CODE_POS+CODE_W-1 downto CODE_POS) = LI then
              --rs_v_n(i) <= '0';
              rs_v_n(i)(rs) <= '0';
            end if;
          when MUL_FAMILY =>
            if cram_rdData(CODE_POS+CODE_W-1 downto CODE_POS) = MACC then
              --rd_v_n(i) <= '1';
              rd_v_n(i)(rd) <= '1';
            end if;
          when others =>
        end case;
      end if;
    end process;
  end generate;
  
  process(st_cram, cram_rdAddr_i, cram_rdAddr_conf, pc_rdy_i, wf_active, PCs, cram_toggle)
  begin
    cram_rdAddr_n <= cram_rdAddr_i;
    cram_rqst <= '0';
    st_cram_n <= st_cram;
    cram_toggle_n <= cram_toggle;
    case st_cram is
      when check =>
        if cram_toggle(cram_toggle'high) = '1' then
          for i in 0 to N_WF_CU-1 loop
            if wf_active(i)='1' and pc_rdy_i(i)='0' then
              st_cram_n <= request;
              cram_rdAddr_n <= PCs(i);
              cram_toggle_n <= cram_toggle + 1;
            end if;
          end loop;
        else
          for i in N_WF_CU-1 downto 0 loop
            if wf_active(i)='1' and pc_rdy_i(i)='0' then
              st_cram_n <= request;
              cram_rdAddr_n <= PCs(i);
              cram_toggle_n <= cram_toggle + 1;
            end if;
          end loop;
        end if;   
      when request =>
        cram_rqst <= '1';
        st_cram_n <= wait_resp;
      when wait_resp =>
        cram_rqst <= '1';
        if cram_rdAddr_conf = cram_rdAddr_i then
          st_cram_n <= check;
          cram_rqst <= '0';
        end if;
    end case;
  end process;
  ---------------------------------------------------------------------------------------------------------}}}
end Behavioral;

