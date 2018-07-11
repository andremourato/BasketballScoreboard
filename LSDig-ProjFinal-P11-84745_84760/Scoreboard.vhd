library IEEE;
use IEEE.STD_LOGIC_1164.all;
use IEEE.NUMERIC_STD.all;
use work.vga_config.all;

entity Scoreboard is

	port(CLOCK_50 : in  std_logic;
		  KEY      : in  std_logic_vector(3 downto 0);
		  HEX7     : out std_logic_vector(6 downto 0);
		  HEX6     : out std_logic_vector(6 downto 0);
		  HEX5     : out std_logic_vector(6 downto 0);
		  HEX4     : out std_logic_vector(6 downto 0);
		  HEX3     : out std_logic_vector(6 downto 0);
		  HEX2     : out std_logic_vector(6 downto 0);
		  HEX1     : out std_logic_vector(6 downto 0);
		  HEX0     : out std_logic_vector(6 downto 0);
		  
		  --VGA PORTS
		  vga_clk     : out std_logic;
		  vga_hs      : out std_logic;
		  vga_vs      : out std_logic;
		  vga_sync_n  : out std_logic;
		  vga_blank_n : out std_logic;
		  vga_r       : out std_logic_vector(7 downto 0);
		  vga_g       : out std_logic_vector(7 downto 0);
		  vga_b       : out std_logic_vector(7 downto 0);
		  
		  -- IR PORTS
		  
		  irda_rxd : in std_logic);

end Scoreboard;

architecture Shell of Scoreboard is 
	
  -- Scoreboards signals
  
  signal s_key0,s_key1,s_key2,s_key3 : std_logic; -- Clean keys after debounce unit
  signal s_clk_1HZ   					 : std_logic; -- Clock with frequency of 1 hz
  signal s_count_period 			    : std_logic_vector(7 downto 0);
  signal end_of_period					 : std_logic;
  signal end_of_game    				 : std_logic;
  
  -- HOME SIGNALS
  signal s_count_local 				  : std_logic_vector(7 downto 0); -- Local fouls
  signal bcd_MS_local,bcd_LS_local : std_logic_vector(3 downto 0); -- Local fouls Bits
  signal s_count_score_local 		  : std_logic_vector(7 downto 0); -- Local Score
  signal bcd_LS_score_local 		  : std_logic_vector(3 downto 0); -- Local Score Lest Significant Bit
  signal bcd_Mid_score_local 		  : std_logic_vector(3 downto 0); -- Local Score Middle Bit
  signal bcd_MS_score_local 		  : std_logic_vector(3 downto 0); -- Local Score Most Significant Bit
  
  -- GUEST SIGNALS
  signal s_count_visit 				  : std_logic_vector(7 downto 0); -- Visit fouls
  signal bcd_MS_visit,bcd_LS_visit : std_logic_vector(3 downto 0); -- Visit fouls Bits
  signal s_count_score_visit 		  : std_logic_vector(7 downto 0); -- Visit Score
  signal bcd_LS_score_visit 		  : std_logic_vector(3 downto 0); -- Visit Score Lest Significant Bit
  signal bcd_Mid_score_visit 		  : std_logic_vector(3 downto 0); -- Visit Score Middle Bit
  signal bcd_MS_score_visit 		  : std_logic_vector(3 downto 0); -- Visit Score Most Significant Bit
  
  -- TIMER SIGNAL
  signal s_count_timer : std_logic_vector(15 downto 0); -- Current time
	
  
  -- Phase 2 VGA signals
	
	
  constant clock_frequency : real := vga_frequency;
  signal clock : std_logic;
  
  -- the VGA stuff
  constant xm_coord  	: integer := 12;             -- x coordinate of the leftmost pixel of the main window
  constant xs_coord  	: integer := xm_coord+512+8; -- x coordinate of the leftmost pixel of the side window
  constant y_coord   	: integer := 76;             -- y coordinate of the bottom pixel of the two windows
  constant border_size  : integer := 5;				  -- Outline of the rectangles
  signal vga_data_0  	: vga_data_t;
  signal vga_data_1  	: vga_data_t;
  signal vga_data_2  	: vga_data_t;
  signal vga_rgb_0   	: vga_rgb_t;
  signal border_1    	: std_logic;       		    -- '1' when border
  signal guest_score 	: std_logic;
  signal home_score  	: std_logic;
  signal guest_fouls		: std_logic;
  signal home_fouls 		: std_logic;          					
  signal timer_display  : std_logic;
  signal period_display : std_logic;
  -- Borders
  signal s_border_home_0 : std_logic;
  signal s_border_home_1 : std_logic;
  signal s_border_visit_0: std_logic;
  signal s_border_visit_1: std_logic;
  signal s_border_timer  : std_logic;
  signal s_border_period : std_logic;
  -- Letters
  signal s_letter_row   : std_logic_vector(3 downto 0);
  signal s_letter_column: std_logic_vector(3 downto 0);
  signal s_char         : std_logic_vector(6 downto 0);
  signal s_char_1       : std_logic_vector(6 downto 0);
  signal s_char_2       : std_logic_vector(6 downto 0);
  signal s_char_3                     : std_logic_vector(6 downto 0);
  signal s_timer_digit_row 			  : std_logic_vector(3 downto 0);
  signal s_timer_digit_column 		  : std_logic_vector(3 downto 0);
  signal s_score_digit_row 			  : std_logic_vector(3 downto 0);
  signal s_score_digit_column 		  : std_logic_vector(3 downto 0);
  signal s_fouls_period_digit_row     : std_logic_vector(3 downto 0);
  signal s_fouls_period_digit_column  : std_logic_vector(3 downto 0);
  signal s_fouls_period_display 	     : std_logic;
  signal s_timer_display				  : std_logic;
  signal s_score_display				  : std_logic;
  signal m_inside_1  	: std_logic;                 -- '1' when inside main window
  signal s_inside_1  	: std_logic;                 -- '1' when inside side window
  signal outside_1   	: std_logic;                 -- '1' when outside 800x600 area
  signal y_1        	   : unsigned(8 downto 0);      -- y coordinate relative to the bottom of the main window
  
  --letters
  signal s_letters :std_logic;
  
  --Phase 3 IR 
  
  signal data           	: std_logic_vector(31 downto 0); -- received command
  signal valid          	: std_logic;                     -- received command valid pulse
  signal fouls_guest_IR 	: std_logic;
  signal fouls_home_IR  	: std_logic;  
  signal score_home_IR_1	: std_logic;
  signal score_home_IR_2	: std_logic; 
  signal score_home_IR_3	: std_logic;
  signal score_guest_IR_1	: std_logic; 
  signal score_guest_IR_2	: std_logic;
  signal score_guest_IR_3	: std_logic;  
  signal channel_up_IR   	: std_logic;
  signal return_IR       	: std_logic;
  signal s_startgame       : std_logic;
  signal s_startgame_reg   : std_logic;

	
