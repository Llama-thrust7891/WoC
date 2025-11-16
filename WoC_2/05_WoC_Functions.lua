-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------Wings of Conflict Mission Script----------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-----------------------------------------------------------------------
-- Simple Persistence for blueAirfields and redAirfields only
-----------------------------------------------------------------------

local filepath = lfs.writedir() .. "\\Missions\\WoC-Syria-MW\\Save\\"
local airfieldsFile = filepath .. "airfields.lua"
--local zoneUnitFile = filepath .. "zone_units.lua"

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

---------End Persistence for airfields----------------
------------------------------------------------------


---------Mission Restart schedule----------------
------------------------------------------------------


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

-----------------------------------------------------
-----End Mission Restart schedule
------------------------------------------------------
------------------------------------------------------

--- Get all airbase names that are airdromes, excluding those named "H" add to list "AairfieldNames"

function getAllAirbaseNames()
    local airfields = {}
    for _, airbase in ipairs(world.getAirbases()) do
        local abName = airbase:getName()
        -- Skip airbases named exactly "H"
        if abName ~= "H" then
            local AF = AIRBASE:FindByName(abName)
            if AF and AF.isAirdrome then
                table.insert(airfields, abName)
            end
        end
    end
    return airfields
end
AirfieldNames = getAllAirbaseNames()
-- ensure globals exist to avoid nil concat / table.insert errors
blueAirfields = blueAirfields or {}
redAirfields = redAirfields or {}
referenceAirfield = referenceAirfield or nil

-----------------SortredAirfield-----------------------

--Sort airfields into red and blue
-- Sort airfields into red and blue
function sortairfields()
    -- reset lists to avoid duplicates on multiple calls
    blueAirfields = {}
    redAirfields = {}

    -- ensure we have airfields
    if not AirfieldNames or #AirfieldNames == 0 then
        env.info("sortairfields: no AirfieldNames available")
        return
    end

    -- if referenceAirfield not set, pick first available airfield as fallback
    if not referenceAirfield or type(referenceAirfield) ~= "string" or referenceAirfield == "" then
        referenceAirfield = AirfieldNames[1]
        env.info("sortairfields: referenceAirfield not set, defaulting to " .. tostring(referenceAirfield))
    end

    -- Find reference airbase
    local refAirbase = AIRBASE:FindByName(referenceAirfield)
    if not refAirbase then
        env.info("Reference airfield not found: " .. tostring(referenceAirfield))
        return
    end
    local refX = refAirbase:GetVec2().x

    -- Use the static AirfieldNames list
    for _, airfieldName in ipairs(AirfieldNames) do
        local airbase = AIRBASE:FindByName(airfieldName)
        if airbase then
            local pos = airbase:GetVec2()
            if pos and pos.x and pos.x > refX then
                table.insert(redAirfields, airfieldName)
            else
                table.insert(blueAirfields, airfieldName)
            end
        end
    end
    --Save the sorted airfields to file
    saveAirfields()
end

--Count airbase parking spots by type
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

----create a zone object and opszone object around an airfield
function CreateAirfieldOpszones(airfieldName)
    local zoneName = "Capture Zone - " .. airfieldName
    local zoneRadius = 5000 -- 5 km capture zone
    local zone = ZONE_AIRBASE:New(airfieldName, zoneRadius)
    local opzone = OPSZONE:New(zone):SetDrawZone(true):SetObjectCategories(Object.Category.UNIT):SetUnitCategories(Unit.Category.GROUND_UNIT)
end

