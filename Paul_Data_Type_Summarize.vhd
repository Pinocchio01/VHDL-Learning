----------------------------------------------------------------------------------------------
--
-- Title: data types in VHDL 
--
-- Company: University of Stuttgart (IIS)
--
-- Author: Yichao Peng
--
-- Project Name: VHDL Coding Style
--
-- Target Devices: 
-- Tool Versions: 
-- Description: This document includes standard VHDL data types and assignments regulations.
--              Copyright reserved.
-- Dependencies: 
-- 
-- Additional Comments:
-- 
-- History:
-- 	Version 0.1  Create file, Yichao Peng, 2022/09/27 17:28:40

--
----------------------------------------------------------------------------------------------



---- 1. Libraries and packages in VHDL ----------------------

-- 		* LIBRARY and USE are reserved keywords in VHDL

-- 		1.1 ieee
LIBRARY ieee; -- ieee, std, work
USE ieee.std_logic_1164.ALL;  -- STD_LOGIC(8 values), STD_ULOGIC(9 values) ; * mostly often used package
USE ieee.std_logic_arith;     -- SIGNED, UNSIGNED; conv functions
USE ieee.std_logic_signed;    -- function for std_logic_vector to operate like signed
USE ieee.std_logic_unsigned;  -- function for std_logic_vector to operate like unsigned

-- 		1.2 std
LIBRARY std; -- standard resource library, include packages: standard and textio
USE std.standard.ALL;

-- 		1.3 work
LIBRARY work; -- current workspace, include ALL codes in current design, * need not be declared 
USE work.ALL;

--		1.4 Library declaration
LIBRARY library_name;
USE library_name.package_name.package_parts;




---- 2. Predefined data type in VHDL IEEE 1076 and IEEE 1164 ----

-- 		2.1 BIT and BIT_VECTOR

-- declarations
SIGNAL x ：bit;
SIGNAL y : bit_vector(3 DOWNTO 0);  -- left MSB
SIGNAL w : bit_vector(0 TO 7);      -- right MSB

-- 		assignments
x <= '1'; 			-- * width equal 1 then value in single quotion ' '
y <= "0111"; 		-- * width larger than 1 then value in double quotion " "; MSB = '0'
w <= "01110001" 	-- * MSB = '1'

-- 		2.2 STD_LOGIC and STD_LOGIC_VECTOR

-- * STD_LOGIC type output can be connected to a common node!
-- declarations
SIGNAL x : std_logic; 	-- STD_LOGIC multilogic system => 8 possible values: 'X', '0', '1', 'Z', 'W', 'L', 'H', '-'; only '0' '1' 'Z' synthesizable
SIGNAL y : std_logic_vector(3 DOWNTO 0) := "0001"; 	-- initial value optional

-- 		2.3 STD_ULOGIC and STD_ULOGIC_VECTOR

-- * STD_ULOGIC type output must not be connected to a common node!
-- declarations
SIGNAL x ：std_ulogic;  -- STD_ULOGIC multilogic system => 9 possible values: 'X', '0', '1', 'Z', 'W', 'L', 'H', '-', 'U'; only '0' '1' 'Z' synthesizable 
SIGNAL y : std_ulogic_vector(3 DOWNTO 0);

-- 		assignments
x <= '1'; 			-- * width equal 1 then value in single quotion ' '
y <= "0111"; 		-- * width larger than 1 then value in double quotion " "; MSB = '0'
w <= "01110001"; 	-- * MSB = '1'

-- 		2.4 BOOLEAN

SIGNAL x : boolean := true; -- false

-- 		2.5 INTEGER

SIGNAL x : integer := 10; -- 32-bit integer range from -2147483647 to 2147483647

-- 		2.6 NATURAL

SIGNAL x : natural := 10; -- non-negative integer from 0 to 2147483647

-- 		2.7 REAL

SIGNAL x : real := -1.5;  -- real number from -1.0*10^38 to 1.0*10^38, not synthesizable

-- 		2.8 Physical literal

SIGNAL x : time := 10 ns; -- physical quantity like time or voltage, etc. For simulation use only, not synthesizable
-- * The VHDL standard predefines only one physical type: TIME, which is defined in the STANDARD package.
-- * See following chapter for user defined physical type.

-- 		2.9 CHARACTER and STRING

SIGNAL x : character := 'a';   -- single character
SIGNAL y : string := "abcdef"; -- string

-- 		2.10 SIGNED and UNSIGNED

USE ieee.numeric_std.ALL;

SIGNAL x : signed(3 DOWNTO 0) := "0111";   -- detail see later section
SIGNAL y : unsigned(3 DOWNTO 0) := "1000";


----  Examples of predefined types ---------------------

-- types

