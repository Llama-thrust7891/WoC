--Define the precreated zones in the MIZ file here for use in 05_WoC_Functions.lua

CapZone1 = ZONE:FindByName("CAP_Zone_NE-1")
CapZone2 = ZONE:FindByName("CAP_Zone_NE-2")
CapZone3 = ZONE:FindByName("CAP_Zone_NE-3")
CapZone4 = ZONE:FindByName("CAP_Zone_NW-1"):DrawZone(2,{1,0,0},1,{1,0,0},.15,4) 
CapZone5 = ZONE:FindByName("CAP_Zone_NW-2")
CapZone6 = ZONE:FindByName("CAP_Zone_NW-3")
CapZone7 = ZONE:FindByName("CAP_Zone_NW-4")
CapZone8 = ZONE:FindByName("CAP_Zone_SE-1")
CapZone9 = ZONE:FindByName("CAP_Zone_SE-2")
CapZone10 = ZONE:FindByName("CAP_Zone_SE-3")
CapZone11 = ZONE:FindByName("CAP_Zone_SE-4")
CapZone12 = ZONE:FindByName("CAP_Zone_SW-1"):DrawZone(2,{0,0,1},1,{0,0,1},.15,4) 
CapZone13 = ZONE:FindByName("CAP_Zone_SW-2")
CapZone14 = ZONE:FindByName("CAP_Zone_SW-3")

redAirfieldszoneset =  SET_ZONE:New()
blueAirfieldszoneset = SET_ZONE:New()