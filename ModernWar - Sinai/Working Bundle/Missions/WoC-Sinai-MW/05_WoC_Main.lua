-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------Wings of Conflict Mission Script----------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------


-----------------------------------------------------------------------
-----------------------------------------------------------------------
------------------Start of Persistence Script--------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------

local filepath = lfs.writedir() .. "\\Missions\\WoC-Sinai\\Save\\"

-- Function to create the directory if it doesn't exist
local function createDirectory(path)
    local command = 'mkdir "' .. path .. '"'
    os.execute(command)
end

-- Ensure the directory exists
createDirectory(filepath)

-- Define the zones dynamically using SET_ZONE
local zonesToCheck = SET_ZONE:New():FilterStart()

-- Function to save unit locations within zones
local function saveUnitLocationsInZones()
    local unitsInZones = {}

    zonesToCheck:ForEachZone(function(zone)
        local zoneName = zone:GetName()
        local unitsInZone = mist.getUnitsInZones(mist.makeUnitTable({'[all][vehicle]'}), {zoneName}, 'cylinder')
        for _, unit in ipairs(unitsInZone) do
            local unitPos = unit:getPosition().p
            table.insert(unitsInZones, {
                unitName = unit:getName(),
                zoneName = zoneName,
                position = {x = unitPos.x, y = unitPos.y, z = unitPos.z}
            })
        end
    end)

    -- Save the data to a file
    local fileName = filepath .. "unit_locations_in_zones.lua"
    local file = io.open(fileName, "w")
    if file then
        file:write("unitsInZones = {\n")
        for _, unitData in ipairs(unitsInZones) do
            file:write("    {\n")
            file:write('        unitName = "' .. unitData.unitName .. '",\n')
            file:write('        zoneName = "' .. unitData.zoneName .. '",\n')
            file:write("        position = {x = " .. unitData.position.x .. ", y = " .. unitData.position.y .. ", z = " .. unitData.position.z .. "},\n")
            file:write("    },\n")
        end
        file:write("}\n")
        file:close()
        trigger.action.outText("Unit locations saved to " .. fileName, 10)
    else
        trigger.action.outText("Failed to save unit locations", 10)
    end
end

-- Function to save static objects
local function saveStaticObjects()
    local staticObjects = {}

    local statics = SET_STATIC:New():FilterStart()
    statics:ForEachStatic(function(static)
        local staticPos = static:GetPosition().p
        table.insert(staticObjects, {
            staticName = static:GetName(),
            position = {x = staticPos.x, y = staticPos.y, z = staticPos.z},
            typeName = static:GetTypeName(),
            category = static:GetCategory(),
            country = static:GetCountry(),
            heading = static:GetHeading()
        })
    end)

    -- Save the data to a file
    local fileName = filepath .. "static_objects.lua"
    local file = io.open(fileName, "w")
    if file then
        file:write("staticObjects = {\n")
        for _, staticData in ipairs(staticObjects) do
            file:write("    {\n")
            file:write('        staticName = "' .. staticData.staticName .. '",\n')
            file:write("        position = {x = " .. staticData.position.x .. ", y = " .. staticData.position.y .. ", z = " .. staticData.position.z .. "},\n")
            file:write('        typeName = "' .. staticData.typeName .. '",\n')
            file:write('        category = "' .. staticData.category .. '",\n')
            file:write('        country = "' .. staticData.country .. '",\n')
            file:write("        heading = " .. staticData.heading .. ",\n")
            file:write("    },\n")
        end
        file:write("}\n")
        file:close()
        trigger.action.outText("Static objects saved to " .. fileName, 10)
    else
        trigger.action.outText("Failed to save static objects", 10)
    end
end

-- Example of despawning aircraft that haven't moved in 5 minutes
local function monitorAircraftMovement(aircraft)
  local unit = UNIT:FindByName(aircraft:GetName())
  if unit then
    local startPos = unit:GetPointVec2()
    SCHEDULER:New(nil, function()
      if unit and unit:IsAlive() then
        local currentPos = unit:GetPointVec2()
        local dist = currentPos:Get2DDistance(startPos)
        if dist < 20 then -- still at same position, assume stuck
          env.info("Despawning stuck aircraft: " .. unit:GetName())
          unit:Destroy()
        end
      end
    end, {}, 300) -- 5 minutes delay
  end
end


