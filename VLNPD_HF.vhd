library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use ieee.std_logic_misc.all;
use ieee.numeric_std.all;

-- The divider unit take as input: a dividend, a divisor_reg and an enable signal.
-- All these inputs are registered in the first clock cycle. 
-- The division starts from the second clock cycles.
-- This is a synchronous unit, so it takes as input also clock and reset signals.
-- Finally, the division result is ready when the output signal 
-- division_finished_out is high. The result is available in the remainder reg.
entity divider is
    Port ( dividend_i               : in  STD_LOGIC_VECTOR(31 downto 0);
           divisor_i                : in  STD_LOGIC_VECTOR(31 downto 0);
           reset                    : in  STD_LOGIC;
           clk                      : in  STD_LOGIC;
           div_enable_i             : in  STD_LOGIC;
           division_finished_out    : out STD_LOGIC
         -- result                   : out std_logic_vector(63 downto 0)
           );
end divider;

architecture Behavioral of divider is
component CLZ_64
    Port  (
            input : in  STD_LOGIC_VECTOR(63 downto 0);
            output: out STD_LOGIC_VECTOR(5 downto 0)
           );
end component;


component CLZ_32
    Port(
            input : in  STD_LOGIC_VECTOR(31 downto 0);
            output: out STD_LOGIC_VECTOR(4 downto 0)
        );
end component;

component Dynamic_Shifter
    Port( 
            input : in STD_LOGIC_VECTOR (63 downto 0);
            shift_amt : in unsigned(4 downto 0);
            shifter_enable:in STD_LOGIC;
            output : out STD_LOGIC_VECTOR (63 downto 0)
        );
end component;


-- Input registers
signal divisor_reg          : std_logic_vector(31 downto 0);                    -- Dividend register. 32 bits register that store the content of the input signal dividend_i
signal div_enable_reg       : std_logic;                                        -- Enable signal register. 1 bit register that store  the content of the input signal div_enable_i

-- Output register
signal division_finished_wire   : std_logic;                                    -- Complete signal. It is high when the division is finished

-- Divider internal registers
signal count                    : integer range 32 downto 0;                    -- Counter register. The counter shows the remaining division steps.
signal count_wire               : integer range 32 downto 0;                    -- Counter wire. Counter register input.
signal remaining_shifts         : integer range 32 downto 0;                    -- Counter wire. Counter register input.
signal R                        : std_logic_vector(63 downto 0);                -- Remainder register. 64 bit, in the Most Significant Word (MSW) we have the remainder, in the LSW the quotient. Note that in the first clock cycle the remainder is initialized with the dividend in its LSW.
signal S                        : std_logic_vector(32 downto 0);                -- Difference signal. Output of the subtractor unit 1 (RemainderMSW - divisor_reg)

-- Count Leading Zeros units
signal clz_divisor              : integer range 31 downto 0;                    -- Output of the 32 bits Count Leading Zero unit used to detect the divisor_reg MSOne.
signal clz_divisor_wire         : integer range 31 downto 0;                    -- Output of the 32 bits Count Leading Zero unit used to detect the divisor_reg MSOne.
signal clz_remainder            : integer range 63 downto 0;                    -- Output of the 64 bits Count Leading Zero unit used to detect the Remainder MSOne.
signal clz_remainder_wire       : integer range 63 downto 0;                    -- Output of the 64 bits Count Leading Zero unit used to detect the Remainder MSOne.
signal shift                    : integer range 31 downto -2;                    -- Difference signal. Output of the subtractor unit 2 (clz_remainder - clz_divisor - 1)
signal shift_amt                : unsigned(4 downto 0);                         -- Difference signal. Output of the subtractor unit 2 (clz_remainder - clz_divisor - 1)
signal clz_rem_in               : std_logic_vector(63 downto 0);
signal clz_remainder_vec        : std_logic_vector(5 downto 0);
signal clz_divisor_vec          : std_logic_vector(4 downto 0);
    
-- Shifter  
signal shifted_R                : std_logic_vector(63 downto 0);                -- Signal containing the remainder shifted dynamically. Output of the dynamic shifter
signal new_R                    : std_logic_vector(63 downto 0);                -- Signal containing the remainder shifted dynamically. Output of the dynamic shifter
signal shifter_enable           : std_logic;                                    -- Difference signal. Output of the subtractor unit 2 (clz_remainder - clz_divisor - 1)
signal limited_shift            : std_logic;                                    -- Difference signal. Output of the subtractor unit 2 (clz_remainder - clz_divisor - 1)
constant allzeros               : std_logic_vector(32 downto 0):=(others=>'0');

 
signal shifter_enable_reg       : std_logic;                                    -- High frequency version control signal
                                                                                -- In the standard divider version, shift_amount+1 are computed in one cycle (dynamic shift +  subtraction (classical step))
                                                                                -- In the optimized one, shift_amount step are computed but the sequent difference is performed in the next clock cycle.
                                                                                -- This means that, when the dynamic shift is performed, the subtraction is not. 
                                                                                -- Then, in the next step just the subtraction is computed in this clock cycle. This cycle is exploited to compute also the clzs of the new result
                                                                                -- In this way, the DYNAMIC SHIFT is NEVER performed IN THE SAME CLOCK CYCLE OF THE CLZ. 
                                                                                -- These two operation, that are the critical path, are splitted. 

