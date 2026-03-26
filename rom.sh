#!/bin/sh
#
# Author   : ko, HomeDL
# Previous : https://github.com/kedziorno/Trash/blob/main/SHELL_Scripts/generate_roms.sh
# Versions :
#   1.0 - File created
#   1.1 - improvments
#
# This script create ROM files from big one with case/when VHDL statements.
# Usage: script [modules number]
# Example: rom.sh 100
#
# For example, can be used to generate .vhd Distributed ROM files for one VGA
# frame VGA 640*480 with 24bit color, so we must have 307200 when line's
# (0 - 307199) in file roma.vhd
#
# So file roma.vhd must look's like:
# -- start address
# when 0 => data <= "00000000";
# ...
# when [address integer] => data <= [8 bit constant];
# ...
# -- end address plus others
# when others => data <= (others => '0');
#
# TAB1 : TAB = 2 x SPACE

set -x

SPLIT=$1

OUTPUT_DIR="rom_test/"
TAB1='\ \ ';
TAB2="${TAB1}${TAB1}";
TAB3="${TAB2}${TAB1}";
TAB4="${TAB2}${TAB2}";
TAB5="${TAB4}${TAB1}";
TAB6="${TAB4}${TAB2}";

rm -rf ${OUTPUT_DIR} && mkdir ${OUTPUT_DIR}

WC_L=`wc -l roma.vhd | awk -F " " '{print $1}'`

LINES=$((${WC_L}/${SPLIT}))

# XXX small pieces, extremely speed-up synthesis time XXX
# better to be divided by lines option
split -l $LINES -d roma.vhd ${OUTPUT_DIR}/rom

cd ${OUTPUT_DIR}

# file ranges and sub ROMs entities
for i in `find . -maxdepth 1 -regex "\.\/rom[0-9]*" | sort`;
do
  rom=`basename $i`;
  OTHERS="others";
  MIN="`head -1 ${rom} | awk -F " " '{print $2;}'`";
  MAX="`tail -1 ${rom} | awk -F " " '{print $2;}'`";
  if [ "${MAX}" = "${OTHERS}" ]; then
    MAX=`tail -2 ${rom} | head -1 | awk -F " " '{print $2;}'`;
  fi
  SUM="`echo "${rom}${MIN}${MAX}" | sum | awk '{print $1}'`";
  COMMENT="\
--
-- ROM ${rom} file instance
-- Variable SUM is generated from ROM file name and ADDRESS range MIN MAX
--
";
  COMMENT="`echo "${COMMENT}" | sed 's/--/\\-\\-/g'`";
  COMMENT="`echo "${COMMENT}" | tr "$'\n'" "$'\n'"`";
  COMMENT="`echo "${COMMENT}" | sed 's/$/\\\/g'`";
  STRING_HEAD="\
${COMMENT}
\n\
LIBRARY ieee;\n\
USE     ieee.std_logic_1164.all;\n\
USE     ieee.numeric_std.all;\n\
\n\
\-\- SUM ${SUM}\n\
ENTITY ROM_${rom} IS\n\
PORT (\n\
${TAB1}reset   : IN  STD_LOGIC;\n\
${TAB1}data    : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);\n\
${TAB1}address : IN  INTEGER RANGE ${MIN} TO ${MAX}\n\
);\n\
END ENTITY ROM_${rom};\n\
\n\
ARCHITECTURE BEHAVIORAL_${rom} OF ROM_${rom} IS\n\
BEGIN\n\
${TAB1}p0_${rom} : PROCESS (\n\
${TAB2}reset, address\n\
${TAB1}) IS\n\
${TAB1}BEGIN\n\
${TAB2}IF (reset = '1') THEN\n\
${TAB3}data <= (OTHERS => '0');\n\
${TAB2}ELSE\n\
${TAB3}CASE (address) IS\n\
${TAB3}\-\- start\n\
";
  STRING_TAIL="\\
${TAB3}\-\- end\n\
${TAB3}END CASE;\n\
${TAB2}END IF;\n\
${TAB1}END PROCESS p0_${rom};\n\
END ARCHITECTURE BEHAVIORAL_${rom};\
";
  sed -i "1s/^/${STRING_HEAD}/" $i;
  sed -i "$ a ${STRING_TAIL}" $i;
  mv "${rom}" "${rom}.vhd"
done

# rom_mux file
rm -rf rom.vhd
touch rom.vhd

echo "" > rom.vhd

COMMENT="\
${TAB1}\
-- Architecure comments
";
COMMENT="`echo "${COMMENT}" | sed 's/--/\\-\\-/g'`";
COMMENT="`echo "${COMMENT}" | tr "$'\n'" "$'\n'"`";
COMMENT="`echo "${COMMENT}" | sed 's/$/\\\/g'`";
sed -i "$ a ${COMMENT} --\n" rom.vhd

