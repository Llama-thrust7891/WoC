-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------Wings of Conflict Mission Script----------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- Simple Persistence for blueAirfields and redAirfields only
-----------------------------------------------------------------------

local filepath = lfs.writedir() .. "\\Missions\\WoC-Sinai-MW\\Save\\"
local airfieldsFile = filepath .. "airfields.lua"
local zoneUnitFile = filepath .. "zone_units.lua"

-- Ensure the directory exists
local function createDirectory(path)
    local command = 'mkdir "' .. path .. '"'
    os.execute(command)
end
createDirectory(filepath)

-- Save function
function saveAirfields()
    local file = io.open(airfieldsFile, "w")
    if file then
        file:write("blueAirfields = {\n")
        for _, name in ipairs(blueAirfields or {}) do
            file:write('    "' .. name .. '",\n')
        end
        file:write("}\n")
        file:write("redAirfields = {\n")
        for _, name in ipairs(redAirfields or {}) do
            file:write('    "' .. name .. '",\n')
        end
        file:write("}\n")
        file:close()
        env.info("Airfields saved to " .. airfieldsFile)
    else
        env.info("Failed to save airfields")
    end
end

function saveZoneUnitCounts(zones)
    local file = io.open(zoneUnitFile, "w")
    if not file then return end
    file:write("ZoneUnitCounts = {\n")
    for _, zone in ipairs(zones) do
        local zoneName = zone:GetName()
        local set = SET_UNIT:New():FilterZones({zone}):FilterCategoryGround():FilterOnce()
        local typeCounts = {}
        set:ForEachUnit(function(unit)
            local typeName = unit:GetTypeName()
            typeCounts[typeName] = (typeCounts[typeName] or 0) + 1
        end)
        file:write('  ["'..zoneName..'"] = {\n')
        for typeName, count in pairs(typeCounts) do
            file:write('    ["'..typeName..'"] = '..count..',\n')
        end
        file:write('  },\n')
    end
    file:write("}\n")
    file:close()
    env.info("Zone unit counts saved (unit-level).")
end

-- Load function
function loadAirfields()
    if lfs.attributes(airfieldsFile) then
        local chunk, err = loadfile(airfieldsFile)
        if chunk then
            local list = {}
            setfenv(chunk, list)
            local ok, _ = pcall(chunk)
            if ok then
                blueAirfields = list.blueAirfields or {}
                redAirfields = list.redAirfields or {}
                env.info("Airfields loaded from save.")
            else
                env.info("Error running airfields file.")
            end
        else
            env.info("Error loading airfields file: " .. tostring(err))
        end
    else
        env.info("No airfields save file found, using defaults.")
        sortairfields()
    end
end

function loadZoneUnitCounts()
    if lfs.attributes(zoneUnitFile) then
        local chunk, err = loadfile(zoneUnitFile)
        if chunk then
            local envTable = {}
            setfenv(chunk, envTable)
            local ok, _ = pcall(chunk)
            if ok then
                return envTable.ZoneUnitCounts or {}
            end
        end
    end
    return {}
end

function enforceZoneUnitCountsFromOpsZones()
    local savedCounts = loadZoneUnitCounts()
    OPS_Zones:ForEachZone(function(opszone)
        local zone = opszone:GetZone()
        local zoneName = zone:GetName()
        local set = SET_UNIT:New():FilterZones({zone}):FilterCategoryGround():FilterOnce()
        local currentCounts = {}
        set:ForEachUnit(function(unit)
            local typeName = unit:GetTypeName()
            currentCounts[typeName] = currentCounts[typeName] or {}
            table.insert(currentCounts[typeName], unit)
        end)
        local saved = savedCounts[zoneName] or {}
        for typeName, units in pairs(currentCounts) do
            local allowed = saved[typeName] or 0
            if #units > allowed then
                -- Destroy extras
                for i = allowed+1, #units do
                    local unit = units[i]
                    if unit and unit:IsAlive() then
                        unit:Destroy()
                        env.info("Destroyed extra unit "..unit:GetName().." of type "..typeName.." in zone "..zoneName)
                    end
                end
            end
        end
    end)
end
local RESTART_INTERVAL = 8 * 60 * 60 -- 8 hours in seconds

function ScheduleMissionRestart()
    local restartTime = timer.getTime() + RESTART_INTERVAL

    -- Helper to schedule a warning
    local function scheduleWarning(secondsBefore, message)
        local warnTime = restartTime - secondsBefore
        if warnTime > timer.getTime() then
            TIMER:New(function()
                MESSAGE:New(message, 30):ToAll()
            end):Start(warnTime - timer.getTime())
        end
    end

    scheduleWarning(30*60, "Mission will restart in 30 minutes!")
    scheduleWarning(15*60, "Mission will restart in 15 minutes!")
    scheduleWarning(5*60,  "Mission will restart in 5 minutes!")
    scheduleWarning(60,     "Mission will restart in 1 minute!")

    -- Schedule the actual restart
    TIMER:New(function()
        MESSAGE:New("Mission is restarting now!", 30):ToAll()
        trigger.action.setUserFlag(9999, 1) -- Use your preferred restart method here
    end):Start(restartTime - timer.getTime())
end

-- Call this at mission start
ScheduleMissionRestart()

-- Usage at mission start:
-- loadAirfields()
-- ... (your mission logic)
-- saveAirfields() -- call when you want to save (e.g. on mission end or periodically)
--TIMER:New(function()
--    saveZoneUnitCounts(blueAirfieldszones)
--    saveZoneUnitCounts(redAirfieldszones)
--end):Start(133, 120) -- every 120 seconds after 130 seconds

TIMER:New(saveAirfields):Start(130, 120) -- every 120 seconds after 130 seconds
--Start the main script for setting up the Wings of Conflict Mission--

SamCount = 1
MinDistance = 300
MaxDistance = 1000
--Coalition = "USA" --commented out only needed for testing
---get airbases on the map---
function getAllAirbaseNames()
    local airfields = {}  -- Correctly define this table
    
    
    for _, airbase in ipairs(world.getAirbases()) do
        
        table.insert(airfields, airbase:getName())  -- Insert into the correct table
       

    end
    return airfields  -- Return the correct table
    
    
end
AirfieldNames = getAllAirbaseNames()

-- Assign airfields west of "Baluza" to Red, others to Blue
heliParkingCount = 0
aircraftParkingCount = 0
redAirfields = {}
blueAirfields = {}
redAirfieldszones =  {}
blueAirfieldszones = {}
redAirfieldszoneset =  SET_ZONE:New()
blueAirfieldszoneset = SET_ZONE:New()

referenceAirfield = "Baluza"
--Sort airfields into red and blue
function sortairfields()
    if not blueAirfields or not redAirfields then
        blueAirfields = {}
        redAirfields = {}
    end

    for _, airfieldName in ipairs(AirfieldNames) do
        local airfield = AIRBASE:FindByName(airfieldName)
        if airfield then
            local airfieldPosition = airfield:GetVec2()
            local referenceAirfieldPosition = AIRBASE:FindByName(referenceAirfield):GetVec2()
            if airfieldPosition.y < referenceAirfieldPosition.y then
                table.insert(redAirfields, airfieldName)
                redAirfieldszoneset:AddZone(airfield:GetZone())
            else
                table.insert(blueAirfields, airfieldName)
                blueAirfieldszoneset:AddZone(airfield:GetZone())
            end
        end
    end
end
--create  auftrag patrol mission for later use
function AssignPatrolMission(GroupName, airfieldName)
    if not GroupName then
        env.info("ERROR: AssignPatrolMission - Group is nil!")
        return
    end

    -- Find the airbase and its zone
    local airbase = AIRBASE:FindByName(airfieldName)
    if not airbase then
        env.info("ERROR: AssignPatrolMission - Airbase not found: " .. airfieldName)
        return
    end

    local patrolZone = airbase:GetZone()  -- Get airbase zone

    -- Create a new AUFTRAG (Mission Order) for patrol
    local patrolMission = AUFTRAG:NewPATROLZONE(
        patrolZone, -- Patrol in the airbase's zone
        20  -- Speed (km/h)
        )
    
        
    -- Assign the mission to the group
    GroupName:AddMission(patrolMission)
    
    env.info("Assigned Patrol Mission to " .. group:GetName() .. " in zone: " .. airfieldName)
end
---spawning function for later use
function Spawn_Near_airbase(GroupTemplate, airfieldName, Inner, Outer, Patrol)
    Patrol = Patrol ~= false -- Default to true if not explicitly set to false
    local Group = GROUP:FindByName(GroupTemplate) -- Find group by name in ME
    if not GroupTemplate then
        env.info("ERROR: Group template "..GroupTemplate.." not found!")
        return
    end

    -- Generate unique name
    local GroupName = airfieldName.."_"..GroupTemplate.."_"..SamCount
    local Airbase = AIRBASE:FindByName(airfieldName)
    local Spawnpoint = nil
    
    if not Airbase then
        env.info("ERROR: Airbase not found: " .. airfieldName)
        return
    end
    
    -- Try to find a warehouse in the airfield's spawn zone
    local SpawnZone = Airbase:GetZone()
    local WarehouseFound = nil
    
    local WarehouseSet = SET_STATIC:New():FilterCoalitions(Airbase:GetCoalition()):FilterTypes("Warehouse"):FilterStart()
    WarehouseSet:ForEachStatic(
        function(warehouse)
            if warehouse:IsInZone(SpawnZone) then
                WarehouseFound = warehouse
            end
        end
    )
    
    if WarehouseFound then
        local WarehouseCoord = WarehouseFound:GetCoordinate()
        local WarehouseZone = ZONE_RADIUS:New("WarehouseZone", WarehouseCoord:GetVec2(), 200)
        Spawnpoint = WarehouseZone:GetRandomCoordinate(80, 200, land.SurfaceType.ROAD)
        env.info("Spawn point set near warehouse at " .. airfieldName)
    else
        -- Default to airbase zone if no warehouse is found
        Spawnpoint = SpawnZone:GetRandomCoordinate(Inner, Outer, land.SurfaceType.ROAD)
        env.info("No warehouse found. Defaulting to airbase zone spawn at " .. airfieldName)
    end
    
    -- Log spawn action
    env.info("Spawning "..GroupTemplate.." with name "..GroupName)
    
    -- Spawn using Moose
    local Group_Spawn = SPAWN:NewWithAlias(GroupTemplate, GroupName)
    Group_Spawn:InitPositionCoordinate(Spawnpoint)
    
    if Patrol then
        --Group_Spawn:OnSpawnGroup(AssignPatrolMission(GroupName, airfieldName))
        env.info("no mission assigned")
    end
    
    Group_Spawn:Spawn()
    
    -- Increment counter
    SamCount = SamCount + 1
end

OPS_Zones = SET_OPSZONE:New()

----create a zone object and opszone object around an airfield
function CreateAirfieldOpszones(airfieldName)
    local zoneName = "Capture Zone - " .. airfieldName
    local zoneRadius = 5000 -- 5 km capture zone
    local zone = ZONE_AIRBASE:New(airfieldName, zoneRadius)
    local opzone = OPSZONE:New(zone):SetDrawZone(true):SetObjectCategories(Object.Category.UNIT):SetUnitCategories(Unit.Category.GROUND_UNIT)
end
----For each airbase, check for the number of Aircraft parking and Helicopter parking----
---- Used when deploying squadrons to determine suitable aircraft (helo \vtol strips\ minor \major airbase.)

local function airbaseParkingSummary(airfieldName)
    local af = AIRBASE:FindByName(airfieldName)

    if not af then
        trigger.action.outText("Error: Airfield '" .. airfieldName .. "' not found", 10)
        return nil
    end

    -- Get parking data for the airfield
    local parkingData = af:GetParkingData(false)  -- False for all parking spots, not just available ones

    if #parkingData == 0 then
        trigger.action.outText("No parking data for airfield '" .. airfieldName .. "'", 10)
    end

    -- Initialize counters
    local heliParkingCount = 0
    local aircraftParkingCount = 0

    -- Iterate through parking data and count the term types
    for _, spot in ipairs(parkingData) do
        local termType = spot.Term_Type

        if termType == 40 then
            heliParkingCount = heliParkingCount + 1  -- Count heli parking spots
        elseif termType ~= 16 then
            aircraftParkingCount = aircraftParkingCount + 1  -- Count aircraft parking spots, ignore 16
        end
    end

    -- Return the summary data
    return {
        airfieldName = airfieldName,
        heliParkingCount = heliParkingCount,
        aircraftParkingCount = aircraftParkingCount
    }
end
--spawn static building warehouse with tents
function SpawnWarehouse(airfieldName, warehouseName, coalitionSide)
    local airbase = AIRBASE:FindByName(airfieldName)
    if not airbase then
        trigger.action.outText("Error: Airfield not found - " .. airfieldName, 10)
        return
    end

    local SpawnZone = airbase:GetZone()
    local Spawnpoint = nil
    local MaxAttempts = 200  -- Try up to 200 locations if obstructed
    local Attempts = 0

    repeat
        Spawnpoint = SpawnZone:GetRandomCoordinate(150, 1000, land.SurfaceType.ROAD)
        if land.getSurfaceType(Spawnpoint) == land.SurfaceType.ROAD then
            ValidSpawn = true
        else
            Attempts = Attempts + 1
        end
    until ValidSpawn or Attempts >= MaxAttempts

    -- Fallback Method if No Valid Spot Found
    if not ValidSpawn then
        trigger.action.outText("WARNING: Could not find a clear spawn point for warehouse at " .. airfieldName .. ". Using fallback", 10)
        env.info("WARNING: No clear warehouse spawn point found at " .. airfieldName .. ". Using fallback")
        
        Spawnpoint = SpawnZone:GetRandomCoordinate(300, 600, land.SurfaceType.LAND)  -- Fallback zone
        
        if land.getSurfaceType(Spawnpoint) ~= land.SurfaceType.LAND then
            trigger.action.outText("ERROR: Fallback method failed for warehouse at " .. airfieldName, 10)
            env.info("ERROR: Fallback method failed for warehouse at " .. airfieldName)
            return
        end
    end

    local warehouseHeading = 180 --airbase:GetHeading() -- Align with airbase general heading

    -- Spawn the warehouse
    local warehouse = {
        category = "Warehouses",
        type = "Warehouse",
        country = coalitionSide,
        x = Spawnpoint.x,
        y = Spawnpoint.z,
        heading = warehouseHeading,
        name = warehouseName,
    }

    mist.dynAddStatic(warehouse)
    env.info("Warehouse created at " .. airfieldName .. " after " .. Attempts .. " attempts.")

    -- Calculate tent positions (aligned left and right)
    local tentSpacing = 20  -- Distance between tents
    local numTents = 3  -- Number of tents in each row
    local sideOffset = 30  -- Distance left/right from the warehouse

    -- Convert heading to radians
    --local headingRad = math.rad(warehouseHeading)

    -- Directional vectors based on warehouse heading
    local forwardX = math.cos(warehouseHeading)
    local forwardY = math.sin(warehouseHeading)

    -- Perpendicular left/right vectors (rotated by 90 degrees)
    local leftX = -forwardY
    local leftY = forwardX

    for i = 1, numTents do
        -- Position each tent in a row aligned with the warehouse
        local tentForwardOffset = (i - 1) * tentSpacing

        local leftTentPos = {
            x = Spawnpoint.x + (leftX * sideOffset) + (forwardX * tentForwardOffset),
            y = Spawnpoint.z + (leftY * sideOffset) + (forwardY * tentForwardOffset)
        }

        local rightTentPos = {
            x = Spawnpoint.x - (leftX * sideOffset) + (forwardX * tentForwardOffset),
            y = Spawnpoint.z - (leftY * sideOffset) + (forwardY * tentForwardOffset)
        }

        local tentLeft = {
            category = "Fortifications",
            type = "FARP Tent",
            country = coalitionSide,
            x = leftTentPos.x,
            y = leftTentPos.y,
            heading = warehouseHeading,
            name = warehouseName .. "_TentL" .. i,
        }

        local tentRight = {
            category = "Fortifications",
            type = "FARP Tent",
            country = coalitionSide,
            x = rightTentPos.x,
            y = rightTentPos.y,
            heading = warehouseHeading,
            name = warehouseName .. "_TentR" .. i,
        }

        mist.dynAddStatic(tentLeft)
        mist.dynAddStatic(tentRight)
    end

    env.info("Tents placed around warehouse at " .. airfieldName)
end


OPS_Zones = SET_OPSZONE:New()

function CreateAllAirfieldOpszones()
    for _, airfieldName in ipairs(blueAirfields) do
        local zone = ZONE_AIRBASE:New(airfieldName, 5000)
        local opzone = OPSZONE:New(zone):SetDrawZone(true):SetObjectCategories(Object.Category.UNIT):SetUnitCategories(Unit.Category.GROUND_UNIT)
        OPS_Zones:AddZone(opzone)
    end
    for _, airfieldName in ipairs(redAirfields) do
        local zone = ZONE_AIRBASE:New(airfieldName, 5000)
        local opzone = OPSZONE:New(zone):SetDrawZone(true):SetObjectCategories(Object.Category.UNIT):SetUnitCategories(Unit.Category.GROUND_UNIT)
        OPS_Zones:AddZone(opzone)
    end
end





function SpawnBlueForces(airfieldName, warehouseName, coalitionSide, MinDistance, MaxDistance)
    local parkingCount = aircraftParkingCount + heliParkingCount

    -- Spawn the warehouse and tents
    SpawnWarehouse(airfieldName, warehouseName, coalitionSide)

    -- Wait 2 seconds for the warehouse static to be indexed, then spawn units
    timer.scheduleFunction(function()
        local airbase = AIRBASE:FindByName(airfieldName)
        if not airbase then
            env.info("ERROR: Airbase not found: " .. airfieldName)
            return
        end

        local parkingData = airbaseParkingSummary(airfieldName)
        if not parkingData then
            env.info("No parking data available for " .. airfieldName)
            return
        end

        -- Try to find the warehouse static
        local warehouse = STATIC:FindByName(warehouseName)
        local SpawnZone = airbase:GetZone()
        local WarehouseZone = nil

        if warehouse and warehouse:IsAlive() then
            local WarehouseCoord = warehouse:GetCoordinate()
            WarehouseZone = ZONE_RADIUS:New("WarehouseZone", WarehouseCoord:GetVec2(), 200)
            env.info("Warehouse found for " .. airfieldName .. ", spawning units near warehouse.")
        else
            env.info("No warehouse found. Defaulting to airbase zone spawn at " .. airfieldName)
        end

        -- Helper to spawn a group near the warehouse or fallback zone
        local function SpawnGroupNearZone(GroupTemplate, Patrol)
            Patrol = Patrol ~= false -- Default to true if not explicitly set to false
            local GroupName = airfieldName.."_"..GroupTemplate.."_"..SamCount
            local Spawnpoint = nil

            if WarehouseZone then
                Spawnpoint = WarehouseZone:GetRandomCoordinate(80, 200, land.SurfaceType.ROAD)
            else
                Spawnpoint = SpawnZone:GetRandomCoordinate(MinDistance, MaxDistance, land.SurfaceType.ROAD)
            end

            env.info("Spawning "..GroupTemplate.." with name "..GroupName)
            local Group_Spawn = SPAWN:NewWithAlias(GroupTemplate, GroupName)
            Group_Spawn:InitPositionCoordinate(Spawnpoint)
            if Patrol then
                env.info("no mission assigned")
            end
            Group_Spawn:Spawn()
            SamCount = SamCount + 1
        end

        -- Spawn groups (SAM site only if enough parking)
        if parkingData.aircraftParkingCount > 80 then
            SpawnGroupNearZone(Group_Blue_SAM_Site, false)
        end

        SpawnGroupNearZone(Group_Blue_SAM)
        SpawnGroupNearZone(Group_Blue_Mech, true)
        SpawnGroupNearZone(Group_Blue_APC, true)
        SpawnGroupNearZone(Group_Blue_Armoured)
        --SpawnGroupNearZone(Group_Blue_Inf)
        SpawnGroupNearZone(Group_Blue_Truck)

        env.info("Finished Spawning Blue Groups at airbase "..airfieldName)

        -- Create the opszone after all spawns
        --CreateAirfieldOpszones(airfieldName)
        --env.info("Finished Creating Opszone at airbase "..airfieldName)
        end, {}, timer.getTime() + 1)
