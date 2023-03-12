------------------------------------------------------------------------ 
-- Company: University of Stuttgart (IIS)
-- Engineer: Yichao Peng
-- 
-- Create Date: 2022/09/25 15:51
-- Design Name: 
-- Module Name: Paul_Components_VHDL
-- Project Name: Common circuit components written in VHDL
-- Target Devices: 
-- Tool Versions:
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created

-- Additional Comments: The codes does not include library declaration unless special case.
-- All codes tested.

-- List for components:
-- 1. 	NAND Gate
-- 2. 	D Flip-Flop with asynchronous reset
-- 3.   Multiplexer(IF)
-- 4. 	Down-counter (4-bit)
-- 5. 	Adder



------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;


-- 1.	NAND Gate

ENTITY nand_gate IS
	PORT (
		a, b : IN BIT;
		o : OUT BIT
		);
END nand_gate;

ARCHITECTURE Behavioral OF nand_gate IS
BEGIN
	o <= a NAND b;
END Behavioral;



-- 2. 	D Flip-Flop with asynchronous reset

ENTITY dff is
	PORT (
		d, clk, arstn: IN std_logic; -- active low
		q : OUT std_logic
	);
END dff;

ARCHITECTURE Behavioral OF dff IS
BEGIN
	PROCESS (arstn,clk)
	BEGIN
		IF (arstn = '0') THEN
			q <= '0';
		ELSIF rising_edge(clk) THEN
			q <= d;
		END IF;
	END PROCESS;
END Behavioral;



-- 3. Multiplexer

-- 3.1 	Multiplexer(IF)

ENTITY mux is
	PORT (
		a, b : IN std_logic_vector(7 DOWNTO 0);
		sel  : IN std_logic_vector(1 DOWNTO 0);
		q    : OUT std_logic_vector(7 DOWNTO 0)
	);
END mux;

ARCHITECTURE Behavioral OF mux IS
BEGIN
	PROCESS (a,b,sel)
	BEGIN
		IF (sel = "00") THEN
			q <= "00000000";
		ELSIF (sel = "01") THEN
			q <= a;
		ELSIF (sel = "10") then
			q <= b;
		ELSE
			q <= (OTHERS => 'Z'); -- high impedence
		END IF;
	END PROCESS;
END Behavioral;

-- 3.2 	Multiplexer(WHEN)

-- 3.2.1 WHEN/ELSE statement

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY mux IS
	PORT ( 
		a, b, c, d : IN std_logic;
		sel : IN std_logic_vector(1 DOWNTO 0);
		y : OUT std_logic
	);
END mux;

ARCHITECTURE Behavioral OF mux IS
BEGIN
	y <= a WHEN sel = "00" ELSE
		 b WHEN sel = "01" ELSE
		 c WHEN sel = "10" ELSE
		 d;
END Behavioral;

-- 3.2.2 WITH/SELECT/WHEN

-- 3.2.2.1 STD_LOGIC_VECTOR

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY mux IS
	PORT (
		a, b, c, d : IN STD_LOGIC;
		sel : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
		y : OUT STD_LOGIC
	);
END mux;

ARCHITECTURE mux2 OF mux IS
BEGIN
	WITH sel SELECT
		y <= a WHEN "00",	-- , instead of ;
			 b WHEN "01",
			 c WHEN "10",
			 d WHEN OTHERS;	-- can't be "11", should cover every possible conditions
END mux2;

-- 3.2.2.2 INTEGER

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY mux IS
	PORT (
		a, b, c, d : IN STD_LOGIC;
		sel : IN INTEGER RANGE 0 TO 3;
		y : OUT STD_LOGIC
	);
END mux;

-- Select required structure with CONFIGURATION statement

ARCHITECTURE Behavioral1 OF mux IS	-- 1. with WHEN/ELSE
BEGIN
	y <= a WHEN sel = 0 ELSE
		 b WHEN sel = 1 ELSE
		 c WHEN sel = 2 ELSE
		 d;
END Behavioral1;

