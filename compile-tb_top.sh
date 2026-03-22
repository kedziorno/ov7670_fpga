#!/bin/bash
# Usage script.sh "y|n" [DB WDB] "time" [numeric] "period" [ms|us|ns]
source /home/user/.local/Xilinx/14.7/ISE_DS/settings32.sh
database=$1
top=$2
time_period=$3
time_scale=$4
rm -rf isim_output.txt
rm -rf isim_gui.cmd
echo "onerror {resume}" > isim_gui.cmd
if [ x${database} = x"y" ]; then
grep "wvobject fp_name=\"/" tb_${top}.wcfg | sed -E "s/<wvobject fp_name=\"(.*)\" type=\"(.*)\" db_ref_id=\"(.*)\">/\1/g" | awk -F " " '{printf ("wave add %s\n", $0)}' >> isim_gui.cmd
fi
echo "run ${time_period} ${time_scale}" >> isim_gui.cmd
echo "quit -f" >> isim_gui.cmd
fuse -v -intstyle ise \
-o tb_${top}_isim_beh.exe \
-prj tb_${top}_beh.prj \
work.tb_${top}
if [ $? = 0 ]; then
if [ x${database} = x"y" ]; then
./tb_${top}_isim_beh.exe -intstyle ise -tclbatch isim_gui.cmd \
-view tb_${top}.wcfg \
-wdb tb_${top}_isim_beh.wdb \
-log isim_output.txt
else
./tb_${top}_isim_beh.exe -intstyle ise -tclbatch isim_gui.cmd \
-log isim_output.txt
fi
fi
