--------------------------------------------------------------------------------
-- Company: 
-- Engineer:
--
-- Create Date:   13:24:32 03/27/2026
-- Design Name:   
-- Module Name:   /home/user/_WORKSPACE_/kedziorno/ov7670_vga_Nexys2/tb_VGA_timing_synch.vhd
-- Project Name:  ov7670_vga_Nexys2
-- Target Device:  
-- Tool versions:  
-- Description:   
-- 
-- VHDL Test Bench Created by ISE for module: VGA_timing_synch
-- 
-- Dependencies:
-- 
-- Revision:
-- Revision 0.01 - File Created
-- Additional Comments:
--
-- Notes: 
-- This testbench has been automatically generated using types std_logic and
-- std_logic_vector for the ports of the unit under test.  Xilinx recommends
-- that these types always be used for the top-level I/O of a design in order
-- to guarantee that the testbench will bind correctly to the post-implementation 
-- simulation model.
--------------------------------------------------------------------------------
LIBRARY ieee;
USE ieee.std_logic_1164.ALL;
 
-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--USE ieee.numeric_std.ALL;
 
ENTITY tb_vga_timing IS
END tb_vga_timing;
 
ARCHITECTURE behavior OF tb_vga_timing IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT vga_timing
    PORT(
         clk25 : IN  std_logic;
         rst   : IN  std_logic;
         Hsync : OUT  std_logic;
         Vsync : OUT  std_logic;
         blank : OUT  std_logic;
         activeArea : OUT  std_logic;
         interrupt  : out std_logic

        );
    END COMPONENT;
    for all : vga_timing use entity work.vga_timing (lsfr_2);

   --Inputs
   signal clk25 : std_logic := '0';
   signal rst : std_logic := '0';

 	--Outputs
   signal Hsync : std_logic;
   signal Vsync : std_logic;
   signal blank : std_logic;
   signal activeArea : std_logic;
   signal interrupt : std_logic;

   -- Clock period definitions
   constant clk25_period : time := 40 ns;

BEGIN

	-- Instantiate the Unit Under Test (UUT)
   uut: vga_timing PORT MAP (
          clk25 => clk25,
          rst => rst,
          Hsync => Hsync,
          Vsync => Vsync,
          blank => blank,
          activeArea => activeArea,
          interrupt => interrupt
        );

   -- Clock process definitions
   clk25_process :process
   begin
		clk25 <= '0';
		wait for clk25_period/2;
		clk25 <= '1';
		wait for clk25_period/2;
   end process;
 

   -- Stimulus process
   stim_proc: process
   begin		
      -- hold reset state for 100 ns.
      rst <= '1';
      wait for 100 ns;	
      rst <= '0';
      wait for clk25_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