function SpawnWarehouse(airfieldName, warehouseName, coalitionSide)
    local airbase = AIRBASE:FindByName(airfieldName)
    if not airbase then
        trigger.action.outText("Error: Airfield not found - " .. airfieldName, 10)
        env.info("SpawnWarehouse: airbase not found: " .. tostring(airfieldName))
        return
    end

    local SpawnZone = airbase:GetZone()
    local spawnX, spawnY

    -- Try to get clear positions from the zone (prefer a few candidates)
    if SpawnZone and SpawnZone.GetClearZonePositions then
        local ok, res = pcall(function() return SpawnZone:GetClearZonePositions(GetClearZonePositionsDistance, 3) end)
        if ok and res then
            -- res can be a table of Vec2 positions or a single Vec2
            if type(res) == "table" then
                -- table of positions
                if #res >= 1 and res[1] and (res[1].x or res[1].y) then
                    spawnX = res[1].x
                    spawnY = res[1].y
                elseif res.x and res.y then
                    -- sometimes returns a single Vec2
                    spawnX = res.x
                    spawnY = res.y
                end
            end
        else
            env.info("SpawnWarehouse: GetClearZonePositions pcall failed for " .. airfieldName)
        end
    end

    -- Fallback to airbase centre if no clear position found
    -- to be fixed later with get random coordinates around airbase using surface type road
    if not (spawnX and spawnY) then
        local center = airbase:GetVec2()
        spawnX = center.x + math.random(-50, 50)
        spawnY = center.y + math.random(-50, 50)
        env.info("SpawnWarehouse: falling back to airbase centre for " .. airfieldName)
    end

    local warehouseHeading = 180 -- degrees

    -- Convert heading to radians for vector math
    local headingRad = math.rad(warehouseHeading)
    local forwardX = math.cos(headingRad)
    local forwardY = math.sin(headingRad)
    local leftX = -forwardY
    local leftY = forwardX

    -- Build warehouse static entry
    local warehouse = {
        category = "Warehouses",
        type = "Warehouse",
        country = coalitionSide or 0,
        x = spawnX,
        y = spawnY,
        heading = math.rad(warehouseHeading),
        name = warehouseName,
    }

    local okAdd, err = pcall(function() mist.dynAddStatic(warehouse) end)
    if not okAdd then
        env.info("SpawnWarehouse: mist.dynAddStatic failed for " .. warehouseName .. " : " .. tostring(err))
    else
        env.info("Warehouse created at " .. airfieldName)
    end

    -- Tents around the warehouse
    local tentSpacing = 20
    local numTents = 3
    local sideOffset = 30

    for i = 1, numTents do
        local tentForwardOffset = (i - 1) * tentSpacing

        local leftTentX = spawnX + (leftX * sideOffset) + (forwardX * tentForwardOffset)
        local leftTentY = spawnY + (leftY * sideOffset) + (forwardY * tentForwardOffset)

        local rightTentX = spawnX - (leftX * sideOffset) + (forwardX * tentForwardOffset)
        local rightTentY = spawnY - (leftY * sideOffset) + (forwardY * tentForwardOffset)

        local tentLeft = {
            category = "Fortifications",
            type = "FARP Tent",
            country = coalitionSide or 0,
            x = leftTentX,
            y = leftTentY,
            heading = math.rad(warehouseHeading),
            name = warehouseName .. "_TentL" .. i,
        }

        local tentRight = {
            category = "Fortifications",
            type = "FARP Tent",
            country = coalitionSide or 0,
            x = rightTentX,
            y = rightTentY,
            heading = math.rad(warehouseHeading),
            name = warehouseName .. "_TentR" .. i,
        }

        pcall(function() mist.dynAddStatic(tentLeft) end)
        pcall(function() mist.dynAddStatic(tentRight) end)
    end

    env.info("Tents placed around warehouse at " .. airfieldName)
end

--------------------------------------------------------
-----------Depoly Warehouses to airfields-----------------
------------------------------------------------------


function isInList(list, value)
    if not list then return false end
    for _, v in ipairs(list) do if v == value then return true end end
    return false
end

-- Spawn a warehouse for each airfield in AirfieldNames.
-- Pass an optional default coalitionSide (numeric country id expected by SpawnWarehouse).
function SpawnWarehousesForAllAirfields(coalitionSideDefault)
    local side = coalitionSideDefault or 1 -- default country id
    for _, airfieldName in ipairs(AirfieldNames or {}) do
        local warehouseName = "Warehouse - " .. airfieldName
        SpawnWarehouse(airfieldName, warehouseName, side)
    end
end

