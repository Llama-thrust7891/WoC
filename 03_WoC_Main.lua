---Start the main script for setting up the Wings of Conflict Mission--

--Testing Spawn of Predefined group in 04_Woc_Groups.lua
SamCount = 000

function spawn_Blue_SAM_Site(GroupTemplate, Groupname)

Group_SAM__Hawk = SPAWN:NewFromTemplate(GroupTemplate, Groupname)
Group_SAM__Hawk:InitCountry(country.id.USA)
Group_SAM__Hawk:InitCategory(Group.Category.GROUND)
Group_SAM__Hawk:InitCoalition(coalition.side.BLUE)

Group_SAM__Hawk:Spawn()
end

SamCount = 000
Groupname = BlueSamGroupName.."_"..SamCount+1

spawn_Blue_SAM_Site(BlueSamGroupName, Groupname )