-- Function to save airfields
local function saveAirfields()
    local airfieldsData = {
        blueAirfields = {},
        redAirfields = {}
    }

    for _, airbase in ipairs(world.getAirbases()) do
        local airbaseName = airbase:getName()
        local coalition = airbase:getCoalition()

        if coalition == 2 then
            table.insert(airfieldsData.blueAirfields, airbaseName)
        elseif coalition == 1 then
            table.insert(airfieldsData.redAirfields, airbaseName)
        end
    end

    local fileName = filepath .. "airfields.lua"
    local file = io.open(fileName, "w")
    if file then
        file:write("airfieldsData = {\n")
        file:write("    blueAirfields = {\n")
        for _, airbaseName in ipairs(airfieldsData.blueAirfields) do
            file:write('        "' .. airbaseName .. '",\n')
        end
        file:write("    },\n")
        file:write("    redAirfields = {\n")
        for _, airbaseName in ipairs(airfieldsData.redAirfields) do
            file:write('        "' .. airbaseName .. '",\n')
        end
        file:write("    }\n")
        file:write("}\n")
        file:close()
        trigger.action.outText("Airfields saved to " .. fileName, 10)
    else
        trigger.action.outText("Failed to save airfields", 10)
    end
end

local function exportAirwingToFile(airwing, fileName)
    local filePath = filepath .. fileName
    local file = io.open(filePath, "w")

    if file then
        file:write("airwing = {\n")
        file:write("    name = \"" .. airwing:GetName() .. "\",\n")
        file:write("    squadrons = {\n")
        for squadronName, squadron in pairs(airwing.squadrons or {}) do
            file:write("        [\"" .. squadronName .. "\"] = {\n")
            file:write("            assetCount = " .. squadron:CountAssets() .. ",\n")
            file:write("        },\n")
        end
        file:write("    },\n")
        file:write("    payloads = {\n")
        for payloadName, payload in pairs(airwing.payloads or {}) do
            file:write("        [\"" .. payloadName .. "\"] = {\n")
            file:write("            count = " .. payload.count .. ",\n")
            file:write("        },\n")
        end
        file:write("    },\n")
        file:write("}\n")
        file:close()
        trigger.action.outText("Airwing exported to " .. filePath, 10)
    else
        trigger.action.outText("Failed to export airwing to file", 10)
    end
end

local function saveBlueAirwingsToFile()
    local fileName = filepath .. "BlueAirwings.lua"
    local file = io.open(fileName, "w")

    if file then
        file:write("BlueAirwings = {\n")
        for warehouseName, airwing in pairs(BlueAirwings) do
            file:write("    [\"" .. warehouseName .. "\"] = {\n")
            file:write("        name = \"" .. airwing:GetName() .. "\",\n")
            file:write("        squadrons = {\n")
            for squadronName, squadron in pairs(airwing.squadrons or {}) do
                file:write("            [\"" .. squadronName .. "\"] = {\n")
                file:write("                assetCount = " .. squadron:CountAssets() .. ",\n")
                file:write("            },\n")
            end
            file:write("        },\n")
            file:write("        payloads = {\n")
            for payloadName, payload in pairs(airwing.payloads or {}) do
                file:write("            [\"" .. payloadName .. "\"] = {\n")
                file:write("                count = " .. payload.count .. ",\n")
                file:write("            },\n")
            end
            file:write("        },\n")
            file:write("    },\n")
        end
        file:write("}\n")
        file:close()
        trigger.action.outText("BlueAirwings saved to " .. fileName, 10)
    else
        trigger.action.outText("Failed to save BlueAirwings to file", 10)
    end
end
-- Schedule the functions to run periodically
--mist.scheduleFunction(saveUnitLocationsInZones, {}, timer.getTime() + 10, 180) -- Runs every 300 seconds (5 minutes)
--mist.scheduleFunction(saveStaticObjects, {}, timer.getTime() + 10, 120) -- Runs every 300 seconds (5 minutes)
----mist.scheduleFunction(saveAirwingsAndBrigades, {}, timer.getTime() + 10, 120) -- Runs every 300 seconds (5 minutes)
--mist.scheduleFunction(saveAirfields, {}, timer.getTime() + 10, 120) -- Runs every 300 seconds (5 minutes)

