----------------------------------------------------------------------------------
-- Title: Entity conv
--
-- Company: IIS, University of Stuttgart
--
-- Author: Yichao Peng
--
-- Project Name: Image Processing on Zynq
--
-- Target Devices: 
-- Tool Versions: 
-- Description: A convolution (multiplication + addition) calculator
-- 				with n*n (all ones/ others) kernel for picture smoothing/enhance/...
-- 				here use smooth kernel as example.
--
-- Dependencies: 
-- 
-- History:
-- 	Version 0.1 Create file, Yichao Peng, 2023/07/21 21:11
--  Version 0.2 Modify file, Yichao Peng, 2023/07/30 22:09 
--				Change kernel_length into kernel_size
--	Version 0.3 Modify file, Yichao Peng, 2023/08/03 22:34
--
--				Change valid signals
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

ENTITY conv IS

	GENERIC(
		i_width   		: integer := 72;
		o_width  		: integer := 8;
		kernel_size 	: integer := 3
	);
	
	PORT(
		i_clk   				: IN std_logic;
		i_rstn   				: IN std_logic; 							-- synchronous reset, active low
		i_pixel_data			: IN std_logic_vector(i_width-1 DOWNTO 0); 	-- all gray value in a kernel
		i_pixel_data_valid		: IN std_logic;
		o_convolved_data  		: OUT std_logic_vector(o_width-1 DOWNTO 0);
		o_convolved_data_valid	: OUT std_logic		
	);
	
END ENTITY;

ARCHITECTURE Behavioral OF conv IS
	
	-- kernel definition
	TYPE conv_kernel_type IS ARRAY(kernel_size * kernel_size - 1 DOWNTO 0) OF std_logic_vector(o_width-1 DOWNTO 0); 	-- self define array type to store 512 * 8 bytes vector
	CONSTANT kernel : conv_kernel_type := (OTHERS => (0 => '1', OTHERS => '0'));										-- use aggregation to initialize the array

	-- intermediate results
	TYPE multi_result_type IS ARRAY(kernel_size * kernel_size - 1 DOWNTO 0) OF std_logic_vector(2*o_width-1 DOWNTO 0);
	SIGNAL multData : multi_result_type := (OTHERS => (OTHERS => '0')); 												-- store the multiplication result each kernel pixel	

	CONSTANT sumData_width : integer := 2*o_width + integer(log2(real(kernel_size * kernel_size))) + 1; 				-- log2 round to 0
	SIGNAL sumData : std_logic_vector(sumData_width-1 DOWNTO 0) := (OTHERS => '0');										-- intermediate sum

	-- intermediate valid signals
	SIGNAL	multi_data_valid : std_logic := '0';
	SIGNAL	sum_data_valid 	 : std_logic := '0';
	
BEGIN
	
	-- Attention: using multi-process pipeline to reduce calculation time
	-- Delay: 3 clock periods (due to 3 pipeline elements)
	-- Don't assign value to signal in multiple processes!
	
	multi_proc : PROCESS(i_clk)		-- matrix point multipication
		VARIABLE multDataSingle : integer := 0;
		VARIABLE multDataInt : multi_result_type := (OTHERS => (OTHERS => '0'));	-- intermediate variable
	BEGIN
		IF rising_edge(i_clk) THEN
			IF i_rstn = '0' THEN
				multDataSingle := 0;
				multDataInt := (OTHERS => (OTHERS => '0'));
				multi_data_valid <= '0';
			ELSE
				FOR i IN 0 TO kernel_size * kernel_size - 1 LOOP -- or 'reverse_range
					multDataSingle := to_integer(unsigned(kernel(i))) * to_integer(unsigned(i_pixel_data(i*o_width + o_width - 1 DOWNTO i*o_width)));
					multDataInt(i) := std_logic_vector(to_unsigned(multDataSingle, 2*o_width));
				END LOOP;
				multData <= multDataInt;
				multi_data_valid <= i_pixel_data_valid;
			END IF;
		END IF;
	END PROCESS;
	
	add_proc : PROCESS(i_clk)		-- addition
		VARIABLE sumDataInt : std_logic_vector(sumData_width-1 DOWNTO 0) := (OTHERS => '0');
	BEGIN
		IF rising_edge(i_clk) THEN
			IF i_rstn = '0' THEN
				sumDataInt := (OTHERS => '0');
				sum_data_valid <= '0';
			ELSE
				sumDataInt := (OTHERS => '0'); 	-- variable must be explicitly assigned or will have value from last process
				FOR i IN multData'RANGE LOOP
					sumDataInt := sumDataInt + std_logic_vector(resize(unsigned(multData(i)),sumData_width));
				END LOOP;
				sumData <= sumDataInt;
				sum_data_valid <= multi_data_valid;
			END IF;
		END IF;
	END PROCESS;

	div_proc : PROCESS(i_clk)
	BEGIN
		IF rising_edge(i_clk) THEN
			IF i_rstn = '0' THEN
				o_convolved_data <= (OTHERS => '0');
				o_convolved_data_valid <= '0';
			ELSE
				o_convolved_data <= std_logic_vector(resize(unsigned(sumData)/9,o_width)); -- only reserve integer part, and then truncation
				o_convolved_data_valid <= sum_data_valid;
			END IF;
		END IF;
	END PROCESS;
	
END Behavioral;