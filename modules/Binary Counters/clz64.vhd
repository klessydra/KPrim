-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
--░█████╗░██╗░░░░░███████╗░░░░░░░█████╗░░░██╗██╗
--██╔══██╗██║░░░░░╚════██║░░░░░░██╔═══╝░░██╔╝██║
--██║░░╚═╝██║░░░░░░░███╔═╝█████╗██████╗░██╔╝░██║
--██║░░██╗██║░░░░░██╔══╝░░╚════╝██╔══██╗███████║
--╚█████╔╝███████╗███████╗░░░░░░╚█████╔╝╚════██║
--░╚════╝░╚══════╝╚══════╝░░░░░░░╚════╝░░░░░░╚═╝
-------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity CLZ_64 is
    Port ( input : in  STD_LOGIC_VECTOR(63 downto 0);
           output: out STD_LOGIC_VECTOR(5 downto 0)
           );
end CLZ_64;

architecture Behavioral of CLZ_64 is
begin
    
-------------------------------------------------------------------------------------
-- REMAINDER LEADING ZERO COUNTER: 64 BIT DATA
CLZ_64_Bit:process(input)
variable input_vec          : std_logic_vector(63 downto 0);
variable remainder_v_0      : std_logic_vector(31 downto 0);
variable remainder_z_0      : std_logic_vector(31 downto 0);
variable remainder_z_1      : std_logic_vector(31 downto 0);
variable remainder_v_1      : std_logic_vector(15 downto 0);
variable remainder_z_2      : std_logic_vector(23 downto 0);
variable remainder_v_2      : std_logic_vector(7 downto 0);
variable remainder_z_3      : std_logic_vector(15 downto 0);
variable remainder_v_3      : std_logic_vector(3 downto 0);
variable remainder_z_4      : std_logic_vector(9 downto 0);
variable remainder_v_4      : std_logic_vector(1 downto 0);
variable remainder_z_5      : std_logic_vector(5 downto 0);
variable remainder_v_flag   : std_logic;
begin        

        -- 2 bit CLZs
        for i in 0 to 31 loop
            -- CLZ bits 0,1
            remainder_v_0(i):= not(input(i*2))and not(input((i*2)+1));
            remainder_z_0(i):= input(i*2)     and not(input((i*2)+1));
        end loop;
        
        -- 4 bit CLZs
        for i in 0 to 15 loop
            remainder_v_1(i)      := remainder_v_0((i*2)+1)  and remainder_v_0(2*i);
            remainder_z_1(2*i)    := (remainder_z_0(2*i)     and remainder_v_0((i*2)+1)) or (remainder_z_0((i*2)+1) and not (remainder_v_0((i*2)+1)));
            remainder_z_1((i*2)+1):= remainder_v_0((i*2)+1);
        end loop;
        
        -- 8 bit CLZs:
        for i in 0 to 7 loop
             remainder_v_2(i)     := remainder_v_1((i*2)+1)  and remainder_v_1(2*i);
             remainder_z_2(3*i)   := (remainder_z_1(i*4)     and remainder_v_1((i*2)+1)) or (remainder_z_1((i*4)+2) and not(remainder_v_1((i*2)+1)));
             remainder_z_2(3*i+1) := (remainder_z_1((i*4)+1) and remainder_v_1((i*2)+1)) or (remainder_z_1((i*4)+3) and not(remainder_v_1((i*2)+1)));
             remainder_z_2(3*i+2) := remainder_v_1((i*2)+1);
        end loop;
            
        -- 16 bit CLZs
        for i in 0 to 3 loop
            remainder_v_3(i)      := remainder_v_2((i*2)+1)  and remainder_v_2(2*i);        
            remainder_z_3(4*i)    := (remainder_z_2((i*6))   and remainder_v_2((i*2)+1)) or (remainder_z_2((i*6)+3) and not(remainder_v_2((i*2)+1)));
            remainder_z_3(4*i+1)  := (remainder_z_2((i*6)+1) and remainder_v_2((i*2)+1)) or (remainder_z_2((i*6)+4) and not(remainder_v_2((i*2)+1)));
            remainder_z_3(4*i+2)  := (remainder_z_2((i*6)+2) and remainder_v_2((i*2)+1)) or (remainder_z_2((i*6)+5) and not(remainder_v_2((i*2)+1)));        
            remainder_z_3(4*i+3)  := remainder_v_2((i*2)+1);
        end loop;
        
        -- 32 bits CLZ
        remainder_v_4(0)  := (remainder_v_3(1) and remainder_v_3(0));
        remainder_z_4(4)  := (remainder_v_3(1));
        remainder_z_4(3)  := (remainder_z_3(3) and remainder_v_3(1)) or (remainder_z_3(7) and not(remainder_v_3(1)));
        remainder_z_4(2)  := (remainder_z_3(2) and remainder_v_3(1)) or (remainder_z_3(6) and not(remainder_v_3(1)));
        remainder_z_4(1)  := (remainder_z_3(1) and remainder_v_3(1)) or (remainder_z_3(5) and not(remainder_v_3(1)));
        remainder_z_4(0)  := (remainder_z_3(0) and remainder_v_3(1)) or (remainder_z_3(4) and not(remainder_v_3(1)));

        remainder_v_4(1)  := (remainder_v_3(3)  and remainder_v_3(2));
        remainder_z_4(9)  := (remainder_v_3(3));
        remainder_z_4(8)  := (remainder_z_3(11) and remainder_v_3(3))  or (remainder_z_3(15) and not(remainder_v_3(3)));
        remainder_z_4(7)  := (remainder_z_3(10) and remainder_v_3(3))  or (remainder_z_3(14) and not(remainder_v_3(3)));
        remainder_z_4(6)  := (remainder_z_3(9)  and remainder_v_3(3))  or (remainder_z_3(13) and not(remainder_v_3(3)));
        remainder_z_4(5)  := (remainder_z_3(8)  and remainder_v_3(3))  or (remainder_z_3(12) and not(remainder_v_3(3)));
         
        -- 64 bits CLZ
        remainder_v_flag  := (remainder_v_4(1) and remainder_v_4(0));
        remainder_z_5(5)  := (remainder_v_4(1));
        remainder_z_5(4)  := (remainder_z_4(4) and remainder_v_4(1)) or (remainder_z_4(9) and not(remainder_v_4(1)));
        remainder_z_5(3)  := (remainder_z_4(3) and remainder_v_4(1)) or (remainder_z_4(8) and not(remainder_v_4(1)));
        remainder_z_5(2)  := (remainder_z_4(2) and remainder_v_4(1)) or (remainder_z_4(7) and not(remainder_v_4(1)));
        remainder_z_5(1)  := (remainder_z_4(1) and remainder_v_4(1)) or (remainder_z_4(6) and not(remainder_v_4(1)));
        remainder_z_5(0)  := (remainder_z_4(0) and remainder_v_4(1)) or (remainder_z_4(5) and not(remainder_v_4(1)));

        output  <= remainder_z_5;

    end process;



end Behavioral;
