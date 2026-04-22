`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    15:58:35 04/06/2026 
// Design Name: 
// Module Name:    ram_buffer 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////

// Asymmetric port RAM
// Read Wider than Write. Read Statement in loop
//asym_ram_sdp_read_wider.v
// https://docs.amd.com/r/en-US/ug901-vivado-synthesis/Dual-Port-Asymmetric-RAM-When-Read-is-Wider-than-Write-Verilog

module asym_ram_sdp_read_wider (clkA, clkB, enaA, weA, enaB, addrA, addrB, diA, doB, reset);
parameter WIDTHA = 16;
parameter SIZEA = 1024;
parameter ADDRWIDTHA = 10;

parameter WIDTHB = 16;
parameter SIZEB = 1024;
parameter ADDRWIDTHB = 10;
input clkA;
input clkB;
input weA;
input enaA, enaB;
input reset;
input [ADDRWIDTHA-1:0] addrA;
input [ADDRWIDTHB-1:0] addrB;
input [WIDTHA-1:0] diA;
output [WIDTHB-1:0] doB;
`define max(a,b) {(a) > (b) ? (a) : (b)}
`define min(a,b) {(a) < (b) ? (a) : (b)}

function integer log2;
input integer value;
reg [31:0] shifted;
integer res;
begin
if (value < 2)
log2 = value;
else
begin
shifted = value-1;
for (res=0; shifted>0; res=res+1)
shifted = shifted>>1;
log2 = res;
end
end
endfunction

localparam maxSIZE = `max(SIZEA, SIZEB);
localparam maxWIDTH = `max(WIDTHA, WIDTHB);
localparam minWIDTH = `min(WIDTHA, WIDTHB);

localparam RATIO = maxWIDTH / minWIDTH;
localparam log2RATIO = log2(RATIO);

reg [minWIDTH-1:0] RAM [0:maxSIZE-1];
reg [WIDTHB-1:0] readB;

integer ir;
initial begin
  for (ir = 0; ir < maxSIZE; ir = ir + 1) begin
    RAM [ir] = 0;
  end
end

always @(negedge clkA)
begin
if (enaA) begin
if (weA)
RAM[addrA] <= diA;
end
end


integer i;
reg [log2RATIO-1:0] lsbaddr;
always @(negedge clkB)
begin : ramread
if(reset)
readB <= 0;
else
if (enaB) begin
for (i = 0; i < RATIO; i = i+1) begin
lsbaddr = i;
readB[(i+1)*minWIDTH-1 -: minWIDTH] <= RAM[{addrB, lsbaddr}];
end
end
end

assign doB = readB;

endmodule
