----------------------------------------------------------------------------------
-- Company: University of Stuttgart
-- Engineer: 
-- 
-- Create Date: 2022/09/25 14:03:41
-- Design Name: NMR sequence generator
-- Module Name: tb_fpga_pulse_mem - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
-- Description: 
-- 
-- Dependencies: 
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
-- 
----------------------------------------------------------------------------------

-- ! Use standard library ieee
LIBRARY IEEE;

-- ! Use logic elements
USE ieee.std_logic_1164.ALL;
-- ! Use numeric functions
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;

-- ! Use library fpga_pulse_gen_pkg
USE work.fpga_pulse_gen_pkg.ALL;

ENTITY tb_fpga_pulse_gen IS
--  Port ( );
END tb_fpga_pulse_gen;

ARCHITECTURE Behavioral OF tb_fpga_pulse_gen IS
	
	-- constants
	CONSTANT clk_period : time := 10 ns; 								    -- 100 MHz or any other clock frequency
		-- 0 in std_logic_vector
	CONSTANT f_lamor : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0) 	  := "00001111010111000010100011110110"; -- 6 MHz
	CONSTANT f_local : std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0)    := "00001111100111011011001000101101"; -- 6.1 MHz
	CONSTANT pi      : integer := 134217728; -- 180° 					

	
    SIGNAL clk        						:   std_logic	:= '0';
	SIGNAL o_tx_pulse						: 	std_logic	:= '0'; 		--tx pulse
	SIGNAL o_rx_pulse						: 	std_logic	:= '0'; 		--rx pulse
	SIGNAL ov_config_dds_data_ch0			:	std_logic_vector(C_DDS_CONFIG_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- DDS config data output
	SIGNAL o_config_tvalid_ch0				:	std_logic	:= '0'; 		-- DDS valid SIGNAL output	
	SIGNAL ov_config_dds_data_ch1			:   std_logic_vector(C_DDS_CONFIG_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- DDS config data output	
	SIGNAL o_config_tvalid_ch1				:   std_logic	:= '0';	   		-- DDS valid SIGNAL output		
	SIGNAL o_mux_ch							:   std_logic	:= '0'; 		-- channel digital switch
	
	SIGNAL i_en									: std_logic := '0';
	-- select the section
	SIGNAL iv_set_nr_sections					: unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_write_sel_section					: unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- select the number of to config		
	SIGNAL iv_set_section_type					: unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- section type 																					  -- 0: Tx																					  -- 1: Rx	
	SIGNAL iv_set_delay 						: unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');	
	SIGNAL iv_set_mux 							: unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- after tx wait mux change time
	-- repetition contol
	SIGNAL iv_set_start_repeat_pointer			: unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_end_repeat_pointer 			: unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL iv_set_cycle_repetition_number		: unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');		
	SIGNAL iv_set_experiment_repetition_number	: unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	-- DDS contol		
	SIGNAL iv_set_phase_ch0		 				: unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- configuration the phase of dds
	SIGNAL iv_set_frequency_ch0		 			: unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- configuraton the frequency 		
	SIGNAL iv_set_phase_ch1			 			: unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- configuration the phase of dds
	SIGNAL iv_set_frequency_ch1		 			: unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0'); -- configuraton the frequency 		
	SIGNAL iv_set_resetn_dds					: unsigned(C_DATA_WIDTH - 1 DOWNTO 0) := (OTHERS => '0');
	SIGNAL o_busy								: std_logic := '0';
	SIGNAL o_data_ready							: std_logic := '0';
	
	component dds_compiler_0 IS
	  PORT (
		aclk : IN STD_LOGIC;
		aresetn : IN STD_LOGIC;  	
		s_axis_config_tvalid : IN STD_LOGIC;
		s_axis_config_tdata : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
		m_axis_data_tvalid : OUT STD_LOGIC;
		m_axis_data_tdata : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	  );
	END component;

		
	component dds_compiler_1 IS
	  PORT (
		aclk : IN STD_LOGIC;
		aresetn : IN STD_LOGIC;        
		s_axis_config_tvalid : IN STD_LOGIC;
		s_axis_config_tdata : IN STD_LOGIC_VECTOR(63 DOWNTO 0);
		m_axis_data_tvalid : OUT STD_LOGIC;
		m_axis_data_tdata : OUT STD_LOGIC_VECTOR(15 DOWNTO 0)
	  );
	END COMPONENT;

	SIGNAL 
	aresetn 
	: STD_LOGIC := '0';  
		
	SIGNAL 
	m_axis_data_tdata_ch0,
	m_axis_data_tdata_ch1
	: STD_LOGIC_VECTOR(15 DOWNTO 0):= (OTHERS => '0');
	
BEGIN
	inst_dds_0: dds_compiler_0
	PORT MAP
	(
		aclk => clk,
		aresetn              => aresetn,		
		s_axis_config_tvalid => o_config_tvalid_ch0,
		s_axis_config_tdata => ov_config_dds_data_ch0,
		m_axis_data_tvalid => OPEN,
		m_axis_data_tdata => m_axis_data_tdata_ch0
	);

	inst_dds_1: dds_compiler_1
	PORT MAP
	(
		aclk => clk,
		aresetn              => aresetn,
		s_axis_config_tvalid => o_config_tvalid_ch1,
		s_axis_config_tdata => ov_config_dds_data_ch1,
		m_axis_data_tvalid => OPEN,
		m_axis_data_tdata => m_axis_data_tdata_ch1
	);
	
	-- An instance of fpga_pulse_gen with architecture Behavioral
	inst_fpga_pulse_gen : ENTITY work.fpga_pulse_gen(Behavioral) PORT MAP(
		clk 									=>	clk,
		o_tx_pulse								=>	o_tx_pulse,
		o_rx_pulse								=>	o_rx_pulse,	
		ov_config_dds_data_ch0					=>	ov_config_dds_data_ch0,
		o_config_tvalid_ch0						=>	o_config_tvalid_ch0,		
		ov_config_dds_data_ch1					=>	ov_config_dds_data_ch1,	
		o_config_tvalid_ch1						=>	o_config_tvalid_ch1,		
		o_mux_ch								=>	o_mux_ch, 
		i_en									=>	i_en,
		-- select the section
		iv_set_nr_sections						=>	iv_set_nr_sections,
		iv_write_sel_section					=>	iv_write_sel_section,	
		iv_set_section_type						=>	iv_set_section_type,	
		iv_set_delay 							=>	iv_set_delay,	
		-- Rx section configuration parameter	
		iv_set_mux 								=>	iv_set_mux,	
		-- repetition contol
		iv_set_start_repeat_pointer				=>	iv_set_start_repeat_pointer,	
		iv_set_end_repeat_pointer 				=>	iv_set_end_repeat_pointer,	
		iv_set_cycle_repetition_number			=>	iv_set_cycle_repetition_number,		
		iv_set_experiment_repetition_number		=>	iv_set_experiment_repetition_number,	
		-- DDS contol		
		o_dds_rstn								=>  aresetn,
		iv_set_phase_ch0		 				=>	iv_set_phase_ch0,	
		iv_set_frequency_ch0		 			=>	iv_set_frequency_ch0,			
		iv_set_phase_ch1			 			=>	iv_set_phase_ch1,	
		iv_set_frequency_ch1		 			=>	iv_set_frequency_ch1,
		iv_set_resetn_dds						=>  iv_set_resetn_dds,
		o_busy									=>	o_busy,	
		o_data_ready							=>	o_data_ready
	);

	-- Testbench processes
	
	PROCESS -- system reference clock
	BEGIN
		clk <= '1';
		WAIT FOR clk_period/2;
		clk <= '0';
		WAIT FOR clk_period/2;
	END PROCESS;

	PROCESS		-- fpga_pulse_gen test
		-- procedure define
	    PROCEDURE Load_Data_Prod
        (
			CONSTANT write_sel_section  : IN INTEGER;
			CONSTANT set_section_type   : IN INTEGER;
			CONSTANT set_delay  	    : IN INTEGER;
			CONSTANT set_mux            : IN INTEGER;
			CONSTANT set_phase_ch0  	: IN INTEGER;
			CONSTANT set_frequency_ch0  : IN std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
			CONSTANT set_phase_ch1      : IN INTEGER;
			CONSTANT set_frequency_ch1  : IN std_logic_vector(C_DATA_WIDTH - 1 DOWNTO 0);
			CONSTANT set_resetn_dds		: IN INTEGER
        ) IS
        BEGIN
            -- WAIT UNTIL rising_edge(clk);     -- use wait until rising_edge instead of wait for 1 ms (not exact edge defined)
			-- choose write (and read section)
			WAIT UNTIL rising_edge(clk);
			iv_write_sel_section  	 				<= to_unsigned(write_sel_section, C_DATA_WIDTH);
			iv_set_section_type 	 				<= to_unsigned(set_section_type, C_DATA_WIDTH);
			iv_set_delay 		 	 				<= to_unsigned(set_delay, C_DATA_WIDTH);
			iv_set_mux 			 	 				<= to_unsigned(set_mux, C_DATA_WIDTH);
			iv_set_phase_ch0 						<= to_unsigned(set_phase_ch0,C_DATA_WIDTH);
			iv_set_frequency_ch0 	 				<= unsigned(set_frequency_ch0);
			iv_set_phase_ch1						<= to_unsigned(set_phase_ch1,C_DATA_WIDTH);
			iv_set_frequency_ch1 	 				<= unsigned(set_frequency_ch1);
			iv_set_resetn_dds						<= to_unsigned(set_resetn_dds,C_DATA_WIDTH);	
        END Load_Data_Prod;		
	
		-- procedure define
	    PROCEDURE Load_Command_Prod
        (
            CONSTANT 
			set_nr_sections,
			set_start_repeat_pointer,
			set_end_repeat_pointer,
			set_cycle_repetition_number,
			set_experiment_repetition_number  
			: IN INTEGER
        ) IS
        BEGIN
            -- WAIT UNTIL rising_edge(clk);  -- use wait until rising_edge instead of wait for 1 ms (no exact edge defined)
			-- choose write (and read section)
			WAIT UNTIL rising_edge(clk);
			iv_set_nr_sections 						<= to_unsigned(set_nr_sections, C_DATA_WIDTH);
			iv_set_start_repeat_pointer 			<= to_unsigned(set_start_repeat_pointer, C_DATA_WIDTH);
			iv_set_end_repeat_pointer   			<= to_unsigned(set_end_repeat_pointer, C_DATA_WIDTH);
			iv_set_cycle_repetition_number  		<= to_unsigned(set_cycle_repetition_number, C_DATA_WIDTH);
			iv_set_experiment_repetition_number 	<= to_unsigned(set_experiment_repetition_number, C_DATA_WIDTH);
        END Load_Command_Prod;	

	BEGIN
	i_en <= '0';	

		Load_Command_Prod
		(
			12,	 	-- iv_set_nr_sections: 0-11
			4, 		-- iv_set_start_repeat_pointer
			9, 		-- iv_set_end_repeat_pointer
			10, 	-- iv_set_cycle_repetition_number: 150
			2  		-- iv_set_experiment_repetition_number: 10
		);


		-- section 0 configuration		
		WAIT FOR 5 * clk_period;
		WAIT UNTIL rising_edge(clk);
		Load_Data_Prod
		(
			0, 				-- iv_write_sel_section      
			2, 				-- iv_set_section_type		Phase reset DELAY = 5 us
			50, 			-- iv_set_delay
			0, 				-- iv_set_mux TX
			0, 				-- iv_set_phase_ch0
			f_lamor, 		-- iv_set_frequency_ch0: 6 MHz
			0, 				-- iv_set_phase_ch1
			f_lamor,  		-- iv_set_frequency_ch1: 6 MHz	
			0
		);

		-- section 1 configuration		
		WAIT FOR 5 * clk_period;
		WAIT UNTIL rising_edge(clk);
		Load_Data_Prod
		(
			1, 				-- iv_write_sel_section      
			2, 				-- iv_set_section_type		Phase set DELAY = 5 us
			500, 			-- iv_set_delay
			0, 				-- iv_set_mux TX
			pi, 			-- iv_set_phase_ch0: 90 deg
			f_lamor, 		-- iv_set_frequency_ch0: 6 MHz
			0, 				-- iv_set_phase_ch1
			f_lamor, 		-- iv_set_frequency_ch1: 6 MHz -- phase coherent until here
			1
		);

		-- section 2 configuration
		WAIT FOR 5 * clk_period;
		WAIT UNTIL rising_edge(clk);
		Load_Data_Prod
		(
			2, 				-- iv_write_sel_section      
			0, 				-- iv_set_section_type 		TX duration = 10 us
			410, 			-- iv_set_delay
			1, 				-- iv_set_mux TX
			pi/2, 			-- iv_set_phase_ch0: 90 deg
			(OTHERS =>'0'), 		-- iv_set_frequency_ch0: 6 MHz
			pi, 			-- iv_set_phase_ch1: 0 deg
			(OTHERS =>'0'), 		-- iv_set_frequency_ch1: 6 MHz -- phase coherent until here
			1
		);
		
		-- section 3 configuration
		WAIT FOR 5 * clk_period;
		WAIT UNTIL rising_edge(clk);
		Load_Data_Prod
		(
			3, 				-- iv_write_sel_section      
			2, 				-- iv_set_section_type 		wait duration DELAY = 100 us
			100, 			-- iv_set_delay
			0, 				-- iv_set_mux TX
			0, 				-- iv_set_phase_ch0: 0 deg
			f_lamor, 		-- iv_set_frequency_ch0: 6 MHz
			0, 				-- iv_set_phase_ch1: 0 deg
			f_lamor, 		-- iv_set_frequency_ch1: 6 MHz -- phase coherent until here
			0
		);
		
		-- section 4 configuration
		WAIT FOR 5 * clk_period;
		WAIT UNTIL rising_edge(clk);
		Load_Data_Prod
		(
			4, 				-- iv_write_sel_section      
			2, 				-- iv_set_section_type 		Phase set DELAY = 100 us
			100, 			-- iv_set_delay
			0, 				-- iv_set_mux TX
			pi, 			-- iv_set_phase_ch0: 180 deg
			f_lamor, 		-- iv_set_frequency_ch0: 6 MHz
			0, 				-- iv_set_phase_ch1: 0 deg
			f_lamor, 		-- iv_set_frequency_ch1: 6 MHz -- phase coherent until here
			1
		);	
		
		-- section 5 configuration
		WAIT FOR 5 * clk_period;
		WAIT UNTIL rising_edge(clk);
		Load_Data_Prod
		(
			5, 				-- iv_write_sel_section      
			0, 				-- iv_set_section_type 		TX pi duration DELAY = 20 us
			200, 			-- iv_set_delay
			0, 				-- iv_set_mux TX
			0, 			-- iv_set_phase_ch0: 180 deg
			f_lamor, 		-- iv_set_frequency_ch0: 6 MHz
			0, 			-- iv_set_phase_ch1: 0 deg
			f_lamor, 		-- iv_set_frequency_ch1: 6 MHz -- phase coherent until here
			1
		);	

		-- section 6 configuration
		WAIT FOR 5 * clk_period;
		WAIT UNTIL rising_edge(clk);
		Load_Data_Prod
		(
			6, 				-- iv_write_sel_section      
			2, 				-- iv_set_section_type 		wait duration DELAY = 100 us
			100, 			-- iv_set_delay
			0, 				-- iv_set_mux TX
			0, 			-- iv_set_phase_ch0: 0 deg
			f_lamor, 		-- iv_set_frequency_ch0: 6 MHz
			0, 			-- iv_set_phase_ch1: 0 deg
			f_lamor, 		-- iv_set_frequency_ch1: 6 MHz -- phase coherent until here
			1
		);

		-- section 7 configuration
		WAIT FOR 5 * clk_period;
		WAIT UNTIL rising_edge(clk);
		Load_Data_Prod
		(
			7, 				-- iv_write_sel_section      
			2, 				-- iv_set_section_type 		wait duration DELAY = 100 us
			100, 			-- iv_set_delay
			0, 				-- iv_set_mux RX			mux switch to RX
			0, 			-- iv_set_phase_ch0: 0 deg
			f_lamor, 		-- iv_set_frequency_ch0: 6 MHz
			0, 			-- iv_set_phase_ch1: 0 deg
			f_lamor, 		-- iv_set_frequency_ch1: 6 MHz -- phase coherent until here
			1
		);
		-- section 8 configuration
		WAIT FOR 5 * clk_period;
		WAIT UNTIL rising_edge(clk);
		Load_Data_Prod
		(
			8, 				-- iv_write_sel_section      
			1, 				-- iv_set_section_type 		RX duration DELAY = 3 us
			300, 			-- iv_set_delay
			1, 				-- iv_set_mux RX
			0, 			-- iv_set_phase_ch0: 0 deg
			f_lamor, 		-- iv_set_frequency_ch0: 6 MHz
			0, 			-- iv_set_phase_ch1: 0 deg
			f_lamor, 		-- iv_set_frequency_ch1: 6 MHz -- phase coherent until here
			1
		);
		
		-- section 9 configuration
		WAIT FOR 5 * clk_period;
		WAIT UNTIL rising_edge(clk);
		Load_Data_Prod
		(
			9, 				-- iv_write_sel_section      
			2, 				-- iv_set_section_type 		wait duration DELAY = 100 us
			100, 			-- iv_set_delay
			0, 				-- iv_set_mux RX
			0, 			-- iv_set_phase_ch0: 0 deg
			f_lamor, 		-- iv_set_frequency_ch0: 6 MHz
			0, 			-- iv_set_phase_ch1: 0 deg
			f_lamor, 		-- iv_set_frequency_ch1: 6 MHz -- phase coherent until here
			1
		);
		
		-- section 10 configuration
		WAIT FOR 5 * clk_period;
		WAIT UNTIL rising_edge(clk);
		Load_Data_Prod
		(
			10, 			-- iv_write_sel_section      
			2, 				-- iv_set_section_type 		last experiment DELAY = 10 us
			100, 			-- iv_set_delay
			0, 				-- iv_set_mux RX
			0, 			-- iv_set_phase_ch0: 0 deg
			(OTHERS =>'0'), 		-- iv_set_frequency_ch0: 6 MHz
			0, 			-- iv_set_phase_ch1: 0 deg
			(OTHERS =>'0'), 		-- iv_set_frequency_ch1: 6 MHz -- phase coherent until here
			1
		);

		-- section 11 configuration
		WAIT FOR 5 * clk_period;
		WAIT UNTIL rising_edge(clk);
		Load_Data_Prod
		(
			11, 			-- iv_write_sel_section      
			2, 				-- iv_set_section_type 		end experiment duration DELAY = 1 us
			100, 			-- iv_set_delay
			0, 				-- iv_set_mux RX
			0, 			-- iv_set_phase_ch0: 0 deg
			f_lamor, 		-- iv_set_frequency_ch0: 6 MHz
			0, 			-- iv_set_phase_ch1: 0 deg
			f_lamor, 		-- iv_set_frequency_ch1: 6 MHz -- phase coherent until here
			1
		);
		
		
		WAIT FOR 10 * clk_period;		
		WAIT UNTIL rising_edge(clk);
		i_en <= '1';
		
		WAIT FOR 25000 * clk_period;

		ASSERT false
		REPORT "Simulation finished"
		SEVERITY failure;

	END PROCESS;

END Behavioral;
