-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
-- ██╗░░░██╗░█████╗░██████╗░██╗░█████╗░██████╗░██╗░░░░░███████╗
-- ██║░░░██║██╔══██╗██╔══██╗██║██╔══██╗██╔══██╗██║░░░░░██╔════╝
-- ╚██╗░██╔╝███████║██████╔╝██║███████║██████╦╝██║░░░░░█████╗░░
-- ░╚████╔╝░██╔══██║██╔══██╗██║██╔══██║██╔══██╗██║░░░░░██╔══╝░░
-- ░░╚██╔╝░░██║░░██║██║░░██║██║██║░░██║██████╦╝███████╗███████╗
-- ░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚═╝╚═╝╚═╝░░╚═╝╚═════╝░╚══════╝╚══════╝
--
-- ██╗░░░░░░█████╗░████████╗███████╗███╗░░██╗░█████╗░██╗░░░██╗         ██████╗░██╗██╗░░░██╗██╗██████╗░███████╗██████╗░
-- ██║░░░░░██╔══██╗╚══██╔══╝██╔════╝████╗░██║██╔══██╗╚██╗░██╔╝         ██╔══██╗██║██║░░░██║██║██╔══██╗██╔════╝██╔══██╗
-- ██║░░░░░███████║░░░██║░░░█████╗░░██╔██╗██║██║░░╚═╝░╚████╔╝░         ██║░░██║██║╚██╗░██╔╝██║██║░░██║█████╗░░██████╔╝
-- ██║░░░░░██╔══██║░░░██║░░░██╔══╝░░██║╚████║██║░░██╗░░╚██╔╝░░         ██║░░██║██║░╚████╔╝░██║██║░░██║██╔══╝░░██╔══██╗
-- ███████╗██║░░██║░░░██║░░░███████╗██║░╚███║╚█████╔╝░░░██║░░░         ██████╔╝██║░░╚██╔╝░░██║██████╔╝███████╗██║░░██║
-- ╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚═╝░░╚══╝░╚════╝░░░░╚═╝░░░         ╚═════╝░╚═╝░░░╚═╝░░░╚═╝╚═════╝░╚══════╝╚═╝░░╚═╝
--
-- ░██████╗████████╗░█████╗░███╗░░██╗██████╗░░█████╗░██████╗░██████╗░
-- ██╔════╝╚══██╔══╝██╔══██╗████╗░██║██╔══██╗██╔══██╗██╔══██╗██╔══██╗
-- ╚█████╗░░░░██║░░░███████║██╔██╗██║██║░░██║███████║██████╔╝██║░░██║
-- ░╚═══██╗░░░██║░░░██╔══██║██║╚████║██║░░██║██╔══██║██╔══██╗██║░░██║
-- ██████╔╝░░░██║░░░██║░░██║██║░╚███║██████╔╝██║░░██║██║░░██║██████╔╝
-- ╚═════╝░░░░╚═╝░░░╚═╝░░╚═╝╚═╝░░╚══╝╚═════╝░╚═╝░░╚═╝╚═╝░░╚═╝╚═════╝░
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

-- The divider unit take as input: a dividend, a divisor_reg and an enable signal.
-- All these inputs are stored in registered in the first clock cycle. 
-- The division starts from the second clock cycles.
-- The division result is ready when the output signal 
-- division_finished_out is high. The result is available in the remainder reg.

entity divider_HF is
  generic (
    size                 : natural := 32;
    extra_precision_bits : natural := 0  -- extra precision bits that help in rounding
  );
  Port (
    dividend_i            : in  std_logic_vector(size-1 downto 0);
    divisor_i             : in  std_logic_vector(size-1 downto 0);
    reset                 : in  std_logic;
    clk                   : in  std_logic;
    div_enable_i          : in  std_logic;
    division_finished_out : out std_logic;
    result                : out std_logic_vector(((size+extra_precision_bits)*2)-1 downto 0) -- Decomment if you want to see the result
  );
end divider_HF;