local function loadSavedData()
    local unitLocationsFile = filepath .. "unit_locations_in_zones.lua"
    local staticObjectsFile = filepath .. "static_objects.lua"

    -- Load unit locations
    local unitLocations = dofile(unitLocationsFile)
    if unitLocations then
        for _, unitData in ipairs(unitLocations.unitsInZones) do
            local unit = Unit.getByName(unitData.unitName)
            if unit then
                unit:setPosition({p = unitData.position})
            else
                -- Spawn the unit if it doesn't exist
                mist.dynAdd({
                    category = 'vehicle',
                    name = unitData.unitName,
                    type = unitData.typeName,
                    x = unitData.position.x,
                    y = unitData.position.z,
                    heading = 0
                })
            end
        end
    end

    -- Load static objects
    local staticObjects = dofile(staticObjectsFile)
    if staticObjects then
        for _, staticData in ipairs(staticObjects.staticObjects) do
            local static = StaticObject.getByName(staticData.staticName)
            if not static then
                -- Spawn the static object if it doesn't exist
                mist.dynAddStatic({
                    category = 'static',
                    name = staticData.staticName,
                    type = staticData.typeName,
                    x = staticData.position.x,
                    y = staticData.position.z,
                    heading = staticData.heading
                })
            end
        end
    end
end
-- Function to load airfields
local function loadAirfields()
    local airfieldsFile = filepath .. "airfields.lua"
    local airfieldsData, loadError = loadfile(airfieldsFile)
    
    if airfieldsData then
        local success, result = pcall(airfieldsData)
        if success and result then
            blueAirfields = result.blueAirfields
            redAirfields = result.redAirfields
            trigger.action.outText("Airfields loaded successfully", 10)
        else
            trigger.action.outText("Failed to execute airfields file: " .. tostring(result), 10)
            sortairfields()
        end
    else
        trigger.action.outText("Failed to load airfields file: " .. tostring(loadError), 10)
        sortairfields()
    end
end

-----------------------------------------------------------------------
-----------------------------------------------------------------------
------------------End of Persistence Script----------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------


---Start the main script for setting up the Wings of Conflict Mission--

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

----create a zone object and opszone object around an airfield
function CreateAirfieldOpszones(airfieldName)
    local zoneName = "Capture Zone - " .. airfieldName
    local zoneRadius = 5000 -- 5 km capture zone
    local zone = ZONE_AIRBASE:New(airfieldName, zoneRadius)
    local opzone = OPSZONE:New(zone):SetDrawZone(true)
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
        Spawnpoint = SpawnZone:GetRandomCoordinate(50, 1000, land.SurfaceType.ROAD)
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






local function SpawnBlueForces(airfieldName, warehouseName, coalitionSide, MinDistance, MaxDistance)
   local parkingCount = aircraftParkingCount +heliParkingCount
   
    SpawnWarehouse(airfieldName, warehouseName, coalitionSide)
    local function spawnmessageblue()
          env.info("Finished Spawning Blue warehouse at airbase "..airfieldName)
          end
     timer.scheduleFunction(spawnmessageblue, {}, timer.getTime() + 1)
     
     local parkingData = airbaseParkingSummary(airfieldName)
      
    
     if  parkingData.aircraftParkingCount > 80 then
        Spawn_Near_airbase(Group_Blue_SAM_Site, airfieldName, MinDistance, MaxDistance ,false)
    end

    Spawn_Near_airbase(Group_Blue_SAM, airfieldName, MinDistance, MaxDistance)
    Spawn_Near_airbase(Group_Blue_Mech, airfieldName, MinDistance, MaxDistance)
    Spawn_Near_airbase(Group_Blue_APC, airfieldName, MinDistance, MaxDistance)
    Spawn_Near_airbase(Group_Blue_Armoured, airfieldName, MinDistance, MaxDistance)
    --Spawn_Near_airbase(Group_Blue_Inf, airfieldName, MinDistance, MaxDistance)
    Spawn_Near_airbase(Group_Blue_Truck, airfieldName, MinDistance, MaxDistance)

    env.info("Finished Spawning Blue Groups at airbase "..airfieldName)


    CreateAirfieldOpszones(airfieldName)
    env.info("Finished Creating Opszone at airbase "..airfieldName)
end

