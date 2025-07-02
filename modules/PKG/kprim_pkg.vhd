-- ieee packages
library ieee;
use ieee.std_logic_1164.all;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use std.textio.all;
use ieee.math_real.all;


package kprim is

  function or_vect_bits(input_vector : in std_logic_vector)  return std_logic;
  function and_vect_bits(input_vector : in std_logic_vector) return std_logic;


end package;

package body kprim is

  function or_vect_bits(input_vector : std_logic_vector) return std_logic is
    variable result : std_logic := '0';
  begin
    for i in input_vector'range loop
      result := result or input_vector(i);
    end loop;
    return result;
  end function or_vect_bits;

  function and_vect_bits(input_vector : std_logic_vector) return std_logic is
    variable result : std_logic := '0';
  begin
    for i in input_vector'range loop
      result := result and input_vector(i);
    end loop;
    return result;
  end function and_vect_bits;

end package body;
