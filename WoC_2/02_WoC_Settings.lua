--set server restart interval
RESTART_INTERVAL = 8 * 60 * 60 -- 8 hours in seconds
--set reference airfield for dividing the map
referenceAirfield = "Rayak"

-- Set the required clear zone around warehouses for airfield spawning 
-- if too large, warehouses spawn too far away for SQNS recommend no higher then 200.
GetClearZonePositionsDistance = 125

 -- Set Chief Verbosity(5)
CheifVerbosity = 5
-- "MissionLimit" set per mission limit for the below missions
--AUFTRAG.Type.ARTY)
--AUFTRAG.Type.BARRAGE)
--AUFTRAG.Type.GROUNDATTACK)
--AUFTRAG.Type.RECON)
--AUFTRAG.Type.BAI)
--AUFTRAG.Type.INTERCEPT)
--AUFTRAG.Type.SEAD)
--AUFTRAG.Type.CAPTUREZONE)
--AUFTRAG.Type.CASENHANCED)
--AUFTRAG.Type.CAS)
MissionLimit = 4
--Set max missions per chief to 100 by default
ChiefMissionLimit =100