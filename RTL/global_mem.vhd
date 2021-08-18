-- libraries -------------------------------------------------------------------------------------------{{{
library ieee;
use ieee.std_logic_1164.all;
use ieee.float_pkg.all;
use ieee.numeric_std.ALL;
use ieee.math_real.all;
use ieee.math_complex.all;
library work;
use work.all;
use work.FGPU_definitions.all;
use work.FGPU_simulation_pkg.all;
use ieee.std_logic_textio.all;
use std.textio.all;
---------------------------------------------------------------------------------------------------------}}}
entity global_mem is
-- generics & ports {{{
generic(
  MEM_PHY_ADDR_W    : natural := 13;
  ADDR_OFFSET      : unsigned := X"1000_0000";
  MAX_NDRANGE_SIZE  : natural := 64*1024
);
port(
  new_kernel          : in std_logic;
  finished_kernel     : in std_logic;
  size_0              : in natural;
  size_1              : in natural;
  target_offset_addr  : in natural := 2**(N+L+M-1+2);
  problemSize         : in natural;
  -- AXI Slave Interfaces
  -- common signals
  mx_arlen_awlen      : in std_logic_vector(7 downto 0):= (others=>'0');
  -- interface 0 {{{
  -- ar channel
  m0_araddr           : in std_logic_vector(GMEM_ADDR_W-1 downto 0):= (others=>'0');
  m0_arvalid          : in std_logic := '0';
  m0_arready          : buffer std_logic := '0';
  m0_arid             : in std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- r channel
  m0_rdata            : out std_logic_vector(GMEM_DATA_W-1 downto 0):= (others=>'0');
  m0_rlast            : out std_logic := '0';
  m0_rvalid           : buffer std_logic := '0';
  m0_rready           : in std_logic;
  m0_rid              : out std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- aw channel
  m0_awaddr           : in std_logic_vector(GMEM_ADDR_W-1 downto 0) := (others=>'0');
  m0_awvalid          : in std_logic := '0';
  m0_awready          : buffer std_logic := '0';
  m0_awid             : in std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- w channel
  m0_wdata            : in std_logic_vector(GMEM_DATA_W-1 downto 0):= (others=>'0');
  m0_wstrb            : in std_logic_vector(GMEM_DATA_W/8-1 downto 0):= (others=>'0');
  m0_wlast            : in std_logic := '0';
  m0_wvalid           : in std_logic := '0';
  m0_wready           : buffer std_logic := '0';
  -- b channel
  m0_bvalid           : out std_logic := '0';
  m0_bready           : in std_logic := '0';
  m0_bid              : out std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- }}}
  -- interface 1 {{{
  -- ar channel
  m1_araddr           : in std_logic_vector(GMEM_ADDR_W-1 downto 0):= (others=>'0');
  m1_arvalid          : in std_logic := '0';
  m1_arready          : buffer std_logic := '0';
  m1_arid             : in std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- r channel
  m1_rdata            : out std_logic_vector(GMEM_DATA_W-1 downto 0):= (others=>'0');
  m1_rlast            : out std_logic := '0';
  m1_rvalid           : buffer std_logic := '0';
  m1_rready           : in std_logic;
  m1_rid              : out std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- aw channel
  m1_awaddr           : in std_logic_vector(GMEM_ADDR_W-1 downto 0) := (others=>'0');
  m1_awvalid          : in std_logic := '0';
  m1_awready          : buffer std_logic := '0';
  m1_awid             : in std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- w channel
  m1_wdata            : in std_logic_vector(GMEM_DATA_W-1 downto 0):= (others=>'0');
  m1_wstrb            : in std_logic_vector(GMEM_DATA_W/8-1 downto 0):= (others=>'0');
  m1_wlast            : in std_logic := '0';
  m1_wvalid           : in std_logic := '0';
  m1_wready           : buffer std_logic := '0';
  -- b channel
  m1_bvalid           : out std_logic := '0';
  m1_bready           : in std_logic := '0';
  m1_bid              : out std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- }}}
  -- interface 2 {{{
  -- ar channel
  m2_araddr           : in std_logic_vector(GMEM_ADDR_W-1 downto 0):= (others=>'0');
  m2_arvalid          : in std_logic := '0';
  m2_arready          : buffer std_logic := '0';
  m2_arid             : in std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- r channel
  m2_rdata            : out std_logic_vector(GMEM_DATA_W-1 downto 0):= (others=>'0');
  m2_rlast            : out std_logic := '0';
  m2_rvalid           : buffer std_logic := '0';
  m2_rready           : in std_logic;
  m2_rid              : out std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- aw channel
  m2_awaddr           : in std_logic_vector(GMEM_ADDR_W-1 downto 0) := (others=>'0');
  m2_awvalid          : in std_logic := '0';
  m2_awready          : buffer std_logic := '0';
  m2_awid             : in std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- w channel
  m2_wdata            : in std_logic_vector(GMEM_DATA_W-1 downto 0):= (others=>'0');
  m2_wstrb            : in std_logic_vector(GMEM_DATA_W/8-1 downto 0):= (others=>'0');
  m2_wlast            : in std_logic := '0';
  m2_wvalid           : in std_logic := '0';
  m2_wready           : buffer std_logic := '0';
  -- b channel
  m2_bvalid           : out std_logic := '0';
  m2_bready           : in std_logic := '0';
  m2_bid              : out std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- }}}
  -- interface 3 {{{
  -- ar channel
  m3_araddr           : in std_logic_vector(GMEM_ADDR_W-1 downto 0):= (others=>'0');
  m3_arvalid          : in std_logic := '0';
  m3_arready          : buffer std_logic := '0';
  m3_arid             : in std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- r channel
  m3_rdata            : out std_logic_vector(GMEM_DATA_W-1 downto 0):= (others=>'0');
  m3_rlast            : out std_logic := '0';
  m3_rvalid           : buffer std_logic := '0';
  m3_rready           : in std_logic;
  m3_rid              : out std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- aw channel
  m3_awaddr           : in std_logic_vector(GMEM_ADDR_W-1 downto 0) := (others=>'0');
  m3_awvalid          : in std_logic := '0';
  m3_awready          : buffer std_logic := '0';
  m3_awid             : in std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- w channel
  m3_wdata            : in std_logic_vector(GMEM_DATA_W-1 downto 0):= (others=>'0');
  m3_wstrb            : in std_logic_vector(GMEM_DATA_W/8-1 downto 0):= (others=>'0');
  m3_wlast            : in std_logic := '0';
  m3_wvalid           : in std_logic := '0';
  m3_wready           : buffer std_logic := '0';
  -- b channel
  m3_bvalid           : out std_logic := '0';
  m3_bready           : in std_logic := '0';
  m3_bid              : out std_logic_vector(ID_WIDTH-1 downto 0) := (others=>'0');
  -- }}}
  clk, nrst           : in  std_logic
);
  -- }}}
