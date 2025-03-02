local function getAllAirbaseNames()
    local airfields = {}  -- Correctly define this table
    
    
    for _, airbase in ipairs(world.getAirbases()) do
        
        table.insert(airfields, airbase:getName())  -- Insert into the correct table
       

    end
    return airfields  -- Return the correct table
    
    
end

local airbaseNames = getAllAirbaseNames()
-- Assign airfields west of "Baluza" to Red, others to Blue
redAirfields = {}
blueAirfields = {}
redAirfieldszones =  {}
blueAirfieldszones = {}
redAirfieldszoneset =  SET_ZONE:New()
blueAirfieldszoneset = SET_ZONE:New()
referenceAirfield = "Baluza"


for _, airfieldName in ipairs(airbaseNames) do  -- Use 'airbaseNames' here
    local airfield = AIRBASE:FindByName(airfieldName)
    if airfield then
        local airfieldPosition = airfield:GetVec2()
        local referenceAirfieldPosition = AIRBASE:FindByName(referenceAirfield):GetVec2()
        --
        if airfieldPosition.y < referenceAirfieldPosition.y then
            table.insert(redAirfields, airfieldName)
            redAirfieldszoneset:AddZone(airfield:GetZone())

        else
            table.insert(blueAirfields, airfieldName)
            blueAirfieldszoneset:AddZone(airfield:GetZone())
        end
    end
end

-- Display airfield assignments
--trigger.action.outText("Red Airfields: " .. table.concat(redAirfields, ", ") .. "\nBlue Airfields: " .. table.concat(blueAirfields, ", "), 25)

-- Helper function to ensure units spawn on land and not runways
-- Also ensures units do not spawn at the same spot as another unit
local function findSuitableSpawnPosition(basePosition, minDistance, maxDistance, coalitionSide)
    local retries = 150 -- Max attempts to find a suitable position
    while retries > 0 do
        local angle = math.random() * 2 * math.pi
        local distance = math.random(minDistance, maxDistance)
        local xOffset = math.cos(angle) * distance
        local yOffset = math.sin(angle) * distance

        local spawnPosition = {
            x = basePosition.x + xOffset,
            y = basePosition.y + yOffset,
        }

        -- Check the surface type at the spawn position
        local surfaceType = land.getSurfaceType({ x = spawnPosition.x, y = 0, z = spawnPosition.y })
        env.info("Surface type: " .. surfaceType)
        if surfaceType == land.SurfaceType.LAND then
            return spawnPosition
        end

        retries = retries - 1
    end

    -- If no suitable position is found, Retry filtering out water positions only
    retries = 200 -- Max attempts to find a suitable position
    while retries > 0 do
        local angle = math.random() * 2 * math.pi
        local distance = math.random(minDistance, maxDistance)
        local xOffset = math.cos(angle) * distance
        local yOffset = math.sin(angle) * distance

        local spawnPosition = {
            x = basePosition.x + xOffset,
            y = basePosition.y + yOffset,
        }

        -- Check the surface type at the spawn position
        local surfaceType = land.getSurfaceType({ x = spawnPosition.x, y = 0, z = spawnPosition.y })
        if surfaceType ~= land.SurfaceType.WATER then
            return spawnPosition
        end

        retries = retries - 1
    end

  -- If no suitable position is found, give up and get random location
  local angle = math.random() * 2 * math.pi
  local distance = math.random(300, 500)
  local xOffset = math.cos(angle) * distance
  local yOffset = math.sin(angle) * 50
  local spawnPosition = {
      x = basePosition.x + xOffset,
      y = basePosition.y + yOffset,
  }
  trigger.action.outText("No subtle position found - ", 10)
    --trigger.action.outText("Warning: Could not find a suitable position for spawning units near " .. coalitionSide .. " base.", 10)
    return spawnPosition
end

local function assignRandomPatrol(group, patrolZoneName)
    local patrolZone = ZONE:FindByName(patrolZoneName)
    if not patrolZone then
        trigger.action.outText("Error: Patrol zone not found - " .. patrolZoneName, 10)
        return
    end

    -- Set up patrol behavior
    local patrol = AI_PATROL_ZONE:New(patrolZone, 10, 20) -- Patrol with speeds between 10-20
    patrol:SetControllable(group)
    patrol:__Start(1) -- Start patrol after 1 second
