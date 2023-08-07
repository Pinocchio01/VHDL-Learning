----------------------------------------------------------------------------------
-- Title: testbench of conv
--
-- Company: IIS, University of Stuttgart
--
-- Author: Yichao Peng
--
-- Project Name: Image processing on Zynq
--
-- Target Devices:
-- Tool Versions:
-- Description: Convolutional computation unit.
-- 
-- Dependencies: Entity conv.
-- 
-- History:
-- 	Version 0.1  Create file, Yichao Peng, 2022/7/23 23:54
-- 
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.math_real.ALL;

ENTITY tb_conv IS
--  Port ( );
END tb_conv;

ARCHITECTURE Behavioral OF tb_conv IS
	
	-- constants
	CONSTANT clk_period   		: time    := 10 ns;
	CONSTANT C_i_width  		: integer := 72; 		-- input width in bits
	CONSTANT C_o_width 			: integer := 8; 		-- output width in bits
	CONSTANT C_kernel_size	 	: integer := 3; 		-- kernel size
	
	-- type for procedure input
	TYPE int_vector IS ARRAY(C_kernel_size * C_kernel_size - 1 DOWNTO 0) OF integer;
	
	-- signals
	SIGNAL
	clk,
	rstn, 											-- synchronous reset, active high
	i_pixel_data_valid,
	o_convolved_data_valid
	: std_logic := '0';
	SIGNAL i_pixel_data : std_logic_vector(C_i_width-1 DOWNTO 0) := (OTHERS => '0'); -- all gray value in a kernel
	SIGNAL o_convolved_data : std_logic_vector(C_o_width-1 DOWNTO 0) := (OTHERS => '0'); -- convolved data for current pixel
	
BEGIN

	-- component instatiation
	inst_conv : ENTITY work.conv
	GENERIC MAP(
		i_width   		=> 	C_i_width,
		o_width   		=> 	C_o_width,
		kernel_size		=> 	C_kernel_size
	)
	PORT MAP(
		i_clk 					=> 	clk,
		i_rstn   				=> 	rstn,
		i_pixel_data 			=> 	i_pixel_data,
		i_pixel_data_valid 		=> 	i_pixel_data_valid,
		o_convolved_data 		=> 	o_convolved_data,
		o_convolved_data_valid 	=> 	o_convolved_data_valid
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
			CONSTANT C_rstn : IN std_logic;
			CONSTANT C_i_pixel_data_valid : IN std_logic;
			CONSTANT C_i_pixel_data : IN int_vector
		) IS
		
		BEGIN
			WAIT UNTIL rising_edge(clk);
			rstn <= C_rstn;
			i_pixel_data_valid <= C_i_pixel_data_valid;
			FOR i IN C_i_pixel_data'RANGE LOOP
				i_pixel_data(i*C_o_width+7 DOWNTO i*C_o_width) <= std_logic_vector(to_unsigned(C_i_pixel_data(i), C_o_width));
			END LOOP;
		END Load_Data_Prod;
		
	BEGIN
		WAIT UNTIL rising_edge(clk);
		
		Load_Data_Prod				-- reset active
		(
			'0', 					-- rstn
			'0',					-- valid
			(1,1,1,1,1,1,1,1,1)		-- input
		);
		
		WAIT FOR 5 * clk_period;
		Load_Data_Prod				-- reset inactive
		(
			'1', 					-- rstn
			'1',					-- valid
			(1,1,1,1,1,1,1,1,1)		-- input
		);
		
		WAIT FOR 5 * clk_period;
		Load_Data_Prod				-- reset inactive
		(
			'1', 					-- rstn
			'1',					-- valid
			(2,2,2,2,2,2,2,2,2)		-- input
		);
		
		WAIT FOR 5 * clk_period;
		Load_Data_Prod
		(
			'1', 					-- rstn
			'1',					-- valid
			(1,2,3,4,5,6,7,8,9)		-- input
		);

		WAIT FOR 5 * clk_period;
		Load_Data_Prod
		(
			'1', 					-- rstn
			'1',					-- valid
			(1,1,1,1,1,1,1,1,255)		-- input
		);
		
		WAIT FOR 5 * clk_period;    -- invalid check
		Load_Data_Prod
		(
			'1', 					-- rstn
			'0',					-- valid
			(1,2,3,4,5,6,7,8,9)		-- input
		);		
		
		-- reset
		WAIT FOR 100 * clk_period;
		rstn <= '0';
		
		-- assert false
		WAIT FOR 100 * clk_period;
		ASSERT false
		REPORT "Simulation finished"
		SEVERITY failure;
		
	END PROCESS;
	
END Behavioral;