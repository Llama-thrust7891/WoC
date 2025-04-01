------------Modern Warfare 94  index----------------
--------------------------------------------
---
--local lfs = require("lfs")
--local savedGamesPath = lfs.writedir() -- This gets "C:/Users/YourUsername/Saved Games/DCS/" dynamically
--dofile(lfs.writedir() .. "Missions/WoC-Sinai-MW/01_WoC_Index.lua")  - call in ME.
dofile(lfs.writedir() .. "Missions/WoC-Sinai-MW/Moose.lua")
dofile(lfs.writedir() .. "Missions/WoC-Sinai-MW/mist_4_5_126.lua")
--dofile(lfs.writedir() .. "Missions/WoC-Sinai-MW/03_Persistence.lua")
dofile(lfs.writedir() .. "Missions/WoC-Sinai-MW/04_WoC_Groups_MW.lua")
dofile(lfs.writedir() .. "Missions/WoC-Sinai-MW/05_WoC_Main.lua")


-----Coldwar units table-----
--BlueSamGroupName = Group_USA_Hawk