
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_loopback is 
	generic (number_of_clock_cycles: integer := 18;
			 bitsize : integer := 8;
			samples_per_bit : integer := 3;
			idle_number_of_cycles : integer := 100);
	port( sys_clock: in std_logic;
	 	reset : in std_logic;
	 	tx_line : out std_logic;
	 	tx_active : out std_logic;
	 	transmit_done : out std_logic
	 	);
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

signal tx_line_var : std_logic ; -- Reads output of tx_line.Don't write to it
signal tx_start_transmitting_var : std_logic; -- Write 1 to indicate start of communication
signal tx_active_var : std_logic; -- Reads output.Don't write to it
signal transmit_done_var : std_logic; -- Reads output.Don't write to it

begin
tx_start_transmitting_var <= '1';

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
					 	tx_data_array => "11101000",
					 	tx_line => tx_line_var,
					    tx_start_transmitting => tx_start_transmitting_var,  
					    tx_active =>tx_active_var,
					    transmit_done => transmit_done_var
						);


transmit_done <= transmit_done_var;
tx_line <= tx_line_var;
tx_active <= tx_active_var;
end UART_loopback_architecture ; 