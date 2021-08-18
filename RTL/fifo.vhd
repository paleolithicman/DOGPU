-- libraries --------------------------------------------------------------------------------------------{{{
library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.all;
use work.FGPU_definitions.all;
---------------------------------------------------------------------------------------------------------}}}
entity fifo is -- {{{
generic(
  FIFO_WIDTH  : integer := 32;
  LG_DEPTH    : integer := 1
);
port(
  clk                     : in  std_logic;
  enq                     : in  std_logic;
  deq                     : in  std_logic;
  din                     : in  std_logic_vector(FIFO_WIDTH - 1 downto 0);
  dout                    : out std_logic_vector(FIFO_WIDTH - 1 downto 0);
  valid                   : out std_logic := '0';
  full                    : out std_logic := '0';
  nrst                    : in  std_logic
);
end entity; -- }}}
architecture behavioral of fifo is
  -- signals {{{
  constant DEPTH                          : integer := 2**LG_DEPTH;

  type ramType is array (natural range <>) of std_logic_vector(FIFO_WIDTH - 1 downto 0);
  signal fifo                             : ramType(0 to DEPTH-1) := (others=>(others=>'0'));
  signal fifo_re                          : std_logic := '0';
  signal fifo_notEmpty                    : std_logic := '0';
  signal fifo_wrData                      : std_logic_vector(FIFO_WIDTH-1 downto 0) := (others=>'0');
  signal fifo_rdAddr                      : unsigned(LG_DEPTH-1 downto 0) := (others=>'0');
  signal fifo_wrAddr                      : unsigned(LG_DEPTH-1 downto 0) := (others=>'0');
  signal fifo_count                       : unsigned(LG_DEPTH downto 0) := (others=>'0');
  -- }}}
begin
  fifo_notEmpty <= '1' when fifo_count /= 0 else '0';
  full <= '1' when fifo_count = DEPTH-1 else '0';
  fifo_re <= fifo_notEmpty and ((not valid) or deq);
  process(clk)
  begin
    if rising_edge(clk) then
      if enq = '1' then
        fifo(to_integer(fifo_wrAddr)) <= din;
      end if;
      if fifo_re = '1' then
        dout <= fifo(to_integer(fifo_rdAddr));
      end if;

      if nrst = '0' then
        fifo_wrAddr <= (others=>'0');
        fifo_rdAddr <= (others=>'0');
        valid <= '0';
        fifo_count <= (others=>'0');
      else
        if enq = '1' then
          fifo_wrAddr <= fifo_wrAddr + 1;
        end if;
        if fifo_re = '1' then
          fifo_rdAddr <= fifo_rdAddr + 1;
          valid <= '1';
        elsif deq then
          valid <= '0';
        end if;
        if fifo_re = '1' and (enq /= '1') and (fifo_count /= 0) then
          fifo_count <= fifo_count - 1;
        elsif enq = '1' and (fifo_re /= '1') and (fifo_count /= DEPTH) then
          fifo_count <= fifo_count + 1;
        end if;
      end if;
    end if;
  end process;
end architecture;

-- libraries --------------------------------------------------------------------------------------------{{{
library ieee;
use ieee.std_logic_1164.all;
use IEEE.NUMERIC_STD.ALL;
library work;
use work.all;
use work.FGPU_definitions.all;
---------------------------------------------------------------------------------------------------------}}}
entity fifo2 is -- {{{
generic(
  FIFO_WIDTH  : integer := 32
);
port(
  clk                     : in  std_logic;
  enq                     : in  std_logic;
  deq                     : in  std_logic;
  din                     : in  std_logic_vector(FIFO_WIDTH - 1 downto 0);
  dout                    : out std_logic_vector(FIFO_WIDTH - 1 downto 0);
  empty                   : out std_logic := '0';
  full                    : out std_logic := '0';
  nrst                    : in  std_logic
);
end entity; -- }}}
architecture behavioral of fifo2 is
  -- signals {{{
  signal fifo                             : std_logic_vector(FIFO_WIDTH-1 downto 0) := (others=>'0');
  signal fifo_re                          : std_logic := '0';
  signal fifo_notEmpty                    : std_logic := '0';
  signal fifo_wrData                      : std_logic_vector(FIFO_WIDTH-1 downto 0) := (others=>'0');
  signal fifo_count                       : unsigned(1 downto 0) := (others=>'0');
  -- }}}
begin
  empty <= nor fifo_count;
  full <= fifo_count(1);
  process(clk)
  begin
    if rising_edge(clk) then
      if enq = '1' then
        if empty = '1' or deq = '1' then
          dout <= din;
        else
          fifo <= din;
        end if;
      else
        if deq = '1' then
          dout <= fifo;
        end if;
      end if;

      if nrst = '0' then
        fifo_count <= (others=>'0');
      else
        if deq = '1' and (enq /= '1') and (fifo_count /= 0) then
          fifo_count <= fifo_count - 1;
        elsif enq = '1' and (deq /= '1') and (fifo_count /= 2) then
          fifo_count <= fifo_count + 1;
        end if;
      end if;
    end if;
  end process;
end architecture;