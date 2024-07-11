-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--░█████╗░██╗░░░░░███████╗░░░░░░██████╗░██████╗░
--██╔══██╗██║░░░░░╚════██║░░░░░░╚════██╗╚════██╗
--██║░░╚═╝██║░░░░░░░███╔═╝█████╗░█████╔╝░░███╔═╝
--██║░░██╗██║░░░░░██╔══╝░░╚════╝░╚═══██╗██╔══╝░░
--╚█████╔╝███████╗███████╗░░░░░░██████╔╝███████╗
--░╚════╝░╚══════╝╚══════╝░░░░░░╚═════╝░╚══════╝
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
entity CLZ_32 is
    Port ( input : in STD_LOGIC_VECTOR (31 downto 0);
           output : out STD_LOGIC_VECTOR (4 downto 0));
end CLZ_32;
architecture Behavioral of CLZ_32 is
begin
    
CLZ_32_Bit:process(input)
variable v_0      : std_logic_vector(15 downto 0);
variable z_0      : std_logic_vector(15 downto 0);
variable z_1      : std_logic_vector(15 downto 0);
variable v_1      : std_logic_vector(7 downto 0);
variable z_2      : std_logic_vector(11 downto 0);
variable v_2      : std_logic_vector(3 downto 0);
variable z_3      : std_logic_vector(7 downto 0);
variable v_3      : std_logic_vector(1 downto 0);
variable z_4      : std_logic_vector(4 downto 0);
variable v_flag   : std_logic;
begin    
    -- For a 32 CLZs unit we use:
    -- 16 x 2 bit CLZs
    for i in 0 to 15 loop
        -- CLZ bits 0,1
        v_0(i):= not(input(i*2))and not(input((i*2)+1));
        z_0(i):= input(i*2)     and not(input((i*2)+1));
    end loop;
  
--    V_0
--    0, 0, 1
--    0, 1, 0
--    1, 0, 0
--    1, 1, 0
--
--    Z_0
--    0, 0, 0
--    0, 1, 0
--    1, 0, 1
--    1, 1, 0
--
--    (0,0) and not (1,0)
    
    -- 8 x 4 bit CLZs
    for i in 0 to 7 loop
        v_1(i)      := v_0((i*2)+1)  and v_0(2*i);
        z_1(2*i)    := (z_0(2*i)     and v_0((i*2)+1)) or (z_0((i*2)+1) and not (v_0((i*2)+1)));
        z_1((i*2)+1):= v_0((i*2)+1);
    end loop;
    
    -- 4 x 8 bit CLZs:
    for i in 0 to 3 loop
         v_2(i)     := v_1((i*2)+1)  and v_1(2*i);
         z_2(3*i)   := (z_1(i*4)     and v_1((i*2)+1)) or (z_1((i*4)+2) and not(v_1((i*2)+1)));
         z_2(3*i+1) := (z_1((i*4)+1) and v_1((i*2)+1)) or (z_1((i*4)+3) and not(v_1((i*2)+1)));
         z_2(3*i+2) := v_1((i*2)+1);
    end loop;
        
    -- 2 x 16 bits CLZs
    for i in 0 to 1 loop
        v_3(i)      := v_2((i*2)+1)  and v_2(2*i);        
        z_3(4*i)    := (z_2((i*6))   and v_2((i*2)+1)) or (z_2((i*6)+3) and not(v_2((i*2)+1)));
        z_3(4*i+1)  := (z_2((i*6)+1) and v_2((i*2)+1)) or (z_2((i*6)+4) and not(v_2((i*2)+1)));
        z_3(4*i+2)  := (z_2((i*6)+2) and v_2((i*2)+1)) or (z_2((i*6)+5) and not(v_2((i*2)+1)));        
        z_3(4*i+3)  := v_2((i*2)+1);
    end loop;
    
    -- 1 x 32 bits CLZ
    v_flag  := v_3(1) and v_3(0);
    z_4(4)  := v_3(1);
    z_4(3)  := (z_3(3) and v_3(1)) or (z_3(7) and not(v_3(1)));
    z_4(2)  := (z_3(2) and v_3(1)) or (z_3(6) and not(v_3(1)));
    z_4(1)  := (z_3(1) and v_3(1)) or (z_3(5) and not(v_3(1)));
    z_4(0)  := (z_3(0) and v_3(1)) or (z_3(4) and not(v_3(1)));
    output<= z_4;
end process;
end Behavioral;
