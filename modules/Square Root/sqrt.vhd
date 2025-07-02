
-- ieee packages ------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Square root Newton Raphson
entity sqrt is
  generic (
    sqrt_implementation : natural := 0;
    size                : natural := 32;
    fraction_size       : natural := 0  -- size of the fractional part for fixed point sqrt
  );
  port (
    clk_i          : in  std_logic;
    rst_ni         : in  std_logic;
    start          : in  std_logic;
    number         : in  std_logic_vector(size-1 downto 0); -- Input number as std_logic_vector
    sqrt_res       : out std_logic_vector(size-1 downto 0); -- Output square root as std_logic_vector
    busy           : out std_logic;
    ready          : out std_logic;
    precision_sqrt : out std_logic;  -- Indicates result is exactly in the middle
    inexact_sqrt   : out std_logic  -- Indicates the result is not exact
  );
end sqrt;

architecture behavioral of sqrt is

  -- Square root Newton Raphson
  component sqrt_nr is
    generic (
      size                : natural := 32;
      fraction_size       : natural := 0
    );
    port (
      clk_i          : in  std_logic;
      rst_ni         : in  std_logic;
      start          : in  std_logic;
      number         : in  std_logic_vector(size-1 downto 0); -- Input number as std_logic_vector
      sqrt_res       : out std_logic_vector(size-1 downto 0); -- Output square root as std_logic_vector
      busy           : out std_logic;
      ready          : out std_logic;
      precision_sqrt : out std_logic;  -- Indicates result is exactly in the middle
      inexact_sqrt   : out std_logic  -- Indicates the result is not exact
    );
  end component;

begin

  sqrt_nr_gen : if (sqrt_implementation = 0) generate
  -- Square root Newton Raphson
  sqrt_nr_inst : sqrt_nr
    generic map(
      size          => size,
      fraction_size => fraction_size 
    )
    port map(
      clk_i          => clk_i,
      rst_ni         => rst_ni,
      start          => start,
      number         => number,
      sqrt_res       => sqrt_res,
      busy           => busy,
      ready          => ready,
      precision_sqrt => precision_sqrt,
      inexact_sqrt   => inexact_sqrt
    );
  end generate;

end architecture behavioral;
