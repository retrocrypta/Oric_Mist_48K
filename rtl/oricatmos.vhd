--
-- A simulation model of ORIC ATMOS hardware
-- Copyright (c) SEILEBOST - March 2006
--
-- All rights reserved
--
-- Redistribution and use in source and synthezised forms, with or without
-- modification, are permitted provided that the following conditions are met:
--
-- Redistributions of source code must retain the above copyright notice,
-- this list of conditions and the following disclaimer.
--
-- Redistributions in synthesized form must reproduce the above copyright
-- notice, this list of conditions and the following disclaimer in the
-- documentation and/or other materials provided with the distribution.
--
-- Neither the name of the author nor the names of other contributors may
-- be used to endorse or promote products derived from this software without
-- specific prior written permission.
--
-- THIS CODE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
-- AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO,
-- THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR
-- PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR OR CONTRIBUTORS BE
-- LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
-- CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
-- SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
-- INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
-- CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
-- ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
-- POSSIBILITY OF SUCH DAMAGE.
--
-- You are responsible for any legal issues arising from your use of this code.
--
-- The latest version of this file can be found at: passionoric.free.fr
--
-- Email seilebost@free.fr
--
--

  library ieee;
  use ieee.std_logic_1164.all;
  use ieee.std_logic_arith.all;
  use ieee.std_logic_unsigned.all;

  
entity oricatmos is
  port (
    CLK_IN            : in    std_logic;
	 CLK_PSG           : in    std_logic;
    RESET             : in    std_logic;
	 ps2_key         	 : in    std_logic_vector(10 downto 0);
	 key_pressed       : in    std_logic;
	 key_extended      : in    std_logic;
	 key_code          : in    std_logic_vector(7 downto 0);
	 key_strobe        : in    std_logic;
    K7_TAPEIN         : in    std_logic;
    K7_TAPEOUT        : out   std_logic;
    K7_REMOTE         : out   std_logic;
	 rom               : in    std_logic;
	 PSG_OUT           : out   std_logic_vector(15 downto 0);
    VIDEO_R           : out   std_logic;
    VIDEO_G           : out   std_logic;
    VIDEO_B           : out   std_logic;
    VIDEO_HSYNC       : out   std_logic;
    VIDEO_VSYNC       : out   std_logic;
    VIDEO_SYNC        : out   std_logic;
	 ram_ad            : out std_logic_vector(15 downto 0);
	 ram_d             : out std_logic_vector( 7 downto 0);
	 ram_q             : in  std_logic_vector( 7 downto 0);
	 ram_cs            : out std_logic;
	 ram_oe            : out std_logic;
	 ram_we            : out std_logic;
	 phi2              : out std_logic;
	 joystick_0        : in  std_logic_vector( 7 downto 0);
	 joystick_1        : in  std_logic_vector( 7 downto 0);
	 pll_locked        : in  std_logic
	 
);
end;

architecture RTL of oricatmos is
  
    -- Gestion des resets
	 signal RESETn        		: std_logic;
    signal reset_dll_h        : std_logic;
    signal delay_count        : std_logic_vector(7 downto 0) := (others => '0');
    signal clk_cnt            : std_logic_vector(2 downto 0) := "000";

    -- cpu
    signal cpu_ad             : std_logic_vector(23 downto 0);
    signal cpu_di             : std_logic_vector(7 downto 0);
    signal cpu_do             : std_logic_vector(7 downto 0);
    signal cpu_rw             : std_logic;
    signal cpu_irq            : std_logic;
      
	 -- VIA
    signal via_pa_out_oe      : std_logic_vector( 7 downto 0);
    signal via_pa_in          : std_logic_vector( 7 downto 0);
    signal via_pa_in_from_psg : std_logic_vector( 7 downto 0);
    signal via_pa_out         : std_logic_vector( 7 downto 0);
    signal via_cb1_out        : std_logic;
    signal via_cb1_oe_l       : std_logic;
    signal via_cb2_out        : std_logic;
    signal via_cb2_oe_l       : std_logic;
    signal via_pb_in             : std_logic_vector( 7 downto 0);
    signal via_pb_out            : std_logic_vector( 7 downto 0);
    signal via_pb_oe_l           : std_logic_vector( 7 downto 0);
    signal VIA_DO             : std_logic_vector( 7 downto 0);

    
    -- Clavier : émulation par port PS2
    signal KEY_ROW            : std_logic_vector( 7 downto 0);

    -- PSG
    signal psg_bdir           : std_logic; 
    signal psg_bc1            : std_logic; 
	 signal ym_o_ioa           : std_logic_vector (7 downto 0);
    -- ULA    
    signal ula_phi2           : std_logic;
    signal ula_CSIOn          : std_logic;
	 signal ula_CSIO           : std_logic;
    signal ula_CSROMn         : std_logic;
    signal ula_AD_RAM         : std_logic_vector(7 downto 0);
    signal ula_AD_SRAM        : std_logic_vector(15 downto 0);
    signal ula_CE_SRAM        : std_logic;
    signal ula_OE_SRAM        : std_logic;
    signal ula_WE_SRAM        : std_logic;
	 signal ula_LATCH_SRAM     : std_logic;
    signal ula_CLK_4          : std_logic;
    signal ula_RASn           : std_logic;
    signal ula_CASn           : std_logic;
    signal ula_MUX            : std_logic;
    signal ula_RW_RAM         : std_logic;
	 signal ula_IOCONTROL      : std_logic;
	 signal ula_VIDEO_R        : std_logic;
	 signal ula_VIDEO_G        : std_logic;
	 signal ula_VIDEO_B        : std_logic;
	 signal ula_SYNC           : std_logic;
    
	 signal lSRAM_D            : std_logic_vector(7 downto 0);
	 signal ENA_1MHZ           : std_logic;
    signal ROM_ATMOS_DO     	: std_logic_vector(7 downto 0);
    signal ROM_1_DO    			: std_logic_vector(7 downto 0);
	 
	 --- Printer port
	 signal PRN_STROBE			: std_logic;
	 signal PRN_DATA           : std_logic_vector(7 downto 0);


	 signal SRAM_DO            : std_logic_vector(7 downto 0);
	 signal break           	: std_logic;
	 signal joya               : std_logic_vector(6 downto 0);
	 signal joyb               : std_logic_vector(6 downto 0);
	 
	 -- Disk controller
	 signal cont_MAPn          : std_logic :='1';
    signal cont_ROMDISn       : std_logic :='1';
    signal cont_D_OUT         : std_logic_vector(7 downto 0);
    signal cont_IOCONTROLn    : std_logic :='1';

	 signal  disk_cur_TRACK    : std_logic_vector(5 downto 0);  -- Current track (0-34)

    signal IMAGE_NUMBER_out   : std_logic_vector(9 downto 0);
    signal disk_track_addr    : std_logic_vector(13 downto 0);
    signal disk_a_on          : std_logic; -- 0 when disk is active else 1
    signal track_ok           : std_logic; 

