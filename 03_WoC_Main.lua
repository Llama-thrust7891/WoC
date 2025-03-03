---Start the main script for setting up the Wings of Conflict Mission--
SamCount = 1
MinDistance =200
MaxDistance = 1000
--Coalition = "USA" --commented out only needed for testing

function getAllAirbaseNames()
    local airfields = {}  -- Correctly define this table
    
    
    for _, airbase in ipairs(world.getAirbases()) do
        
        table.insert(airfields, airbase:getName())  -- Insert into the correct table
       

    end
    return airfields  -- Return the correct table
    
    
end

AirfieldNames = getAllAirbaseNames()
-- Assign airfields west of "Baluza" to Red, others to Blue
redAirfields = {}
blueAirfields = {}
redAirfieldszones =  {}
blueAirfieldszones = {}
redAirfieldszoneset =  SET_ZONE:New()
blueAirfieldszoneset = SET_ZONE:New()
referenceAirfield = "Baluza"

function sortairfields()
for _, airfieldName in ipairs(AirfieldNames) do  -- Use 'airbaseNames' here
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
end


function Spawn_Near_airbase(GroupTemplate,Inner,Outer)
    local Group = GROUP:FindByName(GroupTemplate) -- Find group by name in ME
    if not GroupTemplate then
        env.info("ERROR: Group template "..GroupTemplate.." not found!")
        return
    end
    -- Generate unique name
    local GroupName = airfieldName.."_"..GroupTemplate.."_"..SamCount
    local SpawnZone = AIRBASE:FindByName(airfieldName):GetZone()
    local Spawnpoint = SpawnZone:GetRandomCoordinate(Inner, Outer, land.SurfaceType.LAND) -- Get a random Vec2

    -- Log spawn action
    env.info("Spawning "..GroupTemplate.." with name "..GroupName)

    -- Spawn using Moose
    Group_Spawn = SPAWN:NewWithAlias(GroupTemplate, GroupName)
    --Group_Spawn:InitPositionVec2(Spawnpoint)
    Group_Spawn:InitPositionCoordinate(Spawnpoint)
    Group_Spawn:Spawn()

    -- Increment counter
    SamCount = SamCount + 1
end

----create a zone object and opszone object around an airfield
function CreateAirfieldOpszones(airfieldName)
    local zoneName = "Capture Zone - " .. airfieldName
    local zoneRadius = 5000 -- 5 km capture zone
    local zone = ZONE_AIRBASE:New(airfieldName, zoneRadius)
    local opzone = OPSZONE:New(zone):SetDrawZone(true):SetCaptureThreatlevel(2)
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

function SpawnWarehouse(airfieldName, coalitionSide)
    local airbase = AIRBASE:FindByName(airfieldName)
    if not airbase then
        trigger.action.outText("Error: Airfield not found - " .. airfieldName, 10)
        return
    end
    local SpawnZone = AIRBASE:FindByName(airfieldName):GetZone()
    local Spawnpoint = SpawnZone:GetRandomCoordinate(Inner, Outer, land.SurfaceType.LAND) -- Get a random Vec2
    local warehouseHeading = airbase:GetHeading() -- Align with airbase general heading

    local warehouseName = "warehouse_" .. airfieldName
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
    env.info("Warehouse created: " .. warehouseName)
end

local function SpawnBlueForces(airfieldName, coalitionSide, MinDistance, MaxDistance)
    
    Spawn_Near_airbase(Group_Blue_SAM_Site, MinDistance, MaxDistance)
    Spawn_Near_airbase(Group_Blue_SAM, MinDistance, MaxDistance)
    Spawn_Near_airbase(Group_Blue_Mech, MinDistance, MaxDistance)
    Spawn_Near_airbase(Group_Blue_APC, MinDistance, MaxDistance)
    Spawn_Near_airbase(Group_Blue_Armoured, MinDistance, MaxDistance)
    Spawn_Near_airbase(Group_Blue_Inf, MinDistance, MaxDistance)
    Spawn_Near_airbase(Group_Blue_Truck, MinDistance, MaxDistance)
    env.info("Finished Spawning Blue Groups at airbase "..airfieldName)

    SpawnWarehouse(airfieldName, coalitionSide)
    env.info("Finished Spawning Blue warehouse at airbase "..airfieldName)
    CreateAirfieldOpszones(airfieldName)
    env.info("Finished Creating Opszone at airbase "..airfieldName)

end

function DeployForces()
    for _, airfield in ipairs(blueAirfields) do  -- Use 'airbaseNames' here
           

        if airfield then
            airfieldName = airfield:GetName()
            coalitionSide = "USA"
            SpawnBlueForces(airfieldName, coalitionSide, MinDistance, MaxDistance)
            env.inf("Deploying at airfield "..airfieldName)
        else
            env.inf("No Airbases found")
        end
    end
end

sortairfields()
DeployForces()

--Start OPS Zones as a zone set. ensure this is called after creating all zones.
OPS_Zones = SET_OPSZONE:New():FilterOnce()
OPS_Zones:Start()

env.info("Ops Zones Started")

--function checkopszones()
--
--end