end global_mem;
architecture Behavioral of global_mem is
  -- constants & functions {{{
  constant C_MEM_SIZE                 : integer := 2**MEM_PHY_ADDR_W;
  CONSTANT MAX_DELAY                  : real := 0.0;
  CONSTANT MIN_DELAY                  : integer := 15; -- delay = min + rand*max
  CONSTANT IMPLEMENT_DELAY            : boolean := true;
  CONSTANT MAX_STEAM_PAUSE            : real := 15.0;
  CONSTANT IMPLEMENT_NO_STREAM_READ   : boolean := false;
  CONSTANT FILL_MODULO                : natural := 49;
  CONSTANT BVALID_DELAY_W             : natural := 2;
  type gmem_type is array (C_MEM_SIZE-1 downto 0) of std_logic_vector(GMEM_DATA_W-1 downto 0);


  -- function called clogb2 that returns an integer which has the
  --value of the ceiling of the log base 2

  function clogb2 (bit_depth : integer) return integer is -- {{{
     variable depth  : integer := bit_depth;                               
     variable count  : integer := 1;                                       
   begin                                                                   
      for clogb2 in 1 to bit_depth loop  -- Works for up to 32 bit integers
        if (bit_depth <= 2) then                                           
          count := 1;                                                      
        else                                                               
          if(depth <= 1) then                                              
            count := count;                                                
          else                                                             
            depth := depth / 2;                                            
            count := count + 1;                                            
          end if;                                                          
        end if;                                                            
     end loop;                                                             
     return(count);                                                        
   end; -- }}}
  function init_mem_with_file(len: in integer; file_name: in string) return gmem_type is  -- {{{
    file init_file : text open read_mode is file_name;
    variable init_line : line;
    variable res : gmem_type := (others=>(others=>'0'));
  begin
    for i in 0 to len-1 loop
      for j in 0 to GMEM_DATA_W/32-1 loop
        -- synthesis translate_off
        readline(init_file, init_line);
        hread(init_line, res(i)((j+1)*32-1 downto j*32));
        -- synthesis translate_on
      end loop;
    end loop;
    return(res);
  end; -- }}}
  function init_me_with_modulu(len: in integer; fill_modulo: in natural) return gmem_type is  -- {{{
    variable i : integer := 0;
    variable res : gmem_type := (others=>(others=>'0'));
  begin
    for i in 0 to len-1 loop --len-1 loop  
      for j in 0 to GMEM_DATA_W/32-1 loop
        res(i)((j+1)*32-1 downto j*32) := std_logic_vector(to_unsigned((i*2+j) mod fill_modulo, 32));
      end loop;
      -- res(i)(31 downto 0) := std_logic_vector(to_unsigned(i, 32) );
      -- res(i)(63 downto 32) := std_logic_vector(to_signed(-i, 32));
    end loop;
    return(res);
  end; -- }}}
  impure function init_mem_fft (size_0: in integer ) return gmem_type is  -- {{{
    variable res : gmem_type := (others=>(others=>'0'));
    variable seed1, seed2 : positive := 1;
    variable rand : real;
    variable tmp_unsigned : unsigned(DATA_W-1 downto 0) := (others=>'0');
    variable nStages, tmp_integer : integer;
    variable tmp_std_logic : std_logic := '0';
    variable li          : line;
  begin
    nStages := 1;
    tmp_integer := 1;
    while tmp_integer < size_0 loop
      tmp_integer := tmp_integer * 2;
      nStages := nStages + 1;
    end loop;
    assert DATA_W*2 = GMEM_DATA_W;
    -- write data with bit reverse
    for i in 0 to 2*size_0-1 loop 
      tmp_unsigned := to_unsigned(i, 32);
      for m in 0 to nStages/2 loop
        tmp_std_logic := tmp_unsigned(nStages-1-m);
        tmp_unsigned(nStages-1-m) := tmp_unsigned(m);
        tmp_unsigned(m) := tmp_std_logic;
      end loop;
      res(to_integer(tmp_unsigned))(DATA_W-1 downto 0) := to_slv(to_float(i mod 4)); -- real part
      res(to_integer(tmp_unsigned))(2*DATA_W-1 downto DATA_W) := (others=>'0');  -- imaginary part
    end loop;
    -- for i in 0 to 7 loop
    --   write(li, to_real(to_float(res(i)(DATA_W-1 downto 0))));
    --   swrite(li, " +j ");
    --   write(li, to_real(to_float(res(i)(2*DATA_W-1 downto DATA_W))));
    --   write(li, LF);
    -- end loop;
    -- writeline(OUTPUT, li);
    
    -- write twiddles
    for i in 0 to 2*size_0-1 loop 
      -- res(C_MEM_SIZE/2 + i)(DATA_W-1 downto 0) := to_slv(to_float(cos(to_real(MATH_PI*i/to_real(size_0)))));
      res(C_MEM_SIZE/4 + i)(DATA_W-1 downto 0) := to_slv(to_float(cos(real(MATH_PI*real(i)/real(size_0)))));
      res(C_MEM_SIZE/4 + i)(2*DATA_W-1 downto DATA_W) := to_slv(-to_float(sin(real(MATH_PI*real(i)/real(size_0)))));
    end loop;
    -- for i in 0 to 7 loop
    --   write(li, to_real(to_float(res(C_MEM_SIZE/4+i)(DATA_W-1 downto 0))));
    --   swrite(li, " +j ");
    --   write(li, to_real(to_float(res(C_MEM_SIZE/4+i)(2*DATA_W-1 downto DATA_W))));
    --   write(li, LF);
    -- end loop;
    -- writeline(OUTPUT, li);
    return(res);
  end; -- }}}
  function init_mem_floydwarshall (len: in integer) return gmem_type is  -- {{{
    variable i : integer := 0;
    variable res : gmem_type := (others=>(others=>'0'));
    variable seed1, seed2 : positive := 1;
    variable rand : real;
  begin
    for i in 0 to len-1 loop --len-1 loop  
      for j in 0 to GMEM_DATA_W/DATA_W-1 loop
        uniform(seed1, seed2, rand);
        res(i)((j+1)*DATA_W-1 downto j*DATA_W) := to_slv(to_float(rand*10.0));
        if i = j then
          res(i)((j+1)*DATA_W-1 downto j*DATA_W) := (others=>'0');
        end if;
      end loop;
    end loop;
    return(res);
  end; -- }}}
  function init_mem_rand_float (len: in integer; data_width: in integer) return gmem_type is  -- {{{
    variable i : integer := 0;
    variable res : gmem_type := (others=>(others=>'0'));
    variable seed1, seed2 : positive := 1;
    variable rand : real;
  begin
    for i in 0 to len-1 loop --len-1 loop  
      for j in 0 to GMEM_DATA_W/data_width-1 loop
        uniform(seed1, seed2, rand);
        res(i)((j+1)*data_width-1 downto j*data_width) := to_slv(to_float(rand));
      end loop;
    end loop;
    return(res);
  end; -- }}}
  function init_mem_rand (len: in integer; data_width: in integer) return gmem_type is  -- {{{
    variable i : integer := 0;
    variable res : gmem_type := (others=>(others=>'0'));
    variable tmp_integer  : integer;
    variable tmp_unsigned : unsigned(DATA_W-1 downto 0) := (others=>'0');
    variable seed1, seed2 : positive := 1;
    variable rand : real;
  begin
    for i in 0 to len-1 loop --len-1 loop  
      for j in 0 to GMEM_DATA_W/data_width-1 loop
        uniform(seed1, seed2, rand);
        rand := rand * 1024.0 * 1024.0 * 1024.0 * 2.0;
        tmp_integer := integer(rand);
        tmp_unsigned := to_unsigned(tmp_integer, DATA_W);
        res(i)((j+1)*data_width-1 downto j*data_width) := std_logic_vector(tmp_unsigned(data_width-1 downto 0));
      end loop;
    end loop;
    return(res);
  end; -- }}}
  function init_mem_rand_no_denorm (len: in integer; data_width: in integer) return gmem_type is  -- {{{
    variable i : integer := 0;
    variable res : gmem_type := (others=>(others=>'0'));
    variable tmp_integer  : integer;
    -- variable tmp_unsigned : unsigned(DATA_W-1 downto 0) := (others=>'0');
    variable tmp_unsigned : unsigned(DATA_W-1 downto 0) := X"3fc00000";
    variable seed1, seed2 : positive := 1;
    variable rand : real;
  begin
    for i in 0 to len-1 loop --len-1 loop  
      for j in 0 to GMEM_DATA_W/data_width-1 loop
        uniform(seed1, seed2, rand);
        rand := rand * 1024.0 * 1024.0 * 1024.0 * 2.0;
        -- tmp_integer := integer(rand);
        -- tmp_unsigned := to_unsigned(tmp_integer, DATA_W);
        if tmp_unsigned(DATA_W-2 downto DATA_W-9) = 0 then
          tmp_unsigned := to_unsigned(0, DATA_W);
        end if;
        res(i)((j+1)*data_width-1 downto j*data_width) := std_logic_vector(tmp_unsigned(data_width-1 downto 0));
      end loop;
    end loop;
    return(res);
  end; -- }}}
  function init_mem_float (len: in integer) return gmem_type is  -- {{{
    variable i : integer := 0;
    variable res : gmem_type := (others=>(others=>'0'));
    variable tmp_unsigned : unsigned(DATA_W-1 downto 0) := (others=>'0');
  begin
    for i in 0 to len-1 loop --len-1 loop  
      for j in 0 to GMEM_DATA_W/DATA_W-1 loop
        tmp_unsigned := to_unsigned(GMEM_DATA_W/DATA_W*i+j, DATA_W);
        res(i)((j+1)*DATA_W-1 downto j*DATA_W) := std_logic_vector(to_float(tmp_unsigned));
      end loop;
    end loop;
    return(res);
  end; --}}}
  function init_mem (len: in integer; data_width: in integer) return gmem_type is  -- {{{
    variable i : integer := 0;
    variable res : gmem_type := (others=>(others=>'0'));
    variable tmp_unsigned : unsigned(DATA_W-1 downto 0) := (others=>'0');
  begin
    for i in 0 to len-1 loop --len-1 loop  
      for j in 0 to GMEM_DATA_W/data_width-1 loop
        tmp_unsigned := to_unsigned(GMEM_DATA_W/data_width*i+j, DATA_W);
        res(i)((j+1)*data_width-1 downto j*data_width) := std_logic_vector(tmp_unsigned(data_width-1 downto 0));
      end loop;
    end loop;
    return(res);
  end; --}}}
  --}}}
  --  read & write addresses {{{
  signal gmem: gmem_type := init_mem(C_MEM_SIZE/2, DATA_W);
  signal tmp_gmem : SLV32_ARRAY(0 to 2**16-1) := (others=>(others=>'0'));
  type mem_phy_addr_array is array(natural range <>) of unsigned(MEM_PHY_ADDR_W-1 downto 0);
  signal wr_addr                          : gmem_addr_array(N_AXI-1 downto 0) := (others=>(others=>'0'));
  type gmem_addr_2d_array is array(natural range <>, natural range <>) of unsigned(GMEM_ADDR_W-1 downto 0);
  signal wr_addr_offset                   : mem_phy_addr_array(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal written_count                    : integer := 0;
  signal cycle_count                      : unsigned(63 downto 0) := (others=>'0');
  signal wf_reach_sync_ltch               : std_logic_vector(N_CU-1 downto 0) := (others=>'0');
  signal written_addrs                    : std_logic_vector(MAX_NDRANGE_SIZE-1 downto 0) := (others=>'0');
  signal new_kernel_d0, new_kernel_d1     : std_logic := '0';
  -- }}}
  -- other signals {{{
  signal delay                            : nat_2d_array(N_AXI-1 downto 0, N_WR_FIFOS_AXI-1 downto 0) := (others=>(others=>0));
  -- }}}
  -- alias signals {{{
  signal wvalid, wready                   : std_logic_vector(N_AXI-1 downto 0) := (others=>'0');
  signal wdata, rdata                     : gmem_word_array(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal wstrb                            : gmem_be_array(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal awready, awvalid                 : std_logic_vector(N_AXI-1 downto 0) := (others=>'0');
  signal arready, arvalid                 : std_logic_vector(N_AXI-1 downto 0) := (others=>'0');
  signal rready, rvalid, rlast            : std_logic_vector(N_AXI-1 downto 0) := (others=>'0');
  signal bvalid, bready                   : std_logic_vector(N_AXI-1 downto 0) := (others=>'0');
  signal araddr, awaddr                   : gmem_addr_array(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal arid, rid, awid, bid             : id_array(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal wlast                            : std_logic_vector(N_AXI-1 downto 0) := (others=>'0');
  type slv_delay_array is array(natural range <>) of std_logic_vector(MIN_DELAY-1 downto 0);
  type gmem_word_delay_array is array(natural range <>) of gmem_word_array(MIN_DELAY-1 downto 0);
  signal rvalid_vec                       : slv_delay_array(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal rdata_vec                        : gmem_word_delay_array(N_AXI-1 downto 0) := (others=>(others=>(others=>'0')));
  -- }}}
  -- read multiplexing {{{
  type st_reader_type is (idle, delay_before_read, send_data);
  type st_reader_array is array (natural range <>, natural range<>) of st_reader_type;
  -- }}}
  -- write signals {{{
  constant c_awaddr_fifo_capacity_w       : natural := 3;
  constant c_awaddr_fifo_capacity         : natural := 2**c_awaddr_fifo_capacity_w;
  -- awaddr fifo
  type awaddr_fifo_array is array(natural range <>) of gmem_addr_array(c_awaddr_fifo_capacity-1 downto 0);
  signal awaddr_fifo                      : awaddr_fifo_array(N_AXI-1 downto 0) := (others=>(others=>(others=>'0')));
  type awaddr_fifo_addr_vec is array(natural range <>) of unsigned(c_awaddr_fifo_capacity_w-1 downto 0);
  signal awaddr_fifo_wrAddr               : awaddr_fifo_addr_vec(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal awaddr_fifo_rdAddr               : awaddr_fifo_addr_vec(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal awaddr_fifo_nempty               : std_logic_vector(N_AXI-1 downto 0) := (others=>'0');
  signal awaddr_fifo_full                 : std_logic_vector(N_AXI-1 downto 0) := (others=>'0');
  signal awaddr_fifo_pop, awaddr_fifo_push: std_logic_vector(N_AXI-1 downto 0) := (others=>'0');
  -- awid fifo
  type awid_fifo_array is array(natural range <>) of id_array(max(1, 2**BVALID_DELAY_W/2**BURST_W)*c_awaddr_fifo_capacity-1 downto 0);
  signal awid_fifo                        : awid_fifo_array(N_AXI-1 downto 0) := (others=>(others=>(others=>'0')));
  type awid_fifo_addr_array is array( natural range <>) of unsigned(c_awaddr_fifo_capacity_w+max(BVALID_DELAY_W-BURST_W, 0)-1 downto 0);
  signal awid_fifo_rdAddr                 : awid_fifo_addr_array(N_AXI-1 downto 0) := (others=>(others=>'0'));
  signal awid_fifo_wrAddr                 : awid_fifo_addr_array(N_AXI-1 downto 0) := (others=>(others=>'0'));
  type st_write_type is (get_address, write);
  type st_write_array is array (natural range <>) of st_write_type;
  signal st_write                         : st_write_array(N_AXI-1 downto 0) := (others=>get_address);
  -- write pipe for delaying bvalid
  type wdata_vec_type is array (natural range <>) of gmem_word_array(N_AXI-1 downto 0);
  signal wdata_vec                        : wdata_vec_type(2**BVALID_DELAY_W-1 downto 0) := (others=>(others=>(others=>'0')));
  type wstrb_vec_type is array(natural range <>) of gmem_be_array(N_AXI-1 downto 0);
  signal wstrb_vec                        : wstrb_vec_type(2**BVALID_DELAY_W-1 downto 0) := (others=>(others=>(others=>'0')));
  type wlast_vec_type is array(natural range <>) of std_logic_vector(N_AXI-1 downto 0);
  signal wlast_vec, wvalid_vec            : wlast_vec_type(2**BVALID_DELAY_W-1 downto 0) := (others=>(others=>'0'));
  type wr_addr_offset_vec_type is array(natural range <>) of mem_phy_addr_array(N_AXI-1 downto 0);
  signal wr_addr_offset_vec               : wr_addr_offset_vec_type(2**BVALID_DELAY_W-1 downto 0) := (others=>(others=>(others=>'0')));
  --}}}
begin
  -- alias signals ---------------------------------------------------------------------------------------{{{
  wvalid(0) <= m0_wvalid;
  wdata(0) <= m0_wdata;
  wstrb(0) <= m0_wstrb;
  wlast(0) <= m0_wlast;
  m0_wready <= wready(0);
  m0_awready <= awready(0);
  awvalid(0) <= m0_awvalid;
  awaddr(0) <= unsigned(m0_awaddr);
  araddr(0) <= unsigned(m0_araddr);
  m0_arready <= arready(0);
  arvalid(0) <= m0_arvalid;
  arid(0) <= m0_arid;
  rready(0) <= m0_rready;
  m0_rvalid <= rvalid(0);
  m0_rid <= rid(0);
  awid(0) <= m0_awid;
  m0_bid <= bid(0);
  m0_rdata <= rdata(0);
  m0_rlast <= rlast(0);
  m0_bvalid <= bvalid(0);
  bready(0) <= m0_bready;
  MORE_THAN_1_W_AXI : if N_AXI > 1 generate
  begin
    wvalid(1) <= m1_wvalid;
    wdata(1) <= m1_wdata;
    wstrb(1) <= m1_wstrb;
    wlast(1) <= m1_wlast;
    m1_wready <= wready(1);
    m1_awready <= awready(1);
    awaddr(1) <= unsigned(m1_awaddr);
    araddr(1) <= unsigned(m1_araddr);
    awvalid(1) <= m1_awvalid;
    m1_arready <= arready(1);
    arvalid(1) <= m1_arvalid;
    arid(1) <= m1_arid;
    rready(1) <= m1_rready;
    m1_rvalid <= rvalid(1);
    m1_rid <= rid(1);
    awid(1) <= m1_awid;
    m1_bid <= bid(1);
    m1_rdata <= rdata(1);
    m1_rlast <= rlast(1);
    m1_bvalid <= bvalid(1);
    bready(1) <= m1_bready;
  end generate;
  MORE_THAN_2_W_AXI: if N_AXI > 2 generate
  begin
    wvalid(2) <= m2_wvalid;
    wdata(2) <= m2_wdata;
    wstrb(2) <= m2_wstrb;
    wlast(2) <= m2_wlast;
    m2_wready <= wready(2);
    m2_awready <= awready(2);
    awvalid(2) <= m2_awvalid;
    awaddr(2) <= unsigned(m2_awaddr);
    araddr(2) <= unsigned(m2_araddr);
    m2_arready <= arready(2);
    arvalid(2) <= m2_arvalid;
    arid(2) <= m2_arid;
    awid(2) <= m2_awid;
    m2_bid <= bid(2);
    rready(2) <= m2_rready;
    m2_rvalid <= rvalid(2);
    m2_rid <= rid(2);
    m2_rdata <= rdata(2);
    m2_rlast <= rlast(2);
    m2_bvalid <= bvalid(2);
    bready(2) <= m2_bready;
  end generate;
  MORE_THAN_3_W_AXI : if N_AXI > 3 generate
  begin
    wvalid(3) <= m3_wvalid;
    wdata(3) <= m3_wdata;
    wstrb(3) <= m3_wstrb;
    wlast(3) <= m3_wlast;
    m3_wready <= wready(3);
    m3_awready <= awready(3);
    awvalid(3) <= m3_awvalid;
    awaddr(3) <= unsigned(m3_awaddr);
    araddr(3) <= unsigned(m3_araddr);
    m3_arready <= arready(3);
    arvalid(3) <= m3_arvalid;
    arid(3) <= m3_arid;
    awid(3) <= m3_awid;
    m3_bid <= bid(3);
    rready(3) <= m3_rready;
    m3_rvalid <= rvalid(3);
    m3_rid <= rid(3);
    m3_rdata <= rdata(3);
    m3_rlast <= rlast(3);
    m3_bvalid <= bvalid(3);
    bready(3) <= m3_bready;
  end generate;
  ---------------------------------------------------------------------------------------------------------}}}
  -- mem module -------------------------------------------------------------------------------------------{{{
  process(clk)
  begin
    if rising_edge(clk) then
      for j in 0 to N_AXI-1 loop
        if wvalid_vec(0)(j) = '1' and wready(j) = '1' then
          for i in 0 to GMEM_DATA_W/8-1 loop
            if wstrb_vec(0)(j)(i) = '1' then
              gmem(to_integer(wr_addr_offset_vec(0)(j)))((i+1)*8-1 downto i*8) <= wdata_vec(0)(j)((i+1)*8-1 downto i*8);
            end if;
          end loop;
        end if;
      end loop;
      if new_kernel = '1' then
        if SIM_READ_MEM_FILE then
          write(output, "initializing memory from file: " & "../RTL/init_mem.mif"  & LF);
                  -- synthesis translate_off
          gmem <= init_mem_with_file(C_MEM_SIZE, "../RTL/init_mem.mif");
                  -- synthesis translate_on
        elsif kernel_name = mat_mul or kernel_name = xcorr  then
          gmem <= init_me_with_modulu(C_MEM_SIZE/2, FILL_MODULO);
        elsif kernel_name = fadd or kernel_name = add_float or kernel_name = mul_float then
          -- gmem <= init_mem_rand_no_denorm(C_MEM_SIZE, 32);
          write(output, "initializing memory from file: " & "../RTL/init_mem.mif" & LF);
                   -- synthesis translate_off
          gmem <= init_mem_with_file(C_MEM_SIZE, "../RTL/init_mem.mif");
                  -- synthesis translate_on
        elsif kernel_name = median or kernel_name = max_half_atomic then
          gmem <= init_mem_rand(C_MEM_SIZE/2, 32);
        elsif kernel_name = floydwarshall then
          gmem <= init_mem_floydwarshall(C_MEM_SIZE/2);
        elsif kernel_name = fft_hard then
          gmem <= init_mem_fft(size_0);
        elsif kernel_name = fir_char4 then
          gmem <= init_mem(C_MEM_SIZE/2, 8);
        elsif kernel_name = parallelSelection then
          gmem <= init_mem_float(C_MEM_SIZE/2);
        -- elsif kernel_name = copy then
        --   write(output, "initializing memory from file: " & file_name & LF);
        --   gmem <= init_mem_with_file(C_MEM_SIZE/2, "../RTL/init_mem.mif");
        -- elsif kernel_name = ludecompose then
        --   gmem <= init_mem_rand(C_MEM_SIZE/2, 32);
        --   -- gmem(0)(DATA_W-1 downto 0) <= to_slv(to_float(121));
        --   -- gmem(0)(2*DATA_W-1 downto DATA_W) <= to_slv(to_float(68));
        --   -- gmem(1)(DATA_W-1 downto 0) <= to_slv(to_float(30));
        --   -- gmem(1)(2*DATA_W-1 downto DATA_W) <= to_slv(to_float(73));
        --   -- gmem(2)(DATA_W-1 downto 0) <= to_slv(to_float(109));
        --   -- gmem(2)(2*DATA_W-1 downto DATA_W) <= to_slv(to_float(94));
        --   -- gmem(3)(DATA_W-1 downto 0) <= to_slv(to_float(62));
        --   -- gmem(3)(2*DATA_W-1 downto DATA_W) <= to_slv(to_float(31));
        --   -- gmem(4)(DATA_W-1 downto 0) <= to_slv(to_float(113));
        --   -- gmem(4)(2*DATA_W-1 downto DATA_W) <= to_slv(to_float(5));
        --   -- gmem(5)(DATA_W-1 downto 0) <= to_slv(to_float(27));
        --   -- gmem(5)(2*DATA_W-1 downto DATA_W) <= to_slv(to_float(106));
        --   -- gmem(6)(DATA_W-1 downto 0) <= to_slv(to_float(33));
        --   -- gmem(6)(2*DATA_W-1 downto DATA_W) <= to_slv(to_float(6));
        --   -- gmem(7)(DATA_W-1 downto 0) <= to_slv(to_float(86));
        --   -- gmem(7)(2*DATA_W-1 downto DATA_W) <= to_slv(to_float(92));
        else
          gmem <= init_mem(C_MEM_SIZE/2, 32);
        end if;
      end if;
    end if;
  end process;
  ---------------------------------------------------------------------------------------------------------}}}
  -- read control -------------------------------------------------------------------------------------------{{{
  process(clk)
    variable rdAddr : gmem_addr_array(N_AXI-1 downto 0) := (others=>(others=>'0'));
  begin
    if rising_edge(clk) then
      if nrst = '0' then
        rvalid_vec <= (others=>(others=>'0'));
      else
        for i in 0 to N_AXI-1 loop
          arready(i) <= '1';
          rlast(i) <= '1';
          rid(i) <= (others=>'0');
          if arvalid(i) = '1' then
            rdAddr(i) := unsigned(araddr(i)) - ADDR_OFFSET;
            rvalid_vec(i)(MIN_DELAY-1) <= '1';
            rdata_vec(i)(MIN_DELAY-1) <= gmem(to_integer(rdAddr(i)(MEM_PHY_ADDR_W+2+GMEM_N_BANK_W-1 downto 2+GMEM_N_BANK_W)));
          else
            rvalid_vec(i)(MIN_DELAY-1) <= '0';
          end if;
          rvalid_vec(i)(MIN_DELAY-2 downto 0) <= rvalid_vec(i)(MIN_DELAY-1 downto 1);
          rdata_vec(i)(MIN_DELAY-2 downto 0) <= rdata_vec(i)(MIN_DELAY-1 downto 1);
          rvalid(i) <= rvalid_vec(i)(0);
          rdata(i) <= rdata_vec(i)(0);
        end loop;
      end if;
    end if;
  end process;
  --read_fsms: process(clk)
  --  variable seed1, seed2 : positive := 1;
  --  variable rand : real;
  --  variable rdAddr, wrAddr        : gmem_addr_2d_array(N_AXI-1 downto 0, N_WR_FIFOS_AXI-1 downto 0) := (others=>(others=>(others=>'0')));
  --  variable st_reader          : st_reader_array(N_AXI-1 downto 0, N_WR_FIFOS_AXI-1 downto 0) := (others=>(others=>idle));
  --  variable rlen            : nat_2d_array(N_AXI-1 downto 0, N_WR_FIFOS_AXI-1 downto 0) := (others=>(others=>0));
  --begin
  --  if rising_edge(clk) then
  --    if nrst = '0' then
  --    else
  --      for i in 0 to N_AXI-1 loop
  --        arready(i) <= '0';
  --        rvalid(i) <= '0';
  --        rlast(i) <= '0';

  --        -- id readers
  --        for j in 0 to N_WR_FIFOS_AXI-1 loop
  --          case st_reader(i, j) is
  --            when idle =>
  --              if arvalid(i) = '1' and arready(i) = '0' and to_integer(unsigned(arid(i))) = j then
  --                arready(i) <= '1';
  --                rdAddr(i, j) := unsigned(araddr(i)) - ADDR_OFFSET;
  --                rlen(i, j) := to_integer(unsigned(mx_arlen_awlen));
  --                if IMPLEMENT_DELAY then
  --                  st_reader(i, j) := delay_before_read;
  --                  uniform(seed1, seed2, rand);
  --                  delay(i, j) <= MIN_DELAY + integer(rand*MAX_DELAY);
  --                else
  --                  st_reader(i, j) := send_data;
  --                end if;
  --              end if;
  --            when delay_before_read =>
  --              if delay(i,j) /= 0 then
  --                delay(i, j) <= delay(i, j) - 1;
  --              else
  --                st_reader(i, j) := send_data;
  --              end if;
  --            when send_data =>
  --              if to_integer(unsigned(rid(i))) = j and rvalid(i) = '1' and rready(i) = '1' then
  --                rdAddr(i, j) := rdAddr(i, j) + GMEM_N_BANK*4;
  --                if rlen(i, j) = 0 then
  --                  st_reader(i, j) := idle;
  --                else
  --                  rlen(i, j) := rlen(i, j) - 1;
  --                  if IMPLEMENT_NO_STREAM_READ then
  --                    uniform(seed1, seed2, rand);
  --                    if rand < 0.5 then
  --                      uniform(seed1, seed2, rand);
  --                      delay(i, j) <= integer(rand*MAX_STEAM_PAUSE);
  --                      st_reader(i, j) := delay_before_read;
  --                    end if;
  --                  end if;
  --                end if;
  --              end if;
  --          end case;
  --        end loop;

  --        for j in 0 to N_WR_FIFOS_AXI-1 loop
  --          if st_reader(i, j) = send_data then
  --            rvalid(i) <= '1';
  --            rdata(i) <= gmem(to_integer(rdAddr(i, j)(MEM_PHY_ADDR_W+2+GMEM_N_BANK_W-1 downto 2+GMEM_N_BANK_W)));
  --            rid(i) <= std_logic_vector(to_unsigned(j, ID_WIDTH));
  --            if rlen(i, j) = 0 then
  --              rlast(i) <= '1';
  --            end if;
  --            exit;
  --          end if;
  --        end loop;

  --      end loop;
  --    end if;
  --  end if;
  --end process;
  ---------------------------------------------------------------------------------------------------------}}}
  -- write control -------------------------------------------------------------------------------------------{{{
  --wr_addr_offset_alias: for i in 0 to N_AXI-1 generate
  --begin
  --  wr_addr_offset(i) <= wr_addr(i)(MEM_PHY_ADDR_W+2+GMEM_N_BANK_W-1 downto 2+GMEM_N_BANK_W);
  --end generate;

  process(clk)
    variable wrAddr : gmem_addr_array(N_AXI-1 downto 0) := (others=>(others=>'0'));
  begin
    if rising_edge(clk) then
      if nrst = '0' then
        wvalid_vec <= (others=>(others=>'0'));
        awready <= (others=>'1');
        wready <= (others=>'1');
      else
        for i in 0 to N_AXI-1 loop
          awready(i) <= '1';
          wready(i) <= '1';
          if awvalid(i) = '1' then
            wrAddr(i) := unsigned(awaddr(i)) - ADDR_OFFSET;
            wr_addr_offset_vec(wr_addr_offset_vec'high)(i) <= wrAddr(i)(MEM_PHY_ADDR_W+2+GMEM_N_BANK_W-1 downto 2+GMEM_N_BANK_W);
          end if;
        end loop;
        wvalid_vec(wvalid_vec'high) <= wvalid;
        wvalid_vec(wvalid_vec'high-1 downto 0) <= wvalid_vec(wvalid_vec'high downto 1);
        wdata_vec(wdata_vec'high) <= wdata;
        wdata_vec(wdata_vec'high-1 downto 0) <= wdata_vec(wdata_vec'high downto 1);
        wstrb_vec(wstrb_vec'high) <= wstrb;
        wstrb_vec(wstrb_vec'high-1 downto 0) <= wstrb_vec(wstrb_vec'high downto 1);
        wr_addr_offset_vec(wr_addr_offset_vec'high-1 downto 0) <= wr_addr_offset_vec(wr_addr_offset_vec'high downto 1);
      end if;
    end if;
  end process;
  
  --awready <= not awaddr_fifo_full;
  --awaddr_fifo_push <= awvalid and awready;
  --process(clk)
  --  variable pop_awaddr: std_logic_vector(N_AXI-1 downto 0) := (others=>'0');
  --  variable seed1, seed2 : positive := 1;
  --  variable rand : real;
  --  variable bid_wait_cycles : natural := 0;
  --begin
  --  if rising_edge(clk) then
  --    if nrst = '0' then
  --      awaddr_fifo_wrAddr <= (others=>(others=>'0'));
  --      awaddr_fifo_rdAddr <= (others=>(others=>'0'));
  --      st_write <= (others=> get_address);
  --      awaddr_fifo_nempty <= (others=>'0');
  --      awaddr_fifo_full <= (others=>'0');
  --      awaddr_fifo_pop <= (others=>'0');
  --      awid_fifo_rdAddr  <= (others=>(others=>'0'));
  --      awid_fifo_wrAddr <= (others=>(others=>'0'));
  --    else
  --      wready <= (others=>'1');
  --      wdata_vec(wdata_vec'high) <= wdata;
  --      wdata_vec(wdata_vec'high-1 downto 0) <= wdata_vec(wdata_vec'high downto 1);
  --      wlast_vec(wlast_vec'high-1 downto 0) <= wlast_vec(wlast_vec'high downto 1);
  --      for i in 0 to N_AXI-1 loop
  --        wlast_vec(wlast_vec'high)(i) <= '0';
  --        if wlast(i) = '1' then
  --          while true loop
  --            uniform(seed1, seed2, rand);
  --            bid_wait_cycles := integer(rand*real(2**BVALID_DELAY_W));
  --            if bid_wait_cycles > 2**BVALID_DELAY_W-2 then
  --              bid_wait_cycles := 2**BVALID_DELAY_W-2;
  --            end if;
  --            -- if bid_wait_cycles = 0 then
  --            --   bid_wait_cycles := 1;
  --            -- end if;
  --            -- report "bid_wait_cycles = " & integer'image(bid_wait_cycles);
  --            if wlast_vec(bid_wait_cycles+1)(i) = '0' then
  --              wlast_vec(bid_wait_cycles)(i) <= '1';
  --              exit;
  --            else
  --              -- report "setting wlast failed";
  --            end if;
  --          end loop;
  --        end if;
  --      end loop;
  --      wvalid_vec(wvalid_vec'high) <= wvalid;
  --      wvalid_vec(wvalid_vec'high-1 downto 0) <= wvalid_vec(wvalid_vec'high downto 1);
  --      wstrb_vec(wstrb_vec'high) <= wstrb;
  --      wstrb_vec(wstrb_vec'high-1 downto 0) <= wstrb_vec(wstrb_vec'high downto 1);
  --      wr_addr_offset_vec(wr_addr_offset_vec'high) <= wr_addr_offset;
  --      wr_addr_offset_vec(wr_addr_offset_vec'high-1 downto 0) <= wr_addr_offset_vec(wr_addr_offset_vec'high downto 1);
  --      for i in 0 to N_AXI-1 loop
  --        if wlast_vec(0)(i) = '1' then
  --          bvalid(i) <= '1';
  --          bid(i) <= awid_fifo(i)(to_integer(awid_fifo_rdAddr(i)));
  --          awid_fifo_rdAddr(i) <= awid_fifo_rdAddr(i) + 1;
  --        elsif bready(i) = '1' then
  --          bvalid(i) <= '0';
  --        end if;
  --        pop_awaddr(i) := '0';
  --        awaddr_fifo_pop(i) <= '0';
  --        case st_write(i) is
  --          when get_address =>
  --            if awaddr_fifo_nempty(i) = '1' then
  --              awaddr_fifo_pop(i) <= '1';
  --              pop_awaddr(i) := '1';
  --              wr_addr(i) <= awaddr_fifo(i)(to_integer(awaddr_fifo_rdAddr(i))) - ADDR_OFFSET;
  --              awaddr_fifo_rdAddr(i) <= awaddr_fifo_rdAddr(i) + 1;
  --              st_write(i) <= write;
  --            end if;
  --          when write =>
  --            if wvalid(i) = '1' and wready(i) = '1' then
  --              wr_addr(i) <= wr_addr(i) + GMEM_N_BANK*4;
  --              if wlast(i) = '1' then
  --                if awaddr_fifo_nempty(i) = '1' then
  --                  awaddr_fifo_pop(i) <= '1';
  --                  pop_awaddr(i) := '1';
  --                  wr_addr(i) <= awaddr_fifo(i)(to_integer(awaddr_fifo_rdAddr(i))) - ADDR_OFFSET;
  --                  awaddr_fifo_rdAddr(i) <= awaddr_fifo_rdAddr(i) + 1;
  --                  st_write(i) <= write;
  --                else
  --                  st_write(i) <= get_address;
  --                end if;
  --              end if;
  --            end if;
  --        end case;
  --        if awaddr_fifo_push(i) = '1' then
  --          -- if to_integer(unsigned(awaddr(i)(17 downto 0))) = 3712 then
  --          --   report "heeere";
  --          -- end if;
  --          awaddr_fifo(i)(to_integer(awaddr_fifo_wrAddr(i))) <= unsigned(awaddr(i));
  --          awaddr_fifo_wrAddr(i) <= awaddr_fifo_wrAddr(i) + 1;
  --          awid_fifo(i)(to_integer(awid_fifo_wrAddr(i))) <= awid(i);
  --          awid_fifo_wrAddr(i) <= awid_fifo_wrAddr(i) + 1;
  --        end if;

  --        if awaddr_fifo_push(i) = '1' and pop_awaddr(i) = '0' and awaddr_fifo_wrAddr(i)+1 = awaddr_fifo_rdAddr(i) then
  --          awaddr_fifo_full(i) <= '1';
  --        elsif awaddr_fifo_push(i) = '0' and pop_awaddr(i) = '1' then
  --          awaddr_fifo_full(i) <= '0';
  --        end if;
  --        if awaddr_fifo_push(i) = '1' and pop_awaddr(i) = '0' then
  --          awaddr_fifo_nempty(i) <= '1';
  --        elsif awaddr_fifo_push(i) = '0' and pop_awaddr(i) = '1' and awaddr_fifo_rdAddr(i)+1 = awaddr_fifo_wrAddr(i) then
  --          awaddr_fifo_nempty(i) <= '0';
  --        end if;
  --      end loop;
  --    end if;
  --  end if;
  --end process;
  --------------------------------------------------------------------------------------------------------}}}
  -- test process -------------------------------------------------------------------------------------------{{{
  test_process: process(clk)
    -- test procedures {{{
    -- variables  {{{
    variable wr_addr_int    : integer := 0;
    variable li          : line;
    variable offset        : integer := 16#0008_0000#;
    variable stride                       : natural := 65;
    variable written_count_tmp  : integer := 0;
    type SLV16_ARRAY is array (natural range <>) of std_logic_vector(15 downto 0);
    type SLV8_ARRAY is array(natural range <>) of std_logic_vector(7 downto 0);
    variable must_data_word    : SLV32_ARRAY(1 downto 0) := (others=>(others=>'0'));
    variable must_data_half    : SLV16_ARRAY(3 downto 0) := (others=>(others=>'0'));
    variable must_data_byte    : SLV8_ARRAY(7 downto 0) := (others=>(others=>'0'));
    variable must_data                    : std_logic_vector(GMEM_DATA_W-1 downto 0) := (others=>'0');
    variable word_addr, second_word_addr  : natural := 0;
    variable byte_addr                    : natural := 0;
    variable half_addr                    : natural := 0;
    variable tmp_signed                   : signed(DATA_W-1 downto 0) := (others=>'0');
    variable tmp_unsigned_64              : unsigned(GMEM_DATA_W-1 downto 0) := (others=>'0');
    variable tmp_unsigned                 : unsigned(DATA_W-1 downto 0) := (others=>'0');
    variable tmp_integer                  : integer;
    variable tmp_float                    : float32 := to_float(0);
    variable tmp_std_logic : std_logic := '0';
    variable rowIndx, colIndx, res, k  : natural := 0;
    variable p00, p01, p02, p10, p11, p12, p20, p21, p22 : unsigned(DATA_W-1 downto 0) := (others=>'0');
    variable nStages, stageIndx, pairDistance, blockWidth, leftIndx, rightIndx: integer := 0;
    variable leftElement, rightElement, greater, lesser : unsigned(DATA_W-1 downto 0) := (others=>'0');
    variable leftElement_float, rightElement_float, greater_float, lesser_float :  float32 := to_float(0);
    variable twiddle, a, b, res_a, res_b : complex;
    variable passIndx, sameDirectionBlock : integer := 0;
    variable nGroups, groupOffset : integer := 0;
    variable x1, y1, z1, m1, x2, y2, z2, m2 : float32 := to_float(0);
    variable xdiff, ydiff, zdiff, distSquared : float32 := to_float(0);
    variable accx, accy, accz, invDist, invDistCube, s : float32 := to_float(0);
    variable oldVelx, oldVely, oldVelz, newVelx, newVely, newVelz : float32 := to_float(0);
    variable softeningFactor : float32 := to_float(500); --  don't change (fixed in sch_ram.xml)
    variable deltaTime : float32 := to_float(0.005); --  don't change (fixed in sch_ram.xml)
    -- }}}
    function canonicalize_float(f: std_logic_vector(31 downto 0)) return std_logic_vector is -- {{{
      variable res : std_logic_vector(31 downto 0) := (others=>'0');
    begin
      res := f;
      if  f(30 downto 23) = X"FF" then --NaN or infinity
        if f(22 downto 0) /= (0 to 22 => '0') then --NaN
          res(22 downto 0) := (0=>'1', others=>'0');
          res(31) := '0';
        end if;
      end if;
      return res;
    end function; -- }}}
    procedure check_kernel is -- {{{
    begin
      for i in 0 to N_AXI-1 loop
        if wvalid(i) = '1' and wready(i) = '1' then
          wr_addr_int := to_integer(unsigned(wr_addr_offset(i)));
          -- assert wr_addr_int /= 16#1b9b8# and wr_addr_int /= 16#1b9b9# and wr_addr_int /= 16#1b9ba# and wr_addr_int /= 16#1b9bb# and wr_addr_int /= 16#1b9bc# and wr_addr_int /= 16#1b9bd# and wr_addr_int /= 16#1b9be# and wr_addr_int /= 16#1b9bf#;
          -- write(output, "0x" & to_hstring(to_signed(word_addr, 32)) & LF);
          if kernel_name = bitonic or kernel_name = fft_hard or kernel_name = floydwarshall then
            word_addr := wr_addr_int*2; -- index of first parameter value
          else
            word_addr := wr_addr_int*2-(offset+target_offset_addr)/4; -- index of first parameter value
          end if;
          second_word_addr := word_addr + 64*1024; -- index of the second parameter
          -- assert word_addr < 64*1024 severity failure;
          assert word_addr >= 0 report integer'image(word_addr) severity failure ;
          byte_addr := word_addr * 4;
          half_addr := word_addr * 2;
          case kernel_name is
            when copy  =>
              for k in 0 to 1  loop
                must_data((k+1)*DATA_W-1 downto k*DATA_W) := std_logic_vector(to_unsigned(word_addr+k, DATA_W));
              end loop;
            when fadd => -- {{{
              --must_data(DATA_W-1 downto 0) := to_slv( to_float(gmem(word_addr/GMEM_N_BANK)(DATA_W-1 downto 0)) * 
              --                                        to_float(gmem(second_word_addr/GMEM_N_BANK)(DATA_W-1 downto 0)) +
              --                                        to_float(gmem(wr_addr_int*2/GMEM_N_BANK)(DATA_W-1 downto 0)) );
              --must_data(2*DATA_W-1 downto DATA_W) := to_slv(to_float(gmem(word_addr/GMEM_N_BANK)(2*DATA_W-1 downto DATA_W)) *
              --                                               to_float(gmem(second_word_addr/GMEM_N_BANK)(2*DATA_W-1 downto DATA_W)) +
              --                                               to_float(gmem(wr_addr_int*2/GMEM_N_BANK)(2*DATA_W-1 downto DATA_W)) );
              -- must_data(DATA_W-1 downto 0) := to_slv( to_float(gmem(word_addr/GMEM_N_BANK)(DATA_W-1 downto 0)) + 
              --                                         to_float(gmem(second_word_addr/GMEM_N_BANK)(DATA_W-1 downto 0)) );
              -- must_data(2*DATA_W-1 downto DATA_W) := to_slv(to_float(gmem(word_addr/GMEM_N_BANK)(2*DATA_W-1 downto DATA_W)) +
              --                                               to_float(gmem(second_word_addr/GMEM_N_BANK)(2*DATA_W-1 downto DATA_W)) );
              -- }}}
            when add_float =>  -- {{{
              must_data(DATA_W-1 downto 0) := to_slv(to_float(gmem(word_addr/GMEM_N_BANK)(DATA_W-1 downto 0)) + to_float(1));
              must_data(2*DATA_W-1 downto DATA_W) := to_slv(to_float(gmem(word_addr/GMEM_N_BANK)(2*DATA_W-1 downto DATA_W)) + to_float(1));
              -- }}}
            when mul_float => -- {{{
              must_data(DATA_W-1 downto 0) := to_slv( to_float(gmem(word_addr/GMEM_N_BANK)(DATA_W-1 downto 0)) * 
                                                      to_float(gmem(second_word_addr/GMEM_N_BANK)(DATA_W-1 downto 0)) );
              must_data(2*DATA_W-1 downto DATA_W) := to_slv(to_float(gmem(word_addr/GMEM_N_BANK)(2*DATA_W-1 downto DATA_W)) *
                                                            to_float(gmem(second_word_addr/GMEM_N_BANK)(2*DATA_W-1 downto DATA_W)) );
              -- }}}
            when mat_mul => -- {{{
              colIndx := word_addr mod size_0;
              rowIndx := word_addr / size_0;
              res := 0;
              for k in 0 to size_0-1 loop
                res := res + ((rowIndx*size_0+k) mod FILL_MODULO) * ((colIndx+k*size_0)mod FILL_MODULO);
              end loop;
              -- res := size_0*size_0*rowIndx*colIndx + (size_0*size_0*rowIndx+colIndx)*(size_0-1)*size_0/2 + size_0*(size_0-1)*size_0*(2*size_0-1)/6;
              must_data(DATA_W-1 downto 0) := std_logic_vector(to_unsigned(res, DATA_W));
              colIndx := (word_addr+1) mod size_0;
              rowIndx := (word_addr+1) / size_0;
              res := 0;
              for k in 0 to size_0-1 loop
                res := res + ((rowIndx*size_0+k) mod FILL_MODULO) * ((colIndx+k*size_0)mod FILL_MODULO);
              end loop;
              must_data(2*DATA_W-1 downto DATA_W) := std_logic_vector(to_unsigned(res, DATA_W));
              -- }}}
            when fir => -- {{{
              res := 0;
              for p in 0 to 5-1 loop
                res := res + (word_addr+p)*p;
              end loop;
              must_data(DATA_W-1 downto 0) := std_logic_vector(to_unsigned(res, DATA_W));
              res := 0;
              for p in 0 to 5-1 loop
                res := res + (word_addr+p+1);
              end loop;
              must_data(2*DATA_W-1 downto DATA_W) := std_logic_vector(to_unsigned(res, DATA_W));
              -- }}}
            when others =>
              report "undifined program index!" severity failure;
          end case; --- }}}
          if wvalid(i) = '1' and wready(i) = '1' then
            case COMP_TYPE is
              when 0 => -- byte {{{
                for k in 0 to 7 loop
                  if wstrb(i)(k) = '1' and must_data((k+1)*8-1 downto k*8) /= wdata(i)((k+1)*8-1 downto k*8) then
                    report  "wdata byte " & integer'image(k) & " on AXI " & integer'image(i) &  
                            " data is " & integer'image(to_integer(unsigned(wdata(i)((k+1)*8-1 downto k*8)))) & 
                            " must be " & integer'image(to_integer(unsigned(must_data((k+1)*8-1 downto k*8)))) &
                            " on byte Nr. " & integer'image(byte_addr) 
                            severity failure;
                  end if;
                  if wstrb(i)(k) = '1' then
                    if written_addrs(byte_addr+k) = '0' then
                      written_count_tmp := written_count_tmp + 1;
                    else
                      -- report "double write";
                    end if;
                    written_addrs(byte_addr+k) <= '1';
                  end if;
                end loop;
                --}}}
              when 1 => -- half word {{{
                for k in 0 to 3 loop
                  assert wstrb(i)((k+1)*2-1 downto k*2) = "00" or must_data((k+1)*16-1 downto k*16) = wdata(i)((k+1)*16-1 downto k*16) 
                  report "wdata half word " & integer'image(k) & " on AXI " & integer'image(i) severity failure;
                  if wstrb(i)(k*2) = '1' then
                    if written_addrs(half_addr+k) = '0' then
                      written_count_tmp := written_count_tmp + 1;
                    else
                      -- report "double write";
                    end if;
                    written_addrs(half_addr+k) <= '1';
                  end if;
                end loop; 
                -- }}}
              when 2 => -- word {{{
                for k in 0 to 1 loop
                  if kernel_name = add_float or kernel_name = mul_float or kernel_name = fadd then
                    if  wstrb(i)((k+1)*DATA_W/8-1 downto k*DATA_W) = X"F" then
                      if canonicalize_float(must_data((k+1)*DATA_W-1 downto k*DATA_W)) /= 
                      canonicalize_float(wdata(i)((k+1)*DATA_W-1 downto k*DATA_W)) then
                        --write(output, "wdata word " & integer'image(k) & " on AXI " & integer'image(i) & " is " & 
                        --   "0x" & to_hstring(unsigned(wdata(i)((k+1)*DATA_W-1 downto k*DATA_W))) & 
                        --   " (should be " & "0x" & to_hstring(unsigned(must_data((k+1)*DATA_W-1 downto k*DATA_W))) & ") for word_addr = " &
                        --   integer'image(word_addr+k) & LF);
                        if kernel_name = fadd then
                          -- write(li, to_real(to_float(gmem(word_addr/GMEM_N_BANK)((k+1)*DATA_W-1 downto k*DATA_W))));
                          -- write(li, LF);
                          -- write(li, to_real(to_float(must_data((k+1)*DATA_W-1 downto k*DATA_W))));
                          -- writeline(output, li);
                        else
                          write(output, to_hstring(gmem(word_addr/GMEM_N_BANK)((k+1)*DATA_W-1 downto k*DATA_W))&LF);
                          write(output, to_hstring(gmem(second_word_addr/GMEM_N_BANK)((k+1)*DATA_W-1 downto k*DATA_W))&LF);
                        end if;
                        -- assert false ;
                        -- assert false severity failure;
                      end if;
                    end if;
                  elsif kernel_name /= sum_atomic then
                    if  wstrb(i)((k+1)*DATA_W/8-1 downto k*DATA_W) = X"F" and
                        must_data((k+1)*DATA_W-1 downto k*DATA_W) /= wdata(i)((k+1)*DATA_W-1 downto k*DATA_W) then
                      write(output, "wdata word " & integer'image(k) & " on AXI " & integer'image(i) & " is " & 
                           integer'image(to_integer(unsigned(wdata(i)((k+1)*DATA_W-1 downto k*DATA_W)))) & 
                           " (should be " & integer'image(to_integer(unsigned(must_data((k+1)*DATA_W-1 downto k*DATA_W)))) & ") for word_addr = " &
                           integer'image(word_addr+k) & LF);
                      assert false severity failure;
                    end if;
                  end if;
                  if wstrb(i)(k*DATA_W/8) = '1' then
                    if written_addrs(word_addr+k) = '0' then
                      written_count_tmp := written_count_tmp + 1;
                    else
                      -- report "double write";
                    end if;
                    written_addrs(word_addr+k) <= '1';
                  end if;
                end loop;
                -- }}}
              when others =>
                report "undefined computation type!" severity failure;
            end case;
          end if;
        end if;
      end loop;
    end procedure;
    procedure check_written_count(num: integer) is
    begin
      if written_count = num then
        if STAT = 0 then
          report "Kernel finished successfully! Size was :"&integer'image(num);
        end if;
      else
        report "XXXXXXXXXXXXXXXXXXXX    NOT ALL RESULTS ARE WRITTEN XXXXXXXXXXXXXXXXXX  ! Size was :"&integer'image(num)& " written are: "&integer'image(written_count);
        -- for i in 0 to num-1 loop
        --   assert written_addrs(i) = '1' report "The address "&integer'image(i)&" is not written" severity failure;
        -- end loop;
        -- assert false severity failure;

      end if;
    end procedure;
    procedure write_mem_to_file(len: in integer; file_name: in string) is
      file result_file : text open write_mode is file_name;
      variable result_line : line;
      variable tmp_data : std_logic_vector(31 downto 0) := (others=>'0');
    begin
      write(output, "writing memory to file: " & file_name & LF);
      for i in 0 to len-1 loop
        for j in 0 to GMEM_DATA_W/32-1 loop
          tmp_data := gmem(i)((j+1)*32-1 downto j*32);
          hwrite(result_line, tmp_data);
          writeline(result_file, result_line);
        end loop;
      end loop;
    end;
    procedure check_kernel_with_file(file_name : in string; start: in integer; len : in integer) is
      file must_file : text open read_mode is file_name;
      variable must_line : line;
      variable tmp_data : std_logic_vector(31 downto 0) := (others=>'0');
    begin
      write(output, "start comparing result with " & file_name & LF);
      for i in 0 to len-1 loop
        for j in 0 to GMEM_DATA_W/32-1 loop
          readline(must_file, must_line);
          hread(must_line, tmp_data);
          if gmem(start+i)((j+1)*32-1 downto j*32) /= tmp_data(31 downto 0) then
            write(output, "word" & integer'image(i*GMEM_DATA_W/32+j) & " is " & 
            integer'image(to_integer(unsigned(gmem(start+i)((j+1)*32-1 downto j*32)))) &
            " (should be " & integer'image(to_integer(unsigned(tmp_data))));
            assert false severity failure;
          end if;
        end loop;
      end loop;
      write(output, "PASSED" & LF);
    end procedure;
    -- }}}
  begin
    if rising_edge(clk) then
      written_count_tmp := 0;
      -- check_kernel;
      new_kernel_d0 <= new_kernel;
      new_kernel_d1 <= new_kernel_d0;
      wf_reach_sync_ltch <= <<signal .FGPU_tb.uut.wf_reach_gsync: std_logic_vector >>;

      if new_kernel = '1' then
        cycle_count <= to_unsigned(0, 64);
        written_count <= 0;
        written_addrs <= (others=>'0');
        if kernel_name = bitonic then
          for i in 0 to 2**16-1 loop
            tmp_gmem(i) <= std_logic_vector(to_unsigned(i, 32));
          end loop;
          nStages := 1;
          tmp_integer := 1;
          while tmp_integer < size_0 loop
            tmp_integer := tmp_integer * 2;
            nStages := nStages + 1;
          end loop;
          stageIndx := 0;
          passIndx := 0;
        elsif kernel_name = fft_hard then
          nStages := 1;
          tmp_integer := 1;
          while tmp_integer < size_0 loop
            tmp_integer := tmp_integer * 2;
            nStages := nStages + 1;
          end loop;
          stageIndx := 0;
          
          -- with bit reverse
          for i in 0 to size_0*2-1 loop
            tmp_unsigned := to_unsigned(i, 32);
            for j in 0 to nStages/2 loop
              tmp_std_logic := tmp_unsigned(nStages-1-j);
              tmp_unsigned(nStages-1-j) := tmp_unsigned(j);
              tmp_unsigned(j) := tmp_std_logic;
            end loop;
            tmp_gmem(2*to_integer(tmp_unsigned)) <= to_slv(to_float(i mod 4)); -- real part
            tmp_gmem(2*to_integer(tmp_unsigned)+1) <= (others=>'0');  -- imaginary part
          end loop;
        end if;
      else
        written_count <= written_count + written_count_tmp;
        cycle_count <= cycle_count + 1;
        if to_integer(cycle_count) mod 1000 = 0 then
          write(output, "cycle: " & integer'image(to_integer(cycle_count)) & LF);
        end if;
        if <<signal .FGPU_tb.uut.wf_reach_gsync: std_logic_vector >> = (0 to N_CU-1 =>'1') and wf_reach_sync_ltch /= (0 to N_CU-1=>'1') then
          if <<signal .FGPU_tb.uut.compute_units_inst.compute_units_i_low(0).compute_unit_inst.CUS_inst.global_syncing: std_logic >> = '1' then
            write(output, "gsync reached, cycle: " & integer'image(to_integer(cycle_count)) & LF);
          elsif <<signal .FGPU_tb.uut.compute_units_inst.compute_units_i_low(1).compute_unit_inst.CUS_inst.global_syncing: std_logic >> = '1' then
            write(output, "gsync reached, cycle: " & integer'image(to_integer(cycle_count)) & LF);
          elsif <<signal .FGPU_tb.uut.compute_units_inst.compute_units_i_low(2).compute_unit_inst.CUS_inst.global_syncing: std_logic >> = '1' then
            write(output, "gsync reached, cycle: " & integer'image(to_integer(cycle_count)) & LF);
          elsif <<signal .FGPU_tb.uut.compute_units_inst.compute_units_i_low(3).compute_unit_inst.CUS_inst.global_syncing: std_logic >> = '1' then
            write(output, "gsync reached, cycle: " & integer'image(to_integer(cycle_count)) & LF);
          elsif <<signal .FGPU_tb.uut.compute_units_i_high(4).compute_unit_inst.CUS_inst.global_syncing: std_logic >> = '1' then
            write(output, "gsync reached, cycle: " & integer'image(to_integer(cycle_count)) & LF);
          elsif <<signal .FGPU_tb.uut.compute_units_i_high(5).compute_unit_inst.CUS_inst.global_syncing: std_logic >> = '1' then
            write(output, "gsync reached, cycle: " & integer'image(to_integer(cycle_count)) & LF);
          elsif <<signal .FGPU_tb.uut.compute_units_i_high(6).compute_unit_inst.CUS_inst.global_syncing: std_logic >> = '1' then
            write(output, "gsync reached, cycle: " & integer'image(to_integer(cycle_count)) & LF);
          elsif <<signal .FGPU_tb.uut.compute_units_i_high(7).compute_unit_inst.CUS_inst.global_syncing: std_logic >> = '1' then
            write(output, "gsync reached, cycle: " & integer'image(to_integer(cycle_count)) & LF);
          end if;
        end if;
      end if;
      if finished_kernel = '1' then
        write(output, "CYCLES SPENT EXECUTING KERNEL: " & integer'image(to_integer(cycle_count)) & LF);
        if SIM_WRITE_MEM_FILE then
          write_mem_to_file(C_MEM_SIZE, "../RTL/result_mem.mif");
        end if;
        if SIM_CHECK_MEM_FILE then
          check_kernel_with_file("../RTL/test_result.mif", 16#00010000#, 1024);
        end if;
        -- if COMP_TYPE = 0 then -- byte mode
        --   check_written_count(size_0*size_1*4);
        -- elsif kernel_name = median then
        --   check_written_count(size_0*size_1-2*(size_0-1)-2*(size_1-1)); -- no write for edge pixels
        -- else
        --   check_written_count(size_0*size_1);
        -- end if;
      end if;
        -- write(li, std_logic_vector(wr_addr_offset(0)));
        -- writeline(OUTPUT, li);
        -- report "written addr: " & integer'image(2*(wr_addr_int-16#400#));

    end if;
  end process;
  ---------------------------------------------------------------------------------------------------------}}}
  -- performance measurements ------------------------------------------------------------------------------{{{
  perf_count: if STAT = 1 generate
    process(clk)
      -- variable n_empty_bytes, n_written_bytes : natural := 0;
      -- variable empty_bytes_percentage: real := 0.0;
      variable min_n_bursts, n_wr_increase, n_rd_increase : real := 0.0;
      variable min_n_read_bursts, min_n_write_bursts : real := 0.0;
      variable n_wr_bursts, n_rd_bursts : natural := 0;
      variable size, data_size_word  : natural := 0;
    begin
      if rising_edge(clk) then
        if finished_kernel = '1' then
          -- if kernel_name = sum_atomic or kernel_name = max_half_atomic then
          --   data_size_word := problemSize;
          --   -- empty_bytes_percentage := real(n_empty_bytes)/real(n_written_bytes);
          --   -- report "# of written empty bytes = " & integer'image(n_empty_bytes);
          --   -- report "# of written bytes = " & integer'image(n_written_bytes);
          --   min_n_read_bursts := ceil(real(data_size_word)/real(GMEM_N_BANK)/real(to_integer(unsigned(mx_arlen_awlen)+1))); -- smallest number of bursts need ti finish the task
          --   min_n_write_bursts := ceil(real(1)/real(GMEM_N_BANK)/real(to_integer(unsigned(mx_arlen_awlen)+1)));
          --   n_wr_increase := real(n_wr_bursts)/min_n_write_bursts*100.0 - 100.0;
          --   n_rd_increase := real(n_rd_bursts)/min_n_read_bursts*100.0 - 100.0;
          --   report "Problem size= "&integer'image(data_size_word) & ", # WR Bursts= " & integer'image(n_wr_bursts) & " (+" & integer'image(integer(n_wr_increase)) &"%)" & 
          --           ", # RD Bursts= " & integer'image(n_rd_bursts) & " (+" & integer'image(integer(n_rd_increase)) &"%)";
          --   -- n_empty_bytes := 0;
          --   -- n_written_bytes := 0;
          --   n_wr_bursts := 0;
          --   n_rd_bursts := 0;
          -- elsif kernel_name /= bitonic  and kernel_name /= fft_hard then
          --   size := size_0*size_1;
          --   if COMP_TYPE = 0 then -- byte
          --     data_size_word := size_0*size_1 / 4;
          --   elsif COMP_TYPE = 1 then -- half word
          --     data_size_word := size_0*size_1 / 2;
          --   else -- word
          --     data_size_word := size_0*size_1;
          --   end if;
          --   -- empty_bytes_percentage := real(n_empty_bytes)/real(n_written_bytes);
          --   -- report "# of written empty bytes = " & integer'image(n_empty_bytes);
          --   -- report "# of written bytes = " & integer'image(n_written_bytes);
          --   min_n_bursts := ceil(real(data_size_word)/real(GMEM_N_BANK)/real(to_integer(unsigned(mx_arlen_awlen)+1))); -- smallest number of bursts need ti finish the task
          --   n_wr_increase := real(n_wr_bursts)/min_n_bursts*100.0 - 100.0;
          --   n_rd_increase := real(n_rd_bursts)/min_n_bursts*100.0 - 100.0;
          --   -- report "Size= "&integer'image(data_size_word) &", Empty written bytes = " & integer'image(integer(empty_bytes_percentage)) & " %"&", # Bursts= " &
          --   --       integer'image(n_wr_bursts) & " (+" & integer'image(integer(n_wr_increase)) &" %)";
          --   report "Size= "&integer'image(size) & ", # WR Bursts= " & integer'image(n_wr_bursts) & " (+" & integer'image(integer(n_wr_increase)) &"%)" & 
          --           ", # RD Bursts= " & integer'image(n_rd_bursts) & " (+" & integer'image(integer(n_rd_increase)) &"%)";
          --   -- n_empty_bytes := 0;
          --   -- n_written_bytes := 0;
          --   n_wr_bursts := 0;
          --   n_rd_bursts := 0;
          -- end if;
        else
          for i in 0 to N_AXI-1 loop
            if awvalid(i) = '1' and awready(i) = '1' then
              n_wr_bursts := n_wr_bursts + 1;
            end if;
            if arvalid(i) = '1' and arready(i) = '1' then
              n_rd_bursts := n_rd_bursts + 1;
            end if;
            -- if wvalid(i) = '1' then
            --   for j in 0 to GMEM_DATA_W/8-1 loop
            --     if wstrb(i)(j) = '1' then
            --       -- n_written_bytes := n_written_bytes + 1;
            --     else
            --       -- n_empty_bytes := n_empty_bytes + 1;
            --     end if;
            --   end loop;
            -- end if;
          end loop;
        end if;
      end if;
    end process;
  end generate;
  ---------------------------------------------------------------------------------------------------------}}}
  ---------------------------------------------------------------------------------------------------------- }}}
end Behavioral;