local function SpawnRedForces(airfieldName, warehouseName, coalitionSide, MinDistance, MaxDistance)
    local parkingCount = aircraftParkingCount +heliParkingCount
  
    SpawnWarehouse(airfieldName, warehouseName, coalitionSide)
    local function spawnmessageRed()
        env.info("Finished Spawning Red warehouse at airbase "..airfieldName)
        end
   timer.scheduleFunction(spawnmessageRed, {}, timer.getTime() + 1)
    
    local parkingData = airbaseParkingSummary(airfieldName)

     if parkingData.aircraftParkingCount > 100 then
         Spawn_Near_airbase(Group_Red_SAM_Site, airfieldName, MinDistance, MaxDistance ,false)
     end
 
     Spawn_Near_airbase(Group_Red_SAM, airfieldName, MinDistance, MaxDistance)
     Spawn_Near_airbase(Group_Red_Mech, airfieldName, MinDistance, MaxDistance)
     Spawn_Near_airbase(Group_Red_APC, airfieldName, MinDistance, MaxDistance)
     Spawn_Near_airbase(Group_Red_Armoured, airfieldName, MinDistance, MaxDistance)
     --Spawn_Near_airbase(Group_Red_Inf, airfieldName, MinDistance, MaxDistance)
     Spawn_Near_airbase(Group_Red_Truck, airfieldName, MinDistance, MaxDistance)
 
     env.info("Finished Spawning Red Groups at airbase "..airfieldName)

     CreateAirfieldOpszones(airfieldName)
     env.info("Finished Creating Opszone at airbase "..airfieldName)
 end




