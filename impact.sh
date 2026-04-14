#!/bin/bash

chmod 0700 /home/user/.local/Xilinx/14.7/ISE_DS/settings64.sh
. /home/user/.local/Xilinx/14.7/ISE_DS/settings64.sh
impact -batch _impact.cmd

