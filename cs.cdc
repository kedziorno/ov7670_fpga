#ChipScope Core Inserter Project File Version 3.0
#Wed Aug 10 18:57:53 CEST 2022
Project.device.designInputFile=/home/user/workspace/ov7670_vga_Nexys2/Top_cs.ngc
Project.device.designOutputFile=/home/user/workspace/ov7670_vga_Nexys2/Top_cs.ngc
Project.device.deviceFamily=13
Project.device.enableRPMs=true
Project.device.outputDirectory=/home/user/workspace/ov7670_vga_Nexys2/_ngo
Project.device.useSRL16=true
Project.filter.dimension=10
Project.filter<0>=*data1*
Project.filter<1>=*clkcam*
Project.filter<2>=
Project.filter<3>=*pclk1*
Project.filter<4>=*href*
Project.filter<5>=*vsync*
Project.filter<6>=*pclk*
Project.filter<7>=*cambuf*
Project.filter<8>=*hsync*
Project.filter<9>=*camclk*
Project.icon.boundaryScanChain=1
Project.icon.enableExtTriggerIn=false
Project.icon.enableExtTriggerOut=false
Project.icon.triggerInPinName=
Project.icon.triggerOutPinName=
Project.unit.dimension=1
Project.unit<0>.clockChannel=ov7670_pclk1buf
Project.unit<0>.clockEdge=Falling
Project.unit<0>.dataChannel<0>=ov7670_pclk1buf
Project.unit<0>.dataChannel<1>=ov7670_vsync1_IBUF
Project.unit<0>.dataChannel<2>=ov7670_href1_IBUF
Project.unit<0>.dataChannel<3>=ov7670_data1_0_IBUF
Project.unit<0>.dataChannel<4>=ov7670_data1_2_IBUF
Project.unit<0>.dataChannel<5>=ov7670_data1_4_IBUF
Project.unit<0>.dataChannel<6>=ov7670_data1_6_IBUF
Project.unit<0>.dataChannel<7>=clkcambuf1
Project.unit<0>.dataDepth=16384
Project.unit<0>.dataEqualsTrigger=true
Project.unit<0>.dataPortWidth=8
Project.unit<0>.enableGaps=false
Project.unit<0>.enableStorageQualification=true
Project.unit<0>.enableTimestamps=false
Project.unit<0>.timestampDepth=0
Project.unit<0>.timestampWidth=0
Project.unit<0>.triggerChannel<0><0>=clkcambuf1
Project.unit<0>.triggerChannel<0><1>=ov7670_vsync1_IBUF
Project.unit<0>.triggerChannel<0><2>=ov7670_href1_IBUF
Project.unit<0>.triggerChannel<0><3>=ov7670_data1_0_IBUF
Project.unit<0>.triggerChannel<0><4>=ov7670_data1_2_IBUF
Project.unit<0>.triggerChannel<0><5>=ov7670_data1_4_IBUF
Project.unit<0>.triggerChannel<0><6>=ov7670_data1_6_IBUF
Project.unit<0>.triggerChannel<0><7>=ov7670_data1_7_IBUF
Project.unit<0>.triggerConditionCountWidth=0
Project.unit<0>.triggerMatchCount<0>=1
Project.unit<0>.triggerMatchCountWidth<0><0>=0
Project.unit<0>.triggerMatchType<0><0>=1
Project.unit<0>.triggerPortCount=1
Project.unit<0>.triggerPortIsData<0>=true
Project.unit<0>.triggerPortWidth<0>=8
Project.unit<0>.triggerSequencerLevels=16
Project.unit<0>.triggerSequencerType=1
Project.unit<0>.type=ilapro
