library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.all;
use work.FGPU_definitions.all;
library fmul;

ENTITY fmul_wrap IS
    PORT (
        aclk : IN STD_LOGIC;
        arst : IN STD_LOGIC;
        s_axis_a_tvalid : IN STD_LOGIC;
        s_axis_a_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        s_axis_b_tvalid : IN STD_LOGIC;
        s_axis_b_tdata : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
        m_axis_result_tvalid : OUT STD_LOGIC;
        m_axis_result_tdata : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
    );
END fmul_wrap;

ARCHITECTURE fmul_arch OF fmul_wrap IS
    constant LATENCY : natural := 3;
    component fmul is
    port (
        clk    : in  std_logic                     := 'X';             -- clk
        areset : in  std_logic                     := 'X';             -- reset
        en     : in  std_logic_vector(0 downto 0)  := (others => 'X'); -- en
        a      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- a
        b      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- b
        q      : out std_logic_vector(31 downto 0)                     -- q
    );
    end component fmul;
    signal v_en : std_logic_vector(0 downto 0) := (others => 'X');
    signal v_out : std_logic_vector(LATENCY-1 downto 0) := (others => 'X');
    signal q: std_logic_vector(31 downto 0) := (others => 'X');
BEGIN
    u0 : component fmul
    port map (
        clk    => aclk,               --    clk.clk
        areset => arst,               -- areset.reset
        en     => v_en,               --     en.en
        a      => s_axis_a_tdata,     --      a.a
        b      => s_axis_b_tdata,     --      b.b
        q      => q --      q.q
    );
    -- generate valid signals
    process (aclk)
    begin
        if (aclk'event and aclk = '1') then
            v_out(0) <= (s_axis_a_tvalid and s_axis_b_tvalid);
            for i in 0 to LATENCY-2 loop
                v_out(i+1) <= v_out(i);
            end loop;
        end if;
    end process;
    v_en(0) <= (s_axis_a_tvalid and s_axis_b_tvalid);
    m_axis_result_tvalid <= v_out(LATENCY-1);
    m_axis_result_tdata <= q;
END fmul_arch;
