----------------------------------
----------------------------------
---------PLayer Tasking ----------
function PlayerTaskingBlue()
    -- Settings - we want players to have a settings menu, be on imperial measures, and get directions as BR
    _SETTINGS:SetPlayerMenuOn()
    _SETTINGS:SetImperial()
    _SETTINGS:SetA2G_BR()
   
    -- Set up the A2G task controller for the blue side named "82nd Airborne"
    BlueTaskManagerA2G = PLAYERTASKCONTROLLER:New("82 Airbourne",coalition.side.Blue,PLAYERTASKCONTROLLER.Type.A2G)
   
    -- set locale to English
    BlueTaskManagerA2G:SetLocale("en")
   
    -- Set up detection with grup names *containing* "Blue Recce", these will add targets to our controller via detection. Can be e.g. a drone.
    BlueTaskManagerA2G:SetupIntel("Blue")
   
    -- Add a single Recce group name "Blue Humvee"
    --RedTaskManager:AddAgent(GROUP:FindByName("Blue"))
   
    -- Set the callsign for SRS and Menu name to be "Groundhog"
    BlueTaskManagerA2G:SetMenuName("Ghost Bat")
   
    -- Add accept- and reject-zones for detection
    -- Accept zones are handy to limit e.g. the engagement to a certain zone. The example is a round, mission editor created zone named "AcceptZone"
    BlueTaskManagerA2G:AddAcceptZone(ZONE:New("CAP_Zone_E"))
    BlueTaskManagerA2G:AddAcceptZone(ZONE:New("CAP_Zone_SE"))
    BlueTaskManagerA2G:AddAcceptZone(ZONE:New("CAP_Zone_Mid"))
    BlueTaskManagerA2G:AddAcceptZone(ZONE:New("CAP_Zone_W"))
    BlueTaskManagerA2G:AddAcceptZone(ZONE:New("CAP_Zone_SW"))
   
    -- Reject zones are handy to create borders. The example is a ZONE_POLYGON, created in the mission editor, late activated with waypoints, 
    -- named "AcceptZone#ZONE_POLYGON"
    --BlueTaskManager:AddRejectZone(ZONE:FindByName("RejectZone"))
   
    -- Set up using SRS for messaging
   --local hereSRSPath = "C:\\Program Files\\DCS-SimpleRadio-Standalone"
   --local hereSRSPort = 5002
    -- local hereSRSGoogle = "C:\\Program Files\\DCS-SimpleRadio-Standalone\\yourkey.json"
    BlueTaskManagerA2G:SetSRS({130,250},{radio.modulation.AM,radio.modulation.AM},hereSRSPath,"female","en-GB",hereSRSPort,"Microsoft Hazel Desktop",0.7,hereSRSGoogle)
   
    -- Controller will announce itself under these broadcast frequencies, handy to use cold-start frequencies here of your aircraft
    BlueTaskManagerA2G:SetSRSBroadcast({130,250},{radio.modulation.AM,radio.modulation.AM})
   
    -- Example: Manually add an AIRBASE as a target
    --BlueTaskManagerA2G:AddTarget(AIRBASE:FindByName(AIRBASE.Caucasus.Senaki_Kolkhi))
   
    -- Example: Manually add a COORDINATE as a target
    --BlueTaskManagerA2G:AddTarget(GROUP:FindByName("Scout Coordinate"):GetCoordinate())
   
    -- Set a whitelist for tasks
    BlueTaskManagerA2G:SetTaskWhiteList({AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING, AUFTRAG.Type.BOMBRUNWAY, AUFTRAG.Type.SEAD,AUFTRAG.Type.INTERCEPT,AUFTRAG.Type.CAP})
   
    -- Set target radius
    BlueTaskManagerA2G:SetTargetRadius(1000)
   -- BlueTaskManagerA2G:Verbose()  ---doesnt work
end
   