begin

-- IR Entity

  ir : entity work.ir_nec_decoder(v1)
		  generic map(clock_frequency => clock_frequency)
		  port map(clock => clock,
					  irda_rxd => irda_rxd,
					  data => data,
					  valid => valid);

-- VGA Entities


  clk : entity work.vga_clock_generator(v1)
              port map(clock_50 => clock_50,vga_clock => clock);
	
  vc : entity work.vga_controller(v1)
              port map(clock => clock,reset => '0',vga_data_0 => vga_data_0);
				  
  vo : entity work.vga_output(v1)
              port map(clock => clock,
                       vga_data => vga_data_0,vga_rgb => vga_rgb_0,
                       vga_clk => vga_clk,
                       vga_hs => vga_hs,vga_vs => vga_vs,vga_sync_n => vga_sync_n,vga_blank_n => vga_blank_n,
                       vga_r => vga_r,vga_g => vga_g,vga_b => vga_b);
							  
	-- Letters and Digits Entities
  letter_FONT : entity work.font_16x16_bold(v1)
				port map(clock =>clock,
							char_0=>s_char, 
							row_0=>s_letter_row,    
							column_0=>s_letter_column, 
							data_1=>s_letters);
							
	s_digits_FONT : entity work.font_16x16_bold(v1)
				port map(clock =>clock,
							char_0=>s_char_1, 
							row_0=>s_timer_digit_row,    
							column_0=>s_timer_digit_column, 
							data_1=>s_timer_display);
	
	score_digits_FONT : entity work.font_16x16_bold(v1)
				port map(clock =>clock,
							char_0=>s_char_2, 
							row_0=>s_score_digit_row,    
							column_0=>s_score_digit_column, 
							data_1=>s_score_display);
							
							
	fouls_period_digits_FONT : entity work.font_16x16_bold(v1)
				port map(clock =>clock,
							char_0=>s_char_3, 
							row_0=>s_fouls_period_digit_row,    
							column_0=>s_fouls_period_digit_column, 
							data_1=>s_fouls_period_display);
	
-- Debounce Units

DebounceUnit_0 : entity work.DebounceUnit(Behavioral)
	port map(refClk    => CLOCK_50,
				dirtyIn   => not KEY(0),
				pulsedOut => s_key0);

DebounceUnit_1 : entity work.DebounceUnit(Behavioral)
	port map(refClk    => CLOCK_50,
				dirtyIn   => not KEY(1),
				pulsedOut => s_key1);

DebounceUnit_2 : entity work.DebounceUnit(Behavioral)
	port map(refClk    => CLOCK_50,
				dirtyIn   => not KEY(2),
				pulsedOut => s_key2);

DebounceUnit_3 : entity work.DebounceUnit(Behavioral)
	port map(refClk    => CLOCK_50,
				dirtyIn   => not KEY(3),
				pulsedOut => s_key3);
-- Scoreboard
					 
counterUp_period : entity work.CounterUp(Behavioral)
		generic map(N => 4, M =>1)
		port map (clk   => CLOCK_50,
					 start_1 => end_of_period and channel_up_IR,
					 start_2=>'0',
					 start_3=>'0',
					 reset => end_of_game and return_IR, 
					 count => s_count_period);

counterUp_visit_fouls : entity work.CounterUp(Behavioral)
		port map (clk   => CLOCK_50,
					 start_1 => (s_key1 or fouls_guest_IR) and (not end_of_game and not end_of_period and s_startgame_reg),
					 start_2=>'0',
					 start_3=>'0',
					 reset => end_of_game and return_IR, 
					 count => s_count_visit);
				
