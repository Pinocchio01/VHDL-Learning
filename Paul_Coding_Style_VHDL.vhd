------------------------------------------------------------------------ Company: university of stuttgart (IIS)
-- Engineer: Yichao Peng
-- 
-- Create Date: 2022/07/24 16:59:40
-- Design Name: 
-- Module Name: Coding_Style_VHDL - Behavioral
-- Project Name: Coding style and cheat sheet for VHDL 
-- Target Devices: 
-- Tool Versions:
-- Description: * means annotations for important content or format.
--              No difference between Uppercase and lowercase in VHDL.
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created

-- Additional Comments:

-- These examples shown below illustrate the formatting enforced by CSV (this document). 
-- The examples of different parts are just to show coding style, not coherent and not executable.

-- A cheat sheet for common statements in VHDL please refer to the other '.vhd' document in this serial.

-- They show a subset of the rules used in VHDL coding:
-- 1. Capitalization & Uppercase
--	  1.1 	Reserved keywords uppercase
--	  1.2 	Operator and Attribute uppercase
--    1.3 	'X','Z' MUST in uppercase
--	  1.4 	Data type lowercase
-- 2. Indentation:
--    2.1 	Space before left bracket, unless it is index in the bracket.
-- 3. Column alignments:
-- 	  3.1 	comments
--	  3.2 	's
--    3.3 	assignment operators (<= and =>)
-- 4. Vertical spacing

------------------------------------------------------------------------

-- Library and Package

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;

-- Entity 1

