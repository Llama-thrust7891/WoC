------------Coldwar 78 index----------------
--------------------------------------------
---
local lfs = require("lfs")
local savedGamesPath = lfs.writedir() -- This gets "C:/Users/YourUsername/Saved Games/DCS/" dynamically
dofile(lfs.writedir() .. "Missions/WoC-Sinai/04_WoC_Groups.lua")
dofile(lfs.writedir() .. "Missions/WoC-Sinai/03_WoC_Main.lua")


-----Coldwar units table-----
BlueSamGroupName = Group_USA_NASAM