function PlayerTaskingRed()
    -- Settings - we want players to have a settings menu, be on imperial measures, and get directions as BR
  --_SETTINGS:SetPlayerMenuOn()
  --_SETTINGS:SetImperial()
  --_SETTINGS:SetA2G_BR()
   
    -- Set up the A2G task controller for the blue side named "82nd Airborne"
    RedTaskManagerA2G = PLAYERTASKCONTROLLER:New("31st Infantry",coalition.side.RED,PLAYERTASKCONTROLLER.Type.A2G)
   
    -- set locale to English
    RedTaskManagerA2G:SetLocale("en")
   
    -- Set up detection with grup names *containing* "Blue Recce", these will add targets to our controller via detection. Can be e.g. a drone.
    RedTaskManagerA2G:SetupIntel("Red")
   
    -- Add a single Recce group name "Blue Humvee"
    --RedTaskManager:AddAgent(GROUP:FindByName("Blue"))
   
    -- Set the callsign for SRS and Menu name to be "Groundhog"
    RedTaskManagerA2G:SetMenuName("SnakeEyes")
   
    -- Add accept- and reject-zones for detection
    -- Accept zones are handy to limit e.g. the engagement to a certain zone. The example is a round, mission editor created zone named "AcceptZone"
    RedTaskManagerA2G:AddAcceptZone(ZONE:New("CAP_Zone_E"))
    RedTaskManagerA2G:AddAcceptZone(ZONE:New("CAP_Zone_SE"))
    RedTaskManagerA2G:AddAcceptZone(ZONE:New("CAP_Zone_Mid"))
    RedTaskManagerA2G:AddAcceptZone(ZONE:New("CAP_Zone_W"))
    RedTaskManagerA2G:AddAcceptZone(ZONE:New("CAP_Zone_SW"))
   
    -- Reject zones are handy to create borders. The example is a ZONE_POLYGON, created in the mission editor, late activated with waypoints, 
    -- named "AcceptZone#ZONE_POLYGON"
    --BlueTaskManager:AddRejectZone(ZONE:FindByName("RejectZone"))
   
    -- Set up using SRS for messaging
   --local hereSRSPath = "C:\\Program Files\\DCS-SimpleRadio-Standalone"
   --local hereSRSPort = 5002
    -- local hereSRSGoogle = "C:\\Program Files\\DCS-SimpleRadio-Standalone\\yourkey.json"
    RedTaskManagerA2G:SetSRS({130,240},{radio.modulation.AM,radio.modulation.AM},hereSRSPath,"female","en-GB",hereSRSPort,"Microsoft Hazel Desktop",0.7,hereSRSGoogle)
   
    -- Controller will announce itself under these broadcast frequencies, handy to use cold-start frequencies here of your aircraft
    RedTaskManagerA2G:SetSRSBroadcast({127,240},{radio.modulation.AM,radio.modulation.AM})
   
    -- Example: Manually add an AIRBASE as a target
    --RedTaskManagerA2G:AddTarget(AIRBASE:FindByName(AIRBASE.Caucasus.Senaki_Kolkhi))
   
    -- Example: Manually add a COORDINATE as a target
    --RedTaskManagerA2G:AddTarget(GROUP:FindByName("Scout Coordinate"):GetCoordinate())
   
    -- Set a whitelist for tasks
    RedTaskManagerA2G:SetTaskWhiteList({AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING, AUFTRAG.Type.BOMBRUNWAY, AUFTRAG.Type.SEAD,AUFTRAG.Type.INTERCEPT,AUFTRAG.Type.CAP,AUFTRAG.NewTROOPTRANSPORT})
   
    -- Set target radius
    RedTaskManagerA2G:SetTargetRadius(1000)
   -- RedTaskManagerA2G:Verbose()---doesnt work
end
------------------------------------------
------------------------------------------
--------- End Player Tasking--------------
------------------------------------------
------------------------------------------