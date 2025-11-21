----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------Start Mission-----------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------
ScheduleMissionRestart()
--redAirfieldszoneset = {}
--blueAirfieldszoneset = {}

loadAirfields()
SpawnWarehousesByFaction(blueSide, redSide)
CreateAllAirfieldOpszones()
OPS_Zones:Start()

---for testing purpose only
-- initialize CTLD now that zones/warehouses exist
if BlueOpsCTLD then BlueOpsCTLD(blueAirfieldszoneset) end
if RedOpsCTLD then RedOpsCTLD(redAirfieldszoneset) end
--DeployForces()
--deployairwings()


----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------Mission Timmers---------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------
TIMER:New(function() pcall(saveAirfields) end):Start(130, 120)

-- spawn guards/warehouses safely
TIMER:New(function() pcall(SpawnAirfieldGuards, "blue") end):Start(10)
TIMER:New(function() pcall(SpawnAirfieldGuards, "red") end):Start(12)
TIMER:New(function() pcall(SpawnWarehouseGuards, "blue") end):Start(15)
TIMER:New(function() pcall(SpawnWarehouseGuards, "red") end):Start(17)

-- create named timers with safe wrappers
local CreateChiefBlue = TIMER:New(function() pcall(CreateChief, "blue") end)
local CreateChiefRed  = TIMER:New(function() pcall(CreateChief, "red") end)
local DeployAirwings   = TIMER:New(function() pcall(DeployAirwingsFromWarehouses) end)
local MonitorZones     = TIMER:New(function() pcall(monitoropszones) end)
local tplayertaskingRed  = TIMER:New(function() pcall(PlayerTaskingRed) end)
local tplayertaskingBlue = TIMER:New(function() pcall(PlayerTaskingBlue) end)

-- start them
CreateChiefBlue:Start(11)
CreateChiefRed:Start(13)
DeployAirwings:Start(15)
MonitorZones:Start(20)
tplayertaskingRed:Start(20)
tplayertaskingBlue:Start(20)

-- Start periodic OPS zone capture checks: first run after 30s, then every 60s
