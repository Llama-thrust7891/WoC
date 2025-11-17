----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------Start Mission-----------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------
ScheduleMissionRestart()

--CreateBlueChief()
--CreateRedChief()
loadAirfields()
SpawnWarehousesByFaction(1, 2)
CreateAllAirfieldOpszones()
OPS_Zones:Start()
redAirfieldszoneset = {}
blueAirfieldszoneset = {}
---for testing purpose only

--DeployForces()
--deployairwings()


----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------Mission Timmers---------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------
TIMER:New(saveAirfields):Start(130, 120) 

local guardTimerblueWH = TIMER:New(SpawnWarehouseGuards, "blue")
local guardTimerredWH = TIMER:New(SpawnWarehouseGuards, "red")
local guardTimerblueAF = TIMER:New(SpawnAirfieldGuards, "blue")
local guardTimerredAF = TIMER:New(SpawnAirfieldGuards, "red")
local CreateChiefBlue = TIMER:New(CreateChief, "blue")
local CreateChiefRed = TIMER:New(CreateChief, "red")
guardTimerblueWH:Start(3)
guardTimerredWH:Start(5)
guardTimerblueAF:Start(7)
guardTimerredAF:Start(9)
CreateChiefBlue:Start(11)
CreateChiefRed:Start(13)