counterUp_local_fouls : entity work.CounterUp(Behavioral)
		port map (clk=>CLOCK_50,
					 start_1 => (s_key0 or fouls_home_IR) and (not end_of_game and not end_of_period and s_startgame_reg),
					 start_2 =>'0',
					 start_3 =>'0',
					 reset => end_of_game and return_IR, 
					 count => s_count_local);

counterUp_score_guest : entity work.CounterUp(Behavioral)
		generic map(N =>255)
		port map (clk   => CLOCK_50,
					 start_1 => (s_key2 or score_guest_IR_1) and (not end_of_game and not end_of_period and s_startgame_reg),
					 start_2 => score_guest_IR_2 and (not end_of_game and not end_of_period and s_startgame_reg),
					 start_3 => score_guest_IR_3 and (not end_of_game and not end_of_period and s_startgame_reg),
					 reset => end_of_game and return_IR, 
					 count => s_count_score_visit);
				
counterUp_score_home : entity work.CounterUp(Behavioral)
		generic map(N =>255)
		port map (clk=>CLOCK_50,
					 start_1 => (s_key3 or score_home_IR_1) and (not end_of_game and not end_of_period and s_startgame_reg),
					 start_2 => score_home_IR_2 and (not end_of_game and not end_of_period and s_startgame_reg),
					 start_3 => score_home_IR_3 and (not end_of_game and not end_of_period and s_startgame_reg),
					 reset => end_of_game and return_IR, 
					 count => s_count_score_local);
					 
Bin2BCD_local : entity work.Bin2BCD(Behavioral)
		port map (binIn => s_count_local,
					 bcdMS => bcd_MS_local,
					 bcdLS => bcd_LS_local);


Bin2BCD_visit : entity work.Bin2BCD(Behavioral)
		port map (binIn => s_count_visit,
					 bcdMS => bcd_MS_visit,
					 bcdLS => bcd_LS_visit);
					 
Bin2BCD_local_score : entity work.Bin2BCD_3Digits(Behavioral)
		port map (binIn => s_count_score_local,
					 bcdMS => bcd_MS_score_local,
					 bcdMid=> bcd_Mid_score_local,
					 bcdLS => bcd_LS_score_local);


Bin2BCD_visit_score : entity work.Bin2BCD_3Digits(Behavioral)
		port map (binIn => s_count_score_visit,
					 bcdMS => bcd_MS_score_visit,
					 bcdMid=> bcd_Mid_score_visit,	
					 bcdLS => bcd_LS_score_visit);

-- Time counter
register_enable_counter : entity work.Reg1(Behavioral)
		port map(asyncReset => end_of_period or end_of_game,
					clk        => CLOCK_50,			 
					enable	  => s_startgame,
					dataIn	  => '1',
					dataOut	  => s_startgame_reg);
				 
cntBCD_Down4 : entity work.cntBCDDown4(Behavioral)
		generic map(N => x"0010")
		port map (reset  => (end_of_period and channel_up_IR) or (end_of_game and return_IR),
					 clk    => s_clk_1HZ,
					 enable => s_startgame_reg, 
					 count  => s_count_timer);
					 			 
clockDivider_1HZ: entity work.ClkDividerN(Behavioral)
		port map (clkIn  => CLOCK_50,
					 clkOut => s_clk_1HZ);
					 
Bin7Decoder_0:  entity work.Bin7SegDecoder(Behavioral)
		port map(binInput => s_count_timer(3 downto 0),
					enable   => '1',
					decOut_n => HEX0);
		
					 
Bin7Decoder_1:  entity work.Bin7SegDecoder(Behavioral)
		port map(binInput => s_count_timer(7 downto 4),
					enable   => '1',
					decOut_n => HEX1);
		
					 
Bin7Decoder_2:  entity work.Bin7SegDecoder(Behavioral)
		port map(binInput => s_count_timer(11 downto 8),
					enable   => '1',
					decOut_n => HEX2);

Bin7Decoder_3:  entity work.Bin7SegDecoder(Behavioral)
		port map(binInput => s_count_timer(15 downto 12),
					enable   => '1',
					decOut_n => HEX3);
					
--  Display of both local and visit scores'
					
Bin7Decoder_4:  entity work.Bin7SegDecoder(Behavioral)
		port map(binInput => bcd_MS_visit,
					enable   => '1',
					decOut_n => HEX7);
		
					 
Bin7Decoder_5:  entity work.Bin7SegDecoder(Behavioral)
		port map(binInput => bcd_LS_visit,
					enable   => '1',
					decOut_n => HEX6);
		
					 
Bin7Decoder_6:  entity work.Bin7SegDecoder(Behavioral)
		port map(binInput => bcd_MS_local,
					enable   => '1',
					decOut_n => HEX5);

Bin7Decoder_7:  entity work.Bin7SegDecoder(Behavioral)
		port map(binInput => bcd_LS_local,
					enable   => '1',
					decOut_n => HEX4);
					
