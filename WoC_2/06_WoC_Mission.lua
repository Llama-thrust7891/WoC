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
guardTimerblueWH:Start(5)
guardTimerredWH:Start(8)
guardTimerblueAF:Start(11)
guardTimerredAF:Start(14)
