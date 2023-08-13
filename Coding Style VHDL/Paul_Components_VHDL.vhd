----------------------------------------------------------------------------------------------
--
-- Title: Common digital circuit components written in VHDL 
--
-- Company: University of Stuttgart (IIS)
--
-- Author: Yichao Peng
--
-- Project Name: VHDL Coding Style
--
-- Target Devices: 
-- Tool Versions: 
-- Description: This document includes digital circuits design components. All validated.
--              Copyright reserved.
-- Dependencies: 
-- 
-- Additional Comments: ... means some codes omitted.
-- 
-- History:
-- 	Version 0.1  Create file, Yichao Peng, 2022/09/25 15:51
--  Version 0.2  Add components, Yichao Peng, 2023/08/10 21:05
----------------------------------------------------------------------------------------------

-- List for components:
-- 1. 	NAND Gate
-- 2. 	D Flip-Flop with Asynchronous Reset
-- 3.   Multiplexer(IF)
-- 4. 	Down-counter (4-bit)
-- 5. 	Adder
-- 6. 	Universal Parity Detector
-- 7. 	Universal Parity Generator
-- 8. 	Tri-State Buffer
-- 9.	Full Adder
-- 10.  ALU (Arithmetic + Logic -> Multiplexer)
-- 11.  Vector Shifter
-- 12.  Mod-10 Counter
-- 13.  Shift Register
-- 14.  Cascade Adder


----------------------------------------------------------------------------------------------


-- 1.	NAND Gate

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY nand_gate IS
	PORT (
		a, b : IN bit;
		o : OUT bit
		);
END nand_gate;

ARCHITECTURE Behavioral OF nand_gate IS
BEGIN
	o <= a nand b;						-- pure conbinational logic
END Behavioral;



-- 2. 	D Flip-Flop with Asynchronous Reset

-- 2.1 	With sensitivity list

-- 2.1.1 Using IF Statement

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY dff IS
	PORT(
		d, clk, arstn: IN std_logic; 	-- active low
		q : OUT std_logic
	);
END dff;

ARCHITECTURE Behavioral OF dff IS
BEGIN
	PROCESS(arstn, clk)
	BEGIN
		IF (arstn = '0') THEN
			q <= '0';
		ELSIF rising_edge(clk) THEN
			q <= d;
		END IF;
	END PROCESS;
END Behavioral;

-- 2.1.2 Using CASE Statement

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY dff IS
	PORT(
		d, clk, arstn: IN std_logic; 					-- Active low
		q : OUT std_logic
	);
END dff;

