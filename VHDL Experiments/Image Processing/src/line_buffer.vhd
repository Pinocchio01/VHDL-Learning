----------------------------------------------------------------------------------
-- Title: Entity line_buffer
--
-- Company: IIS, University of Stuttgart
--
-- Author: Yichao Peng
--
-- Project Name: Image Processing on Zynq
--
-- Target Devices: 
-- Tool Versions: 
-- Description: Universal line buffer, same structure of RAM.
--              Can't use FIFO in image neighbourhood processing because for convolution we need to access data more times.
-- 
-- Dependencies:
-- 
-- History:
-- 	Version 0.1 Create file, Yichao Peng, 2023/07/20 10:30
--  Version 0.2 Modify file, Yichao Peng, 2023/07/30 22:00 Reduce delay in output.
--  
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.math_real.ALL;

ENTITY line_buffer IS
	GENERIC(
		i_width   : integer := 8;	-- input width: one byte for each pixel
		o_width   : integer := 24;	-- output width to conv
		ram_depth : integer := 512	-- image width (how many pixels in a line)
	);
	PORT(															-- memory is always ready to receive data, so no ready signal required
		i_clk   		: IN std_logic;
		i_rstn   		: IN std_logic; 							-- synchronous reset, active low
		i_pixel_data 	: IN std_logic_vector(i_width-1 DOWNTO 0); 	-- a pixel one byte for grey value
		i_data_valid	: IN std_logic;								-- whether input data is valid
		i_rd_data_flag	: IN std_logic; 							-- if '1', read pointer jump to next, else read address not change
		o_data  		: OUT std_logic_vector(o_width-1 DOWNTO 0) 	-- read out 3 pixels a time for kernel size 3
	);
END ENTITY;

ARCHITECTURE Behavioral OF line_buffer IS
	TYPE lineBuffer IS ARRAY(ram_depth-1 DOWNTO 0) OF std_logic_vector(i_width-1 DOWNTO 0); -- self define array type to store 512 * 8 bytes vector
	SIGNAL single_line : lineBuffer;
	SIGNAL 
	wrPntr, -- 2^9 = 512, memory write address pointer
	rdPntr : std_logic_vector(integer(log2(real(ram_depth)))-1 DOWNTO 0) := (OTHERS => '0'); -- memory read pointer
BEGIN

	wr_proc : PROCESS(i_clk)			-- control write behaviour: if valid, write input data to current position
	BEGIN
		IF rising_edge(i_clk) THEN
			IF (i_data_valid = '1') THEN
				single_line(to_integer(unsigned(wrPntr))) <= i_pixel_data;
			END IF;
		END IF;
	END PROCESS;
	
	wrPntr_proc : PROCESS(i_clk)		-- control write position
	BEGIN
		IF rising_edge(i_clk) THEN
			IF (i_rstn = '0') THEN
				wrPntr <= (OTHERS => '0');
			ELSIF (i_data_valid = '1') THEN
				wrPntr <= wrPntr + '1';
			END IF;
		END IF;
	END PROCESS;
	
	-- rd_proc : PROCESS(i_clk)			-- control read behaviour
	-- BEGIN
		-- IF rising_edge(i_clk) THEN
			-- o_data <= single_line(to_integer(unsigned(rdPntr))) & single_line(to_integer(unsigned(rdPntr + 1))) & single_line(to_integer(unsigned(rdPntr + 2)));
		-- END IF;
	-- END PROCESS;
	
	-- combinational logic for pre-fetch (even if read flag inactive)
	-- control read behaviour, if waiting for rising edge of clk, one more read latency
	o_data <= single_line(to_integer(unsigned(rdPntr))) & single_line(to_integer(unsigned(rdPntr + 1))) & single_line(to_integer(unsigned(rdPntr + 2)));

	rdPntr_proc: PROCESS(i_clk)		-- control read position
	BEGIN
		IF rising_edge(i_clk) THEN
			IF (i_rstn = '0') THEN
				rdPntr <= (OTHERS => '0');
			ELSIF (i_rd_data_flag = '1') THEN	-- increase read pointer only if read flag high
				rdPntr <= rdPntr + '1';			-- Xilinx IP core will increase output size each time, here adjustable
			END IF;
		END IF;
	END PROCESS;

END Behavioral;