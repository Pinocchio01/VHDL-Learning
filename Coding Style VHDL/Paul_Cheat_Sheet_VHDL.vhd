----------------------------------------------------------------------------------------------
--
-- Title: Cheat_Sheet_VHDL
--
-- Company: University of Stuttgart (IIS)
--
-- Author: Yichao Peng
--
-- Project Name: VHDL Coding Style
--
-- Target Devices: 
-- Tool Versions: 
-- Description: Illustrate how to write common constructive parts in VHDL.
--              Copyright reserved.
-- Dependencies: 
-- 
-- Additional Comments: (...) codes should be written here, [...] can be written or omitted here.
-- 
-- History:
--
-- 	Version 0.1  Create file, Yichao Peng, 2022/07/24 16:59
--	Version 0.2  Modify file, Yichao Peng, 2023/08/09 22:58
----------------------------------------------------------------------------------------------

-- Directory:
-- 
-- (No.1-No.3 are three basic parts of VHDL codes, No.4 is commonly used structures.)
--
-- 1. Library (and Packages inside)
-- 2. Entity
-- 3. Architecture
--		3.1 Sequential statements
--			3.1.1 Process
--				3.1.1.1 Basic structure without sensitivity list
--              3.1.1.2 Basic structure with sensitivity list
--			3.1.2 Procedures in process
--		3.2 Concurrent statements
--          3.2.1 Operations
--			3.2.2 WHEN statement
--			3.2.3 GENERATE statement
-- 			3.2.4 BLOCK Statement
--				3.2.4.1 Simple BLOCK
--				3.2.4.2 Guarded BLOCK
-- 4. Common statements used in sequential codes
-- 		4.1 IF statement
--      4.2 WAIT statement
--		4.3 CASE statement
--		
-- 		4. State machine
------------------------------------------------------------------------



----- Start of Part 1 : Library and Package -----

-- Three common libraries: ieee, std and work
-- std and work are visible by default and need not be declared

-- !!! Syntactic structure !!! --
LIBRARY library_name;
USE library_name.package_name.package_parts;
-- !!! Syntactic structure !!! --

-- Examples

LIBRARY ieee; 				 		-- Library
USE ieee.std_logic_1164.ALL; 		-- Packages
USE ieee.numeric_std.ALL;			-- defines numeric types and arithmetic functions for unsigned and signed
USE ieee.math_real.ALL;				-- define common real constants, functions and transcendental functions

--- LIBRARY std;
USE std.standard.ALL;

LIBRARY grlib;                      -- Library of integrated set of reusable IP cores
USE grlib_amba.ALL;				    -- Packages in grlib : viriables defined inside amba.vhd can be utilized
USE grlib_stdlib.ALL;

-- User defined package

-- !!! Syntactic structure !!! --
-- Package declaration
PACKAGE package_name IS
	-- Self defined enumeration type
	TYPE new_type_name IS (enu0, enu1, enu2...);
	-- Self defined constant
	CONSTANT new_const : const_type : const_value;
	-- Self defined function
	FUNCTION new_func(func_parameter : para_type) RETURN return_value_type;
END PACKAGE;
-- Package realization
PACKAGE BODY package_name IS
	-- function details
	FUNCTION new_func(func_parameter : para_type) RETURN  return_value_type IS
	BEGIN
		...
		RETURN ...
	END FUNCTION new_func;
END PACKAGE BODY package_name;
-- !!! Syntactic structure !!! --

-- LIBRARY work;

USE work.fpga_pulse_gen_pkg.ALL; 	-- User defined package

PACKAGE fpga_pulse_gen_pkg IS       -- Below is the content in fpga_pulse_gen_pkg.vhd

-- Number of bits of data signals
    CONSTANT C_DATA_WIDTH         : integer := 32;
-- Width of command of fpga_pulse_gen
	CONSTANT C_COMMAND_WIDTH      : integer := 8;
-- Number of bits of xilinx dds ip core configuration data width
    CONSTANT C_DDS_CONFIG_DATA_WIDTH         : integer := 64;

-- Address for section control
	-- The type of section
	CONSTANT C_SECTION_TYPE 	  : integer := 0;
	-- delay
	CONSTANT C_DELAY 			  : integer := 1;
	-- The wait mux duration
	CONSTANT C_SET_MUX 			  : integer := 2;

