
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

-- Baud rate = Frequency of uart_clock/samples_per_bit

entity UART_tx is 
	generic (samples_per_bit : integer := 6;
			bitsize : integer := 5;
			idle_number_of_cycles : integer := 1000);
	port(uart_clock: in std_logic;
	 	reset : in std_logic;
	 	tx_data_array : in std_logic_vector(bitsize-1 downto 0);  -- Data array to be transmitted.
	 	tx_line : out std_logic;								  -- Tx of the system
	    tx_start_transmitting :  in std_logic;					  -- Drive high to start transmitting
	    tx_active : out std_logic;								  -- High when transmission is active
	    transmit_done : out std_logic 							  -- High when transmission is completed
		);
end entity;

architecture UART_tx_architecture of UART_tx is 

--We implement UART using a finite state machine on the FPGA
-- Our FSM has five states as listed below
type state_type_tx is (tx_idle,tx_data_bits,tx_start_bit,tx_stop_bit,tx_exit);
signal state : state_type_tx := tx_idle;

begin

process(reset,uart_clock,tx_start_transmitting) 

variable count : integer := 0;  -- Counts the number of cycles elapsed 
variable number_of_bits : integer := 0;--Counts the number of data bits already transmitted
variable idle_number_of_cycles_count : integer := 0;--Counts the number of cycles elapsed after reset

begin

	if(not(reset) = '1' ) then	-- Asyncronous active LOW reset.

		count := 0;				-- Initialize everything to zero upon reset
		number_of_bits := 0;

		state <= tx_idle;		-- Initially in idle state 
		tx_line <= '1';			-- Tx line is high when it's idle.
		tx_active <= '0';
		transmit_done <= '0';
		idle_number_of_cycles_count := 0; -- We have to count up to idle_number_of_cycles before transmitting when
										  -- tx_start_transmitting eventually goes high
	elsif(tx_start_transmitting = '0') then

		count := 0;
		number_of_bits := 0;

		state <= tx_idle;
		tx_line <= '1';
		tx_active <= '0';
		transmit_done <= '0';
		idle_number_of_cycles_count := idle_number_of_cycles;	-- Not a reset so don't wait once tx_start_transmitting
																-- goes high

	elsif(rising_edge(uart_clock)) then
		case(state) is 
			
		when	tx_idle => 	tx_active <= '0';
							transmit_done <='0';
							tx_line <= '1';				-- Line is kept high
						
						if(tx_start_transmitting = '0') then 
							state <= tx_idle;				-- Stay in the same state 
							count := 0;
						else
							if(idle_number_of_cycles_count = idle_number_of_cycles) then   -- If we come from reset we wait 
																						   --before moving ahead
								state <= tx_start_bit;									   -- else we move ahead without waiting 
								count := 0;												   -- to the next state
							else
								idle_number_of_cycles_count := idle_number_of_cycles_count + 1;
						end if;
					end if;

		when	tx_start_bit =>  tx_active <= '1';
								 transmit_done <= '0';
								 tx_line <= '0';						-- UART interprets a low line as start bit  
								if(count = samples_per_bit - 1) then	-- Wait for one baud_rate cycle to elapse
										state <= tx_data_bits;			-- Go to next state
										number_of_bits := 0;
										count := 0;
								 else
								 		count := count + 1;
								 		state <= tx_start_bit;			-- Wait
								 end if;
								

		when 	tx_data_bits => tx_active <= '1';
								tx_line <= tx_data_array(number_of_bits);	-- Number of bits = data bits already sent + 1
								transmit_done <= '0';						-- i.e data bit to be currently sent

								if(count = samples_per_bit - 1) then
									if(number_of_bits = bitsize-1) then		--wait for bitsize(8) bits to be sent before moving
										number_of_bits := 0;				-- to the next state
										state <= tx_stop_bit;
									else
										number_of_bits := number_of_bits+1;
										state <= tx_data_bits;
									end if;
									
									count := 0;
								else
									count := count + 1 ;
									state<= tx_data_bits;
								end if;
								

		when	tx_stop_bit =>  tx_active <= '1';
								tx_line <= '1';			-- UART interprets a high line as a stop bit 
								transmit_done <= '0';
							   if(count = samples_per_bit - 1) then
										state <= tx_exit;
										number_of_bits := 0;
										count := 0;
								 else
								 		count := count + 1;
								 end if;

		when tx_exit => 	tx_active <= '0';	-- This state just exists to keep track of when transmission of 1 byte of 
							tx_line <= '1';		-- data has been successfully sent.
							transmit_done <= '1'; 

							if(count = samples_per_bit - 1) then
										state <= tx_idle;	-- Go back to idle after one baud_rate_cycle
										number_of_bits := 0;
										idle_number_of_cycles_count := idle_number_of_cycles ;
										count := 0;
								 else
								 		count := count + 1;
								 end if;

		when others => state <= tx_idle;


		end case;


	end if;

end process;


end UART_tx_architecture; 