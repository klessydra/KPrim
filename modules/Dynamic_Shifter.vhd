----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 20.01.2023 11:33:06
-- Design Name: 
-- Module Name: Dynamic_Shifter - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;


entity Dynamic_Shifter is
    Port ( input : in STD_LOGIC_VECTOR (63 downto 0);
           shift_amt : in unsigned(4 downto 0);
           output : out STD_LOGIC_VECTOR (63 downto 0));
end Dynamic_Shifter;

architecture Behavioral of Dynamic_Shifter is
constant allzeros       : std_logic_vector(32 downto 0) := (others=>'0');
begin
shifter:process(shift_amt,input)
variable temp : std_logic_vector(63 downto 0);
begin
    -- The shifter is realized as the cascade of three MUX. This reduce area consumption
    temp := input;
    case shift_amt(4 downto 4) is
        when "0"    =>  temp := temp; 
        when others =>  temp := temp (47 downto 0) & allzeros(15 downto 0);
    end case;
    
    case shift_amt( 3 downto 2) is
        when "00"   =>  temp := temp; 
        when "01"   =>  temp := temp (59 downto 0) & allzeros(3 downto 0);
        when "10"   =>  temp := temp (55 downto 0) & allzeros(7 downto 0);
        when others =>  temp := temp (51 downto 0) & allzeros(11 downto 0);
    end case;
    
    case shift_amt( 1 downto 0) is
        when "00"   =>  temp := temp; 
        when "01"   =>  temp := temp (62 downto 0) & allzeros(0 downto 0);
        when "10"   =>  temp := temp (61 downto 0) & allzeros(1 downto 0);
        when others =>  temp := temp (60 downto 0) & allzeros(2 downto 0);
    end case;   

    output<=temp;
end process;

end Behavioral;
