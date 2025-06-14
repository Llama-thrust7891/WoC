------------Modern Warfare 94  index----------------
--------------------------------------------
---
--local lfs = require("lfs")
--local savedGamesPath = lfs.writedir() -- This gets "C:/Users/YourUsername/Saved Games/DCS/" dynamically
--dofile(lfs.writedir() .. "Missions/WoC-Sinai-MW/01_WoC_Index.lua")  - call in ME.
dofile(lfs.writedir() .. "Missions/WoC-Syria-MW/Moose.lua")
dofile(lfs.writedir() .. "Missions/WoC-Syria-MW/mist_4_5_126.lua")
--dofile(lfs.writedir() .. "Missions/WoC-Sinai-MW/03_Persistence.lua")
dofile(lfs.writedir() .. "Missions/WoC-Syria-MW/04_WoC_Groups_MW.lua")
dofile(lfs.writedir() .. "Missions/WoC-Syria-MW/05_WoC_Main.lua")
SaveFolder = "\\Missions\\WoC-Syria-MW\\Save\\"


-----Coldwar units table-----
--BlueSamGroupName = Group_USA_Hawk