architecture Behavioral of divider_HF is

  constant extended_size       : natural := size + extra_precision_bits;
  constant size_width          : integer := integer(ceil(log2(real(size))));
  constant extended_size_width : integer := integer(ceil(log2(real(extended_size))));

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

  component Dynamic_Shifter
    generic (
      size       : natural;
      size_width : integer
    );
    Port (
      input          : in  std_logic_vector((size*2)-1 downto 0);
      shift_amt      : in  unsigned(size_width-1 downto 0);
      shifter_enable : in  std_logic;
      output         : out std_logic_vector((size*2)-1 downto 0)
    );
  end component;

  -- Divider signals
  signal divisor_reg      : std_logic_vector(size-1 downto 0);              -- Divisor register. 
  signal R                : std_logic_vector((extended_size*2)-1 downto 0); -- Remainder register. 64 bit, in the Most Significant Word (MSW) we have the remainder, in the LSW the quotient. Note that in the first clock cycle the remainder is initialized with the dividend in its LSW.
  signal div_enable_reg   : std_logic;                                      -- Enable signal register. 
  signal dividend_wire    : std_logic_vector(size-1 downto 0);              -- Dividend input register
  signal divisor_wire     : std_logic_vector(size-1 downto 0);              -- Divisor input register
  signal div_enable_wire  : std_logic;
  signal count            : integer range extended_size downto 0; -- Counter register. The counter shows the remaining division steps.
  signal count_wire       : integer range extended_size downto 0; -- Counter wire. Counter register input.
  signal remaining_shifts : integer range size downto 0;     -- Counter wire. Counter register input.
  signal S                : std_logic_vector(extended_size downto 0); -- Difference signal. Output of the subtractor unit 1 (RemainderMSW - divisor_reg)

  -- Count Leading Zeros units
  signal clz_divisor        : integer range size downto 0;                      -- Output of the size bits Count Leading Zero unit used to detect the divisor_reg MSOne.
  signal clz_divisor_wire   : integer range size downto 0;                      -- Output of the size bits Count Leading Zero unit used to detect the divisor_reg MSOne.
  signal clz_remainder      : integer range (extended_size*2) downto 0;                  -- Output of the size*2 bits Count Leading Zero unit used to detect the Remainder MSOne.
  signal clz_remainder_wire : integer range (extended_size*2) downto 0;                  -- Output of the size*2 bits Count Leading Zero unit used to detect the Remainder MSOne.
  signal shift              : signed(extended_size_width downto 0);             -- Difference signal. Output of the subtractor unit 2 (clz_remainder - clz_divisor - 1)
  signal shift_amt          : unsigned(extended_size_width-1 downto 0);         -- Difference signal. Output of the subtractor unit 2 (clz_remainder - clz_divisor - 1)
  signal clz_rem_in         : std_logic_vector((extended_size*2)-1 downto 0);   -- CLZ64 input signal
  signal clz_remainder_vec  : std_logic_vector(extended_size_width downto 0);   -- CLZ64 output
  signal clz_remainder_vec2 : std_logic_vector(extended_size_width+1 downto 0); -- CLZ64 output
  signal clz_divisor_vec    : std_logic_vector(extended_size_width-1 downto 0); -- CLZ32 output
  signal clz_divisor_vec2   : std_logic_vector(extended_size_width downto 0);   -- CLZ32 output

  -- Shifter
  signal shifted_R              : std_logic_vector((extended_size*2)-1 downto 0); -- Signal containing the remainder shifted dynamically. Output of the dynamic shifter
  signal new_R                  : std_logic_vector((extended_size*2)-1 downto 0); -- Signal containing the remainder shifted dynamically. Output of the dynamic shifter
  signal shifter_in             : std_logic_vector((extended_size*2)-1 downto 0);
  signal shifter_enable         : std_logic;                             -- Difference signal. Output of the subtractor unit 2 (clz_remainder - clz_divisor - 1)
  signal shifter_enable_reg     : std_logic;                             -- Difference signal. Output of the subtractor unit 2 (clz_remainder - clz_divisor - 1)
  signal limited_shift          : std_logic;                             -- Difference signal. Output of the subtractor unit 2 (clz_remainder - clz_divisor - 1)
  signal division_finished_wire : std_logic;
  attribute dont_touch          : string;
  attribute dont_touch of R     : signal is "true"; -- Comment if the division result is an output

  constant allzeros             : std_logic_vector(extended_size downto 0) := (others => '0');
  signal tmp_size               : unsigned(size_width+1 downto 0);