end

function SpawnRedForces(airfieldName, warehouseName, coalitionSide, MinDistance, MaxDistance)
    local parkingCount = aircraftParkingCount + heliParkingCount

    -- Spawn the warehouse and tents
    SpawnWarehouse(airfieldName, warehouseName, coalitionSide)

    -- Wait 2 seconds for the warehouse static to be indexed, then spawn units
    timer.scheduleFunction(function()
        local airbase = AIRBASE:FindByName(airfieldName)
        if not airbase then
            env.info("ERROR: Airbase not found: " .. airfieldName)
            return
        end

        local parkingData = airbaseParkingSummary(airfieldName)
        if not parkingData then
            env.info("No parking data available for " .. airfieldName)
            return
        end

        -- Try to find the warehouse static
        local warehouse = STATIC:FindByName(warehouseName)
        local SpawnZone = airbase:GetZone()
        local WarehouseZone = nil

        if warehouse and warehouse:IsAlive() then
            local WarehouseCoord = warehouse:GetCoordinate()
            WarehouseZone = ZONE_RADIUS:New("WarehouseZone", WarehouseCoord:GetVec2(), 200)
            env.info("Warehouse found for " .. airfieldName .. ", spawning units near warehouse.")
        else
            env.info("No warehouse found. Defaulting to airbase zone spawn at " .. airfieldName)
        end

        -- Helper to spawn a group near the warehouse or fallback zone
        local function SpawnGroupNearZone(GroupTemplate, Patrol)
            Patrol = Patrol ~= false -- Default to true if not explicitly set to false
            local GroupName = airfieldName.."_"..GroupTemplate.."_"..SamCount
            local Spawnpoint = nil

            if WarehouseZone then
                Spawnpoint = WarehouseZone:GetRandomCoordinate(80, 200, land.SurfaceType.ROAD)
            else
                Spawnpoint = SpawnZone:GetRandomCoordinate(MinDistance, MaxDistance, land.SurfaceType.ROAD)
            end

            env.info("Spawning "..GroupTemplate.." with name "..GroupName)
            local Group_Spawn = SPAWN:NewWithAlias(GroupTemplate, GroupName)
            Group_Spawn:InitPositionCoordinate(Spawnpoint)
            if Patrol then
                env.info("no mission assigned")
            end
            Group_Spawn:Spawn()
            SamCount = SamCount + 1
        end

        -- Spawn groups (SAM site only if enough parking)
        if parkingData.aircraftParkingCount > 100 then
            SpawnGroupNearZone(Group_Red_SAM_Site, false)
        end

        SpawnGroupNearZone(Group_Red_SAM)
        SpawnGroupNearZone(Group_Red_Mech, true)
        SpawnGroupNearZone(Group_Red_APC, true)
        SpawnGroupNearZone(Group_Red_Armoured)
        --SpawnGroupNearZone(Group_Red_Inf)
        SpawnGroupNearZone(Group_Red_Truck)

        env.info("Finished Spawning Red Groups at airbase "..airfieldName)

        -- Create the opszone after all spawns
       --CreateAirfieldOpszones(airfieldName)
       --env.info("Finished Creating Opszone at airbase "..airfieldName)
    end, {}, timer.getTime() + 2)
end




---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
----------------Begin Deploying Squadrons and Brigades---------------------------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
AA_MissionSet = {AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.RECON}
CAS_MissionSet = {AUFTRAG.Type.CAS, AUFTRAG.Type.CASENHANCED,AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING}
SEAD_MissionSet = {AUFTRAG.Type.SEAD}
HeloAttack_MissionSet = {AUFTRAG.Type.CAS, AUFTRAG.Type.BAI,AUFTRAG.Type.ESCORT}
HeloTrans_MissionSet = {AUFTRAG.Type.TROOPTRANSPORT, AUFTRAG.Type.CARGOTRANSPORT, AUFTRAG.Type.RECON, AUFTRAG.Type.OPSTRANSPORT}
APC_MissionSet = {AUFTRAG.Type.CAPTUREZONE,AUFTRAG.Type.PATROLZONE,AUFTRAG.Type.ARMOUREDGUARD,AUFTRAG.Type.GROUNDATTACK, AUFTRAG.Type.ONGUARD, AUFTRAG.Type.OPSTRANSPORT}
IFV_MissionSet = {AUFTRAG.Type.CAPTUREZONE,AUFTRAG.Type.PATROLZONE,AUFTRAG.Type.ARMOUREDGUARD,AUFTRAG.Type.GROUNDATTACK, AUFTRAG.Type.ONGUARD, AUFTRAG.Type.OPSTRANSPORT}
MBT_MissionSet = {AUFTRAG.Type.CAPTUREZONE,AUFTRAG.Type.PATROLZONE,AUFTRAG.Type.ARMOUREDGUARD,AUFTRAG.Type.GROUNDATTACK, AUFTRAG.Type.ONGUARD}