ARCHITECTURE Behavioral OF dff IS
BEGIN
	PROCESS(arstn, clk)
	BEGIN
		CASE rstn IS
			WHEN '1' => q <= '0';
			WHEN '0' =>
				IF (clk'event and clk = '1') THEN
					q <= d;
				END IF;
			WHEN OTHERS => NULL;						-- Like UNAFFECTED, nothing happens
		END CASE;
	END PROCESS;
END Behavioral;

-- 2.2 	Without sensitivity list (WAIT ON statement)

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY dff IS
	PORT(
		d, clk, arstn: IN std_logic; 	-- active low
		q : OUT std_logic
	);
END dff;

ARCHITECTURE Behavioral OF dff IS
BEGIN
	PROCESS
	BEGIN
		WAIT ON rst, clk;
		IF (arstn = '0') THEN
			q <= '0';
		ELSIF rising_edge(clk) THEN
			q <= d;
		END IF;
	END PROCESS;
END Behavioral;



-- 3. Multiplexer

-- 3.0 Multiplexer(Logical Operators only)

ENTITY mux IS
	PORT(
		a, b, c, d, s0, s1 : IN std_logic;		-- 4-inputs Multiplexer
		y : OUT std_logic
		);
END mux;

ARCHITECTURE pure_logic OF mux IS
BEGIN
	y <= (a and not s1 and not s0) OR			-- not has higher priority than and
		 (b and not s1 and s0) OR
		 (c and s1 and not s0) OR
		 (d and s1 and s0);
END pure_logic;

-- 3.1 	Multiplexer(IF)

ENTITY mux IS
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

-- 3.2.1 WHEN/ELSE

ENTITY mux IS
	PORT ( 
		a, b, c, d : IN std_logic;
		sel : IN std_logic_vector(1 DOWNTO 0);
		y   : OUT std_logic
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

ENTITY mux IS
	PORT (
		a, b, c, d : IN std_logic;
		sel : IN std_logic_vector(1 DOWNTO 0);
		y   : OUT std_logic
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

ENTITY mux IS
	PORT (
		a, b, c, d : IN std_logic;
		sel : IN integer RANGE 0 TO 3;
		y : OUT std_logic
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
		y <= a WHEN 0,							-- , instead of ;
			 b WHEN 1,
			 c WHEN 2,
			 d WHEN 3;							-- Here 3 is equal to OTHERS, compared to 3.2.2.1
END Behavioral2;



-- 4. 	Down-counter (4-bit)

USE ieee.std_logic_unsigned.ALL;

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
    
    count <= temp; 								  -- concurrent statement
	
END Behavioral;



-- 5. 	Adder

-- 5.1 Method 1: in/out = SIGNED

USE ieee.std_logic_arith.ALL;
--USE ieee.numeric_std.ALL;

ENTITY adder IS
	PORT (
		a,b : IN signed(3 DOWNTO 0);
		sum : OUT signed(4 DOWNTO 0)
	);
END adder;

ARCHITECTURE adder OF adder IS 					  -- * Architecture can have same name as entity
BEGIN
	sum <= signed('0'&std_logic_vector(a)) + signed('0'&std_logic_vector(b));   -- Add one bit only possible in type std_logic_vector
END adder;

-- 5.2 Method 2: out = INTEGER

USE ieee.std_logic_arith.ALL;

ENTITY adder is
	PORT (
		a,b : IN signed(3 DOWNTO 0);
		sum : OUT integer RANGE -16 TO 15
	);
END adder;

ARCHITECTURE adder OF adder IS
BEGIN
	sum <= CONV_INTEGER(a + b);                   -- Signed senmantic is like std_logic_vector, and add operation can happen on different width 
END adder;

-- testbench of 5.2

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
		sum : OUT integer RANGE -16 TO 15  			-- 3-bit signed -8 TO 7
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

PROCESS 											-- System reference clock
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
		n : integer := 7
	);
	PORT(
		input  : IN bit_vector(n DOWNTO 0);
		output : OUT bit;
	);
END parity_det;

ARCHITECTURE parity OF parity_det IS
BEGIN
	PROCESS (input) -- sensitivity list only input, not sequential circuit
		VARIABLE temp : bit;
	BEGIN
		temp :=  '0';
		FOR i IN input'RANGE LOOP
			temp := temp XOR input(i);
		END LOOP;
		output <= temp;
	END PROCESS;
END parity;
	
-- testbench of parity detector


ENTITY tb_parity_det IS
--  Port ( );
END tb_parity_det;

ARCHITECTURE Behavioral OF tb_parity_det IS

COMPONENT parity_det IS
	GENERIC (
		n : integer := 7
	);
	PORT(
		input  : IN bit_vector(n DOWNTO 0);
		output : OUT bit
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
		n : integer := 7
	);
	PORT (
		input : IN bit_vector(n-1 DOWNTO 0);
		output : OUT bit_vector(n DOWNTO 0)
	);
END parity_gen;

ARCHITECTURE Behavioral OF parity_gen IS
BEGIN
	PROCESS (input)
		VARIABLE temp1 : bit;
		VARIABLE temp2 : bit_vector(output'RANGE);
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

ENTITY tb_parity_gen IS
--  Port ( );
END tb_parity_gen;

ARCHITECTURE Behavioral OF tb_parity_gen IS

COMPONENT parity_gen IS
	GENERIC (
		n : integer := 8
	);
	PORT (
		input : IN bit_vector(n-1 DOWNTO 0);
		output : OUT bit_vector(n DOWNTO 0)
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



-- 8. 	Tri-State Buffer

-- ena low then output <= input; ena high then output <= "ZZZZZZZZ" (high impedence)

ENTITY tri_state IS
	PORT (
		ena : IN std_logic;
		input : IN std_logic_vector(7 DOWNTO 0);
		output : OUT std_logic_vector(7 DOWNTO 0)
	);
END tri_state;

ARCHITECTURE Behavioral OF tri_state IS
BEGIN
	output <= input WHEN (ena='0') ELSE
			  (OTHERS => 'Z');
END Behavioral;



-- 9.	Full adder

-- Carry and addition result: cout = a.b + a.cin + b.cin

ENTITY full_adder IS
	PORT(
		a, b, cin : IN bit;
		s, cout   : OUT bit
	);
END full_adder;

ARCHITECTURE dataflow OF full_adder IS
BEGIN
	s <= a xor b xor cin;
	cout <= (a and b) or (b and c) or (a and cin);	-- Equal to (a and b) or ((a xor b) and c)
END dataflow;



-- 10.  ALU (Arithmetic + Logic -> Multiplexer)

USE ieee.std_logic_unsigned.ALL;					-- For arithmetic calculations

ENTITY ALU IS
	PORT(
		a, b : IN std_logic_vector(7 DOWNTO 0);
		s	 : IN std_logic_vector(3 DOWNTO 0);		-- MSB choose A or L, other 3 bits for different functions
		cin  : IN std_logic;
		y    : OUT std_logic_vector(7 DOWNTO 0)		
	);
END ALU;

ARCHITECTURE dataflow OF ALU IS
	SIGNAL arith, logic : std_logic_vector(7 DOWNTO 0) := (OTHERS => '0');	-- Store arith and logic operation results
BEGIN
	--------------- Arithmetic Unit: -----------------
	WITH sel(2 DOWNTO 0) SELECT
		arith <= a 	   		 WHEN "000",			-- choose a
			  <= a + 1 		 WHEN "000",			-- a + 1
			  <= a - 1 		 WHEN "000",			-- a - 1
			  <= b 			 WHEN "000",			-- choose b
			  <= b + 1 		 WHEN "000",			-- b + 1
			  <= b - 1 		 WHEN "000",			-- b - 1
			  <= a + b  	 WHEN "000",			-- a + b
			  <= a + b + cin WHEN OTHERS;			-- a + b + cin
	---------------- Logic Unit: ---------------------
	WITH sel(2 DOWNTO 0) SELECT
		logic <= not a 	   	 WHEN "000",
			  <= not b 		 WHEN "000",
			  <= a and b 	 WHEN "000",
			  <= a or b 	 WHEN "000",
			  <= a nand b 	 WHEN "000",
			  <= a nor b 	 WHEN "000",
			  <= a xor b  	 WHEN "000",	
			  <= not(a xor b)WHEN OTHERS;		  
	------------------- Mux: --------------------------
	WITH sel(3) SELECT
		y < arith WHEN '0',
			logic WHEN OTHERS;	
END dataflow;



-- 11.  Vector Shifter (GENERATE Statement)
-- 		Shift a 4-bit vector 0-4 bit left to form a 8-bit vector.

ENTITY vector_shifter IS
	PORT(
		inp  : IN std_logic_vector(3 DOWNTO 0);
		sel  : IN integer RANGE 0 TO 4;
		outp : OUT std_logic_vector(7 DOWNTO 0)
	);
END vector_shifter;

ARCHITECTURE Behavioral OF vector_shifter IS
	SUBTYPE vector IS std_logic_vector(7 DOWNTO 0);
	TYPE matrix IS ARRAY(4 DOWNTO 0) OF vector;
	SIGNAL rows : matrix;
BEGIN
	rows(0) <= "0000" & inp;					-- "00001111"
	G1 : FOR i IN 1 TO 4 GENERATE
		rows(i) = row(i-1)(6 DOWNTO 0) & '0';	-- Equal to sll, but sll not on std_logic_vector
	END GENERATE;
	outp <= rows(sel);							-- Choose after generation of all possible results
END Behavioral;



-- 12.  Mod-10 Counter

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY counter IS
	PORT(
		clk   : IN std_logic;
		digit : OUT integer RANGE 0 TO 9
	);
END counter;

ARCHITECTURE Behavioral OF counter IS
BEGIN
	count_proc : PROCESS(clk)
		VARIABLE temp : integer RANGE 0 TO 10;
	BEGIN
		IF (clk'event and clk = '1') THEN			-- Equal to: WAIT UNTIL (clk'event and clk = '1');
			temp := temp + 1;
			IF (temp=10) THEN
				temp := 0;
			END IF;
		END IF;
		digit <= temp;
	END PROCESS;
END Behavioral; 



-- 13.  Shift Register
-- 		Output signal q will have n clk_period delay than input signal d.

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY shiftreg IS
	GENERIC(
		n : integer := 4; 					-- # of stages
	);
	PORT(
		d, clk, rstn : IN std_logic;
		q : OUT std_logic
	);
END shiftreg;

ARCHITECTURE Behavioral OF shiftreg IS
	SIGNAL temp : std_logic_vector(n-1 DOWNTO 0) := (OTHERS => '0');
BEGIN
	PROCESS(clk, rst):
	BEGIN
		IF (rstn = '0') THEN				-- Asynchronous reset
			temp <= (OTHERS => '0');
		ELSIF (clk'event and clk = '1') THEN
			temp <= 'd' & temp(temp'left DOWNTO 1);
		END IF;
	END PROCESS;
	q <= temp(0);
END Behavioral;
	


-- 14.  Cascade Adder
--		Sum: s_j = a_j XOR b_j XOR c_j
--		Carry: c_(j+1) = (a_j AND b_j) OR (a_j AND c_j) OR (b_j AND c_j)

-- 14.1 Generic, with vectors