ARCHITECTURE Behavioral2 OF mux IS	-- 2. with WITH/SELECT/WHEN
BEGIN
	WITH sel SELECT
		y <= a WHEN 0,	-- , instead of ;
			 b WHEN 1,
			 c WHEN 2,
			 d WHEN 3;	-- here 3 is equal to OTHERS, compared to 3.2.2.1
END Behavioral2;



-- 4. 	Down-counter (4-bit)

USE ieee.std_logic_signed.ALL;

ENTITY down_count IS
    PORT ( clk,rst : IN std_logic;
           count   : OUT std_logic_vector(3 DOWNTO 0);
		   finish  : OUT std_logic
		  );
END down_count;

ARCHITECTURE Behavioral OF down_count IS
    SIGNAL temp : std_logic_vector(3 DOWNTO 0) := "1111";
    BEGIN
    PROCESS(clk,rst)
        BEGIN
            IF rising_edge(clk) THEN
                IF (rst = '1') THEN
                    temp <= "1111";
                    finish <= '0';
                ELSE
                    IF temp = "0000" THEN
                        finish <= '1';
                    ELSE 
                        finish <= '0';
                        temp <= temp - 1;
                    END IF;
                END IF;
            END IF;
    END PROCESS;
    
    count <= temp; -- concurrent statement
	
END Behavioral;



-- 5. 	Adder

-- 5.1 Method 1: in/out = SIGNED

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;
--USE ieee.numeric_std.ALL;

ENTITY adder IS
	PORT (
		a,b : IN signed(3 DOWNTO 0);
		sum : OUT signed(4 DOWNTO 0)
	);
END adder;

ARCHITECTURE adder OF adder IS 	-- * architecture can have same name as entity
BEGIN
	sum <= signed('0'&std_logic_vector(a)) + signed('0'&std_logic_vector(b));   -- add one bit only possible in type std_logic_vector
END adder;

-- 5.2 Method 2: out = INTEGER

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY adder is
	PORT (
		a,b : IN signed(3 DOWNTO 0);
		sum : OUT integer RANGE -16 TO 15
	);
END adder;

ARCHITECTURE adder OF adder IS 	-- * architecture can have same name as entity
BEGIN
	sum <= CONV_INTEGER(a + b);                   -- signed senmantic is like std_logic_vector, and add operation can happen on different width 
END adder;

-- testbench of 5.2

LIBRARY IEEE;
USE IEEE.STD_LOGIC_1164.ALL;
USE ieee.std_logic_arith.ALL;

ENTITY tb_adder IS
--  Port ( );
END tb_adder;

ARCHITECTURE Behavioral OF tb_adder IS

SIGNAL clk : std_logic := '0';
SIGNAL a : signed(3 DOWNTO 0) := "0001";
SIGNAL b : signed(3 DOWNTO 0) := "0010";
SIGNAL sum : integer;

COMPONENT adder IS
	PORT (
		a,b : IN signed(3 DOWNTO 0);
		sum : OUT integer RANGE -16 TO 15  -- 3-bit signed -8 TO 7
	);
END COMPONENT;

BEGIN

DUT : adder
PORT MAP
(
    a => a,
    b => b,
    sum => sum
);

PROCESS -- system reference clock
BEGIN
	clk <= '1';
	WAIT FOR 1 ms;
	clk <= '0';
	WAIT FOR 1 ms;
END PROCESS;

PROCESS (clk)
BEGIN
    IF rising_edge(clk) THEN
        a <= a + 1;
    END IF;
END PROCESS;

END Behavioral;



-- 6. 	Universal Parity Detector

-- return 1 if parity is odd number of 1, 0 if even number of 1.

ENTITY parity_det IS
	GENERIC (
		n : INTEGER := 7
	);
	PORT(
		input  : IN bit_vector(n DOWNTO 0);
		output : OUT BIT;
	);
END parity_det;

ARCHITECTURE parity OF parity_det IS
BEGIN
	PROCESS (input) -- sensitivity list only input, not sequential circuit
		VARIABLE temp : BIT;
	BEGIN
		temp :=  '0';
		FOR i IN input'RANGE LOOP
			temp := temp XOR input(i);
		END LOOP;
		output <= temp;
	END PROCESS;