-- VGA Implementation

	delay : process(clock) is
	begin
		if rising_edge(clock) then
			vga_data_1 <= vga_data_0;
			vga_data_2 <= vga_data_1;
		end if;
	end process;
	
	sequential : process(clock) is
	begin
		if rising_edge(clock) then
			border_1 <= '0'; -- not in border by default
			guest_score <= '0'; -- no guest score rectangle by default
			home_score <= '0'; -- no home score rectangle by default
			guest_fouls <= '0'; -- no guest fouls rectangle by default
			home_fouls <= '0'; -- no home fouls rectangle by default
			timer_display <= '0'; -- no timer rectangle by default
			period_display <= '0'; -- no period rectangle by default
			s_border_home_0 <= '0';
			s_border_home_1 <= '0';
			s_border_visit_0 <= '0';
			s_border_visit_1 <= '0';
			s_border_timer   <= '0';
			s_border_period  <= '0';
			
			
			if vga_data_0.x < 4 or vga_data_0.x >= vga_width-4 or vga_data_0.y < 4 or vga_data_0.y >= vga_height-4 then
				border_1 <= '1'; -- in border
			
			--###################LETTERS#####################--
			
			--GUEST
			
			-- G
			elsif(vga_data_0.x>=50  and vga_data_0.x<=82  and vga_data_0.y>=82 and vga_data_0.y<=114) then
				s_char<="1000111";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 82)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - 50)/2,4));
			
			-- U
			elsif(vga_data_0.x>=82  and vga_data_0.x<=114  and vga_data_0.y>=82 and vga_data_0.y<=114) then
				s_char<="1010101";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 82)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - 82)/2,4));
		
			-- E
			elsif(vga_data_0.x>=114  and vga_data_0.x<=146  and vga_data_0.y>=82 and vga_data_0.y<=114) then
				s_char<="1000101";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 82)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - 114)/2,4));
			
			-- S
			elsif(vga_data_0.x>=146  and vga_data_0.x<=178  and vga_data_0.y>=82 and vga_data_0.y<=114) then
				s_char<="1010011";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 82)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - 146)/2,4));
			
			-- T
			elsif(vga_data_0.x>=178  and vga_data_0.x<=210  and vga_data_0.y>=82 and vga_data_0.y<=114) then
				s_char<="1010100";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 82)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - 178)/2,4));
			
			--HOME
			
			-- H
			elsif(vga_data_0.x<=vga_width - 157  and vga_data_0.x>=vga_width - 189  and vga_data_0.y>= 82 and vga_data_0.y<=114) then
				s_char<="1001000";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 82)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - (vga_width - 157))/2,4));
			-- O
			elsif(vga_data_0.x<=vga_width - 125  and vga_data_0.x>=vga_width - 157  and vga_data_0.y>= 82 and vga_data_0.y<=114) then
				s_char<="1001111";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 82)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - (vga_width - 125))/2,4));
			
			-- M
         elsif(vga_data_0.x<=vga_width - 93  and vga_data_0.x>=vga_width - 125  and vga_data_0.y>= 82 and vga_data_0.y<=114) then
				s_char<="1001101";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 82)/2,4));
            s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - (vga_width - 93))/2,4));
			
			-- E
			elsif(vga_data_0.x<=vga_width - 61  and vga_data_0.x>=vga_width - 93  and vga_data_0.y>= 82 and vga_data_0.y<=114) then
				s_char<="1000101";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 82)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - (vga_width - 61))/2,4));
			
			--FOULS_GUEST
			
			-- F
			elsif(vga_data_0.x>=77  and vga_data_0.x<=109  and vga_data_0.y<=vga_height-68 and vga_data_0.y>=vga_height-100) then
				s_char<="1000110";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 82)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - 77)/2,4));
		
			-- O
			elsif(vga_data_0.x>=109  and vga_data_0.x<=141  and vga_data_0.y<=vga_height-68 and vga_data_0.y>=vga_height-100) then
				s_char<="1001111";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 82)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - 109)/2,4));
			
			-- U
			elsif(vga_data_0.x>=141  and vga_data_0.x<=173  and vga_data_0.y<=vga_height-68 and vga_data_0.y>=vga_height-100) then
				s_char<="1010101";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 82)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - 141)/2,4));
			
			-- L
			elsif(vga_data_0.x>=173  and vga_data_0.x<=205  and vga_data_0.y<=vga_height-68 and vga_data_0.y>=vga_height-100) then
				s_char<="1001100";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 82)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - 173)/2,4));
			
			-- S
			elsif(vga_data_0.x>=205  and vga_data_0.x<=237  and vga_data_0.y<=vga_height-68 and vga_data_0.y>=vga_height-100) then
				s_char<="1010011";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 82)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - 205)/2,4));
				
			--FOULS_HOME
			
			-- F
			elsif(vga_data_0.x<=vga_width-205 and vga_data_0.x>=vga_width-237  and vga_data_0.y<=vga_height-68 and vga_data_0.y>=vga_height-100) then
				s_char<="1000110";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 82)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x-(vga_width-237))/2,4));
				
			-- O
			elsif(vga_data_0.x<=vga_width-173 and vga_data_0.x>=vga_width-205  and vga_data_0.y<=vga_height-68 and vga_data_0.y>=vga_height-100) then
				s_char<="1001111";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 82)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - (vga_width-205))/2,4));

			-- U
			elsif(vga_data_0.x<=vga_width-141 and vga_data_0.x>=vga_width-173  and vga_data_0.y<=vga_height-68 and vga_data_0.y>=vga_height-100) then
				s_char<="1010101";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 82)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - (vga_width-173))/2,4));
			
			-- L
			elsif(vga_data_0.x<=vga_width-109 and vga_data_0.x>=vga_width-141  and vga_data_0.y<=vga_height-68 and vga_data_0.y>=vga_height-100) then
				s_char<="1001100";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 82)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - (vga_width-141))/2,4));
			
			-- S
			elsif(vga_data_0.x<=vga_width-77 and vga_data_0.x>=vga_width-109  and vga_data_0.y<=vga_height-68 and vga_data_0.y>=vga_height-100) then
				s_char<="1010011";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 82)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - (vga_width-109))/2,4));
			
				
			--PERIOD
			
			-- P
			elsif(vga_data_0.x>=304 and vga_data_0.x<=336  and vga_data_0.y>=450 and vga_data_0.y<=482) then
				s_char<="1010000";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 450)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x- 304)/2,4));
				
			-- E
			elsif(vga_data_0.x>=336 and vga_data_0.x<=368 and vga_data_0.y>=450 and vga_data_0.y<=482) then
				s_char<="1000101";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 450)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - 336)/2,4));

			-- R
			elsif(vga_data_0.x>=368 and vga_data_0.x<=400  and vga_data_0.y>=450 and vga_data_0.y<=482) then
				s_char<="1010010";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 450)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - 368)/2,4));
			
			-- I
			elsif(vga_data_0.x>=400 and vga_data_0.x<=432  and vga_data_0.y>=450 and vga_data_0.y<=482) then
				s_char<="1001001";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 450)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - 400)/2,4));
			
			-- O
			elsif(vga_data_0.x>=432 and vga_data_0.x<=464  and vga_data_0.y>=450 and vga_data_0.y<=482) then
				s_char<="1001111";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 450)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - 432)/2,4));
			
			-- D
			elsif(vga_data_0.x>=464 and vga_data_0.x<=496  and vga_data_0.y>=450 and vga_data_0.y<=482) then
				s_char<="1000100";
				s_letter_row <= std_logic_vector(to_unsigned((vga_data_0.y - 450)/2,4));
				s_letter_column <= std_logic_vector(to_unsigned((vga_data_0.x - 464)/2,4));
			
			-- TIMER DIGITS
			-- DIGIT 0 (RIGHT MOST)
			elsif(vga_data_0.x>=496 and vga_data_0.x<=560  and vga_data_0.y>=93 and vga_data_0.y<=157) then
				s_char_1<="011"& s_count_timer(3 downto 0); 
				s_timer_digit_row <= std_logic_vector(to_unsigned((vga_data_0.y - 93)/4,4));
				s_timer_digit_column <= std_logic_vector(to_unsigned((vga_data_0.x - 496)/4,4));
			
			-- DIGIT 1
			elsif(vga_data_0.x>=432 and vga_data_0.x<=496  and vga_data_0.y>=93 and vga_data_0.y<=157) then
				s_char_1<="011"& s_count_timer(7 downto 4); 
				s_timer_digit_row <= std_logic_vector(to_unsigned((vga_data_0.y - 93)/4,4));
				s_timer_digit_column <= std_logic_vector(to_unsigned((vga_data_0.x - 432)/4,4));
			
			-- :
			elsif(vga_data_0.x>=368 and vga_data_0.x<=432  and vga_data_0.y>=93 and vga_data_0.y<=157) then
				s_char_1<="0111010"; 
				s_timer_digit_row <= std_logic_vector(to_unsigned((vga_data_0.y - 93)/4,4));
				s_timer_digit_column <= std_logic_vector(to_unsigned((vga_data_0.x - 368)/4,4));
				
			-- DIGIT 2
			elsif(vga_data_0.x>=304 and vga_data_0.x<=368  and vga_data_0.y>=93 and vga_data_0.y<=157) then
				s_char_1<="011"& s_count_timer(11 downto 8); 
				s_timer_digit_row <= std_logic_vector(to_unsigned((vga_data_0.y - 93)/4,4));
				s_timer_digit_column <= std_logic_vector(to_unsigned((vga_data_0.x - 304)/4,4));
				
			-- DIGIT 3 (LEFT MOST)
			elsif(vga_data_0.x>=240 and vga_data_0.x<=304  and vga_data_0.y>=93 and vga_data_0.y<=157) then
				s_char_1<="011"& s_count_timer(15 downto 12); 
				s_timer_digit_row <= std_logic_vector(to_unsigned((vga_data_0.y - 93)/4,4));
				s_timer_digit_column <= std_logic_vector(to_unsigned((vga_data_0.x - 240)/4,4));
				
			--GUEST SCORE DIGITS
			
			-- DIGIT 0(RIGHT MOST)
			elsif(vga_data_0.x>=149 and vga_data_0.x<=197  and vga_data_0.y>=201 and vga_data_0.y<=249) then
				s_char_2<="011"& bcd_LS_score_local;
				s_score_digit_row <= std_logic_vector(to_unsigned((vga_data_0.y - 201)/3,4));
				s_score_digit_column <= std_logic_vector(to_unsigned((vga_data_0.x - 149)/3,4));
				
			-- DIGIT 1
			elsif(vga_data_0.x>=101 and vga_data_0.x<=149  and vga_data_0.y>=201 and vga_data_0.y<=249) then
				s_char_2<="011"& bcd_Mid_score_local; 
				s_score_digit_row <= std_logic_vector(to_unsigned((vga_data_0.y - 201)/3,4));
				s_score_digit_column <= std_logic_vector(to_unsigned((vga_data_0.x - 101)/3,4));
				
			-- DIGIT 2(LEFT MOST)
			elsif(vga_data_0.x>=53 and vga_data_0.x<=101  and vga_data_0.y>=201 and vga_data_0.y<=249) then
				s_char_2<="011"& bcd_MS_score_local;
				s_score_digit_row <= std_logic_vector(to_unsigned((vga_data_0.y - 201)/3,4));
				s_score_digit_column <= std_logic_vector(to_unsigned((vga_data_0.x - 53)/3,4));
			
			
			--HOME SCORE DIGITS
			
			-- DIGIT 2(LEFT MOST)
			elsif(vga_data_0.x<=vga_width-149 and vga_data_0.x>=vga_width-197  and vga_data_0.y>=201 and vga_data_0.y<=249) then
				s_char_2<="011"& bcd_MS_score_visit; 
				s_score_digit_row <= std_logic_vector(to_unsigned((vga_data_0.y - 201)/3,4));
				s_score_digit_column <= std_logic_vector(to_unsigned((vga_data_0.x - (vga_width-149))/3,4));
				
			-- DIGIT 1
			elsif(vga_data_0.x<=vga_width-101 and vga_data_0.x>=vga_width-149  and vga_data_0.y>=201 and vga_data_0.y<=249) then
				s_char_2<="011"& bcd_Mid_score_visit; 
				s_score_digit_row <= std_logic_vector(to_unsigned((vga_data_0.y - 201)/3,4));
				s_score_digit_column <= std_logic_vector(to_unsigned((vga_data_0.x -(vga_width- 101))/3,4));
				
			-- DIGIT 0(RIGHT MOST)
			elsif(vga_data_0.x<=vga_width-53 and vga_data_0.x>=vga_width-101  and vga_data_0.y>=201 and vga_data_0.y<=249) then
				s_char_2<="011"& bcd_LS_score_visit; 
				s_score_digit_row <= std_logic_vector(to_unsigned((vga_data_0.y - 201)/3,4));
				s_score_digit_column <= std_logic_vector(to_unsigned((vga_data_0.x -(vga_width- 53))/3,4));
				
			--GUEST fouls DIGITS
			
			-- DIGIT 0(RIGHT MOST)
			elsif(vga_data_0.x>=150 and vga_data_0.x<=198  and vga_data_0.y>=vga_height-224 and vga_data_0.y<=vga_height-176) then
				s_char_3<="011"& bcd_LS_visit; 
				s_fouls_period_digit_row <= std_logic_vector(to_unsigned((vga_data_0.y - (vga_height-224))/3,4));
				s_fouls_period_digit_column <= std_logic_vector(to_unsigned((vga_data_0.x - 150)/3,4));
					
			-- DIGIT 1(LEFT MOST)
			elsif(vga_data_0.x>=102 and vga_data_0.x<=150  and vga_data_0.y>=vga_height-224 and vga_data_0.y<=vga_height-176) then
				s_char_3<="011"& bcd_MS_visit; 
				s_fouls_period_digit_row <= std_logic_vector(to_unsigned((vga_data_0.y - (vga_height-224))/3,4));
				s_fouls_period_digit_column <= std_logic_vector(to_unsigned((vga_data_0.x - 102)/3,4));
			
			--HOME fouls DIGITS
			
			-- DIGIT 1(LEFT MOST)
			elsif(vga_data_0.x>=vga_width-198 and vga_data_0.x<=vga_width-150 and vga_data_0.y>=vga_height-224 and vga_data_0.y<=vga_height-176) then
				s_char_3<="011"& bcd_MS_local; 
				s_fouls_period_digit_row <= std_logic_vector(to_unsigned((vga_data_0.y - (vga_height-224))/3,4));
				s_fouls_period_digit_column <= std_logic_vector(to_unsigned((vga_data_0.x - (vga_width-150))/3,4));
				
			-- DIGIT 0(RIGHT MOST)
			elsif(vga_data_0.x>=vga_width-150 and vga_data_0.x<=vga_width-102 and vga_data_0.y>=vga_height-224 and vga_data_0.y<=vga_height-176) then
				s_char_3<="011"& bcd_LS_local; 
				s_fouls_period_digit_row <= std_logic_vector(to_unsigned((vga_data_0.y - (vga_height-224))/3,4));
				s_fouls_period_digit_column <= std_logic_vector(to_unsigned((vga_data_0.x -(vga_width-102))/3,4));
			
			-- PERIOD DIGITS
			
			elsif(vga_data_0.x>=376 and vga_data_0.x<=424  and vga_data_0.y>=326 and vga_data_0.y<=374) then
				s_char_3<="011"& s_count_period(3 downto 0); 
				s_fouls_period_digit_row <= std_logic_vector(to_unsigned((vga_data_0.y - 326)/3,4));
				s_fouls_period_digit_column <= std_logic_vector(to_unsigned((vga_data_0.x - 376)/3,4));
			
			
			end if;	
				
			--###################BACKGROUND RECTANGLES#####################--
			
			-- GUEST SCORE
			if(vga_data_0.x>=50  and vga_data_0.x<=200  and vga_data_0.y>=150 and vga_data_0.y<=300) then
				if(s_score_display = '0') then
					guest_score<='1';
				end if;			
			
			-- HOME SCORE
			elsif(vga_data_0.x<=vga_width-50  and vga_data_0.x>=vga_width-200  
			and vga_data_0.y>=150 and vga_data_0.y<=300) then
				if(s_score_display = '0') then
					home_score<='1';
				end if;
			
			-- GUEST fouls
			elsif(vga_data_0.x>=100  and vga_data_0.x<=200  and
			vga_data_0.y<=vga_height-150 and vga_data_0.y>=vga_height-250) then
				if(s_fouls_period_display = '0') then
					guest_fouls<='1';
				end if;			
			-- HOME fouls
			elsif(vga_data_0.x<=vga_width-100  and vga_data_0.x>=vga_width-200  and
			vga_data_0.y<=vga_height-150 and vga_data_0.y>=vga_height-250) then
				if(s_fouls_period_display = '0') then
					home_fouls<='1';
				end if;
			
			-- TIMER DISPLAY	
			elsif(vga_data_0.x>=245  and vga_data_0.x<=vga_width-245  and vga_data_0.y>=50 and vga_data_0.y<=200) then
				if(s_timer_display = '0') then
					timer_display <= '1';
				end if;
					
			-- PERIOD DISPLAY
			elsif(vga_data_0.x>=350  and vga_data_0.x<=450  and vga_data_0.y>=300 and vga_data_0.y<=400) then
				if(s_fouls_period_display = '0') then
					period_display <= '1';
				end if;
				
			--################BORDERS##################--	
			
			-- HOME SCORE BORDER
			elsif(vga_data_0.x<=vga_width-50+border_size  and vga_data_0.x>=vga_width-200-border_size  
			and vga_data_0.y>=150-border_size and vga_data_0.y<=300+border_size) then
				if(s_score_display = '0' and home_score = '0') then
					s_border_home_0 <= '1';
				end if;
			
			-- HOME FOULS
			elsif (vga_data_0.x<=vga_width-100+border_size and vga_data_0.x>=vga_width-200-border_size and
			vga_data_0.y<=vga_height-150+border_size and vga_data_0.y>=vga_height-250-border_size) then
				if(s_fouls_period_display = '0' and home_fouls ='0') then
					s_border_home_1 <= '1';
				end if;
				
			--GUEST SCORE BORDER
			elsif(vga_data_0.x>=50-border_size  and vga_data_0.x<=200+border_size
			and vga_data_0.y>=150-border_size and vga_data_0.y<=300+border_size) then
				if(s_score_display = '0' and guest_score = '0') then
					s_border_visit_0 <= '1';
				end if;
			
			--GUEST FOULS BORDER
			elsif(vga_data_0.x>=100-border_size  and vga_data_0.x<=200+border_size  and
			vga_data_0.y<=vga_height-150+border_size and vga_data_0.y>=vga_height-250-border_size) then
				if(s_fouls_period_display = '0' and guest_fouls = '0') then
					s_border_visit_1 <= '1';
				end if;
			
			-- TIMER BORDER
			elsif(vga_data_0.x>=245-border_size and vga_data_0.x<=vga_width-245+border_size
			and vga_data_0.y>=50-border_size and vga_data_0.y<=200+border_size) then
				if(s_timer_display = '0' and timer_display = '0') then
					s_border_timer <= '1';
				end if;
			
			-- PERIOD BORDER
			elsif(vga_data_0.x>=350-border_size and vga_data_0.x<=450+border_size
			and vga_data_0.y>=300-border_size and vga_data_0.y<=400+border_size) then
				if(s_timer_display = '0' and timer_display = '0') then
					s_border_timer <= '1';
				end if;
			
			end if;
			
			--#######################################--
			
			vga_rgb_0.r <= x"24"; vga_rgb_0.g <= x"76"; vga_rgb_0.b <= x"9E"; -- blue by default
			if border_1 = '1' then
				vga_rgb_0.r <= x"FF"; vga_rgb_0.g <= x"FF"; vga_rgb_0.b <= x"FF"; -- the border is white
				
			elsif guest_score = '1' then -- colors of score retangle of the guest team
				vga_rgb_0.r <= x"00";
				vga_rgb_0.g <= x"00";
				vga_rgb_0.b <= x"00";
				
			elsif home_score ='1' then   -- colors of score retangle of the home team
				vga_rgb_0.r <= x"00";
				vga_rgb_0.g <= x"00";
				vga_rgb_0.b <= x"00";
				
			elsif guest_fouls = '1' then -- colors of fouls retangle of the guest team
				vga_rgb_0.r <= x"00";
				vga_rgb_0.g <= x"00";
				vga_rgb_0.b <= x"00";
				
			elsif home_fouls ='1' then   -- colors of fouls retangle of the home team
				vga_rgb_0.r <= x"00";
				vga_rgb_0.g <= x"00";
				vga_rgb_0.b <= x"00";
				
			elsif timer_display = '1' then -- colors of timer background
				vga_rgb_0.r <= x"00";
				vga_rgb_0.g <= x"00";
				vga_rgb_0.b <= x"00";
				
			elsif period_display ='1' then   -- colors of period retangle to the home team
				vga_rgb_0.r <= x"00";
				vga_rgb_0.g <= x"00";
				vga_rgb_0.b <= x"00";
				
			elsif s_timer_display = '1' then -- color of the digits in the timer
				if(s_clk_1HZ = '1' and end_of_game = '1') then
					vga_rgb_0.r <= x"00";
					vga_rgb_0.g <= x"00";
					vga_rgb_0.b <= x"00";
				else
					vga_rgb_0.r <= x"FF";
					vga_rgb_0.g <= x"00";
					vga_rgb_0.b <= x"00";
				end if;
				
			elsif s_score_display ='1' then -- color of the digits in the score
				vga_rgb_0.r <= x"FF";
				vga_rgb_0.g <= x"FF";
				vga_rgb_0.b <= x"33";
				
			elsif s_fouls_period_display = '1' then -- color of the digits in the fouls and display
				vga_rgb_0.r <= x"00";
				vga_rgb_0.g <= x"F0";
				vga_rgb_0.b <= x"00";
				
			elsif s_letters = '1' then
				vga_rgb_0.r <= x"FF";
				vga_rgb_0.g <= x"FF";
				vga_rgb_0.b <= x"FF";
				
			-- BORDERS
			
			elsif s_border_visit_0 = '1' then -- VISIT SCORE BORDER
				vga_rgb_0.r <= x"FF";
				vga_rgb_0.g <= x"FF";
				vga_rgb_0.b <= x"FF";
				
			elsif s_border_visit_1 = '1' then -- VISIT FOULS BORDER
				vga_rgb_0.r <= x"FF";
				vga_rgb_0.g <= x"FF";
				vga_rgb_0.b <= x"FF";
			
			elsif s_border_home_0 = '1' then -- HOME SCORE BORDER
				vga_rgb_0.r <= x"FF";
				vga_rgb_0.g <= x"FF";
				vga_rgb_0.b <= x"FF";
			
			elsif s_border_home_1 = '1' then -- HOME FOULS BORDER
				vga_rgb_0.r <= x"FF";
				vga_rgb_0.g <= x"FF";
				vga_rgb_0.b <= x"FF";
			
			elsif s_border_period = '1' then -- PERIOD BORDER
				vga_rgb_0.r <= x"FF";
				vga_rgb_0.g <= x"FF";
				vga_rgb_0.b <= x"FF";
				
			elsif s_border_timer = '1' then -- TIMER BORDER
				vga_rgb_0.r <= x"FF";
				vga_rgb_0.g <= x"FF";
				vga_rgb_0.b <= x"FF";
			end if;
			
			-- Phase 3 -IR 
			fouls_guest_IR   <='0';
			fouls_home_IR    <='0';
			score_guest_IR_1 <='0';
			score_guest_IR_2 <='0';
			score_guest_IR_3 <='0';
			score_home_IR_1  <='0';
			score_home_IR_2  <='0';
			score_home_IR_3  <='0';
			channel_up_IR    <='0';
			return_IR        <='0';
			s_startgame      <='0';
			
			if(valid = '1') then
				if(data=x"EB_14_6B_86") then     -- Fouls Guest (Adjust Left)
					fouls_guest_IR<='1';
				elsif(data=x"E7_18_6B_86") then	-- Fouls Home (Adjust Right)
					fouls_home_IR<= '1';
				elsif(data=x"FB_04_6B_86") then  -- Count Guest (button "4")
					score_guest_IR_1<='1';
				elsif(data=x"FA_05_6B_86") then 	-- Count Guest (button "5")
					score_guest_IR_2<='1';
				elsif(data=x"F9_06_6B_86") then 	-- Count Guest (button "6")
					score_guest_IR_3<='1';	
				elsif(data=x"FE_01_6B_86") then  -- Count Home (button "1")
					score_home_IR_1<='1';
				elsif(data=x"FD_02_6B_86") then  -- Count Home (button "2")
					score_home_IR_2<='1';
				elsif(data=x"FC_03_6B_86") then  -- Count Home (button "3")
					score_home_IR_3<='1';
				elsif(data=x"E5_1A_6B_86") then  -- Increments Period(button Channel UP)
					channel_up_IR<='1';
				elsif(data=x"E8_17_6B_86") then -- RESTARTS THE MATCH when pressed
					return_IR <= '1';
				elsif(data=x"E9_16_6B_86") then -- Plays THE MATCH when pressed	
					s_startgame<='1';
				end if;
			end if;
			
			--checks if the game has ended
			end_of_game  <='0';
			end_of_period<='0';
			
			if(s_count_timer=X"0000") then
				if(s_count_period>=X"04") then
					end_of_game   <= '1';
				else
					end_of_period <= '1';
				end if;
			end if;
			
		end if;
	end process;			

		
end Shell;