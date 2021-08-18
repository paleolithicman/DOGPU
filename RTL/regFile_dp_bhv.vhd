-- libraries -------------------------------------------------------------------------------------------{{{
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.all;
use work.FGPU_definitions.all;
-- library regfile_dp_block;
---------------------------------------------------------------------------------------------------------}}}
entity regFile_dp is
port(
  -- rs_addr, rt_addr     : in unsigned(FREG_FILE_BLOCK_W-2 downto 0); -- level 2.
  -- rd_addr, rx_addr     : in unsigned(FREG_FILE_BLOCK_W-2 downto 0); -- level 2.
  rx_addr               : in unsigned(FREG_FILE_BLOCK_W-2 downto 0); -- level 2.
  rb_addr               : in unsigned(FREG_FILE_BLOCK_W-2 downto 0); -- level 2.
  -- re                   : in std_logic; -- level 2.

  -- rs                   : out std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0):= (others=>'0'); -- level 7.
  -- rt                   : out std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0):= (others=>'0');
  rout                  : out std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0):= (others=>'0'); -- level 6
  re                    : in std_logic; -- level 2.

  we                    : in std_logic_vector(FREG_N_SIMD-1 downto 0); -- level 18.
  wrAddr                : in unsigned(FREG_FILE_BLOCK_W-2 downto 0); -- level 18.
  wrData                : in std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0); -- level 18.

  clk                   : in std_logic
);
end entity;

architecture Behavioral of regFile_dp is
  type reg_array is array (natural range <>) of SLV32_ARRAY(FREG_N_SIMD-1 downto 0);
  -- functions {{{
  function initialize_regfile (depth: integer; data_width: integer; value: integer) return reg_array is
    variable res: reg_array(0 to depth-1);
  begin
    for i in 0 to depth-1 loop
      for j in 0 to data_width/DATA_W-1 loop
        res(i)(j) := std_logic_vector(to_unsigned(value+j*16#40000#, DATA_W));
      end loop;
    end loop;
    return res;
  end;
  -- }}}
  -- signals definitions {{{
  signal regFile_rdAddr                  : unsigned(FREG_FILE_BLOCK_W-2 downto 0) := (others=>'0');
  signal regFile_outData                 : std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others => '0');
  signal regFile_outData_n               : std_logic_vector(FREG_N_SIMD*DATA_W-1 downto 0) := (others => '0');

  signal regFile512: reg_array(0 to 2**(FREG_FILE_BLOCK_W-1)-1) := initialize_regfile(2**(FREG_FILE_BLOCK_W-1), FREG_N_SIMD*DATA_W, 16#41000000#);
  -- }}}
begin
  regFile_Instance: process (clk)
  begin
    if (clk'event and clk = '1') then
      if re = '1' then
        regFile_rdAddr <= rb_addr; -- @ 3
      else
        regFile_rdAddr <= rx_addr;
      end if;
      --if we(0) = '1' then -- level 19.
      --  regFile512(to_integer(wrAddr)) <= wrData; -- @ 20.
      --end if;
      for i in 0 to FREG_N_SIMD-1 loop
        if we(i) = '1' then
          regFile512(to_integer(wrAddr))(i) <= wrData((i+1)*DATA_W-1 downto i*DATA_W);
        end if;
      end loop;
      for i in 0 to FREG_N_SIMD-1 loop
        regFile_outData_n((i+1)*DATA_W-1 downto i*DATA_W) <= regFile512(to_integer(regFile_rdAddr))(i); -- rb @ 4
      end loop;
      regFile_outData <= regFile_outData_n; -- rb @ 5
      rout <= regFile_outData; -- rb @ 6
    end if;
  end process;
  
end Behavioral;

