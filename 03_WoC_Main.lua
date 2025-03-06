---Start the main script for setting up the Wings of Conflict Mission--
SamCount = 1
MinDistance = 300
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
        Spawnpoint = SpawnZone:GetRandomCoordinate(50, 1000, land.SurfaceType.LAND)
        if land.getSurfaceType(Spawnpoint) == land.SurfaceType.LAND then
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
    env.info("Finished Spawning Blue warehouse at airbase "..airfieldName)

    if  parkingCount > 100 then
        Spawn_Near_airbase(Group_Blue_SAM_Site, airfieldName, MinDistance, MaxDistance ,false)
    end

    Spawn_Near_airbase(Group_Blue_SAM, airfieldName, MinDistance, MaxDistance)
    Spawn_Near_airbase(Group_Blue_Mech, airfieldName, MinDistance, MaxDistance)
    Spawn_Near_airbase(Group_Blue_APC, airfieldName, MinDistance, MaxDistance)
    Spawn_Near_airbase(Group_Blue_Armoured, airfieldName, MinDistance, MaxDistance)
    Spawn_Near_airbase(Group_Blue_Inf, airfieldName, MinDistance, MaxDistance)
    Spawn_Near_airbase(Group_Blue_Truck, airfieldName, MinDistance, MaxDistance)

    env.info("Finished Spawning Blue Groups at airbase "..airfieldName)


    CreateAirfieldOpszones(airfieldName)
    env.info("Finished Creating Opszone at airbase "..airfieldName)
end

