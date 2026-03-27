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
 
ENTITY tb_VGA_timing_synch IS
END tb_VGA_timing_synch;
 
ARCHITECTURE behavior OF tb_VGA_timing_synch IS 
 
    -- Component Declaration for the Unit Under Test (UUT)
 
    COMPONENT VGA_timing_synch
    PORT(
         clk25 : IN  std_logic;
         Hsync : OUT  std_logic;
         Vsync : OUT  std_logic;
         blank : OUT  std_logic;
         activeArea1 : OUT  std_logic
        );
    END COMPONENT;
    for all : VGA_timing_synch use entity work.VGA_timing_synch(lsfr);

   --Inputs
   signal clk25 : std_logic := '0';

 	--Outputs
   signal Hsync : std_logic;
   signal Vsync : std_logic;
   signal blank : std_logic;
   signal activeArea1 : std_logic;

   -- Clock period definitions
   constant clk25_period : time := 40 ns;

BEGIN

	-- Instantiate the Unit Under Test (UUT)
   uut: VGA_timing_synch PORT MAP (
          clk25 => clk25,
          Hsync => Hsync,
          Vsync => Vsync,
          blank => blank,
          activeArea1 => activeArea1
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
      wait for 100 ns;	

      wait for clk25_period*10;

      -- insert stimulus here 

      wait;
   end process;

END;