COMMENT="\
--
-- ROM_MUX (ROMs multiplexing)
-- Comments\:
-- \[short describe\]
-- \[purpose\]
--
-- Variable SUM can be used to navigate over generated ROMs.
-- (Used TAB over SPACE in some place of identations, replace).
--
";
COMMENT="`echo "${COMMENT}" | sed 's/--/\\-\\-/g'`";
COMMENT="`echo "${COMMENT}" | tr "$'\n'" "$'\n'"`";
COMMENT="`echo "${COMMENT}" | sed 's/$/\\\/g'`";

# head rom_mux
ROMMUX_HEAD="\
${COMMENT}
\n\
LIBRARY ieee;\n\
USE     ieee.std_logic_1164.ALL;\n\
USE     ieee.numeric_std.ALL;\n\
\n\
ENTITY ROM_MUX IS\n\
PORT (\n\
${TAB1}reset   : IN  STD_LOGIC;\n\
${TAB1}data    : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);\n\
${TAB1}address : IN  INTEGER RANGE 0 TO ${WC_L} - 1\n\
);\n\
END ENTITY ROM_MUX;\n\
\n\
ARCHITECTURE BEHAVIORAL_ROM_MUX OF ROM_MUX IS\
";

sed -i "1s/^/${ROMMUX_HEAD}/" rom.vhd;

p0_data_sens_list="";

COMMENT="\
${TAB1}\
-----------------------------------------------------------------------------
${TAB1}\
-- COMPONENTS
${TAB1}\
----------------------------------------------------------------------------
";
COMMENT="`echo "${COMMENT}" | sed 's/--/\\-\\-/g'`";
COMMENT="`echo "${COMMENT}" | tr "$'\n'" "$'\n'"`";
COMMENT="`echo "${COMMENT}" | sed 's/$/\\\/g'`";
sed -i "$ a ${COMMENT}-\n" rom.vhd

# rom_mux components
for i in `find . -maxdepth 1 -regex "\.\/rom[0-9]+.vhd" | sort`;
do
  rom=`basename $i`;
  rom1=`basename $i ".vhd"`;
  OTHERS="others";
  MIN="`grep -i "when " ${rom} | head -1 | awk -F " " '{print $2;}'`";
  MAX="`grep -i "when " ${rom} | tail -1 | awk -F " " '{print $2;}'`";
  if [ "${MAX}" = "${OTHERS}" ]; then
    MAX=`grep -i "when " ${rom} | tail -2 | head -1 | awk -F " " '{print $2;}'`;
  fi
  SUM="`echo "${rom1}${MIN}${MAX}" | sum | awk '{print $1}'`";
COMPONENT="\
${TAB1}COMPONENT ROM_${rom1} IS \-\- SUM ${SUM}\n\
${TAB1}PORT (\n\
${TAB2}reset   : IN  STD_LOGIC;\n\
${TAB2}data    : OUT STD_LOGIC_VECTOR (7 DOWNTO 0);\n\
${TAB2}address : IN  INTEGER RANGE ${MIN} TO ${MAX}\n\
${TAB1});\n\
${TAB1}END COMPONENT ROM_${rom1};\n\
${TAB1}SIGNAL ROM_${rom1}_address  : INTEGER RANGE ${MIN} TO ${MAX};\n\
${TAB1}SIGNAL ROM_${rom1}_data     : STD_LOGIC_VECTOR (7 DOWNTO 0);\n\
";
  sed -i "$ a ${COMPONENT}" rom.vhd
done

sed -i "$ a BEGIN\n" rom.vhd

COMMENT="\
${TAB1}\
-----------------------------------------------------------------------------
${TAB1}\
-- INSTANTINANCES
${TAB1}\
----------------------------------------------------------------------------
";
COMMENT="`echo "${COMMENT}" | sed 's/--/\\-\\-/g'`";
COMMENT="`echo "${COMMENT}" | tr "$'\n'" "$'\n'"`";
COMMENT="`echo "${COMMENT}" | sed 's/$/\\\/g'`";
sed -i "$ a ${COMMENT}-\n" rom.vhd

# sub ROMS instantinates
for i in `find . -maxdepth 1 -regex "\.\/rom[0-9]+.vhd" | sort`;
do
  rom=`basename $i`;
  rom1=`basename $i ".vhd"`;
  OTHERS="others";
  MIN="`grep -i "when " ${rom} | head -1 | awk -F " " '{print $2;}'`";
  MAX="`grep -i "when " ${rom} | tail -1 | awk -F " " '{print $2;}'`";
  if [ "${MAX}" = "${OTHERS}" ]; then
    MAX=`grep -i "when " ${rom} | tail -2 | head -1 | awk -F " " '{print $2;}'`;
  fi
