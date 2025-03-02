---Start the main script for setting up the Wings of Conflict Mission--

-- Testing Spawn of Predefined group in 04_WoC_Groups.lua
SamCount = 0
Template_Spawnzone = ZONE:FindByName("Template_Spawn_Zone")  -- Ensure the zone exists
BlueSamGroupName = "Group_USA_Hawk"  -- Use the actual group name

function Spawn_Blue_SAM_Site(GroupName)
    local GroupTemplate = GROUP:FindByName(GroupName) -- Find group by name in ME
    if not GroupTemplate then
        env.info("ERROR: Group template "..GroupName.." not found!")
        return
    end

    -- Generate unique name
    local Groupname = GroupName.."_"..SamCount
    local SpawnPoint = Template_Spawnzone:GetRandomVec2() -- Get a random Vec2
    local newX = SpawnPoint.x
    local newY = SpawnPoint.y

    -- Log spawn action
    env.info("Spawning "..GroupName.." with name "..Groupname.." at X:"..newX.." Y:"..newY)

    -- Spawn using Moose
    Group_SAM_Hawk = SPAWN:New(GroupName)
        :InitCountry(country.id.USA)
        :InitCategory(Group.Category.GROUND)
        :InitCoalition(coalition.side.BLUE)
        :SpawnFromVec3(SpawnPointVec3)

    -- Increment counter
    SamCount = SamCount + 1
end

Spawn_Blue_SAM_Site(BlueSamGroupName)