x0 <= '0';			-- BIT, STD_LOGIC or STD_ULOGIC
x1 <= "00011111";   -- BIT_VECTOR, STD_LOGIC_VECTOR, STD_ULOGIC_VECTOR, SIGNED or UNSIGNED
x2 <= "0001_1111";  -- underline allowed in BIT_VECTOR: same as x2, improved readability
x3 <= "101111";     -- binary number "101111", decimal number 47
x4 <= B"101111";    -- same as x3, as default binary
x5 <= O"57";        -- octal 57, decimal 47
x6 <= X"2F";        -- hexadecimal 2F, decimal 47
n  <= 1200;         -- integer
m  <= 1_200;        -- underline allowed in integer
IF ready THEN ...   -- boolean operation: if ready is true then operate statements after THEN
y  <= 1.2E-5        -- real number, unsynthesizable
q  <= d after 10 ns -- physical quantity, unsynthesizable

-- assignments

SIGNAL a : BIT;
SIGNAL b : BIT_VECTOR(7 DOWNTO 0);
SIGNAL c : STD_LOGIC;
SIGNAL d : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL e : INTEGER RANGE 0 TO 255;
-- ...
-- legal operations between different data types
a <= b(5);
b(0) <= a;
c <= d(5);
d(0) <= c;
-- illegal operations
a <= c;
b <= d;
e <= b;
e <= d;




---- 3. User defined data type in VHDL ----

-- user defined INTEGER types

TYPE integer IS RANGE -2147483647 TO +2147483647; 	-- same as predefined type INTEGER
TYPE natural IS RANGE 0 TO +2147483647;				-- same as predefined type NATURAL
TYPE my_integer IS RANGE -32 TO 32;					-- subset of predefined type INTEGER
TYPE student_grade IS RANGE 0 TO 100;               -- subset of predefined type NATURAL

-- user defined ENUMERATED types

TYPE bit IS ('0', '1');                             -- same as BIT in essence
TYPE my_logic IS ('0', '1', 'Z');                   -- subset of STD_LOGIC
TYPE bit_vector IS ARRAY(NATURAL RANGE<>) OF bit;   -- RANGE<> : no value bounding; NATURAL RANGE<> : bounded in natural value
TYPE state IS (idle, forward, backward, stop);      -- enumerate type for FSM
TYPE color IS (red, green, blue, white);            -- automatically coded: red - "00", green - "01", blue - "10"; white - "11"
-- * user defined properties will be showed later



---- 4. Subtype in VHDL -------------------

-- * new type vs. subtype: subtype can operate with parent type, new type is different from other types, operation not allowed

-- example of subtypes

SUBTYPE natural IS integer RANGE 0 TO INTEGER'HIGH;  -- natural as subtype of integer
SUBTYPE my_logic IS STD_LOGIC RANGE '0' TO 'Z';      -- my_logic =  ('0' '1' 'Z'), because STD_LOGIC = ('X', '0', '1', 'Z', 'W', 'L', 'H', '-');
SUBTYPE my_color IS color RANGE red TO blue;         -- my_color = (red, green, blue)
SUBTYPE small_integer IS integer RANGE -32 TO 32;    -- subtype of integer

-- assignments

SUBTYPE my_logic IS STD_LOGIC RANGE '0' TO '1';      -- subtype of std_logic
SIGNAL a : BIT;
SIGNAL b : STD_LOGIC;
SIGNAL c : my_logic;
-- ...
-- legal operations between different data types
b <= c;  --  type and subtype can operate
-- illegal operations
b <= a;  -- bit does not match with std_logic




---- 5. Array in VHDL -------------------

-- * 1D, 2D or 1x1D... High dimensional arrays are usually unsynthesizable

TYPE type_name IS ARRAY (specification) OF data_type;   -- define new array type
SIGNAL signal_name : type_name [ := initial_value];     -- declare signal, variable and constant using new array type; initial value optional

-- example 1 : 1x1D
TYPE row IS ARRAY(7 DOWNTO 0) OF STD_LOGIC;             -- 1D array
TYPE matrix IS ARRAY(0 TO 3) OF row;                    -- 1x1D array 
SIGNAL r : row := "00010001";							-- 1D Signal
SIGNAL r0: row := ('0','0','0','1','0','0','0','1');    -- 1D Signal
SIGNAL x : matrix :=  (('0','0','0','1','0','0','0','1'),('0','0','0','1','0','0','0','1'),
						('0','0','0','1','0','0','0','1'),('0','0','0','1','0','0','0','1'));   -- 1x1D signal

-- example 2 : 1x1D
TYPE matrix IS ARRAY(0 TO 3) OF std_logic_vector(7 DOWNTO 0); -- from data compatibility point of view, this method is better

-- example 3 : 2D (element scalar)
TYPE matrix2D IS ARRAY(0 TO 3, 7 DOWNTO 0) OF STD_LOGIC; -- 2D array

