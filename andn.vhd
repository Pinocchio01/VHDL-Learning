----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2022/01/21 15:10:29
-- Design Name: 
-- Module Name: andn - Behavioral
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

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity andn is
    generic(
        n : integer := 2);
    port( 
        a   : in std_logic_vector(n-1 downto 0);
        c   : out std_logic);                                     --clk : in std_logic;   
end andn;

architecture Behavioral of andn is
begin
    process(a)
        variable mark : std_logic;
    begin
        mark := '1';
        for i in a'length-1 downto 0 loop
            if a(i) = '0' then 
                mark := '0';                                     -- notice how to set value to a variable instead of a signal
            end if;
        end loop;
    c <= mark;
    end process;
    
end Behavioral;
