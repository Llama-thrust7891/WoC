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

function AssignPatrolMission(group, airfieldName)
    if not group then
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
    group:AddMission(patrolMission)
    
    env.info("Assigned Patrol Mission to " .. group:GetName() .. " in zone: " .. airfieldName)
end

function Spawn_Near_airbase(GroupTemplate, airfieldName, Inner, Outer, Patrol)
    Patrol = Patrol ~= false -- Default to true if not explicitly set to false
    local Group = GROUP:FindByName(GroupTemplate) -- Find group by name in ME
    if not GroupTemplate then
        env.info("ERROR: Group template "..GroupTemplate.." not found!")
        return
    end
    -- Generate unique name
    local GroupName = airfieldName.."_"..GroupTemplate.."_"..SamCount
    local SpawnZone = AIRBASE:FindByName(airfieldName):GetZone()
    local Spawnpoint = SpawnZone:GetRandomCoordinate(Inner, Outer, land.SurfaceType.ROAD) -- Get a random Vec2

    -- Log spawn action
    env.info("Spawning "..GroupTemplate.." with name "..GroupName)

    -- Spawn using Moose
    Group_Spawn = SPAWN:NewWithAlias(GroupTemplate, GroupName)
    Group_Spawn:InitPositionCoordinate(Spawnpoint)
    if Patrol then
        Group_Spawn:OnSpawnGroup(AssignPatrolMission(group, airfieldName))
    end
    --Group_Spawn:OnSpawnGroup(AssignPatrolMission(Group_Spawn, airfieldName))
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
   --local parkingCount = aircraftParkingCount +heliParkingCount

    if aircraftParkingCount > 60 then
        Spawn_Near_airbase(Group_Blue_SAM_Site, airfieldName, MinDistance, MaxDistance ,false)
    end

    Spawn_Near_airbase(Group_Blue_SAM, airfieldName, MinDistance, MaxDistance)
    Spawn_Near_airbase(Group_Blue_Mech, airfieldName, MinDistance, MaxDistance)
    Spawn_Near_airbase(Group_Blue_APC, airfieldName, MinDistance, MaxDistance)
    Spawn_Near_airbase(Group_Blue_Armoured, airfieldName, MinDistance, MaxDistance)
    Spawn_Near_airbase(Group_Blue_Inf, airfieldName, MinDistance, MaxDistance)
    Spawn_Near_airbase(Group_Blue_Truck, airfieldName, MinDistance, MaxDistance)

    env.info("Finished Spawning Blue Groups at airbase "..airfieldName)

    SpawnWarehouse(airfieldName, coalitionSide)
    env.info("Finished Spawning Blue warehouse at airbase "..airfieldName)
    CreateAirfieldOpszones(airfieldName)
    env.info("Finished Creating Opszone at airbase "..airfieldName)
end

local function SpawnRedForces(airfieldName, coalitionSide, MinDistance, MaxDistance)
    --local parkingCount = aircraftParkingCount +heliParkingCount
 
     if aircraftParkingCount > 60 then
         Spawn_Near_airbase(Group_Red_SAM_Site, airfieldName, MinDistance, MaxDistance ,false)
     end
 
     Spawn_Near_airbase(Group_Red_SAM, airfieldName, MinDistance, MaxDistance)
     Spawn_Near_airbase(Group_Red_Mech, airfieldName, MinDistance, MaxDistance)
     Spawn_Near_airbase(Group_Red_APC, airfieldName, MinDistance, MaxDistance)
     Spawn_Near_airbase(Group_Red_Armoured, airfieldName, MinDistance, MaxDistance)
     Spawn_Near_airbase(Group_Red_Inf, airfieldName, MinDistance, MaxDistance)
     Spawn_Near_airbase(Group_Red_Truck, airfieldName, MinDistance, MaxDistance)
 
     env.info("Finished Spawning Blue Groups at airbase "..airfieldName)
 
     SpawnWarehouse(airfieldName, coalitionSide)
     env.info("Finished Spawning Blue warehouse at airbase "..airfieldName)
     CreateAirfieldOpszones(airfieldName)
     env.info("Finished Creating Opszone at airbase "..airfieldName)
 end



function DeployForces()
    for _, airfieldName in ipairs(blueAirfields) do
        if airfieldName then
            env.info("Processing airfield: " .. airfieldName) -- Debugging

            local coalitionSide = country.id.USA -- Ensure correct coalition format
            SpawnBlueForces(airfieldName, coalitionSide, MinDistance, MaxDistance)

            env.info("Deployed at airfield: "..airfieldName)
        else
            env.info("No Blue Airbases found")
        end
    end
    for _, airfieldName in ipairs(redAirfields) do
        if airfieldName then
            env.info("Processing airfield: " .. airfieldName) -- Debugging

            local coalitionSide = country.id.USSR -- Ensure correct coalition format
            SpawnRedForces(airfieldName, coalitionSide, MinDistance, MaxDistance)

            env.info("Deployed at airfield: "..airfieldName)
        else
            env.info("No Airbases found")
        end
    end
end

AirfieldNames = getAllAirbaseNames()
sortairfields()
DeployForces()

--Start OPS Zones as a zone set. ensure this is called after creating all zones.
OPS_Zones = SET_OPSZONE:New():FilterOnce()
OPS_Zones:Start()

env.info("Ops Zones Started")

--function checkopszones()
--
--end