---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
----------------Begin Deploying Squadrons and Brigades---------------------------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

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
        SQN1:AddMissionCapability({AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.SEAD, AUFTRAG.Type.CAS,AUFTRAG.Type.CASENHANCED, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING})
        SQN1:SetDespawnAfterHolding()
        SQN1:SetDespawnAfterLanding()
        SQN1:SetTakeoffHot()
        SQN1:SetMissionRange(80)
        airwing:AddSquadron(SQN1)
        
       -- BlueAirwings.squadrons =SQN1


        local SQN2 = SQUADRON:New(Blue_LT_Fighter, 2, "Blue Light Fighter Squadron "..airfieldName)
        SQN2:AddMissionCapability({AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING,AUFTRAG.Type.RECON,AUFTRAG.Type.CASENHANCED})
        SQN2:SetDespawnAfterHolding()
        SQN2:SetDespawnAfterLanding()
        SQN2:SetMissionRange(100)
        SQN2:SetTakeoffHot()
        SQN2:SetMissionRange(80)
        airwing:AddSquadron(SQN2)
        
       -- BlueAirwings.squadrons =SQN2

        local SQN3 = SQUADRON:New(Blue_Attack, 2, "Blue Attack Squadron "..airfieldName)
        SQN3:AddMissionCapability({AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING,AUFTRAG.Type.CASENHANCED})
        SQN3:SetDespawnAfterHolding()
        SQN3:SetDespawnAfterLanding()
        SQN3:SetMissionRange(100)
        SQN3:SetTakeoffHot()
        SQN3:SetMissionRange(80)
        airwing:AddSquadron(SQN3)
        -- BlueAirwings.squadrons =SQN3


       Blue_payload_Fighter_AA= airwing:NewPayload(GROUP:FindByName(Blue_Fighter.."_AA"), 4, {AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT}, 90)
       Blue_payload_Fighter_CAS= airwing:NewPayload(GROUP:FindByName(Blue_Fighter.."_CAS"), 4, {AUFTRAG.Type.BOMBING, AUFTRAG.Type.CAS, AUFTRAG.Type.BAI},50)
       Blue_payload_LtFighter_AA= airwing:NewPayload(GROUP:FindByName(Blue_LT_Fighter.."_AA"), 2, {AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT},80)
       Blue_payload_LtFighter_CAS= airwing:NewPayload(GROUP:FindByName(Blue_LT_Fighter.."_CAS"), 2, {AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING,AUFTRAG.Type.RECON,AUFTRAG.Type.CASENHANCED},70)
       Blue_payload_LtFighter_SEAD= airwing:NewPayload(GROUP:FindByName(Blue_LT_Fighter.."_SEAD"), 4, {AUFTRAG.Type.SEAD},100)
       Blue_payload_Attack_CAS =airwing:NewPayload(GROUP:FindByName(Blue_Attack.."_CAS"), 2, {AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING,AUFTRAG.Type.CASENHANCED},80)

    else
        env.info("Not enough aircraft parking spots at " .. airfieldName)
    end

    if parkingData.heliParkingCount > 1 or parkingData.aircraftParkingCount > 1 then
        local SQN4 = SQUADRON:New(Blue_Helo, 4, "Blue Transport Squadron "..airfieldName)
        SQN4:AddMissionCapability({AUFTRAG.Type.TROOPTRANSPORT, AUFTRAG.Type.CARGOTRANSPORT, AUFTRAG.Type.RECON, AUFTRAG.Type.CAS, AUFTRAG.Type.BAI}):SetAttribute(GROUP.Attribute.AIR_TRANSPORTHELO)
        SQN4:SetDespawnAfterHolding()
        SQN4:SetDespawnAfterLanding()
        SQN4:SetMissionRange(40)
        SQN4:SetTakeoffHot()

        local SQN5 = SQUADRON:New(Blue_AttackHelo, 4, "Blue CAS Squadron "..airfieldName)
        SQN5:AddMissionCapability({AUFTRAG.Type.TROOPTRANSPORT, AUFTRAG.Type.CARGOTRANSPORT, AUFTRAG.Type.RECON, AUFTRAG.Type.CAS, AUFTRAG.Type.BAI}):SetAttribute(GROUP.Attribute.AIR_TRANSPORTHELO)
        SQN5:SetDespawnAfterHolding()
        SQN5:SetDespawnAfterLanding()
        SQN5:SetMissionRange(40)
        SQN5:SetTakeoffHot()

        airwing:AddSquadron(SQN4)
        airwing:AddSquadron(SQN5)
        -- BlueAirwings.squadrons =SQN4
       Blue_payload_helo_Trans = airwing:NewPayload(GROUP:FindByName(Blue_Helo.."_Trans"), 4, {AUFTRAG.Type.TROOPTRANSPORT,AUFTRAG.Type.CARGOTRANSPORT,AUFTRAG.Type.RECON,AUFTRAG.Type.OPSTRANSPORT},80)
       Blue_payload_helo_CAS = airwing:NewPayload(GROUP:FindByName(Blue_AttackHelo.."_CAS"), 4, {AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING},50)
       
       

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
    platoonAPC:AddMissionCapability({AUFTRAG.Type.PATROLZONE,AUFTRAG.Type.ARMOUREDGUARD, AUFTRAG.Type.ONGUARD}, 60):SetAttribute(GROUP.Attribute.GROUND_APC)
        -- Mechanised platoon
    local platoonMECH=PLATOON:New(Group_Blue_Mech, 5,"Blue Mechanised Platoon "..airfieldName)
    platoonMECH:AddMissionCapability({AUFTRAG.Type.PATROLZONE,AUFTRAG.Type.ARMOUREDGUARD, AUFTRAG.Type.ONGUARD}, 70)
    platoonMECH:AddWeaponRange(UTILS.KiloMetersToNM(0.5), UTILS.KiloMetersToNM(20))
        -- Armoured platoon
    local platoonArmoured =PLATOON:New(Group_Blue_Armoured, 5,"Blue Armoured Platoon "..airfieldName)
    platoonArmoured:AddMissionCapability({AUFTRAG.Type.PATROLZONE,AUFTRAG.Type.ARMOUREDGUARD,AUFTRAG.Type.ARMOUREDATTACK, AUFTRAG.Type.ONGUARD}, 70)
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
    SQN1:AddMissionCapability({AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING,AUFTRAG.Type.CASENHANCED})
    SQN1:SetDespawnAfterHolding()
    SQN1:SetDespawnAfterLanding()
    SQN1:SetTakeoffHot()
    SQN1:SetMissionRange(60)

     
    local SQN2 = SQUADRON:New(Red_Attack, 2, "Red Attack Squadron "..airfieldName)
    SQN2:AddMissionCapability({AUFTRAG.Type.ESCORT, AUFTRAG.Type.SEAD, AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING,AUFTRAG.Type.RECON,AUFTRAG.Type.CASENHANCED})
    SQN2:SetDespawnAfterHolding()
    SQN2:SetDespawnAfterLanding()
    SQN2:SetTakeoffHot()
    SQN2:SetMissionRange(80)    

    local SQN3 = SQUADRON:New(Red_LT_Fighter, 2, "Red Light Fighter Squadron "..airfieldName)
    SQN3:AddMissionCapability({AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING})
    SQN3:SetDespawnAfterHolding()
    SQN3:SetDespawnAfterLanding()
    SQN3:SetTakeoffHot()
    SQN3:SetMissionRange(60)
    
    Red_payload_Fighter_AA = airwing:NewPayload(GROUP:FindByName(Red_Fighter.."_AA"), 4, {AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT}, 80)
    Red_payload_LTFighter_CAS = airwing:NewPayload(GROUP:FindByName(Red_Fighter.."_CAS"), 4, {AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING,AUFTRAG.Type.CASENHANCED},50 )
    Red_payload_LtFighter_AA = airwing:NewPayload(GROUP:FindByName(Red_LT_Fighter.."_AA"), 2, {AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT})
    Red_payload_Attack_SEAD = airwing:NewPayload(GROUP:FindByName(Red_Attack.."_SEAD"), 2, {AUFTRAG.Type.SEAD},90)
    Red_payload_Attack_CAS = airwing:NewPayload(GROUP:FindByName(Red_Attack.."_CAS"), 2, {AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING,AUFTRAG.Type.RECON,AUFTRAG.Type.CASENHANCED},90)
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
    SQN4:AddMissionCapability({AUFTRAG.Type.TROOPTRANSPORT, AUFTRAG.Type.CARGOTRANSPORT, AUFTRAG.Type.RECON, AUFTRAG.Type.CAS, AUFTRAG.Type.BAI}):SetAttribute(GROUP.Attribute.AIR_TRANSPORTHELO)
    SQN4:SetDespawnAfterHolding()
    SQN4:SetDespawnAfterLanding()
    SQN4:SetTakeoffHot()
    SQN4:SetMissionRange(40)
    airwing:AddSquadron(SQN4)
    env.info(string.format("###Squadron %s was added to  %s assets###", SQN4:GetName(), airwingName))
    Red_payload_helo_trans = airwing:NewPayload(GROUP:FindByName(Red_Helo.."_Trans"), 4, {AUFTRAG.Type.TROOPTRANSPORT,AUFTRAG.Type.CARGOTRANSPORT,AUFTRAG.Type.RECON,AUFTRAG.Type.OPSTRANSPORT},80)
    Red_payload_helo_CAS = airwing:NewPayload(GROUP:FindByName(Red_Helo.."_CAS"), 4, {AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING},50)
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
        platoonAPC:AddMissionCapability({AUFTRAG.Type.PATROLZONE,AUFTRAG.Type.ARMOUREDGUARD, AUFTRAG.Type.ONGUARD}, 60):SetAttribute(GROUP.Attribute.GROUND_APC)
            -- Mechanised platoon
        local platoonMECH=PLATOON:New(Group_Red_Mech, 5, "Red Mechanised Platoon "..airfieldName)
        platoonMECH:AddMissionCapability({AUFTRAG.Type.PATROLZONE,AUFTRAG.Type.ARMOUREDGUARD, AUFTRAG.Type.ONGUARD}, 70)
        platoonMECH:AddWeaponRange(UTILS.KiloMetersToNM(0.5), UTILS.KiloMetersToNM(20))
            -- Armoured platoon
        local platoonArmoured =PLATOON:New(Group_Red_Armoured, 5,"Red Armoured Platoon "..airfieldName)
        platoonMECH:AddMissionCapability({AUFTRAG.Type.PATROLZONE,AUFTRAG.Type.ARMOUREDGUARD,AUFTRAG.Type.ARMOUREDATTACK, AUFTRAG.Type.ONGUARD}, 70)
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
local CapZone1 = ZONE:FindByName("CAP_Zone_E")
local CapZone2 = ZONE:FindByName("CAP_Zone_SE")
local CapZone3 = ZONE:FindByName("CAP_Zone_Mid")
local CapZone4 = ZONE:FindByName("CAP_Zone_Mid")
local CapZone5 = ZONE:FindByName("CAP_Zone_W")

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
    BlueChief:SetLimitMission(2, AUFTRAG.Type.GROUNDATTACK)
    BlueChief:SetLimitMission(2, AUFTRAG.Type.RECON)
    BlueChief:SetLimitMission(2, AUFTRAG.Type.BAI)
    BlueChief:SetLimitMission(2, AUFTRAG.Type.INTERCEPT)
    BlueChief:SetLimitMission(2, AUFTRAG.Type.SEAD)
    BlueChief:SetLimitMission(2, AUFTRAG.Type.BOMBING)
    BlueChief:SetLimitMission(2, AUFTRAG.Type.CAPTUREZONE)
    BlueChief:SetLimitMission(2, AUFTRAG.Type.CASENHANCED)
    BlueChief:SetLimitMission(2, AUFTRAG.Type.CAS)
    BlueChief:SetLimitMission(15, Total)
    
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
    BlueChief:AddBorderZone(CapZone1)
    BlueChief:AddBorderZone(CapZone2)
    BlueChief:AddBorderZone(CapZone3)
    BlueChief:AddConflictZone(CapZone4)
    BlueChief:AddConflictZone(CapZone5)
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
     RedChief:SetLimitMission(2, AUFTRAG.Type.GROUNDATTACK)
     RedChief:SetLimitMission(2, AUFTRAG.Type.BOMBING)
     RedChief:SetLimitMission(2, AUFTRAG.Type.RECON)
     RedChief:SetLimitMission(2, AUFTRAG.Type.BAI)
     RedChief:SetLimitMission(2, AUFTRAG.Type.INTERCEPT)
     RedChief:SetLimitMission(2, AUFTRAG.Type.SEAD)
     RedChief:SetLimitMission(2, AUFTRAG.Type.CAPTUREZONE)
     RedChief:SetLimitMission(2, AUFTRAG.Type.CASENHANCED)
     RedChief:SetLimitMission(2, AUFTRAG.Type.CAS)
     RedChief:SetLimitMission(15, Total)

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
    RedChief:AddConflictZone(CapZone1)
    RedChief:AddConflictZone(CapZone2)
    RedChief:AddBorderZone(CapZone3)
    RedChief:AddBorderZone(CapZone4)
    RedChief:AddBorderZone(CapZone5)
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