local function SpawnRedForces(airfieldName, warehouseName, coalitionSide, MinDistance, MaxDistance)
    local parkingCount = aircraftParkingCount +heliParkingCount
  
    SpawnWarehouse(airfieldName, warehouseName, coalitionSide)
    env.info("Finished Spawning Blue warehouse at airbase "..airfieldName)

     if parkingCount > 100 then
         Spawn_Near_airbase(Group_Red_SAM_Site, airfieldName, MinDistance, MaxDistance ,false)
     end
 
     Spawn_Near_airbase(Group_Red_SAM, airfieldName, MinDistance, MaxDistance)
     Spawn_Near_airbase(Group_Red_Mech, airfieldName, MinDistance, MaxDistance)
     Spawn_Near_airbase(Group_Red_APC, airfieldName, MinDistance, MaxDistance)
     Spawn_Near_airbase(Group_Red_Armoured, airfieldName, MinDistance, MaxDistance)
     Spawn_Near_airbase(Group_Red_Inf, airfieldName, MinDistance, MaxDistance)
     Spawn_Near_airbase(Group_Red_Truck, airfieldName, MinDistance, MaxDistance)
 
     env.info("Finished Spawning Blue Groups at airbase "..airfieldName)

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
UsedSquadronNames = {} -- Global set to store used squadron names

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
    local airwingName = GenerateUniqueSquadronName("Blue Airwing " .. airfieldName)
    local airwing = AIRWING:New(warehouseName, airwingName)
    airwing:SetAirbase(AIRBASE:FindByName(airfieldName))
    airwing:Start()
    table.insert(BlueAirwings, airwing:GetName())
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
    if parkingData.aircraftParkingCount > 10 then
        local SQN1 = SQUADRON:New("F-4Phantom", 4, GenerateUniqueSquadronName("Fighter Squadron"))
        SQN1:AddMissionCapability({AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.SEAD, AUFTRAG.Type.CAS,AUFTRAG.Type.CASENHANCED, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING})
        SQN1:SetDespawnAfterHolding()
        SQN1:SetDespawnAfterLanding()
        airwing:AddSquadron(SQN1)
        :SetDespawnAfterLanding()

        local SQN2 = SQUADRON:New("F-5E", 2, GenerateUniqueSquadronName("Light Fighter Squadron"))
        SQN2:AddMissionCapability({AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING,AUFTRAG.Type.RECON,AUFTRAG.Type.CASENHANCED})
        SQN2:SetDespawnAfterHolding()
        SQN2:SetDespawnAfterLanding()
        airwing:AddSquadron(SQN2)

        local SQN3 = SQUADRON:New("A-10", 2, GenerateUniqueSquadronName("Attack Squadron"))
        SQN3:AddMissionCapability({AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING,AUFTRAG.Type.CASENHANCED})
        SQN3:SetDespawnAfterHolding()
        SQN3:SetDespawnAfterLanding()
        airwing:AddSquadron(SQN3)

        airwing:NewPayload(GROUP:FindByName("F-4Phantom_AA"), 4, {AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT}, 80)
        airwing:NewPayload(GROUP:FindByName("F-4Phantom_SEAD"), 4, {AUFTRAG.Type.SEAD})
        airwing:NewPayload(GROUP:FindByName("F-4Phantom_Strike"), 4, {AUFTRAG.Type.BOMBING, AUFTRAG.Type.CAS, AUFTRAG.Type.BAI},50)
        airwing:NewPayload(GROUP:FindByName("F-5E_AA"), 2, {AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT},80)
        airwing:NewPayload(GROUP:FindByName("F-5E_CAS"), 2, {AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING,AUFTRAG.Type.RECON,AUFTRAG.Type.CASENHANCED},70)
        airwing:NewPayload(GROUP:FindByName("A-10_CAS"), 2, {AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING,AUFTRAG.Type.CASENHANCED},60)

    else
        env.info("Not enough aircraft parking spots at " .. airfieldName)
    end

    if parkingData.heliParkingCount > 1 or parkingData.aircraftParkingCount > 1 then
        local SQN4 = SQUADRON:New("UH-1", 4, GenerateUniqueSquadronName("Rotary Squadron"))
        SQN4:AddMissionCapability({AUFTRAG.Type.TROOPTRANSPORT, AUFTRAG.Type.CARGOTRANSPORT, AUFTRAG.Type.RECON, AUFTRAG.Type.CAS, AUFTRAG.Type.BAI}):SetAttribute(GROUP.Attribute.AIR_TRANSPORTHELO)
        SQN4:SetDespawnAfterHolding()
        SQN4:SetDespawnAfterLanding()
        airwing:AddSquadron(SQN4)
        airwing:NewPayload(GROUP:FindByName("UH-1_Trans"), 4, {AUFTRAG.Type.TROOPTRANSPORT,AUFTRAG.Type.CARGOTRANSPORT,AUFTRAG.Type.RECON,AUFTRAG.Type.OPSTRANSPORT},80)
        airwing:NewPayload(GROUP:FindByName("UH-1_CAS"), 4, {AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING},50)
    else
        env.info("Not enough helicopter parking spots at " .. airfieldName)
    end

    BlueChief:AddAirwing(airwing)
    
    -- Create a Brigade
    local Brigade=BRIGADE:New(warehouse, airwingname) --Ops.Brigade#BRIGADE
    -- Set spawn zone.
    Brigade:SetSpawnZone(airbase:GetZone())
        -- TPz Fuchs platoon.
    local platoonAPC=PLATOON:New(Group_Blue_APC, 5, GenerateUniqueSquadronName("Motorised"))
    platoonAPC:AddMissionCapability({AUFTRAG.Type.PATROLZONE,AUFTRAG.Type.ARMOUREDGUARD, AUFTRAG.Type.ONGUARD}, 60):SetAttribute(GROUP.Attribute.GROUND_APC)
        -- Mechanised platoon
    local platoonMECH=PLATOON:New(Group_Blue_Mech, 5, GenerateUniqueSquadronName("Mechanised"))
    platoonMECH:AddMissionCapability({AUFTRAG.Type.PATROLZONE,AUFTRAG.Type.ARMOUREDGUARD, AUFTRAG.Type.ONGUARD}, 70)
    platoonMECH:AddWeaponRange(UTILS.KiloMetersToNM(0.5), UTILS.KiloMetersToNM(20))
        -- Armoured platoon
    local platoonArmoured =PLATOON:New(Group_Blue_Armoured, 5, GenerateUniqueSquadronName("Armoured"))
    platoonMECH:AddMissionCapability({AUFTRAG.Type.PATROLZONE,AUFTRAG.Type.ARMOUREDGUARD,AUFTRAG.Type.ARMOUREDATTACK, AUFTRAG.Type.ONGUARD}, 70)
        -- Arty platoon.
    local platoonARTY=PLATOON:New(Group_Blue_Arty, 2, GenerateUniqueSquadronName("Artillary"))
    platoonARTY:AddMissionCapability({AUFTRAG.Type.ARTY}, 80)
    platoonARTY:AddWeaponRange(UTILS.KiloMetersToNM(10), UTILS.KiloMetersToNM(32)):SetAttribute(GROUP.Attribute.GROUND_ARTILLERY)
        -- M939 Truck platoon. Can provide ammo in DCS.
    local platoonLogi=PLATOON:New(Group_Blue_Truck, 5, GenerateUniqueSquadronName("Logistics"))
    platoonLogi:AddMissionCapability({AUFTRAG.Type.AMMOSUPPLY}, 70)
    local platoonINF=PLATOON:New(Group_Blue_Inf, 5, GenerateUniqueSquadronName("Platoon"))
    platoonINF:AddMissionCapability({AUFTRAG.Type.GROUNDATTACK, AUFTRAG.Type.ONGUARD}, 50)
        -- mobile SAM
    local platoonSAM=PLATOON:New(Group_Blue_SAM, 5, GenerateUniqueSquadronName("Sam"))
    platoonINF:AddMissionCapability({AUFTRAG.Type.AIRDEFENSE}, 50)
   
    -- Add platoons.
    Brigade:AddPlatoon(platoonAPC)
    Brigade:AddPlatoon(platoonARTY)
    Brigade:AddPlatoon(platoonArmoured)
    Brigade:AddPlatoon(platoonMECH)
    Brigade:AddPlatoon(platoonLogi)
    Brigade:AddPlatoon(platoonINF)
    Brigade:AddPlatoon(platoonSAM)

    -- Start brigade.
    Brigade:Start()
    BlueChief:AddBrigade(Brigade)
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
    local airwingName = GenerateUniqueSquadronName("Red Airwing " .. airfieldName)
    local airwing = AIRWING:New(warehouseName, airwingname)
    airwing:SetAirbase(AIRBASE:FindByName(airfieldName))
    airwing:Start()
    table.insert(RedAirwings, airwing:GetName())
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
    if parkingData.aircraftParkingCount > 10 then
    local SQN1 = SQUADRON:New("Mig-21", 4, GenerateUniqueSquadronName("Fighter Squadron"))
    SQN1:AddMissionCapability({AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.SEAD, AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING,AUFTRAG.Type.CASENHANCED})
    SQN1:SetDespawnAfterHolding()
    SQN1:SetDespawnAfterLanding()
    local SQN2 = SQUADRON:New("SU-25", 2, GenerateUniqueSquadronName("Attack Squadron"))
    SQN2:AddMissionCapability({AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING,AUFTRAG.Type.RECON,AUFTRAG.Type.CASENHANCED})
    SQN2:SetDespawnAfterHolding()
    SQN2:SetDespawnAfterLanding()

    local SQN3 = SQUADRON:New("Mig-19", 2, GenerateUniqueSquadronName("Light Fighter Squadron"))
    SQN3:AddMissionCapability({AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT, AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING})
    SQN3:SetDespawnAfterHolding()
    SQN3:SetDespawnAfterLanding()

    airwing:NewPayload(GROUP:FindByName("Mig-19_AA"), 2, {AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT})
    airwing:NewPayload(GROUP:FindByName("Mig-21_AA"), 4, {AUFTRAG.Type.GCICAP, AUFTRAG.Type.CAP, AUFTRAG.Type.INTERCEPT, AUFTRAG.Type.ESCORT}, 80)
    airwing:NewPayload(GROUP:FindByName("Mig-21_CAS"), 4, {AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING,AUFTRAG.Type.CASENHANCED},50 )
    airwing:NewPayload(GROUP:FindByName("SU-25_SEAD"), 2, {AUFTRAG.Type.SEAD})
    airwing:NewPayload(GROUP:FindByName("SU-25_CAS"), 2, {AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING,AUFTRAG.Type.RECON,AUFTRAG.Type.CASENHANCED})
    airwing:AddSquadron(SQN1)
    airwing:AddSquadron(SQN2)
    airwing:AddSquadron(SQN3)
   
    
    else
    env.info("Not enough aircraft parking spots at " .. airfieldName)
    end
    if parkingData.heliParkingCount > 1 or parkingData.aircraftParkingCount > 1 then
    local SQN4 = SQUADRON:New("MI-8", 8, GenerateUniqueSquadronName("Rotary Squadron"))
    SQN4:AddMissionCapability({AUFTRAG.Type.TROOPTRANSPORT, AUFTRAG.Type.CARGOTRANSPORT, AUFTRAG.Type.RECON, AUFTRAG.Type.CAS, AUFTRAG.Type.BAI}):SetAttribute(GROUP.Attribute.AIR_TRANSPORTHELO)
    SQN4:SetDespawnAfterHolding()
    SQN4:SetDespawnAfterLanding()
    airwing:AddSquadron(SQN4)
    airwing:NewPayload(GROUP:FindByName("MI-8_Trans"), 4, {AUFTRAG.Type.TROOPTRANSPORT,AUFTRAG.Type.CARGOTRANSPORT,AUFTRAG.Type.RECON,AUFTRAG.Type.OPSTRANSPORT},80)
    airwing:NewPayload(GROUP:FindByName("MI-8_CAS"), 4, {AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING},50)
    else
    env.info("Not enough helicopter parking spots at " .. airfieldName)
    end
    RedChief:AddAirwing(airwing)
    
    -- Create a Brigade
    local Brigade=BRIGADE:New(warehouseName, airwingname) --Ops.Brigade#BRIGADE
    -- Set spawn zone.
    Brigade:SetSpawnZone(airbase:GetZone())
        -- TPz Fuchs platoon.
        local platoonAPC=PLATOON:New(Group_Red_APC, 5, GenerateUniqueSquadronName("Motorised"))
        platoonAPC:AddMissionCapability({AUFTRAG.Type.PATROLZONE,AUFTRAG.Type.ARMOUREDGUARD, AUFTRAG.Type.ONGUARD}, 60):SetAttribute(GROUP.Attribute.GROUND_APC)
            -- Mechanised platoon
        local platoonMECH=PLATOON:New(Group_Red_Mech, 5, GenerateUniqueSquadronName("Mechanised"))
        platoonMECH:AddMissionCapability({AUFTRAG.Type.PATROLZONE,AUFTRAG.Type.ARMOUREDGUARD, AUFTRAG.Type.ONGUARD}, 70)
        platoonMECH:AddWeaponRange(UTILS.KiloMetersToNM(0.5), UTILS.KiloMetersToNM(20))
            -- Armoured platoon
        local platoonArmoured =PLATOON:New(Group_Red_Armoured, 5, GenerateUniqueSquadronName("Armoured"))
        platoonMECH:AddMissionCapability({AUFTRAG.Type.PATROLZONE,AUFTRAG.Type.ARMOUREDGUARD,AUFTRAG.Type.ARMOUREDATTACK, AUFTRAG.Type.ONGUARD}, 70)
            -- Arty platoon.
        local platoonARTY=PLATOON:New(Group_Red_Arty, 2, GenerateUniqueSquadronName("Artilliary"))
        platoonARTY:AddMissionCapability({AUFTRAG.Type.ARTY}, 80)
        platoonARTY:AddWeaponRange(UTILS.KiloMetersToNM(10), UTILS.KiloMetersToNM(32)):SetAttribute(GROUP.Attribute.GROUND_ARTILLERY)
            -- M939 Truck platoon. Can provide ammo in DCS.
        local platoonLogi=PLATOON:New(Group_Red_Truck, 5, GenerateUniqueSquadronName("Logistics"))
        platoonLogi:AddMissionCapability({AUFTRAG.Type.AMMOSUPPLY}, 70)
        local platoonINF=PLATOON:New(Group_Red_Inf, 5, GenerateUniqueSquadronName("Platoon"))
        platoonINF:AddMissionCapability({AUFTRAG.Type.GROUNDATTACK, AUFTRAG.Type.ONGUARD}, 50)
            -- mobile SAM
        local platoonSAM=PLATOON:New(Group_Red_SAM, 5, GenerateUniqueSquadronName("Sam"))
        platoonINF:AddMissionCapability({AUFTRAG.Type.AIRDEFENSE}, 50)
    
    
       --Group_Blue_SAM_Site = "Hawk_Site"
       --Group_Blue_SAM = "Blue_SAM_M48_Template"
       --Group_Blue_Mech = "Blue_Mech_Marder_Template"
       --Group_Blue_APC = "Blue_APC_M113_Template"
       --Group_Blue_Armoured = "Blue_Armoured_Leopard_Template"
       --Group_Blue_Arty = "Blue_ART_M109_Template"
       --Group_Blue_Inf = "Blue_INF_M4_Template"
       --Group_Blue_Truck = "Blue_Truck_M939_Template"
        
        -- Add platoons.
        Brigade:AddPlatoon(platoonAPC)
        Brigade:AddPlatoon(platoonARTY)
        Brigade:AddPlatoon(platoonArmoured)
        Brigade:AddPlatoon(platoonMECH)
        Brigade:AddPlatoon(platoonLogi)
        Brigade:AddPlatoon(platoonINF)
        Brigade:AddPlatoon(platoonSAM)
    
    -- Start brigade.
    Brigade:Start()
    RedChief:AddBrigade(Brigade)
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


