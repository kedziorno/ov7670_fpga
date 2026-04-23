setMode -bs
setMode -bs
setMode -bs
setMode -bs
setCable -port auto
Identify -inferir 
identifyMPM 
setCable -target "digilent_plugin"
ReadIdcode -p 1 
assignFile -p 1 -file "top_raw_signals.bit"
Program -p 1 
Program -p 2 
setMode -bs
setMode -bs
setMode -bs
setMode -ss
setMode -sm
setMode -hw140
setMode -spi
setMode -acecf
setMode -acempm
setMode -pff