BlueAirwings = {}
RedAirwings = {}
BlueBrigades = {}
RedBrigades ={}
UsedSquadronNames = {} -- Global set to store used squadron names
local blueawacscount = 0
local redawacscount = 0
-- Debug OP Zone Counts
env.info("Blue Zones Count: " .. tostring(#blueAirfieldszones))
env.info("Red Zones Count: " .. tostring(#redAirfieldszones))

-- Helper function to generate a unique squadron name
function GenerateUniqueSquadronName(baseName)
    local name
    repeat
        name = math.random(1, 400) .. " " .. baseName
    until not UsedSquadronNames[name]
    UsedSquadronNames[name] = true
    return name
end

-- Function to create Blue Airwing 
---CreateBlueAirwing(warehouse, airwingName, airfieldName) for reference
function CreateBlueAirwing(warehouse, airwingName, airfieldName)
    local warehouseName = warehouse:GetName()
    local airfieldName = warehouseName:gsub("^warehouse_", "")
    local airwingName = "Blue Airwing " .. airfieldName
    local airwing = AIRWING:New(warehouseName, airwingName)
    
    --airwing.squadrons = {} -- Ensure squadrons table is initialized
    airwing:SetAirbase(AIRBASE:FindByName(airfieldName))
    airwing:Start()
    BlueAirwings[warehouseName] = airwing -- Store the airwing in the table
    env.info(airwingName .. " added to Blue Airwing list")

    -- Get parking summary for the warehouse's airbase
    --local warehouseName = warehouse:GetName()

    -- Remove "warehouse_" prefix
    --local airfieldName = warehouseName:gsub("^warehouse_", "")

    -- Find the airbase object by name
    local airbase = AIRBASE:FindByName(airfieldName)
    local parkingData = airbaseParkingSummary(airfieldName)
    env.info("Debug: airbaseParkingSummary = " .. tostring(airbaseParkingSummary))

    if not parkingData then
        env.info("No parking data available for " .. airfieldName)
        return
    end
    
    -- Check if conditions are met before adding squadrons
    if blueawacscount < 1 and parkingData.aircraftParkingCount > 100 then
        env.info("Info: AWACS SQN Deployed to Airwing: "..airwing:GetName())

        local BlueAWACSSquadron = SQUADRON:New("Blue_AWACS", 2, "Darkstar")
        BlueAWACSSquadron:AddMissionCapability({AUFTRAG.Type.ORBIT,AUFTRAG.Type.AWACS}, 100)
        BlueAWACSSquadron:SetFuelLowRefuel(true)
        BlueAWACSSquadron:SetFuelLowThreshold(0.2)
        BlueAWACSSquadron:SetTurnoverTime(10, 20)
        BlueAWACSSquadron:SetTakeoffAir()

        Blue_payload_Awacs = airwing:NewPayload(GROUP:FindByName("Blue_AWACS"), 2, {AUFTRAG.Type.ORBIT,AUFTRAG.Type.AWACS}, 100)
        airwing:AddSquadron(BlueAWACSSquadron)
        blueawacscount = blueawacscount + 1
        BlueAwacsAirwing = airwing
        BlueAwacsAirfieldName = airfieldName
    end

    if parkingData.aircraftParkingCount > 10 then
        local SQN1NAME =  "Blue Fighter Squadron "..airfieldName
        local SQN1 = SQUADRON:New(Blue_Fighter, 4, SQN1NAME)
        SQN1:AddMissionCapability({AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.RECON,AUFTRAG.Type.CAS, AUFTRAG.Type.CASENHANCED,AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING,SEAD},80)
        SQN1:SetDespawnAfterLanding(true)
        SQN1:SetDespawnAfterHolding(true)
        SQN1:SetTakeoffCold()
        SQN1:SetMissionRange(80)
        airwing:AddSquadron(SQN1)
        
       -- BlueAirwings.squadrons =SQN1


        local SQN2 = SQUADRON:New(Blue_LT_Fighter, 2, "Blue Light Fighter Squadron "..airfieldName)
        SQN2:AddMissionCapability({AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.RECON,AUFTRAG.Type.CAS, AUFTRAG.Type.CASENHANCED,AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING},70)
        SQN2:SetDespawnAfterLanding(true)
        SQN2:SetDespawnAfterHolding(true)
        SQN2:SetMissionRange(100)
        SQN2:SetTakeoffCold()
        SQN2:SetMissionRange(80)
        airwing:AddSquadron(SQN2)
        
       -- BlueAirwings.squadrons =SQN2

        local SQN3 = SQUADRON:New(Blue_Attack, 2, "Blue Attack Squadron "..airfieldName)
        SQN3:AddMissionCapability({AUFTRAG.Type.CAS, AUFTRAG.Type.CASENHANCED,AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING,AUFTRAG.Type.SEAD},80)
        SQN3:SetDespawnAfterLanding(true)
        SQN3:SetDespawnAfterHolding(true)
        SQN3:SetMissionRange(100)
        SQN3:SetTakeoffCold()
        SQN3:SetMissionRange(80)
        airwing:AddSquadron(SQN3)
        -- BlueAirwings.squadrons =SQN3


       Blue_payload_Fighter_AA= airwing:NewPayload(GROUP:FindByName(Blue_Fighter.."_AA"), 4, {AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.RECON}, 90)
       Blue_payload_Fighter_CAS= airwing:NewPayload(GROUP:FindByName(Blue_Fighter.."_CAS"), 4, {AUFTRAG.Type.CAS, AUFTRAG.Type.CASENHANCED,AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING},50)
       Blue_payload_LtFighter_AA= airwing:NewPayload(GROUP:FindByName(Blue_LT_Fighter.."_AA"), 2, {AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.RECON},80)
       Blue_payload_LtFighter_CAS= airwing:NewPayload(GROUP:FindByName(Blue_LT_Fighter.."_CAS"), 2, {AUFTRAG.Type.CAS, AUFTRAG.Type.CASENHANCED,AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING},70)
       Blue_payload_LtFighter_SEAD= airwing:NewPayload(GROUP:FindByName(Blue_LT_Fighter.."_SEAD"), 4, {AUFTRAG.Type.SEAD},100)
       Blue_payload_Attack_CAS =airwing:NewPayload(GROUP:FindByName(Blue_Attack.."_CAS"), 2, {AUFTRAG.Type.CAS, AUFTRAG.Type.CASENHANCED,AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING},80)

    else
        env.info("Not enough aircraft parking spots at " .. airfieldName)
    end

    if parkingData.heliParkingCount > 1 or parkingData.aircraftParkingCount > 1 then
        local SQN4 = SQUADRON:New(Blue_Helo, 4, "Blue Transport Squadron "..airfieldName)
        SQN4:AddMissionCapability({AUFTRAG.Type.TROOPTRANSPORT, AUFTRAG.Type.CARGOTRANSPORT, AUFTRAG.Type.RECON, AUFTRAG.Type.OPSTRANSPORT}):SetAttribute(GROUP.Attribute.AIR_TRANSPORTHELO)
        SQN4:SetDespawnAfterLanding(true)
        SQN4:SetDespawnAfterHolding(true)
        SQN4:SetMissionRange(40)
        SQN4:SetTakeoffCold()

        local SQN5 = SQUADRON:New(Blue_AttackHelo, 4, "Blue CAS Squadron "..airfieldName)
        SQN5:AddMissionCapability({AUFTRAG.Type.CAS, AUFTRAG.Type.BAI,AUFTRAG.Type.ESCORT}):SetAttribute(GROUP.Attribute.AIR_TRANSPORTHELO)
        SQN5:SetDespawnAfterLanding(true)
        SQN5:SetDespawnAfterHolding(true)
        SQN5:SetMissionRange(40)
        SQN5:SetTakeoffCold()

        airwing:AddSquadron(SQN4)
        airwing:AddSquadron(SQN5)
        -- BlueAirwings.squadrons =SQN4
       Blue_payload_helo_Trans = airwing:NewPayload(GROUP:FindByName(Blue_Helo.."_Trans"), 4, {AUFTRAG.Type.TROOPTRANSPORT, AUFTRAG.Type.CARGOTRANSPORT, AUFTRAG.Type.RECON, AUFTRAG.Type.OPSTRANSPORT},80)
       Blue_payload_helo_CAS = airwing:NewPayload(GROUP:FindByName(Blue_AttackHelo.."_CAS"), 4, {AUFTRAG.Type.CAS, AUFTRAG.Type.BAI,AUFTRAG.Type.ESCORT},50)
       
       

    else
        env.info("Not enough helicopter parking spots at " .. airfieldName)
    end
    
    BlueChief:AddAirwing(airwing)
    -- Hook into Airwing spawn destroy in the event the aircraft is stuck
        airwing:HandleEvent(EVENTS.Birth)
        function airwing:OnEventBirth(EventData)
          if EventData.IniObject and EventData.IniObject:IsAircraft() then
            monitorAircraftMovement(EventData.IniObject)
          end
        end
    -- Create a Brigade
    local Brigade=BRIGADE:New(warehouse, airwingname) --Ops.Brigade#BRIGADE
    -- Set spawn zone.
    Brigade:SetSpawnZone(airbase:GetZone())
        -- TPz Fuchs platoon.
    local platoonAPC=PLATOON:New(Group_Blue_APC, 5, "Blue Motorised Platoon "..airfieldName)
    platoonAPC:AddMissionCapability(APC_MissionSet, 60):SetAttribute(GROUP.Attribute.GROUND_APC)
        -- Mechanised platoon
    local platoonMECH=PLATOON:New(Group_Blue_Mech, 5,"Blue Mechanised Platoon "..airfieldName)
    platoonMECH:AddMissionCapability(IFV_MissionSet, 70):SetAttribute(GROUP.Attribute.GROUND_APC)
    platoonMECH:AddWeaponRange(UTILS.KiloMetersToNM(0.5), UTILS.KiloMetersToNM(20))
        -- Armoured platoon
    local platoonArmoured =PLATOON:New(Group_Blue_Armoured, 5,"Blue Armoured Platoon "..airfieldName)
    platoonArmoured:AddMissionCapability(MBT_MissionSet, 80)
        -- Arty platoon.
    --local platoonARTY=PLATOON:New(Group_Blue_Arty, 2, "Blue Artillary Platoon "..airfieldName)
    --platoonARTY:AddMissionCapability({AUFTRAG.Type.ARTY}, 80)
    --platoonARTY:AddWeaponRange(UTILS.KiloMetersToNM(10), UTILS.KiloMetersToNM(32)):SetAttribute(GROUP.Attribute.GROUND_ARTILLERY)
        -- M939 Truck platoon. Can provide ammo in DCS.
    local platoonLogi=PLATOON:New(Group_Blue_Truck, 5, "Blue Logistics Platoon "..airfieldName)
    platoonLogi:AddMissionCapability({AUFTRAG.Type.AMMOSUPPLY}, 70)
    --local platoonINF=PLATOON:New(Group_Blue_Inf, 5, "Blue Infantry Platoon "..airfieldName)
    --platoonINF:AddMissionCapability({AUFTRAG.Type.GROUNDATTACK, AUFTRAG.Type.ONGUARD}, 50)
        -- mobile SAM
    local platoonSAM=PLATOON:New(Group_Blue_SAM, 5, "Blue SAM Platoon "..airfieldName)
    platoonSAM:AddMissionCapability({AUFTRAG.Type.AIRDEFENSE}, 100)
   
    -- Add platoons.
    Brigade:AddPlatoon(platoonAPC)
    --Brigade:AddPlatoon(platoonARTY)
    Brigade:AddPlatoon(platoonArmoured)
    Brigade:AddPlatoon(platoonMECH)
    Brigade:AddPlatoon(platoonLogi)
    --Brigade:AddPlatoon(platoonINF)
    Brigade:AddPlatoon(platoonSAM)

    -- Start brigade.
    Brigade:Start()
    BlueChief:AddBrigade(Brigade)
    BlueBrigades[warehouseName] = Brigade 
    local ongaurdzone = airbase:GetZone()
    -- local onguardCoord = ongaurdzone:GetRandomCoordinate(nil, nil, {land.SurfaceType.LAND})
     local GaurdZone1 =AUFTRAG:NewONGUARD(ongaurdzone:GetRandomCoordinate(nil, nil, {land.SurfaceType.LAND}))
     local GaurdZone2 =AUFTRAG:NewONGUARD(ongaurdzone:GetRandomCoordinate(nil, nil, {land.SurfaceType.LAND}))
     local GaurdZone3 =AUFTRAG:NewONGUARD(ongaurdzone:GetRandomCoordinate(nil, nil, {land.SurfaceType.LAND}))
     GaurdZone1:SetRepeatOnFailure(2):SetFormation(ENUMS.Formation.Vehicle.OffRoad):SetRequiredAssets(1, 1)
     GaurdZone2:SetRepeatOnFailure(2):SetFormation(ENUMS.Formation.Vehicle.OffRoad):SetRequiredAssets(1, 1)
     GaurdZone2:SetRepeatOnFailure(2):SetFormation(ENUMS.Formation.Vehicle.OffRoad):SetRequiredAssets(1, 1)
    --Brigade:AddMission(GaurdZone1)
    --Brigade:AddMission(GaurdZone2)
    --Brigade:AddMission(GaurdZone3)

    

end

-- Function to create Red Airwing
function CreateRedAirwing(warehouse, airwingName, airfieldName)
    local warehouseName = warehouse:GetName()
    local airfieldName = warehouseName:gsub("^warehouse_", "")
    local airwingName = "Red Airwing " .. airfieldName
    local airwing = AIRWING:New(warehouseName, airwingName)
    --airwing.squadrons = {} -- Ensure squadrons table is initialized
    airwing:SetAirbase(AIRBASE:FindByName(airfieldName))
    airwing:Start()
    
    env.info(airwingName.. " added to Red Airwing list")  -- Log the report
    -- Get parking summary for the warehouse's airbase
    --local warehouseName = warehouse:GetName()

    -- Remove "warehouse_" prefix
    --local airfieldName = warehouseName:gsub("^warehouse_", "")

    -- Find the airbase object by name
    local airbase = AIRBASE:FindByName(airfieldName)
    local parkingData = airbaseParkingSummary(airfieldName)
    env.info("Debug: airbaseParkingSummary = " .. tostring(airbaseParkingSummary))

    if not parkingData then
        env.info("No parking data available for " .. airfieldName)
        return
    end

    if redawacscount < 1 and parkingData.aircraftParkingCount > 100  then
        env.info("Info: AWACS SQN Deployed to Airwing: "..airwing:GetName())

        local RedAWACSSquadron = SQUADRON:New("Red_AWACS", 2, "Magic")
        RedAWACSSquadron:AddMissionCapability({AUFTRAG.Type.ORBIT,AUFTRAG.Type.AWACS}, 100)
        RedAWACSSquadron:SetFuelLowRefuel(true)
        RedAWACSSquadron:SetFuelLowThreshold(0.2)
        RedAWACSSquadron:SetTurnoverTime(10, 20)
        RedAWACSSquadron:SetTakeoffAir()
        redawacscount = redawacscount + 1
        RedAwacsAirwing = airwing
        Red_payload_Awacs = airwing:NewPayload(GROUP:FindByName("Red_AWACS"), 2, {AUFTRAG.Type.ORBIT,AUFTRAG.Type.AWACS}, 100)
        airwing:AddSquadron(RedAWACSSquadron)
    end

    if parkingData.aircraftParkingCount > 10 then

    local SQN1 = SQUADRON:New(Red_Fighter, 4, "Red Fighter Squadron "..airfieldName)
    SQN1:AddMissionCapability({AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.RECON},80)
    SQN1:SetDespawnAfterLanding(true)
    SQN1:SetDespawnAfterHolding(true)
    SQN1:SetTakeoffCold()
    SQN1:SetMissionRange(60)

     
    local SQN2 = SQUADRON:New(Red_Attack, 2, "Red Attack Squadron "..airfieldName)
    SQN2:AddMissionCapability({AUFTRAG.Type.SEAD,AUFTRAG.Type.RECON, AUFTRAG.Type.CAS, AUFTRAG.Type.CASENHANCED,AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING,AUFTRAG.Type.SEAD},80)
    SQN2:SetDespawnAfterLanding(true)
    SQN2:SetDespawnAfterHolding(true)
    SQN2:SetTakeoffCold()
    SQN2:SetMissionRange(80)    

    local SQN3 = SQUADRON:New(Red_LT_Fighter, 2, "Red Light Fighter Squadron "..airfieldName)
    SQN3:AddMissionCapability({AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.RECON, AUFTRAG.Type.CAS, AUFTRAG.Type.CASENHANCED,AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING},70)
    SQN3:SetDespawnAfterLanding(true)
    SQN3:SetDespawnAfterHolding(true)
    SQN3:SetTakeoffCold()
    SQN3:SetMissionRange(60)
    
    Red_payload_Fighter_AA = airwing:NewPayload(GROUP:FindByName(Red_Fighter.."_AA"), 4, {AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.RECON}, 90)
    Red_payload_LTFighter_CAS = airwing:NewPayload(GROUP:FindByName(Red_Fighter.."_CAS"), 4, {AUFTRAG.Type.CAS, AUFTRAG.Type.CASENHANCED,AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING}, 70)
    Red_payload_LtFighter_AA = airwing:NewPayload(GROUP:FindByName(Red_LT_Fighter.."_AA"), 2, {AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.RECO},70)
    Red_payload_Attack_SEAD = airwing:NewPayload(GROUP:FindByName(Red_Attack.."_SEAD"), 2, {AUFTRAG.Type.SEAD},90)
    Red_payload_Attack_CAS = airwing:NewPayload(GROUP:FindByName(Red_Attack.."_CAS"), 2,{AUFTRAG.Type.CAS, AUFTRAG.Type.CASENHANCED,AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING}, 90)
    airwing:AddSquadron(SQN1)
    airwing:AddSquadron(SQN2)
    airwing:AddSquadron(SQN3)
    env.info(string.format("###Squadron %s was added to  %s assets###", SQN1:GetName(), airwingName))
    env.info(string.format("###Squadron %s was added to  %s assets###", SQN2:GetName(), airwingName))
    env.info(string.format("###Squadron %s was added to  %s assets###", SQN3:GetName(), airwingName))
   
    
    else
    env.info("Not enough aircraft parking spots at " .. airfieldName)
    end
    if parkingData.heliParkingCount > 1 or parkingData.aircraftParkingCount > 1 then
    local SQN4 = SQUADRON:New(Red_Helo, 8, "Red Transport Squadron "..airfieldName)
    SQN4:AddMissionCapability({AUFTRAG.Type.TROOPTRANSPORT, AUFTRAG.Type.CARGOTRANSPORT, AUFTRAG.Type.RECON, AUFTRAG.Type.OPSTRANSPORT,AUFTRAG.Type.CAS, AUFTRAG.Type.BAI,AUFTRAG.Type.ESCORT}):SetAttribute(GROUP.Attribute.AIR_TRANSPORTHELO)
    SQN4:SetDespawnAfterLanding(true)
    SQN4:SetDespawnAfterHolding(true)
    SQN4:SetTakeoffCold()
    SQN4:SetMissionRange(40)
    airwing:AddSquadron(SQN4)
    env.info(string.format("###Squadron %s was added to  %s assets###", SQN4:GetName(), airwingName))
    Red_payload_helo_trans = airwing:NewPayload(GROUP:FindByName(Red_Helo.."_Trans"), 4, {AUFTRAG.Type.TROOPTRANSPORT, AUFTRAG.Type.CARGOTRANSPORT, AUFTRAG.Type.RECON, AUFTRAG.Type.OPSTRANSPORT},80)
    Red_payload_helo_CAS = airwing:NewPayload(GROUP:FindByName(Red_Helo.."_CAS"), 4,{AUFTRAG.Type.CAS, AUFTRAG.Type.BAI,AUFTRAG.Type.ESCORT},50)
    else
    env.info("Not enough helicopter parking spots at " .. airfieldName)
    end
    
    RedAirwings[warehouseName] = airwing -- Store the airwing in the table
    RedChief:AddAirwing(airwing)
    -- Hook into Airwing spawn destroy in the event the aircraft is stuck
        airwing:HandleEvent(EVENTS.Birth)
        function airwing:OnEventBirth(EventData)
          if EventData.IniObject and EventData.IniObject:IsAircraft() then
            monitorAircraftMovement(EventData.IniObject)
          end
        end
    -- Create a Brigade
    local Brigade=BRIGADE:New(warehouseName, airwingname) --Ops.Brigade#BRIGADE
    -- Set spawn zone.
    Brigade:SetSpawnZone(airbase:GetZone())
        -- TPz Fuchs platoon.
        local platoonAPC=PLATOON:New(Group_Red_APC, 5, "Red Motorised Platoon "..airfieldName)
        platoonAPC:AddMissionCapability(APC_MissionSet, 60):SetAttribute(GROUP.Attribute.GROUND_APC)
            -- Mechanised platoon
        local platoonMECH=PLATOON:New(Group_Red_Mech, 5, "Red Mechanised Platoon "..airfieldName)
        platoonMECH:AddMissionCapability(IFV_MissionSet, 70)
        platoonMECH:AddWeaponRange(UTILS.KiloMetersToNM(0.5), UTILS.KiloMetersToNM(20))
            -- Armoured platoon
        local platoonArmoured =PLATOON:New(Group_Red_Armoured, 5,"Red Armoured Platoon "..airfieldName)
        platoonArmoured:AddMissionCapability(MBT_MissionSet, 80)
            -- Arty platoon.
        --local platoonARTY=PLATOON:New(Group_Red_Arty, 2, "Red Artillary Platoon "..airfieldName)
        --platoonARTY:AddMissionCapability({AUFTRAG.Type.ARTY}, 80)
        --platoonARTY:AddWeaponRange(UTILS.KiloMetersToNM(10), UTILS.KiloMetersToNM(32)):SetAttribute(GROUP.Attribute.GROUND_ARTILLERY)
            -- M939 Truck platoon. Can provide ammo in DCS.
        local platoonLogi=PLATOON:New(Group_Red_Truck, 5, "Red Logistics Platoon "..airfieldName)
        platoonLogi:AddMissionCapability({AUFTRAG.Type.AMMOSUPPLY}, 70)
       --local platoonINF=PLATOON:New(Group_Red_Inf, 5, "Red Infantry Platoon "..airfieldName)
       --platoonINF:AddMissionCapability({AUFTRAG.Type.GROUNDATTACK, AUFTRAG.Type.ONGUARD}, 50)
            -- mobile SAM
        local platoonSAM=PLATOON:New(Group_Red_SAM, 5,  "Red SAM Platoon "..airfieldName)
        platoonSAM:AddMissionCapability({AUFTRAG.Type.AIRDEFENSE}, 100)
           
        -- Add platoons.
        Brigade:AddPlatoon(platoonAPC)
        --Brigade:AddPlatoon(platoonARTY)
        Brigade:AddPlatoon(platoonArmoured)
        Brigade:AddPlatoon(platoonMECH)
        Brigade:AddPlatoon(platoonLogi)
        --Brigade:AddPlatoon(platoonINF)
        Brigade:AddPlatoon(platoonSAM)
    
    -- Start brigade.
    Brigade:Start()
    RedChief:AddBrigade(Brigade)
    RedBrigades[warehouseName] = Brigade 
    local ongaurdzone = airbase:GetZone()
   -- local onguardCoord = ongaurdzone:GetRandomCoordinate(nil, nil, {land.SurfaceType.LAND})
    local GaurdZone1 =AUFTRAG:NewONGUARD(ongaurdzone:GetRandomCoordinate(nil, nil, {land.SurfaceType.LAND}))
    local GaurdZone2 =AUFTRAG:NewONGUARD(ongaurdzone:GetRandomCoordinate(nil, nil, {land.SurfaceType.LAND}))
    local GaurdZone3 =AUFTRAG:NewONGUARD(ongaurdzone:GetRandomCoordinate(nil, nil, {land.SurfaceType.LAND}))
    GaurdZone1:SetRepeatOnFailure(2):SetFormation(ENUMS.Formation.Vehicle.OffRoad):SetRequiredAssets(1, 1)
    GaurdZone2:SetRepeatOnFailure(2):SetFormation(ENUMS.Formation.Vehicle.OffRoad):SetRequiredAssets(1, 1)
    GaurdZone2:SetRepeatOnFailure(2):SetFormation(ENUMS.Formation.Vehicle.OffRoad):SetRequiredAssets(1, 1)
  --Brigade:AddMission(GaurdZone1)
  --Brigade:AddMission(GaurdZone2)
  --Brigade:AddMission(GaurdZone3)
  
end

------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
--------------------------------End Squadron and Brigade functions------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------


------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
--------------------------------------Begin Chief functions-------------------------------------------------
------------------------------------------------------------------------------------------------------------
------------------------------------------------------------------------------------------------------------
local CapZone1 = ZONE:FindByName("CAP_Zone_E"):DrawZone(2,{0,0,1},1,{0,0,1},.15,4) 
local CapZone2 = ZONE:FindByName("CAP_Zone_SE")
local CapZone3 = ZONE:FindByName("CAP_Zone_Mid")
local CapZone4 = ZONE:FindByName("CAP_Zone_Mid")
local CapZone5 = ZONE:FindByName("CAP_Zone_W"):DrawZone(2,{1,0,0},1,{1,0,0},.15,4) 
local CapZone6 = ZONE:FindByName("CAP_Zone_Mid_S")
local CapZone7 = ZONE:FindByName("CAP_Zone_DSE")
local CapZone8 = ZONE:FindByName("CAP_Zone_DSW")
local CapZone9 = ZONE:FindByName("CAP_Zone_N_W")
local CapZone10 = ZONE:FindByName("CAP_Zone_N_E")
local CapZone11 = ZONE:FindByName("CAP_Zone_DNE")

---
-- CHIEF OF STAFF
---
-- Create Blue Chief

function CreateBlueChief()
    BlueAgents = SET_GROUP:New():FilterCoalitions("blue"):FilterStart()

    -- Define Blue Chief
    BlueChief = CHIEF:New(coalition.side.BLUE, BlueAgents)
    --BlueChief:SetTacticalOverviewOn()
    BlueChief:SetVerbosity(5)

    -- Set strategy for Blue Chief
    BlueChief:SetStrategy(CHIEF.Strategy.AGGRESSIVE)
    BlueChief:SetDefcon(CHIEF.DEFCON.RED)

    BlueChief:SetBorderZones(blueAirfieldszoneset)
    BlueChief:SetConflictZones(redAirfieldszoneset)
    BlueChief:SetLimitMission(2, AUFTRAG.Type.ARTY)
    BlueChief:SetLimitMission(2, AUFTRAG.Type.BARRAGE)
    BlueChief:SetLimitMission(6, AUFTRAG.Type.GROUNDATTACK)
    BlueChief:SetLimitMission(2, AUFTRAG.Type.RECON)
    BlueChief:SetLimitMission(2, AUFTRAG.Type.BAI)
    BlueChief:SetLimitMission(2, AUFTRAG.Type.INTERCEPT)
    BlueChief:SetLimitMission(2, AUFTRAG.Type.SEAD)
    BlueChief:SetLimitMission(2, AUFTRAG.Type.BOMBING)
    BlueChief:SetLimitMission(4, AUFTRAG.Type.CAPTUREZONE)
    BlueChief:SetLimitMission(2, AUFTRAG.Type.CASENHANCED)
    BlueChief:SetLimitMission(2, AUFTRAG.Type.CAS)
    BlueChief:SetLimitMission(20, Total)
    
    --testing demo resource lists---
    --local ResourceListEmpty, ResourceIFV=BlueChief:CreateResource(AUFTRAG.Type.PATROLZONE,  1, 3, {GROUP.Attribute.GROUND_TANK,GROUP.Attribute.GROUND_APC})
    --local ResourceAlpha=BlueChief:AddToResource(ResourceListEmpty, AUFTRAG.Type.ONGUARD, 1, 3, GROUP.Attribute.GROUND_TANK)
    --local ResourceBravo=BlueChief:AddToResource(ResourceListEmpty, AUFTRAG.Type.ONGUARD, 1, 3, GROUP.Attribute.GROUND_APC)
    --local ResourceCharlie=BlueChief:AddToResource(ResourceListEmpty, AUFTRAG.Type.ONGUARD, 1, 2, GROUP.Attribute.GROUND_SAM)

    -- Create a resource list for an empty zone and add an ONGUARD mission for up to three IFVs.
    local ResourceListEmpty, ResourceAPC=BlueChief:CreateResource(AUFTRAG.Type.PATROLZONE,  0, 3, GROUP.Attribute.GROUND_APC)
    local ResourceInfAlpha=BlueChief:AddToResource(ResourceListEmpty, AUFTRAG.Type.ONGUARD, 1, 3, GROUP.Attribute.GROUND_INFANTRY)
    local ResourceInfBravo=BlueChief:AddToResource(ResourceListEmpty, AUFTRAG.Type.ONGUARD, 1, 3, GROUP.Attribute.GROUND_INFANTRY)
    local resourceInf=BlueChief:CreateResource(AUFTRAG.Type.ONGUARD, 1, 3, GROUP.Attribute.GROUND_INFANTRY)
    local resourceMech=BlueChief:CreateResource(AUFTRAG.Type.PATROLZONE, 1, 3, {GROUP.Attribute.GROUND_APC,GROUP.Attribute.GROUND_IFV,GROUP.Attribute.GROUND_TANK})
    

    -- Resource Infantry Alpha is transported by up to 3 transport helos.
    BlueChief:AddTransportToResource(ResourceInfAlpha, 1, 3, {GROUP.Attribute.AIR_TRANSPORTHELO})
    BlueChief:AddTransportToResource(resourceInf, 1, 3, {GROUP.Attribute.AIR_TRANSPORTHELO})
    BlueChief:AddTransportToResource(resourceInf, 1, 3, {GROUP.Attribute.GROUND_APC})

    -- Resource Infantry Bravo is transported by up to 2 APCs.gu
    BlueChief:AddTransportToResource(ResourceInfBravo, 1, 2, {GROUP.Attribute.GROUND_APC})

    --- Create a resource list of mission types and required assets for the case that the zone is OCCUPIED.
    --
    -- Here, we create an enhanced CAS mission and employ at least on and at most two asset groups.
    -- NOTE that two objects are returned, the resource list (ResourceOccupied) and the first resource of that list (resourceCAS).
    local ResourceOccupied, resourceCAS=BlueChief:CreateResource(AUFTRAG.Type.CASENHANCED, 1, 2)
    -- We also add ARTY missions with at least one and at most two assets. We additionally require these to be MLRS groups (and not howitzers).
    BlueChief:AddToResource(ResourceOccupied, AUFTRAG.Type.GROUNDATTACK, 1, 2, nil)
    -- BlueChief:DeleteFromResource(ResourceOccupied, AUFTRAG.Type.ARTY)
    -- Add at least one RECON mission that uses UAV type assets.
    BlueChief:AddToResource(ResourceOccupied, AUFTRAG.Type.RECON, 1, nil)
    
    Blue_DetectionSetGroup = SET_GROUP:New()
    Blue_DetectionSetGroup:FilterCoalitions("blue")
    Blue_DetectionSetGroup:FilterStart()
    BlueIntel = INTEL:New(Blue_DetectionSetGroup, "blue", "CIA")
    BlueIntel:SetClusterAnalysis(true, true)
    --RedIntel:SetVerbosity(2)
    BlueIntel:__Start(2)

    BlueChief:AddCapZone(CapZone1,26000,400,180,25)
    BlueChief:AddCapZone(CapZone2,26000,400,180,25)
    BlueChief:AddCapZone(CapZone3,26000,400,180,25)
    BlueChief:AddCapZone(CapZone6,26000,400,180,25)
    BlueChief:AddCapZone(CapZone8,26000,400,180,25)
    BlueChief:AddCapZone(CapZone7,26000,400,180,25)
    BlueChief:AddBorderZone(CapZone1)
    BlueChief:AddBorderZone(CapZone2)
    BlueChief:AddBorderZone(CapZone3)
    BlueChief:AddBorderZone(CapZone10)
    BlueChief:AddBorderZone(CapZone11)
    BlueChief:AddConflictZone(CapZone4)
    BlueChief:AddConflictZone(CapZone5)
    BlueChief:AddConflictZone(CapZone6)
    BlueChief:AddConflictZone(CapZone7)

    BlueChief:SetResponseOnTarget(1, 2, 8, TARGET.Category.AIRCRAFT, AUFTRAG.Type.INTERCEPT, 1)
    BlueChief:SetResponseOnTarget(1, 2, 1, TARGET.Category.GROUND, AUFTRAG.Type.BAI, 1)
    BlueChief:SetResponseOnTarget(1, 2, 1, TARGET.Category.GROUND, AUFTRAG.Type.ARMOUREDATTACK, 4)

end

-- Create Red Chief
function CreateRedChief()
    RedAgents = SET_GROUP:New():FilterCoalitions("red"):FilterStart()

    -- Define Red Chief
      RedChief = CHIEF:New(coalition.side.RED, RedAgents)
     -- RedChief:SetTacticalOverviewOn()
      RedChief:SetVerbosity(5)

    -- Set strategy for Red Chief
     RedChief:SetStrategy(CHIEF.Strategy.AGGRESSIVE)
     RedChief:SetDefcon(CHIEF.DEFCON.RED)
     RedChief:SetBorderZones(redAirfieldszoneset)
     RedChief:SetConflictZones(blueAirfieldszoneset)

     RedChief:SetLimitMission(2, AUFTRAG.Type.ARTY)
     RedChief:SetLimitMission(2, AUFTRAG.Type.BARRAGE)
     RedChief:SetLimitMission(6, AUFTRAG.Type.GROUNDATTACK)
     RedChief:SetLimitMission(2, AUFTRAG.Type.BOMBING)
     RedChief:SetLimitMission(2, AUFTRAG.Type.RECON)
     RedChief:SetLimitMission(2, AUFTRAG.Type.BAI)
     RedChief:SetLimitMission(2, AUFTRAG.Type.INTERCEPT)
     RedChief:SetLimitMission(2, AUFTRAG.Type.SEAD)
     RedChief:SetLimitMission(4, AUFTRAG.Type.CAPTUREZONE)
     RedChief:SetLimitMission(2, AUFTRAG.Type.CASENHANCED)
     RedChief:SetLimitMission(2, AUFTRAG.Type.CAS)
     RedChief:SetLimitMission(20, Total)

     --local ResourceListEmpty, ResourceIFV=RedChief:CreateResource(AUFTRAG.Type.PATROLZONE,  1, 3, {GROUP.Attribute.GROUND_TANK,GROUP.Attribute.GROUND_APC})
     --local ResourceAlpha=RedChief:AddToResource(ResourceListEmpty, AUFTRAG.Type.ONGUARD, 1, 3, GROUP.Attribute.GROUND_TANK)
     --local ResourceBravo=RedChief:AddToResource(ResourceListEmpty, AUFTRAG.Type.ONGUARD, 1, 3, GROUP.Attribute.GROUND_APC)
     --local ResourceCharlie=RedChief:AddToResource(ResourceListEmpty, AUFTRAG.Type.ONGUARD, 1, 2, GROUP.Attribute.GROUND_SAM)
     -- Create a resource list for an empty zone and add an ONGUARD mission for up to three IFVs.
     local ResourceListEmpty, ResourceAPC=RedChief:CreateResource(AUFTRAG.Type.PATROLZONE,  0, 3, GROUP.Attribute.GROUND_APC)
     local ResourceInfAlpha=RedChief:AddToResource(ResourceListEmpty, AUFTRAG.Type.ONGUARD, 1, 3, GROUP.Attribute.GROUND_INFANTRY)
     local ResourceInfBravo=RedChief:AddToResource(ResourceListEmpty, AUFTRAG.Type.ONGUARD, 1, 3, GROUP.Attribute.GROUND_INFANTRY)
 
     -- Resource Infantry Alpha is transported by up to 3 transport helos.
     RedChief:AddTransportToResource(ResourceInfAlpha, 1, 3, {GROUP.Attribute.AIR_TRANSPORTHELO})
 
     -- Resource Infantry Bravo is transported by up to 2 APCs.
     RedChief:AddTransportToResource(ResourceInfBravo, 1, 2, {GROUP.Attribute.GROUND_APC})

         -- Here, we create an enhanced CAS mission and employ at least on and at most two asset groups.
    -- NOTE that two objects are returned, the resource list (ResourceOccupied) and the first resource of that list (resourceCAS).
    local ResourceOccupied, resourceCAS=RedChief:CreateResource(AUFTRAG.Type.CASENHANCED, 1, 1)
    -- We also add ARTY missions with at least one and at most two assets. We additionally require these to be MLRS groups (and not howitzers).
    RedChief:AddToResource(ResourceOccupied, AUFTRAG.Type.GROUNDATTACK, 1, 2, nil)
    -- Add at least one RECON mission that uses UAV type assets.
    RedChief:AddToResource(ResourceOccupied, AUFTRAG.Type.RECON, 1, nil)

    --allOpsZones:ForEachZone(
    --    function(opzone)
    --        RedChief:AddStrategicZone(opzone, nil, nil, ResourceOccupied, ResourceListEmpty)
    --    end
    --    )
    Red_DetectionSetGroup = SET_GROUP:New()
    Red_DetectionSetGroup:FilterCoalitions("red")
    Red_DetectionSetGroup:FilterStart()
    RedIntel = INTEL:New(Red_DetectionSetGroup, "red", "KGB")
    RedIntel:SetClusterAnalysis(true, true)
    --RedIntel:SetVerbosity(2)
    RedIntel:__Start(2)
    

    RedChief:AddCapZone(CapZone3,26000,400,180,25)
    RedChief:AddCapZone(CapZone4,26000,400,180,25)
    RedChief:AddCapZone(CapZone5,26000,400,180,25)
    RedChief:AddCapZone(CapZone8,26000,400,180,25)
    RedChief:AddCapZone(CapZone9,26000,400,180,25)
    RedChief:AddCapZone(CapZone6,26000,400,180,25)
    RedChief:AddConflictZone(CapZone1)
    RedChief:AddConflictZone(CapZone2)
    RedChief:AddConflictZone(CapZone10)
    RedChief:AddConflictZone(CapZone11)
    RedChief:AddBorderZone(CapZone3)
    RedChief:AddBorderZone(CapZone4)
    RedChief:AddBorderZone(CapZone5)
    RedChief:AddBorderZone(CapZone6)
    RedChief:SetResponseOnTarget(1, 1, 8, TARGET.Category.GROUND, AUFTRAG.Type.ARMOUREDATTACK, 4)
    RedChief:SetResponseOnTarget(1, 1, 3, TARGET.Category.AIRCRAFT, AUFTRAG.Type.INTERCEPT, 1)
    RedChief:SetResponseOnTarget(1, 1, 3, TARGET.Category.GROUND, AUFTRAG.Type.BAI, 1)
end

env.info("Ops Zones Started")

--Function to combine the above functions into deploying Red and blue gaurds and warehouses around airbases. 
function DeployForces()
    for _, airfieldName in ipairs(blueAirfields) do
        if airfieldName then
            env.info("Processing airfield: " .. airfieldName) -- Debugging
            airbaseParkingSummary(airfieldName)
            local warehouseName = "warehouse_" .. airfieldName
            local coalitionSide = "USA" -- 1 =USA
            SpawnBlueForces(airfieldName, warehouseName, coalitionSide, MinDistance, MaxDistance)
            env.info("Deployed at airfield: "..airfieldName)
        else
            env.info("No Blue Airbases found")
        end
    end
    for _, airfieldName in ipairs(redAirfields) do
        if airfieldName then
            env.info("Processing airfield: " .. airfieldName) -- Debugging
            airbaseParkingSummary(airfieldName)
            local warehouseName = "warehouse_" .. airfieldName
            local coalitionSide = "RUSSIA" -- 0 = Russia, 29 Egypt, 68, ussr
            SpawnRedForces(airfieldName, warehouseName, coalitionSide, MinDistance, MaxDistance)
            env.info("Deployed at airfield: "..airfieldName)
        else
            env.info("No Airbases found")
        end
    end
end


-- Warehouse Filtering collect all warehouses for use later.
local blueWarehouseSet = SET_STATIC:New():FilterCoalitions("blue"):FilterTypes("Warehouse"):FilterStart()
local redWarehouseSet = SET_STATIC:New():FilterCoalitions("red"):FilterTypes("Warehouse"):FilterStart()

-- Debug Warehouse Counts
env.info("Blue warehouse Count: " .. tostring(#blueWarehouseSet:GetSetObjects()))
env.info("Red warehouse Count: " .. tostring(#redWarehouseSet:GetSetObjects()))

-- OP Zone Filtering
local blueopzones = SET_OPSZONE:New():FilterCoalitions("blue"):FilterStart()
local redopzones = SET_OPSZONE:New():FilterCoalitions("red"):FilterStart()


-- Debug Total OPSZONE Count
local allOpsZones = SET_OPSZONE:New():FilterStart()
env.info("Total OPSZONE Count: " .. tostring(#allOpsZones:GetSetObjects()))

-- Check Actual Owner of All OPSZONEs
allOpsZones:ForEachZone(
    function(opzone)
        local coalition = opzone:GetOwner() -- FIXED: Use GetOwner() instead of GetCoalition()
        env.info("Zone: " .. opzone:GetName() .. " | Owner: " .. tostring(coalition))
    end
)

-- Iterate Blue OP Zones
blueopzones:ForEachZone(
    function(opzone)
        table.insert(blueAirfieldszones, opzone:GetZone())
        env.info("Blue OPSZONE added: " .. opzone:GetName())
    end
)

-- Iterate Red OP Zones
redopzones:ForEachZone(
    function(opzone)
        table.insert(redAirfieldszones, opzone:GetZone())
        env.info("Red OPSZONE added: " .. opzone:GetName())
    end
)



-- Iterate over blue warehouses and create airwings
function deployairwings()
    blueWarehouseSet:ForEachStatic(
        function(warehouse)
            local warehouseName = warehouse:GetName()
            local airwingName = GenerateUniqueSquadronName("Blue Airwing " .. warehouseName)
            local airfieldName = warehouseName:gsub("^warehouse_", "")
            local airwing = CreateBlueAirwing(warehouse, airwingName, airfieldName)  -- Get the airwing object
        end
    )

    -- Iterate over red warehouses and create airwings
    redWarehouseSet:ForEachStatic(
        function(warehouse)
            local warehouseName = warehouse:GetName()
            local airwingName = GenerateUniqueSquadronName("Red Airwing " .. warehouseName)
            local airfieldName = warehouseName:gsub("^warehouse_", "")
            local airwing = CreateRedAirwing(warehouse, airwingName, airfieldName)  -- Get the airwing object
        end
    )
end

----------------------------------------------------------------------------
----------------------------------------------------------------------------
----------------------------Start Mission-----------------------------------
----------------------------------------------------------------------------
----------------------------------------------------------------------------


CreateBlueChief()
CreateRedChief()
loadAirfields()
CreateAllAirfieldOpszones()
OPS_Zones:Start()
DeployForces()
deployairwings()
--TIMER:New(function()
--    enforceZoneUnitCounts(blueAirfieldszones)
--    enforceZoneUnitCounts(redAirfieldszones)
--end):Start(10)  -- Wait 10 secs after mission start

-- Call the initialize function at mission start
--initializeMission()
RedChief:__Start(1)
BlueChief:__Start(1)

--OPS_Zones = SET_OPSZONE:New():FilterOnce()
--OPS_Zones:Start()

--load persistent units
--enforceZoneUnitCountsFromOpsZones()


function monitoropszones()
    OPS_Zones:ForEachZone(function(opszone)
        env.info("Monitoring OPSZONE: " .. opszone:GetName())
        
        function opszone:OnAfterCaptured(From, Event, To, Coalition)

            -- Convert Coalition to a usable string
            local coalitionSide = (Coalition == coalition.side.BLUE and "blue") or "red"
            local airfieldName = opszone:GetZone():GetName()
            env.info("Deploying Airwing and Brigade HQ at "..airfieldName)
            local warehouseName = "warehouse_" .. airfieldName
            env.info("New warehouse name is: " .. warehouseName)

            -- Find and delete the existing airwing stock items
            local existingAirwing
            if coalitionSide == "blue" then
                existingAirwing = BlueAirwings[warehouseName]
            else
                existingAirwing = RedAirwings[warehouseName]
            end

            if existingAirwing then
                local stockInfo = existingAirwing:GetStockInfo()
                for stockItem, _ in pairs(stockInfo) do
                    existingAirwing:_DeleteStockItem(stockItem)
                end
                env.info("Existing airwing stock items deleted: " .. warehouseName)
                if coalitionSide == "blue" then
                    BlueAirwings[warehouseName] = nil
                else
                    RedAirwings[warehouseName] = nil
                end
            end

            -- Destroy the existing warehouse
            local warehouse = STATIC:FindByName(warehouseName)
            if warehouse then
                warehouse:Destroy()
                env.info("Warehouse destroyed: " .. warehouseName)
            end

            -- Spawn new forces and create a new airwing
            if coalitionSide == "blue" then
                coalitionSide = "USA"
                SpawnWarehouse(airfieldName, warehouseName, coalitionSide)
                SpawnBlueForces(airfieldName, warehouseName, coalitionSide, MinDistance, MaxDistance)
                warehouse = STATIC:FindByName(warehouseName)
                CreateBlueAirwing(warehouse, airwingName, airfieldName)
                
                 Blue_ctld:AddCTLDZone(airfieldName,CTLD.CargoZoneType.LOAD,SMOKECOLOR.Blue,true,true)
                 env.info("Blue ZONE added to CTLD LOAD ZONE: " .. airfieldName)
                
            elseif coalitionSide == "red" then
                coalitionSide = "RUSSIA"
                SpawnWarehouse(airfieldName, warehouseName, coalitionSide)
                SpawnRedForces(airfieldName, warehouseName, coalitionSide, MinDistance, MaxDistance)
                warehouse = STATIC:FindByName(warehouseName)
                CreateRedAirwing(warehouse, airwingName, airfieldName)

                 Red_ctld:AddCTLDZone(airfieldName,CTLD.CargoZoneType.LOAD,SMOKECOLOR.Red,true,true)
                 env.info("Red ZONE added to CTLD LOAD ZONE: " .. airfieldName)

            end
        end
    end)
end
----------------------------------
----------------------------------
---------PLayer Tasking ----------
function PlayerTaskingBlue()
    -- Settings - we want players to have a settings menu, be on imperial measures, and get directions as BR
    _SETTINGS:SetPlayerMenuOn()
    _SETTINGS:SetImperial()
    _SETTINGS:SetA2G_BR()
   
    -- Set up the A2G task controller for the blue side named "82nd Airborne"
    BlueTaskManagerA2G = PLAYERTASKCONTROLLER:New("82 Airbourne",coalition.side.Blue,PLAYERTASKCONTROLLER.Type.A2G)
   
    -- set locale to English
    BlueTaskManagerA2G:SetLocale("en")
   
    -- Set up detection with grup names *containing* "Blue Recce", these will add targets to our controller via detection. Can be e.g. a drone.
    BlueTaskManagerA2G:SetupIntel("Blue")
   
    -- Add a single Recce group name "Blue Humvee"
    --RedTaskManager:AddAgent(GROUP:FindByName("Blue"))
   
    -- Set the callsign for SRS and Menu name to be "Groundhog"
    BlueTaskManagerA2G:SetMenuName("Ghost Bat")
   
    -- Add accept- and reject-zones for detection
    -- Accept zones are handy to limit e.g. the engagement to a certain zone. The example is a round, mission editor created zone named "AcceptZone"
    BlueTaskManagerA2G:AddAcceptZone(ZONE:New("CAP_Zone_E"))
    BlueTaskManagerA2G:AddAcceptZone(ZONE:New("CAP_Zone_SE"))
    BlueTaskManagerA2G:AddAcceptZone(ZONE:New("CAP_Zone_Mid"))
    BlueTaskManagerA2G:AddAcceptZone(ZONE:New("CAP_Zone_W"))
    BlueTaskManagerA2G:AddAcceptZone(ZONE:New("CAP_Zone_SW"))
   
    -- Reject zones are handy to create borders. The example is a ZONE_POLYGON, created in the mission editor, late activated with waypoints, 
    -- named "AcceptZone#ZONE_POLYGON"
    --BlueTaskManager:AddRejectZone(ZONE:FindByName("RejectZone"))
   
    -- Set up using SRS for messaging
   --local hereSRSPath = "C:\\Program Files\\DCS-SimpleRadio-Standalone"
   --local hereSRSPort = 5002
    -- local hereSRSGoogle = "C:\\Program Files\\DCS-SimpleRadio-Standalone\\yourkey.json"
    BlueTaskManagerA2G:SetSRS({130,250},{radio.modulation.AM,radio.modulation.AM},hereSRSPath,"female","en-GB",hereSRSPort,"Microsoft Hazel Desktop",0.7,hereSRSGoogle)
   
    -- Controller will announce itself under these broadcast frequencies, handy to use cold-start frequencies here of your aircraft
    BlueTaskManagerA2G:SetSRSBroadcast({130,250},{radio.modulation.AM,radio.modulation.AM})
   
    -- Example: Manually add an AIRBASE as a target
    --BlueTaskManagerA2G:AddTarget(AIRBASE:FindByName(AIRBASE.Caucasus.Senaki_Kolkhi))
   
    -- Example: Manually add a COORDINATE as a target
    --BlueTaskManagerA2G:AddTarget(GROUP:FindByName("Scout Coordinate"):GetCoordinate())
   
    -- Set a whitelist for tasks
    BlueTaskManagerA2G:SetTaskWhiteList({AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING, AUFTRAG.Type.BOMBRUNWAY, AUFTRAG.Type.SEAD,AUFTRAG.Type.INTERCEPT,AUFTRAG.Type.CAP})
   
    -- Set target radius
    BlueTaskManagerA2G:SetTargetRadius(1000)
   -- BlueTaskManagerA2G:Verbose()  ---doesnt work
end
--PlayerTaskingBlue()
function PlayerTaskingRed()
    -- Settings - we want players to have a settings menu, be on imperial measures, and get directions as BR
  --_SETTINGS:SetPlayerMenuOn()
  --_SETTINGS:SetImperial()
  --_SETTINGS:SetA2G_BR()
   
    -- Set up the A2G task controller for the blue side named "82nd Airborne"
    RedTaskManagerA2G = PLAYERTASKCONTROLLER:New("31st Infantry",coalition.side.RED,PLAYERTASKCONTROLLER.Type.A2G)
   
    -- set locale to English
    RedTaskManagerA2G:SetLocale("en")
   
    -- Set up detection with grup names *containing* "Blue Recce", these will add targets to our controller via detection. Can be e.g. a drone.
    RedTaskManagerA2G:SetupIntel("Red")
   
    -- Add a single Recce group name "Blue Humvee"
    --RedTaskManager:AddAgent(GROUP:FindByName("Blue"))
   
    -- Set the callsign for SRS and Menu name to be "Groundhog"
    RedTaskManagerA2G:SetMenuName("SnakeEyes")
   
    -- Add accept- and reject-zones for detection
    -- Accept zones are handy to limit e.g. the engagement to a certain zone. The example is a round, mission editor created zone named "AcceptZone"
    RedTaskManagerA2G:AddAcceptZone(ZONE:New("CAP_Zone_E"))
    RedTaskManagerA2G:AddAcceptZone(ZONE:New("CAP_Zone_SE"))
    RedTaskManagerA2G:AddAcceptZone(ZONE:New("CAP_Zone_Mid"))
    RedTaskManagerA2G:AddAcceptZone(ZONE:New("CAP_Zone_W"))
    RedTaskManagerA2G:AddAcceptZone(ZONE:New("CAP_Zone_SW"))
   
    -- Reject zones are handy to create borders. The example is a ZONE_POLYGON, created in the mission editor, late activated with waypoints, 
    -- named "AcceptZone#ZONE_POLYGON"
    --BlueTaskManager:AddRejectZone(ZONE:FindByName("RejectZone"))
   
    -- Set up using SRS for messaging
   --local hereSRSPath = "C:\\Program Files\\DCS-SimpleRadio-Standalone"
   --local hereSRSPort = 5002
    -- local hereSRSGoogle = "C:\\Program Files\\DCS-SimpleRadio-Standalone\\yourkey.json"
    RedTaskManagerA2G:SetSRS({130,240},{radio.modulation.AM,radio.modulation.AM},hereSRSPath,"female","en-GB",hereSRSPort,"Microsoft Hazel Desktop",0.7,hereSRSGoogle)
   
    -- Controller will announce itself under these broadcast frequencies, handy to use cold-start frequencies here of your aircraft
    RedTaskManagerA2G:SetSRSBroadcast({127,240},{radio.modulation.AM,radio.modulation.AM})
   
    -- Example: Manually add an AIRBASE as a target
    --RedTaskManagerA2G:AddTarget(AIRBASE:FindByName(AIRBASE.Caucasus.Senaki_Kolkhi))
   
    -- Example: Manually add a COORDINATE as a target
    --RedTaskManagerA2G:AddTarget(GROUP:FindByName("Scout Coordinate"):GetCoordinate())
   
    -- Set a whitelist for tasks
    RedTaskManagerA2G:SetTaskWhiteList({AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING, AUFTRAG.Type.BOMBRUNWAY, AUFTRAG.Type.SEAD,AUFTRAG.Type.INTERCEPT,AUFTRAG.Type.CAP,AUFTRAG.NewTROOPTRANSPORT})
   
    -- Set target radius
    RedTaskManagerA2G:SetTargetRadius(1000)
   -- RedTaskManagerA2G:Verbose()---doesnt work
end
--PlayerTaskingRed()
------------------------------------------
------------------------------------------
--------- End Player Tasking--------------
------------------------------------------
------------------------------------------
-------------
-----CTLD----
-------------
function BlueOpsCTLD()
    env.info(string.format("###Blue CTLD FILE Start Load ###"))
    
    SETTINGS:SetPlayerMenuOff()
    
       Blue_ctld = CTLD:New(coalition.side.BLUE,nil,"23rd Transport Squadron")
    
       Blue_ctld:SetOwnSetPilotGroups(SET_GROUP:New():FilterCoalitions("blue"):FilterCategoryHelicopter():FilterFunction(
        function(grp)
        local _type = grp:GetTypeName()
        local retval = false
        if _type == "CH-47Fbl1" or _type == "UH-1H" or _type == "Mi-8MT" or _type == "Mi-8MTV2" or _type == "Mi-24P" or _type == "UH-60L"   then
            retval = true;
        end
        return retval
        end ):FilterStart())
       
       Blue_ctld.maximumHoverHeight = 35
       Blue_ctld.forcehoverload = false
       Blue_ctld.dropcratesanywhere = true
       Blue_ctld.buildtime = 10
       Blue_ctld:UnitCapabilities("UH-1H", true, true, 2, 12, 15, 3000)
       Blue_ctld:UnitCapabilities("MI-24P", true, true, 2, 12, 15, 3000)
       Blue_ctld:UnitCapabilities("MI-24V", true, true, 2, 12, 15, 3000)
       Blue_ctld:UnitCapabilities("CH-47", true, true, 8, 24, 30, 7200)
    
       Blue_ctld:__Start(5)
    
       -- add infantry unit called "Anti-Tank Small" using template "ATS", of type TROOP with size 3
       -- infantry units will be loaded directly from LOAD zones into the heli (matching number of free seats needed)
          Blue_ctld:AddTroopsCargo("Infantry Squad",{Group_Blue_Inf},CTLD_CARGO.Enum.TROOPS,3)
    
       -- add infantry unit called "Anti-Tank" using templates "AA" and "AA"", of type TROOP with size 4. No weight. We only have 2 in stock:
          Blue_ctld:AddTroopsCargo("Anti-Air",{Group_Blue_SAM},CTLD_CARGO.Enum.TROOPS,3,nil)
          
          Blue_ctld:AddTroopsCargo("M113",{Group_Blue_APC},CTLD_CARGO.Enum.TROOPS,4,nil)
          Blue_ctld:AddTroopsCargo("SHORAD",{Group_Blue_SAM},CTLD_CARGO.Enum.TROOPS,4,nil)
    --      Blue_ctld:AddTroopsCargo("Mechanised",{"Blue_Mech_Marder_Template","Ground_Blue_SPG_Stryker"},CTLD_CARGO.Enum.TROOPS,8,nil)
    
    
          -- add an engineers unit called "Wrenches" using template "Engineers", of type ENGINEERS with size 2. Engineers can be loaded, dropped,
       -- and extracted like troops. However, the will seek to build and/or repair crates found in a given radius. Handy if you can\'t stay
       -- to build or repair or under fire.
          Blue_ctld:AddTroopsCargo("Wrenches",{"Blue_CTLD_Wrenches"},CTLD_CARGO.Enum.ENGINEERS,4)
          Blue_ctld.EngineerSearch = 2000 -- teams will search for crates in this radius.
    
          -- add vehicle called "Humvee" using template "Humvee", of type VEHICLE, size 2, i.e. needs two crates to be build
       -- vehicles and FOB will be spawned as crates in a LOAD zone first. Once transported to DROP zones, they can be build into the objects
          Blue_ctld:AddCratesCargo("Marder Group",{Group_Blue_Mech},CTLD_CARGO.Enum.VEHICLE,2,500)
       -- if you want to add weight to your Heli, crates can have a weight in kg **per crate**. Fly carefully.
          Blue_ctld:AddCratesCargo("Hawk_Site", {Group_Blue_SAM_Site},CTLD_CARGO.Enum.VEHICLE,8,500)
       -- if you want to add weight to your Heli, crates can have a weight in kg **per crate**. Fly carefully.
          --Blue_ctld:AddCratesCargo("NASAM",{"Blue_NASAM_Template"},CTLD_CARGO.Enum.VEHICLE,18)
       -- if you want to add weight to your Heli, crates can have a weight in kg **per crate**. Fly carefully.
          Blue_ctld:AddCratesCargo("Leopard Group",{Group_Blue_Armoured},CTLD_CARGO.Enum.VEHICLE,4,500)
          Blue_ctld:AddCratesCargo("M109 Group",{Group_Blue_Arty},CTLD_CARGO.Enum.VEHICLE,2,500)
       -- if you want to add weight to your Heli, crates can have a weight in kg **per crate**. Fly carefully.
       -- add infantry unit called "Forward Ops Base" using template "FOB", of type FOB, size 4, i.e. needs four crates to be build:
          Blue_ctld:AddCratesCargo("Forward Ops Base",{"Blue_CTLD_FOB"},CTLD_CARGO.Enum.FOB,4)
    
       -- add crates to repair FOB or VEHICLE type units - the 2nd parameter needs to match the template you want to repair,
       -- e.g. the "Humvee" here refers back to the "Humvee" crates cargo added above (same template!)
          Blue_ctld:AddCratesRepair("Humvee Repair","Blue_Unarmed_Humvee_Template",CTLD_CARGO.Enum.REPAIR,1)
          Blue_ctld.repairtime = 300 -- takes 300 seconds to repair something
    
       -- add static cargo objects, e.g ammo chests - the name needs to refer to a STATIC object in the mission editor, 
       -- here: it\'s the UNIT name (not the GROUP name!), the second parameter is the weight in kg.
          --Blue_ctld:AddStaticsCargo("Blue_Ammo",500)
    
          blueAirfieldszoneset:ForEachZone(
            function(zone)
                local zonename = zone:GetName()
                Blue_ctld:AddCTLDZone(zonename,CTLD.CargoZoneType.LOAD,SMOKECOLOR.Blue,true,true)
              
                env.info("Blue ZONE added to CTLD LOAD ZONE: " .. zone:GetName())
            end
        )  
    
          -- Add a zone of type LOAD to our setup. Players can load any troops and crates here as defined in 1.2 above.
          -- "Loadzone" is the name of the zone from the ME. Players can load, if they are inside the zone.
          -- Smoke and Flare color for this zone is blue, it is active (can be used) and has a radio beacon.
           -- Add a zone of type DROP. Players can drop crates here.
          -- Smoke and Flare color for this zone is blue, it is active (can be used) and has a radio beacon.
          -- NOTE: Troops can be unloaded anywhere, also when hovering in parameters. 
          --moved  to zone empty function 
          --Blue_ctld:AddCTLDZone("Dropzone",CTLD.CargoZoneType.DROP,SMOKECOLOR.Red,true,true)
    
    
    env.info(string.format("###Blue CTLD FILE Loaded Succesfully###"))
    
end

function RedOpsCTLD()
    env.info(string.format("###Red CTLD FILE Start Load ###"))
    
    SETTINGS:SetPlayerMenuOff()
    
       Red_ctld = CTLD:New(coalition.side.RED,nil,"23rd Transport Squadron")
    
       Red_ctld:SetOwnSetPilotGroups(SET_GROUP:New():FilterCoalitions("red"):FilterCategoryHelicopter():FilterFunction(
        function(grp)
        local _type = grp:GetTypeName()
        local retval = false
        if _type == "CH-47Fbl1" or _type == "UH-1H" or _type == "Mi-8MT" or _type == "Mi-8MTV2" or _type == "Mi-24P" or _type == "UH-60L"   then
            retval = true;
        end
        return retval
        end ):FilterStart())
       
       Red_ctld.maximumHoverHeight = 35
       Red_ctld.forcehoverload = false
       Red_ctld.dropcratesanywhere = true
       Red_ctld.buildtime = 10
       Red_ctld:UnitCapabilities("UH-1H", true, true, 2, 12, 15, 3000)
       Red_ctld:UnitCapabilities("MI-24P", true, true, 2, 12, 15, 3000)
       Red_ctld:UnitCapabilities("MI-24V", true, true, 2, 12, 15, 3000)
       Red_ctld:UnitCapabilities("CH-47", true, true, 8, 24, 30, 7200)
    
       Red_ctld:__Start(5)
    
       -- add infantry unit called "Anti-Tank Small" using template "ATS", of type TROOP with size 3
       -- infantry units will be loaded directly from LOAD zones into the heli (matching number of free seats needed)
          Red_ctld:AddTroopsCargo("Infantry Squad",{Group_Red_Inf},CTLD_CARGO.Enum.TROOPS,3)
    
       -- add infantry unit called "Anti-Tank" using templates "AA" and "AA"", of type TROOP with size 4. No weight. We only have 2 in stock:
          Red_ctld:AddTroopsCargo("Anti-Air",{Group_Red_SAM},CTLD_CARGO.Enum.TROOPS,3,nil)
          
          Red_ctld:AddTroopsCargo("M113",{Group_Red_APC},CTLD_CARGO.Enum.TROOPS,4,nil)
          Red_ctld:AddTroopsCargo("SHORAD",{Group_Red_SAM},CTLD_CARGO.Enum.TROOPS,4,nil)
    --      Red_ctld:AddTroopsCargo("Mechanised",{"Red_Mech_Marder_Template","Ground_Red_SPG_Stryker"},CTLD_CARGO.Enum.TROOPS,8,nil)
    
    
          -- add an engineers unit called "Wrenches" using template "Engineers", of type ENGINEERS with size 2. Engineers can be loaded, dropped,
       -- and extracted like troops. However, the will seek to build and/or repair crates found in a given radius. Handy if you can\'t stay
       -- to build or repair or under fire.
          Red_ctld:AddTroopsCargo("Wrenches",{"Red_CTLD_Wrenches"},CTLD_CARGO.Enum.ENGINEERS,4)
          Red_ctld.EngineerSearch = 2000 -- teams will search for crates in this radius.
    
          -- add vehicle called "Humvee" using template "Humvee", of type VEHICLE, size 2, i.e. needs two crates to be build
       -- vehicles and FOB will be spawned as crates in a LOAD zone first. Once transported to DROP zones, they can be build into the objects
          Red_ctld:AddCratesCargo("Marder Group",{Group_Red_Mech},CTLD_CARGO.Enum.VEHICLE,2,500)
       -- if you want to add weight to your Heli, crates can have a weight in kg **per crate**. Fly carefully.
          Red_ctld:AddCratesCargo("Hawk_Site", {Group_Red_SAM_Site},CTLD_CARGO.Enum.VEHICLE,8,500)
       -- if you want to add weight to your Heli, crates can have a weight in kg **per crate**. Fly carefully.
          --Red_ctld:AddCratesCargo("NASAM",{"Red_NASAM_Template"},CTLD_CARGO.Enum.VEHICLE,18)
       -- if you want to add weight to your Heli, crates can have a weight in kg **per crate**. Fly carefully.
          Red_ctld:AddCratesCargo("Leopard Group",{Group_Red_Armoured},CTLD_CARGO.Enum.VEHICLE,4,500)
          Red_ctld:AddCratesCargo("M109 Group",{Group_Red_Arty},CTLD_CARGO.Enum.VEHICLE,2,500)
       -- if you want to add weight to your Heli, crates can have a weight in kg **per crate**. Fly carefully.
       -- add infantry unit called "Forward Ops Base" using template "FOB", of type FOB, size 4, i.e. needs four crates to be build:
          Red_ctld:AddCratesCargo("Forward Ops Base",{"Red_CTLD_FOB"},CTLD_CARGO.Enum.FOB,4)
    
       -- add crates to repair FOB or VEHICLE type units - the 2nd parameter needs to match the template you want to repair,
       -- e.g. the "Humvee" here refers back to the "Humvee" crates cargo added above (same template!)
          Red_ctld:AddCratesRepair("Humvee Repair","Red_Unarmed_Humvee_Template",CTLD_CARGO.Enum.REPAIR,1)
          Red_ctld.repairtime = 300 -- takes 300 seconds to repair something
    
       -- add static cargo objects, e.g ammo chests - the name needs to refer to a STATIC object in the mission editor, 
       -- here: it\'s the UNIT name (not the GROUP name!), the second parameter is the weight in kg.
          --Red_ctld:AddStaticsCargo("Red_Ammo",500)
    
          redAirfieldszoneset:ForEachZone(
            function(zone)
                local zonename = zone:GetName()
                Red_ctld:AddCTLDZone(zonename,CTLD.CargoZoneType.LOAD,SMOKECOLOR.Red,true,true)
              
                env.info("Red ZONE added to CTLD LOAD ZONE: " .. zone:GetName())
            end
        )  
    
          -- Add a zone of type LOAD to our setup. Players can load any troops and crates here as defined in 1.2 above.
          -- "Loadzone" is the name of the zone from the ME. Players can load, if they are inside the zone.
          -- Smoke and Flare color for this zone is Red, it is active (can be used) and has a radio beacon.
           -- Add a zone of type DROP. Players can drop crates here.
          -- Smoke and Flare color for this zone is Red, it is active (can be used) and has a radio beacon.
          -- NOTE: Troops can be unloaded anywhere, also when hovering in parameters. 
          --moved  to zone empty function 
          --Red_ctld:AddCTLDZone("Dropzone",CTLD.CargoZoneType.DROP,SMOKECOLOR.Red,true,true)

    env.info(string.format("###Red CTLD FILE Loaded Succesfully###"))
    
end

BlueOpsCTLD()
RedOpsCTLD()

-------------------------------------------
-------------------------------------------
---------End CTLD------------------------
-------------------------------------------
-------------------------------------------

--------------------------------------------
--------------------------------------------
------------------Airwing Production--------
--------------------------------------------

local function ProduceAirwing(warehouseName, airwing, Coalition)
    local factory = STATIC:FindByName(warehouseName)

   
    -- Check that factory is alive.
    if factory and factory:IsAlive() then
        env.info(string.format("Producing for airwing: %s for %s", warehouseName, Coalition))
        
        -- Function to safely check payload and add if it's 2 or less
        local function IncreaseIfBelowLimit(payload)
            if payload then
                local currentAmount = airwing:GetPayloadAmount(payload) or 0
                if currentAmount <= 2 then
                    airwing:IncreasePayloadAmount(payload, 1)
                    env.info(string.format("Increased payload for %s, new amount: %d", warehouseName, currentAmount + 1))
                else
                    env.info(string.format("Skipped increasing payload for %s (already >2)", warehouseName))
                end
            else
                env.info(string.format("Warning: payload does not exist for %s", warehouseName))
            end
        end


        if Coalition == "Blue" then
            IncreaseIfBelowLimit(Blue_payload_Fighter_AA)
            IncreaseIfBelowLimit(Blue_payload_LtFighter_SEAD)
            IncreaseIfBelowLimit(Blue_payload_Fighter_CAS)
            IncreaseIfBelowLimit(Blue_payload_LtFighter_AA)
            IncreaseIfBelowLimit(Blue_payload_LtFighter_CAS)
            IncreaseIfBelowLimit(Blue_payload_Attack_CAS)
            IncreaseIfBelowLimit(Blue_payload_helo_Trans)
            IncreaseIfBelowLimit(Blue_payload_helo_CAS)
            IncreaseIfBelowLimit(Blue_payload_Awacs)
            
        elseif Coalition == "Red" then
            IncreaseIfBelowLimit(Red_payload_Fighter_AA)
            IncreaseIfBelowLimit(Red_payload_Fighter_SEAD)
            IncreaseIfBelowLimit(Red_payload_Fighter_CAS)
            IncreaseIfBelowLimit(Red_payload_LtFighter_AA)
            IncreaseIfBelowLimit(Red_payload_LtFighter_CAS)
            IncreaseIfBelowLimit(Red_payload_Attack_CAS)
            IncreaseIfBelowLimit(Red_payload_helo_CAS)
            IncreaseIfBelowLimit(Red_payload_helo_trans)
            IncreaseIfBelowLimit(Red_payload_Awacs)
        else
            env.info("Coalition not found")
        end

        -- Function to safely get payload amount
        local function GetPayloadSafe(payload)
            return payload and airwing:GetPayloadAmount(payload) or 0
        end
        
        local N1, N2, N3, N4, N5, N6
        if Coalition == "Blue" then
            N1 = GetPayloadSafe(Blue_payload_Fighter_AA)
            N2 = GetPayloadSafe(Blue_payload_Fighter_SEAD)
            N3 = GetPayloadSafe(Blue_payload_Fighter_CAS)
            N4 = GetPayloadSafe(Blue_payload_LtFighter_AA)
            N5 = GetPayloadSafe(Blue_payload_LtFighter_CAS)
            N6 = GetPayloadSafe(Blue_payload_Attack_CAS)
            N7 = GetPayloadSafe(Blue_payload_helo_CAS)
            N8 = GetPayloadSafe(Blue_payload_helo_Trans)
            N9 = GetPayloadSafe(Blue_payload_Awacs)
        elseif Coalition == "Red" then
            N1 = GetPayloadSafe(Red_payload_Fighter_AA)
            N2 = GetPayloadSafe(Red_payload_Attack_SEAD)
            N3 = GetPayloadSafe(Red_payload_Fighter_CAS)
            N4 = GetPayloadSafe(Red_payload_LtFighter_AA)
            N5 = GetPayloadSafe(Red_payload_LtFighter_CAS)
            N6 = GetPayloadSafe(Red_payload_Attack_CAS)
            N7 = GetPayloadSafe(Red_payload_helo_CAS)
            N8 = GetPayloadSafe(Red_payload_helo_trans)
            N9 = GetPayloadSafe(Red_payload_Awacs)
        else
            env.info("Coalition not found")
        end

        -- Log payload info
        env.info(string.format(
            "Payloads available after production at %s: AA=%d, SEAD=%d, CAS=%d, LtAA=%d, LtCAS=%d, AttackCAS=%d, heloCAS=%d, heloTrans=%d, AWACS=%d",
            warehouseName, N1 or 0, N2 or 0, N3 or 0, N4 or 0, N5 or 0, N6 or 0, N7 or 0, N8 or 0, N9 or 0
        ))
        if Coalition == "Blue" then 
        local airfieldName = warehouseName:gsub("^warehouse_", "")
        local Sqn1 = airwing:GetSquadron("Blue Fighter Squadron "..airfieldName)
        local Sqn2 = airwing:GetSquadron("Blue Light Fighter Squadron "..airfieldName)
        local Sqn3 = airwing:GetSquadron("Blue Attack Squadron "..airfieldName)
        local Sqn4 = airwing:GetSquadron("Blue Transport Squadron "..airfieldName)
        local Sqn5 = airwing:GetSquadron("Blue CAS Squadron "..airfieldName)
        local Sqn6 = airwing:GetSquadron("Blue_AWACS")
        
        env.info("Producing assets for Blue Airwing: " .. airfieldName)
            if Sqn1  then
                    local Nsqn1 = Sqn1:CountAssets()
                    if Nsqn1 < 2 then
                    env.info(string.format("###Squadron %s has %d assets###", Sqn1:GetName(), Nsqn1)) 
                    airwing:AddAssetToSquadron(Sqn1, 2)
                    env.info(string.format("Added 2 assets to squadron %s. New total: %d", Sqn1:GetName(), Sqn1:CountAssets()))
                else
                    env.info(string.format("No assets Added to squadron %s.  Total Assets: %d", Sqn1:GetName(), Sqn1:CountAssets()))
                    end
            end
            if Sqn2  then
                    local Nsqn2 = Sqn2:CountAssets()
                    if Nsqn2 < 2 then
                    env.info(string.format("###Squadron %s has %d assets###", Sqn2:GetName(), Nsqn2)) 
                    airwing:AddAssetToSquadron(Sqn2, 2)
                    env.info(string.format("Added 2 assets to squadron %s. New total: %d", Sqn2:GetName(), Sqn2:CountAssets()))
                    else
                        env.info(string.format("No assets Added to squadron %s.  Total Assets: %d", Sqn2:GetName(), Sqn2:CountAssets()))
                    end
            end
            if Sqn3  then
                    local Nsqn3 = Sqn3:CountAssets()
                    if Nsqn3 < 2 then
                    env.info(string.format("###Squadron %s has %d assets###", Sqn3:GetName(), Nsqn3)) 
                    airwing:AddAssetToSquadron(Sqn3, 2)
                    env.info(string.format("Added 2 assets to squadron %s. New total: %d", Sqn3:GetName(), Sqn3:CountAssets()))
                    else
                        env.info(string.format("No assets Added to squadron %s.  Total Assets: %d", Sqn3:GetName(), Sqn3:CountAssets()))
                    end
            end
            if Sqn4  then
                    local Nsqn4 = Sqn4:CountAssets()
                    if Nsqn4 < 2 then
                    env.info(string.format("###Squadron %s has %d assets###", Sqn4:GetName(), Nsqn4)) 
                    airwing:AddAssetToSquadron(Sqn4, 2)
                    env.info(string.format("Added 2 assets to squadron %s. New total: %d", Sqn4:GetName(), Sqn4:CountAssets()))
                    else
                        env.info(string.format("No assets Added to squadron %s.  Total Assets: %d", Sqn4:GetName(), Sqn4:CountAssets()))
                    end
            end
            if Sqn5  then
                    local Nsqn5 = Sqn5:CountAssets()
                    if Nsqn5 < 2 then
                    env.info(string.format("###Squadron %s has %d assets###", Sqn5:GetName(), Nsqn5)) 
                    airwing:AddAssetToSquadron(Sqn5, 2)
                    env.info(string.format("Added 2 assets to squadron %s. New total: %d", Sqn5:GetName(), Sqn5:CountAssets()))
                    else
                        env.info(string.format("No assets Added to squadron %s.  Total Assets: %d", Sqn5:GetName(), Sqn5:CountAssets()))
                    end
            end
            if Sqn6  then
                    local Nsqn6 = Sqn6:CountAssets()
                    if Nsqn6 < 2 then
                    env.info(string.format("###Squadron %s has %d assets###", Sqn6:GetName(), Nsqn6)) 
                    airwing:AddAssetToSquadron(Sqn6, 2)
                    env.info(string.format("Added 2 assets to squadron %s. New total: %d", Sqn6:GetName(), Sqn6:CountAssets()))
                    else
                        env.info(string.format("No assets Added to squadron %s.  Total Assets: %d", Sqn6:GetName(), Sqn6:CountAssets()))
                    end
            end


        end
        if Coalition == "Red" then
        local airfieldName = warehouseName:gsub("^warehouse_", "")
        local Sqn1 = airwing:GetSquadron("Red Fighter Squadron "..airfieldName)
        local Sqn2 = airwing:GetSquadron("Red Light Fighter Squadron "..airfieldName)
        local Sqn3 = airwing:GetSquadron("Red Attack Squadron "..airfieldName)
        local Sqn4 = airwing:GetSquadron("Red Transport Squadron "..airfieldName)
        local Sqn5 = airwing:GetSquadron("Red CAS Squadron "..airfieldName)
        local Sqn6 = airwing:GetSquadron("Red_AWACS")
        
        env.info("Producing assets for Red Airwing: " .. airfieldName)
            if Sqn1  then
                    local Nsqn1 = Sqn1:CountAssets()
                    if Nsqn1 < 2 then
                    env.info(string.format("###Squadron %s has %d assets###", Sqn1:GetName(), Nsqn1)) 
                    airwing:AddAssetToSquadron(Sqn1, 2)
                    env.info(string.format("Added 2 assets to squadron %s. New total: %d", Sqn1:GetName(), Sqn1:CountAssets()))
                else
                    env.info(string.format("No assets Added to squadron %s.  Total Assets: %d", Sqn1:GetName(), Sqn1:CountAssets()))
                    end
            end
            if Sqn2  then
                    local Nsqn2 = Sqn2:CountAssets()
                    if Nsqn2 < 2 then
                    env.info(string.format("###Squadron %s has %d assets###", Sqn2:GetName(), Nsqn2)) 
                    airwing:AddAssetToSquadron(Sqn2, 2)
                    env.info(string.format("Added 2 assets to squadron %s. New total: %d", Sqn2:GetName(), Sqn2:CountAssets()))
                    else
                        env.info(string.format("No assets Added to squadron %s.  Total Assets: %d", Sqn2:GetName(), Sqn2:CountAssets()))
                    end
            end
            if Sqn3  then
                    local Nsqn3 = Sqn3:CountAssets()
                    if Nsqn3 < 2 then
                    env.info(string.format("###Squadron %s has %d assets###", Sqn3:GetName(), Nsqn3)) 
                    airwing:AddAssetToSquadron(Sqn3, 2)
                    env.info(string.format("Added 2 assets to squadron %s. New total: %d", Sqn3:GetName(), Sqn3:CountAssets()))
                    else
                        env.info(string.format("No assets Added to squadron %s.  Total Assets: %d", Sqn3:GetName(), Sqn3:CountAssets()))
                    end
            end
            if Sqn4  then
                    local Nsqn4 = Sqn4:CountAssets()
                    if Nsqn4 < 2 then
                    env.info(string.format("###Squadron %s has %d assets###", Sqn4:GetName(), Nsqn4)) 
                    airwing:AddAssetToSquadron(Sqn4, 2)
                    env.info(string.format("Added 2 assets to squadron %s. New total: %d", Sqn4:GetName(), Sqn4:CountAssets()))
                    else
                        env.info(string.format("No assets Added to squadron %s.  Total Assets: %d", Sqn4:GetName(), Sqn4:CountAssets()))
                    end
            end
            if Sqn5  then
                    local Nsqn5 = Sqn5:CountAssets()
                    if Nsqn5 < 2 then
                    env.info(string.format("###Squadron %s has %d assets###", Sqn5:GetName(), Nsqn5)) 
                    airwing:AddAssetToSquadron(Sqn5, 2)
                    env.info(string.format("Added 2 assets to squadron %s. New total: %d", Sqn5:GetName(), Sqn5:CountAssets()))
                    else
                        env.info(string.format("No assets Added to squadron %s.  Total Assets: %d", Sqn5:GetName(), Sqn5:CountAssets()))
                    end
            end
            if Sqn6  then
                    local Nsqn6 = Sqn6:CountAssets()
                    if Nsqn6 < 2 then
                    env.info(string.format("###Squadron %s has %d assets###", Sqn6:GetName(), Nsqn6)) 
                    airwing:AddAssetToSquadron(Sqn6, 2)
                    env.info(string.format("Added 2 assets to squadron %s. New total: %d", Sqn6:GetName(), Sqn6:CountAssets()))
                    else
                        env.info(string.format("No assets Added to squadron %s.  Total Assets: %d", Sqn6:GetName(), Sqn6:CountAssets()))
                    end
            end
        end    
    
    end
end


--------------------------------------------------
-- Function to produce brigade assets for a given warehouse and brigade
-- Coalition is either "Blue" or "Red"
--------------------------------------------------

function Producebrigade(warehouseName, brigade, Coalition)
    if Coalition == "Blue" then 
        local airfieldName = warehouseName:gsub("^warehouse_", "")
        local Plt1 = brigade:GetPlatoon("Blue Motorised Platoon "..airfieldName)
        local Plt2 = brigade:GetPlatoon("Blue Mechanised Platoon "..airfieldName)
        local Plt3 = brigade:GetPlatoon("Blue Armoured Platoon "..airfieldName)
        local Plt4 = brigade:GetPlatoon("Blue Artillary Platoon "..airfieldName)
        local Plt5 = brigade:GetPlatoon("Blue Logistics Platoon "..airfieldName)
        local Plt6 = brigade:GetPlatoon("Blue Infantry Platoon "..airfieldName)
        local Plt7 = brigade:GetPlatoon("Blue SAM Platoon "..airfieldName)
        env.info("Producing assets for Blue Brigade: " .. airfieldName)
        if Plt1  then
            local Nplt1 = Plt1:CountAssets()
            if Nplt1 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt1:GetName(), Nplt1)) 
            brigade:AddAssetToSquadron(Plt1, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt1:GetName(), Plt1:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt1:GetName(), Plt1:CountAssets()))
            end
        end
        if Plt2  then
            local Nplt2 = Plt2:CountAssets()
            if Nplt2 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt2:GetName(), Nplt2)) 
            brigade:AddAssetToSquadron(Plt2, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt2:GetName(), Plt2:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt2:GetName(), Plt2:CountAssets()))
            end
        end
        if Plt3  then
            local Nplt3 = Plt3:CountAssets()
            if Nplt3 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt3:GetName(), Nplt3)) 
            brigade:AddAssetToSquadron(Plt3, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt3:GetName(), Plt3:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt3:GetName(), Plt3:CountAssets()))
            end
        end 
        if Plt4  then
            local Nplt4 = Plt4:CountAssets()
            if Nplt4 < 2 then
            env.info(string.format("###Platoon %s has %d assets###", Plt4:GetName(), Nplt4)) 
            brigade:AddAssetToSquadron(Plt4, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt4:GetName(), Plt4:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt4:GetName(), Plt4:CountAssets()))
            end
        end
        if Plt5  then
            local Nplt5 = Plt5:CountAssets()
            if Nplt5 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt5:GetName(), Nplt5)) 
            brigade:AddAssetToSquadron(Plt5, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt5:GetName(), Plt5:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt5:GetName(), Plt5:CountAssets()))
            end
        end
        if Plt6  then
            local Nplt6 = Plt6:CountAssets()
            if Nplt6 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt6:GetName(), Nplt6)) 
            brigade:AddAssetToSquadron(Plt6, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt6:GetName(), Plt6:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt6:GetName(), Plt6:CountAssets()))
            end
        end
        if Plt7  then
            local Nplt7 = Plt7:CountAssets()
            if Nplt7 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt7:GetName(), Nplt7)) 
            brigade:AddAssetToSquadron(Plt7, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt7:GetName(), Plt7:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt7:GetName(), Plt7:CountAssets()))
            end
        end
    end

    if Coalition == "Red" then 
        local airfieldName = warehouseName:gsub("^warehouse_", "")
        local Plt1 = brigade:GetPlatoon("Red Motorised Platoon "..airfieldName)
        local Plt2 = brigade:GetPlatoon("Red Mechanised Platoon "..airfieldName)
        local Plt3 = brigade:GetPlatoon("Red Armoured Platoon "..airfieldName)
        local Plt4 = brigade:GetPlatoon("Red Artillary Platoon "..airfieldName)
        local Plt5 = brigade:GetPlatoon("Red Logistics Platoon "..airfieldName)
        local Plt6 = brigade:GetPlatoon("Red Infantry Platoon "..airfieldName)
        local Plt7 = brigade:GetPlatoon("Red SAM Platoon "..airfieldName)
        env.info("Producing assets for Red Brigade: " .. airfieldName)
        --motorised platoon
        if Plt1  then
            local Nplt1 = Plt1:CountAssets()
            if Nplt1 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt1:GetName(), Nplt1)) 
            brigade:AddAssetToSquadron(Plt1, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt1:GetName(), Plt1:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt1:GetName(), Plt1:CountAssets()))
            end
        end
        --mechanised platoon
        if Plt2  then
            local Nplt2 = Plt2:CountAssets()
            if Nplt2 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt2:GetName(), Nplt2)) 
            brigade:AddAssetToSquadron(Plt2, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt2:GetName(), Plt2:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt2:GetName(), Plt2:CountAssets()))
            end
        end
        --armoured platoon
        if Plt3  then
            local Nplt3 = Plt3:CountAssets()
            if Nplt3 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt3:GetName(), Nplt3))
            brigade:AddAssetToSquadron(Plt3, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt3:GetName(), Plt3:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt3:GetName(), Plt3:CountAssets()))
            end
        end
        --artillary platoon
        if Plt4  then
            local Nplt4 = Plt4:CountAssets()
            if Nplt4 < 2 then
            env.info(string.format("###Platoon %s has %d assets###", Plt4:GetName(), Nplt4)) 
            brigade:AddAssetToSquadron(Plt4, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt4:GetName(), Plt4:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt4:GetName(), Plt4:CountAssets()))
            end
        end
        --logistics platoon
        if Plt5  then
            local Nplt5 = Plt5:CountAssets()
            if Nplt5 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt5:GetName(), Nplt5)) 
            brigade:AddAssetToSquadron(Plt5, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt5:GetName(), Plt5:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt5:GetName(), Plt5:CountAssets()))
            end
        end
        --infantry platoon
        if Plt6  then
            local Nplt6 = Plt6:CountAssets()
            if Nplt6 < 3 then
            env.info(string.format("###Platoon %s has %d assets###", Plt6:GetName(), Nplt6)) 
            brigade:AddAssetToSquadron(Plt6, 2)
            env.info(string.format("Added 2 assets to Platoon %s. New total: %d", Plt6:GetName(), Plt6:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt6:GetName(), Plt6:CountAssets()))
            end
        end
        --SAM platoon
        if Plt7  then
            local Nplt7 = Plt7:CountAssets()
            if Nplt7 < 2 then
            env.info(string.format("###Platoon %s has %d assets###", Plt7:GetName(), Nplt7)) 
            brigade:AddAssetToSquadron(Plt7, 1)
            env.info(string.format("Added 1 assets to Platoon %s. New total: %d", Plt7:GetName(), Plt7:CountAssets()))
            else
            env.info(string.format("No assets Added to Platoon %s.  Total Assets: %d", Plt7:GetName(), Plt7:CountAssets()))
            end
        end
    end