---
-- CHIEF OF STAFF
---
-- Create Blue Chief

function CreateBlueChief()
    BlueAgents = SET_GROUP:New():FilterCoalitions("blue"):FilterOnce()

    -- Define Blue Chief
    BlueChief = CHIEF:New(coalition.side.BLUE, BlueAgents)
    BlueChief:SetTacticalOverviewOn()
    BlueChief:SetVerbosity(5)

    -- Set strategy for Blue Chief
    BlueChief:SetStrategy(CHIEF.Strategy.AGGRESSIVE)
    BlueChief:SetDefcon(CHIEF.DEFCON.RED)

    BlueChief:SetBorderZones(blueAirfieldszoneset)
    BlueChief:SetConflictZones(redAirfieldszoneset)
    BlueChief:SetLimitMission(4, AUFTRAG.Type.ARTY)
    BlueChief:SetLimitMission(4, AUFTRAG.Type.BARRAGE)
    BlueChief:SetLimitMission(4, AUFTRAG.Type.GROUNDATTACK)
    BlueChief:SetLimitMission(4, AUFTRAG.Type.RECON)
    BlueChief:SetLimitMission(4, AUFTRAG.Type.BAI)
    BlueChief:SetLimitMission(8, AUFTRAG.Type.INTERCEPT)
    BlueChief:SetLimitMission(4, AUFTRAG.Type.SEAD)
    BlueChief:SetLimitMission(4, AUFTRAG.Type.CAPTUREZONE)
    BlueChief:SetLimitMission(4, AUFTRAG.Type.CASENHANCED)
    BlueChief:SetLimitMission(4, AUFTRAG.Type.CAS)
    BlueChief:SetLimitMission(100, Total)
    
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

    --allOpsZones:ForEachZone(
    --function(opzone)
    --    BlueChief:AddStrategicZone(opzone, nil, nil, nil, ResourceListEmpty)
    --end
    --)

