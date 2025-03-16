------------Coldwar 78 index----------------
--------------------------------------------
---
--local lfs = require("lfs")
--local savedGamesPath = lfs.writedir() -- This gets "C:/Users/YourUsername/Saved Games/DCS/" dynamically
-- dofile(lfs.writedir() .. "Missions/WoC-Sinai/01_WoC_Index.lua")  - call in ME.
dofile(lfs.writedir() .. "Missions/WoC-Sinai/Moose.lua")
dofile(lfs.writedir() .. "Missions/WoC-Sinai/mist_4_5_126.lua")
--dofile(lfs.writedir() .. "Missions/WoC-Sinai/03_Persistence.lua")
dofile(lfs.writedir() .. "Missions/WoC-Sinai/04_WoC_Groups_CW78.lua")
dofile(lfs.writedir() .. "Missions/WoC-Sinai/05_WoC_Main.lua")


-----Coldwar units table-----
BlueSamGroupName = Group_USA_Hawk