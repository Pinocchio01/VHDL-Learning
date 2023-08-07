----------------------------------------------------------------------------------
-- Title: Entity image_cu
--
-- Company: IIS, University of Stuttgart
--
-- Author: Yichao Peng
--
-- Project Name: Image processing on Zynq
--
-- Target Devices: 
-- Tool Versions: 
-- Description: Control unit of image processing IP core. Move input data into line_buffer to combine and transfer to conv.
-- 				Coordinate between line buffers and conv.
--				Consists of two multiplexers and a FSM: one multiplexer controlling to which buffer to write new data (wrLineBuffer_pointer),
--				the other choosing the data from which three line buffers to form the output (rdLineBuffer_pointer). FSM to control whether to read or not.
--				
-- Dependencies: Entity line_buffer
-- 
-- History:
-- 	Version 0.1 Create file, Yichao Peng, 2023/7/24 21:46
--  Version 0.2 Modify file, Yichao Peng, 2023/7/30 22:58
--              Change rd_buffer_flag_proc process into combinational logic. 
--  			rd_line_buffer_flag to decide whether to increase rdLineBuffer_pointer, instead of LineBuffer_rd_valid_v
-- 
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY image_cu IS
	GENERIC(
		kernel_size : integer := 3;     -- kernel size
		i_width   	: integer := 8;		-- read pixel data into line buffer
		o_width   	: integer := 72;	-- output data to conv
		ram_depth 	: integer := 512    -- width of line buffer (number of columns)
	);
	PORT(
		i_clk   					: IN std_logic;
		i_rstn   					: IN std_logic; 							 -- synchronous reset, active low
		i_pixel_data				: IN std_logic_vector(i_width-1 DOWNTO 0); 	
		i_pixel_data_valid			: IN std_logic;								 -- assign to each line buffer
		o_pixel_data  				: OUT std_logic_vector(o_width-1 DOWNTO 0);  -- all gray value in a kernel
		o_pixel_data_valid			: OUT std_logic;							 -- valid until >= 3*512 pixels are stored in buffers 
		o_intr						: OUT std_logic								 -- interrupt signal to PS to get one more line
	);
END ENTITY;

ARCHITECTURE Behavioral OF image_cu IS
	
	-- state machine type definition
	
	TYPE StateType IS (IDLE, RD_BUFFER);  -- enumeration type for FSM
	SIGNAL rdState : StateType := IDLE;
	
	-- signal definition
	
	SIGNAL rd_line_buffer_flag  	: std_logic 				   	:= '0';					-- whether to read out
	SIGNAL total_wr_pixel_counter	: std_logic_vector(11 DOWNTO 0)	:= (OTHERS => '0');     -- total number of stored and not read data, larger than 3 * 512 - 1, start reading data, max 4 * 512 - 1. (rd_line_buffer_flag = '1')
	SIGNAL wr_pixel_counter 		: std_logic_vector(8 DOWNTO 0) 	:= (OTHERS => '0');  	-- if count to 511, switch to next line to write more pixel data (2^9 = 512)
	SIGNAL rd_pixel_counter 		: std_logic_vector(8 DOWNTO 0) 	:= (OTHERS => '0');  	-- if count to 511, switch to next line to read more pixel data
	
	-- here not use integer, because if exceed won't automatically change to "000000000" but will cause compilation error
	
	SIGNAL wrLineBuffer_pointer 	: std_logic_vector(1 DOWNTO 0) 	:= (OTHERS => '0');  	-- write from: 4 buffers in total
	SIGNAL LineBuffer_wr_valid_v 	: std_logic_vector(3 DOWNTO 0) 	:= (OTHERS => '0');  	-- one bit for one buffer, one hot, according to wrLineBuffer_pointer
	SIGNAL rdLineBuffer_pointer 	: std_logic_vector(1 DOWNTO 0) 	:= (OTHERS => '0');  	-- read from: 4 buffers in total
	SIGNAL LineBuffer_rd_valid_v    : std_logic_vector(3 DOWNTO 0) 	:= (OTHERS => '0');     -- if '1' read out, else not; one hot, for 4 line buffers
	
	-- line buffer read out data, concatenate to form output
	
	SIGNAL lb0_rd_data 				: std_logic_vector(i_width*kernel_size-1 DOWNTO 0) := (OTHERS => '0'); 	-- read out data from line buffer 0
	SIGNAL lb1_rd_data 				: std_logic_vector(i_width*kernel_size-1 DOWNTO 0) := (OTHERS => '0'); 	-- read out data from line buffer 1
	SIGNAL lb2_rd_data 				: std_logic_vector(i_width*kernel_size-1 DOWNTO 0) := (OTHERS => '0'); 	-- read out data from line buffer 2
	SIGNAL lb3_rd_data 				: std_logic_vector(i_width*kernel_size-1 DOWNTO 0) := (OTHERS => '0'); 	-- read out data from line buffer 3
	
