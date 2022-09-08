----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 2022/04/21 11:56:56
-- Design Name: 
-- Module Name: array_arith - Behavioral
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
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx leaf cells in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity array_arith is
    port( int_0 : in INTEGER := 0;
          vec_0 : in STD_LOGIC_VECTOR(7 downto 0) := "00000000";
          add_vec_int_0 : out STD_LOGIC_VECTOR(7 downto 0) := "00000000");
end array_arith;

architecture Behavioral of array_arith is
begin
process(int_0,vec_0)
    begin 
        add_vec_int_0 <= int_0 + vec_0;
end process;
end Behavioral;