end




  -- Start a timer to simulate payload production. -use in create airwing function
TIMER:New(function()
    for warehouseName, airwing in pairs(BlueAirwings) do
        local factory = STATIC:FindByName("Blue_Airwing_Factory")
        
        -- Check that factory is alive.
        if factory and factory:IsAlive() then
            local Coalition = "Blue"
            env.info("Producing for airwing: ###".. airwing:GetName() .."### for Blue")
            ProduceAirwing(warehouseName, airwing, Coalition)
        end
    end
    for warehouseName, brigade in pairs(BlueBrigades) do
        local factory = STATIC:FindByName("Blue_Airwing_Factory")
        
        -- Check that factory is alive.
        if factory and factory:IsAlive() then
            local Coalition = "Blue"
            env.info("Producing for Brigade: ###".. brigade:GetName() .."### for Blue")
            Producebrigade(warehouseName, brigade, Coalition)
        end
    end
    
end):Start(20 * 60, 20 * 60)

TIMER:New(function()
    for warehouseName, airwing in pairs(RedAirwings) do
        local factory = STATIC:FindByName("Red_Airwing_Factory")
        
        -- Check that factory is alive.
        if factory and factory:IsAlive() then
            local Coalition = "Red"
            env.info("Producing for airwing: ###"..airwing:GetName().."### for Red")
            ProduceAirwing(warehouseName, airwing, Coalition)
                     
        end
    end
    for warehouseName, brigade in pairs(RedBrigades) do
        local factory = STATIC:FindByName("Red_Airwing_Factory")
        
        -- Check that factory is alive.
        if factory and factory:IsAlive() then
            local Coalition = "Red"
            env.info("Producing for Brigade: ###".. brigade:GetName() .."### for Red")
            Producebrigade(warehouseName, brigade, Coalition)
        end
    end
end):Start(20 * 60, 20 * 60)