BEGIN

	-- instantiate 4 line buffers, three for kernel and one for pre-loading
	
	inst_line_buffer_0 : ENTITY work.line_buffer
	GENERIC MAP(
		i_width   => i_width,
		o_width   => kernel_size * i_width,
		ram_depth => ram_depth
	)
	PORT MAP(
		i_clk   		=> i_clk,
		i_rstn   		=> i_rstn,
		i_pixel_data  	=> i_pixel_data,  		
		i_data_valid	=> LineBuffer_wr_valid_v(0),	-- control which line buffer to store current pixel
		i_rd_data_flag	=> LineBuffer_rd_valid_v(0),
		o_data  		=> lb0_rd_data
	);
	
	inst_line_buffer_1 : ENTITY work.line_buffer
	GENERIC MAP(
		i_width   => i_width,
		o_width   => kernel_size * i_width,
		ram_depth => ram_depth
	)
	PORT MAP(
		i_clk   		=> i_clk,
		i_rstn   		=> i_rstn,
		i_pixel_data  	=> i_pixel_data,  		
		i_data_valid	=> LineBuffer_wr_valid_v(1),	-- control which line buffer to store current pixel
		i_rd_data_flag	=> LineBuffer_rd_valid_v(1),
		o_data  		=> lb1_rd_data
	);

	inst_line_buffer_2 : ENTITY work.line_buffer
	GENERIC MAP(
		i_width   => i_width,
		o_width   => kernel_size * i_width,
		ram_depth => ram_depth
	)
	PORT MAP(
		i_clk   		=> i_clk,
		i_rstn   		=> i_rstn,
		i_pixel_data  	=> i_pixel_data,  		
		i_data_valid	=> LineBuffer_wr_valid_v(2),	-- control which line buffer to store current pixel
		i_rd_data_flag	=> LineBuffer_rd_valid_v(2),
		o_data  		=> lb2_rd_data
	);

	inst_line_buffer_3 : ENTITY work.line_buffer
	GENERIC MAP(
		i_width   => i_width,
		o_width   => kernel_size * i_width,
		ram_depth => ram_depth
	)
	PORT MAP(
		i_clk   		=> i_clk,
		i_rstn   		=> i_rstn,
		i_pixel_data  	=> i_pixel_data,  		
		i_data_valid	=> LineBuffer_wr_valid_v(3),	-- control which line buffer to store current pixel
		i_rd_data_flag	=> LineBuffer_rd_valid_v(3),
		o_data  		=> lb3_rd_data
	);

	-- processes
	
	-- count how many pixels are currently stored and not read out yet in all 4 line buffers
	pixel_wr_count_total_proc : PROCESS(i_clk)
	BEGIN
		IF rising_edge(i_clk) THEN
			IF i_rstn = '0' THEN
				total_wr_pixel_counter <= (OTHERS => '0');
			ELSE
				IF (i_pixel_data_valid = '1' and rd_line_buffer_flag = '0') THEN		-- only write
					total_wr_pixel_counter <= total_wr_pixel_counter + 1;
				ELSIF (i_pixel_data_valid = '0' and rd_line_buffer_flag = '1') THEN		-- only read
					total_wr_pixel_counter <= total_wr_pixel_counter - 1;
				END IF;  																-- otherwise total_wr_pixel_counter not change
			END IF;
		END IF;
	END PROCESS;

	-- state machine process to control read state (rd_line_buffer_flag)
	rd_state_proc : PROCESS(i_clk)
	BEGIN
		IF rising_edge(i_clk) THEN
			IF i_rstn = '0' THEN
				rdState <= IDLE;
				rd_line_buffer_flag <= '0';
				o_intr <= '0';
			ELSE
				CASE rdState IS
					WHEN IDLE =>
						o_intr <= '0';
						IF (to_integer(unsigned(total_wr_pixel_counter)) >= kernel_size * ram_depth) THEN
							rd_line_buffer_flag <= '1';
							rdState <= RD_BUFFER;  					-- jump into read buffer state
						END IF;
					WHEN RD_BUFFER =>
						IF (rd_pixel_counter = std_logic_vector(to_signed(ram_depth-1, rd_pixel_counter'length))) THEN  	-- if already read out the whole line buffer, back to IDLE to check if next three line buffers are ready to read out
							rdState <= IDLE;
							rd_line_buffer_flag <= '0';  			-- already finished read out one line buffer, stop reading and wait for load enough data
							o_intr <= '1';  						-- interrupt signal
						END IF;
				END CASE;
			END IF;
		END IF;
	END PROCESS;
	
	-- count how many pixels are already written in current line buffer
	pixel_wr_count_proc : PROCESS(i_clk)
	BEGIN
		IF rising_edge(i_clk) THEN
			IF i_rstn = '0' THEN
				wr_pixel_counter <= (OTHERS => '0');
			ELSE
				IF i_pixel_data_valid = '1' THEN
					wr_pixel_counter <= wr_pixel_counter + 1;
				END IF;
			END IF;
		END IF;
	END PROCESS;

	-- update pointer to choose which line buffer to write currently
	wr_buffer_pointer_proc : PROCESS(i_clk)
	BEGIN
		IF rising_edge(i_clk) THEN
			IF i_rstn = '0' THEN
				wrLineBuffer_pointer <= (OTHERS => '0');
			ELSE
				IF ((wr_pixel_counter = std_logic_vector(to_signed(ram_depth-1, rd_pixel_counter'length))) and (i_pixel_data_valid = '1')) THEN
					wrLineBuffer_pointer <= wrLineBuffer_pointer + 1;  -- 3 to 0
				END IF;
			END IF;
		END IF;
	END PROCESS;

	-- only the line buffer which wrLineBuffer_pointer specifies is allowed to write in more data currently
	line_buffer_wr_valid_proc : PROCESS(i_clk)
	BEGIN
		IF rising_edge(i_clk) THEN
			LineBuffer_wr_valid_v <= (OTHERS => '0');
			LineBuffer_wr_valid_v(to_integer(unsigned(wrLineBuffer_pointer))) <= i_pixel_data_valid;
		END IF;
	END PROCESS;

	-- count how many pixels are already read out from current line buffer
	pixel_rd_count_proc : PROCESS(i_clk)
	BEGIN
		IF rising_edge(i_clk) THEN
			IF i_rstn = '0' THEN
				rd_pixel_counter <= (OTHERS => '0');
			ELSE
				IF rd_line_buffer_flag = '1' THEN
					rd_pixel_counter <= rd_pixel_counter + 1;
				END IF;
			END IF;
		END IF;
	END PROCESS;
	
	-- update pointer to choose from which 3 line buffers (from rdLineBuffer_pointer the next 3) to read currently
	rd_buffer_pointer_proc : PROCESS(i_clk)
	BEGIN
		IF rising_edge(i_clk) THEN
			IF i_rstn = '0' THEN
				rdLineBuffer_pointer <= (OTHERS => '0');
			ELSIF ((rd_pixel_counter = std_logic_vector(to_signed(ram_depth-1, rd_pixel_counter'length))) and (rd_line_buffer_flag = '1')) THEN
				rdLineBuffer_pointer <= rdLineBuffer_pointer + 1;  -- if (3,0,1) after read out entire 3rd line buffer, will read (0,1,2) again
			END IF;												   -- see next process
		END IF;
	END PROCESS;
	
	rd_buffer_flag_proc : PROCESS(i_clk)
	BEGIN
		IF rising_edge(i_clk) THEN
			IF i_rstn = '0' THEN
				LineBuffer_rd_valid_v <= (OTHERS => '0');
			ELSE
				CASE rdLineBuffer_pointer IS
					WHEN "00" =>
						LineBuffer_rd_valid_v(0) <= rd_line_buffer_flag;
						LineBuffer_rd_valid_v(1) <= rd_line_buffer_flag;
						LineBuffer_rd_valid_v(2) <= rd_line_buffer_flag;
						LineBuffer_rd_valid_v(3) <= '0';
					WHEN "01" =>
						LineBuffer_rd_valid_v(0) <= '0';
						LineBuffer_rd_valid_v(1) <= rd_line_buffer_flag;
						LineBuffer_rd_valid_v(2) <= rd_line_buffer_flag;
						LineBuffer_rd_valid_v(3) <= rd_line_buffer_flag;
					WHEN "10" =>
						LineBuffer_rd_valid_v(0) <= rd_line_buffer_flag;
						LineBuffer_rd_valid_v(1) <= '0';
						LineBuffer_rd_valid_v(2) <= rd_line_buffer_flag;
						LineBuffer_rd_valid_v(3) <= rd_line_buffer_flag;
					WHEN "11" =>
						LineBuffer_rd_valid_v(0) <= rd_line_buffer_flag;
						LineBuffer_rd_valid_v(1) <= rd_line_buffer_flag;
						LineBuffer_rd_valid_v(2) <= '0';
						LineBuffer_rd_valid_v(3) <= rd_line_buffer_flag;									
					WHEN OTHERS =>
						LineBuffer_rd_valid_v(0) <= '0';
						LineBuffer_rd_valid_v(1) <= '0';
						LineBuffer_rd_valid_v(2) <= '0';
						LineBuffer_rd_valid_v(3) <= '0';															
				END CASE;
			END IF;
		END IF;
	END PROCESS;

	-- concatenate 24-bit outputs from all three current line buffers to form the 72-bit output 
	rd_buffer_proc : PROCESS(i_clk)
	BEGIN
		IF rising_edge(i_clk) THEN
			IF i_rstn = '0' THEN
				o_pixel_data <= (OTHERS => '0');
			ELSE
				CASE rdLineBuffer_pointer IS
					WHEN "00" =>
						o_pixel_data <= lb2_rd_data & lb1_rd_data & lb0_rd_data;
					WHEN "01" =>
						o_pixel_data <= lb3_rd_data & lb2_rd_data & lb1_rd_data;
					WHEN "10" =>
						o_pixel_data <= lb0_rd_data & lb3_rd_data & lb2_rd_data;
					WHEN "11" =>
						o_pixel_data <= lb1_rd_data & lb0_rd_data & lb3_rd_data;
					WHEN OTHERS =>
						o_pixel_data <= (OTHERS => '0');
				END CASE;
			END IF;
		END IF;
	END PROCESS;
	
	-- output is valid when rd_line_buffer_flag is high
	o_valid_proc : PROCESS(i_clk)
	BEGIN
		IF rising_edge(i_clk) THEN
			IF i_rstn = '0' THEN
				o_pixel_data_valid <= '0';
			ELSE
				o_pixel_data_valid <= rd_line_buffer_flag;
			END IF;			
		END IF;
	END PROCESS;
	
END Behavioral;