end

 
-- Update the garrison spawning logic to include patrols
local function createCaptureZoneAndGarrison(airfieldName, coalitionSide)
    local airfield = AIRBASE:FindByName(airfieldName)
    if not airfield then
        trigger.action.outText("Error: Airfield not found - " .. airfieldName, 10)
        return
    end

    local airfieldPosition = airfield:GetVec2()
    local zoneName = "Capture Zone - " .. airfieldName
    local zoneRadius = 5000 -- 5 km capture zone
    local zone = ZONE_RADIUS:New(zoneName, airfieldPosition, zoneRadius)
    local opzone = OPSZONE:New(zoneName):SetDrawZone(true):SetCaptureThreatlevel(2)
  
    -- Define the garrison composition
    local garrisonComposition = {}

    if coalitionSide == "red" then
        garrisonComposition = {
            EWR = { { type = "p-19 s-125 sr", count = 1 } }, -- Only spawns once
            AAA = { { type = "ZSU-23-4 Shilka", count = 2 } },
            SAM = { { type = "Osa 9A33 ln", count = 2 } },
            Armored = { { type = "T-55", count = 2 }  },
            Mechanised = {{ type = "BMP-1", count = 3 }}
        }
        table.insert(redAirfieldszones, zoneName)
        
    elseif coalitionSide == "blue" then
        garrisonComposition = {
            EWR = { { type = "Hawk sr", count = 1 } }, -- Only spawns once
            AAA = { { type = "Vulcan", count = 2 } },
            SAM = { { type = "M48 Chaparral", count = 2 }},
            Armored = { { type = "M-60", count = 2 }},
            Mechanised = {{ type = "BMP-1", count = 3 }}
            }
            table.insert(blueAirfieldszones, zoneName)
            
    end

    local function spawnGroup(groupName, unitComposition, spawnCount)
        for spawnIndex = 1, spawnCount do
            local usedPositions = {}
            local garrisonGroupName = string.format("%s-%s-%d", groupName, airfieldName, spawnIndex) -- Unique group name
            local garrisonUnits = {}

            local maxOffset = 30  -- Maximum offset for subsequent units
            local minDistance = 500 + maxOffset  -- Adjusted minimum distance
            local maxDistance = 750 - maxOffset  -- Adjusted maximum distance
            
            for _, unit in ipairs(unitComposition) do
                for i = 1, unit.count do
                    local spawnPosition
                    if i == 1 then
                        -- First unit gets a spawn position that is buffered
                        spawnPosition = findSuitableSpawnPosition(airfieldPosition, minDistance, maxDistance, coalitionSide)
                    else
                        -- Subsequent units placed relative to the first unit 
                        local angle = math.random() * 2 * math.pi
                        local distance = math.random(-maxOffset, maxOffset)
                        spawnPosition = {
                           --x = garrisonUnits[1].x + distance,
                           --y = garrisonUnits[1].y + distance,
                            x = garrisonUnits[1].x + math.cos(angle) * distance,
                            y = garrisonUnits[1].y + math.sin(angle) * distance,
                        }
                    end
            
                    -- Add the unit to the group
                    table.insert(garrisonUnits, {
                        type = unit.type,
                        x = spawnPosition.x,
                        y = spawnPosition.y,
                        heading = math.random() * 2 * math.pi,
                        skill = "Random",
                    })
                end
            end

            -- Spawn the group
            local spawnedGroup = mist.dynAdd({
                category = "GROUND",
                coalition = coalitionSide,
                country = coalitionSide == "red" and "Russia" or "USA",
                name = garrisonGroupName,
                units = garrisonUnits,
            })

            -- Assign patrols for AAA and Armored groups
            if spawnedGroup and (groupName == "AAA" or groupName == "Armored") then
                local patrolZoneName = "Patrol Zone - " .. airfieldName
                local patrolZone = ZONE_RADIUS:New(patrolZoneName, airfieldPosition, zoneRadius)
                assignRandomPatrol(GROUP:FindByName(garrisonGroupName), patrolZoneName)
            end
 
        end
    end

    -- Spawn groups with correct counts
    spawnGroup("EWR", garrisonComposition.EWR, 1) -- Spawn once
    spawnGroup("AAA", garrisonComposition.AAA, 1) -- Spawn three times
    spawnGroup("Armored", garrisonComposition.Armored, 0) -- Spawn three times
    spawnGroup("SAM", garrisonComposition.SAM, 1)
    spawnGroup("Mechanised", garrisonComposition.Mechanised,0)
    local randomNumber = math.random(1, 6)

    -- Check if the random number is greater than 5
   -- if randomNumber > 5 then
   --     SpawnSamSite = SPAWN:New(SamSite):InitPositionVec2(GetRandomVec2(ZONE:FindByName(zoneName))):spawn()
   -- end

    --trigger.action.outText("Garrison created and patrol assigned at " .. airfieldName .. ".", 10)
end

-- Create garrisons for Red
for _, airfieldName in ipairs(redAirfields) do
    createCaptureZoneAndGarrison(airfieldName, "red")
end

-- Create garrisons for Blue
for _, airfieldName in ipairs(blueAirfields) do
    createCaptureZoneAndGarrison(airfieldName, "blue")
end

OPS_Zones = SET_OPSZONE:New():FilterPrefixes("Capture Zone"):FilterOnce()
OPS_Zones:Start()

trigger.action.outText("Mission setup complete: Garrisons created for Red and Blue.", 10)