end

-- Create Red Chief
function CreateRedChief()
    RedAgents = SET_GROUP:New():FilterCoalitions("red"):FilterOnce()

    -- Define Red Chief
      RedChief = CHIEF:New(coalition.side.RED, RedAgents)
      RedChief:SetTacticalOverviewOn()
      RedChief:SetVerbosity(5)

    -- Set strategy for Red Chief
     RedChief:SetStrategy(CHIEF.Strategy.AGGRESSIVE)
     RedChief:SetDefcon(CHIEF.DEFCON.RED)
     RedChief:SetBorderZones(redAirfieldszoneset)
     RedChief:SetConflictZones(blueAirfieldszoneset)

     RedChief:SetLimitMission(4, AUFTRAG.Type.ARTY)
     RedChief:SetLimitMission(4, AUFTRAG.Type.BARRAGE)
     RedChief:SetLimitMission(4, AUFTRAG.Type.GROUNDATTACK)
     RedChief:SetLimitMission(4, AUFTRAG.Type.RECON)
     RedChief:SetLimitMission(4, AUFTRAG.Type.BAI)
     RedChief:SetLimitMission(8, AUFTRAG.Type.INTERCEPT)
     RedChief:SetLimitMission(4, AUFTRAG.Type.SEAD)
     RedChief:SetLimitMission(4, AUFTRAG.Type.CAPTUREZONE)
     RedChief:SetLimitMission(4, AUFTRAG.Type.CASENHANCED)
     RedChief:SetLimitMission(4, AUFTRAG.Type.CAS)
     RedChief:SetLimitMission(100, Total)

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

