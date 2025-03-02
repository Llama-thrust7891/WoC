---Start the main script for setting up the Wings of Conflict Mission--

-- Testing Spawn of Predefined group in 04_WoC_Groups.lua
SamCount = 1
airfieldName = "Palmachim"
MinDistance =200
MaxDistance = 1000

function Spawn_Near_airbase(GroupTemplate,Inner,Outer)
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
    --Group_Spawn:InitPositionVec2(Spawnpoint)
    Group_Spawn:InitPositionCoordinate(Spawnpoint)
    Group_Spawn:Spawn()

    -- Increment counter
    SamCount = SamCount + 1
end

Spawn_Near_airbase(Group_Blue_SAM_Site, MinDistance, MaxDistance)
Spawn_Near_airbase(Group_Blue_SAM, MinDistance, MaxDistance)
Spawn_Near_airbase(Group_Blue_Mech, MinDistance, MaxDistance)
Spawn_Near_airbase(Group_Blue_APC, MinDistance, MaxDistance)
Spawn_Near_airbase(Group_Blue_Armoured, MinDistance, MaxDistance)
Spawn_Near_airbase(Group_Blue_Inf, MinDistance, MaxDistance)
Spawn_Near_airbase(Group_Blue_Truck, MinDistance, MaxDistance)