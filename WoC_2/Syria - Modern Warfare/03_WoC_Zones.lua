

--------------------------------------------------------
---------------------Zones -----------------------------
---------------------------------------------------------

--Define the precreated zones in the MIZ file here for use in 05_WoC_Functions.lua

CapZone1 = ZONE:FindByName("CAP_Zone_NE-1")--redborder
CapZone2 = ZONE:FindByName("CAP_Zone_NE-2") --redcap,redborder
CapZone3 = ZONE:FindByName("CAP_Zone_NE-3") --redcap,redborder
CapZone4 = ZONE:FindByName("CAP_Zone_NW-1"):DrawZone(2,{1,0,0},1,{1,0,0},.15,4)--redcap,redborder-redawacs
CapZone5 = ZONE:FindByName("CAP_Zone_NW-2")--redborder
CapZone6 = ZONE:FindByName("CAP_Zone_NW-3")--redcap,redborder
CapZone7 = ZONE:FindByName("CAP_Zone_NW-4")--redcap,redborder
CapZone8 = ZONE:FindByName("CAP_Zone_SE-1") --Bluecap,blueborder
CapZone9 = ZONE:FindByName("CAP_Zone_SE-2")--Bluecap,blueborder
CapZone10 = ZONE:FindByName("CAP_Zone_SE-3")--Bluecap,blueborder
CapZone11 = ZONE:FindByName("CAP_Zone_SE-4")--blueborder
CapZone12 = ZONE:FindByName("CAP_Zone_SW-1"):DrawZone(2,{0,0,1},1,{0,0,1},.15,4) --Bluecap,blueborder-blueawacs
CapZone13 = ZONE:FindByName("CAP_Zone_SW-2")--Bluecap,blueborder
CapZone14 = ZONE:FindByName("CAP_Zone_SW-3")--blueborder
CapZone15 = ZONE:FindByName("CAP_Zone_Mid")--Bluecap

BlueBorderSet = SET_ZONE:New()
RedBorderSet = SET_ZONE:New()

RedBorderSet:AddZone(CapZone1)
RedBorderSet:AddZone(CapZone2)
RedBorderSet:AddZone(CapZone3)
RedBorderSet:AddZone(CapZone4)
RedBorderSet:AddZone(CapZone5)
RedBorderSet:AddZone(CapZone6)
RedBorderSet:AddZone(CapZone7)

BlueBorderSet:AddZone(CapZone8)
BlueBorderSet:AddZone(CapZone9)
BlueBorderSet:AddZone(CapZone10)
BlueBorderSet:AddZone(CapZone11)
BlueBorderSet:AddZone(CapZone12)
BlueBorderSet:AddZone(CapZone13)
BlueBorderSet:AddZone(CapZone14)
BlueBorderSet:AddZone(CapZone15)



redAirfieldszoneset =  SET_ZONE:New()
blueAirfieldszoneset = SET_ZONE:New()

-------------------------------------------------------
-------------------------------------------------------
----------------------End Zones -------------------------
-------------------------------------------------------