-- Derived constants
	SUBTYPE t_pulse_gen_config_data IS unsigned;

	CONSTANT C_SEL_DDS_CH_WIDTH : integer := integer(ceil(log2(real(C_NR_DDS_XILINX))));
	
-- Type deinition for array of configuration data signals
	TYPE t_pulse_gen_config_data_signals IS ARRAY (natural RANGE <>) OF t_pulse_gen_config_data(C_DDS_CONFIG_DATA_WIDTH - 1 DOWNTO 0);
	
-- Type definition for array of control signals	
	TYPE t_pulse_gen_config_valid_signals IS ARRAY (natural RANGE <>) OF unsigned(0 DOWNTO 0);
	
END fpga_pulse_gen_pkg;

PACKAGE BODY fpga_pulse_gen_pkg IS
END fpga_pulse_gen_pkg;

----- End of Part 1 : Library and Package -----



----- Start of Part 2 : Entity -----

-- !!! Syntactic structure !!! --
ENTITY entity_name IS
	PORT (
		port_name: signal_mode signal_type; -- signal_mode: IN, OUT, INOUT, BUFFER
		port_name: signal_mode signal_type;
		...);
END entity_name;
-- !!! Syntactic structure !!! --

ENTITY Coding_Style_VHDL IS
	GENERIC (
		N	    	: positive := 8;		-- input bus width
		CNT_VAL		: positive := 1000 		-- clock counts
	);
	PORT (
		sys_clk 	: IN 	std_logic ; 	-- system clock
		i_start     : IN    std_logic ; 	-- input start bit
		iv_data 	: IN 	std_logic_vector(1 downto 0); 	-- input data vector
		ov_data 	: OUT 	std_logic_vector(1 downto 0); 	-- output data vector
		o_strb      : OUT   std_logic ; 	-- strobe for new data available
END ENTITY Coding_Style_VHDL;

----- End of Part 2 : Entity -----


----- Start of Part 3 ：Architecture -----

-- !!! Syntactic structure !!! --
ARCHITECTURE architecture_name OF entity_name is
	[declarations]
BEGIN
	(code)
END architecture_name;
-- !!! Syntactic structure !!! --

-- Attention: Statements in VHDL are divided into Sequential and Concurrent statements.
--            Logic are divided into combinational and sequential logic. 
-- 			  Sequential statements can realize both sequential and combinational logic.
--			  Concurrent codes are called "Data Flow" codes.
--			  Note: not all circuits with storing components are sequential: like RAM.
--		3.1 Sequential Statements: only statements placed within PROCESS, FUNCTION or PROCEDURE are sequential
--			3.1.1 Process
--				3.1.1.1 Basic Structure without sensitivity list
--              3.1.1.2 Basic Structure with sensitivity list
--			3.1.2 Procedures in process
--		3.2 Concurrent Statements: (different processes are also parallel between each other(circuits))
--			3.2.1 Assignment statement ONLY with AND, NOT, +, *, sll etc. operators
--			3.2.2 WHEN Statement
--          3.3.3 GENERATE Statement
--			3.2.3 GUARDED BLOCK: the only exception to generate synchronized sequential circuit with concurrent statement.

ARCHITECTURE Example_architecture OF Coding_Style_VHDL IS

	-- Constants
	CONSTANT clk_period : time := 10 ns;	-- physical type
	
	-- Signals
	-- 	! Dynamic value transfer medium: 
	--		1) SIGNAL: global (can be declared in PACKAGE, ENTITY or ARCHITECTURE)
	--		2) VARIABLE: local (can be declared in sequential codes, PROCESS, PROCEDURE or FUNCTION)
	SIGNAL 
		en,
		busy,
		data_ready
		: std_logic := '0'; 				-- No signal mode declaration in architecture (only in entity)
	SIGNAL
		dds_phase_offset,
		dds_frequency_offset		
		: unsigned(C_DATA_WIDTH - 1 DOWNTO 0):= (OTHERS => '0');
		
	-- Design under test : component instantiation
	inst_design_1_wrapper : ENTITY work.design_1_wrapper (STRUCTURE) PORT MAP
	(
		clk => clk,
		i_en => i_en,
		iv_set_cycle_repetition_number => iv_set_cycle_repetition_number,
		o_busy => o_busy,
		o_tx_pulse => o_tx_pulse,
		ov_mem_depth => ov_mem_depth,
		ov_nr_dds_ch => ov_nr_dds_ch
	);
	