--Conversion VHDL
signal dividend_i_wire          :std_logic_vector(31 downto 0);
signal divisor_i_wire           :std_logic_vector(31 downto 0);
signal div_enable_i_wire        :std_logic;
attribute dont_touch           : string;
attribute dont_touch of R : signal is "true";
signal shifter_in               : std_logic_vector(63 downto 0);
begin

shifter_in<=R(62 downto 0) &'0';
-- BLOCKS
CLZ_64_Bit: CLZ_64 port map( input => clz_rem_in, output => clz_remainder_vec);
CLZ_32_Bit: CLZ_32 port map( input => divisor_i_wire,  output => clz_divisor_vec);
Dyn_shifter: Dynamic_Shifter port map( input => R, shift_amt=> shift_amt, output => shifted_R); -- Dynamic shifter: three multiplexers

  
divisor_wire      <= divisor_i;
dividend_wire     <= dividend_i;
div_enable_wire   <= div_enable_i;

-------------------------------------------------------------------------------------
-- DIVISOR LEADING ZERO COUNTER 32 BIT DATA
clz_divisor_wire  <= to_integer(unsigned(clz_divisor_vec));

-- REMAINDER LEADING ZERO COUNTER 64 BIT DATA 
clz_remainder_wire  <= to_integer(unsigned(clz_remainder_vec));

-- SUBTRACTOR
-- S   <= std_logic_vector(('0' & unsigned(shifted_R(62 downto 31))) - ('0' & unsigned(divisor_reg))); 


-------------------------------------------------------------------------------------
------------------------------------- COUNTER ---------------------------------------
-------------------------------------------------------------------------------------
counter_handler:process(all)
begin
  count_wire        <= count;
  division_finished_wire<='0';
  -- The counter is enabled (incremented) only when the division is started
  if div_enable_reg='1' then
      count_wire <= count + 1;

      -- If the Shifter is enabled, then dynamic shift is performed and the counter is updated by shift_amount
      if (shifter_enable='1') then
              count_wire<= count + shift;
      end if;

      -- When the counter reach 32, the division is completed: division_finished = '1' and the result is available in remainder
      if count_wire=32 or limited_shift='1' then
          division_finished_wire<='1';            
      end if;
  end if;
end process;

-------------------------------------------------------------------------------------
----------------------------------- SHIFTER -----------------------------------------
-------------------------------------------------------------------------------------
shifter_control: process(all)
begin
  shifter_enable   <= '0'; 
  limited_shift    <= '0';
  shift            <= clz_remainder-clz_divisor-1;  
  -- shift_amt        <= to_unsigned(shift, shift_amt'length);
  shift_amt        <= "00000";

  if (div_enable_reg='0') then
      clz_rem_in <= allzeros(31 downto 0) & dividend_i;
  else
      clz_rem_in <= new_R;
  end if;
  shifter_in<=R;

  -- If Remainder LZs > Divisor LZs, the shifter is enabled. 
  if (shift > 0 and shifter_enable_reg='0' and div_enable_reg='1') then 
      shifter_enable <= '1';
      shift_amt        <= to_unsigned(shift, shift_amt'length);

      -- Shift amount is limited to 32
      if shift >  (31-count) then
        shifter_in      <= R(62 downto 0) &'0';
        shift_amt       <= to_unsigned((31 - count), shift_amt'length);
        limited_shift   <= '1';
    end if;
 end if;   

end process;

result_proc:process(all)
begin

  S   <= std_logic_vector(('0' & unsigned(R(62 downto 31))) - ('0' & unsigned(divisor_reg)));
  if (S(32) = '1') then
     new_R <= R(62 downto 0) & '0';
  else
     new_R <= S(31 downto 0) & R(30 downto 0) & '1';
  end if;


end process;
-------------------------------------------------------------------------------------
------------------------------------ SYNCR ------------------------------------------
-------------------------------------------------------------------------------------
--Division Synchronous Process
Divider_sync : process(clk, reset)
begin
if reset = '1' then
  count           <= 0; 
  R               <= (others => '0');
  divisor_reg     <= (others => '0');
  shifter_enable_reg <='0';
  div_enable_reg  <= '0';
  division_finished_out<='0';
  clz_divisor <= 0;
  clz_remainder<=0;
elsif rising_edge(clk) then
      R                       <= allzeros(31 downto 0) & dividend_wire; 
      divisor_reg             <= divisor_wire;
      div_enable_reg          <= div_enable_wire;
      count                   <= 0;
      clz_divisor             <= clz_divisor_wire; 
      clz_remainder           <= to_integer(unsigned(clz_remainder_vec));
      division_finished_out   <= division_finished_wire;
      shifter_enable_reg      <= shifter_enable;

      if (div_enable_reg='1') then
        count   <= count_wire;
        if (shifter_enable='1') then
            R <= shifted_R;
        else
            R <= new_R;
        end if;
      end if;

end if;
end process;
result<=R;

end Behavioral;

