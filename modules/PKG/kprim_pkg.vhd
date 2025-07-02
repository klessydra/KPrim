-- ieee packages
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.math_real.all;


package kprim_pkg is

  function add_vect_bits(vect : std_logic_vector) return natural;
  function or_vect_bits(vector : std_logic_vector) return std_logic;
  function and_vect_bits(vector : std_logic_vector) return std_logic;

end package;

package body kprim_pkg is

  function add_vect_bits(vect : std_logic_vector) return natural is
    variable count : natural;
  begin
    count := 0;
    for i in vect'range loop
      if vect(i) = '1' then
        count := count + 1;
      end if;
    end loop;
    return count;
  end function add_vect_bits;

  function or_vect_bits(vector : std_logic_vector) return std_logic is
    variable or_result : std_logic := '0';
  begin
    for i in vector'range loop
      or_result := or_result or vector(i);
    end loop;
    return or_result;
  end function or_vect_bits;

  function and_vect_bits(vector : std_logic_vector) return std_logic is
    variable and_result : std_logic := '1';
  begin
    for i in vector'range loop
      and_result := and_result and vector(i);
    end loop;
    return and_result;
  end function and_vect_bits;

end package body;