BEGIN	

--	3.1 Sequential Statements 
--		! Within PROCESS, FUNCTION or PROCEDURE (FUNCTION and PROCEDURE are used for system-level design)

	-- 3.1.1 Processes in architecture
	
	-- !!! Syntactic structure !!! --
	[label_proc:] PROCESS (sensitivity list)
		[/* VARIABLE name: type [range][ : initial_value; ] */]
	BEGIN
		(sequential codes)
	END PROCESS [label_proc];
	-- !!! Syntactic structure !!! --
	
	-- 3.1.1.1 Process without sensitivity list (WAIT statements, not always synthesizeable)
	
	PROCESS		
	BEGIN
		clk <= '1';  -- system reference clock
		WAIT FOR clk_period/2;
		clk <= '0';
		WAIT FOR clk_period/2;
	END PROCESS;
	
	-- 3.1.1.2 process with sensivity list
	
	PROCESS (clk)
		PROCEDURE Load_Command_Prod(
			CONSTANT 
			set_nr_sections,
			set_experiment_repetition_number  
			: IN INTEGER
		) IS
		BEGIN
			-- use wait until rising_edge instead of wait for 1 ms (no exact edge defined) synthesizeable
			-- rising_edge(clk) equal to clk'event AND clk'last_value = '0' AND clk = '1'
			WAIT UNTIL RISING_EDGE (clk);
			iv_set_nr_sections 						<= std_logic_vector(to_unsigned(set_nr_sections, C_DATA_WIDTH));
			iv_set_experiment_repetition_number 	<= std_logic_vector(to_unsigned(set_experiment_repetition_number, C_DATA_WIDTH));
		END Load_Command_Prod;
	BEGIN
		...
	END PROCESS;

