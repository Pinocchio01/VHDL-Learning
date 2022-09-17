-- D Flip-Flop with asynchronous reset
-- It is a sequential circuit

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
-- std and work is visible by default, no need to claim

ENTITY dff is
	PORT (
		d, clk, arstn: IN std_logic; -- active low
		q : OUT std_logic
	);
END dff;

ARCHITECTURE Behavioral OF dff IS
BEGIN
	PROCESS(rst,clk)
	BEGIN
		IF (arsnt = '0') THEN
			q <= '0';
		ELSIF rising_edge(clk) THEN
			q <= d;
		END IF;
	END PROCESS;
END Behavioral;