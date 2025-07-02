-- ieee packages ------------
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- Square root Newton Raphson
entity sqrt_nr is
  generic (
    size          : natural := 32;  -- Default to 32 bits, can be adjusted as needed
    fraction_size : natural := 0
  );
  Port (
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
end sqrt_nr;

architecture Behavioral of sqrt_nr is

  constant size_width : integer := integer(ceil(log2(real(size))));
  constant adj_size   : integer := size + fraction_size; -- Adjusted size for fixed-point calculations

  type STATE_TYPE is (IDLE, CALCULATE);

  signal state         : STATE_TYPE := IDLE;
  signal root          : unsigned(adj_size-1 downto 0);
  signal radicand      : unsigned(adj_size-1 downto 0);
  signal num           : unsigned(adj_size-1 downto 0) := (others => '0');
  signal x_wire        : unsigned(adj_size downto 0) := (others => '0');
  signal x             : unsigned(adj_size-1 downto 0) := (others => '0');
  signal x_2           : unsigned((adj_size*2)-1 downto 0) := (others => '0'); -- This signal represents x^2
  signal xp1_2         : unsigned((adj_size*2)-1 downto 0) := (others => '0'); -- This signal represents (x+1)^2
  signal x05_2         : unsigned((adj_size*2)+1 downto 0) := (others => '0'); -- This signal represents x.5^2
  signal convergence   : std_logic;

  signal clz           : std_logic_vector(size_width downto 0);
  signal index         : integer range 0 to adj_size-1;

  signal div_finished  : std_logic;
  signal result_div    : std_logic_vector(adj_size-1 downto 0);
  signal div_enable    : std_logic;

  component CLZ_top is
    generic (
      size       : natural;
      size_width : integer
    );
    Port (
      input  : in  std_logic_vector(size-1 downto 0);
      output : out std_logic_vector(size_width downto 0)
    );
  end component;

  component divider is
    generic (
      divider_implementation : natural := 5;
      size                   : natural := adj_size
    );
    Port (
      reset                 : in  std_logic;
      clk                   : in  std_logic;
      dividend_i            : in  std_logic_vector(adj_size-1 downto 0);
      divisor_i             : in  std_logic_vector(adj_size-1 downto 0);
      div_enable            : in  std_logic;
      div_finished          : out std_logic;
      result_div            : out std_logic_vector(adj_size-1 downto 0);
      result_rem            : out std_logic_vector(adj_size-1 downto 0)
    );
  end component;

begin

  -- Assert fraction_size is always less than or equal to size
  assert fraction_size <= size report "fraction_size must be less than or equal to size" severity failure;

  divider_inst : divider
    generic map(
      divider_implementation => 5,
      size                   => adj_size
    )
    port map(
      reset        => not rst_ni,
      clk          => clk_i,
      dividend_i   => std_logic_vector(number & (0 to fraction_size-1 => '0')), -- Input is scaled up to match adj_size
      divisor_i    => std_logic_vector(root),
      div_enable   => (start or div_enable) and not convergence,
      div_finished => div_finished,
      result_div   => result_div,
      result_rem   => open
    );

  CLZ_Inst : CLZ_top
    generic map(
      size       => size,
      size_width => size_width
    )
    port map (
      input  => number,
      output => clz
    );

  index  <= (adj_size-1-(to_integer(unsigned(clz))-1))/2;

  ready          <= '0' when start = '1' or busy = '1' else '1';
  x_wire         <= '0' & (x + unsigned(result_div)) when div_finished else x & "0"; -- when div is finished we do the newton raphson of the result, the extra bit to the left is intended for division by two, while the extra bit on the right of "x" is an extra precision bit useful for rounding in fixed-point operations
  root           <= (index+1 to adj_size-1 => '0') & '1' & (0 to index-1 => '0') when start else x;
  radicand       <= unsigned(number & (0 to fraction_size-1 => '0')) when start else num; -- Scale up the radicand for fixed-point
  x_2            <= root * root;
  xp1_2          <= (root + 1) * (root + 1);
  x05_2          <= unsigned(root & '1') * unsigned(root & '1'); -- Calculate x.5^2 for fixed-point
  
  convergence    <= '1' when (x_2(adj_size downto 0) <= radicand) and (xp1_2(adj_size downto 0) >= radicand) else '0';

  process(clk_i, rst_ni)
  begin
    if rst_ni = '0' then
      state          <= IDLE;
      num            <= (others => '0');
      x              <= (others => '0');
      sqrt_res       <= (others => '0');
      precision_sqrt <= '0';
      inexact_sqrt   <= '0';
      busy           <= '0';
      div_enable     <= '0';
    elsif rising_edge(clk_i) then
      case state is
        when IDLE =>
          div_enable <= '0';
          x <= (others => '0');
          precision_sqrt <= '0';
          inexact_sqrt   <= '0';
          if convergence then
            sqrt_res <= std_logic_vector(root(size-1 downto 0)); -- Scale down the result to match output size
            if (xp1_2(adj_size-1 downto 0) = radicand) then
              sqrt_res <= std_logic_vector(root(size-1 downto 0) + 1);
            end if;

            -- Determine precision and inexactness
            precision_sqrt <= '1' when (x05_2 <= (radicand & "00")) else '0';
            inexact_sqrt   <= '1' when (x_2(adj_size-1 downto 0) /= radicand) else '0';

            busy <= '0';
            state <= IDLE;
          elsif start = '1' then
            num      <= unsigned(number & (0 to fraction_size-1 => '0')); -- Scale up the input number for fixed-point
            x(index) <= '1';
            busy     <= '1';
            state    <= CALCULATE;
          end if;

        when CALCULATE =>
          -- Check for convergence
          if convergence then
            sqrt_res <= std_logic_vector(root(size-1 downto 0)); -- Scale down the result to match output size
            if (xp1_2(adj_size-1 downto 0) = radicand) then
              sqrt_res <= std_logic_vector(root(size-1 downto 0) + 1);
            end if;
            
            -- Determine precision and inexactness
            precision_sqrt <= '1' when (x05_2 <= (radicand & "00")) else '0';
            inexact_sqrt   <= '1' when (x_2(adj_size-1 downto 0) /= radicand) else '0';

            busy <= '0';
            state <= IDLE;
          else
            div_enable <= div_finished;
            x     <= x_wire(adj_size downto 1); -- Division by 2 for Newton-Raphson is done when "x_wire" is assigned to "x"
            state <= CALCULATE; -- Continue iterating
          end if;

        when others =>
          state <= IDLE;
      end case;
    end if;
  end process;

end architecture Behavioral;

