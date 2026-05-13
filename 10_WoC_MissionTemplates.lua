--create  auftrag patrol mission for later use
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