-- Spawn warehouses and attempt to use blue/red lists to choose side.
-- Supply numeric IDs for blueSide and redSide (adjust to your mission country IDs).
function SpawnWarehousesByFaction(blueSide, redSide, defaultSide)
    blueSide     = "USA"     or 1
    redSide      = "RUSSIA"      or 2
    defaultSide  = defaultSide  or 0
    

    -- Ensure saved lists exist / are loaded
    if not (blueAirfields and redAirfields) then
        env.info("SpawnWarehousesByFaction: blueAirfields/redAirfields nil - call loadAirfields() before spawning")
        return
    end

    -- Spawn on blue list
    for _, airfieldName in ipairs(blueAirfields or {}) do
        local warehouseName = "Warehouse - " .. airfieldName
        SpawnWarehouse(airfieldName, warehouseName, blueSide)
    end

    -- Spawn on red list
    for _, airfieldName in ipairs(redAirfields or {}) do
        local warehouseName = "Warehouse - " .. airfieldName
        SpawnWarehouse(airfieldName, warehouseName, redSide)
    end
end


--------------------------------------------------------
-----------End Depoly Warehouses to airfields-------------
--------------------------------------------------------

---------------------------------------------------------
-- Create opszones around all airfields in blueAirfields and redAirfields
---------------------------------------------------------
OPS_Zones = SET_OPSZONE:New()

function CreateAllAirfieldOpszones()
    for _, airfieldName in ipairs(blueAirfields) do
        local airbase = AIRBASE:FindByName(airfieldName)
        if airbase then
            local zone = ZONE_AIRBASE:New(airfieldName, 5000)
            local opzone = OPSZONE:New(zone):SetDrawZone(true):SetObjectCategories(Object.Category.UNIT):SetUnitCategories(Unit.Category.GROUND_UNIT)
            OPS_Zones:AddZone(opzone)
        else
            env.info("CreateAllAirfieldOpszones: Airbase not found for blue: " .. tostring(airfieldName))
        end
    end
    for _, airfieldName in ipairs(redAirfields) do
        local airbase = AIRBASE:FindByName(airfieldName)
        if airbase then
            local zone = ZONE_AIRBASE:New(airfieldName, 5000)
            local opzone = OPSZONE:New(zone):SetDrawZone(true):SetObjectCategories(Object.Category.UNIT):SetUnitCategories(Unit.Category.GROUND_UNIT)
            OPS_Zones:AddZone(opzone)
        else
            env.info("CreateAllAirfieldOpszones: Airbase not found for red: " .. tostring(airfieldName))
        end
    end
end

-- Spawn a group at a point within a zone


function SpawnGroupclearzone(GroupTemplate, GroupName, SpawnZone, range)
    range = range or 25
    
    local ok, posTable = pcall(function() return SpawnZone:GetClearZonePositions(range, 1) end)
    if not ok or not posTable then
        env.info("SpawnGroupAtPoint: GetClearZonePositions failed for " .. tostring(GroupName))
        return
    end

    -- Take first position from table
    local Spawnpoint = posTable[1]
    
    if not Spawnpoint or not Spawnpoint.x or not Spawnpoint.y then
        env.info("SpawnGroupAtPoint: invalid spawn position for " .. tostring(GroupName))
        return
    end

    env.info("Spawning " .. tostring(GroupTemplate) .. " with name " .. tostring(GroupName))
    local Group_Spawn = SPAWN:NewWithAlias(GroupTemplate, GroupName)
    Group_Spawn:InitPositionVec2(Spawnpoint)
    Group_Spawn:Spawn()
end

function SpawnGroupAtPoint(GroupTemplate, GroupName, SpawnZone, inner, outer, surfaceTypes)
    inner = inner or 15  -- Default inner radius
    outer = outer or 100  -- Default outer radius
    local Spawnpoint = SpawnZone:GetRandomVec2(inner, outer, surfaceTypes)

    if not Spawnpoint or not Spawnpoint.x or not Spawnpoint.y then
        env.info("SpawnGroupAtPoint: invalid spawn position for " .. tostring(GroupName))
        return
    end

    env.info("Spawning " .. tostring(GroupTemplate) .. " with name " .. tostring(GroupName))
    local Group_Spawn = SPAWN:NewWithAlias(GroupTemplate, GroupName)
    Group_Spawn:InitPositionVec2(Spawnpoint)
    Group_Spawn:Spawn()