END parity;
	
-- testbench of parity detector

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tb_parity_det IS
--  Port ( );
END tb_parity_det;

ARCHITECTURE Behavioral OF tb_parity_det IS

COMPONENT parity_det IS
	GENERIC (
		n : INTEGER := 7
	);
	PORT(
		input  : IN bit_vector(n DOWNTO 0);
		output : OUT BIT
	);
END COMPONENT;

SIGNAL input : bit_vector(7 DOWNTO 0) := (OTHERS => '0');
SIGNAL output : bit := '0'; -- even number of '1'

BEGIN

    DUT : parity_det 
        GENERIC MAP
        (
             n => 7
        )
        PORT MAP
        (
            input => input,
            output => output
        );

    PROCESS
    BEGIN
		input <= "10001000";
		WAIT FOR 1 ms;
		input <= "11100000";
		WAIT FOR 1 ms;
        
        ASSERT false
        REPORT "Simulation finished"
        SEVERITY failure;
    END PROCESS;

END Behavioral;



-- 7. 	Universal Parity Generator

-- output = input + parity bit, make number of 1 even

ENTITY parity_gen IS
	GENERIC (
		n : INTEGER := 7
	);
	PORT (
		input : IN BIT_VECTOR(n-1 DOWNTO 0);
		output : OUT BIT_VECTOR(n DOWNTO 0)
	);
END parity_gen;

ARCHITECTURE Behavioral OF parity_gen IS
BEGIN
	PROCESS (input)
		VARIABLE temp1 : BIT;
		VARIABLE temp2 : BIT_VECTOR(output'RANGE);
	BEGIN
		temp1 := '0';	-- parity bit initial value '0'
		FOR i IN input'RANGE LOOP
			temp1 := temp1 XOR input(i);
			temp2(i) := input(i);	-- first n-1 bits of output same as input, left most bit is parity bit
		END LOOP;
		temp2(output'HIGH) := temp1;
		output <= temp2;
	END PROCESS;
END Behavioral;
		
-- testbench of parity generator

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tb_parity_gen IS
--  Port ( );
END tb_parity_gen;

ARCHITECTURE Behavioral OF tb_parity_gen IS

COMPONENT parity_gen IS
	GENERIC (
		n : INTEGER := 8
	);
	PORT (
		input : IN BIT_VECTOR(n-1 DOWNTO 0);
		output : OUT BIT_VECTOR(n DOWNTO 0)
	);
END COMPONENT;

SIGNAL input : bit_vector(7 DOWNTO 0) := (OTHERS => '0');
SIGNAL output : bit_vector(8 DOWNTO 0) := (OTHERS => '0');

BEGIN

    DUT : parity_gen
        GENERIC MAP
        (
             n => 8
        )
        PORT MAP
        (
            input => input,
            output => output
        );

    PROCESS
    BEGIN
        input <= "10001000";
        WAIT FOR 1 ms;
        input <= "11100000";
        WAIT FOR 1 ms;
        
        ASSERT false
        REPORT "Simulation finished"
        SEVERITY failure;
    END PROCESS;

END Behavioral;



-- 8. 	Tri-State buffer

-- ena low then output <= input; end high then output <= "ZZZZZZZZ" (high impedence)

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tri_state IS
	PORT (
		ena : IN STD_LOGIC;
		input : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		output : OUT STD_LOGIC_VECTOR(7 DOWNTO 0)
	);
END tri_state;

ARCHITECTURE Behavioral OF tri_state IS
BEGIN
	output <= input WHEN (ena='0') ELSE
			  (OTHERS => 'Z');
END Behavioral;



-- 9.	Full adder

-- carry and addition result: cout = a.b + a.cin + b.cin

ENTITY full_adder IS
PORT (a, b, cin : IN BIT;
	  s, cout   : OUT BIT);
END full_adder;

ARCHITECTURE dataflow OF full_adder IS
BEGIN
	s <= a XOR b XOR cin;
	cout <= (a AND b) OR (b AND c) OR (a AND cin);
END dataflow;






























