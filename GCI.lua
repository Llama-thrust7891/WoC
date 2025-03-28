-- Table to store player preferences
local GCI_Players = {}
local DefaultUpdateTime = 30  -- Default update time in seconds

-- Function to calculate BRAA (Bearing, Range, Altitude, Aspect)
function GetBRAA(player, bandit)
    if not player or not bandit then return nil end

    local playerCoord = player:GetCoordinate()
    local banditCoord = bandit:GetCoordinate()
    
    if not playerCoord or not banditCoord then return nil end

    local bearing, distance = playerCoord:GetBearingTo(banditCoord, UTILS.FeetToMeters(1))
    local altitude = banditCoord.y
    local aspect = "Hot"

    -- Check if the bandit is flanking or running
    local banditVec2 = bandit:GetVelocityVec3()
    if banditVec2 then
        local banditHeading = math.deg(math.atan2(banditVec2.z, banditVec2.x))
        local angleDiff = math.abs(bearing - banditHeading)
        if angleDiff > 135 then
            aspect = "Cold"
        elseif angleDiff > 45 then
            aspect = "Flanking"
        end
    end

    return string.format("BULLSEYE %d° / %.1fnm / %dft / %s", bearing, distance * 0.000539957, altitude, aspect)
end

-- Function to send BRAA message to a player
function SendBRAA(playerName)
    local player = UNIT:FindByName(playerName)
    if player and player:IsAlive() then
        local nearestBandit, minDistance = nil, math.huge

        -- Find the closest enemy aircraft
        DetectionSetGroup:ForEachGroup(function(banditGroup)
            local banditUnit = banditGroup:GetUnit(1)
            if banditUnit and banditUnit:IsAlive() then
                local distance = player:GetCoordinate():Get2DDistance(banditUnit:GetCoordinate())
                if distance < minDistance then
                    minDistance = distance
                    nearestBandit = banditUnit
                end
            end
        end)

        -- Show BRAA call if a bandit is found
        if nearestBandit then
            local message = GetBRAA(player, nearestBandit)
            if message then
                MESSAGE:New(message, 5):ToClient(player)
            end
        end
    end
end

-- Function to update GCI for all players with active updates
function UpdateGCI()
    for playerName, data in pairs(GCI_Players) do
        if data.active then
            SendBRAA(playerName)
        end
    end

    -- Schedule next update based on active intervals
    local nextUpdate = DefaultUpdateTime
    for _, data in pairs(GCI_Players) do
        if data.active and data.interval < nextUpdate then
            nextUpdate = data.interval
        end
    end

    TIMER:New(UpdateGCI):Start(nextUpdate)
end

-- Function to toggle GCI updates for a player
function ToggleGCI(playerName, interval)
    if not GCI_Players[playerName] then
        GCI_Players[playerName] = { active = true, interval = DefaultUpdateTime }
    end

    if interval then
        GCI_Players[playerName].interval = interval
    else
        GCI_Players[playerName].active = not GCI_Players[playerName].active
    end
end

-- Function to add the F10 menu for players
function AddGCIMenu(player)
    local group = player:GetGroup()
    if group then
        local menuRoot = MENU_GROUP:New(group, "GCI")

        MENU_GROUP_COMMAND:New(group, "Toggle GCI", menuRoot, ToggleGCI, player:GetName())
        MENU_GROUP_COMMAND:New(group, "Set Interval: 10s", menuRoot, ToggleGCI, player:GetName(), 10)
        MENU_GROUP_COMMAND:New(group, "Set Interval: 30s", menuRoot, ToggleGCI, player:GetName(), 30)
        MENU_GROUP_COMMAND:New(group, "Set Interval: 1min", menuRoot, ToggleGCI, player:GetName(), 60)
        MENU_GROUP_COMMAND:New(group, "Set Interval: 5min", menuRoot, ToggleGCI, player:GetName(), 300)
    end
end

-- Monitor for new players and add the menu
SCHEDULER:New(nil, function()
    for _, playerName in pairs(UTILS.GetPlayers()) do
        local player = UNIT:FindByName(playerName)
        if player and not GCI_Players[playerName] then
            AddGCIMenu(player)
            GCI_Players[playerName] = { active = false, interval = DefaultUpdateTime }
        end
    end
end, {}, 1, 10)

-- Start the GCI update loop
UpdateGCI()
env.info("GCI script with menu initialized.")
-- End of GCI script