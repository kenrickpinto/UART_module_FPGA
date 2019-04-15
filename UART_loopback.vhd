

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
-- Our clock is 50MHz.To achieve a baud rate of 921,600 kHz our UART clock frequency = 50MHz/921.6kHz = 54(approximately).
--We divide it into two parts.UART clock period = 18 * sys_clock_period and we repeat each bit for 3 cycles of the UART clock.
--This will effectively give us a baud rate of 921.6 kHz.
entity UART_loopback is 
	generic (number_of_clock_cycles: integer := 18; 
			 bitsize : integer := 8;  -- Number of data bits
			samples_per_bit : integer := 3;
			idle_number_of_cycles : integer := 100); -- We wait for idle_number_of_cycles after reset.
	port( sys_clock: in std_logic; -- system clock (50 MHz)
	 	reset : in std_logic; -- Asynchronous active LOW global reset
	 	tx_line : out std_logic;  -- This will be connected to the Rx of the receiver
	 	tx_active : out std_logic; -- High when transmission is taking place.
	 	transmit_done : out std_logic -- High when transmission has been completed.This will help us in not attempting
	 	);							  -- to transmit when a previoustransmit has yet to be completed.	
end entity;

architecture UART_loopback_architecture of UART_loopback is 


component UART_clock_generation is 
	generic (number_of_clock_cycles : integer := 9); 
	port( main_clock: in std_logic;
	 	reset : in std_logic;
	 	uart_clock : out std_logic
		);
end component;

component UART_tx is 
	generic (samples_per_bit : integer := 6;
			bitsize : integer := 5;
			idle_number_of_cycles : integer := 100);
	port( uart_clock: in std_logic;
	 	reset : in std_logic;
	 	tx_data_array : in std_logic_vector(bitsize-1 downto 0);
	 	tx_line : out std_logic;
	    tx_start_transmitting :  in std_logic;
	    tx_active : out std_logic;
	    transmit_done : out std_logic
		);
end component;

signal uart_clock : std_logic;

signal tx_line_var : std_logic ; -- Drives the tx_line
signal tx_start_transmitting_var : std_logic; -- Drive this high to start transmitting
signal tx_active_var : std_logic; -- Reads active status of transmission
signal transmit_done_var : std_logic; 

begin
tx_start_transmitting_var <= '1';  -- We always keep this high so as to achieve continous transmission here.
								   -- We can even make it conditional


x_1 : UART_clock_generation 
		generic map (number_of_clock_cycles => number_of_clock_cycles)
		port map ( main_clock => sys_clock,
		 		   reset => reset,
		 		   uart_clock => uart_clock
			);



x_2 : UART_tx 
			generic map (samples_per_bit => samples_per_bit,
						bitsize => bitsize,
						idle_number_of_cycles => idle_number_of_cycles)
			port map (  reset => reset,
						uart_clock => uart_clock,
					 	tx_data_array => "11101000",                   -- Data bits to be sent
					 	tx_line => tx_line_var,
					    tx_start_transmitting => tx_start_transmitting_var,  
					    tx_active =>tx_active_var,
					    transmit_done => transmit_done_var
						);


transmit_done <= transmit_done_var;
tx_line <= tx_line_var;
tx_active <= tx_active_var;
end UART_loopback_architecture ; 