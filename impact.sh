#!/bin/bash

chmod 0700 /home/user/.local/Xilinx/14.7/ISE_DS/settings64.sh
. /home/user/.local/Xilinx/14.7/ISE_DS/settings64.sh
if [ $# == 0 ]; then
  echo "usage script.sh [1 - normal | 2 - rs]"
  exit 1
fi

if [ $1 = 1 ]; then
impact -batch _impact.cmd
fi

if [ $1 = 2 ]; then
impact -batch _impact_rs.cmd
fi

