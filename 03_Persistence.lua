local lfs = require("lfs")
local filepath = lfs.writedir() .. "Missions\\WoC-Sinai\\Save\\"

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
        file:write("unitsInZones = " .. mist.utils.serialize("unitsInZones", unitsInZones))
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
            typeName = static:GetTypeName()
        })
    end)

    -- Save the data to a file
    local fileName = filepath .. "static_objects.lua"
    local file = io.open(fileName, "w")
    if file then
        file:write("staticObjects = " .. mist.utils.serialize("staticObjects", staticObjects))
        file:close()
        trigger.action.outText("Static objects saved to " .. fileName, 10)
    else
        trigger.action.outText("Failed to save static objects", 10)
    end
end

-- Function to save airwings and brigades
local function saveAirwingsAndBrigades()
    local airwingsAndBrigades = {
        blueAirwings = {},
        redAirwings = {},
        blueBrigades = {},
        redBrigades = {}
    }

    for warehouseName, airwing in pairs(BlueAirwings) do
        airwingsAndBrigades.blueAirwings[warehouseName] = airwing:GetStockInfo()
    end

    for warehouseName, airwing in pairs(RedAirwings) do
        airwingsAndBrigades.redAirwings[warehouseName] = airwing:GetStockInfo()
    end

    -- Save the data to a file
    local fileName = filepath .. "airwings_and_brigades.lua"
    local file = io.open(fileName, "w")
    if file then
        file:write("airwingsAndBrigades = " .. mist.utils.serialize("airwingsAndBrigades", airwingsAndBrigades))
        file:close()
        trigger.action.outText("Airwings and brigades saved to " .. fileName, 10)
    else
        trigger.action.outText("Failed to save airwings and brigades", 10)
    end
end

-- Schedule the functions to run periodically
mist.scheduleFunction(saveUnitLocationsInZones, {}, timer.getTime() + 10, 300) -- Runs every 300 seconds (5 minutes)
mist.scheduleFunction(saveStaticObjects, {}, timer.getTime() + 10, 300) -- Runs every 300 seconds (5 minutes)
mist.scheduleFunction(saveAirwingsAndBrigades, {}, timer.getTime() + 10, 300) -- Runs every 300 seconds (5 minutes)

local function loadSavedData()
    local unitLocationsFile = filepath .. "unit_locations_in_zones.lua"
    local staticObjectsFile = filepath .. "static_objects.lua"
    local airwingsAndBrigadesFile = filepath .. "airwings_and_brigades.lua"

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
                    heading = 0
                })
            end
        end
    end

    -- Load airwings and brigades
    local airwingsAndBrigades = dofile(airwingsAndBrigadesFile)
    if airwingsAndBrigades then
        for warehouseName, stockInfo in pairs(airwingsAndBrigades.blueAirwings) do
            local airwing = BlueAirwings[warehouseName]
            if airwing then
                for stockItem, count in pairs(stockInfo) do
                    airwing:AddStock(stockItem, count)
                end
            end
        end

        for warehouseName, stockInfo in pairs(airwingsAndBrigades.redAirwings) do
            local airwing = RedAirwings[warehouseName]
            if airwing then
                for stockItem, count in pairs(stockInfo) do
                    airwing:AddStock(stockItem, count)
                end
            end
        end
    end
end

local function initializeMission()
    local unitLocationsFile = filepath .. "unit_locations_in_zones.lua"
    local staticObjectsFile = filepath .. "static_objects.lua"
    local airwingsAndBrigadesFile = filepath .. "airwings_and_brigades.lua"

    -- Deploy opszones and initialize chiefs
    sortairfields()
    DeployForces()
    CreateBlueChief()
    CreateRedChief()

    if lfs.attributes(unitLocationsFile) and lfs.attributes(staticObjectsFile) and lfs.attributes(airwingsAndBrigadesFile) then
        loadSavedData()
    else
        -- Call your functions to spawn groups and assets fresh
        deployairwings()
    end
end

-- Call the initialize function at mission start
initializeMission()