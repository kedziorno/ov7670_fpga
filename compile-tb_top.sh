#!/bin/bash
#. $HOME/.local/Xilinx/14.7/ISE_DS/settings64.sh
#fuse -v -intstyle ise -incremental -lib unisims_ver -lib unimacro_ver -lib xilinxcorelib_ver \
#-o tb_ov7670_camera_emulator_isim_beh.exe \
#-prj tb_ov7670_camera_emulator_beh.prj \
#work.tb_ov7670_camera_emulator \
#work.glbl
#if [ $? = 0 ]; then
#./tb_ov7670_camera_emulator_isim_beh.exe -intstyle ise -tclbatch isim.cmd \
#-view tb_ov7670_camera_emulator.wcfg \
#-wdb tb_ov7670_camera_emulator_isim_beh.wdb \
#-log isim_output.txt
#fi

#!/bin/bash
source /home/user/.local/Xilinx/14.7/ISE_DS/settings64.sh
top=$1
rm -rf isim_output.txt
rm -rf isim_gui.cmd
echo "onerror {resume}" > isim_gui.cmd
grep "wvobject fp_name=\"/" tb_${top}.wcfg | sed -E "s/<wvobject fp_name=\"(.*)\" type=\"(.*)\" db_ref_id=\"(.*)\">/\1/g" | awk -F " " '{printf ("wave add %s\n", $0)}' >> isim_gui.cmd
echo "run all" >> isim_gui.cmd
fuse -v -intstyle ise \
-o tb_${top}_isim_beh.exe \
-prj tb_${top}_beh.prj \
work.tb_${top}
if [ $? = 0 ]; then
./tb_${top}_isim_beh.exe -intstyle ise -tclbatch isim_gui.cmd \
-view tb_${top}.wcfg \
-wdb tb_${top}_isim_beh.wdb \
-log isim_output.txt
fi