SIGNAL v : matrx := (('0','0','0','1','0','0','0','1'),('0','0','0','1','0','0','0','1'),
					('0','0','0','1','0','0','0','1'),('0','0','0','1','0','0','0','1'));       -- initialization of 2D or 1x1D signal
 
SIGNAL m : matrix2D :=  (('0','0','0','1','0','0','0','1'),('0','0','0','1','0','0','0','1'),
						('0','0','0','1','0','0','0','1'),('0','0','0','1','0','0','0','1'));   -- initialization of 2D or 1x1D signal

--  scalar assignments (this case std_logic type)
r(0) <= x(1)(2);
x(0)(0) <= m(3,3);

-- vector assignments
r <= x(0);  -- row type
x(1)(7 DOWNTO 3) <= r(4 DOWNTO 0);
v(1)(7 DOWNTO 3) <= v(2)(4 DOWNTO 0);





---- 6. Port Array in VHDL -------------------

-- * Predefined data type no more than 1D. What for port array?
--   In ENTITY is user type definition not allowed => must define in package!

-- Example of array definition in package and usage in main code

---- Package 1 ----  
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

PACKAGE my_data_types IS
	TYPE vector_array IS ARRAY (NATURAL RANGE <>) OF
		STD_LOGIC_VECTOR(7 DOWNTO 0);
END my_data_types;

--- Package 2 ----
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

PACKAGE my_data_types IS
	CONSTANT b : INTEGER := 7;
	TYPE vector_array IS ARRAY (NATURAL RANGE <>) OF
		STD_LOGIC_VECTOR(b DOWNTO 0);
END my_data_types;
-- * package 1 same function as package 2, only using constant


---- Main Code ----
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE work.my_data_types.ALL;

ENTITY mux IS
	PORT (
		inp: IN vector_array(0 TO 3);
		...
	);
END mux;
...;




---- 6. Record in VHDL -------------------
-- * RECORD can store data in different types, while ARRAY can only store same type

-- example of RECORD

TYPE birthday IS RECORD
	day : INTEGER RANGE 1 TO 31;
	month : month_name;
	
	
	
	
	
---- 7. Signed and Unsigned -------------------
-- * included in std_logic_arith package of ieee library
-- * semantics different from INTEGER, but similar as STD_LOGIC_VECTOR

-- example
LIBRARY ieee;
USE ieee.std_logic_arith.ALL;

SIGNAL x  : SIGNED(3 DOWNTO 0) := "0101";  -- decimal 5
SIGNAL x0 : SIGNED(3 DOWNTO 0) := "1101";  -- decimal -3 = - (2 + 1)
SIGNAL y  : UNSIGNED(0 TO 3)   := "1010";  -- decimal 5
SIGNAL y0 : UNSIGNED(0 TO 3)   := "1011";  -- decimal 13 
-- * stronly recommend DOWNTO instead of TO: confirm the habit of binary number

-- no logical operations for signed and unsigned
SIGNAL a : SIGNED(3 DOWNTO 0);
SIGNAL b : SIGNED(3 DOWNTO 0);
x <= a + b; -- arithmatic operation legal for signed and unsigned
-- x <= a & b; -- illegal

-- Two packages: STD_LOGIC_SIGNED and STD_LOGIC_UNSIGNED allow STD_LOGIC_VECTOR to calculate as signed or unsigned
-- examples
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL; -- must declare
...
SIGNAL a : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL b : STD_LOGIC_VECTOR(7 DOWNTO 0);
SIGNAL x : STD_LOGIC_VECTOR(7 DOWNTO 0);
...
x <= a+b;       -- legal
x <= a AND b;   -- legal





---- 8. Data Type Transform -------------------
-- * Method 1: write code for transform; Method 2: use predefined function in packages

-- example
TYPE long IS INTEGER RANGE -100 TO +100;
TYPE short IS INTEGER RANGE -10 TO 10;
SIGNAL x : short;
SIGNAL y : long;
...
--  y <= 2 * x + 5; -- illegal
y <= long(2*x+5);   -- legal

-- * std_logic_arith package has following functions: 
-- 1. conv_integer(p) 				: p is integer, unsigned, signed, std_ulogic, std_logic, NOT std_logic_vector
-- 2. conv_unsigned(p,b) 			: p is integer, unsigned, signed or std_logic
-- 3. conv_signed(p,b)      		: p is integer, unsigned, signed or std_logic
-- 4. conv_std_logic_vector(p,b)	: p is integer, unsigned, sigend or std_logic 

-- examples
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_arith.ALL; -- must declare
...
SIGNAL a : unsigned(7 DOWNTO 0);
SIGNAL b : unsigned(7 DOWNTO 0);
SIGNAL y : STD_LOGIC_VECTOR(7 DOWNTO 0);
...
y <= conv_std_logic_vector((a+b),8);
