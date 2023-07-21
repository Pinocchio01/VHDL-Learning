------------------------------------------------------------------------ 
--
-- Title: Operations&Attributes in VHDL 
--
-- Company: University of Stuttgart (IIS)
--
-- Author: Yichao Peng
--
-- Project Name: VHDL Coding Style
--
-- Target Devices: 
-- Tool Versions: 
-- Description: This document includes the Operations in VHDL and Attributes of data types.
-- 				Copyright reserved.
-- Dependencies: 
-- 
-- History:
-- 	Version 0.1  Create file, Yichao Peng, 2022/09/28 17:28:40
--
-- Additional Comments:
--
-- Part 1 : Operations in VHDL (6 Predefined Operations):
--
-- 1.1 Assignment operations
-- 1.2 Logical operations
-- 1.3 Arithmetic operations
-- 1.4 Relational operations
-- 1.5 Shift operations
-- 1.6 Concatenation operations
--
-- Part 2 : Attributes in VHDL:
--
-- 2.1 Predefined attributes
--		2.1.1 Value type attributes
--      2.1.2 Signal type attributes
-- 2.2 User defined attributes
--
-- Part 3 : Operations extension : user defined function
--
-- Part 4 : Generics
--
------------------------------------------------------------------------



------------ Part 1 : Operations in VHDL ---------------

----- 1.1 : Assignment operations -----

SIGNAL x : std_logic;
VARIABLE y : STD_LOGIC_VECTOR(3 DOWNTO 0); -- left most MSB
SIGNAL z : STD_LOGIC_VECTOR(0 TO 7); -- right most MSB

x <= '1';                        -- <= SIGNAL
y := "0000";					 -- := VARIABLE, CONSTANT and GENERIC, or initial value of SIGNAL
z <= (0 => '1', OTHERS => '0');  -- => some bits in vector


----- 1.2 : Logical operations -----
 
-- * Operands must in following types: BIT, STD_LOGIC, STD_ULOGIC or extensions(BIT_VECTOR, STD_LOGIC_VECTOR or STD_ULOGIC_VECTOR)
-- * Priority : NOT > AND > OR > NAND > NOR > XOR