INSTANT="\
${TAB1}inst_ROM_${rom1} : ROM_${rom1}\n\
${TAB1}PORT MAP (\n\
${TAB2}reset   => reset,\n\
${TAB2}address => ROM_${rom1}_address,\n\
${TAB2}data    => ROM_${rom1}_data\n\
${TAB1});\n\
";
  sed -i "$ a ${INSTANT}" rom.vhd
  p0_data_sens_list="${p0_data_sens_list}${TAB2},ROM_${rom1}_data\n"
done

COMMENT="\
${TAB1}\
-----------------------------------------------------------------------------
${TAB1}\
-- PROCESS ADDRESS
${TAB1}\
----------------------------------------------------------------------------
";
COMMENT="`echo "${COMMENT}" | sed 's/--/\\-\\-/g'`";
COMMENT="`echo "${COMMENT}" | tr "$'\n'" "$'\n'"`";
COMMENT="`echo "${COMMENT}" | sed 's/$/\\\/g'`";
sed -i "$ a ${COMMENT}-\n" rom.vhd

# process address mux
P0a="\
${TAB1}p0_rom_mux_address : PROCESS (\n\
${TAB2}address\n\
${TAB1}) IS\n\
${TAB1}BEGIN\n\
${TAB2}CASE (address) IS\n\
${TAB3}\-\- start\
";
sed -i "$ a ${P0a}" rom.vhd

for i in `find . -maxdepth 1 -regex "\.\/rom[0-9]+.vhd" | sort`;
do
  rom=`basename $i`;
  rom1=`basename $i ".vhd"`;
  rom2=`basename $i ".vhd" | cut -b 4-`;
  OTHERS="others";
  MIN="`grep -i "when " ${rom} | head -1 | awk -F " " '{print $2;}'`";
  MAX="`grep -i "when " ${rom} | tail -1 | awk -F " " '{print $2;}'`";
  if [ "${MAX}" = "${OTHERS}" ]; then
    MAX=`grep -i "when " ${rom} | tail -2 | head -1 | awk -F " " '{print $2;}'`;
  fi
  RANGE="${TAB4}WHEN ${MIN} TO ${MAX} =>\n${TAB5}ROM_rom${rom2}_address <= address;";
  sed -i "$ a ${RANGE}" rom.vhd
done

P0b="\\
${TAB3}\-\- end\n\
${TAB2}END CASE;\n\
${TAB1}END PROCESS p0_rom_mux_address;\n\
";
sed -i "$ a ${P0b}" rom.vhd

COMMENT="\
${TAB1}\
-----------------------------------------------------------------------------
${TAB1}\
-- PROCESS DATA
${TAB1}\
----------------------------------------------------------------------------
";
COMMENT="`echo "${COMMENT}" | sed 's/--/\\-\\-/g'`";
COMMENT="`echo "${COMMENT}" | tr "$'\n'" "$'\n'"`";
COMMENT="`echo "${COMMENT}" | sed 's/$/\\\/g'`";
sed -i "$ a ${COMMENT}-\n" rom.vhd

# process data mux
P1a="\
${TAB1}p1_rom_mux_data : PROCESS (\n\
${TAB2}reset, address\n\
${p0_data_sens_list}\
${TAB1}) IS\n\
${TAB1}BEGIN\n\
${TAB2}IF (reset = '1') THEN\n\
${TAB3}DATA <= (others => '0');\n\
${TAB2}ELSE\n\
${TAB3}CASE (address) IS\n\
${TAB4}\-\- start\
";
sed -i "$ a ${P1a}" rom.vhd

for i in `find . -maxdepth 1 -regex "\.\/rom[0-9]+.vhd" | sort`;
do
  rom=`basename $i`;
  rom1=`basename $i ".vhd"`;
  rom2=`basename $i ".vhd" | cut -b 4-`;
  OTHERS="others";
  MIN="`grep -i "when " ${rom} | head -1 | awk -F " " '{print $2;}'`";
  MAX="`grep -i "when " ${rom} | tail -1 | awk -F " " '{print $2;}'`";
  if [ "${MAX}" = "${OTHERS}" ]; then
    MAX=`grep -i "when " ${rom} | tail -2 | head -1 | awk -F " " '{print $2;}'`;
  fi
  RANGE="${TAB5}WHEN ${MIN} TO ${MAX} =>\n${TAB6}data <= ROM_rom${rom2}_data;";
  sed -i "$ a ${RANGE}" rom.vhd
done

P1b="\\
${TAB4}\-\- end\n\
${TAB4}WHEN OTHERS => data <= (others => '0');\n\
${TAB3}END CASE;\n\
${TAB2}END IF;\n\
${TAB1}END PROCESS p1_rom_mux_data;\n\
";
sed -i "$ a ${P1b}" rom.vhd

# end architecture
P10="\
END ARCHITECTURE BEHAVIORAL_ROM_MUX;
";
sed -i "$ a ${P10}" rom.vhd