ENTITY mux2to1 IS
	GENERIC (
		N 			: positive := 8;		-- input bus width
		clk_period  : time	   := 10 ns 	-- clock period : 100 MHz
	);
	PORT (
		-- * port_name: signal_mode signal_type;
		-- 4 signal modes: IN, OUT(single-direction, can't be read), INOUT(double-direction) or BUFFER(out, but can be read for internal circuit use)
		-- signal type: bit, std_logic, integer etc.
		sys_clk		: IN std_logic;			-- system clock
		i_a 		: IN std_logic;			-- input data bit a
		i_b 		: IN std_logic;			-- input data bit b
		iv_c		: IN std_logic_vector;	-- input data vector c
		i_sel		: IN std_logic;			-- input select bit
		o_muxed		：OUT std_logic;		-- output bit of multiplexer
		ov_d		: OUT std_logic_vector	-- output data vector d
	);
END mux2to1;

-- Architecture

ARCHITECTURE Behavioral OF mux2to1 IS

	-- User Defined Type (optional)
	
	TYPE state_type IS(
		idle_state, reset_s, count_repitition,
		start_polling, ack_txinfo_rxd, tx_int_info_priority
	);
	TYPE prior_table IS ARRAY(0 to 7) OF unsigned(2 DOWNTO 0);

	-- Signal Declarations (optional)
	
	SIGNAL 
		next_s,
		current_s
		: state_type := reset_s;
	SIGNAL int_type_0	 := unsigned(1 DOWNTO 0) := "01";
	SIGNAL int_type_1	 := unsigned(0 TO 1)	 := (OTHERS => '0')
	SIGNAL pt			 := prior_table := (OTHERS => (OTHERS => '0'));
	SIGNAL
		flag,
		flag1
		: std_logic := '0';
	
BEGIN

	muxed <= (a AND (NOT sel)) OR (b AND sel);
	
	-- if sel = 0 choose a, else choose b
	
END Behavioral;

-- Entity 2

ENTITY mux4to1 IS
	PORT (
		iv_a 	: IN std_logic_vector(3 DOWNTO 0);
		iv_sel	: IN std_logic_vector(1 DOWNTO 0);
		o_muxed	：OUT std_logic
	);
END mux4to1;

ARCHITECTURE Behavioral OF mux4to1 IS
	
	-- Signal Declarations
	
	SIGNAL muxed_if : std_logic_vector(1 downto 0);
	
	-- Component Declarations
	
	COMPONENT mux2to1
		GENERIC (
			N 			: positive := 8;		-- input bus width
			clk_period  : time	   := 10 ns 	-- clock period : 100 MHz
		);
		PORT (
			iv_a 	: IN std_logic_vector(3 DOWNTO 0);
			iv_sel	: IN std_logic_vector(1 DOWNTO 0);
			o_muxed	：IN std_logic
		);
	END COMPONENT;
	
BEGIN
	
	-- Component Instantiations
	
	inst_mux2to1_1downto0 : mux2to1
		GENERIC MAP (
			DELAY 	=> TRE_LEN_1 + TRE_LEN_2 + delay,
			CNT   	=> 0
		)	-- * No ; between GENERIC MAP and PORT MAP !!!
		PORT MAP (
			a 		=> iv_a(0),
			b 		=> iv_a(1),
			sel		=> sel(0),
			muxed 	=> muxed_if(0)
		);
	
	inst_mux2to1_3downto2 : mux2to1
		PORT MAP (
			a 		=> iv_a(2),
			b 		=> iv_a(3),
			sel 	=> sel(0),
			muxed 	=> muxed_if(1)
		);
	
	inst_mux2to1_final : mux2to1
		PORT MAP (
			a 		=> muxed_if(0),
			b 		=> muxed_if(1),
			sel 	=> sel(1),
			muxed 	=> o_muxed
		);
	
	-- mux result:	
		-- if    sel = "00" choose a
		-- elsif sel = "01" choose b
		-- if    sel = "10" choose c
		-- elsif sel = "11" choose d
	
	-- Process 1
	
	and_or : PROCESS (a,b,d,e)
		-- declarative part: empty
	BEGIN
		g <= (a AND b) OR (d AND e);
	END PROCESS and_or;
	
	-- Process 2
	
	PROCESS
	
		-- procedure declaration
	    PROCEDURE Load_Data_Prod
        (
			CONSTANT write_sel_section  : IN INTEGER;
			CONSTANT set_section_type   : IN INTEGER;
			CONSTANT set_frequency_ch0  : IN std_logic_vector(C_DATA_WIDTH - 1 downto 0);
			CONSTANT set_frequency_ch1  : IN std_logic_vector(C_DATA_WIDTH - 1 downto 0);
			CONSTANT set_resetn_dds		: IN INTEGER
        ) IS
        BEGIN
            -- WAIT UNTIL rising_edge(clk);     -- use wait until rising_edge instead of wait for 1 ms (not exact edge defined)
			-- choose write (and read section)
			WAIT UNTIL rising_edge (clk);
			iv_write_sel_section  	 				<= std_logic_vector(to_unsigned(write_sel_section, C_DATA_WIDTH));
			iv_set_section_type 	 				<= std_logic_vector(to_unsigned(set_section_type, C_DATA_WIDTH));
			iv_set_frequency_ch0 	 				<= set_frequency_ch0;
			iv_set_frequency_ch1 	 				<= set_frequency_ch1;
			iv_set_resetn_dds						<= std_logic_vector(to_unsigned(set_resetn_dds,C_DATA_WIDTH));	
        END Load_Data_Prod;	
	
	BEGIN
	
		i_en <= '0';
		
		Load_Data_Prod	-- call procedure
		(
			12,	 	-- iv_set_nr_sections: 0-11
			4, 		-- iv_set_start_repeat_pointer
			9, 		-- iv_set_end_repeat_pointer
			10, 	-- iv_set_cycle_repetition_number
			2  		-- iv_set_experiment_repetition_number
		);

		WAIT FOR 5 * clk_period;
		WAIT UNTIL rising_edge (clk);
		
		Load_Data_Prod	-- call procedure
		(
			12,	 	-- iv_set_nr_sections: 0-11
			5, 		-- iv_set_start_repeat_pointer
			8, 		-- iv_set_end_repeat_pointer
			5, 	-- iv_set_cycle_repetition_number
			1  		-- iv_set_experiment_repetition_number
		);
	
		WAIT FOR 25000 * clk_period;	-- simulation duration

		ASSERT false	-- used in testbench environment: allow simulation to terminate after finish
		REPORT "Simulation finished"
		SEVERITY failure;

	END PROCESS;
	
END Behavioral;