------------------------------------------------------------------------ 
-- Company: University of Stuttgart (IIS)
-- Engineer: Yichao Peng
-- 
-- Create Date: 2022/07/24 16:59:40
-- Design Name: 
-- Module Name: Cheat_Sheet_VHDL - Behavioral
-- Project Name: Cheat sheet for VHDL 
-- Target Devices: 
-- Tool Versions:
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created

-- Additional Comments:

-- These examples shown below illustrate how to write common functional parts in VHDL suggested by CSV.

-- The suggested coding style in VHDL please refer to the other '.vhd' document in this serial.

-- This document provides a cheat sheet for writing: 
-- No.1-No.3 : three basic parts of VHDL codes
-- 1. Library (and Packages inside)
-- 2. Entity
-- 3. Architecture
--		3.1 Sequential statements
--			3.1.1 Process
--				3.1.1.1 Basic Structure without sensitivity list
--              3.1.1.2 Basic Structure with sensitivity list
--			3.1.2 Procedures in process
--		3.2 Concurrent statements
-- 4. Common Examples
-- 		4.1 State Machine
-- 		4.2 IF statement
------------------------------------------------------------------------



----- Start of Part 1 : Library and Package -----

-- three common libraries: ieee, std and work
-- std and work are visible by default and need not be declared

-- ! syntactic structure ! --
LIBRARY library_name;
USE library_name.package_name.package_parts;
-- ! syntactic structure ! --

LIBRARY ieee; 				 		-- Library
USE ieee.std_logic_1164.ALL; 		-- Packages
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

--- LIBRARY std;
USE std.standard.ALL;

LIBRARY grlib;                      -- Library of integrated set of reusable IP cores
USE grlib_amba.ALL;				    -- Packages in grlib : viriables defined inside amba.vhd can be utilized
USE grlib_stdlib.ALL;

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

-- Address for section control
	-- The type of section Tx
	CONSTANT C_STYPE_TX 		  : integer := 0;
	-- The type of section Rx
	CONSTANT C_STYPE_RX 		  : integer := 1;
	-- The type of section Delay
	CONSTANT C_STYPE_DELAY        : integer := 2;

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

-- ! syntactic structure ! --
ENTITY entity_name IS
	PORT (
		port_name: signal_mode signal_type; -- signal_mode: IN, OUT, INOUT, BUFFER
		port_name: signal_mode signal_type;
		...);
END entity_name;
-- ! syntactic structure ! --

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

-- ! syntactic structure ! --
ARCHITECTURE architecture_name OF entity_name is
	[declarations]
BEGIN
	(code)
END architecture_name;
-- ! syntactic structure ! --

-- Attention: Statements in VHDL are divided into Sequential and Concurrent statements.
--            Logic are divided into combinational and sequential logic. 
-- 			  Sequential statements can realize both sequential and combinational logic.
--		3.1 Sequential Statements: only statements placed UNDER Process, Function or Procedure
--			3.1.1 Process
--				3.1.1.1 Basic Structure without sensitivity list
--              3.1.1.2 Basic Structure with sensitivity list
--			3.1.2 Procedures in process
--		3.2 Concurrent Statements: WHEN & GENERATE, basically different processes are also parallel(circuits).
--				   GUARDED BLOCK : the only exception to generate synchronized sequential circuit with concurrent statement.

ARCHITECTURE Behavioral OF Coding_Style_VHDL IS
-- Signals
	SIGNAL 
		en,
		busy,
		data_ready
		: std_logic := '0'; -- No signal mode declaration in architecture (only in entity)
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

--		3.1 Sequential Statements UNDER Process, Function or Procedure

	-- 3.1.1 Processes in architecture

	-- 3.1.1.1 Process without sensitivity list
	
	PROCESS		
	BEGIN
		clk <= '1';  -- system reference clock
		WAIT FOR clk_period/2;
		clk <= '0';
		WAIT FOR clk_period/2;
	END PROCESS;
	
	-- 3.1.1.2 process with sensivity list
	
	PROCESS (clk)
		PROCEDURE Load_Command_Prod
			(
				CONSTANT 
				set_nr_sections,
				set_experiment_repetition_number  
				: IN INTEGER
			) IS
			BEGIN
				-- use wait until rising_edge instead of wait for 1 ms (no exact edge defined) synthesizeable
				-- rising_edge(clk) equal to clk'event AND clk'last_value = '0' AND clk = '1'
				WAIT UNTIL RISING_EDGE (clk);
				iv_set_nr_sections 						<= std_logic_vector (to_unsigned (set_nr_sections, C_DATA_WIDTH));
				iv_set_experiment_repetition_number 	<= std_logic_vector (to_unsigned (set_experiment_repetition_number, C_DATA_WIDTH));
			END Load_Command_Prod;
	
END Behavioral;

--		3.2 Concurrent Statements: WHEN & GENERATE & OPERATIONS

	-- 3.2.1 Operations: conditional signal setting statement (direct signal assignment statement)
	
	muxed <= (a AND (NOT sel)) OR (b AND sel);	-- one bit multiplexer
	
	y <= (a AND NOT s1 AND NOT s0) OR	-- two bits multiplexer, pure logic operations
		 (b AND NOT s1 AND s0) OR
		 (c AND s1 AND NOT s0) OR
		 (d AND s1 AND s0);
	
	-- 3.2.2 WHEN Statement
	
	-- * 3 value description method:
	-- WHEN value						-- single value
	-- WHEN value1 TO value2			-- range, applicable for enumeration type
	-- WHEN value1 | value2 | value3	-- multivalue
	
	-- 3.2.2.1 WHEN/ELSE
	
	assignment WHEN condition ELSE
	assignment WHEN condition ELSE
	...;
	
	-- example
	
	output <= "000" WHEN (inp = '0' OR reset = '1') ELSE
			  "001" WHEN ctl = '1' ELSE
			  "010";
	
	-- 3.2.2.2 WITH/SELECT/WHEN
	
	WITH identifier SELECT	-- must consider every condition when using 'WITH/SELECT/WHEN' statement
	assignment WHEN value_,
	assignment WHEN value_,
	...;
	
	-- example
	
	WITH control SELECT
		output <= "000" WHEN reset,
				  "111" WHEN set,
				  UNAFFECTED WHEN OTHERS;	-- very important! keep same value when control takes other values

	-- 3.2.3 GENERATE Statement

	-- 3.2.3.1 FOR/GENERATE
	
	label0 : FOR identifier IN RANGE GENERATE
		(concurrent assignment)
	END GENERATE;
	
	-- 3.2.3.2 IF/GENERATE
	
	label0 : FOR identifier IN RANGE GENERATE
		(concurrent assignment)
	END GENERATE;	
	
	
	
	
----- End of Part 3 ：Architectures -----


----- Start of Part 4 ：Common Examples -----

-- 		4.1 State Machine


-- 		4.2 IF Statement

	IF (sel = "00") THEN
		c <= "00000000";
	ELSIF (sel = "01") THEN
		c <= a;
	ELSIF (sel = "10") THEN
		c <= b;
	ELSE
		c <= (OTHERS => 'Z');
	END IF;




----- End of Part 4 ：Common Examples -----