end
function SelectGroupstoSpawn(coalitionSide)
    guardTemplates = {}
    samTemplates = {}
    airfieldList = {}
    
    if coalitionSide == "blue" then
        guardTemplates = {Group_Blue_Mech, Group_Blue_APC, Group_Blue_Armoured}
        samTemplates = {Group_Blue_SAM1, Group_Blue_SAM2, Group_Blue_SAM3, Group_Blue_SAM4}
        airfieldList = blueAirfields
    elseif coalitionSide == "red" then
        guardTemplates = {Group_Red_Mech, Group_Red_APC, Group_Red_Armoured}
        samTemplates = {Group_Red_SAM1, Group_Red_SAM2, Group_Red_SAM3, Group_Red_SAM4}
        airfieldList = redAirfields
    else
        env.info("SpawnAirfieldGuards: Invalid coalitionSide - " .. tostring(coalitionSide))
        return
    end
end

-- Get airfield position and create airfield-wide zone
function SpawnAirfieldGuards(coalitionSide)
    SelectGroupstoSpawn(coalitionSide)
    for _, airfieldName in ipairs(airfieldList or {}) do
        -- Get warehouse position
        local ab = AIRBASE:FindByName(airfieldName)
        if ab then
            local ok, abvec = pcall(function() return ab:GetVec2() end)
            if ok and abvec and abvec.x then
                local airfieldZone = ZONE_RADIUS:New("zone_airfield_" .. airfieldName, abvec, 2000, false)
                env.info("Airfield zone created for " .. airfieldName .. ": Deploying patrol groups")
                
                -- Deploy additional guards around the airfield
                for i = 1, 2 do
                    local randomIndex = math.random(1, #guardTemplates)
                    local guardTemplate = guardTemplates[randomIndex]
                    local GroupName = guardTemplate .. "_Patrol_" .. airfieldName .. "_" .. i
                    SpawnGroupclearzone(guardTemplate, GroupName, airfieldZone, 25)
                end
                
                -- Deploy additional SAM sites around the airfield
                for i = 1, 2 do
                    local randomIndex = math.random(1, #samTemplates)
                    local samTemplate = samTemplates[randomIndex]
                    local GroupName = samTemplate .. "_SAMSite_" .. airfieldName .. "_" .. i
                    SpawnGroupclearzone(samTemplate, GroupName, airfieldZone, 25)
                end
            else
                env.info("SpawnAirfieldGuards: failed to get airbase Vec2 for " .. tostring(airfieldName))
            end
        else
            env.info("SpawnAirfieldGuards: airbase not found for " .. tostring(airfieldName))
        end
    end    
end
function SpawnWarehouseGuards(coalitionSide)
    SelectGroupstoSpawn(coalitionSide)

    for _, airfieldName in ipairs(airfieldList or {}) do
        -- Get warehouse position
        local warehouseName = "Warehouse - " .. airfieldName
        local warehouse = STATIC:FindByName(warehouseName)
        
        if warehouse then
            local ok, wvec = pcall(function() return warehouse:GetVec2() end)
            if ok and wvec and wvec.x then
                -- Create warehouse guard zone
                local warehouseZone = ZONE_RADIUS:New("zone_warehouse_" .. warehouseName, wvec, 200, false)
                env.info("Warehouse zone created for " .. airfieldName)
                
                -- Spawn 2 random guard groups at warehouse
                for i = 1, 2 do
                    local randomIndex = math.random(1, #guardTemplates)
                    local guardTemplate = guardTemplates[randomIndex]
                    local GroupName = guardTemplate .. "_Guard_" .. airfieldName .. "_" .. i
                    SpawnGroupAtPoint(guardTemplate, GroupName, warehouseZone, 75, 150)
                end
                
                -- Spawn 2 random SAM groups at warehouse
                for i = 1, 2 do
                    local randomIndex = math.random(1, #samTemplates)
                    local samTemplate = samTemplates[randomIndex]
                    local GroupName = samTemplate .. "_SAM_" .. airfieldName .. "_" .. i
                    SpawnGroupAtPoint(samTemplate, GroupName, warehouseZone, 75, 150)
                end
            else
                env.info("SpawnAirfieldGuards: failed to get warehouse Vec2 for " .. tostring(warehouseName))
            end
        else
            env.info("SpawnAirfieldGuards: warehouse not found for " .. tostring(airfieldName))
        end


    end
end