COMPONENT keyboard
	PORT
	(
		clk_24		:	 IN STD_LOGIC;
		clk_en		:	 IN STD_LOGIC;
		reset			:	 IN STD_LOGIC;
		key_pressed	:	 IN STD_LOGIC;
		key_extended:	 IN STD_LOGIC;
		key_strobe	:	 IN STD_LOGIC;
		key_code		:	 IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		col			:	 IN STD_LOGIC_VECTOR(2 DOWNTO 0);
		row			:	 IN STD_LOGIC_VECTOR(7 DOWNTO 0);
		ROWbit		:	 OUT STD_LOGIC_VECTOR(7 DOWNTO 0);
		swrst			:	 OUT STD_LOGIC
	);
END COMPONENT;

begin

RESETn <= not RESET;
inst_cpu : entity work.T65
	port map (
		Mode    		=> "00",
      Res_n   		=> RESETn,
      Enable  		=> ENA_1MHZ,
      Clk     		=> CLK_IN,
      Rdy     		=> '1',
      Abort_n 		=> '1',
      IRQ_n   		=> cpu_irq,
      NMI_n   		=> not break,
      SO_n    		=> '1',
      R_W_n   		=> cpu_rw,
      A       		=> cpu_ad,
      DI      		=> cpu_di,
      DO      		=> cpu_do
);
	


	
ram_ad  <= ula_AD_SRAM when ula_PHI2 = '0' else cpu_ad(15 downto 0);
ram_d   <= cpu_do;
SRAM_DO <= ram_q;
ram_cs  <= ula_CE_SRAM;
ram_oe  <= ula_OE_SRAM;
ram_we  <= ula_WE_SRAM;
phi2    <= ula_PHI2;

inst_rom0 : entity work.BASIC11A  -- Oric Atmos ROM
	port map (
		clk  			=> CLK_IN,
		addr 			=> cpu_ad(13 downto 0),
		data 			=> ROM_ATMOS_DO
);

inst_rom1 : entity work.TEST109 -- Oric-1 ROM
	port map (
		clk  			=> CLK_IN,
		addr 			=> cpu_ad(13 downto 0),
		data 			=> ROM_1_DO
);


inst_ula : entity work.ULA
   port map (
      CLK        	=> CLK_IN,
      PHI2       	=> ula_phi2,
		PHI2_EN     => ENA_1MHZ,
      CLK_4      	=> ula_CLK_4,
      RW         	=> cpu_rw,
      RESETn     	=> pll_locked, --RESETn,
		MAPn      	=> cont_MAPn,
      DB         	=> SRAM_DO,
      ADDR       	=> cpu_ad(15 downto 0),
      SRAM_AD    	=> ula_AD_SRAM,
		SRAM_OE    	=> ula_OE_SRAM,
		SRAM_CE    	=> ula_CE_SRAM,
		SRAM_WE    	=> ula_WE_SRAM,
		LATCH_SRAM 	=> ula_LATCH_SRAM,
      CSIOn      	=> ula_CSIOn,
      CSROMn     	=> ula_CSROMn,
--      CSRAMn     	=> ula_CSRAMn,
      R          	=> VIDEO_R,
      G          	=> VIDEO_G,
      B          	=> VIDEO_B,
      SYNC       	=> VIDEO_SYNC,
		HSYNC      	=> VIDEO_HSYNC,
		VSYNC      	=> VIDEO_VSYNC		
);