-------------
-----CTLD----
-------------
local function FindAirwingByAirfield(airfieldName)
    for warehouseName, airwing in pairs(BlueAirwings) do
        if string.find(warehouseName, airfieldName) then
            env.info("Found airwing for airfield: " .. airfieldName)
            return airwing
        end
    end
    env.info("No airwing found for airfield: " .. airfieldName)
    return nil
end
--------------------
-------AI GCI--------
--------------------
-- Set up AWACS called "AWACS North". It will use the AwacsAW Airwing set up above and be of the "blue" coalition. Homebase is Kutaisi.
-- The AWACS Orbit Zone is a round zone set in the mission editor named "Awacs Orbit", the FEZ is a Polygon-Zone called "Rock" we have also
-- set up in the mission editor with a late activated helo named "Rock#ZONE_POLYGON". Note this also sets the BullsEye to be referenced as "Rock".
-- The CAP station zone is called "Fremont". We will be on 255 AM.
local Blueawacs = AWACS:New("Darkstar",BlueAwacsAirwing,"blue"    ,AIRBASE:FindByName(BlueAwacsAirfieldName),"CAP_Zone_E",ZONE:FindByName("Bulls"),"CAP_Zone_E",255,radio.modulation.AM )
Blueawacs:SetEscort(2,ENUMS.Formation.FixedWing.FingerFour.Group,{x=-500,y=50,z=500},45)
-- Callsign will be "Focus". We'll be a Angels 30, doing 300 knots, orbit leg to 88deg with a length of 25nm.
Blueawacs:SetAwacsDetails(CALLSIGN.AWACS.Darkstar,1,30,300,88,25)
-- Set up SRS on port 5002 - change the below to your path and port
Blueawacs:SetSRS("C:\\Program Files\\DCS-SimpleRadio-Standalone","Male","en-US",5002)
-- Add a "red" border we don't want to cross, set up in the mission editor with a late activated helo named "Red Border#ZONE_POLYGON"
--Blueawacs:SetRejectionZone(ZONE:FindByName("Red Border"))
-- Our CAP flight will have the callsign "Ford", we want 4 AI planes, Time-On-Station is four hours, doing 300 kn IAS.
--Blueawacs:SetAICAPDetails(CALLSIGN.Aircraft.Ford,4,4,300)
-- We're modern (default), e.g. we have EPLRS and get more fill-in information on detections
Blueawacs:SetModernEraAggressive()

