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

function SelectRandomTemplate(templateList)
    if not templateList or #templateList == 0 then
        env.info("SelectRandomTemplate: empty template list")
        return nil
    end
    local randomIndex = math.random(1, #templateList)
    return templateList[randomIndex]
end
--- Get all airbase names that are airdromes, excluding those named "H" add to list "AairfieldNames"
local function SpawnTemplateExists(prefix)
    if not prefix or prefix == "" then return false end
    -- exact group match
    if GROUP:FindByName(prefix) then return true end
    -- search all groups for prefix substring
    local ok, groups = pcall(function() return world.getAllGroups() end)
    if not ok or not groups then return false end
    for _, g in ipairs(groups) do
        local okn, name = pcall(function() return g:getName() end)
        if okn and name and type(name) == "string" then
            if name:find(prefix, 1, true) then
                return true
            end
        end
    end
    return false
end
local function ValidateGroupGlobals()
    for k, v in pairs(_G) do
        if type(k) == "string" and k:match("^Group_") then
            if type(v) ~= "string" then
                env.info("ValidateGroupGlobals: " .. k .. " is not a string (value type: " .. type(v) .. ")")
            else
                if not SpawnTemplateExists(v) then
                    env.info("ValidateGroupGlobals: TEMPLATE NOT FOUND in mission -> " .. k .. " = '" .. tostring(v) .. "'")
                end
            end
        end
    end
end
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
-- Initialize zone sets as MOOSE SET_ZONE so :AddZone and :ForEachZone exist
blueAirfieldszoneset = blueAirfieldszoneset or SET_ZONE:New()
redAirfieldszoneset  = redAirfieldszoneset  or SET_ZONE:New()
referenceAirfield = referenceAirfield or nil
ValidateGroupGlobals()
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
                redAirfieldszoneset:AddZone(airbase:GetZone())
            else
                table.insert(blueAirfields, airfieldName)
                blueAirfieldszoneset:AddZone(airbase:GetZone())
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
local function NormalizeSide(side)
    if not side then return nil end
    if type(side) == "number" then
        if side == country.id.RUSSIA then return "red" end
        if side == country.id.USA then return "blue" end
        local ok, coal = pcall(function() return country.getCoalition(side) end)
        if ok and coal == coalition.side.RED then return "red" end
        if ok and coal == coalition.side.BLUE then return "blue" end
        return nil
    end
    local s = string.lower(tostring(side))
    if s:find("russia") or s:find("rus") or s:find("red") then return "red" end
    if s:find("usa") or s:find("us") or s:find("blue") then return "blue" end
    return nil
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
    -- sensible defaults (strings accepted; SpawnWarehouse handles country conversion)
    blueSide     = blueSide or "USA"
    redSide      = redSide or "RUSSIA"
    defaultSide  = defaultSide or 0

    -- table to store metadata for later retrieval: WarehousesByAirfield[airfieldName] = { name, x, y, side }
    WarehousesByAirfield = WarehousesByAirfield or {}

    -- Ensure saved lists exist / are loaded
    if not (blueAirfields and redAirfields) then
        env.info("SpawnWarehousesByFaction: blueAirfields/redAirfields nil - call loadAirfields() before spawning")
        return WarehousesByAirfield
    end

    -- Spawn on blue list
    for _, airfieldName in ipairs(blueAirfields or {}) do
        local warehouseName = "Warehouse - " .. airfieldName
        SpawnWarehouse(airfieldName, warehouseName, blueSide)

        -- attempt to capture static info (position) for later use
        local ok, staticObj = pcall(function() return STATIC:FindByName(warehouseName) end)
        local x, y = nil, nil
        if ok and staticObj then
            local ok2, vec = pcall(function() return staticObj:GetVec2() end)
            if ok2 and vec and vec.x then
                x, y = vec.x, vec.y
            end
        end

        WarehousesByAirfield[airfieldName] = { name = warehouseName, x = x, y = y, side = blueSide }
    end

    -- Spawn on red list
    for _, airfieldName in ipairs(redAirfields or {}) do
        local warehouseName = "Warehouse - " .. airfieldName
        SpawnWarehouse(airfieldName, warehouseName, redSide)

        local ok, staticObj = pcall(function() return STATIC:FindByName(warehouseName) end)
        local x, y = nil, nil
        if ok and staticObj then
            local ok2, vec = pcall(function() return staticObj:GetVec2() end)
            if ok2 and vec and vec.x then
                x, y = vec.x, vec.y
            end
        end

        WarehousesByAirfield[airfieldName] = { name = warehouseName, x = x, y = y, side = redSide }
    end

    return WarehousesByAirfield
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


function SpawnGroupInClearZone(GroupTemplate, GroupName, ParentZone, inner, outer, surfaceTypes, clearRange, tmpZoneRadius, maxAttempts)
    inner = inner or 15
    outer = outer or 100
    clearRange = clearRange or 25
    tmpZoneRadius = tmpZoneRadius or 500
    maxAttempts = tonumber(maxAttempts) or 10

    if not ParentZone then
        env.info("SpawnGroupInClearZone: ParentZone is nil for " .. tostring(GroupName))
        return false
    end

    for attempt = 1, maxAttempts do
        -- get a random point in the provided parent zone
        local okRand, randPoint = pcall(function() return ParentZone:GetRandomVec2(inner, outer, surfaceTypes) end)
        if not okRand or not randPoint or not randPoint.x then
            env.info(string.format("SpawnGroupInClearZone: attempt %d/%d failed to get random point for %s", attempt, maxAttempts, tostring(GroupName)))
            -- try next attempt
            
        end

        
        -- create a temporary radius zone around that point (only if randPoint valid)
        local tmpZone = nil
        if okRand and randPoint and randPoint.x then
            local tmpZoneName = "tmp_spawn_zone_" .. tostring(math.random(100000,999999))
            pcall(function() tmpZone = ZONE_RADIUS:New(tmpZoneName, randPoint, tmpZoneRadius, false) end)
        end

        -- attempt to get a clear-zone position inside the temp zone
        local spawnPoint = nil
        if tmpZone and type(tmpZone.GetClearZonePositions) == "function" then
            local ok2, posTable = pcall(function() return tmpZone:GetClearZonePositions(clearRange, 1) end)
            if ok2 and posTable and posTable[1] then
                spawnPoint = posTable[1]
            end
        end

        -- fallback: try tmpZone:GetRandomVec2
        if not spawnPoint and tmpZone and type(tmpZone.GetRandomVec2) == "function" then
            local ok3, p = pcall(function() return tmpZone:GetRandomVec2(0, tmpZoneRadius) end)
            if ok3 and p and p.x then spawnPoint = p end
        end

        -- final fallback: try ParentZone:GetRandomVec2
        if not spawnPoint then
            local ok4, p2 = pcall(function() return ParentZone:GetRandomVec2(inner, outer, surfaceTypes) end)
            if ok4 and p2 and p2.x then spawnPoint = p2 end
        end

        if spawnPoint and spawnPoint.x then
            -- spawn the group at the chosen point
            env.info(string.format("SpawnGroupInClearZone: attempt %d/%d spawning %s as %s", attempt, maxAttempts, tostring(GroupTemplate), tostring(GroupName)))
            local Group_Spawn = SPAWN:NewWithAlias(GroupTemplate, GroupName)
            pcall(function() Group_Spawn:InitPositionVec2(spawnPoint) end)
            local okSpawn, err = pcall(function() Group_Spawn:Spawn() end)

            -- cleanup temporary zone (best-effort)
            pcall(function()
                if tmpZone then
                    if type(tmpZone.Destroy) == "function" then tmpZone:Destroy() end
                    if type(tmpZone.Remove) == "function" then tmpZone:Remove() end
                end
            end)

            if okSpawn then
                return true
            else
                env.info("SpawnGroupInClearZone: spawn failed: " .. tostring(err))
                return false
            end
        else
            env.info(string.format("SpawnGroupInClearZone: attempt %d/%d could not find clear point for %s", attempt, maxAttempts, tostring(GroupName)))
            -- cleanup tmpZone before next attempt
            pcall(function()
                if tmpZone then
                    if type(tmpZone.Destroy) == "function" then tmpZone:Destroy() end
                    if type(tmpZone.Remove) == "function" then tmpZone:Remove() end
                end
            end)
            -- continue next attempt
        end
    end

    env.info("SpawnGroupInClearZone: exhausted attempts (" .. tostring(maxAttempts) .. ") - failed to spawn " .. tostring(GroupName))
    return false
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
        -- Get Airfield Zone
        local ab = AIRBASE:FindByName(airfieldName)
        if ab then
            local ok, abvec = pcall(function() return ab:GetVec2() end)
            if ok and abvec and abvec.x then
                local airfieldZone = ZONE_RADIUS:New("zone_airfield_" .. airfieldName, abvec, 2000, false)
                env.info("Airfield zone created for " .. airfieldName .. ": Deploying patrol groups")
                
                -- Deploy additional guards around the airfield
                for i = 1, 4 do
                    local randomIndex = math.random(1, #guardTemplates)
                    local guardTemplate = guardTemplates[randomIndex]
                    local GroupName = guardTemplate .. "_Patrol_" .. airfieldName .. "_" .. i
                    pcall(function() SpawnGroupInClearZone(guardTemplate, GroupName, airfieldZone, 500, 1000, land.SurfaceType.LAND) end)
                end
                
                -- Deploy additional SAM sites around the airfield
                for i = 1, 2 do
                    local randomIndex = math.random(1, #samTemplates)
                    local samTemplate = samTemplates[randomIndex]
                    local GroupName = samTemplate .. "_SAMSite_" .. airfieldName .. "_" .. i
                    pcall(function() SpawnGroupInClearZone(samTemplate, GroupName, airfieldZone, 500, 1500, land.SurfaceType.LAND) end)
                end
                -- Check parking spots before deploying main SAM site
                local parkingData = airbaseParkingSummary(airfieldName)
                    if parkingData and parkingData.aircraftParkingCount > 70 then
                        local siteTemplate, siteGroupName
                        if coalitionSide == "blue" then
                            siteTemplate = Group_Blue_SAM_Site
                            siteGroupName = siteTemplate .. "_MainSite_" .. airfieldName
                        elseif coalitionSide == "red" then
                            siteTemplate = Group_Red_SAM_Site
                            siteGroupName = siteTemplate .. "_MainSite_" .. airfieldName
                        end
                        if siteTemplate then
                        -- spawn using clear-zone function with 170m search radius
                             SpawnGroupclearzone(siteTemplate, siteGroupName, airfieldZone, 150)
                             env.info("SpawnAirfieldGuards: Main SAM site spawned (clearzone) for " .. airfieldName)
                        end
                else
                    env.info("SpawnAirfieldGuards: Not enough parking spots for main SAM site at " .. airfieldName.."No. "..parkingData.aircraftParkingCount)
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
                local warehouseZone = ZONE_RADIUS:New("zone_warehouse_" .. warehouseName, wvec, 1500, false)
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

---------------------------------
-----Build Chief functions-------
---------------------------------
function DefineChief(coalitionSide)
    if string.lower(coalitionSide or "") == "blue" then
    BlueChief = CHIEF:New(coalition.side.BLUE, BlueAgents)
    BlueAgents = SET_GROUP:New():FilterCoalitions("blue"):FilterStart()
    BlueChief:Start()
    BlueChief:SetVerbosity(ChiefVerbosity)
    elseif string.lower(coalitionSide or "") == "red" then
    RedChief = CHIEF:New(coalition.side.RED, RedAgents)
    RedAgents = SET_GROUP:New():FilterCoalitions("red"):FilterStart()
    RedChief:SetVerbosity(ChiefVerbosity)
    RedChief:Start()
    Intel = RedIntel
    else
         env.info("DefineChief: Invalid coalitionSide - " .. tostring(coalitionSide))
         return
    end     
end

-----Build intel groups

function ChiefIntelgroups (coalitionSide)
    if string.lower(coalitionSide or "") == "blue" then
    BlueDetectionSetGroup = SET_GROUP:New()
    BlueDetectionSetGroup:FilterCoalitions("blue")
    BlueDetectionSetGroup:FilterStart()
    BlueIntel = INTEL:New(BlueDetectionSetGroup, "blue", "CIA")
    BlueIntel:SetClusterAnalysis(true, true)
    BlueIntel:__Start(2)
    elseif string.lower(coalitionSide or "") == "red" then
    RedDetectionSetGroup = SET_GROUP:New()
    RedDetectionSetGroup:FilterCoalitions("red")
    RedDetectionSetGroup:FilterStart()
    RedIntel = INTEL:New(RedDetectionSetGroup, "red", "KGB")
    RedIntel:SetClusterAnalysis(true, true)
    RedIntel:__Start(2)
    else
         env.info("ChiefIntelgroups: Invalid coalitionSide - " .. tostring(coalitionSide))
         return
     end
end

function ChiefSettings(coalitionSide)
    if string.lower(coalitionSide or "") == "blue" then
    BlueChief:SetStrategy(CHIEF.Strategy.AGGRESSIVE)
    BlueChief:SetDefcon(CHIEF.DEFCON.RED)
    BlueChief:SetLimitMission(MissionLimit, AUFTRAG.Type.ARTY)
    BlueChief:SetLimitMission(MissionLimit, AUFTRAG.Type.BARRAGE)
    BlueChief:SetLimitMission(MissionLimit, AUFTRAG.Type.GROUNDATTACK)
    BlueChief:SetLimitMission(MissionLimit, AUFTRAG.Type.RECON)
    BlueChief:SetLimitMission(MissionLimit, AUFTRAG.Type.BAI)
    BlueChief:SetLimitMission(MissionLimit, AUFTRAG.Type.INTERCEPT)
    BlueChief:SetLimitMission(MissionLimit, AUFTRAG.Type.SEAD)
    BlueChief:SetLimitMission(MissionLimit, AUFTRAG.Type.CAPTUREZONE)
    BlueChief:SetLimitMission(MissionLimit, AUFTRAG.Type.CASENHANCED)
    BlueChief:SetLimitMission(MissionLimit, AUFTRAG.Type.CAS)
    BlueChief:SetLimitMission(ChiefMissionLimit, Total)
    --SetResponse on Target Detection - controls Chief response to detected threats
    BlueChief:SetResponseOnTarget(1, 2, 1, TARGET.Category.AIRCRAFT, AUFTRAG.Type.INTERCEPT, 1)
    BlueChief:SetResponseOnTarget(1, 2, 1, TARGET.Category.GROUND, AUFTRAG.Type.BAI, 1)
    BlueChief:SetResponseOnTarget(1, 2, 1, TARGET.Category.GROUND, AUFTRAG.Type.ARMOUREDATTACK, 4)

    elseif string.lower(coalitionSide or "") == "red" then
    RedChief:SetStrategy(CHIEF.Strategy.AGGRESSIVE)
    RedChief:SetDefcon(CHIEF.DEFCON.RED)
    RedChief:SetLimitMission(MissionLimit, AUFTRAG.Type.ARTY)
    RedChief:SetLimitMission(MissionLimit, AUFTRAG.Type.BARRAGE)
    RedChief:SetLimitMission(MissionLimit, AUFTRAG.Type.GROUNDATTACK)
    RedChief:SetLimitMission(MissionLimit, AUFTRAG.Type.RECON)
    RedChief:SetLimitMission(MissionLimit, AUFTRAG.Type.BAI)
    RedChief:SetLimitMission(MissionLimit, AUFTRAG.Type.INTERCEPT)
    RedChief:SetLimitMission(MissionLimit, AUFTRAG.Type.SEAD)
    RedChief:SetLimitMission(MissionLimit, AUFTRAG.Type.CAPTUREZONE)
    RedChief:SetLimitMission(MissionLimit, AUFTRAG.Type.CASENHANCED)
    RedChief:SetLimitMission(MissionLimit, AUFTRAG.Type.CAS)
    RedChief:SetLimitMission(ChiefMissionLimit, Total)
    --SetResponse on Target Detection - controls Chief response to detected threats
    RedChief:SetResponseOnTarget(1, 2, 1, TARGET.Category.AIRCRAFT, AUFTRAG.Type.INTERCEPT, 1)
    RedChief:SetResponseOnTarget(1, 2, 1, TARGET.Category.GROUND, AUFTRAG.Type.BAI, 1)
    RedChief:SetResponseOnTarget(1, 2, 1, TARGET.Category.GROUND, AUFTRAG.Type.ARMOUREDATTACK, 4)
    else
        env.info("ChiefSettings: Invalid coalitionSide - " .. tostring(coalitionSide))
        return
     end
end    

function ChiefZones(coalitionSide)

    local side = string.lower(tostring(coalitionSide or ""))

    local function addZonesToChief(chiefObj, setObj, addFnName)
        if not chiefObj or type(chiefObj[addFnName]) ~= "function" or not setObj or type(setObj.ForEachZone) ~= "function" then
            return
        end
        setObj:ForEachZone(function(z)
            pcall(function() chiefObj[addFnName](chiefObj, z) end)
        end)
    end

    if side == "blue" then
        -- add airfield border/conflict zones from sets (iterate and call AddBorderZone/AddConflictZone)
        addZonesToChief(BlueChief, blueAirfieldszoneset, "AddBorderZone")
        addZonesToChief(BlueChief, redAirfieldszoneset, "AddConflictZone")

        -- also iterate the polygon border sets if present
        addZonesToChief(BlueChief, BlueBorderSet, "AddBorderZone")
        addZonesToChief(BlueChief, RedBorderSet, "AddConflictZone")

        -- CAP zones (guarded)
        for _, cz in ipairs({CapZone8, CapZone9, CapZone10, CapZone13, CapZone15}) do
            if cz and type(BlueChief.AddCapZone) == "function" then
                pcall(function() BlueChief:AddCapZone(cz, 26000, 400, 180, 25) end)
            end
        end

    elseif side == "red" then
        -- add airfield border/conflict zones for red chief
        addZonesToChief(RedChief, redAirfieldszoneset, "AddBorderZone")
        addZonesToChief(RedChief, blueAirfieldszoneset, "AddConflictZone")

        -- also iterate the polygon border sets if present
        addZonesToChief(RedChief, RedBorderSet, "AddBorderZone")
        addZonesToChief(RedChief, BlueBorderSet, "AddConflictZone")

        -- CAP zones (guarded)
        for _, cz in ipairs({CapZone2, CapZone3, CapZone4, CapZone6, CapZone7}) do
            if cz and type(RedChief.AddCapZone) == "function" then
                pcall(function() RedChief:AddCapZone(cz, 26000, 400, 180, 25) end)
            end
        end

    else
        env.info("ChiefZones: Invalid coalitionSide - " .. tostring(coalitionSide))
        return
    end
end

function ChiefResourceLists(coalitionSide)
  if string.lower(coalitionSide or "") == "blue" then
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
        local ResourceOccupied, resourceCAS=BlueChief:CreateResource(AUFTRAG.Type.CASENHANCED, 1, 2)
        BlueChief:AddToResource(ResourceOccupied, AUFTRAG.Type.GROUNDATTACK, 1, 2, nil)
        BlueChief:AddToResource(ResourceOccupied, AUFTRAG.Type.RECON, 1, nil)
    elseif string.lower(coalitionSide or "") == "red" then
        -- Create a resource list for an empty zone and add an ONGUARD mission for up to three IFVs.
        local ResourceListEmpty, ResourceAPC=RedChief:CreateResource(AUFTRAG.Type.PATROLZONE,  0, 3, GROUP.Attribute.GROUND_APC)
        local ResourceInfAlpha=RedChief:AddToResource(ResourceListEmpty, AUFTRAG.Type.ONGUARD, 1, 3, GROUP.Attribute.GROUND_INFANTRY)
        local ResourceInfBravo=RedChief:AddToResource(ResourceListEmpty, AUFTRAG.Type.ONGUARD, 1, 3, GROUP.Attribute.GROUND_INFANTRY)
        local resourceInf=RedChief:CreateResource(AUFTRAG.Type.ONGUARD, 1, 3, GROUP.Attribute.GROUND_INFANTRY)
        local resourceMech=RedChief:CreateResource(AUFTRAG.Type.PATROLZONE, 1, 3, {GROUP.Attribute.GROUND_APC,GROUP.Attribute.GROUND_IFV,GROUP.Attribute.GROUND_TANK})
            -- Resource Infantry Alpha is transported by up to 3 transport helos.
        RedChief:AddTransportToResource(ResourceInfAlpha, 1, 3, {GROUP.Attribute.AIR_TRANSPORTHELO})
        RedChief:AddTransportToResource(resourceInf, 1, 3, {GROUP.Attribute.AIR_TRANSPORTHELO})
        RedChief:AddTransportToResource(resourceInf, 1, 3, {GROUP.Attribute.GROUND_APC})
        -- Resource Infantry Bravo is transported by up to 2 APCs.gu
        RedChief:AddTransportToResource(ResourceInfBravo, 1, 2, {GROUP.Attribute.GROUND_APC})
        local ResourceOccupied, resourceCAS=BlueChief:CreateResource(AUFTRAG.Type.CASENHANCED, 1, 2)
        RedChief:AddToResource(ResourceOccupied, AUFTRAG.Type.GROUNDATTACK, 1, 2, nil)
        RedChief:AddToResource(ResourceOccupied, AUFTRAG.Type.RECON, 1, nil)
    else
    env.info("ChiefResourceLists: Invalid coalitionSide - " .. tostring(coalitionSide))
    return  
    end    
end
   
--Create an AI commander "Chief"
function CreateChief(coalitionSide)
    if string.lower(coalitionSide or "") == "blue" or string.lower(coalitionSide or "") == "red" then
        DefineChief(coalitionSide)
        ChiefIntelgroups(coalitionSide)
        ChiefSettings(coalitionSide)
        ChiefZones(coalitionSide)
        ChiefResourceLists(coalitionSide)
        env.info("CreateChief: Deployed successfully for - " .. tostring(coalitionSide))
    else
        env.info("CreateChief: Invalid coalitionSide - " .. tostring(coalitionSide))
        return
    end
end


-----------------------------------------
----------End Chief Section--------------
-----------------------------------------

----------------------------------------
-------------Auftrags Section--------------
----------------------------------------

function CreatePatrolMissionForZone(zone, speed, formation)
    if not zone then
        env.info("CreatePatrolMissionForZone: Zone is nil, cannot create patrol mission")
        return nil
    end

    -- Use default values if not provided
    speed = speed or BrigadePatrolSpeed or 20 -- Default speed in knots
    formation = formation or "Off Road" -- Default formation for ground units

    -- Create the patrol mission
    local patrolMission = AUFTRAG:NewPATROLZONE(zone, speed, 0, formation)
    env.info("CreatePatrolMissionForZone: Patrol mission created for zone " .. zone:GetName())
    return patrolMission
end
function CreateAirDefenseMissionForZone(zone)
    if not zone then
        env.info("CreateAirDefenseMissionForZone: Zone is nil, cannot create air defense mission")
        return nil
    end

    local airDefenseMission = AUFTRAG:NewAIRDEFENSE(zone)
    env.info("CreateAirDefenseMissionForZone: AIRDEFENSE mission created for zone " .. zone:GetName())
    return airDefenseMission
end
---------------------------------------------
-------------End Auftrags Section----------------
---------------------------------------------

---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------
----------------Begin Deploying Squadrons and Brigades---------------------------------------
---------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------

BlueAirwings = {}
RedAirwings = {}
BlueBrigades = {}
RedBrigades = {}
UsedSquadronNames = {} -- Global set to store used squadron names
local blueawacscount = 0
local redawacscount = 0




-- Helper function to generate a unique squadron name
function GenerateUniqueSquadronName(baseName)
    local name
    repeat
        name = math.random(1, 400) .. " " .. baseName
    until not UsedSquadronNames[name]
    UsedSquadronNames[name] = true
    return name
end



-- Create fighter squadron. If `role` is provided it selects only that template group (e.g. "Fighter", "LT_Fighter", "Attack").
-- If `role` is nil or empty it will create squadrons for all entries in FighterTemplates[side].
function CreateFighterSQN(coalitionSide, airwing, airfieldName, role)
    local side = string.lower(coalitionSide or "")
    local templates = FighterTemplates[side]
    if not templates then
        env.info("CreateFighterSQN: Invalid coalitionSide - " .. tostring(coalitionSide))
        return
    end

    -- Build list of entries to use
    local entries = {}
    if not role or role == "" then
        for _, f in ipairs(templates) do table.insert(entries, f) end
    else
        local roleLower = string.lower(role)
        for _, f in ipairs(templates) do
            if (f.key and string.lower(f.key) == roleLower) or (f.name and string.lower(f.name) == roleLower) then
                table.insert(entries, f)
            end
        end
    end

    if #entries == 0 then
        env.info("CreateFighterSQN: No templates found for role '" .. tostring(role) .. "' on side " .. tostring(coalitionSide))
        return
    end

    for _, fighter in ipairs(entries) do
        -- Choose a concrete template name (support table-of-templates or a single string)
        local chosenTemplate = fighter.template
        if type(chosenTemplate) == "table" then
            chosenTemplate = SelectRandomTemplate(chosenTemplate)
        end
  -- Inside CreateFighterSQN function:
        local squadName = GenerateUniqueSquadronName(fighter.name.."_"..airfieldName.."_Squadron")

        -- Warn if the squadron template group is missing in the mission editor
        local templateExists = GROUP:FindByName(chosenTemplate)
        if not templateExists then
            env.info("CreateFighterSQN: TEMPLATE GROUP NOT FOUND: " .. tostring(chosenTemplate) .. " - squadron may fail to spawn")
        end

        local SQN = SQUADRON:New(chosenTemplate, fighter.count or 1, squadName)
        if fighter.missions and fighter.priority then
            SQN:AddMissionCapability(fighter.missions, fighter.priority)
        end
        SQN:SetDespawnAfterLanding(true)
        SQN:SetDespawnAfterHolding(true)
        SQN:SetTakeoffHot()
        SQN:SetMissionRange(fighter.range or 80)
        airwing:AddSquadron(SQN)

        -- Create payloads from the payload table (if any)
        for _, payload in ipairs(fighter.payloads or {}) do
            local fullPayloadGroupName = chosenTemplate .. (payload.pTname or "")
            local payloadGroup = GROUP:FindByName(fullPayloadGroupName)
            if payloadGroup then
                airwing:NewPayload(payloadGroup, payload.pcount or fighter.count or 1, payload.pmission or {}, payload.pPriority or 50)
                env.info("Payload created: " .. tostring(payload.pName) .. " -> " .. tostring(fullPayloadGroupName))
            else
                env.info("CreateFighterSQN: PAYLOAD GROUP NOT FOUND: " .. tostring(fullPayloadGroupName) .. " (template " .. tostring(chosenTemplate) .. ") - skipping payload")
            end
        end

        env.info("Squadron created: " .. squadName .. " using template " .. tostring(chosenTemplate))
    end
end
function CreateAwacsSqn(airwing, coalitionSide, airfieldName)
    if not airwing or not coalitionSide or not airfieldName then
        env.info("CreateAwacsSqn: missing parameters")
        return nil
    end

    local side = string.lower(tostring(coalitionSide))
    local parkingData = airbaseParkingSummary(airfieldName)
    if not parkingData then
        env.info("CreateAwacsSqn: parking data not available for " .. tostring(airfieldName))
        return nil
    end

    if side == "blue" then
        if (blueawacscount or 0) < 1 and (parkingData.aircraftParkingCount or 0) > 100 then
            env.info("Info: AWACS SQN Deployed to Airwing: " .. tostring(airwing and pcall(function() return airwing:GetName() end) and airwing:GetName() or "<unknown>"))
            local ok, sq = pcall(function() return SQUADRON:New("Blue_AWACS", 2, "Darkstar") end)
            if not ok or not sq then
                env.info("CreateAwacsSqn: SQUADRON:New failed for Blue_AWACS -> " .. tostring(sq))
                return nil
            end
            pcall(function() sq:AddMissionCapability({AUFTRAG.Type.ORBIT, AUFTRAG.Type.AWACS}, 100) end)
            pcall(function() sq:SetFuelLowRefuel(true) end)
            pcall(function() sq:SetFuelLowThreshold(0.2) end)
            pcall(function() sq:SetTurnoverTime(10, 20) end)
            pcall(function() sq:SetTakeoffAir() end)

            pcall(function()
                local grp = GROUP:FindByName("Blue_AWACS")
                if grp and type(airwing.NewPayload) == "function" then
                    Blue_payload_Awacs = airwing:NewPayload(grp, 2, {AUFTRAG.Type.ORBIT, AUFTRAG.Type.AWACS}, 100)
                else
                    env.info("CreateAwacsSqn: Blue_AWACS payload group missing or airwing.NewPayload unavailable")
                end
            end)

            pcall(function() if type(airwing.AddSquadron) == "function" then airwing:AddSquadron(sq) end end)
            blueawacscount = (blueawacscount or 0) + 1
            BlueAwacsAirwing = airwing
            BlueAwacsAirfieldName = airfieldName
            env.info("CreateAwacsSqn: Blue AWACS squadron created at " .. tostring(airfieldName))
            return sq
        end
    elseif side == "red" then
        if (redawacscount or 0) < 1 and (parkingData.aircraftParkingCount or 0) > 100 then
            env.info("Info: AWACS SQN Deployed to Airwing: " .. tostring(airwing and pcall(function() return airwing:GetName() end) and airwing:GetName() or "<unknown>"))
            local ok, sq = pcall(function() return SQUADRON:New("Red_AWACS", 2, "Magic") end)
            if not ok or not sq then
                env.info("CreateAwacsSqn: SQUADRON:New failed for Red_AWACS -> " .. tostring(sq))
                return nil
            end
            pcall(function() sq:AddMissionCapability({AUFTRAG.Type.ORBIT, AUFTRAG.Type.AWACS}, 100) end)
            pcall(function() sq:SetFuelLowRefuel(true) end)
            pcall(function() sq:SetFuelLowThreshold(0.2) end)
            pcall(function() sq:SetTurnoverTime(10, 20) end)
            pcall(function() sq:SetTakeoffAir() end)

            pcall(function()
                local grp = GROUP:FindByName("Red_AWACS")
                if grp and type(airwing.NewPayload) == "function" then
                    Red_payload_Awacs = airwing:NewPayload(grp, 2, {AUFTRAG.Type.ORBIT, AUFTRAG.Type.AWACS}, 100)
                else
                    env.info("CreateAwacsSqn: Red_AWACS payload group missing or airwing.NewPayload unavailable")
                end
            end)

            pcall(function() if type(airwing.AddSquadron) == "function" then airwing:AddSquadron(sq) end end)
            redawacscount = (redawacscount or 0) + 1
            RedAwacsAirwing = airwing
            env.info("CreateAwacsSqn: Red AWACS squadron created at " .. tostring(airfieldName))
            return sq
        end
    else
        env.info("CreateAwacsSqn: invalid side " .. tostring(coalitionSide))
        return nil
    end

    return nil
end

-- Create a brigade at the given warehouse / airbase using the templates above
function CreateBrigadeAtWarehouse(warehouse, airbase, airfieldName, coalitionSide, numPatrolMissions)
    if not warehouse or not airbase or not airfieldName or not coalitionSide then
        env.info("CreateBrigadeAtWarehouse: missing parameters")
        return
    end

    numPatrolMissions = numPatrolMissions or 1 -- Default to 1 if not specified

    local side = string.lower(coalitionSide)
    local configs = BrigadeTemplates[side]
    if not configs then
        env.info("CreateBrigadeAtWarehouse: no brigade config for side " .. tostring(coalitionSide))
        return
    end

    local brigadeName = "Brigade " .. airfieldName
    local Brigade = BRIGADE:New(warehouse, brigadeName)
    local ok, zone = pcall(function() return airbase:GetZone() end)
    if ok and zone then
        Brigade:SetSpawnZone(zone)
        -- Assign the requested number of patrol missions
        for i = 1, numPatrolMissions do
            local patrolMission = CreatePatrolMissionForZone(zone)
            if patrolMission then
                Brigade:AddMission(patrolMission)
            end
        end
                -- Assign the requested number of patrol missions
        for i = 1, numPatrolMissions do
            local airDefenseMission = CreateAirDefenseMissionForZone(zone)
            if airDefenseMission then
                Brigade:AddMission(airDefenseMission,GROUP.Attribute.GROUND_AIRDEFENCE)
            end
        end
    else
        env.info("CreateBrigadeAtWarehouse: failed to get airbase zone for " .. tostring(airfieldName))
    end

    for _, cfg in ipairs(configs) do
        if not cfg.template then
            env.info("CreateBrigadeAtWarehouse: missing template for cfg key " .. tostring(cfg.key))
        else
            local platoonName = cfg.name .. " " .. airfieldName
            local chosenTemplate = cfg.template
            if type(chosenTemplate) == "table" then
                chosenTemplate = SelectRandomTemplate(chosenTemplate)
            end
            chosenTemplate = tostring(chosenTemplate)
            env.info("CreateBrigadeAtWarehouse: chosenTemplate -> " .. tostring(chosenTemplate) .. " (cfg.key=" .. tostring(cfg.key) .. ")")

            if not SpawnTemplateExists(chosenTemplate) then
                env.info("CreateBrigadeAtWarehouse: TEMPLATE NOT FOUND: " .. tostring(chosenTemplate) .. " - skipping platoon")
            else
                local ok, platoon = pcall(function() return PLATOON:New(chosenTemplate, cfg.count or 1, platoonName) end)
                if not ok or not platoon then
                    env.info("CreateBrigadeAtWarehouse: PLATOON:New failed for template " .. tostring(chosenTemplate) .. " (key=" .. tostring(cfg.key) .. ")")
                else
                    if cfg.missions and cfg.priority and type(platoon.AddMissionCapability) == "function" then
                        pcall(function() platoon:AddMissionCapability(cfg.missions, cfg.priority) end)
                    end
                    if cfg.attribute and type(platoon.SetAttribute) == "function" then
                        pcall(function() platoon:SetAttribute(cfg.attribute) end)
                    end
                    if cfg.weaponRange and #cfg.weaponRange == 2 and type(platoon.AddWeaponRange) == "function" then
                        local minKm, maxKm = cfg.weaponRange[1], cfg.weaponRange[2]
                        pcall(function() platoon:AddWeaponRange(UTILS.KiloMetersToNM(minKm), UTILS.KiloMetersToNM(maxKm)) end)
                    end
                    Brigade:AddPlatoon(platoon)
                end
            end
        end
     end

    if coalitionSide == "blue" then
        BlueChief:AddBrigade(Brigade)
    elseif coalitionSide == "red" then
        RedChief:AddBrigade(Brigade)
    else
        env.info("CreateBrigadeAtWarehouse: Invalid coalitionSide - " .. tostring(coalitionSide))
        return
    end
    Brigade:Start()
    env.info("Brigade created and started at " .. tostring(airfieldName) .. " (" .. tostring(side) .. ")")
    return Brigade
end


function CreateAirwing(warehouse, coalitionSide)
    local warehouseName = warehouse:GetName()
    local airfieldName = warehouseName:gsub("^Warehouse %- ", "")
    local airwingName = (string.lower(coalitionSide or "") == "red" and "Red Airwing " or "Blue Airwing ") .. airfieldName
    local airwing = AIRWING:New(warehouseName, airwingName)
    
    airwing:SetAirbase(AIRBASE:FindByName(airfieldName))
    airwing:Start()
    if string.lower(coalitionSide or "") == "blue" then
        BlueAirwings[warehouseName] = airwing
    elseif string.lower(coalitionSide or "") == "red" then
        RedAirwings[warehouseName] = airwing
    end
    env.info(airwingName .. " added to Airwing list")

    local airbase = AIRBASE:FindByName(airfieldName)
    local parkingData = airbaseParkingSummary(airfieldName)
    if not parkingData then return end

    -- create fighters / helos as before
    if parkingData.aircraftParkingCount > 10 then
        CreateFighterSQN(coalitionSide, airwing, airfieldName, "Fighter")
        CreateFighterSQN(coalitionSide, airwing, airfieldName, "LT_Fighter")
        CreateFighterSQN(coalitionSide, airwing, airfieldName, "Attack")
    else
        env.info("Not enough aircraft parking spots at " .. airfieldName)
    end

    if parkingData.heliParkingCount > 1 or parkingData.aircraftParkingCount > 1 then
        CreateFighterSQN(coalitionSide, airwing, airfieldName, "Helo")
        CreateFighterSQN(coalitionSide, airwing, airfieldName, "AttackHelo")
    else
        env.info("Not enough helicopter parking spots at " .. airfieldName)
    end

    -- Create AWACS if criteria met (uses new helper)
    pcall(function() CreateAwacsSqn(airwing, coalitionSide, airfieldName) end)

    -- Hook into Airwing spawn destroy in the event the aircraft is stuck
    airwing:HandleEvent(EVENTS.Birth)
    function airwing:OnEventBirth(EventData)
        if EventData.IniObject and EventData.IniObject:IsAircraft() then
            monitorAircraftMovement(EventData.IniObject)
        end
    end
    
    CreateBrigadeAtWarehouse(warehouse, airbase, airfieldName, coalitionSide, 2)
   
    if string.lower(coalitionSide or "") == "blue" then
        BlueChief:AddAirwing(airwing)
    elseif string.lower(coalitionSide or "") == "red" then
        RedChief:AddAirwing(airwing)
    else
        env.info("CreateAirwing: Invalid coalitionSide - " .. tostring(coalitionSide))
        return
    end
end



function DeployAirwingsFromWarehouses()
    WarehousesByAirfield = WarehousesByAirfield or {}
    for airfieldName, info in pairs(WarehousesByAirfield) do
        if type(info) == "table" and info.name then
            local staticObj = STATIC:FindByName(info.name)
            if not staticObj then
                env.info("DeployAirwingsFromWarehouses: static not found for " .. tostring(info.name) .. " (airfield " .. tostring(airfieldName) .. ") - skipping")
            else
                local sideNorm = NormalizeSide(info.side) or "blue" -- default to blue if unknown
                CreateAirwing(staticObj, sideNorm)
                env.info("DeployAirwingsFromWarehouses: CreateAirwing called for " .. tostring(info.name) .. " side=" .. tostring(sideNorm))
            end
        else
            env.info("DeployAirwingsFromWarehouses: invalid entry for airfield " .. tostring(airfieldName))
        end
    end
end

-- Call this after warehouses have been spawned (SpawnWarehousesByFaction returns WarehousesByAirfield)
function BlueOpsCTLD()
    env.info(string.format("###Blue CTLD FILE Start Load ###"))

    SETTINGS:SetPlayerMenuOff()

    Blue_ctld = CTLD:New(coalition.side.BLUE,nil,"23rd Transport Squadron")

    Blue_ctld:SetOwnSetPilotGroups(SET_GROUP:New():FilterCoalitions("blue"):FilterCategoryHelicopter():FilterFunction(
        function(grp)
            local _type = grp:GetTypeName()
            local retval = false
            if _type == "CH-47Fbl1" or _type == "UH-1H" or _type == "Mi-8MT" or _type == "Mi-8MTV2" or _type == "Mi-24P" or _type == "UH-60L" then
                retval = true
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

    -- troops/crates/repair registrations (ensure Group_* variables exist)
    Blue_ctld:AddTroopsCargo("Infantry Squad",{Group_Blue_Inf},CTLD_CARGO.Enum.TROOPS,3)
    Blue_ctld:AddTroopsCargo("Anti-Air",{Group_Blue_SAM},CTLD_CARGO.Enum.TROOPS,3,nil)
    Blue_ctld:AddTroopsCargo("M113",{Group_Blue_APC},CTLD_CARGO.Enum.TROOPS,4,nil)
    Blue_ctld:AddTroopsCargo("SHORAD",{Group_Blue_SAM},CTLD_CARGO.Enum.TROOPS,4,nil)
    Blue_ctld:AddTroopsCargo("Wrenches",{"Blue_CTLD_Wrenches"},CTLD_CARGO.Enum.ENGINEERS,4)
    Blue_ctld.EngineerSearch = 2000

    Blue_ctld:AddCratesCargo("Marder Group",{Group_Blue_Mech},CTLD_CARGO.Enum.VEHICLE,2,500)
    Blue_ctld:AddCratesCargo("Hawk_Site", {Group_Blue_SAM_Site},CTLD_CARGO.Enum.VEHICLE,8,500)
    Blue_ctld:AddCratesCargo("Leopard Group",{Group_Blue_Armoured},CTLD_CARGO.Enum.VEHICLE,4,500)
    Blue_ctld:AddCratesCargo("M109 Group",{Group_Blue_Arty},CTLD_CARGO.Enum.VEHICLE,2,500)
    Blue_ctld:AddCratesCargo("Forward Ops Base",{"Blue_CTLD_FOB"},CTLD_CARGO.Enum.FOB,4)
    Blue_ctld:AddCratesRepair("Humvee Repair","Blue_Unarmed_Humvee_Template",CTLD_CARGO.Enum.REPAIR,1)
    Blue_ctld.repairtime = 300

    -- Add blue ops zones to CTLD
    if blueAirfieldszoneset and type(blueAirfieldszoneset.ForEachZone) == "function" then
        blueAirfieldszoneset:ForEachZone(function(zone)
            Blue_ctld:AddCTLDZone(zone:GetName(),CTLD.CargoZoneType.LOAD,SMOKECOLOR.Blue,true,true)
            env.info("Blue ZONE added to CTLD LOAD ZONE: " .. zone:GetName())
        end)
    else
        env.info("BlueOpsCTLD: blueAirfieldszoneset missing or not a SET_ZONE")
    end

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
            if _type == "CH-47Fbl1" or _type == "UH-1H" or _type == "Mi-8MT" or _type == "Mi-8MTV2" or _type == "Mi-24P" or _type == "UH-60L" then
                retval = true
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

    Red_ctld:AddTroopsCargo("Infantry Squad",{Group_Red_Inf},CTLD_CARGO.Enum.TROOPS,3)
    Red_ctld:AddTroopsCargo("Anti-Air",{Group_Red_SAM},CTLD_CARGO.Enum.TROOPS,3,nil)
    Red_ctld:AddTroopsCargo("M113",{Group_Red_APC},CTLD_CARGO.Enum.TROOPS,4,nil)
    Red_ctld:AddTroopsCargo("SHORAD",{Group_Red_SAM},CTLD_CARGO.Enum.TROOPS,4,nil)
    Red_ctld:AddTroopsCargo("Wrenches",{"Red_CTLD_Wrenches"},CTLD_CARGO.Enum.ENGINEERS,4)
    Red_ctld.EngineerSearch = 2000

    Red_ctld:AddCratesCargo("Marder Group",{Group_Red_Mech},CTLD_CARGO.Enum.VEHICLE,2,500)
    Red_ctld:AddCratesCargo("Hawk_Site", {Group_Red_SAM_Site},CTLD_CARGO.Enum.VEHICLE,8,500)
    Red_ctld:AddCratesCargo("Leopard Group",{Group_Red_Armoured},CTLD_CARGO.Enum.VEHICLE,4,500)
    Red_ctld:AddCratesCargo("M109 Group",{Group_Red_Arty},CTLD_CARGO.Enum.VEHICLE,2,500)
    Red_ctld:AddCratesCargo("Forward Ops Base",{"Red_CTLD_FOB"},CTLD_CARGO.Enum.FOB,4)
    Red_ctld:AddCratesRepair("Humvee Repair","Red_Unarmed_Humvee_Template",CTLD_CARGO.Enum.REPAIR,1)
    Red_ctld.repairtime = 300

    -- Add red ops zones to CTLD
    if redAirfieldszoneset and type(redAirfieldszoneset.ForEachZone) == "function" then
        redAirfieldszoneset:ForEachZone(function(zone)
            Red_ctld:AddCTLDZone(zone:GetName(),CTLD.CargoZoneType.LOAD,SMOKECOLOR.Red,true,true)
            env.info("Red ZONE added to CTLD LOAD ZONE: " .. zone:GetName())
        end)
    else
        env.info("RedOpsCTLD: redAirfieldszoneset missing or not a SET_ZONE")
    end

    env.info(string.format("###Red CTLD FILE Loaded Succesfully###"))
end


-----Monitor zones for capture-----
function monitoropszones()
    if not OPS_Zones or type(OPS_Zones.ForEachZone) ~= "function" then
        env.info("monitoropszones: OPS_Zones missing or does not support ForEachZone")
        return
    end

    OPS_Zones:ForEachZone(function(opszone)
        local okName, zoneName = pcall(function() return opszone:GetName() end)
        env.info("Monitoring OPSZONE: " .. tostring(zoneName or "unknown"))

        -- assign safe handler for capture event
        opszone.OnAfterCaptured = function(self, From, Event, To, Coalition)
            local ok, _ = pcall(function() end) -- placeholder to keep pattern
            -- determine coalition string
            local coalitionSideStr = nil
            if Coalition == coalition.side.BLUE then coalitionSideStr = "blue"
            elseif Coalition == coalition.side.RED then coalitionSideStr = "red"
            else coalitionSideStr = tostring(Coalition) end

            local zoneObj = nil
            pcall(function() zoneObj = self:GetZone() end)
            local airfieldName = (zoneObj and zoneObj:GetName()) or zoneName or "UnknownAirfield"
            env.info("OPSZONE captured: " .. tostring(airfieldName) .. " by " .. tostring(coalitionSideStr))

            -- warehouse name used elsewhere in script
            local warehouseName = "Warehouse - " .. airfieldName

            -- remove existing airwing if present (best-effort, guarded)
            local existingAirwing = nil
            if coalitionSideStr == "blue" then
                existingAirwing = BlueAirwings and BlueAirwings[warehouseName]
            else
                existingAirwing = RedAirwings and RedAirwings[warehouseName]
            end

            if existingAirwing then
                pcall(function()
                    if type(existingAirwing.__Stop) == "function" then existingAirwing:__Stop() end
                end)
                -- try to delete stock items if API available
                if type(existingAirwing.GetStockInfo) == "function" then
                    local ok, stockInfo = pcall(function() return existingAirwing:GetStockInfo() end)
                    if ok and type(stockInfo) == "table" then
                        for stockItem, _ in pairs(stockInfo) do
                            pcall(function()
                                if type(existingAirwing._DeleteStockItem) == "function" then
                                    existingAirwing:_DeleteStockItem(stockItem)
                                end
                            end)
                        end
                    end
                end
                env.info("Existing airwing cleaned up (if supported): " .. warehouseName)
                if coalitionSideStr == "blue" and BlueAirwings then BlueAirwings[warehouseName] = nil
                elseif coalitionSideStr == "red" and RedAirwings then RedAirwings[warehouseName] = nil end
            end

            -- destroy existing warehouse static (if present)
            local ware = STATIC:FindByName(warehouseName)
            if ware then
                pcall(function() ware:Destroy() end)
                env.info("Destroyed existing warehouse static: " .. warehouseName)
            end

            -- spawn new warehouse and create airwing & guards
            local countryID = (coalitionSideStr == "blue") and country.id.USA or country.id.RUSSIA
            pcall(function() SpawnWarehouse(airfieldName, warehouseName, countryID) end)

            -- give a small delay to let static appear (best-effort); find static
            local warehouseStatic = nil
            local okFind, res = pcall(function() return STATIC:FindByName(warehouseName) end)
            if okFind then warehouseStatic = res end

            if warehouseStatic then
                -- create airwing using your existing CreateAirwing function
                pcall(function() CreateAirwing(warehouseStatic, coalitionSideStr) end)
                env.info("Deployed airwing at " .. airfieldName .. " for " .. coalitionSideStr)
                -- spawn ground brigades/guards for the new warehouse (optional)
                pcall(function() CreateBrigadeAtWarehouse(warehouseStatic, AIRBASE:FindByName(airfieldName), airfieldName, coalitionSideStr, 2) end)
            else
                env.info("monitoropszones: failed to locate newly created warehouse static: " .. warehouseName)
            end

            -- register CTLD load zone for this airfield (best-effort)
            if coalitionSideStr == "blue" and Blue_ctld then
                pcall(function() Blue_ctld:AddCTLDZone(airfieldName, CTLD.CargoZoneType.LOAD, SMOKECOLOR.Blue, true, true) end)
                env.info("Blue CTLD LOAD zone added: " .. airfieldName)
            elseif coalitionSideStr == "red" and Red_ctld then
                pcall(function() Red_ctld:AddCTLDZone(airfieldName, CTLD.CargoZoneType.LOAD, SMOKECOLOR.Red, true, true) end)
                env.info("Red CTLD LOAD zone added: " .. airfieldName)
            end
        end
    end)
end
---blue player tasking controller
function PlayerTaskingBlue()
    local settings = SETTINGS or _SETTINGS
    if settings and type(settings.SetPlayerMenuOn) == "function" then
        settings:SetPlayerMenuOn()
    end
    if settings and type(settings.SetImperial) == "function" then
        settings:SetImperial()
    end
    if settings and type(settings.SetA2G_BR) == "function" then
        settings:SetA2G_BR()
    end

    -- create controller (safe)
    local ok, BlueTaskManagerA2G = pcall(function()
        return PLAYERTASKCONTROLLER:New("82 Airbourne", coalition.side.BLUE, PLAYERTASKCONTROLLER.Type.A2G)
    end)
    if not ok or not BlueTaskManagerA2G then
        env.info("PlayerTaskingBlue: failed to create PLAYERTASKCONTROLLER")
        return nil
    end

    -- locale
    if type(BlueTaskManagerA2G.SetLocale) == "function" then
        pcall(function() BlueTaskManagerA2G:SetLocale("en") end)
    end

    -- Setup intel (best-effort)
    if type(BlueTaskManagerA2G.SetupIntel) == "function" then
        pcall(function() BlueTaskManagerA2G:SetupIntel("Blue") end)
    end

    -- Menu / callsign
    if type(BlueTaskManagerA2G.SetMenuName) == "function" then
        pcall(function() BlueTaskManagerA2G:SetMenuName("Ghost Bat") end)
    end

    -- Add accept zones CapZone1..CapZone14 if they exist
    for i = 1, 14 do
        local cz = _G["CapZone" .. i]
        if cz and type(BlueTaskManagerA2G.AddAcceptZone) == "function" then
            pcall(function() BlueTaskManagerA2G:AddAcceptZone(cz) end)
        end
    end

    -- Optional SRS setup (only if required vars provided)
    if hereSRSPath and hereSRSPort then
        if type(BlueTaskManagerA2G.SetSRS) == "function" then
            pcall(function()
                BlueTaskManagerA2G:SetSRS({130,250},{radio.modulation.AM,radio.modulation.AM},
                                         hereSRSPath,"female","en-GB",hereSRSPort,"Microsoft Hazel Desktop",0.7,hereSRSGoogle)
            end)
        end
        if type(BlueTaskManagerA2G.SetSRSBroadcast) == "function" then
            pcall(function() BlueTaskManagerA2G:SetSRSBroadcast({130,250},{radio.modulation.AM,radio.modulation.AM}) end)
        end
    end

    -- Task whitelist and radius (guarded)
    if type(BlueTaskManagerA2G.SetTaskWhiteList) == "function" then
        pcall(function()
            BlueTaskManagerA2G:SetTaskWhiteList({
                AUFTRAG.Type.CAS,
                AUFTRAG.Type.BAI,
                AUFTRAG.Type.BOMBING,
                AUFTRAG.Type.BOMBRUNWAY,
                AUFTRAG.Type.SEAD,
                AUFTRAG.Type.INTERCEPT,
                AUFTRAG.Type.CAP
            })
        end)
    end
    if type(BlueTaskManagerA2G.SetTargetRadius) == "function" then
        pcall(function() BlueTaskManagerA2G:SetTargetRadius(1000) end)
    end

    env.info("PlayerTaskingBlue: A2G controller initialized")
    return BlueTaskManagerA2G
end
---red player tasking controller
function PlayerTaskingRed()
    local settings = SETTINGS or _SETTINGS
    if settings and type(settings.SetPlayerMenuOn) == "function" then
        settings:SetPlayerMenuOn()
    end
    if settings and type(settings.SetImperial) == "function" then
        settings:SetImperial()
    end
    if settings and type(settings.SetA2G_BR) == "function" then
        settings:SetA2G_BR()
    end

    -- create controller (safe)
    local ok, RedTaskManagerA2G = pcall(function()
        return PLAYERTASKCONTROLLER:New("31st Infantry", coalition.side.RED, PLAYERTASKCONTROLLER.Type.A2G)
    end)
    if not ok or not RedTaskManagerA2G then
        env.info("PlayerTaskingRed: failed to create PLAYERTASKCONTROLLER")
        return nil
    end

    -- locale
    if type(RedTaskManagerA2G.SetLocale) == "function" then
        pcall(function() RedTaskManagerA2G:SetLocale("en") end)
    end

    -- Setup intel (best-effort)
    if type(RedTaskManagerA2G.SetupIntel) == "function" then
        pcall(function() RedTaskManagerA2G:SetupIntel("Red") end)
    end

    -- Menu / callsign
    if type(RedTaskManagerA2G.SetMenuName) == "function" then
        pcall(function() RedTaskManagerA2G:SetMenuName("SnakeEyes") end)
    end

    -- Add accept zones CapZone1..CapZone14 if they exist
    for i = 1, 14 do
        local cz = _G["CapZone" .. i]
        if cz and type(RedTaskManagerA2G.AddAcceptZone) == "function" then
            pcall(function() RedTaskManagerA2G:AddAcceptZone(cz) end)
        end
    end

    -- Optional SRS setup (only if required vars provided)
    if hereSRSPath and hereSRSPort then
        if type(RedTaskManagerA2G.SetSRS) == "function" then
            pcall(function()
                RedTaskManagerA2G:SetSRS({130,240},{radio.modulation.AM,radio.modulation.AM},
                                         hereSRSPath,"female","en-GB",hereSRSPort,"Microsoft Hazel Desktop",0.7,hereSRSGoogle)
            end)
        end
        if type(RedTaskManagerA2G.SetSRSBroadcast) == "function" then
            pcall(function() RedTaskManagerA2G:SetSRSBroadcast({127,240},{radio.modulation.AM,radio.modulation.AM}) end)
        end
    end

    -- Task whitelist and radius (guarded)
    if type(RedTaskManagerA2G.SetTaskWhiteList) == "function" then
        pcall(function()
            RedTaskManagerA2G:SetTaskWhiteList({
                AUFTRAG.Type.CAS,
                AUFTRAG.Type.BAI,
                AUFTRAG.Type.BOMBING,
                AUFTRAG.Type.BOMBRUNWAY,
                AUFTRAG.Type.SEAD,
                AUFTRAG.Type.INTERCEPT,
                AUFTRAG.Type.CAP,
                AUFTRAG.NewTROOPTRANSPORT
            })
        end)
    end
    if type(RedTaskManagerA2G.SetTargetRadius) == "function" then
        pcall(function() RedTaskManagerA2G:SetTargetRadius(1000) end)
    end

    env.info("PlayerTaskingRed: A2G controller initialized")
    return RedTaskManagerA2G
end


local function NormalizeCoalitionString(Coalition)
    local c = string.lower(tostring(Coalition or ""))
    if c == "usa" then return "blue" end
    if c == "russia" then return "red" end
    return c
end

local function FindFactoryByWarehouseName(warehouseName)
    if not warehouseName then return nil end
    local factory = STATIC:FindByName(warehouseName)
    if factory then return factory end
    local alt = warehouseName:gsub("^warehouse_", ""):gsub("^Warehouse %- ", "")
    return STATIC:FindByName("Warehouse - " .. alt) or STATIC:FindByName("warehouse_" .. alt)
end

local function IncreasePayloadIfBelow(airwing, payload, limit)
    if not payload or not airwing then return end
    if type(airwing.GetPayloadAmount) ~= "function" or type(airwing.IncreasePayloadAmount) ~= "function" then return end
    local ok, current = pcall(function() return airwing:GetPayloadAmount(payload) end)
    current = (ok and tonumber(current)) or 0
    if current <= (limit or 2) then
        pcall(function() airwing:IncreasePayloadAmount(payload, 1) end)
        env.info(string.format("Increased payload '%s' -> %d", tostring(payload), current + 1))
    end
end

local function GetPayloadSafe(airwing, payload)
    if not payload or not airwing or type(airwing.GetPayloadAmount) ~= "function" then return 0 end
    local ok, amt = pcall(function() return airwing:GetPayloadAmount(payload) end)
    return (ok and tonumber(amt)) or 0
end

local function PayloadListForCoalition(coal)
    if coal == "blue" then
        return {
            "Blue_payload_Fighter_AA","Blue_payload_Fighter_CAS","Blue_payload_LtFighter_AA",
            "Blue_payload_LtFighter_CAS","Blue_payload_LtFighter_SEAD","Blue_payload_Attack_CAS",
            "Blue_payload_Attack_SEAD","Blue_payload_helo_Trans","Blue_payload_helo_CAS",
            "Blue_payload_Attackhelo_CAS","Blue_payload_Awacs"
        }
    elseif coal == "red" then
        return {
            "Red_payload_Fighter_AA","Red_payload_LTFighter_CAS","Red_payload_LtFighter_AA",
            "Red_payload_Attack_SEAD","Red_payload_Attack_CAS","Red_payload_helo_Trans",
            "Red_payload_helo_CAS","Red_payload_Attackhelo_CAS","Red_payload_Attackhelo_Trans",
            "Red_payload_Awacs"
        }
    end
    return {}
end

local function LogPayloadSummary(airwing, warehouseName, coal)
    local payloads = PayloadListForCoalition(coal)
    local vals = {}
    for _, name in ipairs(payloads) do
        table.insert(vals, tostring(GetPayloadSafe(airwing, _G[name])))
    end
    env.info(string.format("ProduceAirwing: payload summary at %s => %s", warehouseName, table.concat(vals, ", ")))
end

local function FindSquadronsForRole(airwing, warehouseName, coal, roleKey)
    local out = {}
    if type(airwing.GetSquadrons) == "function" then
        local ok, sqns = pcall(function() return airwing:GetSquadrons() end)
        if ok and type(sqns) == "table" then
            for _, s in ipairs(sqns) do
                local okn, nm = pcall(function() return s:GetName() end)
                if okn and nm and nm:lower():find(roleKey, 1, true) then table.insert(out, s) end
            end
        end
    else
        local patterns = {
            fighter = (coal == "blue" and "Blue Fighter Squadron " or "Red Fighter Squadron "),
            ["light fighter"] = (coal == "blue" and "Blue Light Fighter Squadron " or "Red Light Fighter Squadron "),
            attack = (coal == "blue" and "Blue Attack Squadron " or "Red Attack Squadron "),
            ["transport helo"] = (coal == "blue" and "Blue Transport Helo Squadron " or "Red Transport Helo Squadron "),
            ["attack helo"] = (coal == "blue" and "Blue Attack Helo Squadron " or "Red Attack Helo Squadron "),
            awacs = (coal == "blue" and "Blue_AWACS" or "Red_AWACS")
        }
        local pat = patterns[roleKey]
        if pat then
            local airfield = warehouseName:gsub("^Warehouse %- ", ""):gsub("^warehouse_", "")
            local ok, s = pcall(function() return airwing:GetSquadron(pat .. airfield) end)
            if ok and s then table.insert(out, s) end
            if roleKey == "awacs" then
                local ok2, s2 = pcall(function() return airwing:GetSquadron(pat) end)
                if ok2 and s2 then table.insert(out, s2) end
            end
        end
    end
    return out
end

local function EnsureSquadronHasAssets(airwing, squadron, minAssets, addAmount)
    if not squadron or not airwing then return end
    local ok, count = pcall(function() return squadron:CountAssets() end)
    count = (ok and tonumber(count)) or 0
    if count < (minAssets or 2) then
        pcall(function() airwing:AddAssetToSquadron(squadron, addAmount or 2) end)
        env.info(string.format("Added assets to squadron %s (was %d)", tostring(squadron and squadron:GetName() or "unknown"), count))
    else
        env.info(string.format("Squadron %s has %d assets (ok)", tostring(squadron and squadron:GetName() or "unknown"), count))
    end
end

-- Refactored ProduceAirwing uses helpers above
local function ProduceAirwing(warehouseName, airwing, Coalition)
    if not warehouseName or not airwing or not Coalition then
        env.info("ProduceAirwing: missing parameters")
        return false
    end

    local coal = NormalizeCoalitionString(Coalition)
    local factory = FindFactoryByWarehouseName(warehouseName)
    if not factory or not factory:IsAlive() then
        env.info("ProduceAirwing: factory not found or destroyed for " .. tostring(warehouseName))
        return false
    end

    env.info(string.format("ProduceAirwing: producing for %s (coalition=%s)", tostring(warehouseName), tostring(coal)))

    for _, name in ipairs(PayloadListForCoalition(coal)) do
        IncreaseIfBelow(airwing, _G[name])
    end

    LogPayloadSummary(airwing, warehouseName, coal)

    local roles = { "fighter", "light fighter", "attack", "transport helo", "attack helo", "awacs" }
    for _, role in ipairs(roles) do
        local squadrons = FindSquadronsForRole(airwing, warehouseName, coal, role)
        for _, sq in ipairs(squadrons) do
            EnsureSquadronHasAssets(airwing, sq, 2, 2)
        end
    end

    return true
end
-- Helpers for brigade production
local function NormalizeCoalition(coalition)
    if not coalition then return nil end
    local c = string.lower(tostring(coalition))
    if c == "usa" then return "blue" end
    if c == "russia" then return "red" end
    return c
end

local function FindPlatoonSafe(brigade, name)
    if not brigade or not name then return nil end
    local ok, plt = pcall(function() return brigade:GetPlatoon(name) end)
    return ok and plt or nil
end

local function CountAssetsSafe(platoon)
    if not platoon then return 0 end
    local ok, n = pcall(function() return platoon:CountAssets() end)
    return (ok and tonumber(n)) or 0
end

local function EnsurePlatoonAssets(brigade, platoon, minAssets, addAmount)
    if not platoon or not brigade then return end
    local n = CountAssetsSafe(platoon)
    minAssets = minAssets or 2
    addAmount = addAmount or 1
    if n < minAssets then
        pcall(function() brigade:AddAssetToSquadron(platoon, addAmount) end)
        env.info(string.format("Added %d assets to platoon %s (was %d)", addAmount, tostring(platoon:GetName()), n))
    else
        env.info(string.format("Platoon %s has %d assets (ok)", tostring(platoon:GetName()), n))
    end
end

-- Refactored ProduceBrigade: lightweight, safe, coalition-aware
local function ProduceBrigadeSafe(warehouseName, brigade, Coalition)
    if not brigade or not Coalition then return false end
    local coal = NormalizeCoalition(Coalition)
    -- derive airfield name tolerant to "Warehouse - X" or "warehouse_X"
    local airfield = tostring(warehouseName or ""):gsub("^Warehouse %- ", ""):gsub("^warehouse_", "")

    env.info(string.format("ProduceBrigadeSafe: producing for brigade at %s (coalition=%s)", airfield, tostring(coal)))

    -- Define platoon name prefixes per side
    local platoonNames = {}
    if coal == "blue" then
        platoonNames = {
            {"Blue Motorised Platoon "..airfield, 3, 1},
            {"Blue Mechanised Platoon "..airfield, 3, 1},
            {"Blue Armoured Platoon "..airfield, 3, 1},
            {"Blue Artillary Platoon "..airfield, 2, 1},
            {"Blue Logistics Platoon "..airfield, 3, 1},
            {"Blue Infantry Platoon "..airfield, 3, 1},
            {"Blue SAM Platoon "..airfield, 3, 1},
        }
    elseif coal == "red" then
        platoonNames = {
            {"Red Motorised Platoon "..airfield, 3, 1},
            {"Red Mechanised Platoon "..airfield, 3, 1},
            {"Red Armoured Platoon "..airfield, 3, 1},
            {"Red Artillary Platoon "..airfield, 2, 1},
            {"Red Logistics Platoon "..airfield, 3, 1},
            {"Red Infantry Platoon "..airfield, 3, 2}, -- infantry adds 2 in red original code
            {"Red SAM Platoon "..airfield, 2, 1},
        }
    else
        env.info("ProduceBrigadeSafe: unknown coalition " .. tostring(Coalition))
        return false
    end

    -- Iterate and ensure assets
    for _, entry in ipairs(platoonNames) do
        local pname, minAssets, addAmt = entry[1], entry[2], entry[3]
        local plt = FindPlatoonSafe(brigade, pname)
        if plt then
            EnsurePlatoonAssets(brigade, plt, minAssets, addAmt)
        else
            env.info("ProduceBrigadeSafe: platoon not found: " .. tostring(pname))
        end
    end

    return true
end


local ProductionScheduler = nil

local function ProductionTick()
    -- Blue airwings
    if BlueAirwings then
        for warehouseName, airwing in pairs(BlueAirwings) do
            pcall(function() ProduceAirwing(warehouseName, airwing, "blue") end)
        end
    end
    -- Red airwings
    if RedAirwings then
        for warehouseName, airwing in pairs(RedAirwings) do
            pcall(function() ProduceAirwing(warehouseName, airwing, "red") end)
        end
    end

    -- Blue brigades
    if BlueBrigades then
        for warehouseName, brigade in pairs(BlueBrigades) do
            pcall(function() ProduceBrigadeSafe(warehouseName, brigade, "blue") end)
        end
    end

    -- Red brigades
    if RedBrigades then
        for warehouseName, brigade in pairs(RedBrigades) do
            pcall(function() ProduceBrigadeSafe(warehouseName, brigade, "red") end)
        end
    end
end

function StartProductionScheduler(interval)
    interval = tonumber(interval) or PRODUCTION_INTERVAL
    if ProductionScheduler then
        env.info("StartProductionScheduler: already running")
        return
    end
    ProductionScheduler = SCHEDULER:New(nil,
        function()
            ProductionTick()
        end,
        {}, 0, interval)
    env.info("StartProductionScheduler: started, interval=" .. tostring(interval))
end

function StopProductionScheduler()
    if ProductionScheduler then
        ProductionScheduler:Stop()
        ProductionScheduler = nil
        env.info("StopProductionScheduler: stopped")
    else
        env.info("StopProductionScheduler: not running")
    end
end

-- start at mission init (call where appropriate)
StartProductionScheduler(PRODUCTION_INTERVAL)


-- helper: track last attack time per opszone to avoid mission spam
 OpszoneLastAttackTime = OpszoneLastAttackTime or {}


local function GetZoneOwnerInfo(opszone)
    if not opszone or type(opszone.GetOwner) ~= "function" then return nil end
    local ownerID = opszone:GetOwner() or 0
    if ownerID == 1 then return "red", ownerID end
    if ownerID == 2 then return "blue", ownerID end
    return "neutral", ownerID
end

local function CountUnitsInOpsZone(opszone, coalitionStr)
    if not opszone or not opszone.GetZone then return 0 end
    local zone = opszone:GetZone()
    if not zone then return 0 end
    local set = SET_UNIT:New():FilterZones({zone})
    if coalitionStr and coalitionStr ~= "neutral" then
        set:FilterCoalitions(coalitionStr)
    end
    set:FilterOnce()
    local ok, cnt = pcall(function() return set:CountAlive() end)
    return (ok and tonumber(cnt)) or 0
end

local function CountChiefMissionsForZone(chief, auftragType, zone)
    if not chief or type(chief.GetMissions) ~= "function" or not zone then return 0 end
    local count = 0
    local ok, missions = pcall(function() return chief:GetMissions() end)
    if not ok or type(missions) ~= "table" then return 0 end
    for _, mission in pairs(missions) do
        if mission and mission.Type == auftragType and mission.Zone and mission.Zone:GetName() == zone:GetName() then
            count = count + 1
        end
    end
    return count
end

local function LaunchGroundPatrolAgainstZone(attackerChief, zone, airfieldName)
    if not attackerChief or not zone then return false end
    -- create a patrol zone mission as a generic ground assault (signature matches existing codebase)
    local ok, patrol = pcall(function() return AUFTRAG:NewPATROLZONE(zone, 80, nil, "On Road") end)
    if not ok or not patrol then
        env.info("LaunchGroundPatrolAgainstZone: failed to create patrol for " .. tostring(airfieldName))
        return false
    end
    pcall(function() attackerChief:AddMission(patrol) end)
    MESSAGE:New(string.format("%s Forces are launching a ground patrol against OPSZONE: %s", (attackerChief == RedChief and "Red" or "Blue"), airfieldName), 20):ToAll()
    return true
end

-- main tick: evaluate OPS_Zones and assign auftrag missions when zone is "heavily damaged"
local function OpszoneCaptureTick()

    if not OPS_Zones or type(OPS_Zones.ForEachZone) ~= "function" then
        env.info("OpszoneCaptureTick: OPS_Zones missing or invalid")
        return
    end

    OPS_Zones:ForEachZone(function(opszone)
        if not opszone then return end
        local zoneObj = nil
        pcall(function() zoneObj = opszone:GetZone() end)
        local airfieldName = (zoneObj and zoneObj:GetName()) or (pcall(function() return opszone:GetName() end) and opszone:GetName()) or "Unknown"
        local ownerStr, ownerID = GetZoneOwnerInfo(opszone)
        env.info("OpszoneCaptureTick: checking zone '" .. airfieldName .. "' owner=" .. tostring(ownerStr) .. "(" .. tostring(ownerID) .. ")")

        -- count units belonging to the owner in this zone
        local friendlyCount = CountUnitsInOpsZone(opszone, ownerStr)
        env.info(string.format("OpszoneCaptureTick: friendly unit count in %s = %d", airfieldName, friendlyCount))

        -- skip neutral or well-defended zones
        if ownerStr == "neutral" then
            return
        end

        -- if the owner has few units, trigger the opposing chief to add a patrol mission to capture
        if friendlyCount < OPSZONE_MIN_DEFEND_COUNT then
            local now = timer.getTime()
            local last = OpszoneLastAttackTime[airfieldName] or 0
            if now - last < OPSZONE_ATTACK_COOLDOWN then
                env.info("OpszoneCaptureTick: cooldown active for " .. airfieldName)
                return
            end

            -- pick attacker chief (opposite of owner)
            local attackerChief = (ownerStr == "red") and BlueChief or RedChief
            if not attackerChief then
                env.info("OpszoneCaptureTick: attacker chief not available for " .. airfieldName)
                return
            end

            -- limit number of similar missions already in chief for that zone
            local existing = CountChiefMissionsForZone(attackerChief, AUFTRAG.Type.PATROLZONE, zoneObj)
            if existing >= 2 then
                env.info("OpszoneCaptureTick: attacker chief already has " .. existing .. " patrols for " .. airfieldName)
                return
            end

            -- Launch attack mission
            local launched = LaunchGroundPatrolAgainstZone(attackerChief, zoneObj, airfieldName)
            if launched then
                OpszoneLastAttackTime[airfieldName] = now
                env.info("OpszoneCaptureTick: launched ground patrol against " .. airfieldName)
            end
        end
    end)
end

local OpszoneCaptureScheduler = nil

function StartOpszoneCaptureScheduler(startDelay, interval)
    startDelay = tonumber(startDelay) or 30
    interval = tonumber(interval) or 60
    if OpszoneCaptureScheduler then
        env.info("StartOpszoneCaptureScheduler: already running")
        return
    end
    -- safe wrapper: pcall the tick so errors won't kill Moose internals
    OpszoneCaptureScheduler = SCHEDULER:New(nil,
        function()
            pcall(OpszoneCaptureTick)
        end,
        {}, startDelay, interval)
    env.info("StartOpszoneCaptureScheduler: started (delay=" .. startDelay .. " interval=" .. interval .. ")")
end

function StopOpszoneCaptureScheduler()
    if OpszoneCaptureScheduler then
        pcall(function() OpszoneCaptureScheduler:Stop() end)
        OpszoneCaptureScheduler = nil
        env.info("StopOpszoneCaptureScheduler: stopped")
    else
        env.info("StopOpszoneCaptureScheduler: not running")
    end
end

-- start it (adjust delay/interval as required)
StartOpszoneCaptureScheduler(30, 60)

-- small utilities to harden event handlers

local function SafeCall(fn, ...)
    if type(fn) ~= "function" then return end
    local ok, err = pcall(fn, ...)
    if not ok then env.info("SafeCall error: " .. tostring(err)) end
end

-- Standard defensive pattern for Moose event callbacks that provide EventData
-- Usage: replace fragile handlers with function(E) SafeEventHandler(E) end
local function SafeEventHandler(EventData, handlerName)
    if not EventData then
        env.info((handlerName or "EventHandler") .. ": missing EventData")
        return nil
    end
    -- common Moose fields: IniObject, IniUnit, IniGroup, IniElement
    local asset = EventData.IniObject or EventData.IniUnit or EventData.IniGroup or EventData.IniElement
    if not asset then
        env.info((handlerName or "EventHandler") .. ": missing IniObject/IniUnit for event")
        return nil
    end
    return asset
end

-- Example wrapper to attach a safe OnAfterDead handler on a Moose object that accepts EventData
-- Replace direct assignments like obj:OnAfterDead(function(asset) ... end) with:
-- AttachSafeOnAfterDead(obj, function(asset) ... end)
local function AttachSafeOnAfterDead(obj, handler)
    if not obj or type(handler) ~= "function" then return end
    -- many Moose classes provide SetOnAfterDead or OnAfterDead; handle both patterns
    if type(obj.OnAfterDead) == "function" then
        local orig = obj.OnAfterDead
        obj.OnAfterDead = function(self, EventData)
            local asset = SafeEventHandler(EventData, "OnAfterDead")
            if not asset then return end
            SafeCall(handler, asset, EventData)
            -- call original if present
            if type(orig) == "function" then pcall(orig, self, EventData) end
        end
    elseif type(obj.AddEventHandler) == "function" then
        -- alternative: register a generic event handler (example API varies)
        pcall(function()
            obj:AddEventHandler("AfterDead", function(EventData)
                local asset = SafeEventHandler(EventData, "AfterDead")
                if not asset then return end
                SafeCall(handler, asset, EventData)
            end)
        end)
    else
        -- fallback: try to set method if exists
        pcall(function() obj.OnAfterDead = function(self, EventData)
            local asset = SafeEventHandler(EventData, "OnAfterDead")
            if not asset then return end
            SafeCall(handler, asset, EventData)
        end end)
    end
end

function GCI()
    -- Set up AWACS called "AWACS North". It will use the AwacsAW Airwing set up above and be of the "blue" coalition. Homebase is Kutaisi.
    -- The AWACS Orbit Zone is a round zone set in the mission editor named "Awacs Orbit", the FEZ is a Polygon-Zone called "Rock" we have also
    -- set up in the mission editor with a late activated helo named "Rock#ZONE_POLYGON". Note this also sets the BullsEye to be referenced as "Rock".
    -- The CAP station zone is called "Fremont". We will be on 255 AM.
    local Blueawacs = AWACS:New("Darkstar",BlueAwacsAirwing,"blue"    ,AIRBASE:FindByName(BlueAwacsAirfieldName),"CAP_Zone_SW-1",ZONE:FindByName("Bulls"),"CAP_Zone_SW-1",255,radio.modulation.AM )
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

    local Redawacs = AWACS:New("Magic",RedAwacsAirwing,"red",AIRBASE:FindByName(BlueAwacsAirfieldName),"CAP_Zone_NW-1",ZONE:FindByName("Bulls"),"CAP_Zone_NW-1",245,radio.modulation.AM )
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
end
