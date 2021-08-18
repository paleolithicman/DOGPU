LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;

ENTITY fdiv_wrap IS
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
END fdiv_wrap;

ARCHITECTURE fdiv_arch OF fdiv_wrap IS
    constant LATENCY_A : natural := 24;
    constant LATENCY_X : natural := 28;
    component fdiv is
    port (
        clk    : in  std_logic                     := 'X';             -- clk
        areset : in  std_logic                     := 'X';             -- reset
        en     : in  std_logic_vector(0 downto 0)  := (others => 'X'); -- en
        a      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- a
        b      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- b
        q      : out std_logic_vector(31 downto 0)                     -- q
    );
    end component fdiv;
    signal v_en : std_logic_vector(0 downto 0) := (others => 'X');
    signal v_out : std_logic_vector(LATENCY_X-1 downto 0) := (others => 'X');
    type res_array is array (0 to LATENCY_X-LATENCY_A-1) of std_logic_vector(31 downto 0);
    signal q_out : res_array := (others=>(others => 'X'));
    signal q: std_logic_vector(31 downto 0) := (others => 'X');
BEGIN
    u0 : component fdiv
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
            for i in 0 to LATENCY_X-2 loop
                v_out(i+1) <= v_out(i);
            end loop;
            for i in 0 to LATENCY_X-LATENCY_A-2 loop
                q_out(i+1) <= q_out(i);
            end loop;
            q_out(0) <= q;
            v_out(0) <= (s_axis_a_tvalid and s_axis_b_tvalid);
        end if;
    end process;
    v_en(0) <= (s_axis_a_tvalid and s_axis_b_tvalid);
    m_axis_result_tvalid <= v_out(LATENCY_X-1);
    m_axis_result_tdata <= q_out(LATENCY_X-LATENCY_A-1);
END fdiv_arch;