library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- Divider Implementations:
-- '0' Combinational Divider
-- '1' Restoring Divider
-- '2' Var Latency divider (Standard)
-- '3' Var Latency divider (Limited Shifter)
-- '4' Var Latency divider (High Performance)
-- '5' Var Latency divider (High Frequency)

entity divider is
  generic (
    divider_implementation : natural := 5;
    size                   : natural := 32;
    fraction_size          : natural := 0; -- size of the fractional part for fixed point division
    extra_precision_bits   : natural := 0  -- extra precision bits that help in rounding
  );
  Port (
    reset                 : in  std_logic;
    clk                   : in  std_logic;
    dividend_i            : in  std_logic_vector(size-1 downto 0);
    divisor_i             : in  std_logic_vector(size-1 downto 0);
    div_enable            : in  std_logic;
    div_finished          : out std_logic;
    result_div            : out std_logic_vector(size+extra_precision_bits-1 downto 0); -- Decomment if you want to see the result
    result_rem            : out std_logic_vector(size+extra_precision_bits-1 downto 0)  -- Decomment if you want to see the result
  );
end divider;

architecture Behavioral of divider is

signal result         : std_logic_vector(((size+extra_precision_bits+fraction_size)*2)-1 downto 0); -- Decomment if you want to see the result
signal result_div_int : std_logic_vector(size-1+fraction_size downto 0);
signal result_rem_int : std_logic_vector(size-1+fraction_size downto 0);

component divider_HF is
  generic (
    size                  : natural := 32;
    extra_precision_bits  : natural := 0
  );
  port (
    dividend_i            : in  std_logic_vector(size-1 downto 0);
    divisor_i             : in  std_logic_vector(size-1 downto 0);
    reset                 : in  std_logic;
    clk                   : in  std_logic;
    div_enable_i          : in  std_logic;
    division_finished_out : out std_logic;
    result                : out std_logic_vector(((size+extra_precision_bits)*2)-1 downto 0) -- Decomment if you want to see the result
  );
end component divider_HF;

begin

  result_div <= result(size+extra_precision_bits+fraction_size-1 downto 0);
  result_rem <= result(((size+extra_precision_bits+fraction_size)*2)-1 downto size+extra_precision_bits+fraction_size);

  COMB_DIV : if divider_implementation = 0 generate

    -- Assert fraction_size is always less than or equal to size
    assert fraction_size = 0 report "fraction_size > 0 is not supported for this divider implemntation" severity failure;

    div_finished <= div_enable;

    process(all)
    begin
      result_div_int(size-1 downto 0) <= std_logic_vector(unsigned(dividend_i) / unsigned(divisor_i));
      result_rem_int(size-1 downto 0) <= std_logic_vector(unsigned(dividend_i) mod unsigned(divisor_i));
    end process;

  end generate COMB_DIV;

  VAR_LAT_DIV_HF : if divider_implementation = 5 generate

    divider_HF_inst : divider_HF
      generic map(
        size                  => size+fraction_size,
        extra_precision_bits  => extra_precision_bits
      )
      port map(
        dividend_i            => dividend_i & (0 to fraction_size-1 => '0'),
        divisor_i             => (0 to fraction_size-1 => '0') & divisor_i,
        reset                 => reset,
        clk                   => clk,
        div_enable_i          => div_enable,
        division_finished_out => div_finished,
        result                => result
      );

  end generate VAR_LAT_DIV_HF;

end Behavioral;