local function initializeMission()
    local unitLocationsFile = filepath .. "unit_locations_in_zones.lua"
    local staticObjectsFile = filepath .. "static_objects.lua"
    local airfieldsFile = filepath .. "airfields.lua"

    -- Ensure the directory exists
    createDirectory(filepath)

    -- Initialize chiefs
    CreateBlueChief()
    CreateRedChief()

    if lfs.attributes(unitLocationsFile) and lfs.attributes(staticObjectsFile) and lfs.attributes(airfieldsFile) then
        loadAirfields()
        loadSavedData()
        deployairwings()
    else
        -- Call your functions to spawn groups and assets fresh
        sortairfields()
        DeployForces()
        deployairwings()
    end
end

-- Call the initialize function at mission start
initializeMission()
RedChief:__Start(1)
BlueChief:__Start(1)

OPS_Zones = SET_OPSZONE:New():FilterOnce()
OPS_Zones:Start()


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
-- set one escort group; this example has two units in the template group, so they can fly a nice formation.
Blueawacs:SetEscort(1,ENUMS.Formation.FixedWing.FingerFour.Group,{x=-500,y=50,z=500},45)
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
Redawacs:SetEscort(1,ENUMS.Formation.FixedWing.FingerFour.Group,{x=-500,y=50,z=500},45)
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
TIMER:New(PlayerTaskingRed):Start(20)

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
        local coalitionID = opszone:GetOwner() -- 1=red, 2=blue, 0=neutral
        local airfieldName = opszone:GetName()     -- Adjust if needed
        local opscoalforces = SET_UNIT:New():FilterZones({opszone:GetZone()}):FilterCoalitions(coalitionID):FilterOnce()
        local opscoalforcescount = opscoalforces:CountAlive()
        env.info("Checking number of units in OPSZONE: " .. opszone:GetName() .. " - Coalition: " .. coalitionID .. " - Count: " .. opscoalforcescount)
        if opscoalforcescount < 10 then
            env.info("Launching assault against OPSZONE: " .. opszone:GetName())
            if coalitionID == coalition.side.RED then
                -- Zone is owned by RED, spawn BLUE units
                Spawn_Near_airbase(Group_Blue_Armoured, airfieldName, 10, 10, true)
                Spawn_Near_airbase(Group_Blue_Mech, airfieldName, 10, 10, true)
                Spawn_Near_airbase(Group_Blue_SAM, airfieldName, 10, 10, true)
            elseif coalitionID == coalition.side.BLUE then
                -- Zone is owned by BLUE, spawn RED units
                Spawn_Near_airbase(Group_Red_Armoured, airfieldName, 10, 10, true)
                Spawn_Near_airbase(Group_Red_Mech, airfieldName, 10, 10, true)
                Spawn_Near_airbase(Group_Red_SAM, airfieldName, 10, 10, true)
            end
        end
    end)
end

--TIMER:New(OpszoneCapture):Start(125, 120) -- every 120 seconds after 60s


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