-- And start
Blueawacs:__Start(5)

local Redawacs = AWACS:New("Magic",RedAwacsAirwing,"red",AIRBASE:FindByName(BlueAwacsAirfieldName),"CAP_Zone_W",ZONE:FindByName("Bulls"),"CAP_Zone_E",245,radio.modulation.AM )
-- set one escort group; this example has two units in the template group, so they can fly a nice formation.
Redawacs:SetEscort(2,ENUMS.Formation.FixedWing.FingerFour.Group,{x=-500,y=50,z=500},45)
-- Callsign will be "Focus". We'll be a Angels 30, doing 300 knots, orbit leg to 88deg with a length of 25nm.
Redawacs:SetAwacsDetails(CALLSIGN.AWACS.Magic,1,30,300,88,25)
-- Set up SRS on port 5002 - change the below to your path and port
Redawacs:SetSRS("C:\\Program Files\\DCS-SimpleRadio-Standalone","Male","en-US",5002)
-- Add a "red" border we don't want to cross, set up in the mission editor with a late activated helo named "Red Border#ZONE_POLYGON"
--Redawacs:SetRejectionZone(ZONE:FindByName("Red Border"))
-- Our CAP flight will have the callsign "Ford", we want 4 AI planes, Time-On-Station is four hours, doing 300 kn IAS.
--Redawacs:SetAICAPDetails(CALLSIGN.Aircraft.Ford,4,4,300)
-- We're modern (default), e.g. we have EPLRS and get more fill-in information on detections
Redawacs:SetModernEraAggressive()
-- And start
Redawacs:__Start(5)
---------------------
---------------------
--End AI GCI-----
---------------------
---------------------
TIMER:New(PlayerTaskingBlue):Start(20)
TIMER:New(PlayerTaskingRed):Start(21)

