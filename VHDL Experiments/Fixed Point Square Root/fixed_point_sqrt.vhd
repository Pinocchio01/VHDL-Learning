----------------------------------------------------------------------------------
-- Title: ENTITY fixed_point_sqrt
--
-- Company: IIS, University of Stuttgart
--
-- Author: Yichao Peng
--
-- Project Name: pNMR spectrometer
--
-- Target Devices: 
-- Tool Versions: 
-- Description: Validate the square root function on fixed point values
--              then add into fixed point package.
-- 
-- Dependencies: PACKAGE fpga_dup_fixedpoint_pkg
-- 
-- History:
-- 	Version 0.1  Create file, Yichao Peng, 2022/07/20
--  
----------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
USE ieee.numeric_std.ALL;
USE ieee.math_real.ALL;
USE ieee.std_logic_arith.ALL;
USE work.fixed_point_pkg_paul.ALL;

ENTITY fixed_point_sqrt IS
	GENERIC(
		dec_width  : integer := 8;
		frac_width : integer := 8
	);
	PORT(
		clk  : IN std_logic;
		rstn : IN std_logic;
		i1   : IN t_ufixed(dec_width-1 DOWNTO -frac_width);
		o1   : OUT t_ufixed(integer(ceil(real(dec_width) / real(2))) - 1 DOWNTO -integer(ceil(real(frac_width) / real(2))))
	);
END ENTITY;

ARCHITECTURE Behavioral OF fixed_point_sqrt IS

	-- constants
	CONSTANT C_input_total_width  	: integer := dec_width + frac_width;
	CONSTANT C_input_half_width 	: integer := integer(ceil(real(C_input_total_width) / real(2)));

BEGIN
	
	logic_proc : PROCESS(i1, rstn, clk)
	-- variables
	VARIABLE q 			: ieee.numeric_std.unsigned(C_input_half_width - 1 DOWNTO 0) 	:= (C_input_half_width - 1 => '1', OTHERS => '0');   -- square root integer plus fraction part, left shift 32 bits
	VARIABLE q0 		: ieee.numeric_std.unsigned(C_input_half_width - 1 DOWNTO 0) 	:= (C_input_half_width - 1 => '1', OTHERS => '0');  -- to store current bit of square root for addition or substraction
	VARIABLE q_ufixed	: t_ufixed(integer(ceil(real(dec_width) / real(2))) - 1 DOWNTO -integer(ceil(real(frac_width) / real(2)))) := (OTHERS => '0');
	VARIABLE a 			: ieee.numeric_std.unsigned(C_input_total_width - 1 DOWNTO 0)   := ieee.numeric_std.unsigned(to_std_logic_vector_proper(i1));     -- from original input into signed type
	VARIABLE b 			: ieee.numeric_std.unsigned(C_input_total_width DOWNTO 0)		 := ieee.numeric_std.unsigned(to_std_logic_vector_proper('0' & i1));     -- for odd number of width
	BEGIN
		q  := (C_input_half_width - 1 => '1', OTHERS => '0');
		q0 := (C_input_half_width - 1 => '1', OTHERS => '0');
		a  := ieee.numeric_std.unsigned(to_std_logic_vector_proper(i1));
		b  := ieee.numeric_std.unsigned(to_std_logic_vector_proper('0' & i1));
		IF rstn = '0' THEN
			o1 <= (OTHERS => '0');
		ELSIF rising_edge(clk) THEN
			IF conv_std_logic_vector(C_input_total_width, 10)(0) = '1' THEN 	-- in case of odd number
				FOR i IN 0 TO C_input_half_width - 1 LOOP	-- integer part
					q0 := shift_right(q0, 1); -- operation in numeric_std library
					IF (b > q * q) THEN -- if s nonnegative
						q := q + q0; -- set next smaller bit to 1
					ELSIF (b = q * q) THEN
						EXIT;
					ELSE
						q := q - q0;
					END IF;
				END LOOP;
				IF (b < q * q) THEN -- LSB approximation
					q := q - to_unsigned(1, C_input_half_width);
				ELSE
					q := q;
				END IF;
				IF (b <= q * q) THEN -- LSB approximation
					q_ufixed(q_ufixed'low) := '0';
				ELSIF (b > q * q) THEN
					q_ufixed(q_ufixed'low) := '1';
				END IF;				
			ELSE														    -- in case of even number
				FOR i IN 0 TO C_input_half_width - 1 LOOP	-- integer part
					q0 := shift_right(q0, 1);
					IF (a > q * q) THEN
						q := q + q0;
					ELSIF (a = q * q) THEN
						EXIT;
					ELSE
						q := q - q0;
					END IF;
				END LOOP;
				IF (a < q * q) THEN -- LSB approximation
					q := q - to_unsigned(1, C_input_half_width);
				ELSIF (a > q * q) THEN
					q := q + to_unsigned(1, C_input_half_width);
				ELSE
					q := q;
				END IF;
				IF (a <= q * q) THEN -- LSB approximation
					q_ufixed(q_ufixed'low) := '0';
				ELSIF (a > q * q) THEN
					q_ufixed(q_ufixed'low) := '1';
				END IF;
			END IF;
			FOR i IN 0 TO q'high LOOP
				q_ufixed(q_ufixed'high - i) := q(q'high - i); -- assign by bit
			END LOOP;
			o1 <= q_ufixed;
		END IF;
	END PROCESS;

END Behavioral;