ula_CSIO <= not(ula_CSIOn);
inst_via : entity work.M6522
	port map (
		I_RS        => cpu_ad(3 downto 0),
		I_DATA      => cpu_do(7 downto 0),
		O_DATA      => VIA_DO,
		I_RW_L      => cpu_rw,
		I_CS1       => cont_IOCONTROLn,
		I_CS2_L     => ula_CSIOn,
		O_IRQ_L     => cpu_irq,   
		I_CA1       => '1',       -- PRT_ACK
		I_CA2       => '1',       -- psg_bdir
		O_CA2       => psg_bdir,  
		O_CA2_OE_L  => open,
		
		I_PA        => via_pa_in,
		O_PA        => via_pa_out,
		O_PA_OE_L   => via_pa_out_oe,
		
		I_CB1       => K7_TAPEIN,
		O_CB1       => via_cb1_out,
      O_CB1_OE_L  => via_cb1_oe_l,
		
		I_CB2       => '1',
		O_CB2       => via_cb2_out,
		O_CB2_OE_L  => via_cb2_oe_l,
		
		I_PB        => via_pb_in,
		O_PB        => via_pb_out,
		RESET_L     => RESETn, --RESETn,
		I_P2_H      => ula_phi2,
		ENA_4       => '1',
		CLK         => ula_CLK_4
);
	
inst_psg : entity work.ay8912
	port map (
		cpuclk      => CLK_IN,
		reset    	=> RESETn, --RESETn,
		cs        	=> '1',
		bc0      	=> psg_bdir,
		bdir     	=> via_cb2_out,
		Data_in     => via_pa_out,
		Data_out    => via_pa_in_from_psg,
		IO_A    		=> ym_o_ioa,
		Amono       => PSG_OUT
);

inst_key : keyboard
	port map(
		clk_24		=> CLK_IN,
		clk_en		=> ENA_1MHZ,
		reset			=> not RESETn, --not RESETn,
		key_pressed	=> key_pressed,
		key_extended => key_extended,
		key_strobe	=> key_strobe,
		key_code		=> key_code,
		row			=> via_pa_out,
		col			=> via_pb_out(2 downto 0),
		ROWbit		=> KEY_ROW,
		swrst			=> break
);






via_pa_in <= (via_pa_out and not via_pa_out_oe) or (via_pa_in_from_psg and via_pa_out_oe);
--via_pa_in <= via_pa_out;
via_pb_in(2 downto 0) <= via_pb_out(2 downto 0);
via_pb_in(3) <= '0' when ( (KEY_ROW or via_pa_out)) = x"FF" else  '1';
--via_pb_in(7 downto 4) <= x"b"; --via_pb_out(7 downto 4);
via_pb_in(4) <=via_pb_out(4);
via_pb_in(5) <= 'Z';
via_pb_in(6) <=via_pb_out(6);
via_pb_in(7) <=via_pb_out(7);



K7_TAPEOUT  <= via_pb_out(7);
K7_REMOTE   <= via_pb_out(6);
PRN_STROBE  <= via_pb_out(4);
PRN_DATA    <= via_pa_out;

cont_IOCONTROLn <= '1'; 
cont_ROMDISn <= '1'; 
cont_MAPn <= '1';


joya <= joystick_0(6 downto 4) & joystick_0(0) & joystick_0(1) & joystick_0(2) & joystick_0(3);
joyb <= joystick_1(6 downto 4) & joystick_1(0) & joystick_1(1) & joystick_1(2) & joystick_1(3);



process begin
	wait until rising_edge(clk_in);
  
	 
		-- expansion port
      if    cpu_rw = '1' and ula_phi2 = '1' and ula_CSIOn = '0' and cont_IOCONTROLn = '0' then
      CPU_DI <= cont_D_OUT;
      -- VIA
		elsif cpu_rw = '1' and ula_phi2 = '1' and ula_CSIOn = '0' and cont_IOCONTROLn = '1' then
			cpu_di <= VIA_DO;
		-- ROM Atmos	
		elsif cpu_rw = '1' and ula_phi2 = '1' and ula_CSIOn = '1' and ula_CSROMn = '0' and rom = '1' and cont_ROMDISn = '1' then
			cpu_di <= ROM_ATMOS_DO;
		--ROM Oric-1
		elsif cpu_rw = '1' and ula_phi2 = '1' and ula_CSIOn = '1' and ula_CSROMn = '0' and rom = '0' and cont_ROMDISn = '1' then
			cpu_di <= ROM_1_DO;	
		-- Oric RAM
		elsif cpu_rw = '1' and ula_phi2 = '1' and ula_CSIOn = '1' and ula_LATCH_SRAM = '0' then
			cpu_di <= SRAM_DO; 
		end if;
end process;

end RTL;
