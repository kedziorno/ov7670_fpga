#!/bin/sh

PROJECT="camera_vga"
DEVICE="xc3s1200e-fg320-4"
BITS="64"

. ~/.local/Xilinx/10.1/ISE/ISE/settings${BITS}.sh

echo "*************************************************************************"
echo "Synthesis project ${PROJECT} (x${BITS}) for device ${DEVICE}"
echo "*************************************************************************"

set -x

mkdir -p xst/projnav.tmp/

xst -intstyle ise -ifn ./${PROJECT}.xst -ofn ./${PROJECT}.syr
if [ $? -ne 0 ]; then
	echo "error on xst";
	exit;
fi
exit 0;
ngdbuild -intstyle ise -dd _ngo -sd ipcore_dir -nt timestamp -uc ${PROJECT}.ucf -p ${DEVICE} ${PROJECT}.ngc ${PROJECT}.ngd
if [ $? -ne 0 ]; then
	echo "error on ngdbuild";
	exit;
fi
map -ise ${PROJECT}.ise -intstyle ise -p ${DEVICE} -cm area -pr off -k 4 -c 100 -o ${PROJECT}_map.ncd ${PROJECT}.ngd ${PROJECT}.pcf
if [ $? -ne 0 ]; then
  echo "error on map";
  exit;
fi
par -w -intstyle ise -ol std -rl std -t 1 ${PROJECT}_map.ncd ${PROJECT}.ncd ${PROJECT}.pcf
if [ $? -ne 0 ]; then
  echo "error on par";
  exit;
fi
trce -intstyle ise -v 3 -s 10 -n 3 -fastpaths -xml ${PROJECT}.twx ${PROJECT}.ncd -o ${PROJECT}.twr ${PROJECT}.pcf -ucf ${PROJECT}.ucf
if [ $? -ne 0 ]; then
  echo "error on trce";
  exit;
fi
# 32bit for fix "ERROR:Bitgen - Unknown DCM site '' in pminfo."
. ~/.local/Xilinx/10.1/ISE/ISE/settings32.sh
bitgen -intstyle ise -f ${PROJECT}.ut ${PROJECT}.ncd
if [ $? -ne 0 ]; then
  echo "error on bitgen";
  exit;
fi
ls -l ${PROJECT}.bit
#. ~/.local/Xilinx/10.1/ISE/ISE/settings${BITS}.sh
#export LD_PRELOAD="/home/user/.local/Xilinx/usb-driver/libusb-driver-x86_64.so"
#impact -batch probe1_impact.batch -b probe1.bit -p auto -ipf probe1.ipf
#impact -batch impact.cmd

