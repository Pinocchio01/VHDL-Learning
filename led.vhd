----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2022/01/19 19:58:58
-- Design Name: 
-- Module Name: led - Behavioral
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
use IEEE.std_logic_unsigned.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity led is
generic(n:integer:=50000000);
port(clk:in std_logic;
reset : in std_logic;
led8s:out std_logic_vector(7 downto 0));
end led;

architecture Behavioral of led is
signal count : integer range n-1 downto 0:=n-1;
signal q1 : std_logic;
signal count2 : std_logic_vector(2 downto 0);
begin
process(clk)
begin
if rising_edge(clk) then
count <= count-1;
if count>=n/2 then
q1 <= '0';
else
q1 <= '1';
end if;
if count <= 0 then
count <= n-1;
end if;
end if ;
end process;

p1: process(q1)
begin
if reset = '0' then
count2 <= "000";
elsif rising_edge(q1) then
if count2 = "111" then
count2 <= "000";
else 
    count2 <= count2 + 1;
end if;
end if;
end process;

p2: process(count2)
begin
case count2 is
when "000" => led8s <= "11111110";
when "001" => led8s <= "11111101";
when "010" => led8s <= "11111011";
when "011" => led8s <= "11110111";
when "100" => led8s <= "11101111";
when "101" => led8s <= "11011101";
when "110" => led8s <= "10111101";
when "111" => led8s <= "01111111";
end case;
end process;

end Behavioral;
