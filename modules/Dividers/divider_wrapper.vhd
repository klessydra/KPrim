library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;


entity divider is
  generic (
    size : natural := 32
  );
  Port (
    dividend_i            : in  std_logic_vector(size-1 downto 0);
    divisor_i             : in  std_logic_vector(size-1 downto 0);
    reset                 : in  std_logic;
    clk                   : in  std_logic;
    div_enable_i          : in  std_logic;
    division_finished_out : out std_logic;
    result                : out std_logic_vector((size*2)-1 downto 0) -- Decomment if you want to see the result
  );
end divider;

architecture Behavioral of divider is
begin

end Behavioral; 