----------------------------------
----------------------------------
--Test Capture Zone Functions-----
----------------------------------
----------------------------------
---just checking ops zones -----
allOpsZones:ForEachZone(
    function (testOpszone)
        local count =1
        testOpszoneName= testOpszone:GetName()
        env.info (count.." Opszone found ".. testOpszoneName)
        count = count+1
    end
)

function DeployOnCapture(airfields, coalitionSide)
    for _, airfieldName in ipairs(airfields) do
        if airfieldName then
            env.info("Processing airfield: " .. airfieldName)
            airbaseParkingSummary(airfieldName)
            local warehouseName = "warehouse_" .. airfieldName

            if coalitionSide == "blue" then
                SpawnBlueForces(airfieldName, warehouseName, coalitionSide, MinDistance, MaxDistance)
                env.info("Blue forces deployed at: " .. airfieldName)
            elseif coalitionSide == "red" then
                SpawnRedForces(airfieldName, warehouseName, coalitionSide, MinDistance, MaxDistance)
                env.info("Red forces deployed at: " .. airfieldName)
            else
                env.info("Unknown coalition: " .. tostring(coalitionSide) .. " for airfield: " .. airfieldName)
            end
        else
            env.info("No airbases found for coalition: " .. tostring(coalitionSide))
        end
    end
end

function DeployNewZoneForces(coalitionSide)
    if coalitionSide == "blue" then
        DeployOnCapture(blueAirfields, coalitionSide)
    elseif coalitionSide == "red" then
        DeployOnCapture(redAirfields, coalitionSide)
    else
        env.info("Invalid coalitionSide: " .. tostring(coalitionSide))
    end
end

function destroyZoneObjects(opszone)
    env.info("Destroying objects in zone: " .. opszone:GetName())

    -- Destroy all active groups in the zone
    local SetGroups = SET_GROUP:New():FilterActive():FilterZones({opszone:GetZone()}):FilterOnce()
    SetGroups:ForEachGroup(function(group)
        env.info("Destroying group: " .. group:GetName())
        group:Destroy()
    end)

    -- Destroy all static objects (avoid errors for unnamed statics)
    local SetStatics = SET_STATIC:New():FilterZones({opszone:GetZone()}):FilterOnce()
    SetStatics:ForEachStatic(function(static)
        local staticName = static:GetName() or "Unnamed Static"
        env.info("Destroying static object: " .. staticName)
        static:Destroy()
    end)

    -- Destroy warehouses/tents that are actually UNITS
    local SetUnits = SET_UNIT:New():FilterZones({opszone}):FilterOnce()
    SetUnits:ForEachUnit(function(unit)
        local unitName = unit:GetName()
        local unitType = unit:GetTypeName()
        
        -- Check if it's a warehouse, tent, ammo, or fuel
        if unitType:find("Warehouse") or unitType:find("Tent") or unitType:find("Ammo") or unitType:find("Fuel") then
            env.info("Destroying unit: " .. unitName .. " (Type: " .. unitType .. ")")
            unit:Destroy()
        end
    end)
end


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

            destroyZoneObjects(self)  -- Destroy objects in the captured zone
            DeployNewZoneForces(coalitionSide)  -- Deploy forces based on new owner
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