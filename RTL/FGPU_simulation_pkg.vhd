-- libraries --------------------------------------------------------------------------------- {{{
library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.ALL;
use ieee.std_logic_textio.all;
use std.textio.all;
------------------------------------------------------------------------------------------------- }}}
package FGPU_simulation_pkg is
  type kernel_type is ( test, copy, max_half_atomic, bitonic,  fadd,  median, floydwarshall, fir_char4, add_float, parallelSelection,  mat_mul,  fir,  xcorr,  sum_atomic,  fft_hard,   mul_float,  sobel );

  CONSTANT kernel_name        : kernel_type := test;
  -- byte(0), half word(1), word(2)
  CONSTANT COMP_TYPE          : natural := 2;

  -- slli(0), sll(1), srli(2), srl(3), srai(4), sra(5), andi(6), and(7), ori(8), or(9), xori(10), xor(11), nor(12), sllb(13), srlb(14), srab(15)
  CONSTANT LOGIC_OP           : natural := 15;
  CONSTANT REDUCE_FACTOR      : natural := 1;
  
  function get_kernel_index (name: in kernel_type) return integer;

end FGPU_simulation_pkg;

package body FGPU_simulation_pkg is
  function get_kernel_index (name: in kernel_type) return integer is
  begin
    case name is
      when test =>
        return 0;
      when others=>
        assert(false) severity failure;
        return 0;
    end case;
  end; -- function reverse_any_vector
end FGPU_simulation_pkg;
