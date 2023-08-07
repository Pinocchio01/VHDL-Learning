----------------------------------------------------------------------------------
-- Title: testbench of image_processor_top
--
-- Company: IIS, University of Stuttgart
--
-- Author: Yichao Peng
--
-- Project Name: Image processing on Zynq
--
-- Target Devices:
-- Tool Versions:
-- Description: Test the function of top module of image processor.
-- 
-- Dependencies: Entity image_processor_top
-- 
-- History:
-- 	Version 0.1  Create file, Yichao Peng, 2023/7/27 13:58
-- 
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;
USE ieee.math_real.ALL;
USE std.textio.ALL;
USE std.env.finish;  -- Stop the simulation when all tests have completed

ENTITY tb_image_processor_top IS
--  Port ( );
END tb_image_processor_top;

ARCHITECTURE Behavioral OF tb_image_processor_top IS
	
	-- file handles
	TYPE char_file IS FILE OF character;
	FILE bmp_file			: char_file OPEN read_mode IS "lena_gray.bmp";	-- under relative path, file must be put in xsim directory
	FILE out_file			: char_file OPEN write_mode IS "lena_gray_blurred.bmp";
--	FILE bmp_file			: char_file OPEN read_mode IS "E:\Electromobility\Masterthesis\FPGA_projects\Trial_projects\imageProcessing\lena_gray.bmp";  -- File handle
--	FILE out_file 			: char_file OPEN write_mode IS "E:\Electromobility\Masterthesis\FPGA_projects\Trial_projects\imageProcessing\lena_gray_blurred.bmp";

	-- Constants
	CONSTANT C_pixel_data_for_conv_width : integer := 72;
	CONSTANT C_i_width					 : integer := 8;
	CONSTANT C_o_width					 : integer := 8;
	CONSTANT C_kernel_size				 : integer := 3;
	CONSTANT C_ram_depth				 : integer := 512;
	CONSTANT C_channel_number			 : integer := 1; 	 -- Number of channels, for RGB is 3
	CONSTANT clk_period 				 : time	   := 10 ns;
	CONSTANT C_image_width 				 : integer := 512;
	CONSTANT C_image_height 			 : integer := 512;
		
	-- Read image file types
	TYPE header_type IS ARRAY(0 TO 1079) OF character;	-- Header of BMP file
	-- TYPE header_type IS ARRAY(0 TO 53) OF character;	-- Header of BMP file
	TYPE pixel_type IS RECORD  -- record type reserved for multichannel images like RGB, here only gray
		gray : std_logic_vector(C_i_width-1 DOWNTO 0);
		-- red 	: std_logic_vector(C_i_width-1 DOWNTO 0);
		-- green 	: std_logic_vector(C_i_width-1 DOWNTO 0);
		-- blue 	: std_logic_vector(C_i_width-1 DOWNTO 0);
	END RECORD;
	TYPE row_type IS ARRAY(integer RANGE <>) OF pixel_type;
	TYPE row_pointer IS ACCESS row_type;
	TYPE image_type IS ARRAY(integer RANGE <>) OF row_pointer;
	TYPE image_pointer IS ACCESS image_type;
		
	-- Signals
	SIGNAL clk 				: std_logic := '0';
	SIGNAL rstn 			: std_logic := '1';  -- Active low
	SIGNAL i_data 			: std_logic_vector(C_i_width-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL i_data_valid 	: std_logic := '0';  -- valid signal for IP core
	-- SIGNAL o_data_ready : std_logic := '0';
	SIGNAL o_data			: std_logic_vector(C_o_width-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL o_data_valid 	: std_logic := '0';
	-- SIGNAL i_data_ready : std_logic := '0';
	SIGNAL o_intr			: std_logic := '0';
	SIGNAL sent_size    	: integer	:= 0;	-- count pixel sent to IP core
	SIGNAL received_size 	: integer   := 0;	-- count pixel written into new file
	
BEGIN

	-- Component instatiation
	DUT : ENTITY work.image_processor_top
	GENERIC MAP(
		pixel_data_for_conv_width 	=> C_pixel_data_for_conv_width,
		i_width					  	=> C_i_width,
		o_width					  	=> C_o_width,
		kernel_size               	=> C_kernel_size,
		ram_depth    			  	=> C_ram_depth
	)
	PORT MAP(
		-- AXI interface
		axi_clk   					=> clk,
		axi_reset_n					=> rstn,
		-- Slave interface			
		i_data_valid				=> i_data_valid,
		i_data						=> i_data,
		o_data_ready  				=> OPEN,			-- controlled by FIFO
		-- Master interface
		o_data_valid  				=> o_data_valid,
		o_data						=> o_data,
		i_data_ready    			=> '1',  			-- from DMA receiver, tell FIFO that DMA receiver is always ready, so FIFO will always set o_data_ready high, meaning ready to receive new data from DMA transmitter
		-- Interrupt
		o_intr						=> o_intr
	);
	
	-- Processes

	clk_proc: PROCESS
	BEGIN
		WAIT FOR clk_period/2;
		clk <= '1';
		WAIT FOR clk_period/2;
		clk <= '0';
	END PROCESS;
	
	read_file_proc: PROCESS  -- Read header and pixels from original file and send to IP core
		-- Process variables
		VARIABLE header 		: header_type;
		VARIABLE row 			: row_pointer;		-- actually no need in our case
		VARIABLE image_pointer 	: image_pointer;
		-- VARIABLE padding 		: integer;
		VARIABLE char 			: character;
		
	BEGIN
	
		-- 0. IP reset
		rstn <= '0';	-- reset at beginning
		WAIT FOR 100 * clk_period;  -- At least 100 clock period reset is valid for Xilinx FPGA
		rstn <= '1';
		WAIT FOR 100 * clk_period;
		
		-- 1. Reading the BMP header and write in new BMP file (same size and template)
		FOR i IN header_type'RANGE LOOP  -- Always use attributes
			read(bmp_file, header(i));	-- unit according to header type - character
			write(out_file, header(i));
		END LOOP;
	
		-- 2. Reading the pixel data (only these data should be sent to IP core)
		-- padding := (4 - C_image_width*C_channel_number mod 4) mod 4;
		image_pointer := NEW image_type(0 TO C_image_height-1);  -- Create a new image type in dynamic memory
		
		FOR row_i IN 0 TO C_kernel_size LOOP	-- firstly send 4 (kernel_size + 1) rows(lines) to the buffer
			row := NEW row_type(0 TO C_image_width - 1);	-- Create a new row type in dynamic memory
			FOR col_i IN 0 TO C_image_width - 1 LOOP
				WAIT UNTIL rising_edge(clk);
				read(bmp_file, char);	-- Read gray pixel in character type
				row(col_i).gray := std_logic_vector(to_unsigned(character'pos(char), 8));
				i_data <= row(col_i).gray;
				i_data_valid <= '1';  -- set input data valid for IP core
			END LOOP;
			
			-- -- Read and discard padding
			-- FOR i IN 1 TO padding LOOP
				-- read(bmp_file, char);
			-- END LOOP;
			-- Assign the row pointer to the image vector of rows
			
			image_pointer(row_i) := row;
		END LOOP;
		
		sent_size <= (C_kernel_size + 1) * C_image_width;  -- update number of already sent pixels
		
		WAIT UNTIL rising_edge(clk);	-- after loading the four line buffers, wait for interrupt signal from IP core
		i_data_valid <= '0';
		WHILE (sent_size < C_image_height * (C_image_width - 1)) LOOP  -- send all pixel data
			WAIT UNTIL rising_edge(o_intr);  -- if o_intr high, send one more line pixel data
			row := NEW row_type(0 TO C_image_width - 1);
			FOR col_i IN 0 TO C_image_width - 1 LOOP
				WAIT UNTIL rising_edge(clk);
				read(bmp_file, char);
				row(col_i).gray := std_logic_vector(to_unsigned(character'pos(char), 8));
				i_data <= row(col_i).gray;
				i_data_valid <= '1';
			END LOOP;
			WAIT UNTIL rising_edge(clk);  -- make sure the last valid signal high for one clock period
			i_data_valid <= '0';  -- after loading one line buffer, wait for the next interrupt signal from IP core
			sent_size <= sent_size + C_image_width;
		END LOOP;
		WAIT UNTIL rising_edge(clk);
		i_data_valid <= '0';			-- until here all pixels sent to IP core
		
		WAIT UNTIL rising_edge(o_intr); -- send two more dummy lines to conquer size reduction due to convolution(although otherwise the kernel will take index -1 and 0, 1 for the last conv operation in a line)
		FOR col_i IN 0 TO C_image_width - 1 LOOP	-- first dummy
			WAIT UNTIL rising_edge(clk);
			i_data <= (OTHERS => '0');	-- no more data, file already empty, dummy data 0 (can modify to mirror)
			i_data_valid <= '1';
		END LOOP;
		WAIT UNTIL rising_edge(clk);
		i_data_valid <= '0';
		WAIT UNTIL rising_edge(o_intr);
		FOR col_i IN 0 TO C_image_width - 1 LOOP	-- second dummy
			WAIT UNTIL rising_edge(clk);
			i_data <= (OTHERS => '0');
			i_data_valid <= '1';
		END LOOP;
		
		WAIT UNTIL rising_edge(clk);				-- close original file
		i_data_valid <= '0';
		file_close(bmp_file);						
		deallocate(row);  -- Keyword to free the dynamically allocated memory for each row
		deallocate(image_pointer);  -- deallocate the memory space for the image variable
		
		WAIT FOR 100 ms;	-- wait for other processes to terminate
		
	END PROCESS;
	
	write_file_proc: PROCESS(clk)  -- Write the output BMP file	
	BEGIN
		IF rising_edge(clk) THEN
			IF o_data_valid = '1' THEN
				write(out_file, character'val(to_integer(unsigned(o_data))));
				received_size <= received_size + 1;
			END IF;
			IF received_size = C_image_height * C_image_width THEN
				file_close(out_file);
				REPORT "Simulation done. Check ""out.bmp"" image.";
				finish;				
			END IF;
		END IF;
	END PROCESS;
	
END Behavioral;