y <= NOT a AND b;		-- (a'.b)
y <= NOT(a AND b);		-- (a.b)'
y <= a NAND b;			-- (a.b)'


----- 1.3 : Arithmetic operations -----
 
-- * Operands must in following types: INTEGER, SIGNED, UNSIGNED, REAL. REAL unsynthesizable.
-- * If std_logic_signed and std_logic_unsigned declared, STD_LOGIC_VECTOR objects can add or substract.

-- 8 operators: +, -, *, /, **, MOD, REM, ABS (+,-,* synthesizable, / only synthesizable for divider 2**n, which means shift right n bits).

delta <= ABS(a-b);
c     <= a MOD b; -- pay attention to difference between MOD and REM


----- 1.4 : Relational operations -----

-- =, /=, <, >, <=, >=
-- Operants must in any same type named before.

counter /= 8;  -- return true or false


----- 1.5 : Shift operations -----
/*
(1) introduced by VHDL 93
(2) syntatic structure: <left operand: bit_vector> <shift operator> <right operator: integer>
*/

x <= "01001";

y <= x SLL 2; 	-- shift left logic "00100", add 0 on right
y <= x SRL 3; 	-- shift right logic "00001" add 0 on left
y <= x SRL -2; 	-- equal to SLL 2

y <= x SLA 2; 	-- shift left arithmatic "00111", copy right
y <= x SRA 3; 	-- shift right arithmatic "00001" copy left

y <= x ROL 2; 	-- ring on left "00101" circular shift
y <= x ROR 2;   -- ring on right "01010" circular shift


----- 1.6 : Concatenation operations -----

-- bit concatenation, used on any type supporting logical operations
-- Two forms: (1) & (2) (,,,)

z <= x & "10000000";	-- x <= '1' then z <= "11000000"
z <= ('1', '1','0', '0', '0', '0', '0', '0')	-- z <= "11000000"



------------ Part 2 : Attributes in VHDL ---------------

-- ATTRIBUTE statement can get information from objects and thus make code more flexible.


-- 2.1 Predefined Attributes(VHDL 87): value type and signal type

-- 2.1.1 Value type attribute

-- synthesizable : d'LOW, d'HIGH, d'LEFT, d'RIGHT, d'LENGTH, d'RANGE, d'REVERSE_RANGE

SIGNAL d : STD_LOGIC_VECTOR(7 DOWNTO 0);
-- d'LOW = 0, d'HIGH = 7, d'LEFT = 7, d'RIGHT = 0, d'LENGTH = 8, d'RANGE = (7 DOWNTO 0), d'REVERSE_RANGE = (0 TO 7)
-- type: integer
-- following 4 loops are equal and synthesizable:

FOR i IN RANGE(0 TO 7) LOOP... -- generate n hardware circuits, instead of running a code n times
FOR i IN x'RANGE(0 TO 7)LOOP...
FOR i IN RANGE(x'LOW TO x'HIGH) LOOP...
FOR i IN RANGE(0 TO x'LENGTH-1) LOOP... 

-- Attributes for enumerate types, mostly unsynthesizable

-- d'VAL(pos), d'POS(value), d'LEFTOF(value), d'VAL(row,column)

-- 2.1.2 Signal type attribute

-- s'EVENT & s'STABLE : synthesizable
-- s'ACTIVE, s'QUITE<time>, s'LAST_EVENT, s'LAST_ACTIVE, s'LAST_VALUE : unsynthesizable, only for simulation

 -- following 4 loops are equal and synthesizable:

IF (clk'EVENT AND clk = '1')...
IF (NOT clk'STABLE AND clk = '1')...
WAIT UNTIL (clk'EVENT AND clk = '1')...
IF RISING_EDGE(clk)...


-- 2.2 User defined Attributes

-- 2.2.1 Attribute declaration
ATTRIBUTE attribute_name : attribute_type;	-- type can be any data type

-- 2.2.2 Attribute description
ATTRIBUTE attribute_name OF target_name: class IS value;	-- class can be data type, signal, function, entity or architecture

-- example 1
ATTRIBUTE number_of_inputs : INTEGER;	-- attribute declaration
ATTRIBUTE number_of_inputs OF nand3 : SIGNAL IS 3;	-- attribute description
...
inputs <= nand3'number_of_inputs;	-- attribute calling

-- example 2
TYPE color IS (red, green, blue, white);	-- user defined enumerate type; red = "00", green = "01"...
ATTRIBUTE enum_encoding OF color : TYPE IS "11 00 10 01";	-- reencode the enumerate type; red = "11", ...

-- * User defined attribute can be declared anywhere in the code, but may not be synthesizable



------------ Part 3 : Operations extension : user defined function ---------------

-- Predefined operations are limited in specific types.
-- User defined operations can have same name as predefined operations.

-- example 1 : create function with name "+" to perform addition on INTEGER and BIT

FUNCTION "+" (a : INTEGER; b : BIT) RETURN INTEGER IS	-- function definition
BEGIN
	IF (b = '1') THEN RETURN a+1;
	ELSE RETURN a;
	END IF;
END "+";

SIGNAL inp1, outp : INTEGER RANGE 0 TO 15; -- function calling
SIGNAL inp2 : BIT;
...
outp <= 3 + inp1 + inp2;	-- first + predefined operation; second + function
...



------------ Part 4 : Generics ---------------

-- declare regular, static parameters
-- modifiable, improve flexibility and reuseability
-- * must be declared in ENTITY part
-- GENERIC parameters are global, can be used within whole design afterwards

GENERIC (parameter_name : parameter_type := parameter_value);

-- example 1:

ENTITY my_entity IS
	GENERIC (
		n : integer := 8,
		vector : bit_vector(7 DOWNTO 0) := "00001111"
	);
	PORT (...);
END my_entity;
ARCHITECTURE my_architecture OF my_entity IS
	...
END my_architecture;

-- example 2 : Universal decoder
-- universal m-n decoder. ena = '0' then x(all) = '1', else x according to truth table

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY decoder IS
	PORT(
		ena : IN std_logic;
		sel : IN std_logic_vector(2 DOWNTO 0);
		x   : OUT std_logic_vector(7 DOWNTO 0)
	);
END decoder;

ARCHITECTURE generic_decoder OF decoder IS`
BEGIN
	PROCESS (ena, sel)
		VARIABLE temp1 : STD_LOGIC_VECTOR(x'HIGH DOWNTO 0);
		VARIABLE temp2 : INTEGER RANGE 0 TO x'HIGH;
	BEGIN
		temp1 := (OTHERS => '1'); -- if ena = '0', no operation on temp1, then temp1 <= "11111111"
		temp2 := 0;
		IF (ena = '1') THEN
			FOR i IN sel'RANGE LOOP
				IF (sel(i) = '1') THEN
					temp2 := 2*temp2 + 1;
				ELSE
					temp2 := 2*temp2;
				END IF;
			END LOOP;
			temp1(temp2) := '0';
		END IF;
		x <= temp1;
	END PROCESS;
END generic_decoder;

-- testbench of example 2

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

ENTITY tb_decoder IS
--  Port ( );
END tb_decoder;

ARCHITECTURE Behavioral OF tb_decoder IS

COMPONENT decoder IS
	PORT(
		ena : IN std_logic;
		sel : IN std_logic_vector(2 DOWNTO 0);
		x   : OUT std_logic_vector(7 DOWNTO 0)
	);
END COMPONENT;

SIGNAL ena : std_logic := '0';
SIGNAL sel : std_logic_vector(2 DOWNTO 0) := "010";
SIGNAL x   : std_logic_vector(7 DOWNTO 0);

BEGIN

DUT : decoder PORT MAP
(
    ena => ena,
    sel => sel,
    x => x
);

PROCESS
BEGIN
    ena <=  '1';
    WAIT FOR 2 ms;
    ena <= '0';
    sel <= "001";
    WAIT FOR 2 ms;
    
    ASSERT false
	REPORT "Simulation finished"
	SEVERITY failure;
END PROCESS;

END Behavioral;



-- example 3 : Universal Parity Detector
-- check parity of bit_vector

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