--		3.2 Concurrent Statements: WHEN & GENERATE & OPERATIONS

	-- 3.2.1 Operations: conditional signal setting statement (direct signal assignment statement)
	
	muxed <= (a and (not sel)) or (b and sel);	-- one bit multiplexer
	
	y <= (a and not s1 and not s0) or	-- two bits multiplexer, pure logic operations
		 (b and not s1 and s0) or
		 (c and s1 and not s0) or
		 (d and s1 and s0);
	
	-- 3.2.2 WHEN Statement
	
	-- * Three different value description method:
	-- WHEN value						-- single value
	-- WHEN value1 TO value2			-- range, applicable for enumeration type
	-- WHEN value1 | value2 | value3	-- multivalue
	
	-- 3.2.2.1 WHEN/ELSE
	
	-- !!! Syntactic structure !!! --
	assignment WHEN condition ELSE
	assignment WHEN condition ELSE
	...;
	-- !!! Syntactic structure !!! --
	
	-- Example
	
	output <= "000" WHEN (inp = '0' OR reset = '1') ELSE
			  "001" WHEN ctl = '1' ELSE
			  "010";
	
	-- 3.2.2.2 WITH/SELECT/WHEN
	
	-- !!! Syntactic structure !!! --
	WITH identifier SELECT	-- Must consider every condition when using 'WITH/SELECT/WHEN' statement
	assignment WHEN value_,
	assignment WHEN value_,
	...;
	-- !!! Syntactic structure !!! --
	
	-- Example
	
	WITH control SELECT
		output <= "000" WHEN reset,
				  "111" WHEN set,
				  UNAFFECTED WHEN OTHERS;	-- Important! keep same value when control takes other values

	-- 3.2.3 GENERATE Statement		
	-- 		 like LOOP, operate iteratively, usually used with FOR
	--		 ! Upper and lower bounds should be both static

	-- 3.2.3.1 FOR/GENERATE
	
	-- !!! Syntactic structure !!! --
	label1 : FOR identifier IN RANGE GENERATE
		(concurrent assignment)
	END GENERATE;
	-- !!! Syntactic structure !!! --
	
	-- 3.2.3.2 IF/GENERATE (No ELSE statement here!)
	
	label0 : FOR identifier IN RANGE GENERATE
		...
		lable2 : IF condition GENERATE		-- IF/GENERATE nested in FOR/GENERATE
			(concurrent assignment)
		END GENERATE;
		...
	END GENERATE;	
	
	-- Example
	
	SIGNAL x : bit_vector(7 DOWNTO 0);
	SIGNAL y : bit_vector(15 DOWNTO 0);
	SIGNAL z : bit_vector(7 DOWNTO 0);
	...
	G1 : FOR i IN x'RANGE GENERATE
		z(i) <= x(i) and y(i+8);			-- AND operation bitwise
	END GENERATE;

	-- 3.2.4 BLOCK Statement
	--		 
	--		 In most cases statements in block are concurrent.
	--		 ! Label can't be omitted. !
	--       Independent (not calling PACKAGE, COMPONENT, FUNCTION or PROCEDURE).
	--
	--		 Divided into:
	-- 		 - 1) simple BLOCK (without a guard condition a block is a grouping together of concurrent statements
	--		      within an architecture for readability and maintainability)
	--		 - 2) guard BLOCK (with guarded expression, execute only when guarded expression's value is true)
	
	-- 3.2.4.1 Simple BLOCK
	
	-- !!! Syntactic structure !!! --
	ARCHITECTURE Behavioral ...
	BEGIN
		...
		block1 : BLOCK
		BEGIN
			...
		END BLOCK block1;
		...
		block2 : BLOCK
		BEGIN
			...
		END BLOCK block2;
		...
	END Behavioral;
	-- !!! Syntactic structure !!! --
	
	-- Example 1 : simple BLOCK
	
	b1 : BLOCK
		SIGNAL a : std_logic;
	BEGIN
		a <= input_sig WHEN ena = '1' ELSE 'Z';
	END BLOCK b1;
	
	-- Example 2 ：(multiple) component instantiations within a block
	
	CONTROL_LOGIC: BLOCK
	BEGIN
	  U1: CONTROLLER_A
		PORT MAP (CLK,X,Y,Z);
	  U2: CONTROLLER_A
		  PORT MAP (CLK,A,B,C);
	END BLOCK CONTROL_LOGIC;

	DATA_PATH: BLOCK
	BEGIN
	  U3: DATAPATH_A PORT MAP
		(BUS_A,BUS_B,BUS_C,Z);
	  U4: DATAPATH_B PORT MAP
		(BUS_A,BUS_C,BUS_D,C);
	END BLOCK DATA_PATH;

	-- Example 3 : nested blocks
	
	label1 : BLOCK
		[declaration area from top layer]
	BEGIN
		[concurrent description statements from top layer]
		label2 : BLOCK
			[declaration area from nested layer]
		BEGIN
			[concurrent description statements from nested layer]
		END BLOCK label2;
		[other concurrent statements from top layer]
	END BLOCK label1;

	-- 3.2.4.2 Guarded BLOCK
	
	-- !!! Syntactic structure !!! --
	label0 : BLOCK (/* guarded expression */)
		[declarations]
	BEGIN
		(/* guarded statements and other concurrent description statements */)
	END BLOCK label0;
	-- !!! Syntactic structure !!! --

	-- Example 1 (special case) : sequential circuit - transparent latch in guarded block
	
	LIBRARY ieee;
	USE ieee.std_logic_1164.ALL;
	
	ENTITY latch IS
		PORT(
			d, clk : IN std_logic;
			q 	   : OUT std_logic
		);
	END latch;
	
	ARCHITECTURE Behavioral OF latch IS
	BEGIN
		b1 : BLOCK(clk = '1')
		BEGIN
			q <= GUARDED d;
		END BLOCK b1;
	END Behavioral;

	-- Example 2 (special case) : sequential circuit - D Flip-Flop in guarded block
	
	LIBRARY ieee;
	USE ieee.std_logic_1164.ALL;
	
	ENTITY dff IS
		PORT(
			d, clk, rst : IN std_logic;
			q 	   : OUT std_logic
		);
	END dff;
	
	ARCHITECTURE Behavioral OF dff IS
	BEGIN
		b1 : BLOCK(clk = '1' and clk = '1')
		BEGIN
			q <= GUARDED '0' WHEN rst = '1' ELSE d;
		END BLOCK b1;
	END Behavioral;

	/* End of examples */

END Example_architecture;	
	
----- End of Part 3 ：Architectures -----


----- Start of Part 4 ：Common Examples -----

-- 		4.1 IF Statement

	-- !!! Syntactic structure !!! --
	IF conditions THEN assignments;
	ELSIF conditions THEN assignments;
	..
	ELSE assignments;
	END IF;
	-- !!! Syntactic structure !!! --

	-- Example
	
	IF (sel = "00") THEN
		c <= "00000000";
	ELSIF (sel = "01") THEN
		c <= a;
	ELSIF (sel = "10") THEN
		c <= b;
	ELSE
		c <= (OTHERS => 'Z');
	END IF;

--      4.2 WAIT statement (Three types of syntactic structures)

	-- !!! Syntactic structure !!! --
	WAIT UNTIL signal_condition;				-- (1) Wait until condition is satisfied then execute
	WAIT ON signal1[, signal2, ...];			-- (2) Wait on any one of the signals changes then execute
	WAIT FOR time_amount;						-- (3) Wait for specific time then execute, NOT synthesizeable!
	-- !!! Syntactic structure !!! --

	-- Example (1)
	
	PROCESS										-- No sensitivity list, synthesizeable
	BEGIN
		WAIT UNTIL (clk'event and clk = '1')	-- Must be at beginning of process due to absence of sensitivity list
		IF (rst = '1') THEN
			output <= (OTHERS => '0');
		ELSIF (clk'event and clk = '1') THEN	-- Same clock edge detected as wait until statement. Just to synchronize.
			output <= input;
		END IF;
	END PROCESS;
	
	-- Example (2)
	
	PROCESS												-- No sensitivity list, synthesizeable
	BEGIN
		WAIT ON clk, rst;								-- Must be at beginning of process due to absence of sensitivity list
		IF (rst = '1') THEN					
			output <= (OTHERS => '0');
		ELSIF (clk'event and clk = '1') THEN			-- Same clock edge detected as wait until statement. Just to synchronize.
			output <= input;
		END IF;
	END PROCESS;	
	
	-- 4.3 CASE Statement
	-- ! Case allows to execute multiple assignments, while WHEN only allows one.	
	
	-- !!! Syntactic structure !!! --
	CASE statement IS
		WHEN condition expression => Sequential execution statement;
		WHEN condition expression => Sequential execution statement;
		...
	END CASE;
	-- !!! Syntactic structure !!! --		
	
	-- Example
	
	CASE control IS
		WHEN "00" => x <= a; y <= b;
		WHEN "01" => x <= b; y <= c;
		WHEN OTHERS => x <= "0000", y <= "ZZZZ";		-- Important for all other cases
	END CASE;

	-- 4.4 LOOP Statement	
	
	-- !!! Syntactic structure !!! --
	-- 4.4.1 FOR/LOOP
	
	[label_:] FOR loop_variable IN range_of_loop LOOP
		(Sequential description statement)
	END LOOP [label_];

	-- 4.4.2 WHILE/LOOP
	
	[label_:] WHILE condition LOOP
		(Sequential description statement)
	END LOOP [label_];
	
	-- 4.4.3 EXIT: exit whole loop
	
	[label_:] EXIT [label_] [WHEN condition];
	
	-- 4.4.4 NEXT: exit current loop
	
	[label_:] NEXT [label_] [WHEN condition];
	-- !!! Syntactic structure !!! --		
	
	-- Example

	-- 4.4.1 FOR/LOOP
	-- ! Upper and lower bounds must be static.
	
	FOR i IN 0 TO 5 LOOP							-- Execute unconditionally until i equal to 5
		x(i) <= enable AND w(i+2);
		y(0, i) <= w(i);
	END LOOP;

	-- 4.4.2 WHILE/LOOP
	
	WHILE (i<10) LOOP
		WAIT UNTIL clk'event and clk = '1';
		(...)
	END LOOP;
	
	-- 4.4.3 EXIT
		
	FOR i IN 0 TO data'RANGE LOOP
		CASE data(i) IS
			WHEN '0' => count := count + 1;
			WHEN OTHERS => EXIT;					-- Exit whole loop
		END CASE;
	END LOOP;

	-- 4.4.4 NEXT
		
	FOR i IN 0 TO 15 LOOP
		NEXT WHEN i = skip;							-- Jump into next loop
		(...)
	END LOOP;
		
-- 		4. State Machine







----- End of Part 4 ：Common Examples -----