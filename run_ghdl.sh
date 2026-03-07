#!/usr/bin/env bash
set -e

# --------------------------
# Configuration
# --------------------------
# Change these to your VHDL files and top entity
SOURCES=(
"std_logic_arith.vhdl"
"numeric_std.vhd"
"p_constants.vhd"
"micron_mem_parameters.vhd"
"video_address_counter.vhd"
"sd_controller.vhd"
"ram1.vhd"
"Bitmap-VHDL-Package/rtl/bmp_pkg.vhd"
"video_timing_3.vhd"
"sdcard_emulator.vhd"
"sccb.vhd"
"memory_dualport.vhd"
"camera_vga.vhd"
"camera_capture.vhd"
"Bitmap-VHDL-Package/rtl/vga_bmp_sink.vhd"
"tb_ov7670_camera_emulator.vhd"
)
TOP_ENTITY="tb_ov7670_camera_emulator"
WORKDIR="work_ghdl"

OPTS="-fsynopsys -Whide"

# --------------------------
# Prepare
# --------------------------
echo "[1/4] Cleaning work directory..."
rm -rf $WORKDIR
mkdir -p $WORKDIR

cp hex_memory_file_frame*.hex $WORKDIR/

# --------------------------
# Load / Analyze (parse + compile)
# --------------------------
echo "[2/4] Analyzing VHDL sources..."
echo "${SOURCES[@]}"
for file in "${SOURCES[@]}"; do
    echo "   • ghdl -a $file"
    ghdl -a ${OPTS} --workdir=$WORKDIR $file
done

# --------------------------
# Elaborate
# --------------------------
echo "[3/4] Elaborating $TOP_ENTITY..."
ghdl -e ${OPTS} --workdir=$WORKDIR $TOP_ENTITY

# --------------------------
# Simulate
# --------------------------
echo "[4/4] Running simulation..."
ghdl -r ${OPTS} --workdir=$WORKDIR $TOP_ENTITY --fst=wave.fst --stop-time=1000000ms

echo "Done!"
echo "Waveform saved to wave.ghw"