begin

  CLZ_REM : CLZ_top
    generic map(
      size       => extended_size*2,
      size_width => extended_size_width+1
    )
    port map (
      input  => clz_rem_in,
      output => clz_remainder_vec2
    );
  clz_remainder_vec <= clz_remainder_vec2(clz_remainder_vec'range);

  CLZ_DIV : CLZ_top
    generic map(
      size       => size,
      size_width => size_width
    )
    port map (
      input  => divisor_wire,
      output => clz_divisor_vec2
    );
  clz_divisor_vec <= clz_divisor_vec2(size_width-1 downto 0);

  -- Dynamic shifter: three multiplexers
  Dyn_shifter : Dynamic_Shifter
    generic map(
      size       => extended_size,
      size_width => extended_size_width
    )
    port map(
      input          => shifter_in,
      shift_amt      => shift_amt,
      shifter_enable => shifter_enable_reg,
      output         => shifted_R
    );

  divisor_wire    <= divisor_i;
  dividend_wire   <= dividend_i;
  div_enable_wire <= '1' when div_enable_i else div_enable_reg;

  -------------------------------------------------------------------------------------
  -- DIVISOR LEADING ZERO COUNTER 32 BIT DATA
  clz_divisor_wire <= to_integer(unsigned(clz_divisor_vec));

  -- REMAINDER LEADING ZERO COUNTER 64 BIT DATA 
  clz_remainder_wire <= to_integer(unsigned(clz_remainder_vec));

  -------------------------------------------------------------------------------------
  ------------------------------------- COUNTER ---------------------------------------
  -------------------------------------------------------------------------------------

  counter_handler : process(all)
  begin
    count_wire             <= count;
    division_finished_wire <= '0';
    -- The counter is enabled (incremented) only when the division is started
    if div_enable_reg = '1' then
      count_wire <= extended_size when (count + 1 > extended_size) else (count + 1);
      -- If the Shifter is enabled, then dynamic shift is performed and the counter is updated by shift_amount
      if (shifter_enable = '1') then
        count_wire <= extended_size when (count + to_integer(shift) > extended_size) else (count + to_integer(shift));
      end if;

      -- When the counter reaches size, the division is completed: division_finished = '1' and the result is available in remainder
      if (count_wire = extended_size or limited_shift = '1') and division_finished_out = '0' then
        division_finished_wire <= '1';
      end if;
    end if;
  end process;

  -------------------------------------------------------------------------------------
  ----------------------------------- SHIFTER -----------------------------------------
  -------------------------------------------------------------------------------------
  shifter_control : process(all)
    variable needed_shift : integer;
  begin
    shifter_enable <= '0';
    limited_shift  <= '0';
    if (clz_remainder-clz_divisor-1 > extended_size-1) then -- take the MSB of index "size_width"
      shift <= to_signed(extended_size-1, shift'length);
    elsif (clz_remainder-clz_divisor-1 > 0) then
      shift <= to_signed(clz_remainder-clz_divisor-1, shift'length);
    else
      shift <= (others => '0');
    end if;

    if (div_enable_reg = '0') then
      clz_rem_in <= (0 to extended_size-1 => '0') & (0 to extra_precision_bits-1 => '0') & dividend_i;  -- we do the shift in the sync process below
    else
      clz_rem_in <= new_R;
    end if;

    shifter_in <= R;
    shift_amt  <= (others => '0');
    -- If Remainder LZs > Divisor LZs, the shifter is enabled. 
    if (shift > 0 and shifter_enable_reg = '0' and div_enable_reg = '1') then
      shifter_enable <= '1';
      shift_amt      <= unsigned(shift(shift_amt'range));

      -- Shift amount is limited to size
      if ( shift > (extended_size - count - 1) ) then
        shifter_in  <= R((extended_size*2)-2 downto 0) &'0';
        if (extended_size - count - 1 >= 0) then
          shift_amt <= to_unsigned((extended_size - count - 1), shift_amt'length);
        end if;
        limited_shift <= '1';
      end if;
    end if;

  end process;

  result_proc : process(all)
  begin
    --S <= std_logic_vector(('0' & unsigned(R((extended_size*2)-2 downto extended_size-1))) - ('0' & unsigned(divisor_reg)));
    --S <= std_logic_vector(('0' & unsigned(R((size*2)-2 downto size-1))) - ('0' & unsigned(divisor_reg)));
    S <= std_logic_vector(('0' & unsigned(R((extended_size * 2) - 2 downto (extended_size * 2) - 2 - (extended_size - 1)))) - ('0' & unsigned(divisor_reg)));

    if (S(extended_size) = '1') then
      new_R <= R((extended_size*2)-2 downto 0) & '0';
    else
      -- Not negative => top half = S(size-1 downto 0), shift in '1'
      new_R <= S(extended_size-1 downto 0) & R(extended_size-2 downto 0) & '1';
    end if;
  end process;

  -------------------------------------------------------------------------------------
  ------------------------------------ SYNCR ------------------------------------------
  -------------------------------------------------------------------------------------
  Divider_sync : process(clk, reset)
  begin
    if reset = '1' then
      count                 <= 0;
      R                     <= (others => '0');
      divisor_reg           <= (others => '0');
      shifter_enable_reg    <= '0';
      div_enable_reg        <= '0';
      division_finished_out <= '0';
      clz_divisor           <= 0;
      clz_remainder         <= 0;
    elsif rising_edge(clk) then
      if (div_enable_reg='0' and div_enable_wire='1') then
        -- Shift the dividend left by extra_precision_bits into the bottom extended_size bits
      end if;
      R                           <= (others => '0');
      R(extended_size-1 downto 0) <= dividend_wire & (0 to extra_precision_bits-1 => '0');
      divisor_reg                 <= divisor_wire;
      count                       <= 0;
      div_enable_reg        <= div_enable_wire;
      clz_divisor           <= clz_divisor_wire;
      clz_remainder         <= to_integer(unsigned(clz_remainder_vec));
      division_finished_out <= division_finished_wire;
      shifter_enable_reg    <= shifter_enable;

      if (div_enable_reg='1') then
        count <= count_wire;
        if (shifter_enable='1') then
          R <= shifted_R;
        else
          R <= new_R;
        end if;
      end if;

      if (division_finished_out) then
        div_enable_reg <= '0';
        count <= 0;
      end if;

    end if;
  end process;
  result <= R;

end Behavioral;