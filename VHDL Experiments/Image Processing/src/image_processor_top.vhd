----------------------------------------------------------------------------------
-- Title: ENTITY image_processor_top (AXI-stream protocol)
--
-- Company: IIS, University of Stuttgart
--
-- Author: Yichao Peng
--
-- Project Name: Image processing on Zynq
--
-- Target Devices: 
-- Tool Versions: 
-- Description: Top design of image processing project. CU coordinates between line buffer and conv.
--				Top module controls the input and output with AXI protocol.
--				Add an extra FIFO to output in order to conquer the mismatch of intermediate signals due to conv pipeline.
--				Input side already has line buffer, no FIFO required.
--
-- Dependencies: ENTITY conv, ENTITY line_buffer, ENTIT image_cu
-- 
-- History:
-- 	Version 0.1  Create file, Yichao Peng, 2023/7/26 18:01
-- 
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.std_logic_unsigned.ALL;

ENTITY image_processor_top IS
	GENERIC(
		pixel_data_for_conv_width : integer := 72;
		i_width					  : integer := 8;
		o_width					  : integer := 8;
		kernel_size               : integer := 3;
		ram_depth    			  : integer := 512
	);
	PORT(
		-- AXI interface
		axi_clk   				: IN std_logic;
		axi_reset_n				: IN std_logic;
		-- slave interface
		i_data_valid			: IN std_logic;
		i_data					: IN std_logic_vector(i_width-1 DOWNTO 0);
		o_data_ready  			: OUT std_logic;  	-- from image_processor, telling DMA transmitter ready to receive data
		-- master interface
		o_data_valid  			: OUT std_logic;
		o_data					: OUT std_logic_vector(o_width-1 DOWNTO 0);
		i_data_ready    		: IN std_logic;  	-- from DMA, telling image_processor transmitter ready to receive data
		-- interrupt
		o_intr					: OUT std_logic		-- tell DMA a line buffer is free now
	);
END ENTITY;

ARCHITECTURE Behavioral OF image_processor_top IS

	-- signal definition
	
	SIGNAL convolved_data_valid  		: std_logic := '0';
	SIGNAL convolved_data				: std_logic_vector(o_width-1 DOWNTO 0) := (OTHERS => '0');
	
	SIGNAL pixel_data_for_conv 			: std_logic_vector(pixel_data_for_conv_width-1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL pixel_data_valid_for_conv 	: std_logic := '0';  -- from line buffer to conv

	SIGNAL axis_prog_full             	: std_logic := '0';  -- output buffer is full and can start carry data

	-- IP core

	COMPONENT output_buffer
	  PORT (
		wr_rst_busy : OUT STD_LOGIC;
		rd_rst_busy : OUT STD_LOGIC;
		s_aclk : IN STD_LOGIC;
		s_aresetn : IN STD_LOGIC;
		s_axis_tvalid : IN STD_LOGIC;
		s_axis_tready : OUT STD_LOGIC;
		s_axis_tdata : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		m_axis_tvalid : OUT STD_LOGIC;
		m_axis_tready : IN STD_LOGIC;
		m_axis_tdata : OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		axis_prog_full : OUT STD_LOGIC
	  );
	END COMPONENT;

BEGIN

-- components instantiation

	-- control unit to coordinate between line buffers and conv
	image_cu_inst : ENTITY work.image_cu
	GENERIC MAP(
		kernel_size => kernel_size,     			-- kernel size
		i_width   	=> i_width,						-- read pixel data into line buffer
		o_width   	=> pixel_data_for_conv_width,	-- output data to conv
		ram_depth 	=> ram_depth
	)
	PORT MAP(
		i_clk   			=> axi_clk,
		i_rstn   			=> axi_reset_n,
		i_pixel_data		=> i_data,
		i_pixel_data_valid	=> i_data_valid,
		o_pixel_data  		=> pixel_data_for_conv,
		o_pixel_data_valid	=> pixel_data_valid_for_conv,
		o_intr				=> o_intr
	);

	-- convolutional unit
	conv_inst : ENTITY work.conv
	GENERIC MAP(
		i_width   		=> pixel_data_for_conv_width,
		o_width  		=> o_width,
		kernel_size 	=> kernel_size
	)
	PORT MAP(
		i_clk   				=> axi_clk, 
		i_rstn   				=> axi_reset_n,  				-- synchronous reset, active low
		i_pixel_data			=> pixel_data_for_conv, 		-- all gray value in a kernel
		i_pixel_data_valid		=> pixel_data_valid_for_conv,
		o_convolved_data  		=> convolved_data,
		o_convolved_data_valid	=> convolved_data_valid
	);
	
	-- output buffer to conquer mismatch
	output_buffer_inst : output_buffer
	PORT MAP (
		wr_rst_busy 	=> OPEN,
		rd_rst_busy 	=> OPEN,
		s_aclk 			=> axi_clk,			-- slave interface connect with conv master interface
		s_aresetn 		=> axi_reset_n,
		s_axis_tvalid 	=> convolved_data_valid,
		s_axis_tready 	=> OPEN,			-- under no case not ready, begin carray out and transfer to DMA when half full
		s_axis_tdata 	=> convolved_data,
		m_axis_tvalid 	=> o_data_valid,
		m_axis_tready 	=> i_data_ready,
		m_axis_tdata 	=> o_data,
		axis_prog_full 	=> axis_prog_full
	);
	
-- processes
	
	-- if not full then tell DMA the top is ready to receive more data
	o_data_valid <= not axis_prog_full;
	
END Behavioral;