end

CreateBlueChief()
CreateRedChief()
-- Add Airwings as assets to the Chief



 RedChief:__Start(1)
 BlueChief:__Start(1)


local CapZone1 = ZONE:FindByName("CAP_Zone_E")
local CapZone2 = ZONE:FindByName("CAP_Zone_SE")
local CapZone3 = ZONE:FindByName("CAP_Zone_Mid")
local CapZone4 = ZONE:FindByName("CAP_Zone_Mid")
local CapZone5 = ZONE:FindByName("CAP_Zone_W")



BlueChief:AddCapZone(CapZone1,26000,400,180,25)
BlueChief:AddCapZone(CapZone2,26000,400,180,25)
BlueChief:AddCapZone(CapZone3,26000,400,180,25)
RedChief:AddCapZone(CapZone3,26000,400,180,25)
RedChief:AddCapZone(CapZone4,26000,400,180,25)
RedChief:AddCapZone(CapZone5,26000,400,180,25)
BlueChief:AddBorderZone(CapZone1)
BlueChief:AddBorderZone(CapZone2)
BlueChief:AddBorderZone(CapZone3)
BlueChief:AddConflictZone(CapZone4)
BlueChief:AddConflictZone(CapZone5)
RedChief:AddConflictZone(CapZone1)
RedChief:AddConflictZone(CapZone2)
RedChief:AddBorderZone(CapZone3)
RedChief:AddBorderZone(CapZone4)
RedChief:AddBorderZone(CapZone5)

