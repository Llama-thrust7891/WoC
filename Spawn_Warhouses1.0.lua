
-- Display airfield assignments
trigger.action.outText("Red Airfields: " .. table.concat(redAirfields, ", ") .. "\nBlue Airfields: " .. table.concat(blueAirfields, ", "), 25)
blueWarehouseList = {}
redWarehouseList = {}

function getRunwayCenterAndHeading(airbase)
    if not airbase.ZoneRunways then 
        return airbase:GetVec2(), airbase:GetHeading() -- Default to airbase position & heading
    end

    local rightRunway = nil
    for _, runwayZone in pairs(airbase.ZoneRunways) do
        if runwayZone:IsRightRunway() then -- Assuming a function to identify right-hand runways
            rightRunway = runwayZone
            break
        end
    end
    
    local function getRunwayCenterAndHeading(airbase)
        if not airbase.ZoneRunways then 
            return airbase:GetVec2(), airbase:GetHeading() -- Default to airbase position & heading
        end
    
        local rightRunway = nil
        for _, runwayZone in pairs(airbase.ZoneRunways) do
            if runwayZone:IsRightRunway() then -- Assuming a function to identify right-hand runways
                rightRunway = runwayZone
                break
            end
        end
        
        if rightRunway then
            local points = rightRunway:GetPoints()
            local center = {
                x = (points[1].x + points[2].x) / 2,
                y = (points[1].y + points[2].y) / 2
            }
            local heading = math.atan2(points[2].y - points[1].y, points[2].x - points[1].x)
            
            -- Offset spawn point to the right of the selected runway
            local offsetDistance = 400 -- Adjust as needed
            local spawnPoint = {
                x = center.x + offsetDistance * math.cos(heading + math.pi / 2),
                y = center.y + offsetDistance * math.sin(heading + math.pi / 2)
            }
            
            -- Check surface type at the computed spawn point
            local surface = land.getSurfaceType(spawnPoint)
            if surface ~= land.SurfaceType.WATER and surface ~= land.SurfaceType.SHALLOW_WATER then
                return spawnPoint, heading
            end
        end
        
        -- Fallback to parking spot 1 position if available, else use airbase position
        if airbase.ParkingSpots and #airbase.ParkingSpots > 0 then
            local parkingSpot = airbase.ParkingSpots[1]
            return {x = parkingSpot.x, y = parkingSpot.y}, airbase:GetHeading()
        end
        
        return airbase:GetVec2(), airbase:GetHeading()
    end
end    


function findSafeSpawnPosition(airbase)
    local runwayCenter, runwayHeading = getRunwayCenterAndHeading(airbase)
    
    -- Determine perpendicular offset direction (90° right)
    local offsetAngle = runwayHeading - math.pi / 2
    local distance = 650

    local spawnPosition = {
        x = runwayCenter.x + math.cos(offsetAngle) * distance,
        y = runwayCenter.y + math.sin(offsetAngle) * distance
        --y = runwayCenter.y + math.sin(offsetAngle) * distance
        --x = runwayCenter.x + math.cos(offsetAngle) * distance,
    }

    return spawnPosition
end

function SpawnWarehouse(airfieldName, coalitionSide)
    local airbase = AIRBASE:FindByName(airfieldName)
    if not airbase then
        trigger.action.outText("Error: Airfield not found - " .. airfieldName, 10)
        return
    end

    local spawnPosition = findSafeSpawnPosition(airbase)
    local warehouseHeading = airbase:GetHeading() -- Align with airbase general heading

    local warehouseName = "warehouse_" .. airfieldName
    local warehouse = {
        category = "Warehouses",
        type = "Warehouse",
        country = coalitionSide == "red" and "Russia" or "USA",
        x = spawnPosition.x,
        y = spawnPosition.y,
        heading = warehouseHeading,
        name = warehouseName,
    }

    mist.dynAddStatic(warehouse)
    env.info("Warehouse created: " .. warehouseName)
    --trigger.action.outText("Warehouse " .. warehouseName .. " created at " .. airfieldName .. ".", 10)
    local airbasecoalition = airbase:GetCoalition()
    if airbasecoalition == "red" then
        table.insert(redWarehouseList, warehouseName)
        env.info("Warehouse added to redwarehouse list " .. warehouseName)
    elseif airbasecoalition == "blue" then
        table.insert(blueWarehouseList, warehouseName)
        env.info("Warehouse added to bluewarehouse list " .. warehouseName)
    end
end

-- Spawn warehouses for Red and Blue
for _, airfieldName in ipairs(redAirfields) do
    SpawnWarehouse(airfieldName, "red")
end

for _, airfieldName in ipairs(blueAirfields) do
    SpawnWarehouse(airfieldName, "blue")
end