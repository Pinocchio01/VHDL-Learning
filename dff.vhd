-- D Flip-Flop with asynchronous reset

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY dff is
	PORT (
		d, clk, arsnt: IN std_logic;
		q : OUT std_logic
	);
END dff;

ARCHITECTURE Behavioral OF dff IS
BEGIN
	PROCESS(rst,clk)
	BEGIN
		IF (arsnt = '1') THEN
			q <= '0';
		ELSIF rising_edge(clk) THEN
			q <= d;
		END IF;
	END PROCESS;
END Behavioral;