--function BlueChief:OnAfterNewContact(From, Event, To, Contact)
--    
---- Gather info of contact.
--local ContactName=BlueChief:GetContactName(Contact)
--local ContactType=BlueChief:GetContactTypeName(Contact)
--local ContactThreat=BlueChief:GetContactThreatlevel(Contact)
--
---- Text message.
--local text=string.format("Detected NEW contact: Name=%s, Type=%s, Threat Level=%d", ContactName, ContactType, ContactThreat)
--
---- Show message in log file.
--env.info(text)
--
--end


BlueChief:SetResponseOnTarget(1, 2, 1, TARGET.Category.AIRCRAFT, AUFTRAG.Type.INTERCEPT, 1)
RedChief:SetResponseOnTarget(1, 2, 1, TARGET.Category.AIRCRAFT, AUFTRAG.Type.INTERCEPT, 1)
BlueChief:SetResponseOnTarget(1, 2, 1, TARGET.Category.GROUND, AUFTRAG.Type.BAI, 1)
RedChief:SetResponseOnTarget(1, 2, 1, TARGET.Category.GROUND, AUFTRAG.Type.BAI, 1)
BlueChief:SetResponseOnTarget(1, 2, 1, TARGET.Category.GROUND, AUFTRAG.Type.ARMOUREDATTACK, 4)
RedChief:SetResponseOnTarget(1, 2, 1, TARGET.Category.GROUND, AUFTRAG.Type.ARMOUREDATTACK, 4)

---Sort the airfields into red and blue, then deploy forces.


--Start OPS Zones as a zone set. ensure this is called after creating all zones.


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

--Sort the airfields and deploy garrision forces.
sortairfields()
DeployForces()


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

deployairwings()
--function checkopszones()
--
--end

OPS_Zones = SET_OPSZONE:New():FilterOnce()
OPS_Zones:Start()

local deployairwingsSchedule = SCHEDULER:New( nil, deployairwings(),{}, 5  )
deployairwingsSchedule:Start()


----------------------------------
----------------------------------
--Test Capture Zone Functions-----
----------------------------------
----------------------------------
---just checking ops zones -----

allOpsZones:ForEachZone(function(opszone)
    env.info("Monitoring OPSZONE: " .. opszone:GetName())

    function opszone:OnAfterCaptured(From, Event, To, Coalition)

        -- Convert Coalition to a usable string
        local coalitionSide = (Coalition == coalition.side.BLUE and "blue") or "red"

        env.info("OPSZONE Capture Event Triggered! " ..
                 "From: " .. tostring(From) .. 
                 " Event: " .. tostring(Event) .. 
                 " To: " .. tostring(To) .. 
                 " Coalition: " .. tostring(coalitionSide))

        if coalitionSide then
            env.info("OpsZone " .. self:GetName() .. " captured by Coalition '" .. coalitionSide .. "'!")

           -- destroyZoneObjects(self)  -- Destroy objects in the captured zone
           -- DeployNewZoneForces(coalitionSide)  -- Deploy forces based on new owner
        else
            env.info("OpsZone capture event triggered, but Coalition was nil!")
        end
    end
end)

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

-- Schedule functions properly
local destroyzoneredSchedule = SCHEDULER:New(nil, destroyzonered, {}, 10) -- No parentheses
local destroyzoneblueSchedule = SCHEDULER:New(nil, destroyzoneblue, {}, 15) -- No parentheses

-----------------------------
-----------------------------
--------End TEstcode---------
-----------------------------
-----------------------------