----------------------------------
----------------------------------
--Test Capture Zone Functions-----
----------------------------------
----------------------------------
---just checking ops zones -----

----Used just to test a zone capture event by destroying all units.
function destroyzonered()
    local zonename = "As Salihiyah"
    local testOpszone = ZONE:New(zonename) -- Use ZONE:New instead of FindByName

    -- Create a SET_GROUP to collect all active groups inside the zone
    local SetGroups = SET_GROUP:New():FilterActive():FilterZones({testOpszone}):FilterOnce()

    SetGroups:ForEachGroup(function(group)
        env.info("Found group: " .. group:GetName() .. " - Destroying!!!")
        group:Destroy() -- Correct destroy method
    end)

    -- Respawn new group after destruction
    Spawn_Near_airbase(Group_Blue_Mech, "As Salihiyah", MinDistance, MaxDistance)
end

function destroyzoneblue()
    local zonename = "Melez"
    local testOpszone = ZONE:New(zonename) -- Use ZONE:New instead of FindByName

    -- Create a SET_GROUP to collect all active groups inside the zone
    local SetGroups = SET_GROUP:New():FilterActive():FilterZones({testOpszone}):FilterOnce()

    SetGroups:ForEachGroup(function(group)
        env.info("Found group: " .. group:GetName() .. " - Destroying!!!")
        group:Destroy() -- Correct destroy method
    end)

    -- Respawn new group after destruction
    Spawn_Near_airbase(Group_Red_Mech, "Melez", MinDistance, MaxDistance)
end

function OpszoneCapture()
    OPS_Zones:ForEachZone(function(opszone)
        local coalitionID = opszone:GetOwner()
        local airfieldName = opszone:GetName()
        local coalition = 0
        if coalitionID == 0 then
            coalition = "neutral"
        elseif coalitionID == 1 then
            coalition = "red"
        elseif coalitionID == 2 then
            coalition = "blue"
        end

        local opscoalforces = SET_UNIT:New():FilterZones({opszone:GetZone()}):FilterCoalitions(coalition):FilterOnce()
        local opscoalforcescount = opscoalforces:CountAlive()
        env.info("Checking number of units in OPSZONE: " .. airfieldName .. " - Coalition: " .. coalitionID .. " - Count: " .. opscoalforcescount)
                -- Save unit counts for this opszone
        
    
        -- Helper to count existing AUFTRAGs for this zone and chief
        local function CountAuftragsForZone(chief, auftragType, zone)
            local count = 0
            for _, mission in pairs(chief:GetMissions() or {}) do
                if mission and mission.Type == auftragType and mission.Zone and mission.Zone:GetName() == zone:GetName() then
                    count = count + 1
                end
            end
            return count
        end
        ------------------------------------
        --unit-level persistence------------
        --Save the units checked to a file--
        ------------------------------------
            local file = io.open(zoneUnitFile, "w")
            if not file then return end
            file:write("ZoneUnitCounts = {\n")
            OPS_Zones:ForEachZone(function(opszone)
                local zone = opszone:GetZone()
                local zoneName = zone:GetName()
                local set = SET_UNIT:New():FilterZones({zone}):FilterCategories("ground"):FilterOnce()
                local typeCounts = {}
                set:ForEachUnit(function(unit)
                    local typeName = unit:GetTypeName()
                    typeCounts[typeName] = (typeCounts[typeName] or 0) + 1
                end)
                file:write('  ["'..zoneName..'"] = {\n')
                for typeName, count in pairs(typeCounts) do
                    file:write('    ["'..typeName..'"] = '..count..',\n')
                end
                file:write('  },\n')
            end)
            file:write("}\n")
            file:close()
            env.info("Zone unit counts saved (unit-level, OPS_Zones).")
        ------------------------------
        ---finish unit persistence----
        ------------------------------
        if opscoalforcescount < 5 then
            env.info("Launching assault against OPSZONE: " .. airfieldName)
            if coalitionID == 1 then
                -- RED owns, BLUE attacks
                local auftragType = AUFTRAG.Type.PATROLZONE
                local existing = CountAuftragsForZone(BlueChief, auftragType, opszone:GetZone())
                if existing < 2 then -- Allow up to 2 patrols, adjust as needed
                    local groundpatrol = AUFTRAG:NewPATROLZONE(opszone:GetZone(),80,nil,"On Road")
                    BlueChief:AddMission(groundpatrol)
                    MESSAGE:New("Blue Forces are launching a new patrol against OPSZONE: " .. airfieldName, 20):ToAll()
                else
                    env.info("BlueChief already has " .. existing .. " patrol missions for " .. airfieldName)
                end
            elseif coalitionID == 2 then
                -- BLUE owns, RED attacks
                local auftragType = AUFTRAG.Type.PATROLZONE
                local existing = CountAuftragsForZone(RedChief, auftragType, opszone:GetZone())
                if existing < 2 then -- Allow up to 2 patrols, adjust as needed
                    local groundpatrol = AUFTRAG:NewPATROLZONE(opszone:GetZone(),80,nil,"On Road")
                    RedChief:AddMission(groundpatrol)
                    MESSAGE:New("Red Forces are launching a new patrol against OPSZONE: " .. airfieldName, 20):ToAll()
                else
                    env.info("RedChief already has " .. existing .. " patrol missions for " .. airfieldName)
                end
            end
        end
    end)
end

TIMER:New(OpszoneCapture):Start(125, 120) -- every 120 seconds after 125s
TIMER:New(monitoropszones):Start(60)



------------------------------------
------------------------------------
-----Player Cap flight requests-----
------------------------------------
------------------------------------
PlayerRequests = {}         -- [playerGroupName] = true/false
PlayerMissions = {}  -- [playerName] = { {type="CAP", id=..., label=...}, ... }
CoalitionReqCount = { [coalition.side.BLUE] = 0, [coalition.side.RED] = 0 }
MAX_REQ_PER_COALITION = 20
MAX_REQ_PER_PLAYER = 6

function CreateCAPZoneForPlayer(playerGroup, zoneObject, label)
    if not playerGroup or not playerGroup:IsAlive() then
        MESSAGE:New("Your group is not alive or not found!", 10):ToGroup(playerGroup)
        return
    end

    local playerName = playerGroup:GetName()
    local coalitionSide = playerGroup:GetCoalition()

    PlayerRequests[playerName] = PlayerRequests[playerName] or 0
    PlayerMissions[playerName] = PlayerMissions[playerName] or {}
    if PlayerRequests[playerName] >= MAX_REQ_PER_PLAYER then
        MESSAGE:New("You already have the maximum number of active missions (" .. MAX_REQ_PER_PLAYER .. ")!", 10):ToGroup(playerGroup)
        return
    end
    if CoalitionReqCount[coalitionSide] >= MAX_REQ_PER_COALITION then
        MESSAGE:New("Your coalition has reached the maximum number of CAP missions!", 10):ToGroup(playerGroup)
        return
    end

    local capZoneName, capZoneRadius, coord
    if zoneObject then
        capZoneName = "CAP_Zone_" .. label .. "_" .. playerName
        capZoneRadius = zoneObject:GetRadius() or 10000
        coord = zoneObject:GetCoordinate()
    else
        capZoneName = "CAP_Zone_Player_" .. playerName
        capZoneRadius = 10000
        coord = playerGroup:GetCoordinate()
    end

    local capZone = ZONE_RADIUS:New(capZoneName, coord:GetVec2(), capZoneRadius)
    local CapRequest = AUFTRAG:NewCAP(capZone, 30000, 400):SetPriority(20, 1, 3):SetRequiredAssets(2, 2):SetRepeatOnFailure(3):SetDuration(60*30)

    if coalitionSide == coalition.side.BLUE then
        BlueChief:AddMission(CapRequest)
        MESSAGE:New("Blue CAP zone assigned!", 10):ToGroup(playerGroup)
    elseif coalitionSide == coalition.side.RED then
        RedChief:AddMission(CapRequest)
        MESSAGE:New("Red CAP zone assigned!", 10):ToGroup(playerGroup)
    end

    PlayerRequests[playerName] = PlayerRequests[playerName] + 1
    CoalitionReqCount[coalitionSide] = CoalitionReqCount[coalitionSide] + 1
    table.insert(PlayerMissions[playerName], {type="CAP", id=capZoneName, label=label or capZoneName})
end

-- Replace your old functions with wrappers:
function CreateCAPZoneOverNamedZone(playerGroup, zoneObject, label)
    CreateCAPZoneForPlayer(playerGroup, zoneObject, label)
end

function CreateCAPZoneOverPlayer(playerGroup)
    CreateCAPZoneForPlayer(playerGroup, nil, "Player")
end

-- CAS Enhanced Mission (Over Player)
function RequestCASEnhancedMission(playerGroup)
    if not playerGroup or not playerGroup:IsAlive() then
        MESSAGE:New("Your group is not alive or not found!", 10):ToGroup(playerGroup)
        return
    end

    local playerName = playerGroup:GetName()
    local coalitionSide = playerGroup:GetCoalition()

    PlayerRequests[playerName] = PlayerRequests[playerName] or 0
    PlayerMissions[playerName] = PlayerMissions[playerName] or {}
    if PlayerRequests[playerName] >= MAX_REQ_PER_PLAYER then
        MESSAGE:New("You already have the maximum number of active missions (" .. MAX_REQ_PER_PLAYER .. ")!", 10):ToGroup(playerGroup)
        return
    end
    if CoalitionReqCount[coalitionSide] >= MAX_REQ_PER_COALITION then
        MESSAGE:New("Your coalition has reached the maximum number of A2A/CAS missions!", 10):ToGroup(playerGroup)
        return
    end

    local casZoneName = "CAS_Zone_Player_" .. playerName
    local casZoneRadius = 10000
    local coord = playerGroup:GetCoordinate()
    local casZone = ZONE_RADIUS:New(casZoneName, coord:GetVec2(), casZoneRadius)
    local altitude = 5000
    local speed = 350
    local rangeMax = 25
    local noEngageZoneSet = nil
    local targetTypes = {"Helicopters", "Ground Units", "Light armed ships"}
    local casMission = AUFTRAG:NewCASENHANCED(casZone, altitude, speed, rangeMax, noEngageZoneSet, targetTypes)
    casMission:SetPriority(20, 1, 3):SetRequiredAssets(2, 2):SetRepeatOnFailure(3):SetDuration(60*30)

    if coalitionSide == coalition.side.BLUE then
        BlueChief:AddMission(casMission)
        MESSAGE:New("Blue CAS Enhanced mission assigned at your location!", 10):ToGroup(playerGroup)
    elseif coalitionSide == coalition.side.RED then
        RedChief:AddMission(casMission)
        MESSAGE:New("Red CAS Enhanced mission assigned at your location!", 10):ToGroup(playerGroup)
    end

    PlayerRequests[playerName] = PlayerRequests[playerName] + 1
    CoalitionReqCount[coalitionSide] = CoalitionReqCount[coalitionSide] + 1
    table.insert(PlayerMissions[playerName], {type="CAS", id=casZoneName, label="CAS Over Player"})
end

