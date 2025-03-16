----------------------------------
----------------------------------
---------PLayer Tasking ----------
function PlayerTasking()
    -- Settings - we want players to have a settings menu, be on imperial measures, and get directions as BR
    _SETTINGS:SetPlayerMenuOn()
    _SETTINGS:SetImperial()
    _SETTINGS:SetA2G_BR()
   
    -- Set up the A2G task controller for the blue side named "82nd Airborne"
    local taskmanager = PLAYERTASKCONTROLLER:New("82nd Airborne",coalition.side.BLUE,PLAYERTASKCONTROLLER.Type.A2G)
   
    -- set locale to English
    taskmanager:SetLocale("en")
   
    -- Set up detection with grup names *containing* "Blue Recce", these will add targets to our controller via detection. Can be e.g. a drone.
    taskmanager:SetupIntel("Blue")
   
    -- Add a single Recce group name "Blue Humvee"
    taskmanager:AddAgent(GROUP:FindByName("Blue"))
   
    -- Set the callsign for SRS and Menu name to be "Groundhog"
    taskmanager:SetMenuName("Ghostbat")
   
    -- Add accept- and reject-zones for detection
    -- Accept zones are handy to limit e.g. the engagement to a certain zone. The example is a round, mission editor created zone named "AcceptZone"
    taskmanager:AddAcceptZone(ZONE:New("CAP_Zone_E"))
    taskmanager:AddAcceptZone(ZONE:New("CAP_Zone_SE"))
    taskmanager:AddAcceptZone(ZONE:New("CAP_Zone_Mid"))
    taskmanager:AddAcceptZone(ZONE:New("CAP_Zone_W"))
    taskmanager:AddAcceptZone(ZONE:New("CAP_Zone_SW"))
   
    -- Reject zones are handy to create borders. The example is a ZONE_POLYGON, created in the mission editor, late activated with waypoints, 
    -- named "AcceptZone#ZONE_POLYGON"
    --taskmanager:AddRejectZone(ZONE:FindByName("RejectZone"))
   
    -- Set up using SRS for messaging
    local hereSRSPath = "C:\\Program Files\\DCS-SimpleRadio-Standalone"
    local hereSRSPort = 5002
    -- local hereSRSGoogle = "C:\\Program Files\\DCS-SimpleRadio-Standalone\\yourkey.json"
    taskmanager:SetSRS({130,255},{radio.modulation.AM,radio.modulation.AM},hereSRSPath,"female","en-GB",hereSRSPort,"Microsoft Hazel Desktop",0.7,hereSRSGoogle)
   
    -- Controller will announce itself under these broadcast frequencies, handy to use cold-start frequencies here of your aircraft
    taskmanager:SetSRSBroadcast({127.5,305},{radio.modulation.AM,radio.modulation.AM})
   
    -- Example: Manually add an AIRBASE as a target
    --taskmanager:AddTarget(AIRBASE:FindByName(AIRBASE.Caucasus.Senaki_Kolkhi))
   
    -- Example: Manually add a COORDINATE as a target
    --taskmanager:AddTarget(GROUP:FindByName("Scout Coordinate"):GetCoordinate())
   
    -- Set a whitelist for tasks
    taskmanager:SetTaskWhiteList({AUFTRAG.Type.CAS, AUFTRAG.Type.BAI, AUFTRAG.Type.BOMBING, AUFTRAG.Type.BOMBRUNWAY, AUFTRAG.Type.SEAD})
   
    -- Set target radius
    taskmanager:SetTargetRadius(1000)
   end
   
   timer.scheduleFunction(PlayerTasking, {}, timer.getTime() + 20)
   
    ------------------------------------------
    ------------------------------------------
    --------- End Player Tasking--------------
    ------------------------------------------
    ------------------------------------------