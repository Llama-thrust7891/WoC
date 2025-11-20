----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------Start Mission-----------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------
ScheduleMissionRestart()

--CreateBlueChief()
--CreateRedChief()
loadAirfields()
SpawnWarehousesByFaction(blueSide, redSide)
CreateAllAirfieldOpszones()
OPS_Zones:Start()
redAirfieldszoneset = {}
blueAirfieldszoneset = {}
---for testing purpose only
-- initialize CTLD now that zones/warehouses exist
if BlueOpsCTLD then BlueOpsCTLD() end
if RedOpsCTLD then RedOpsCTLD() end
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
local DeployAirwings = TIMER:New(DeployAirwingsFromWarehouses)
guardTimerblueWH:Start(3)
guardTimerredWH:Start(5)
guardTimerblueAF:Start(7)
guardTimerredAF:Start(9)
CreateChiefBlue:Start(11)
CreateChiefRed:Start(13)
DeployAirwings:Start(15)