function AddDynamicNearestCASMenu(playerGroup, A2GMenu)
    local playerCoalition = playerGroup:GetCoalition()
    local enemyAirfields = (playerCoalition == coalition.side.BLUE) and redAirfields or blueAirfields

    MENU_GROUP_COMMAND:New(playerGroup, "Refresh Nearest Enemy airfields", A2GMenu, function()
        local playerCoord = playerGroup:GetCoordinate()
        local airfieldDistances = {}
        for _, airfieldName in ipairs(enemyAirfields) do
            local airbase = AIRBASE:FindByName(airfieldName)
            if airbase then
                local afCoord = airbase:GetCoordinate()
                local dist = playerCoord:Get2DDistance(afCoord)
                table.insert(airfieldDistances, {name = airfieldName, distance = dist})
            end
        end
        table.sort(airfieldDistances, function(a, b) return a.distance < b.distance end)
        local dynamicMenu = MENU_GROUP:New(playerGroup, "CAS at Nearest Enemy Airbase (Now)", A2GMenu)
        for i = 1, math.min(5, #airfieldDistances) do
            local airfieldName = airfieldDistances[i].name
            MENU_GROUP_COMMAND:New(playerGroup, "Request CAS at " .. airfieldName, dynamicMenu, function()
                RequestCASEnhancedAtAirbase(playerGroup, airfieldName)
            end)
        end
    end)
end

function RequestCASEnhancedMission(playerGroup)
    if not playerGroup or not playerGroup:IsAlive() then
        MESSAGE:New("Your group is not alive or not found!", 10):ToGroup(playerGroup)
        return
    end

    local playerName = playerGroup:GetName()
    local coalitionSide = playerGroup:GetCoalition()

    PlayerRequests[playerName] = PlayerRequests[playerName] or 0
    if PlayerRequests[playerName] >= MAX_REQ_PER_PLAYER then
        MESSAGE:New("You already have the maximum number of active missions (" .. MAX_REQ_PER_PLAYER .. ")!", 10):ToGroup(playerGroup)
        return
    end

    if CoalitionReqCount[coalitionSide] >= MAX_REQ_PER_COALITION then
        MESSAGE:New("Your coalition has reached the maximum number of A2A/CAS missions!", 10):ToGroup(playerGroup)
        return
    end

    local casZoneName = "CAS_Zone_Player_" .. playerName
    local casZoneRadius = 10000
    local coord = playerGroup:GetCoordinate()
    local casZone = ZONE_RADIUS:New(casZoneName, coord:GetVec2(), casZoneRadius)
    casZone:DrawZone(300, {1,1,0}, 2, {1,1,0}, true)

    local altitude = 5000
    local speed = 350
    local rangeMax = 25
    local noEngageZoneSet = nil
    local targetTypes = {"Helicopters", "Ground Units", "Light armed ships"}

    local casMission = AUFTRAG:NewCASENHANCED(casZone, altitude, speed, rangeMax, noEngageZoneSet, targetTypes)
    casMission:SetPriority(20, 1, 3):SetRequiredAssets(2, 2):SetRepeatOnFailure(3):SetDuration(60*30)

    if coalitionSide == coalition.side.BLUE then
        BlueChief:AddMission(casMission)
        MESSAGE:New("Blue CAS Enhanced mission assigned at your location!", 10):ToGroup(playerGroup)
    elseif coalitionSide == coalition.side.RED then
        RedChief:AddMission(casMission)
        MESSAGE:New("Red CAS Enhanced mission assigned at your location!", 10):ToGroup(playerGroup)
    end

    PlayerRequests[playerName] = PlayerRequests[playerName] + 1
    CoalitionReqCount[coalitionSide] = CoalitionReqCount[coalitionSide] + 1
end

-- Helper function to request CAS at a specific airbase
function RequestCASEnhancedAtAirbase(playerGroup, airfieldName)
    if not playerGroup or not playerGroup:IsAlive() then
        MESSAGE:New("Your group is not alive or not found!", 10):ToGroup(playerGroup)
        return
    end

    local playerName = playerGroup:GetName()
    local coalitionSide = playerGroup:GetCoalition()

    PlayerRequests[playerName] = PlayerRequests[playerName] or 0
    PlayerMissions[playerName] = PlayerMissions[playerName] or {}
    if PlayerRequests[playerName] >= MAX_REQ_PER_PLAYER then
        MESSAGE:New("You already have the maximum number of active missions (" .. MAX_REQ_PER_PLAYER .. ")!", 10):ToGroup(playerGroup)
        return
    end
    if CoalitionReqCount[coalitionSide] >= MAX_REQ_PER_COALITION then
        MESSAGE:New("Your coalition has reached the maximum number of A2A/CAS missions!", 10):ToGroup(playerGroup)
        return
    end

    local airbase = AIRBASE:FindByName(airfieldName)
    if not airbase then
        MESSAGE:New("Airbase not found: " .. airfieldName, 10):ToGroup(playerGroup)
        return
    end

    local casZoneName = "CAS_Zone_" .. airfieldName .. "_" .. playerName
    local casZoneRadius = 10000
    local coord = airbase:GetCoordinate()
    local casZone = ZONE_RADIUS:New(casZoneName, coord:GetVec2(), casZoneRadius)
    local altitude = 2000
    local speed = 350
    local rangeMax = 25
    local noEngageZoneSet = nil
    local targetTypes = {"Helicopters", "Ground Units", "Light armed ships"}
    local casMission = AUFTRAG:NewCASENHANCED(casZone, altitude, speed, rangeMax, noEngageZoneSet, targetTypes)
    casMission:SetPriority(20, 1, 3):SetRequiredAssets(2, 2):SetRepeatOnFailure(3):SetDuration(60*30)

    if coalitionSide == coalition.side.BLUE then
        BlueChief:AddMission(casMission)
        MESSAGE:New("Blue CAS Enhanced mission assigned at " .. airfieldName, 10):ToGroup(playerGroup)
    elseif coalitionSide == coalition.side.RED then
        RedChief:AddMission(casMission)
        MESSAGE:New("Red CAS Enhanced mission assigned at " .. airfieldName, 10):ToGroup(playerGroup)
    end

    PlayerRequests[playerName] = PlayerRequests[playerName] + 1
    CoalitionReqCount[coalitionSide] = CoalitionReqCount[coalitionSide] + 1
    table.insert(PlayerMissions[playerName], {type="CAS", id=casZoneName, label="CAS at " .. airfieldName})
end
function AddDynamicNearestCAPMenus(playerGroup, A2AMenu)
    local playerCoalition = playerGroup:GetCoalition()
    local friendlyAirfields = (playerCoalition == coalition.side.BLUE) and blueAirfields or redAirfields
    local enemyAirfields = (playerCoalition == coalition.side.BLUE) and redAirfields or blueAirfields

    -- Helper to build sorted nearest list
    local function getNearestAirfields(airfieldList, playerCoord)
        local airfieldDistances = {}
        for _, airfieldName in ipairs(airfieldList) do
            local airbase = AIRBASE:FindByName(airfieldName)
            if airbase then
                local afCoord = airbase:GetCoordinate()
                local dist = playerCoord:Get2DDistance(afCoord)
                table.insert(airfieldDistances, {name = airfieldName, distance = dist})
            end
        end
        table.sort(airfieldDistances, function(a, b) return a.distance < b.distance end)
        return airfieldDistances
    end

    -- Single menu item to update nearest airfields
    MENU_GROUP_COMMAND:New(playerGroup, "Update Nearest Airfields", A2AMenu, function()
        -- Optionally: Remove previous dynamic menus here if you want to avoid clutter

        local playerCoord = playerGroup:GetCoordinate()

        -- Friendly submenu
        local nearestFriendly = getNearestAirfields(friendlyAirfields, playerCoord)
        local friendlyMenu = MENU_GROUP:New(playerGroup, "Nearest Friendly Airfields", A2AMenu)
        for i = 1, math.min(5, #nearestFriendly) do
            local airfieldName = nearestFriendly[i].name
            MENU_GROUP_COMMAND:New(playerGroup, "Request CAP at " .. airfieldName, friendlyMenu, function()
                CreateCAPZoneOverNamedZone(playerGroup, AIRBASE:FindByName(airfieldName):GetZone(), airfieldName)
            end)
        end

        -- Enemy submenu
        local nearestEnemy = getNearestAirfields(enemyAirfields, playerCoord)
        local enemyMenu = MENU_GROUP:New(playerGroup, "Nearest Enemy Airfields", A2AMenu)
        for i = 1, math.min(5, #nearestEnemy) do
            local airfieldName = nearestEnemy[i].name
            MENU_GROUP_COMMAND:New(playerGroup, "Request CAP at " .. airfieldName, enemyMenu, function()
                CreateCAPZoneOverNamedZone(playerGroup, AIRBASE:FindByName(airfieldName):GetZone(), airfieldName)
            end)
        end
    end)
end
function RequestEscortMission(playerGroup)
    if not playerGroup or not playerGroup:IsAlive() then
        MESSAGE:New("Your group is not alive or not found!", 10):ToGroup(playerGroup)
        return
    end

    local playerName = playerGroup:GetName()
    local coalitionSide = playerGroup:GetCoalition()

    PlayerRequests[playerName] = PlayerRequests[playerName] or 0
    PlayerMissions[playerName] = PlayerMissions[playerName] or {}
    if PlayerRequests[playerName] >= MAX_REQ_PER_PLAYER then
        MESSAGE:New("You already have the maximum number of active missions (" .. MAX_REQ_PER_PLAYER .. ")!", 10):ToGroup(playerGroup)
        return
    end
    if CoalitionReqCount[coalitionSide] >= MAX_REQ_PER_COALITION then
        MESSAGE:New("Your coalition has reached the maximum number of A2A missions!", 10):ToGroup(playerGroup)
        return
    end

    local offset = {x = -100, y = 0, z = 200}
    local engageDistance = 32
    local targetTypes = {"Air"}
    local escortMission = AUFTRAG:NewESCORT(playerGroup, offset, engageDistance, targetTypes)
    escortMission:SetPriority(20, 1, 3):SetRequiredAssets(2, 2):SetRepeatOnFailure(3):SetDuration(60*30)

    if coalitionSide == coalition.side.BLUE then
        BlueChief:AddMission(escortMission)
        MESSAGE:New("Blue escort mission assigned to your group!", 10):ToGroup(playerGroup)
    elseif coalitionSide == coalition.side.RED then
        RedChief:AddMission(escortMission)
        MESSAGE:New("Red escort mission assigned to your group!", 10):ToGroup(playerGroup)
    end

    PlayerRequests[playerName] = PlayerRequests[playerName] + 1
    CoalitionReqCount[coalitionSide] = CoalitionReqCount[coalitionSide] + 1
    table.insert(PlayerMissions[playerName], {type="ESCORT", id="ESCORT_"..playerName, label="Escort"})
end
function AddActiveMissionsMenu(playerGroup, rootMenu)
    playerGroup.RootMenu = rootMenu -- Store for later use
    MENU_GROUP_COMMAND:New(playerGroup, "Refresh Active Missions", rootMenu, function()
        local playerName = playerGroup:GetName()
        local missions = PlayerMissions[playerName] or {}

        if playerGroup.ActiveMissionsMenu then
            playerGroup.ActiveMissionsMenu:Remove()
        end

        local activeMenu = MENU_GROUP:New(playerGroup, "Active Missions", rootMenu)
        playerGroup.ActiveMissionsMenu = activeMenu

        if #missions == 0 then
            MENU_GROUP_COMMAND:New(playerGroup, "No active missions", activeMenu, function() end)
        else
            for idx, mission in ipairs(missions) do
                local label = string.format("[%d] %s (%s)", idx, mission.type, mission.label or mission.id or "")
                local thisIdx = idx
                MENU_GROUP_COMMAND:New(playerGroup, "Release " .. label, activeMenu, function()
                    ReleasePlayerMissionByIndex(playerGroup, thisIdx)
                end)
            end
        end
    end)
end

function ReleasePlayerMissionByIndex(playerGroup, idx)
    local playerName = playerGroup:GetName()
    local coalitionSide = playerGroup:GetCoalition()
    if not PlayerMissions[playerName] or not PlayerMissions[playerName][idx] then
        MESSAGE:New("No such mission to release.", 10):ToGroup(playerGroup)
        return
    end

    local mission = table.remove(PlayerMissions[playerName], idx)
    PlayerRequests[playerName] = #PlayerMissions[playerName]
    CoalitionReqCount[coalitionSide] = math.max(0, CoalitionReqCount[coalitionSide] - 1)

    -- Optionally: Add logic to actually remove the mission from the Chief if needed

    MESSAGE:New("Released mission: " .. (mission.label or mission.type), 10):ToGroup(playerGroup)
end
function AddDynamicNearestG2GMenus(playerGroup, G2GMenu)
    local playerCoalition = playerGroup:GetCoalition()
    local friendlyAirfields = (playerCoalition == coalition.side.BLUE) and blueAirfields or redAirfields
    local enemyAirfields = (playerCoalition == coalition.side.BLUE) and redAirfields or blueAirfields

    -- Helper to build sorted nearest list
    local function getNearestAirfields(airfieldList, playerCoord)
        local airfieldDistances = {}
        for _, airfieldName in ipairs(airfieldList) do
            local airbase = AIRBASE:FindByName(airfieldName)
            if airbase then
                local afCoord = airbase:GetCoordinate()
                local dist = playerCoord:Get2DDistance(afCoord)
                table.insert(airfieldDistances, {name = airfieldName, distance = dist})
            end
        end
        table.sort(airfieldDistances, function(a, b) return a.distance < b.distance end)
        return airfieldDistances
    end

    -- CAPTUREZONE missions (enemy airfields)
    MENU_GROUP_COMMAND:New(playerGroup, "Update Nearest Enemy Airfields (Capture)", G2GMenu, function()
        local playerCoord = playerGroup:GetCoordinate()
        local nearestEnemy = getNearestAirfields(enemyAirfields, playerCoord)
        local captureMenu = MENU_GROUP:New(playerGroup, "Capture Nearest Enemy Airfields", G2GMenu)
        for i = 1, math.min(5, #nearestEnemy) do
            local airfieldName = nearestEnemy[i].name
            MENU_GROUP_COMMAND:New(playerGroup, "Capture " .. airfieldName, captureMenu, function()
                local opsZone = OPSZONE:New(ZONE_AIRBASE:New(airfieldName, 5000)):SetDrawZone(true)
                local speed = 80 -- knots for ground units
                local altitude = 0 -- not used for ground
                local formation = "Off Road"
                local auftrag = AUFTRAG:NewCAPTUREZONE(opsZone, playerCoalition, speed, altitude, formation)
                if playerCoalition == coalition.side.BLUE then
                    BlueChief:AddMission(auftrag)
                    MESSAGE:New("Blue CAPTUREZONE mission assigned at " .. airfieldName, 10):ToGroup(playerGroup)
                else
                    RedChief:AddMission(auftrag)
                    MESSAGE:New("Red CAPTUREZONE mission assigned at " .. airfieldName, 10):ToGroup(playerGroup)
                end
            end)
        end
    end)

    -- PATROLZONE missions (friendly airfields)
    MENU_GROUP_COMMAND:New(playerGroup, "Update Nearest Friendly Airfields (Patrol)", G2GMenu, function()
        local playerCoord = playerGroup:GetCoordinate()
        local nearestFriendly = getNearestAirfields(friendlyAirfields, playerCoord)
        local patrolMenu = MENU_GROUP:New(playerGroup, "Patrol Nearest Friendly Airfields", G2GMenu)
        for i = 1, math.min(5, #nearestFriendly) do
            local airfieldName = nearestFriendly[i].name
            MENU_GROUP_COMMAND:New(playerGroup, "Patrol " .. airfieldName, patrolMenu, function()
                local patrolZone = ZONE_AIRBASE:New(airfieldName, 5000)
                local speed = 20 -- knots for ground units
                local altitude = 0 -- not used for ground
                local formation = "Off Road"
                local auftrag = AUFTRAG:NewPATROLZONE(patrolZone, speed, altitude, formation)
                if playerCoalition == coalition.side.BLUE then
                    BlueChief:AddMission(auftrag)
                    MESSAGE:New("Blue PATROLZONE mission assigned at " .. airfieldName, 10):ToGroup(playerGroup)
                else
                    RedChief:AddMission(auftrag)
                    MESSAGE:New("Red PATROLZONE mission assigned at " .. airfieldName, 10):ToGroup(playerGroup)
                end
            end)
        end
    end)
end
function AddMenuForAllPlayers()
    local playerSet = SET_GROUP:New():FilterCategoryAirplane():FilterCategoryHelicopter():FilterStart()
    playerSet:ForEachGroup(function(group)
        if group:IsPlayer() then
            -- Root menu for player
            local rootMenu = MENU_GROUP:New(group, "Player Requests")
            -- A2A submenu
            local A2AMenu = MENU_GROUP:New(group, "A2A", rootMenu)
            --A2G Submenu
            local A2GMenu = MENU_GROUP:New(group, "A2G", rootMenu)
            -- G2G submenu
            local G2GMenu = MENU_GROUP:New(group, "G2G", rootMenu)
            -- Dynamic CAP zone over player
            MENU_GROUP_COMMAND:New(group, "Request CAP (Over Me)", A2AMenu, function()
                CreateCAPZoneOverPlayer(group)
            end)
            --add escort mission menu item
            MENU_GROUP_COMMAND:New(group, "Request Escort (Escort Me)", A2AMenu, function()
                RequestEscortMission(group)
            end)
            -- Under A2A or A2G menu: 
            MENU_GROUP_COMMAND:New(group, "Request CAS Enhanced (Over Me)", A2GMenu, function()
                RequestCASEnhancedMission(group)
            end)
            AddDynamicNearestCASMenu(group, A2GMenu)
            AddDynamicNearestCAPMenus(group, A2AMenu)
            AddActiveMissionsMenu(group, rootMenu)
            --ReleasePlayerMissionByIndex(group, rootMenu)
            AddDynamicNearestG2GMenus(group, G2GMenu)
        end
    end)
end

------------------------------
-----ATC Ground Operations----
-----Airbase Traffic management
------------------------------
ATC_Controllers = {}

function ATCGroundOps()
    local Freq = 118.00
    for _, airbase in ipairs(world.getAirbases()) do
        Freq = Freq + 0.50
        local abName = airbase:getName()
        local atc = FLIGHTCONTROL:New(abName, Freq, 0, "C:\\Program Files\\DCS-SimpleRadio-Standalone", 5002)
        atc:SetParkingGuard(Group_Neutral_Inf)
            :SetSpeedLimitTaxi(25)
            :SetLimitTaxi(1, true, 1)
            :SetLimitLanding(2, 0)
            :SetMarkHoldingPattern(false)
            :SetVerbosity(1)
            :SetRunwayRepairtime(7200)
        atc:Start()
        ATC_Controllers[abName] = atc
        env.info("ATC Ground Ops: " .. abName .. " at frequency " .. Freq)
    end
end
function RestartAllATCGroundOps()
    for abName, atc in pairs(ATC_Controllers) do
        if atc.Stop then atc:Stop() end
        atc:Start()
        env.info("Restarted ATC Ground Ops for: " .. abName)
    end
end

function ForceStuckFlightsToReadyTaxiIfNoTaxiing()
    local now = timer.getTime()
    for abName, atc in pairs(ATC_Controllers) do
        local taxiing = atc:GetFlights("TAXIOUT", nil, nil)
        local taxiingCount = taxiing and #taxiing or 0

        if taxiingCount == 0 then
            local flights = atc:GetFlights("PARKING", nil, nil)
            for _, flight in ipairs(flights or {}) do
                if flight.Tparking and (now - flight.Tparking > 600) then -- 10 minutes
                    if flight.Group and flight.Group:IsAlive() then
                        atc:SetFlightStatus(flight, "READYTX")
                        env.info(string.format("Force-taxi: %s at %s set to READYTX after %d seconds in PARKING", flight.Group:GetName(), abName, now - flight.Tparking))
                    else
                        env.info("Skipped force-taxi: flight group is nil or not alive")
                    end
                end
            end
        end
    end
end
function DespawnStuckFlights()
    local now = timer.getTime()
    local foundStuck = false
    for abName, atc in pairs(ATC_Controllers) do
        local parkingFlights = atc:GetFlights("PARKING", nil, nil)
        for _, flight in ipairs(parkingFlights or {}) do
            if flight.Tparking and (now - flight.Tparking > 1200) then -- 20 minutes
                if flight.Group and flight.Group:IsAlive() and not flight.Group:IsPlayer() then
                    env.info(string.format("Despawning stuck flight (PARKING): %s at %s after %d seconds", flight.Group:GetName(), abName, now - flight.Tparking))
                    flight.Group:Destroy(true)
                    foundStuck = true
                else
                    env.info("Skipped despawn: flight group is nil, not alive, or is a player")
                end
            end
        end
        local taxiReturnFlights = atc:GetFlights("TAXIRETURN", nil, nil) or atc:GetFlights("TAXIIN", nil, nil)
        for _, flight in ipairs(taxiReturnFlights or {}) do
            local tTaxiReturn = flight.Ttaxireturn or flight.Ttaxiin
            if tTaxiReturn and (now - tTaxiReturn > 300) then -- 5 minutes
                if flight.Group and flight.Group:IsAlive() and not flight.Group:IsPlayer() then
                    env.info(string.format("Despawning stuck flight (TAXIRETURN/TAXIIN): %s at %s after %d seconds", flight.Group:GetName(), abName, now - tTaxiReturn))
                    flight.Group:Destroy(true)
                    foundStuck = true
                else
                    env.info("Skipped despawn: flight group is nil, not alive, or is a player")
                end
            end
        end
    end
    if foundStuck then
        env.info("Stuck flights found and cleaned up, rechecking in 30 seconds.")
        TIMER:New(DespawnStuckFlights):Start(30)
    end
end


--TIMER:New(DespawnStuckFlights):Start(300, 300) -- Regular check every 5 minutes
--TIMER:New(ForceStuckFlightsToReadyTaxiIfNoTaxiing):Start(60*5, 60*5) -- Check every 5 minutes




---------------
---------------


-- Schedule menu creation at mission start or after a delay
SCHEDULER:New(nil, AddMenuForAllPlayers, {}, 12,30)
--SCHEDULER:New(nil, RedTaskManagerA2G:SetMenuName("SnakeEyes"),{},12,30)
--SCHEDULER:New(nil, BlueTaskManagerA2G:SetMenuName("Ghost Bat"),{},12,30)

ATCGroundOps()

---Blue---
--local CapZone1 = ZONE:FindByName("CAP_Zone_E")
--local CapZone2 = ZONE:FindByName("CAP_Zone_SE")
--local CapZone3 = ZONE:FindByName("CAP_Zone_Mid")
--local CapZone7 = ZONE:FindByName("CAP_Zone_DSE")
--local CapZone10 = ZONE:FindByName("CAP_Zone_N_E"
--local CapZone11 = ZONE:FindByName("CAP_Zone_DNE")
---Both---
--local CapZone6 = ZONE:FindByName("CAP_Zone_Mid_S")
---Red---
--local CapZone4 = ZONE:FindByName("CAP_Zone_Mid")
--local CapZone5 = ZONE:FindByName("CAP_Zone_W")
--local CapZone8 = ZONE:FindByName("CAP_Zone_DSW")
--local CapZone9 = ZONE:FindByName("CAP_Zone_N_W")







-- Schedule functions properly
--timer.scheduleFunction(destroyzonered, {}, timer.getTime() + 13)
--timer.scheduleFunction(destroyzoneblue, {}, timer.getTime() + 16)
--local function configureAWACS()
--    -- Create a SET_GROUP to find all AWACS aircraft by type or name
--    local awacsSet = SET_GROUP:New()
--        :FilterCoalitions("blue")
--        :FilterCategories("plane")
--        --:FilterTypes({"E-3A", "E-2D", "A-50"}) -- Find AWACS types
--        :FilterPrefixes({"Darkstar", "Magic", "Overlord", "Wizard"}) -- Find AWACS by name
--        :FilterStart()
--
--    -- Iterate through the found AWACS groups and configure them
--    awacsSet:ForEachGroup(
--        function(awacsGroup)
--            local awacsFlight = FLIGHTGROUP:New(awacsGroup)
--
--            -- Default callsign & frequency
--            --local callsign = FLIGHTGROUP.Callsign.AWACS_MAGIC
--            --local freq = 251.000 -- Default MHz
--
--            -- Assign Callsign & Frequency Based on Name
--            local name = awacsGroup:GetName()
--            if name:find("Darkstar") then
--                callsign = FLIGHTGROUP.Callsign.AWACS_OVERLORD
--                freq = 255.000
--            elseif name:find("Magic") then
--                callsign = FLIGHTGROUP.Callsign.AWACS_MAGIC
--                freq = 245.000
--            elseif name:find("Overlord") then
--                callsign = FLIGHTGROUP.Callsign.AWACS_OVERLORD
--                freq = 144.000
--            elseif name:find("Wizard") then
--                callsign = FLIGHTGROUP.Callsign.AWACS_WIZARD
--                freq = 154.000
--            end
--
--            -- Enable EPLRS (Datalink)
--            awacsFlight:SetOption(AI.Option.AirborneRadar, true) -- Enables airborne radar functions
--            awacsFlight:SetOption(AI.Option.EPLRS, true) -- Ensures EPLRS is enabled for datalink
--
--            -- Set AWACS Radio Frequency
--            awacsFlight:SetRadio(freq)
--
--            -- Set Callsign (e.g., "Magic 1")
--            awacsFlight:SetCallsign(callsign, 1)
--
--            -- Assign AWACS Radar Task
--            local awacsTask = awacsFlight:EnRouteTaskAWACS()
--            awacsFlight:SetTask(awacsTask)
--
--            MESSAGE:New("AWACS & EPLRS Enabled for " .. name .. " on " .. freq .. " MHz", 10):ToAll()
--        end
--    )
--end

-- Run once at mission start
--configureAWACS()

-- Run every 30 seconds to check for new AWACS spawns
--timer.scheduleFunction(configureAWACS, nil, timer.getTime() + 90)




-----------------------------
-----------------------------
--------End TEstcode---------
-----------------------------
-----------------------------


--Change Log for **WoC - Sinai 6.3**
--
--```
--AI commanders Maximum missions reduced from 100 to 20 (30 missions were seen active at a time from the last play through) This should reduce AI Air threat.
--
--AI Base Capture mission created, When an airfield has less then 5 ground units, the AI commander will be issued with a ground assault mission escorted by Helos. they should launch from the nearest friendly airbase.
--Note: These forces could be intercepted and may need player protection.
--
--max missions per player is 6
--max missions per coalition is 20
--Removed Artillery units from the Ground Brigades 

----Change Log for **WoC - Sinai 6.4**
--Implemented ATC Ground control you can Access Airbase info and request taxi\takeoff through F10 
--you must request taxi to remove the taxi guard.
--
--Updated mission briefing
--
--Added additional Cap Zones for Blue and Red Airwings
--
--Added player menu to request CAP zones over their position or the nearest friendly and enemy airbases.
--Added player menu to request CAS Enhanced missions over their position or the nearest friendly and enemy airbases.
--Added player menu to request Escort missions for their group.
--Added player menu to view and release active missions.
--Added player menu to request G2G missions to the nearest friendly and enemy airbases.

--updated ground unit mission sets.
--GCI Cap staging zones now drawn on the map for both sides.
--Fixed a bug with Red AWACS not spawning correctly. updated the Datalink awacs to be immortal,invis and infinite fuel.
--added an additional check to the base capture logic to stop multiple missions being sent to the same base at the same time.
--
--noticed very few if any ground units being deployed Fixed mission list for Brigades 
--Fixed spawn logic for Defending units, they now spawn near the warehouse and not all over the airbase
--fixed a bug with "no player missions found" appearing continuously.
--
--increase mission limit for ground attack to 6
--tuning the ATC Ground ops is still ongoing, aircraft can still get stuck on the ground, but this should be less frequent.
--added in mission restart every 8 hours with warning message to players.
--made progress on unit persistence but not yet implemented.


--```