-------------------------------------------------------------------
-------------------------------------------------------------------
-----Start of Chief of Staff Script--------------------------------
-------------------------------------------------------------------
-------------------------------------------------------------------
------get parking data----
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
---------------------


BlueAirwings = {}
RedAirwings = {}
UsedSquadronNames = {} -- Global set to store used squadron names
-- Warehouse Filtering
local blueWarehouseSet = SET_STATIC:New():FilterCoalitions("blue"):FilterTypes("Warehouse"):FilterStart()
local redWarehouseSet = SET_STATIC:New():FilterCoalitions("red"):FilterTypes("Warehouse"):FilterStart()

-- Debug Warehouse Counts
env.info("Blue warehouse Count: " .. tostring(#blueWarehouseSet:GetSetObjects()))
env.info("Red warehouse Count: " .. tostring(#redWarehouseSet:GetSetObjects()))

-- OP Zone Filtering
local blueopzones = SET_OPSZONE:New():FilterCoalitions("blue"):FilterStart()
local redopzones = SET_OPSZONE:New():FilterCoalitions("red"):FilterStart()

local blueAirfieldszones = {}
local redAirfieldszones = {}

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
function CreateBlueAirwing(warehouse, airwingname)
    local airwing = AIRWING:New(warehouse, airwingname)
    airwing:Start()
    table.insert(BlueAirwings, airwing:GetName())
    env.info(airwingname .. " added to Blue Airwing list")

    -- Get parking summary for the warehouse's airbase
    local warehouseName = warehouse:GetName()

    -- Remove "warehouse_" prefix
    local airfieldName = warehouseName:gsub("^warehouse_", "")

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
    local platoonAPC=PLATOON:New("Blue_APC_Template", 5, GenerateUniqueSquadronName("Motorised"))
    platoonAPC:AddMissionCapability({AUFTRAG.Type.PATROLZONE,AUFTRAG.Type.ARMOUREDGUARD, AUFTRAG.Type.ONGUARD}, 60):SetAttribute(GROUP.Attribute.GROUND_APC)
        -- Mechanised platoon
    local platoonMECH=PLATOON:New("Blue_Mech_Template", 5, GenerateUniqueSquadronName("Mechanised"))
    platoonMECH:AddMissionCapability({AUFTRAG.Type.PATROLZONE,AUFTRAG.Type.ARMOUREDGUARD,AUFTRAG.Type.ARMOUREDATTACK, AUFTRAG.Type.ONGUARD}, 70)
    platoonMECH:AddWeaponRange(UTILS.KiloMetersToNM(0.5), UTILS.KiloMetersToNM(20))
        -- Arty platoon.
    local platoonARTY=PLATOON:New("Blue_ART_Template", 2, GenerateUniqueSquadronName("Artilliary"))
    platoonARTY:AddMissionCapability({AUFTRAG.Type.ARTY}, 80)
    platoonARTY:AddWeaponRange(UTILS.KiloMetersToNM(10), UTILS.KiloMetersToNM(32)):SetAttribute(GROUP.Attribute.GROUND_ARTILLERY)
        -- M939 Truck platoon. Can provide ammo in DCS.
    local platoonLogi=PLATOON:New("Blue_Truck_Template", 5, GenerateUniqueSquadronName("Logistics"))
    platoonLogi:AddMissionCapability({AUFTRAG.Type.AMMOSUPPLY}, 70)
    local platoonINF=PLATOON:New("Blue_INF_Template", 5, GenerateUniqueSquadronName("Platoon"))
    platoonINF:AddMissionCapability({AUFTRAG.Type.GROUNDATTACK, AUFTRAG.Type.ONGUARD}, 50)
    
    -- Add platoons.
    Brigade:AddPlatoon(platoonAPC)
    Brigade:AddPlatoon(platoonARTY)
    Brigade:AddPlatoon(platoonMECH)
    Brigade:AddPlatoon(platoonLogi)
    Brigade:AddPlatoon(platoonINF)
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
     Brigade:AddMission(GaurdZone1)
     Brigade:AddMission(GaurdZone2)
     Brigade:AddMission(GaurdZone3)

end

-- Function to create Red Airwing
function CreateRedAirwing(warehouse, airwingname)
    local airwing = AIRWING:New(warehouse, airwingname)
    airwing:Start()
    table.insert(RedAirwings, airwing:GetName())
    env.info(airwingname.. " added to Red Airwing list")  -- Log the report
    -- Get parking summary for the warehouse's airbase
    local warehouseName = warehouse:GetName()

    -- Remove "warehouse_" prefix
    local airfieldName = warehouseName:gsub("^warehouse_", "")

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
    local Brigade=BRIGADE:New(warehouse, airwingname) --Ops.Brigade#BRIGADE
    -- Set spawn zone.
    Brigade:SetSpawnZone(airbase:GetZone())
        -- TPz Fuchs platoon.
    local platoonAPC=PLATOON:New("Red_APC_Template", 5, GenerateUniqueSquadronName("Motorised"))
    platoonAPC:AddMissionCapability({AUFTRAG.Type.PATROLZONE,AUFTRAG.Type.ARMOUREDGUARD,AUFTRAG.Type.ONGUARD,AUFTRAG.Type.GROUNDATTACK}, 70)
        -- Mechanised platoon
    local platoonMECH=PLATOON:New("Red_Mech_Template", 5, GenerateUniqueSquadronName("Mechanised"))
    platoonMECH:AddMissionCapability({AUFTRAG.Type.PATROLZONE,AUFTRAG.Type.ARMOUREDGUARD,AUFTRAG.Type.GROUNDATTACK,AUFTRAG.Type.ONGUARD}, 70)
    platoonMECH:AddWeaponRange(UTILS.KiloMetersToNM(0.5), UTILS.KiloMetersToNM(20))
        -- Arty platoon.
    local platoonARTY=PLATOON:New("Red_ART_Template", 2, GenerateUniqueSquadronName("Artilliary"))
    platoonARTY:AddMissionCapability({AUFTRAG.Type.ARTY}, 80)
    platoonARTY:AddWeaponRange(UTILS.KiloMetersToNM(10), UTILS.KiloMetersToNM(32)):SetAttribute(GROUP.Attribute.GROUND_ARTILLERY)
        -- M939 Truck platoon. Can provide ammo in DCS.
    local platoonLogi=PLATOON:New("Red_Truck_Template", 5, GenerateUniqueSquadronName("Logistics"))
    platoonLogi:AddMissionCapability({AUFTRAG.Type.AMMOSUPPLY}, 70)
    local platoonINF=PLATOON:New("Red_INF_Template", 5, GenerateUniqueSquadronName("Platoon"))
    platoonINF:AddMissionCapability({AUFTRAG.Type.ONGUARD}, 50)
    
    -- Add platoons.
    Brigade:AddPlatoon(platoonAPC)
    Brigade:AddPlatoon(platoonARTY)
    Brigade:AddPlatoon(platoonMECH)
    Brigade:AddPlatoon(platoonLogi)
    Brigade:AddPlatoon(platoonINF)
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
    Brigade:AddMission(GaurdZone1)
    Brigade:AddMission(GaurdZone2)
    Brigade:AddMission(GaurdZone3)

end

---
-- CHIEF OF STAFF
---
-- Create Blue Chief

function CreateBlueChief()
    BlueAgents = SET_GROUP:New():FilterCoalitions("blue"):FilterOnce()

    -- Define Blue Chief
    BlueChief = CHIEF:New(coalition.side.BLUE, BlueAgents)
    --BlueChief:SetTacticalOverviewOn()
    --BlueChief:SetVerbosity(5)

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
      --RedChief:SetTacticalOverviewOn()
      --RedChief:SetVerbosity(5)

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

-- Iterate over blue warehouses and create airwings
blueWarehouseSet:ForEachStatic(
    function(warehouse)
        local airwingName = GenerateUniqueSquadronName("Blue Airwing " .. warehouse:GetName())
        local airwing = CreateBlueAirwing(warehouse, airwingName)  -- Get the airwing object
    end
)

-- Iterate over red warehouses and create airwings
redWarehouseSet:ForEachStatic(
    function(warehouse)
        local airwingName = GenerateUniqueSquadronName("Red Airwing " .. warehouse:GetName())
        local airwing = CreateRedAirwing(warehouse, airwingName)  -- Get the airwing object
     end
)


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

local Stratzone1 = OPSZONE:FindByName("Capture Zone - Baluza") -- Replace with your reference zone name
local Stratzone2 = OPSZONE:FindByName("Capture Zone - As Salihiyah")
local Stratzone3 = OPSZONE:FindByName("Capture Zone - Abu Suwayr")
local Stratzone4 = OPSZONE:FindByName("Capture Zone - Al Ismailiyah")
local Stratzone5 = OPSZONE:FindByName("Capture Zone - Difarsuwar Airfield")
local Stratzone6 = OPSZONE:FindByName("Capture Zone - Melez")
local Stratzone7 = OPSZONE:FindByName("Capture Zone - Bir Hasanah")
local Stratzone8 = OPSZONE:FindByName("Capture Zone - Abu Rudeis")

--local function addstrategiczones()
--BlueChief:AddStrategicZone(Stratzone1, nil, 1, ResourceOccupied, ResourceListEmpty)
--BlueChief:AddStrategicZone(Stratzone2, nil, 1, ResourceOccupied, ResourceListEmpty)
--BlueChief:AddStrategicZone(Stratzone3, nil, 2, ResourceOccupied, ResourceListEmpty)
--BlueChief:AddStrategicZone(Stratzone4, nil, 2, ResourceOccupied, ResourceListEmpty)
--BlueChief:AddStrategicZone(Stratzone5, nil, 3, ResourceOccupied, ResourceListEmpty)
--BlueChief:AddStrategicZone(Stratzone6, nil, 3, ResourceOccupied, ResourceListEmpty)
--BlueChief:AddStrategicZone(Stratzone7, nil, 4, ResourceOccupied, ResourceListEmpty)
--BlueChief:AddStrategicZone(Stratzone8, nil, 4, ResourceOccupied, ResourceListEmpty)
--
--RedChief:AddStrategicZone(Stratzone1, nil, 1, ResourceOccupied, ResourceListEmpty)
--RedChief:AddStrategicZone(Stratzone2, nil, 1, ResourceOccupied, ResourceListEmpty)
--RedChief:AddStrategicZone(Stratzone3, nil, 2, ResourceOccupied, ResourceListEmpty)
--RedChief:AddStrategicZone(Stratzone4, nil, 2, ResourceOccupied, ResourceListEmpty)
--RedChief:AddStrategicZone(Stratzone5, nil, 3, ResourceOccupied, ResourceListEmpty)
--RedChief:AddStrategicZone(Stratzone6, nil, 3, ResourceOccupied, ResourceListEmpty)
--RedChief:AddStrategicZone(Stratzone7, nil, 4, ResourceOccupied, ResourceListEmpty)
--RedChief:AddStrategicZone(Stratzone8, nil, 4, ResourceOccupied, ResourceListEmpty)
--end

--add new strategic zones
--local function GetNearestZones(reference, opszones, count)
--    local distances = {}
--
--    for _, opszone in ipairs(opszones) do
--        local distance = reference:GetZone():GetCoordinate():Get2DDistance(opszone:GetZone():GetCoordinate())
--        table.insert(distances, {zone = opszone, distance = distance})
--    end
--
--    -- Sort by distance
--    table.sort(distances, function(a, b) return a.distance < b.distance end)
--
--    -- Extract the nearest 'count' zones
--    local nearest = {}
--    for i = 1, math.min(count, #distances) do
--        table.insert(nearest, distances[i])
--    end
--
--    return nearest
--end


--function BlueChief:OnAfterZoneLost(From, Event, To, OpsZone)
--    local opszone=OpsZone --Ops.OpsZone#OPSZONE
--    local redZones=SET_OPSZONE:New():FilterCoalitions("red"):FilterOnce()
--    redZones:ForEachZone(
--    local nearestRedZones = GetNearestZones(opszone, redZones, 1)
--    BlueChief:AddStrategicZone(nearestRedZones, nil, 4, ResourceOccupied, ResourceListEmpty)
--     )
--    
--    local text=string.format("Damn, we lost strategic zone %s.", opszone:GetName())
--    env.info(text)
--end
function redploywarehouse()
    local Zone = OPSZONE:GetZone()
    local airfield = Zone:GetAirbase()
    local airfieldName = airfield:GetName()
    local warehouseName = "warehouse_" .. airfieldName


-- Destroy existing warehouse
local warehouse = StaticObject.getByName(warehouseName)
if warehouse then
    warehouse:destroy()
end

-- Spawn a new warehouse at the same position
local pos = warehouse:getPoint()
local newWarehouse = mist.dynAddStatic({
    type = "Warehouse", 
    name = warehouseName .. "_RED", 
    country = (newCoalition == coalition.side.RED) and "Russia" or "USA", 
    x = pos.x, 
    y = pos.z,
})
end

--local ScheduleStratzones=TIMER:New(addstrategiczones)
--ScheduleStratzones:Start(300, 1, 5)
function OPSZONE:OnAfterCaptured(From, Event, To, Coalition)
    local Zone = OPSZONE:GetZone()
    local airfield = Zone:GetAirbase()
    local airfieldName = airfield:GetName()
    local warehouseName = "warehouse_" .. airfieldName
    local warehouse = StaticObject.getByName(warehouseName)

    env.info("Opzones ".. zone:GetName().. " Captured by Coalition ** " ..Coalition .. " ** Warehouse ".. warehouseName .." will be redeployed")
    local pos = warehouse:getPoint()
    
    if Coalition == 2 then
        if warehouse then
            warehouse:destroy()
            local newWarehouse = mist.dynAddStatic({
                type = "Warehouse", 
                name = warehouseName, 
                country = (newCoalition == coalition.side.BLUE) and "USSR" or "USA", 
                x = pos.x, 
                y = pos.z,
            })
        else
           SpawnWarehouse(airfieldName, "blue")
        end


    local airwingname = GenerateUniqueSquadronName("Blue Airwing " .. warehouse:GetName())
    CreateBlueAirwing(warehouse, airwingname)

    elseif Coalition == 1 then
        if warehouse then
            warehouse:destroy()

            local newWarehouse = mist.dynAddStatic({
                type = "Warehouse", 
                name = warehouseName, 
                country = (newCoalition == coalition.side.RED) and "USSR" or "USA", 
                x = pos.x, 
                y = pos.z,
            })
        else
            SpawnWarehouse(airfieldName, "red")    
        end


    local airwingname = GenerateUniqueSquadronName("Red Airwing " .. warehouse:GetName())
    CreateRedAirwing(warehouse, airwingname)
    else
        env.info("Unable to deploy Warehosue new Airwing and brigade, no coalition identified")
    end
    
end

--- Function called each time the Chief sends an asset group on a mission.
--function BlueChief:OnAfterOpsOnMission(From, Event, To, OpsGroup, Mission)
--    local opsgroup=OpsGroup --Ops.OpsGroup#OPSGROUP
--    local mission=Mission   --Ops.Auftrag#AUFTRAG
--    
--    -- Info message to log file which group is launched on which mission.
--    local text=string.format("Blue Chief - Group %s is on mission %s [%s]", opsgroup:GetName(), mission:GetName(), mission:GetType())
--    env.info(text)
--    
--end
    
    
--- Function called each time Chief Agents detect a new contact.
--function RedChief:OnAfterNewContact(From, Event, To, Contact)
--
--  -- Gather info of contact.
--  local ContactName=RedChief:GetContactName(Contact)
--  local ContactType=RedChief:GetContactTypeName(Contact)
--  local ContactThreat=RedChief:GetContactThreatlevel(Contact)
--
--  -- Text message.
--  --local text=string.format("Detected NEW contact: Name=%s, Type=%s, Threat Level=%d", ContactName, ContactType, ContactThreat)
--
--  -- Show message in log file.
--  --env.info(text)
--
--end

--- Function called each time the Chief sends an asset group on a mission.
--function RedChief:OnAfterOpsOnMission(From, Event, To, OpsGroup, Mission)
--  local opsgroup=OpsGroup --Ops.OpsGroup#OPSGROUP
--  local mission=Mission   --Ops.Auftrag#AUFTRAG
--
-- -- Info message to log file which group is launched on which mission.
--  local text=string.format("Red Chief - Group %s is on mission %s [%s]", opsgroup:GetName(), mission:GetName(), mission:GetType())
--  env.info(text)
--  trigger.action.outText(text,10)
--
--end


----On after airbase captured destroy and create warehouse, create airwing--- TBD