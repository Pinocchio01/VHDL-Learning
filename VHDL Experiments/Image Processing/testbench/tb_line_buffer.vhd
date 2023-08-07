----------------------------------------------------------------------------------
-- Title: testbench of line_buffer
--
-- Company: IIS, University of Stuttgart
--
-- Author: Yichao Peng
--
-- Project Name: Image processing on Zynq
--
-- Target Devices: 
-- Tool Versions: 
-- Description: Line buffer to store one line pixel of image, each pixel a byte.
-- 
-- Dependencies:
-- 
-- History:
-- 	Version 0.1  Create file, Yichao Peng, 2022/7/21 11:34
-- 
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.math_real.ALL;

ENTITY tb_line_buffer IS
--  Port ( );
END tb_line_buffer;

ARCHITECTURE Behavioral OF tb_line_buffer IS

	-- constants
	CONSTANT clk_period   	: time    := 10 ns;
	CONSTANT C_i_width  	: integer := 8; 		-- input width in bits
	CONSTANT C_o_width 		: integer := 24; 		-- output width in bits, multiple of i_width
	CONSTANT C_ram_depth 	: integer := 512; 		-- memory depth
	
	-- signals
	SIGNAL
	clk,
	rstn, 											-- synchronous reset, active high
	i_data_valid,
	i_rd_data_flag
	: std_logic := '0';
	SIGNAL i_pixel_data   	: std_logic_vector(C_i_width-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL o_data           : std_logic_vector(C_o_width-1 DOWNTO 0) := (OTHERS => '0');
	
BEGIN

	-- component instatiation
	inst_line_buffer : ENTITY work.line_buffer
	GENERIC MAP(
		i_width   		=> 	C_i_width,
		o_width   		=> 	C_o_width,
		ram_depth 		=> 	C_ram_depth
	)
	PORT MAP(
		i_clk 			=> 	clk,
		i_rstn   		=> 	rstn,
		i_pixel_data 	=> 	i_pixel_data,
		i_data_valid 	=> 	i_data_valid,
		i_rd_data_flag 	=> 	i_rd_data_flag,
		o_data 			=> 	o_data
	);
	
	-- processes
	clk_proc: PROCESS
	BEGIN
		WAIT FOR clk_period/2;
		clk <= '1';
		WAIT FOR clk_period/2;
		clk <= '0';
	END PROCESS;
	
	input_process: PROCESS
		-- procedure definition
		PROCEDURE Load_Data_Prod
		(
			CONSTANT
			C_rstn,
			C_i_data_valid,
			C_i_rd_data_flag
			: IN std_logic;
			CONSTANT
			C_i_pixel_data
			: IN integer
		) IS
		BEGIN
			WAIT UNTIL rising_edge(clk);
			rstn 			<= C_rstn;
			i_data_valid 	<= C_i_data_valid;
			i_rd_data_flag 	<= C_i_rd_data_flag;
			i_pixel_data 	<= std_logic_vector(to_unsigned(C_i_pixel_data, C_i_width));
		END Load_Data_Prod;
	BEGIN
		WAIT UNTIL rising_edge(clk);
		Load_Data_Prod				-- reset active, all initial state
		(
			'0', 	-- rstn
			'0',	-- valid
			'0',  	-- rd
			1		-- input
		);
		Load_Data_Prod				-- write 1 to firstn memory cell address, no read-out(rdPntr remains sames)
		(
			'1', 	-- rstn
			'1',	-- valid
			'0',  	-- rd
			1		-- input
		);
		Load_Data_Prod				-- write 2 to second memory cell address, no read-out(rdPntr remains sames)
		(
			'1', 	-- rstn
			'1',	-- valid
			'0',  	-- rd
			2		-- input
		);
		Load_Data_Prod				-- write 3 to third memory cell address
		(
			'1', 	-- rstn
			'1',	-- valid
			'0',  	-- rd
			3		-- input
		);
		Load_Data_Prod				-- write 4 to fourth memory cell address, read out
		(							-- read address should be 0, should have valid read-out value (firstn three pixels/cells)
			'1', 	-- rstn
			'1',	-- valid
			'1',  	-- rd
			4		-- input
		);
		Load_Data_Prod				-- write 5 to fifth memory cell address, read out
		(							-- read address should be 1, should have valid read-out value
			'1', 	-- rstn
			'1',	-- valid
			'1',  	-- rd
			5		-- input
		);
		WAIT FOR 10 * clk_period;
		rstn <= '1'; -- reset all address pointers
		WAIT FOR 100 * clk_period;
		ASSERT false
		REPORT "Simulation finished"
		SEVERITY failure;
	END PROCESS;
END Behavioral;